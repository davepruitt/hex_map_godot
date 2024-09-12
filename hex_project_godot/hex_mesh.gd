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
	var p1 = center + HexMetrics.get_first_solid_corner(direction)
	var p2 = center + HexMetrics.get_second_solid_corner(direction)
	
	center.y = cell.elevation * HexMetrics.ELEVATION_STEP
	p1.y = cell.elevation * HexMetrics.ELEVATION_STEP
	p2.y = cell.elevation * HexMetrics.ELEVATION_STEP
	
	#Add the triangle
	_add_triangle(st, center, p2, p1, cell.hex_color, cell.hex_color, cell.hex_color)
	
	#Add connections to other hex cells
	if (direction <= HexDirectionsClass.HexDirections.SE):
		_triangulate_connection(st, direction, cell, p1, p2)

func _add_triangle (st: SurfaceTool, v1: Vector3, v2: Vector3, v3: Vector3, c1: Color, c2: Color, c3: Color) -> void:
	#Set the color for the vertex, and then add the vertex
	st.set_color(c1)
	st.add_vertex(_perturb(v1))
	#st.add_vertex(v1)
	
	#Set the color for the vertex, and then add the vertex
	st.set_color(c2)
	st.add_vertex(_perturb(v2))
	#st.add_vertex(v2)
	
	#Set the color for the vertex, and then add the vertex
	st.set_color(c3)
	st.add_vertex(_perturb(v3))
	#st.add_vertex(v3)

func _add_quad (st: SurfaceTool, v1: Vector3, v2: Vector3, v3: Vector3, v4: Vector3, c1: Color, c2: Color, c3: Color, c4: Color) -> void:
	_add_triangle(st, v1, v2, v3, c1, c2, c3)
	_add_triangle(st, v2, v4, v3, c2, c4, c3)

func _triangulate_connection (st: SurfaceTool, direction: HexDirectionsClass.HexDirections, cell: HexCell, v1: Vector3, v2: Vector3) -> void:
	#Get the neighboring cell in the specified direction
	var neighbor_cell = cell.get_neighbor(direction)
	
	#If the neighboring cell is null, then fail out of the function
	if (neighbor_cell == null):
		return
	
	var bridge = HexMetrics.get_bridge(direction)
	var v3 = v1 + bridge
	var v4 = v2 + bridge
	
	v3.y = neighbor_cell.elevation * HexMetrics.ELEVATION_STEP
	v4.y = v3.y
	
	if (cell.get_edge_type_from_direction(direction) == Enums.HexEdgeType.Slope):
		pass
		_triangulate_edge_terraces(st, v1, v2, cell, v3, v4, neighbor_cell)
	else:
		_add_quad(st, v1, v2, v3, v4, cell.hex_color, cell.hex_color, neighbor_cell.hex_color, neighbor_cell.hex_color)
	
	#Get the next neighbor of the cell
	var next_direction = HexDirectionsClass.next(direction)
	var next_neighbor = cell.get_neighbor(next_direction)
	if (direction <= HexDirectionsClass.HexDirections.E) and (next_neighbor != null):
		var v5 = v2 + HexMetrics.get_bridge(next_direction)
		v5.y = next_neighbor.elevation * HexMetrics.ELEVATION_STEP
		
		if (cell.elevation <= neighbor_cell.elevation):
			if (cell.elevation <= next_neighbor.elevation):
				_triangulate_corner(st, v2, cell, v4, neighbor_cell, v5, next_neighbor)
			else:
				_triangulate_corner(st, v5, next_neighbor, v2, cell, v4, neighbor_cell)
		elif (neighbor_cell.elevation <= next_neighbor.elevation):
			_triangulate_corner(st, v4, neighbor_cell, v5, next_neighbor, v2, cell)
		else:
			_triangulate_corner(st, v5, next_neighbor, v2, cell, v4, neighbor_cell)

func _triangulate_edge_terraces (st: SurfaceTool,
	begin_left: Vector3, begin_right: Vector3, begin_cell: HexCell,
	end_left: Vector3, end_right: Vector3, end_cell: HexCell):
	
	var v3 = HexMetrics.terrace_lerp(begin_left, end_left, 1)
	var v4 = HexMetrics.terrace_lerp(begin_right, end_right, 1)
	var c2 = HexMetrics.terrace_color_lerp(begin_cell.hex_color, end_cell.hex_color, 1)
	
	_add_quad(st, 
		begin_left, begin_right, 
		v3, v4, 
		begin_cell.hex_color, begin_cell.hex_color, 
		c2, c2)
		
	for i in range(2, HexMetrics.TERRACE_STEPS):
		var v1 = v3
		var v2 = v4
		var c1 = c2
		
		v3 = HexMetrics.terrace_lerp(begin_left, end_left, i)
		v4 = HexMetrics.terrace_lerp(begin_right, end_right, i)
		c2 = HexMetrics.terrace_color_lerp(begin_cell.hex_color, end_cell.hex_color, i)
		
		_add_quad(st,
			v1, v2, v3, v4,
			c1, c1, c2, c2)
		
	_add_quad(st,
		v3, v4,
		end_left, end_right,
		c2, c2,
		end_cell.hex_color, end_cell.hex_color)

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
		_add_triangle(st, bottom, right, left, bottom_cell.hex_color, right_cell.hex_color, left_cell.hex_color)

