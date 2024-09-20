class_name HexGridChunk
extends Node3D

#region Private data members

## This is a list that contains each HexCell object in the grid
var _hex_cells: Array[HexCell] = []

var _terrain: HexMesh = HexMesh.new()
var _rivers: HexMesh = HexMesh.new()
var _roads: HexMesh = HexMesh.new()

var _terrain_shader_material: ShaderMaterial
var _rivers_shader_material: ShaderMaterial
var _road_shader_material: ShaderMaterial

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
	
	#Iterate over each hex cell and triangulate the mesh for that hex
	for i in range(0, len(_hex_cells)):
		_triangulate_hex(_hex_cells[i])
	
	#Finalize the creation of the terrain mesh
	_terrain.end(_terrain_shader_material)
	
	#Finalize the creation of the rivers mesh
	_rivers.end(_rivers_shader_material)
	
	#Finalize the creation of the roads mesh
	_roads.end(_road_shader_material)

func _triangulate_hex (cell: HexCell) -> void:
	#Iterate over each of the 6 directions from the center of the hex
	for i in range(0, 6):
		#Form the mesh for this direction of the hex
		_triangulate_hex_in_direction(cell, i)
	
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
	
	#Add connections to other hex cells
	if (direction <= HexDirectionsClass.HexDirections.SE):
		_triangulate_connection(direction, cell, edge_vertices)

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
	var reversed: bool = (cell.incoming_river_direction == direction)
	_triangulate_river_quad_1(center_l, center_r, m.v2, m.v4, cell.river_surface_y, 0.4, reversed)
	_triangulate_river_quad_1(m.v2, m.v4, e.v2, e.v4, cell.river_surface_y, 0.6, reversed)

func _triangulate_adjacent_to_river (
	direction: HexDirectionsClass.HexDirections, cell: HexCell,
	center: Vector3, e: EdgeVertices) -> void:
	
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
	
	if (cell.has_river_through_edge(direction)):
		e2.v3.y = neighbor_cell.stream_bed_y
		
		var reversed: bool = (cell.has_incoming_river and (cell.incoming_river_direction == direction))
		_triangulate_river_quad_2(e1.v2, e1.v4, e2.v2, e2.v4,
			cell.river_surface_y, neighbor_cell.river_surface_y,
			0.8, reversed)
	
	if (cell.get_edge_type_from_direction(direction) == Enums.HexEdgeType.Slope):
		_triangulate_edge_terraces(e1, cell, e2, neighbor_cell,
			cell.has_road_through_edge(direction))
	else:
		_triangulate_edge_strip(e1, cell.hex_color, e2, neighbor_cell.hex_color,
			cell.has_road_through_edge(direction))
	
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
		
		#The colors will be ignored for roads
		_roads.add_perturbed_triangle_with_uv(center, mC, mL, 
			Color.WHITE, Color.WHITE, Color.WHITE,
			Vector2(1, 0), Vector2(0, 0), Vector2(1, 0))
		_roads.add_perturbed_triangle_with_uv(center, mR, mC, 
			Color.WHITE, Color.WHITE, Color.WHITE,
			Vector2(1, 0), Vector2(1, 0), Vector2(0, 0))
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
	_roads.add_perturbed_triangle_with_uv(center, mR, mL,
		Color.WHITE, Color.WHITE, Color.WHITE,
		Vector2(1, 0), Vector2(0, 0), Vector2(0, 0))

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

#endregion
