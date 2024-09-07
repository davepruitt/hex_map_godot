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
]

#endregion

#region Exported variables

@export var position_label: Label3D

#endregion


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
