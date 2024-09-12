class_name HexCell
extends Node3D

#region Exported variables

## This is a Label3D node that will be used to display the hex cell's position within the hex grid
@export var position_label: Label3D

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
		#Set the elevation value for this cell
		_elevation = value
		
		#Set the position of the cell
		position.y = _elevation * HexMetrics.ELEVATION_STEP
		
		var noise_sample: Vector4 = HexMetrics.sample_noise(position * HexMetrics.CELL_PERTURB_POSITION_MULTIPLIER)
		var perturbation_amount: float = ((noise_sample.y * 2.0 - 1.0) * HexMetrics.ELEVATION_PERTURB_STRENGTH)
		position.y += perturbation_amount
		
		#Set the y-axis position of the "position label" for the cell
		position_label.position.y = 0.01 + abs(perturbation_amount)

#endregion

#region Private data members

## This is the elevation of the hex cell
var _elevation: int = 0

#endregion

#region Overrides

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

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

func get_edge_type_from_direction (direction: HexDirectionsClass.HexDirections) -> Enums.HexEdgeType:
	return HexMetrics.get_edge_type(_elevation, hex_neighbors[int(direction)].elevation)

func get_edge_type_from_other_cell (other_cell: HexCell) -> Enums.HexEdgeType:
	return HexMetrics.get_edge_type(_elevation, other_cell.elevation)

#endregion
