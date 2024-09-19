class_name HexMesh
extends MeshInstance3D

#region Overrides

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
#endregion

#region Public methods

func triangulate_cells (cells: Array[HexCell], mat: ShaderMaterial) -> void:
	#Get an instance of the surface tool
	var surface_tool = SurfaceTool.new();
	
	#Begin creating the mesh
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES);
	
	#Set the smooth group to -1, which produces flat normals for the mesh
	surface_tool.set_smooth_group(-1)
	
	for i in range(0, len(cells)):
		_triangulate_hex(surface_tool, cells[i])
	
	#Generate the normals for the mesh
	surface_tool.generate_normals()
	
	#Generate the tangents for the mesh
	surface_tool.generate_tangents()
	
	#Commit the mesh
	self.mesh = surface_tool.commit()
	
	#Create the collision object for the mesh
	self.create_trimesh_collision()
	
	#Set the material for the mesh
	self.material_override = mat

#endregion

#region Private methods

func _triangulate_hex (st: SurfaceTool, cell: HexCell) -> void:
	#Iterate over each of the 6 directions from the center of the hex
	for i in range(0, 6):
		#Form the mesh for this direction of the hex
		_triangulate_hex_in_direction(st, cell, i)
	
func _triangulate_hex_in_direction (st: SurfaceTool, cell: HexCell, direction: HexDirectionsClass.HexDirections) -> void:
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
				_triangulate_with_river_begin_or_end(st, direction, cell, center, edge_vertices)
			else:
				_triangulate_with_river(st, direction, cell, center, edge_vertices)
		else:
			_triangulate_adjacent_to_river(st, direction, cell, center, edge_vertices)
	else:
		_triangulate_edge_fan(st, center, edge_vertices, cell.hex_color)
	
	#Add connections to other hex cells
	if (direction <= HexDirectionsClass.HexDirections.SE):
		_triangulate_connection(st, direction, cell, edge_vertices)

