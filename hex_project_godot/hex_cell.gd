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

@export var position_label: Label3D
@export var hex_mesh: PackedScene

#endregion

@onready var visualization = $Visualization

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_create_mesh()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _create_mesh () -> void:
	var surface_tool = SurfaceTool.new();
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES);
	
	for i in range(0, 6):
		_add_triangle(surface_tool, Vector3.ZERO, CORNERS[i + 1], CORNERS[i])
	
	#surface_tool.generate_normals()
	visualization.mesh = surface_tool.commit()
	
func _add_triangle (st: SurfaceTool, v1: Vector3, v2: Vector3, v3: Vector3) -> void:
	st.add_vertex(v1)
	st.add_vertex(v2)
	st.add_vertex(v3)
