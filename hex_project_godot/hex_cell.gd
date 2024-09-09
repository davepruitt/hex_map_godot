class_name HexCell
extends Node3D

#region Constants

const OUTER_RADIUS: float = 1.0
const INNER_RADIUS: float = OUTER_RADIUS * 0.866025404

const CORNERS = [
	Vector3(0, 0, OUTER_RADIUS),
	Vector3(INNER_RADIUS, 0, 0.5 * OUTER_RADIUS),
	Vector3(INNER_RADIUS, 0, -0.5 * OUTER_RADIUS),
	Vector3(0, 0, -OUTER_RADIUS),
	Vector3(-INNER_RADIUS, 0, -0.5 * OUTER_RADIUS),
	Vector3(-INNER_RADIUS, 0, 0.5 * OUTER_RADIUS),
	Vector3(0, 0, OUTER_RADIUS),
]

#endregion

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
	
func get_neighbor (direction: HexDirectionsClass.HexDirections) -> HexCell:
	return hex_neighbors[int(direction)]
	
func set_neighbor (direction: HexDirectionsClass.HexDirections, cell: HexCell) -> void:
	#Set the other cell as a neighbor of this cell
	hex_neighbors[int(direction)] = cell
	
	#Set this cell as a neighbor of the other cell
	var opposite_direction = HexDirectionsClass.opposite(direction)
	cell.hex_neighbors[int(opposite_direction)] = self
	
func regenerate_mesh (c: Color) -> void:
	#Set the color used for each vertex in the hex mesh
	hex_color = c
	
	#Regenerate the hex mesh
	_create_mesh()
	
#endregion

#region Private methods

func _create_mesh () -> void:
	#Get an instance of the surface tool
	var surface_tool = SurfaceTool.new();
	
	#Begin creating the mesh
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES);
	
	#Iterate over each of the 6 triangles within the hex
	for i in range(0, 6):
		#Add this triangle to the mesh
		_add_triangle_from_direction(surface_tool, i)
	
	#Generate the normals for the mesh
	surface_tool.generate_normals()
	
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
	
func _add_triangle_from_direction (st: SurfaceTool, direction: HexDirectionsClass.HexDirections) -> void:
	#Calculate the Vector3 positions for the vertices of the triangle
	var center = Vector3.ZERO
	var p1 = center + get_first_corner(direction)
	var p2 = center + get_second_corner(direction)
	
	#Get the previous neighbor
	var previous_direction = HexDirectionsClass.previous(direction)
	var previous_cell = get_neighbor(previous_direction)
	if (previous_cell == null):
		previous_cell = self
	
	#Get the neighbor cell in the specified direction
	var neighbor_cell = get_neighbor(direction)
	if (neighbor_cell == null):
		neighbor_cell = self
		
	#Get the next neighbor
	var next_direction = HexDirectionsClass.next(direction)
	var next_cell = get_neighbor(next_direction)
	if (next_cell == null):
		next_cell = self
		
	#Determine the edge color
	var p1_color = (hex_color + previous_cell.hex_color + neighbor_cell.hex_color) / 3.0
	var p2_color = (hex_color + neighbor_cell.hex_color + next_cell.hex_color) / 3.0
	
	#Add the triangle
	_add_triangle(st, center, p2, p1, hex_color, p2_color, p1_color)

#endregion

#region Public static methods

static func get_first_corner (direction: HexDirectionsClass.HexDirections) -> Vector3:
	return CORNERS[int(direction)]
	
static func get_second_corner (direction: HexDirectionsClass.HexDirections) -> Vector3:
	return CORNERS[int(direction) + 1]	

#endregion
