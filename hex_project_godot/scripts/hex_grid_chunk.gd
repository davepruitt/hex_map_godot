class_name HexGridChunk
extends Node3D

#region Private data members

## This is a list that contains each HexCell object in the grid
var _hex_cells: Array[HexCell] = []

var _terrain: HexMesh = HexMesh.new()
var _rivers: HexMesh = HexMesh.new()
var _roads: HexMesh = HexMesh.new()
var _water: HexMesh = HexMesh.new()
var _water_shore: HexMesh = HexMesh.new()
var _estuaries: HexMesh = HexMesh.new()

var _features: HexFeatureManager = HexFeatureManager.new()

var _terrain_shader_material: ShaderMaterial
var _rivers_shader_material: ShaderMaterial
var _road_shader_material: ShaderMaterial
var _water_shader_material: ShaderMaterial
var _water_shore_shader_material: ShaderMaterial
var _estuaries_shader_material: ShaderMaterial
var _walls_material: StandardMaterial3D

#endregion

#region Public data members

var update_needed: bool = false

#endregion

#region Method overrides

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_child(_terrain)
	add_child(_rivers)
	add_child(_roads)
	add_child(_water)
	add_child(_water_shore)
	add_child(_estuaries)
	add_child(_features)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
#endregion

#region Public methods

func add_cell (index: int, cell: HexCell) -> void:
	#Set the hex chunk reference on the hex cell object
	cell.hex_chunk = self
	
	#Append the cell to the list of cells in this chunk
	_hex_cells.append(cell)
	
	#Add the hex cell as a child of the chunk
	add_child(cell)

func set_terrain_mesh_material (mat: ShaderMaterial) -> void:
	_terrain_shader_material = mat
	
func set_rivers_mesh_material (mat: ShaderMaterial) -> void:
	_rivers_shader_material = mat
	
func set_road_mesh_material (mat: ShaderMaterial) -> void:
	_road_shader_material = mat
	
func set_water_mesh_material (mat: ShaderMaterial) -> void:
	_water_shader_material = mat
	
func set_water_shore_mesh_material (mat: ShaderMaterial) -> void:
	_water_shore_shader_material = mat

func set_estuaries_mesh_material (mat: ShaderMaterial) -> void:
	_estuaries_shader_material = mat

func set_walls_mesh_material (mat: StandardMaterial3D) -> void:
	_walls_material = mat

func request_refresh () -> void:
	#Set the "update needed" flag
	update_needed = true

func refresh () -> void:
	#Run the triangulation of the mesh
	_triangulate_cells()
	
	#Reset the "update needed" flag
	update_needed = false

#endregion

#region Mesh triangulation methods

func _triangulate_cells () -> void:
	#Begin creation of the terrain mesh
	_terrain.begin()
	
	#Begin creation of the rivers mesh
	_rivers.begin()
	_rivers.use_colors = false
	_rivers.use_collider = false
	_rivers.use_uv_coordinates = true
	_rivers.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	#Begin creation of the roads mesh
	_roads.begin()
	_roads.use_colors = false
	_roads.use_collider = false
	_roads.use_uv_coordinates = true
	_roads.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	#Begin creation of the water mesh
	_water.begin()
	_water.use_colors = false
	_water.use_collider = false
	_water.use_uv_coordinates = true
	_water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	#Begin creation of the shore water mesh
	_water_shore.begin()
	_water_shore.use_colors = false
	_water_shore.use_collider = false
	_water_shore.use_uv_coordinates = true
	_water_shore.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	#Begin creation of the estuaries water mesh
	_estuaries.begin()
	_estuaries.use_colors = false
	_estuaries.use_collider = false
	_estuaries.use_uv_coordinates = true
	_estuaries.use_uv2_coordinates = true
	_estuaries.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	#Clear the features for the hex grid chunk
	_features.clear()
	
	#Begin creation of the walls mesh
	_features.walls.begin()
	_features.walls.use_colors = false
	_features.walls.use_collider = false
	_features.walls.use_uv_coordinates = false
	_features.walls.use_uv2_coordinates = false
	_features.walls.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	
	#Iterate over each hex cell and triangulate the mesh for that hex
	for i in range(0, len(_hex_cells)):
		_triangulate_hex(_hex_cells[i])
	
	#Finalize the creation of the terrain mesh
	_terrain.end(_terrain_shader_material)
	
	#Finalize the creation of the rivers mesh
	_rivers.end(_rivers_shader_material)
	
	#Finalize the creation of the roads mesh
	_roads.end(_road_shader_material)
	
	#Finalize the creation of the water mesh
	_water.end(_water_shader_material)
	
	#Finalize the creation of the water shore mesh
	_water_shore.end(_water_shore_shader_material)
	
	#Finalize the creation of the estuaries mesh
	_estuaries.end(_estuaries_shader_material)
	
	#Finalize the creation of the features
	_features.apply()
	
	#Finalize the walls mesh
	_features.walls.end(_walls_material)

func _triangulate_hex (cell: HexCell) -> void:
	#Iterate over each of the 6 directions from the center of the hex
	for i in range(0, 6):
		#Form the mesh for this direction of the hex
		_triangulate_hex_in_direction(cell, i)
	
	#If this cell is not underwater...
	if (not cell.is_underwater):
		#If this cell does not have a river and also does not have roads...
		if (not cell.has_river) and (not cell.has_roads):
			#Add the features to this cell
			_features.add_feature(cell, cell.position)
		
		#If this cell has a special feature...
		if (cell.is_special):
			_features.add_special_feature(cell, cell.position)
	
