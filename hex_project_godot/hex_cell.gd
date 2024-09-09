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

## This is the color that is being used for this hex cell
var hex_color: Color

#endregion

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_create_mesh()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func regenerate_mesh (c: Color) -> void:
	#Set the color used for each vertex in the hex mesh
	hex_color = c
	
	#Regenerate the hex mesh
	_create_mesh()

func _create_mesh () -> void:
	#Get an instance of the surface tool
	var surface_tool = SurfaceTool.new();
	
	#Begin creating the mesh
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES);
	
	#Iterate over each of the 6 triangles within the hex
	for i in range(0, 6):
		#Add this triangle to the mesh
		_add_triangle(surface_tool, Vector3.ZERO, CORNERS[i + 1], CORNERS[i])
	
	#Generate the normals for the mesh
	surface_tool.generate_normals()
	
	#Commit the mesh
	visualization.mesh = surface_tool.commit()
	
	#Create the collision object for the mesh
	visualization.create_trimesh_collision()
	
	#Set the material for the mesh
	visualization.material_override = hex_shader_material
	
func _add_triangle (st: SurfaceTool, v1: Vector3, v2: Vector3, v3: Vector3) -> void:
	#Set the color to be used for each vertex
	st.set_color(hex_color)
	
	#Create each vertex of the triangle
	st.add_vertex(v1)
	st.add_vertex(v2)
	st.add_vertex(v3)
