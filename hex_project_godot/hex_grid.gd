class_name HexGrid
extends Node3D

#region Exported variables

@export var width: int = 0
@export var height: int = 0

@export var hex_cell_prefab: PackedScene

#endregion

#region Private variables

var _hex_cells = []

#endregion

#region Method overrides

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var hex_cells = []
	
	for z in range(0, height):
		for x in range(0, width):
			_create_cell(z, x)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
#endregion

#region Private methods

func _create_cell(z: int, x: int) -> void:
	#Create a Vector3 to store the new hex's position
	var hex_position = Vector3(
		(x + z * 0.5 - (z / 2)) * (HexCell.INNER_RADIUS * 2.0), 
		0.0, 
		z * (HexCell.OUTER_RADIUS * 1.5)
	)
	
	var hex_cell = hex_cell_prefab.instantiate() as HexCell
	hex_cell.position = hex_position
	hex_cell.position_label.text = "(" + str(z) + "," + str(x) + ")"
	
	_hex_cells.append(hex_cell)
	add_child(hex_cell)

#endregion