func _triangulate_hex_in_direction (cell: HexCell, direction: HexDirectionsClass.HexDirections) -> void:
	#Calculate the Vector3 positions for the vertices of the triangle
	var center = cell.position
	var edge_vertices: EdgeVertices = EdgeVertices.new(
		center + HexMetrics.get_first_solid_corner(direction),
		center + HexMetrics.get_second_solid_corner(direction)
	)
	
	if (cell.has_river):
		if (cell.has_river_through_edge(direction)):
			edge_vertices.v3.y = cell.stream_bed_y
			
			if (cell.has_river_beginning_or_end):
				_triangulate_with_river_begin_or_end(direction, cell, center, edge_vertices)
			else:
				_triangulate_with_river(direction, cell, center, edge_vertices)
		else:
			_triangulate_adjacent_to_river(direction, cell, center, edge_vertices)
	else:
		_triangulate_without_river(direction, cell, center, edge_vertices)
		
		#Add features
		if (not cell.is_underwater) and (not cell.has_road_through_edge(direction)):
			var feature_position: Vector3 = (center + edge_vertices.v1 + edge_vertices.v5) * (1.0 / 3.0)
			_features.add_feature(cell, feature_position)
	
	#Add connections to other hex cells
	if (direction <= HexDirectionsClass.HexDirections.SE):
		_triangulate_connection(direction, cell, edge_vertices)
	
	#Triangulate water if this cell is underwater
	if (cell.is_underwater):
		_triangulate_water(direction, cell, center)

func _triangulate_with_river_begin_or_end (
	direction: HexDirectionsClass.HexDirections, cell: HexCell,
	center: Vector3, e: EdgeVertices) -> void:
		
	# In this case, we want to terminate the channel at the center, 
	# but still use two steps to get there. So again we create a middle edge 
	# between the center and edge. Because we do want to terminate the channel, 
	# it is fine that it gets pinched.
	
	var m: EdgeVertices = EdgeVertices.new(
		center.lerp(e.v1, 0.5),
		center.lerp(e.v5, 0.5)
	)
	
	#Set the middle vertex to the stream bed height. But the center should not be adjusted.
	m.v3.y = e.v3.y
	
	#Triangulate with a single edge strip and a fan.
	_triangulate_edge_strip(m, cell.hex_color, e, cell.hex_color)
	_triangulate_edge_fan(center, m, cell.hex_color)
	
	#Triangulate the river quads
	if (not cell.is_underwater):
		var reversed: bool = cell.has_incoming_river
		_triangulate_river_quad_1(m.v2, m.v4, e.v2, e.v4, cell.river_surface_y, 0.6, reversed)
		
		center.y = cell.river_surface_y
		m.v2.y = cell.river_surface_y
		m.v4.y = cell.river_surface_y
		if (reversed):
			var uv1: Vector2 = Vector2(0.5, 0.4)
			var uv2: Vector2 = Vector2(1.0, 0.2)
			var uv3: Vector2 = Vector2(0.0, 0.2)
			
			_rivers.add_perturbed_triangle_with_uv(center, m.v4, m.v2,
				Color.WHITE, Color.WHITE, Color.WHITE,
				uv1, uv3, uv2)
		else:
			var uv1: Vector2 = Vector2(0.5, 0.4)
			var uv2: Vector2 = Vector2(0.0, 0.6)
			var uv3: Vector2 = Vector2(1.0, 0.6)
			
			_rivers.add_perturbed_triangle_with_uv(center, m.v4, m.v2,
				Color.WHITE, Color.WHITE, Color.WHITE,
				uv1, uv3, uv2)

func _triangulate_with_river (
	direction: HexDirectionsClass.HexDirections, cell: HexCell, 
	center: Vector3, e: EdgeVertices) -> void:
	
	var center_l: Vector3 = Vector3.ZERO
	var center_r: Vector3 = Vector3.ZERO
	var opposite_direction: HexDirectionsClass.HexDirections = HexDirectionsClass.opposite(direction)
	var previous_direction: HexDirectionsClass.HexDirections = HexDirectionsClass.previous(direction)
	var next_direction: HexDirectionsClass.HexDirections = HexDirectionsClass.next(direction)
	var next2_direction: HexDirectionsClass.HexDirections = HexDirectionsClass.next2(direction)	
	if (cell.has_river_through_edge(opposite_direction)):
		center_l = center + HexMetrics.get_first_solid_corner(previous_direction) * 0.25
		center_r = center + HexMetrics.get_second_solid_corner(next_direction) * 0.25
	elif (cell.has_river_through_edge(next_direction)):
		center_l = center
		center_r = center.lerp(e.v5, 0.67)
	elif (cell.has_river_through_edge(previous_direction)):
		center_l = center.lerp(e.v1, 0.67)
		center_r = center 
	elif (cell.has_river_through_edge(next2_direction)):
		center_l = center
		center_r = center + HexMetrics.get_solid_edge_middle(next_direction) * (0.5 * HexMetrics.INNER_TO_OUTER)
	else:
		center_l = center + HexMetrics.get_solid_edge_middle(previous_direction) * (0.5 * HexMetrics.INNER_TO_OUTER)
		center_r = center
	
	center = center_l.lerp(center_r, 0.5)
	
	#The middle line can be found by creating edge vertices between the center and edge.
	var m: EdgeVertices = EdgeVertices.new(
		center_l.lerp(e.v1, 0.5),
		center_r.lerp(e.v5, 0.5),
		1.0 / 6.0
	)
	
	#Adjust the middle vertex of the middle edge, as well as the center, 
	#so they become channel bottoms.
	center.y = e.v3.y
	m.v3.y = e.v3.y
	
	#Fill the space between the middle and edge lines.
	_triangulate_edge_strip(m, cell.hex_color, e, cell.hex_color)
	
	#Second section of trapezoid
	_terrain.add_perturbed_triangle(center_l, m.v2, m.v1, cell.hex_color, cell.hex_color, cell.hex_color)
	_terrain.add_perturbed_quad(center_l, center, m.v2, m.v3, cell.hex_color, cell.hex_color, cell.hex_color, cell.hex_color)
	_terrain.add_perturbed_quad(center, center_r, m.v3, m.v4, cell.hex_color, cell.hex_color, cell.hex_color, cell.hex_color)
	_terrain.add_perturbed_triangle(center_r, m.v5, m.v4, cell.hex_color, cell.hex_color, cell.hex_color)
	
	#Form the river quads
	if (not cell.is_underwater):
		var reversed: bool = (cell.incoming_river_direction == direction)
		_triangulate_river_quad_1(center_l, center_r, m.v2, m.v4, cell.river_surface_y, 0.4, reversed)
		_triangulate_river_quad_1(m.v2, m.v4, e.v2, e.v4, cell.river_surface_y, 0.6, reversed)

