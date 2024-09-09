class_name HexGrid
extends Node3D

#region Exported variables

## This is the width of the hex grid (in number of hexes)
@export var width: int = 0

## This is the height of the hex grid (in number of hexes)
@export var height: int = 0

## This is the scene that will be used for each hex cell in the grid
@export var hex_cell_prefab: PackedScene

## This is the default color for each hex in the grid
@export var default_hex_color: Color

#endregion

#region Private variables

## This is a list that contains each HexCell object in the grid
var _hex_cells = []

#endregion

#region Method overrides

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#Create an empty list of hex cells
	var hex_cells = []
	
	#Iterate over the height and width of the hex grid
	var i = 0
	for z in range(0, height):
		for x in range(0, width):
			#Create the hex cell at this position in the grid
			_create_cell(z, x, i)
			
			#Increment i
			i += 1


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
#endregion

#region Public methods

func color_cell(position: Vector3, color_to_use: Color) -> void:
	#Convert the global position to a position within the hex grid
	var inverse_transform_point = position * global_transform
	
	#Convert the position in the hex grid to a set of coordinates within the hex grid
	var coordinates: HexCoordinates = HexCoordinates.FromPosition(inverse_transform_point)
	
	#Output the coordinates for debugging purposes
	print_debug(str(coordinates))
	
	#Find the index into the _hex_cells list for which hex object we want
	var index = coordinates.X + coordinates.Z * width + coordinates.Z / 2.0
	
	#Get the selected hex cell object
	var cell = _hex_cells[index] as HexCell
	
	#Regenerate the selected hex cell's mesh using the specified color
	cell.regenerate_mesh(color_to_use)

#endregion

#region Private methods

func _create_cell(z: int, x: int, i: int) -> void:
	#Create a Vector3 to store the new hex's position
	var hex_position = Vector3(
		(x + z * 0.5 - (z / 2)) * (HexCell.INNER_RADIUS * 2.0), 
		0.0, 
		z * (HexCell.OUTER_RADIUS * 1.5)
	)
	
	#Instantiate a hex cell object
	var hex_cell = hex_cell_prefab.instantiate() as HexCell
	
	#Set the west neighbor of the hex cell
	if (x > 0):
		hex_cell.set_neighbor(HexDirectionsClass.HexDirections.W, _hex_cells[i - 1])
	
	#Set the south-east and south-west neighbors of the hex cell
	if (z > 0):
		if (z & 1) == 0:
			#If this is an even row...
			
			#Set the south-east neighbor of the hex cell
			hex_cell.set_neighbor(HexDirectionsClass.HexDirections.SE, _hex_cells[i - width])
			
			if (x > 0):
				#Set the south-west neighbor of the hex cell
				hex_cell.set_neighbor(HexDirectionsClass.HexDirections.SW, _hex_cells[i - width - 1])
		else:
			#If this is an odd row...
			
			#Set the south-west neighbor of the hex cell
			hex_cell.set_neighbor(HexDirectionsClass.HexDirections.SW, _hex_cells[i - width])
			
			if (x < width - 1):
				#Set the south-east neighbor of the hex cell
				hex_cell.set_neighbor(HexDirectionsClass.HexDirections.SE, _hex_cells[i - width + 1])
	
	#Set the color of the hex cell
	hex_cell.hex_color = default_hex_color
	
	#Set the position of the hex cell in the scene
	hex_cell.position = hex_position
	
	#Set the coordinates of the hex cell within the grid
	hex_cell.hex_coordinates = HexCoordinates.FromOffsetCoordinates(x, z)
	
	#Set the coordinates/position label on the hex cell
	hex_cell.position_label.text = str(hex_cell.hex_coordinates)
	
	#Add this hex cell to the list of hex cells in the grid
	_hex_cells.append(hex_cell)
	
	#Add this hex cell as a child of the scene
	add_child(hex_cell)

#endregion
