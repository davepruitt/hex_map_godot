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

func get_edge_type (direction: HexDirectionsClass.HexDirections) -> Enums.HexEdgeType:
	return HexMetrics.get_edge_type(_elevation, hex_neighbors[int(direction)].elevation)

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
	
	if (get_edge_type(direction) == Enums.HexEdgeType.Slope):
		_triangulate_edge_terraces(st, v1, v2, self, v3, v4, neighbor_cell)
	else:
		_add_quad(st, v1, v2, v3, v4, hex_color, hex_color, neighbor_cell.hex_color, neighbor_cell.hex_color)
	
	#Get the next neighbor of the cell
	var next_direction = HexDirectionsClass.next(direction)
	var next_neighbor = get_neighbor(next_direction)
	if (direction <= HexDirectionsClass.HexDirections.E) and (next_neighbor != null):
		var v5 = v2 + HexMetrics.get_bridge(next_direction)
		v5.y = next_neighbor.elevation * HexMetrics.ELEVATION_STEP
		
		_add_triangle(st, v2, v5, v4, hex_color, next_neighbor.hex_color, neighbor_cell.hex_color)

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

#endregion

#region Public static methods


#endregion