func _triangulate_adjacent_to_river (
	direction: HexDirectionsClass.HexDirections, cell: HexCell,
	center: Vector3, e: EdgeVertices) -> void:
	
	if (cell.has_roads):
		_triangulate_road_adjacent_to_river(direction, cell, center, e)
	
	var next_direction: HexDirectionsClass.HexDirections = HexDirectionsClass.next(direction)
	var previous_direction: HexDirectionsClass.HexDirections = HexDirectionsClass.previous(direction)
	var previous2_direction: HexDirectionsClass.HexDirections = HexDirectionsClass.previous2(direction)
	var next2_direction: HexDirectionsClass.HexDirections = HexDirectionsClass.next2(direction)
	
	if (cell.has_river_through_edge(next_direction)):
		if (cell.has_river_through_edge(previous_direction)):
			center += HexMetrics.get_solid_edge_middle(direction) * (HexMetrics.INNER_TO_OUTER * 0.5)
		elif (cell.has_river_through_edge(previous2_direction)):
			center += HexMetrics.get_first_solid_corner(direction) * 0.25
	elif (cell.has_river_through_edge(previous_direction) and cell.has_river_through_edge(next2_direction)):
		center += HexMetrics.get_second_solid_corner(direction) * 0.25
	
	var m: EdgeVertices = EdgeVertices.new(
		center.lerp(e.v1, 0.5),
		center.lerp(e.v5, 0.5)
	)
	
	_triangulate_edge_strip(m, cell.hex_color, e, cell.hex_color)
	_triangulate_edge_fan(center, m, cell.hex_color)
	
	#Add features to this hex
	if (not cell.is_underwater) and (not cell.has_road_through_edge(direction)):
		var feature_position: Vector3 = (center + e.v1 + e.v5) * (1.0 / 3.0)
		_features.add_feature(cell, feature_position)

func _triangulate_connection (
	direction: HexDirectionsClass.HexDirections, 
	cell: HexCell, e1: EdgeVertices) -> void:
	
	#Get the neighboring cell in the specified direction
	var neighbor_cell = cell.get_neighbor(direction)
	
	#If the neighboring cell is null, then fail out of the function
	if (neighbor_cell == null):
		return
	
	var bridge = HexMetrics.get_bridge(direction)
	bridge.y = neighbor_cell.position.y - cell.position.y
	
	var e2: EdgeVertices = EdgeVertices.new(
		e1.v1 + bridge,
		e1.v5 + bridge
	)
	
	var has_river: bool = cell.has_river_through_edge(direction)
	var has_road: bool = cell.has_road_through_edge(direction)
	
	if (has_river):
		e2.v3.y = neighbor_cell.stream_bed_y
		
		if (not cell.is_underwater):
			if (not neighbor_cell.is_underwater):
				var reversed: bool = (cell.has_incoming_river and (cell.incoming_river_direction == direction))
				_triangulate_river_quad_2(e1.v2, e1.v4, e2.v2, e2.v4,
					cell.river_surface_y, neighbor_cell.river_surface_y,
					0.8, reversed)
			elif (cell.elevation > neighbor_cell.water_level):
				_triangulate_waterfall_in_water(e1.v2, e1.v4, e2.v2, e2.v4,
					cell.river_surface_y, neighbor_cell.river_surface_y,
					neighbor_cell.water_surface_y)
		elif (not neighbor_cell.is_underwater) and (neighbor_cell.elevation > cell.water_level):
			_triangulate_waterfall_in_water(e2.v4, e2.v2, e1.v4, e1.v2, 
				neighbor_cell.river_surface_y, cell.river_surface_y, cell.water_surface_y)
	
	if (cell.get_edge_type_from_direction(direction) == Enums.HexEdgeType.Slope):
		_triangulate_edge_terraces(e1, cell, e2, neighbor_cell, has_road)
	else:
		_triangulate_edge_strip(e1, cell.hex_color, e2, neighbor_cell.hex_color, has_road)
	
	#Add walls
	_features.add_wall(e1, cell, e2, neighbor_cell, has_river, has_road)
	
	#Get the next neighbor of the cell
	var next_direction = HexDirectionsClass.next(direction)
	var next_neighbor = cell.get_neighbor(next_direction)
	if (direction <= HexDirectionsClass.HexDirections.E) and (next_neighbor != null):
		var v5: Vector3 = e1.v5 + HexMetrics.get_bridge(next_direction)
		v5.y = next_neighbor.position.y
		
		if (cell.elevation <= neighbor_cell.elevation):
			if (cell.elevation <= next_neighbor.elevation):
				_triangulate_corner(e1.v5, cell, e2.v5, neighbor_cell, v5, next_neighbor)
			else:
				_triangulate_corner(v5, next_neighbor, e1.v5, cell, e2.v5, neighbor_cell)
		elif (neighbor_cell.elevation <= next_neighbor.elevation):
			_triangulate_corner(e2.v5, neighbor_cell, v5, next_neighbor, e1.v5, cell)
		else:
			_triangulate_corner(v5, next_neighbor, e1.v5, cell, e2.v5, neighbor_cell)