func _triangulate_with_river_begin_or_end (st: SurfaceTool,
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
	_triangulate_edge_strip(st, m, cell.hex_color, e, cell.hex_color)
	_triangulate_edge_fan(st, center, m, cell.hex_color)

func _triangulate_with_river (st: SurfaceTool, 
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
	_triangulate_edge_strip(st, m, cell.hex_color, e, cell.hex_color)
	
	#Second section of trapezoid
	_add_perturbed_triangle(st, center_l, m.v2, m.v1, cell.hex_color, cell.hex_color, cell.hex_color)
	_add_perturbed_quad(st, center_l, center, m.v2, m.v3, cell.hex_color, cell.hex_color, cell.hex_color, cell.hex_color)
	_add_perturbed_quad(st, center, center_r, m.v3, m.v4, cell.hex_color, cell.hex_color, cell.hex_color, cell.hex_color)
	_add_perturbed_triangle(st, center_r, m.v5, m.v4, cell.hex_color, cell.hex_color, cell.hex_color)

func _triangulate_adjacent_to_river (st: SurfaceTool,
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
	
	_triangulate_edge_strip(st, m, cell.hex_color, e, cell.hex_color)
	_triangulate_edge_fan(st, center, m, cell.hex_color)

func _add_triangle (st: SurfaceTool, v1: Vector3, v2: Vector3, v3: Vector3, c1: Color, c2: Color, c3: Color) -> void:
	#Set the color for the vertex, and then add the vertex
	st.set_color(c1)
	st.add_vertex(v1)
	
	#Set the color for the vertex, and then add the vertex
	st.set_color(c2)
	st.add_vertex(v2)
	
	#Set the color for the vertex, and then add the vertex
	st.set_color(c3)
	st.add_vertex(v3)
	
func _add_perturbed_triangle (st: SurfaceTool, v1: Vector3, v2: Vector3, v3: Vector3, c1: Color, c2: Color, c3: Color) -> void:
	#Set the color for the vertex, and then add the vertex
	st.set_color(c1)
	st.add_vertex(_perturb(v1))
	
	#Set the color for the vertex, and then add the vertex
	st.set_color(c2)
	st.add_vertex(_perturb(v2))
	
	#Set the color for the vertex, and then add the vertex
	st.set_color(c3)
	st.add_vertex(_perturb(v3))

func _add_quad (st: SurfaceTool, v1: Vector3, v2: Vector3, v3: Vector3, v4: Vector3, c1: Color, c2: Color, c3: Color, c4: Color) -> void:
	_add_triangle(st, v1, v2, v3, c1, c2, c3)
	_add_triangle(st, v2, v4, v3, c2, c4, c3)
	
func _add_perturbed_quad (st: SurfaceTool, v1: Vector3, v2: Vector3, v3: Vector3, v4: Vector3, c1: Color, c2: Color, c3: Color, c4: Color) -> void:
	_add_perturbed_triangle(st, v1, v2, v3, c1, c2, c3)
	_add_perturbed_triangle(st, v2, v4, v3, c2, c4, c3)

func _triangulate_connection (st: SurfaceTool, 
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
	
	if (cell.get_edge_type_from_direction(direction) == Enums.HexEdgeType.Slope):
		_triangulate_edge_terraces(st, e1, cell, e2, neighbor_cell)
	else:
		_triangulate_edge_strip(st, e1, cell.hex_color, e2, neighbor_cell.hex_color)
	
	#Get the next neighbor of the cell
	var next_direction = HexDirectionsClass.next(direction)
	var next_neighbor = cell.get_neighbor(next_direction)
	if (direction <= HexDirectionsClass.HexDirections.E) and (next_neighbor != null):
		var v5: Vector3 = e1.v5 + HexMetrics.get_bridge(next_direction)
		v5.y = next_neighbor.position.y
		
		if (cell.elevation <= neighbor_cell.elevation):
			if (cell.elevation <= next_neighbor.elevation):
				_triangulate_corner(st, e1.v5, cell, e2.v5, neighbor_cell, v5, next_neighbor)
			else:
				_triangulate_corner(st, v5, next_neighbor, e1.v5, cell, e2.v5, neighbor_cell)
		elif (neighbor_cell.elevation <= next_neighbor.elevation):
			_triangulate_corner(st, e2.v5, neighbor_cell, v5, next_neighbor, e1.v5, cell)
		else:
			_triangulate_corner(st, v5, next_neighbor, e1.v5, cell, e2.v5, neighbor_cell)

func _triangulate_edge_terraces (st: SurfaceTool,
	begin: EdgeVertices, begin_cell: HexCell,
	end: EdgeVertices, end_cell: HexCell):
	
	var e2: EdgeVertices = EdgeVertices.terrace_lerp(begin, end, 1)
	var c2 = HexMetrics.terrace_color_lerp(begin_cell.hex_color, end_cell.hex_color, 1)
	
	_triangulate_edge_strip(st, begin, begin_cell.hex_color, e2, c2)
		
	for i in range(2, HexMetrics.TERRACE_STEPS):
		var e1: EdgeVertices = e2
		var c1: Color = c2
		e2 = EdgeVertices.terrace_lerp(begin, end, i)
		c2 = HexMetrics.terrace_color_lerp(begin_cell.hex_color, end_cell.hex_color, i)
		
		_triangulate_edge_strip(st, e1, c1, e2, c2)
	
	_triangulate_edge_strip(st, e2, c2, end, end_cell.hex_color)

func _triangulate_corner (st: SurfaceTool, 
	bottom: Vector3, bottom_cell: HexCell, 
	left: Vector3, left_cell: HexCell,
	right: Vector3, right_cell: HexCell) -> void:
	
	#Get the edge types
	var left_edge_type: Enums.HexEdgeType = bottom_cell.get_edge_type_from_other_cell(left_cell)
	var right_edge_type: Enums.HexEdgeType = bottom_cell.get_edge_type_from_other_cell(right_cell)
	
	if left_edge_type == Enums.HexEdgeType.Slope:
		if right_edge_type == Enums.HexEdgeType.Slope:
			_triangulate_corner_terraces(st, bottom, bottom_cell, left, left_cell, right, right_cell)
		elif right_edge_type == Enums.HexEdgeType.Flat:
			_triangulate_corner_terraces(st, left, left_cell, right, right_cell, bottom, bottom_cell)
		else:
			_triangulate_corner_terrace_cliff(st, bottom, bottom_cell, left, left_cell, right, right_cell)	
	elif right_edge_type == Enums.HexEdgeType.Slope:
		if left_edge_type == Enums.HexEdgeType.Flat:
			_triangulate_corner_terraces(st, right, right_cell, bottom, bottom_cell, left, left_cell)
		else:
			_triangulate_corner_cliff_terrace(st, bottom, bottom_cell, left, left_cell, right, right_cell)
	elif left_cell.get_edge_type_from_other_cell(right_cell) == Enums.HexEdgeType.Slope:
		if left_cell.elevation < right_cell.elevation:
			_triangulate_corner_cliff_terrace(st, right, right_cell, bottom, bottom_cell, left, left_cell)
		else:
			_triangulate_corner_terrace_cliff(st, left, left_cell, right, right_cell, bottom, bottom_cell)
	else:
		_add_perturbed_triangle(st, bottom, right, left, bottom_cell.hex_color, right_cell.hex_color, left_cell.hex_color)

func _triangulate_corner_terraces (st: SurfaceTool, 
	begin: Vector3, begin_cell: HexCell,
	left: Vector3, left_cell: HexCell,
	right: Vector3, right_cell: HexCell) -> void:
	
	var v3: Vector3 = HexMetrics.terrace_lerp(begin, left, 1)
	var v4: Vector3 = HexMetrics.terrace_lerp(begin, right, 1)
	var c3: Color = HexMetrics.terrace_color_lerp(begin_cell.hex_color, left_cell.hex_color, 1)
	var c4: Color = HexMetrics.terrace_color_lerp(begin_cell.hex_color, right_cell.hex_color, 1)
	
	#The bottom triangle
	_add_perturbed_triangle(st, begin, v4, v3, begin_cell.hex_color, c4, c3)
	
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
		
		_add_perturbed_quad(st, v1, v2, v3, v4, c1, c2, c3, c4)
	
	#The top quad
	_add_perturbed_quad(st, v3, v4, left, right, c3, c4, left_cell.hex_color, right_cell.hex_color)
	
func _triangulate_corner_terrace_cliff (st: SurfaceTool, 
	begin: Vector3, begin_cell: HexCell,
	left: Vector3, left_cell: HexCell,
	right: Vector3, right_cell: HexCell) -> void:
	
	var b: float = 1.0 / (right_cell.elevation - begin_cell.elevation)
	if b < 0:
		b = -b
	
	var boundary: Vector3 = _perturb(begin).lerp(_perturb(right), b)
	var boundary_color: Color = begin_cell.hex_color.lerp(right_cell.hex_color, b)
	
	_triangulate_boundary_triangle(st, begin, begin_cell, left, left_cell, boundary, boundary_color)
	
	if (left_cell.get_edge_type_from_other_cell(right_cell) == Enums.HexEdgeType.Slope):
		_triangulate_boundary_triangle(st, left, left_cell, right, right_cell, boundary, boundary_color)
	else:
		_add_triangle(st, _perturb(left), boundary, _perturb(right), 
			left_cell.hex_color, boundary_color, right_cell.hex_color)

func _triangulate_corner_cliff_terrace (st: SurfaceTool, 
	begin: Vector3, begin_cell: HexCell,
	left: Vector3, left_cell: HexCell,
	right: Vector3, right_cell: HexCell) -> void:
	
	var b: float = 1.0 / (left_cell.elevation - begin_cell.elevation)
	if b < 0:
		b = -b
	
	var boundary: Vector3 = _perturb(begin).lerp(_perturb(left), b)
	var boundary_color: Color = begin_cell.hex_color.lerp(left_cell.hex_color, b)
	
	_triangulate_boundary_triangle(st, right, right_cell, begin, begin_cell, boundary, boundary_color)
	
	if (left_cell.get_edge_type_from_other_cell(right_cell) == Enums.HexEdgeType.Slope):
		_triangulate_boundary_triangle(st, left, left_cell, right, right_cell, boundary, boundary_color)
	else:
		_add_triangle(st, _perturb(left), boundary, _perturb(right), 
			left_cell.hex_color, boundary_color, right_cell.hex_color)

func _triangulate_boundary_triangle (st: SurfaceTool,
	begin: Vector3, begin_cell: HexCell,
	left: Vector3, left_cell: HexCell,
	boundary: Vector3, boundary_color: Color) -> void:
	
	var v2: Vector3 = _perturb(HexMetrics.terrace_lerp(begin, left, 1))
	var c2: Color = HexMetrics.terrace_color_lerp(begin_cell.hex_color, left_cell.hex_color, 1)
	
	_add_triangle(st, _perturb(begin), boundary, v2, begin_cell.hex_color, boundary_color, c2)
	
	for i in range(2, HexMetrics.TERRACE_STEPS):
		var v1: Vector3 = v2
		var c1: Color = c2
		
		v2 = _perturb(HexMetrics.terrace_lerp(begin, left, i))
		c2 = HexMetrics.terrace_color_lerp(begin_cell.hex_color, left_cell.hex_color, i)
		
		_add_triangle(st, v1, boundary, v2, c1, boundary_color, c2)
		
	_add_triangle(st, v2, boundary, _perturb(left), c2, boundary_color, left_cell.hex_color)

func _triangulate_edge_fan (st: SurfaceTool,
	center: Vector3, edge: EdgeVertices, color: Color) -> void:
	
	_add_perturbed_triangle(st, center, edge.v2, edge.v1, color, color, color)
	_add_perturbed_triangle(st, center, edge.v3, edge.v2, color, color, color)
	_add_perturbed_triangle(st, center, edge.v4, edge.v3, color, color, color)
	_add_perturbed_triangle(st, center, edge.v5, edge.v4, color, color, color)

func _triangulate_edge_strip (st: SurfaceTool,
	e1: EdgeVertices, c1: Color, e2: EdgeVertices, c2: Color) -> void:
	
	_add_perturbed_quad(st, e1.v1, e1.v2, e2.v1, e2.v2, c1, c1, c2, c2)
	_add_perturbed_quad(st, e1.v2, e1.v3, e2.v2, e2.v3, c1, c1, c2, c2)
	_add_perturbed_quad(st, e1.v3, e1.v4, e2.v3, e2.v4, c1, c1, c2, c2)
	_add_perturbed_quad(st, e1.v4, e1.v5, e2.v4, e2.v5, c1, c1, c2, c2)

func _perturb (pos: Vector3) -> Vector3:
	#Get a 4D noise sample
	var sample: Vector4 = HexMetrics.sample_noise(pos * HexMetrics.CELL_PERTURB_POSITION_MULTIPLIER)
	
	pos.x += (sample.x * 2.0 - 1.0) * HexMetrics.CELL_PERTURB_STRENGTH
	pos.z += (sample.z * 2.0 - 1.0) * HexMetrics.CELL_PERTURB_STRENGTH
	
	return pos

#endregion