func _triangulate_corner_terraces (st: SurfaceTool, 
	begin: Vector3, begin_cell: HexCell,
	left: Vector3, left_cell: HexCell,
	right: Vector3, right_cell: HexCell) -> void:
	
	var v3: Vector3 = HexMetrics.terrace_lerp(begin, left, 1)
	var v4: Vector3 = HexMetrics.terrace_lerp(begin, right, 1)
	var c3: Color = HexMetrics.terrace_color_lerp(begin_cell.hex_color, left_cell.hex_color, 1)
	var c4: Color = HexMetrics.terrace_color_lerp(begin_cell.hex_color, right_cell.hex_color, 1)
	
	#The bottom triangle
	_add_triangle(st, begin, v4, v3, begin_cell.hex_color, c4, c3)
	
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
		
		_add_quad(st, v1, v2, v3, v4, c1, c2, c3, c4)
	
	#The top quad
	_add_quad(st, v3, v4, left, right, c3, c4, left_cell.hex_color, right_cell.hex_color)
	
func _triangulate_corner_terrace_cliff (st: SurfaceTool, 
	begin: Vector3, begin_cell: HexCell,
	left: Vector3, left_cell: HexCell,
	right: Vector3, right_cell: HexCell) -> void:
	
	var b: float = 1.0 / (right_cell.elevation - begin_cell.elevation)
	if b < 0:
		b = -b
	
	var boundary: Vector3 = begin.lerp(right, b)
	var boundary_color: Color = begin_cell.hex_color.lerp(right_cell.hex_color, b)
	
	_triangulate_boundary_triangle(st, begin, begin_cell, left, left_cell, boundary, boundary_color)
	
	if (left_cell.get_edge_type_from_other_cell(right_cell) == Enums.HexEdgeType.Slope):
		_triangulate_boundary_triangle(st, left, left_cell, right, right_cell, boundary, boundary_color)
	else:
		_add_triangle(st, left, boundary, right, left_cell.hex_color, boundary_color, right_cell.hex_color)

func _triangulate_corner_cliff_terrace (st: SurfaceTool, 
	begin: Vector3, begin_cell: HexCell,
	left: Vector3, left_cell: HexCell,
	right: Vector3, right_cell: HexCell) -> void:
	
	var b: float = 1.0 / (left_cell.elevation - begin_cell.elevation)
	if b < 0:
		b = -b
	
	var boundary: Vector3 = begin.lerp(left, b)
	var boundary_color: Color = begin_cell.hex_color.lerp(left_cell.hex_color, b)
	
	_triangulate_boundary_triangle(st, right, right_cell, begin, begin_cell, boundary, boundary_color)
	
	if (left_cell.get_edge_type_from_other_cell(right_cell) == Enums.HexEdgeType.Slope):
		_triangulate_boundary_triangle(st, left, left_cell, right, right_cell, boundary, boundary_color)
	else:
		_add_triangle(st, left, boundary, right, left_cell.hex_color, boundary_color, right_cell.hex_color)

func _triangulate_boundary_triangle (st: SurfaceTool,
	begin: Vector3, begin_cell: HexCell,
	left: Vector3, left_cell: HexCell,
	boundary: Vector3, boundary_color: Color) -> void:
	
	var v2: Vector3 = HexMetrics.terrace_lerp(begin, left, 1)
	var c2: Color = HexMetrics.terrace_color_lerp(begin_cell.hex_color, left_cell.hex_color, 1)
	
	_add_triangle(st, begin, boundary, v2, begin_cell.hex_color, boundary_color, c2)
	
	for i in range(2, HexMetrics.TERRACE_STEPS):
		var v1: Vector3 = v2
		var c1: Color = c2
		
		v2 = HexMetrics.terrace_lerp(begin, left, i)
		c2 = HexMetrics.terrace_color_lerp(begin_cell.hex_color, left_cell.hex_color, i)
		
		_add_triangle(st, v1, boundary, v2, c1, boundary_color, c2)
		
	_add_triangle(st, v2, boundary, left, c2, boundary_color, left_cell.hex_color)

func _perturb (pos: Vector3) -> Vector3:
	#Get a 4D noise sample
	var sample: Vector4 = HexMetrics.sample_noise(pos * HexMetrics.CELL_PERTURB_POSITION_MULTIPLIER)
	
	pos.x += (sample.x * 2.0 - 1.0) * HexMetrics.CELL_PERTURB_STRENGTH
	pos.y += (sample.y * 2.0 - 1.0) * HexMetrics.CELL_PERTURB_STRENGTH
	pos.z += (sample.z * 2.0 - 1.0) * HexMetrics.CELL_PERTURB_STRENGTH
	
	return pos

#endregion