func _triangulate_edge_terraces (
	begin: EdgeVertices, begin_cell: HexCell,
	end: EdgeVertices, end_cell: HexCell,
	has_road: bool = false):
	
	var e2: EdgeVertices = EdgeVertices.terrace_lerp(begin, end, 1)
	var c2 = HexMetrics.terrace_color_lerp(begin_cell.hex_color, end_cell.hex_color, 1)
	
	_triangulate_edge_strip(begin, begin_cell.hex_color, e2, c2, has_road)
		
	for i in range(2, HexMetrics.TERRACE_STEPS):
		var e1: EdgeVertices = e2
		var c1: Color = c2
		e2 = EdgeVertices.terrace_lerp(begin, end, i)
		c2 = HexMetrics.terrace_color_lerp(begin_cell.hex_color, end_cell.hex_color, i)
		
		_triangulate_edge_strip(e1, c1, e2, c2, has_road)
	
	_triangulate_edge_strip(e2, c2, end, end_cell.hex_color, has_road)

func _triangulate_corner (
	bottom: Vector3, bottom_cell: HexCell, 
	left: Vector3, left_cell: HexCell,
	right: Vector3, right_cell: HexCell) -> void:
	
	#Get the edge types
	var left_edge_type: Enums.HexEdgeType = bottom_cell.get_edge_type_from_other_cell(left_cell)
	var right_edge_type: Enums.HexEdgeType = bottom_cell.get_edge_type_from_other_cell(right_cell)
	
	if left_edge_type == Enums.HexEdgeType.Slope:
		if right_edge_type == Enums.HexEdgeType.Slope:
			_triangulate_corner_terraces(bottom, bottom_cell, left, left_cell, right, right_cell)
		elif right_edge_type == Enums.HexEdgeType.Flat:
			_triangulate_corner_terraces(left, left_cell, right, right_cell, bottom, bottom_cell)
		else:
			_triangulate_corner_terrace_cliff(bottom, bottom_cell, left, left_cell, right, right_cell)	
	elif right_edge_type == Enums.HexEdgeType.Slope:
		if left_edge_type == Enums.HexEdgeType.Flat:
			_triangulate_corner_terraces(right, right_cell, bottom, bottom_cell, left, left_cell)
		else:
			_triangulate_corner_cliff_terrace(bottom, bottom_cell, left, left_cell, right, right_cell)
	elif left_cell.get_edge_type_from_other_cell(right_cell) == Enums.HexEdgeType.Slope:
		if left_cell.elevation < right_cell.elevation:
			_triangulate_corner_cliff_terrace(right, right_cell, bottom, bottom_cell, left, left_cell)
		else:
			_triangulate_corner_terrace_cliff(left, left_cell, right, right_cell, bottom, bottom_cell)
	else:
		_terrain.add_perturbed_triangle(bottom, right, left, bottom_cell.hex_color, right_cell.hex_color, left_cell.hex_color)
	
	#Add walls
	_features.add_wall_three_cells(bottom, bottom_cell, left, left_cell, right, right_cell)

func _triangulate_corner_terraces (
	begin: Vector3, begin_cell: HexCell,
	left: Vector3, left_cell: HexCell,
	right: Vector3, right_cell: HexCell) -> void:
	
	var v3: Vector3 = HexMetrics.terrace_lerp(begin, left, 1)
	var v4: Vector3 = HexMetrics.terrace_lerp(begin, right, 1)
	var c3: Color = HexMetrics.terrace_color_lerp(begin_cell.hex_color, left_cell.hex_color, 1)
	var c4: Color = HexMetrics.terrace_color_lerp(begin_cell.hex_color, right_cell.hex_color, 1)
	
	#The bottom triangle
	_terrain.add_perturbed_triangle(begin, v4, v3, begin_cell.hex_color, c4, c3)
	
	#The steps inbetween
	for i in range(2, HexMetrics.TERRACE_STEPS):
		var v1: Vector3 = v3
		var v2: Vector3 = v4
		var c1: Color = c3
		var c2: Color = c4
		
		v3 = HexMetrics.terrace_lerp(begin, left, i)
		v4 = HexMetrics.terrace_lerp(begin, right, i)
		c3 = HexMetrics.terrace_color_lerp(begin_cell.hex_color, left_cell.hex_color, i)
		c4 = HexMetrics.terrace_color_lerp(begin_cell.hex_color, right_cell.hex_color, i)
		
		_terrain.add_perturbed_quad(v1, v2, v3, v4, c1, c2, c3, c4)
	
	#The top quad
	_terrain.add_perturbed_quad(v3, v4, left, right, c3, c4, left_cell.hex_color, right_cell.hex_color)
	
