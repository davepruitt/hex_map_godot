class_name HexCell
extends Node3D

#region Exported variables

## This is a Label3D node that will be used to display the hex cell's position within the hex grid
@export var position_label: Label3D

## This is the mesh that will be used for this hex cell
@export var visualization: MeshInstance3D

## This is the default ShaderMaterial that will be used for the hex cell's mesh
@export var hex_shader_material: ShaderMaterial

#endregion

#region Public data members

## These are the cordinates of this hex within the hex grid
var hex_coordinates: HexCoordinates

## This is the color of this hex
var hex_color: Color

## This is an array of all neighbors of this hex cell
var hex_neighbors: Array[HexCell] = [null, null, null, null, null, null]

var elevation: int:
	get:
		return _elevation
	set(value):
		_elevation = value		
		position_label.position.y = _elevation * HexMetrics.ELEVATION_STEP

#endregion

#region Private data members

## This is the elevation of the hex cell
var _elevation: int = 0

#endregion

#region Overrides

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_create_mesh()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
#endregion

#region Public methods

func generate_mesh () -> void:
	_create_mesh()
	
func generate_mesh_with_color (c: Color) -> void:
	#Set the color used for each vertex in the hex mesh
	hex_color = c
	
	#Regenerate the hex mesh
	_create_mesh()	
	
func get_neighbor (direction: HexDirectionsClass.HexDirections) -> HexCell:
	return hex_neighbors[int(direction)]
	
func set_neighbor (direction: HexDirectionsClass.HexDirections, cell: HexCell) -> void:
	#Set the other cell as a neighbor of this cell
	hex_neighbors[int(direction)] = cell
	
	#Set this cell as a neighbor of the other cell
	var opposite_direction = HexDirectionsClass.opposite(direction)
	cell.hex_neighbors[int(opposite_direction)] = self

func get_edge_type_from_direction (direction: HexDirectionsClass.HexDirections) -> Enums.HexEdgeType:
	return HexMetrics.get_edge_type(_elevation, hex_neighbors[int(direction)].elevation)

func get_edge_type_from_other_cell (other_cell: HexCell) -> Enums.HexEdgeType:
	return HexMetrics.get_edge_type(_elevation, other_cell.elevation)

#endregion

#region Private methods

func _create_mesh () -> void:
	#Get an instance of the surface tool
	var surface_tool = SurfaceTool.new();
	
	#Begin creating the mesh
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES);
	
	#Iterate over each of the 6 directions from the center of the hex
	for i in range(0, 6):
		#Form the mesh for this direction of the hex
		_triangulate_hex(surface_tool, i)
	
	#Generate the normals for the mesh
	surface_tool.generate_normals()
	
	#Generate the tangents for the mesh
	surface_tool.generate_tangents()
	
	#Commit the mesh
	visualization.mesh = surface_tool.commit()
	
	#Create the collision object for the mesh
	visualization.create_trimesh_collision()
	
	#Set the material for the mesh
	visualization.material_override = hex_shader_material
	
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
	
	
func _add_quad (st: SurfaceTool, v1: Vector3, v2: Vector3, v3: Vector3, v4: Vector3, c1: Color, c2: Color, c3: Color, c4: Color) -> void:
	_add_triangle(st, v1, v2, v3, c1, c2, c3)
	_add_triangle(st, v2, v4, v3, c2, c4, c3)	
	
func _triangulate_hex (st: SurfaceTool, direction: HexDirectionsClass.HexDirections) -> void:
	#Calculate the Vector3 positions for the vertices of the triangle
	var center = Vector3.ZERO
	var p1 = center + HexMetrics.get_first_solid_corner(direction)
	var p2 = center + HexMetrics.get_second_solid_corner(direction)
	
	center.y = _elevation * HexMetrics.ELEVATION_STEP
	p1.y = _elevation * HexMetrics.ELEVATION_STEP
	p2.y = _elevation * HexMetrics.ELEVATION_STEP
	
	#Add the triangle
	_add_triangle(st, center, p2, p1, hex_color, hex_color, hex_color)
	
	#Add connections to other hex cells
	if (direction <= HexDirectionsClass.HexDirections.SE):
		_triangulate_connection(st, direction, p1, p2)
	
func _triangulate_connection (st: SurfaceTool, direction: HexDirectionsClass.HexDirections, v1: Vector3, v2: Vector3) -> void:
	#Get the neighboring cell in the specified direction
	var neighbor_cell = get_neighbor(direction)
	
	#If the neighboring cell is null, then fail out of the function
	if (neighbor_cell == null):
		return
	
	var bridge = HexMetrics.get_bridge(direction)
	var v3 = v1 + bridge
	var v4 = v2 + bridge
	
	v3.y = neighbor_cell.elevation * HexMetrics.ELEVATION_STEP
	v4.y = v3.y
	
	if (get_edge_type_from_direction(direction) == Enums.HexEdgeType.Slope):
		_triangulate_edge_terraces(st, v1, v2, self, v3, v4, neighbor_cell)
	else:
		_add_quad(st, v1, v2, v3, v4, hex_color, hex_color, neighbor_cell.hex_color, neighbor_cell.hex_color)
	
	#Get the next neighbor of the cell
	var next_direction = HexDirectionsClass.next(direction)
	var next_neighbor = get_neighbor(next_direction)
	if (direction <= HexDirectionsClass.HexDirections.E) and (next_neighbor != null):
		var v5 = v2 + HexMetrics.get_bridge(next_direction)
		v5.y = next_neighbor.elevation * HexMetrics.ELEVATION_STEP
		
		if (_elevation <= neighbor_cell.elevation):
			if (_elevation <= next_neighbor.elevation):
				_triangulate_corner(st, v2, self, v4, neighbor_cell, v5, next_neighbor)
			else:
				_triangulate_corner(st, v5, next_neighbor, v2, self, v4, neighbor_cell)
		elif (neighbor_cell.elevation <= next_neighbor.elevation):
			_triangulate_corner(st, v4, neighbor_cell, v5, next_neighbor, v2, self)
		else:
			_triangulate_corner(st, v5, next_neighbor, v2, self, v4, neighbor_cell)
		#_add_triangle(st, v2, v5, v4, hex_color, next_neighbor.hex_color, neighbor_cell.hex_color)

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
			return
		
		if right_edge_type == Enums.HexEdgeType.Flat:
			_triangulate_corner_terraces(st, left, left_cell, right, right_cell, bottom, bottom_cell)
			return
			
		_triangulate_corner_terrace_cliff(st, bottom, bottom_cell, left, left_cell, right, right_cell)
		return
	
	if right_edge_type == Enums.HexEdgeType.Slope:
		if left_edge_type == Enums.HexEdgeType.Flat:
			_triangulate_corner_terraces(st, right, right_cell, bottom, bottom_cell, left, left_cell)
			return
			
		_triangulate_corner_cliff_terrace(st, bottom, bottom_cell, left, left_cell, right, right_cell)
		return
		
	if left_cell.get_edge_type_from_other_cell(right_cell) == Enums.HexEdgeType.Slope:
		if left_cell.elevation < right_cell.elevation:
			_triangulate_corner_cliff_terrace(st, right, right_cell, bottom, bottom_cell, left, left_cell)
		else:
			_triangulate_corner_terrace_cliff(st, left, left_cell, right, right_cell, bottom, bottom_cell)
		return
	
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
		
		_add_triangle(st, v2, boundary, left, c2, boundary_color, left_cell.hex_color)
	
	_add_triangle(st, v2, boundary, left, c2, boundary_color, left_cell.hex_color)

#endregion

#region Public static methods


#endregion
