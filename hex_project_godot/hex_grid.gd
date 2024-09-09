class_name HexGrid
extends Node3D

#region Exported variables

@export var width: int = 0
@export var height: int = 0

@export var hex_cell_prefab: PackedScene

@export var default_hex_color: Color
@export var touched_hex_color: Color

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

#region Public methods

func color_cell(position: Vector3, color_to_use: Color) -> void:
	var inverse_transform_point = position * global_transform
	var coordinates: HexCoordinates = HexCoordinates.FromPosition(inverse_transform_point)
	print_debug(str(coordinates))
	
	var index = coordinates.X + coordinates.Z * width + coordinates.Z / 2.0
	var cell = _hex_cells[index] as HexCell
	cell.regenerate_mesh(color_to_use)

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
	hex_cell.hex_color = default_hex_color
	hex_cell.position = hex_position
	hex_cell.hex_coordinates = HexCoordinates.FromOffsetCoordinates(x, z)
	hex_cell.position_label.text = str(hex_cell.hex_coordinates)
	
	_hex_cells.append(hex_cell)
	add_child(hex_cell)

#endregion