func _triangulate_corner_terrace_cliff (
	begin: Vector3, begin_cell: HexCell,
	left: Vector3, left_cell: HexCell,
	right: Vector3, right_cell: HexCell) -> void:
	
	var b: float = 1.0 / (right_cell.elevation - begin_cell.elevation)
	if b < 0:
		b = -b
	
	var boundary: Vector3 = HexMetrics.perturb(begin).lerp(HexMetrics.perturb(right), b)
	var boundary_color: Color = begin_cell.hex_color.lerp(right_cell.hex_color, b)
	
	_triangulate_boundary_triangle(begin, begin_cell, left, left_cell, boundary, boundary_color)
	
	if (left_cell.get_edge_type_from_other_cell(right_cell) == Enums.HexEdgeType.Slope):
		_triangulate_boundary_triangle(left, left_cell, right, right_cell, boundary, boundary_color)
	else:
		_terrain.add_triangle(HexMetrics.perturb(left), boundary, HexMetrics.perturb(right), 
			left_cell.hex_color, boundary_color, right_cell.hex_color)

func _triangulate_corner_cliff_terrace (
	begin: Vector3, begin_cell: HexCell,
	left: Vector3, left_cell: HexCell,
	right: Vector3, right_cell: HexCell) -> void:
	
	var b: float = 1.0 / (left_cell.elevation - begin_cell.elevation)
	if b < 0:
		b = -b
	
	var boundary: Vector3 = HexMetrics.perturb(begin).lerp(HexMetrics.perturb(left), b)
	var boundary_color: Color = begin_cell.hex_color.lerp(left_cell.hex_color, b)
	
	_triangulate_boundary_triangle(right, right_cell, begin, begin_cell, boundary, boundary_color)
	
	if (left_cell.get_edge_type_from_other_cell(right_cell) == Enums.HexEdgeType.Slope):
		_triangulate_boundary_triangle(left, left_cell, right, right_cell, boundary, boundary_color)
	else:
		_terrain.add_triangle(HexMetrics.perturb(left), boundary, HexMetrics.perturb(right), 
			left_cell.hex_color, boundary_color, right_cell.hex_color)

func _triangulate_boundary_triangle (
	begin: Vector3, begin_cell: HexCell,
	left: Vector3, left_cell: HexCell,
	boundary: Vector3, boundary_color: Color) -> void:
	
	var v2: Vector3 = HexMetrics.perturb(HexMetrics.terrace_lerp(begin, left, 1))
	var c2: Color = HexMetrics.terrace_color_lerp(begin_cell.hex_color, left_cell.hex_color, 1)
	
	_terrain.add_triangle(HexMetrics.perturb(begin), boundary, v2, begin_cell.hex_color, boundary_color, c2)
	
	for i in range(2, HexMetrics.TERRACE_STEPS):
		var v1: Vector3 = v2
		var c1: Color = c2
		
		v2 = HexMetrics.perturb(HexMetrics.terrace_lerp(begin, left, i))
		c2 = HexMetrics.terrace_color_lerp(begin_cell.hex_color, left_cell.hex_color, i)
		
		_terrain.add_triangle(v1, boundary, v2, c1, boundary_color, c2)
		
	_terrain.add_triangle(v2, boundary, HexMetrics.perturb(left), c2, boundary_color, left_cell.hex_color)

func _triangulate_edge_fan (
	center: Vector3, edge: EdgeVertices, color: Color) -> void:
	
	_terrain.add_perturbed_triangle(center, edge.v2, edge.v1, color, color, color)
	_terrain.add_perturbed_triangle(center, edge.v3, edge.v2, color, color, color)
	_terrain.add_perturbed_triangle(center, edge.v4, edge.v3, color, color, color)
	_terrain.add_perturbed_triangle(center, edge.v5, edge.v4, color, color, color)

func _triangulate_edge_strip (
	e1: EdgeVertices, c1: Color, e2: EdgeVertices, c2: Color,
	has_road: bool = false) -> void:
	
	_terrain.add_perturbed_quad(e1.v1, e1.v2, e2.v1, e2.v2, c1, c1, c2, c2)
	_terrain.add_perturbed_quad(e1.v2, e1.v3, e2.v2, e2.v3, c1, c1, c2, c2)
	_terrain.add_perturbed_quad(e1.v3, e1.v4, e2.v3, e2.v4, c1, c1, c2, c2)
	_terrain.add_perturbed_quad(e1.v4, e1.v5, e2.v4, e2.v5, c1, c1, c2, c2)
	
	if (has_road):
		_triangulate_road_segment(e1.v2, e1.v3, e1.v4, 
			e2.v2, e2.v3, e2.v4)

func _triangulate_river_quad_1 (v1: Vector3, v2: Vector3, 
	v3: Vector3, v4: Vector3, 
	y1: float, v: float, reversed: bool
) -> void:
	
	_triangulate_river_quad_2(v1, v2, v3, v4, y1, y1, v, reversed)

func _triangulate_river_quad_2 (v1: Vector3, v2: Vector3, 
	v3: Vector3, v4: Vector3, 
	y1: float, y2: float, v: float, reversed: bool
) -> void:
	v1.y = y1
	v2.y = y1
	v3.y = y2
	v4.y = y2
	
	#This color will be unused
	var c1: Color = Color.WHITE
	if (reversed):
		_rivers.add_perturbed_quad_with_uv(v1, v2, v3, v4, c1, c1, c1, c1, 1, 0, 0.8 - v, 0.6 - v)
	else:
		_rivers.add_perturbed_quad_with_uv(v1, v2, v3, v4, c1, c1, c1, c1, 0, 1, v, v + 0.2)

func _triangulate_road_segment (v1: Vector3, v2: Vector3, v3: Vector3,
	v4: Vector3, v5: Vector3, v6: Vector3) -> void:
	
	v1.y += 0.01;
	v2.y += 0.01;
	v3.y += 0.01;
	v4.y += 0.01;
	v5.y += 0.01;
	v6.y += 0.01;
	
	_roads.add_perturbed_quad_with_uv(v1, v2, v4, v5, 
		Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE,
		0, 1, 0, 0)
	_roads.add_perturbed_quad_with_uv(v2, v3, v5, v6,
		Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE,
		1, 0, 0, 0)

func _triangulate_road (center: Vector3, mL: Vector3, mR: Vector3, e: EdgeVertices,
	has_road_through_cell_edge: bool) -> void:
	
	if (has_road_through_cell_edge):
		var mC: Vector3 = mL.lerp(mR, 0.5)
		_triangulate_road_segment(mL, mC, mR, e.v2, e.v3, e.v4)
		
		#Raise the road from the terrain slightly
		center.y += 0.01;
		mC.y += 0.01;
		mL.y += 0.01;
		mR.y += 0.01;
		
		#The colors will be ignored for roads
		_roads.add_perturbed_triangle_with_uv(center, mC, mL, 
			Color.WHITE, Color.WHITE, Color.WHITE,
			Vector2(1, 0), Vector2(1, 0), Vector2(0, 0))
		_roads.add_perturbed_triangle_with_uv(center, mR, mC, 
			Color.WHITE, Color.WHITE, Color.WHITE,
			Vector2(1, 0), Vector2(0, 0), Vector2(1, 0))
	else:
		_triangulate_road_edge(center, mL, mR)

func _triangulate_without_river (direction: HexDirectionsClass.HexDirections,
	cell: HexCell, center: Vector3, e: EdgeVertices) -> void:
	
	_triangulate_edge_fan(center, e, cell.hex_color)
	
	if (cell.has_roads):
		var interpolators: Vector2 = _get_road_interpolators(direction, cell)
		
		_triangulate_road(center, 
			center.lerp(e.v1, interpolators.x),
			center.lerp(e.v5, interpolators.y),
			e,
			cell.has_road_through_edge(direction))

func _triangulate_road_edge (center: Vector3, mL: Vector3, mR: Vector3) -> void:
	#Raise the road from the terrain slightly
	center.y += 0.01;
	mR.y += 0.01;
	mL.y += 0.01;
	
	_roads.add_perturbed_triangle_with_uv(center, mR, mL,
		Color.WHITE, Color.WHITE, Color.WHITE,
		Vector2(1, 0), Vector2(0, 0), Vector2(0, 0))

func _triangulate_road_adjacent_to_river (direction: HexDirectionsClass.HexDirections,
	cell: HexCell, center: Vector3, e: EdgeVertices) -> void:
	
	var has_road_through_edge: bool = cell.has_road_through_edge(direction)
	var interpolators: Vector2 = _get_road_interpolators(direction, cell)
	var previous_has_river: bool = cell.has_river_through_edge(HexDirectionsClass.previous(direction))
	var next_has_river: bool = cell.has_river_through_edge(HexDirectionsClass.next(direction))
	var road_center: Vector3 = center
	
	if (cell.has_river_beginning_or_end):
		var dir = cell.river_begin_or_end_direction
		var opp_dir = HexDirectionsClass.opposite(dir)
		road_center += HexMetrics.get_solid_edge_middle(opp_dir) * (1.0 / 3.0)
	elif (cell.incoming_river_direction == HexDirectionsClass.opposite(cell.outgoing_river_direction)):
		var corner: Vector3 = Vector3.ZERO
		if (previous_has_river):
			
			if (not has_road_through_edge) and (not cell.has_road_through_edge(HexDirectionsClass.next(direction))):
				return
			
			corner = HexMetrics.get_second_solid_corner(direction)
		else:
			
			if (not has_road_through_edge) and (not cell.has_road_through_edge(HexDirectionsClass.previous(direction))):
				return
			
			corner = HexMetrics.get_first_solid_corner(direction)
		
		road_center += corner * 0.5
		
		if ((cell.incoming_river_direction == HexDirectionsClass.next(direction)) and 
			(
				(cell.has_road_through_edge(HexDirectionsClass.next2(direction))) or
				(cell.has_road_through_edge(HexDirectionsClass.opposite(direction)))
			)
		):
			
			_features.add_bridge(road_center, center - (corner * 0.5))
		
		center += corner * 0.25
	elif (cell.incoming_river_direction == HexDirectionsClass.previous(cell.outgoing_river_direction)):
		road_center -= HexMetrics.get_second_corner(cell.incoming_river_direction) * 0.2
	elif (cell.incoming_river_direction == HexDirectionsClass.next(cell.outgoing_river_direction)):
		road_center -= HexMetrics.get_first_corner(cell.incoming_river_direction) * 0.2
	elif (previous_has_river and next_has_river):
		if (not has_road_through_edge):
			return
			
		var offset: Vector3 = HexMetrics.get_solid_edge_middle(direction) * HexMetrics.INNER_TO_OUTER
		road_center += offset * 0.7
		center += offset * 0.5
	else:
		var middle: HexDirectionsClass.HexDirections
		if previous_has_river:
			middle = HexDirectionsClass.next(direction)
		elif next_has_river:
			middle = HexDirectionsClass.previous(direction)
		else:
			middle = direction
		
		if (
			(not cell.has_road_through_edge(middle)) and 
			(not cell.has_road_through_edge(HexDirectionsClass.previous(middle))) and
			(not cell.has_road_through_edge(HexDirectionsClass.next(middle)))
		):
			return
		
		var offset: Vector3 = HexMetrics.get_solid_edge_middle(middle)
		road_center += offset * 0.25
		
		if (direction == middle) and (cell.has_road_through_edge(HexDirectionsClass.opposite(direction))):
			_features.add_bridge(road_center, center - offset * (HexMetrics.INNER_TO_OUTER * 0.7))
		
	
	var mL: Vector3 = road_center.lerp(e.v1, interpolators.x)
	var mR: Vector3 = road_center.lerp(e.v5, interpolators.y)
	
	_triangulate_road(road_center, mL, mR, e, has_road_through_edge)
	
	var previous_direction: HexDirectionsClass.HexDirections = HexDirectionsClass.previous(direction)
	var next_direction: HexDirectionsClass.HexDirections = HexDirectionsClass.next(direction)
	
	if (previous_has_river):
		_triangulate_road_edge(road_center, center, mL)
	if (next_has_river):
		_triangulate_road_edge(road_center, mR, center)

func _get_road_interpolators (direction: HexDirectionsClass.HexDirections,
	cell: HexCell) -> Vector2:
	
	#Instantiate the object that will hold the result
	var interpolators: Vector2
	
	if (cell.has_road_through_edge(direction)):
		interpolators.x = 0.5
		interpolators.y = 0.5
	else:
		var previous_direction: HexDirectionsClass.HexDirections = HexDirectionsClass.previous(direction)
		var next_direction: HexDirectionsClass.HexDirections = HexDirectionsClass.next(direction)
		
		if (cell.has_road_through_edge(previous_direction)):
			interpolators.x = 0.5
		else:
			interpolators.x = 0.25
		
		if (cell.has_road_through_edge(next_direction)):
			interpolators.y = 0.5
		else:
			interpolators.y = 0.25
	
	#Return the result
	return interpolators

func _triangulate_water (direction: HexDirectionsClass.HexDirections, cell: HexCell, center: Vector3) -> void:
	
	center.y = cell.water_surface_y
	
	var neighbor: HexCell = cell.get_neighbor(direction)
	if (neighbor != null) and (not neighbor.is_underwater):
		_triangulate_shore_water(direction, cell, neighbor, center)
	else:
		_triangulate_open_water(direction, cell, neighbor, center)

func _triangulate_open_water (direction: HexDirectionsClass.HexDirections,
	cell: HexCell, neighbor: HexCell, center: Vector3) -> void:
	
	var c1: Vector3 = center + HexMetrics.get_first_water_corner(direction)
	var c2: Vector3 = center + HexMetrics.get_second_water_corner(direction)

	_water.add_perturbed_triangle(center, c2, c1, 
		Color.WHITE, Color.WHITE, Color.WHITE,
		)
	
	if (direction <= HexDirectionsClass.HexDirections.SE) and (neighbor != null):
		var bridge: Vector3 = HexMetrics.get_water_bridge(direction)
		var e1: Vector3 = c1 + bridge
		var e2: Vector3 = c2 + bridge
		
		_water.add_perturbed_quad(c1, c2, e1, e2, 
			Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE)
		
		if (direction <= HexDirectionsClass.HexDirections.E):
			var next_neighbor: HexCell = cell.get_neighbor(HexDirectionsClass.next(direction))
			if (next_neighbor == null) or (not next_neighbor.is_underwater):
				return
			
			_water.add_perturbed_triangle(c2, 
				c2 + HexMetrics.get_water_bridge(HexDirectionsClass.next(direction)), 
				e2, Color.WHITE, Color.WHITE, Color.WHITE)

func _triangulate_shore_water (direction: HexDirectionsClass.HexDirections,
	cell: HexCell, neighbor: HexCell, center: Vector3) -> void:
	
	var e1: EdgeVertices = EdgeVertices.new(
		center + HexMetrics.get_first_water_corner(direction),
		center + HexMetrics.get_second_water_corner(direction)
	)
	
	_water.add_perturbed_triangle(center, e1.v2, e1.v1,
		Color.WHITE, Color.WHITE, Color.WHITE)
	_water.add_perturbed_triangle(center, e1.v3, e1.v2,
		Color.WHITE, Color.WHITE, Color.WHITE)
	_water.add_perturbed_triangle(center, e1.v4, e1.v3,
		Color.WHITE, Color.WHITE, Color.WHITE)
	_water.add_perturbed_triangle(center, e1.v5, e1.v4,
		Color.WHITE, Color.WHITE, Color.WHITE)
	
	var center2: Vector3 = neighbor.position
	center2.y = center.y
	var e2: EdgeVertices = EdgeVertices.new(
		center2 + HexMetrics.get_second_solid_corner(HexDirectionsClass.opposite(direction)),
		center2 + HexMetrics.get_first_solid_corner(HexDirectionsClass.opposite(direction))
	)
	
	if (cell.has_river_through_edge(direction)):
		_triangulate_estuary(e1, e2, cell.incoming_river_direction == direction)
	else:
		_water_shore.add_perturbed_quad_with_uv(e1.v1, e1.v2, e2.v1, e2.v2,
			Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE,
			0, 0, 0, 1)
		_water_shore.add_perturbed_quad_with_uv(e1.v2, e1.v3, e2.v2, e2.v3,
			Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE,
			0, 0, 0, 1)
		_water_shore.add_perturbed_quad_with_uv(e1.v3, e1.v4, e2.v3, e2.v4,
			Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE,
			0, 0, 0, 1)
		_water_shore.add_perturbed_quad_with_uv(e1.v4, e1.v5, e2.v4, e2.v5,
			Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE,
			0, 0, 0, 1)
		
	var next_neighbor: HexCell = cell.get_neighbor(HexDirectionsClass.next(direction))
	if (next_neighbor != null):
		var v3: Vector3 = next_neighbor.position
		if (next_neighbor.is_underwater):
			v3 += HexMetrics.get_first_water_corner(HexDirectionsClass.previous(direction))
		else:
			v3 += HexMetrics.get_first_solid_corner(HexDirectionsClass.previous(direction))
		v3.y = center.y
		
		var v_val: float = 1.0
		if (next_neighbor.is_underwater):
			v_val = 0.0
		
		_water_shore.add_perturbed_triangle_with_uv(e1.v5, 
			v3,
			e2.v5,
			Color.WHITE, Color.WHITE, Color.WHITE,
			Vector2(0, 0), 
			Vector2(0, v_val), 
			Vector2(0, 1))

func _triangulate_waterfall_in_water (v1: Vector3, v2: Vector3, v3: Vector3, v4: Vector3,
	y1: float, y2: float, water_y: float) -> void:
	
	v1.y = y1
	v2.y = y1
	v3.y = y2
	v4.y = y2
	
	v1 = HexMetrics.perturb(v1)
	v2 = HexMetrics.perturb(v2)
	v3 = HexMetrics.perturb(v3)
	v4 = HexMetrics.perturb(v4)
	
	var t: float = (water_y - y2) / (y1 - y2)
	v3 = v3.lerp(v1, t);
	v4 = v4.lerp(v2, t);
	
	_rivers.add_quad_with_uv(v1, v2, v3, v4,
		Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE,
		0, 1, 0.8, 1)

func _triangulate_estuary (e1: EdgeVertices, e2: EdgeVertices, incoming_river: bool) -> void:
	_water_shore.add_perturbed_triangle_with_uv(e2.v1, e1.v1, e1.v2,
		Color.WHITE, Color.WHITE, Color.WHITE,
		Vector2(0, 1), Vector2(0, 0), Vector2(0, 0))
	_water_shore.add_perturbed_triangle_with_uv(e2.v5, e1.v4, e1.v5,
		Color.WHITE, Color.WHITE, Color.WHITE,
		Vector2(0, 1), Vector2(0, 0), Vector2(0, 0))
	
	if (incoming_river):
		_estuaries.add_perturbed_quad_with_uv_and_uv2_vectors(
			e2.v1, e1.v2, e2.v2, e1.v3,
			Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE,
			Vector2(0, 1), Vector2(0, 0), Vector2(1, 1), Vector2(0, 0),
			Vector2(1.5, 1), Vector2(0.7, 1.15), Vector2(1, 0.8), Vector2(0.5, 1.1)
		)
		
		_estuaries.add_perturbed_triangle_with_uv_and_uv2(
			e1.v3, e2.v4, e2.v2, 
			Color.WHITE, Color.WHITE, Color.WHITE,
			Vector2(0, 0), Vector2(1, 1), Vector2(1, 1),
			Vector2(0.5, 1.1), Vector2(0, 0.8), Vector2(1, 0.8)
		)
		
		_estuaries.add_perturbed_quad_with_uv_and_uv2_vectors(
			e1.v3, e1.v4, e2.v4, e2.v5,
			Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE,
			Vector2(0, 0), Vector2(0, 0), Vector2(1, 1), Vector2(0, 1),
			Vector2(0.5, 1.1), Vector2(0.3, 1.15), Vector2(0, 0.8), Vector2(-0.5, 1)
		)
	else:
		_estuaries.add_perturbed_quad_with_uv_and_uv2_vectors(
			e2.v1, e1.v2, e2.v2, e1.v3,
			Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE,
			Vector2(0, 1), Vector2(0, 0), Vector2(1, 1), Vector2(0, 0),
			Vector2(-0.5, -0.2), Vector2(0.3, -0.35), Vector2(0, 0), Vector2(0.5, -0.3)
		)
		
		_estuaries.add_perturbed_triangle_with_uv_and_uv2(
			e1.v3, e2.v4, e2.v2, 
			Color.WHITE, Color.WHITE, Color.WHITE,
			Vector2(0, 0), Vector2(1, 1), Vector2(1, 1),
			Vector2(0.5, -0.3), Vector2(1, 0), Vector2(0, 0)
		)
		
		_estuaries.add_perturbed_quad_with_uv_and_uv2_vectors(
			e1.v3, e1.v4, e2.v4, e2.v5,
			Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE,
			Vector2(0, 0), Vector2(0, 0), Vector2(1, 1), Vector2(0, 1),
			Vector2(0.5, -0.3), Vector2(0.7, -0.35), Vector2(1, 0), Vector2(1.5, -0.2)
		)
	
	

#endregion




























#region file whitespace region
#endregion
