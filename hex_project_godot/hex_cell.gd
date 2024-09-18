class_name HexCell
extends Node3D

#region Exported variables

## This is a Label3D node that will be used to display the hex cell's position within the hex grid
@export var position_label: Label3D

#endregion

#region Private data members

var _hex_color: Color = Color.BLACK

## This is the elevation of the hex cell
var _elevation: int = -32767

var _has_incoming_river: bool = false

var _has_outgoing_river: bool = false

var _incoming_river_direction: HexDirectionsClass.HexDirections = HexDirectionsClass.HexDirections.NE

var _outgoing_river_direction: HexDirectionsClass.HexDirections = HexDirectionsClass.HexDirections.NE

#endregion

#region Public data members

## This is the HexGridChunk object that this HexCell belongs to
var hex_chunk: HexGridChunk

## These are the cordinates of this hex within the hex grid
var hex_coordinates: HexCoordinates

## This is an array of all neighbors of this hex cell
var hex_neighbors: Array[HexCell] = [null, null, null, null, null, null]

var elevation: int:
	get:
		return _elevation
	set(value):
		#Check to see if the new value is different from the existing value
		if (_elevation == value):
			return
		
		#Set the elevation value for this cell
		_elevation = value
		
		#Set the position of the cell
		position.y = _elevation * HexMetrics.ELEVATION_STEP
		
		var noise_sample: Vector4 = HexMetrics.sample_noise(position * HexMetrics.CELL_PERTURB_POSITION_MULTIPLIER)
		var perturbation_amount: float = ((noise_sample.y * 2.0 - 1.0) * HexMetrics.ELEVATION_PERTURB_STRENGTH)
		position.y += perturbation_amount
		
		#Set the y-axis position of the "position label" for the cell
		position_label.position.y = 0.01 + abs(perturbation_amount)
		
		#Refresh this hex's chunk
		_refresh()
		
## This is the color of this hex
var hex_color: Color:
	get:
		return _hex_color
	set(value):
		if (_hex_color == value):
			return
		
		_hex_color = value
		
		_refresh()

## This is a property indicating whether this cell has an incoming river
var has_incoming_river: bool:
	get:
		return _has_incoming_river

## This is a property indicating whether this cell has an outgoing river
var has_outgoing_river: bool:
	get:
		return _has_outgoing_river

## This is a property indicating the direction of the incoming river, if it exists
var incoming_river_direction: HexDirectionsClass.HexDirections:
	get:
		return _incoming_river_direction

## This is a property indicating the direction of the outgoing river, if it exists
var outgoing_river_direction: HexDirectionsClass.HexDirections:
	get:
		return _outgoing_river_direction
		
## This property indicates whether a river exists in this cell
var has_river: bool:
	get:
		return (_has_incoming_river or _has_outgoing_river)

## This property indicates whether this cell contains the beginning or end of a river
var has_river_beginning_or_end: bool:
	get:
		return (_has_incoming_river != _has_outgoing_river)

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

func show_ui_label (should_show_ui: bool) -> void:
	if (should_show_ui):
		position_label.visible = true
	else:
		position_label.visible = false

func has_river_through_edge (direction: HexDirectionsClass.HexDirections) -> bool:
	var condition_01: bool = _has_incoming_river and _incoming_river_direction == direction
	var condition_02: bool = _has_outgoing_river and _outgoing_river_direction == direction
	return (condition_01 or condition_02)
	
func remove_outgoing_river () -> void:
	#Return immediately if no outgoing river exists
	if (not _has_outgoing_river):
		return
	
	#Set the outgoing river flag to false
	_has_outgoing_river = false
	
	#Refresh this cell
	_refresh_self_only()
	
	#Get the neighbor in the direction the river flows
	var neighbor: HexCell = get_neighbor(_outgoing_river_direction)
	
	#Set the incoming river flag on the neighbor cell
	neighbor._has_incoming_river = false
	
	#Refresh the neighbor cell
	neighbor._refresh_self_only()
	
func remove_incoming_river () -> void:
	#Return immediately if no incoming river exists
	if (not _has_incoming_river):
		return
		
	#Set the incoming river flag to false
	_has_incoming_river = false
	
	#Refresh this cell
	_refresh_self_only()
	
	#Get the neighbor in the direction the river flows
	var neighbor: HexCell = get_neighbor(_incoming_river_direction)
	
	#Set the outgoing river flag on the neighbor cell
	neighbor._has_outgoing_river = false
	
	#Refresh the neighbor
	neighbor._refresh_self_only()

func remove_river () -> void:
	remove_outgoing_river()
	remove_incoming_river()
	

#endregion

#region Private methods

func _refresh_self_only () -> void:
	if (hex_chunk):
		hex_chunk.request_refresh()

func _refresh () -> void:
	if (hex_chunk):
		hex_chunk.request_refresh()
		
		for i in range(0, len(hex_neighbors)):
			var neighbor: HexCell = hex_neighbors[i]
			if (neighbor != null) and (neighbor.hex_chunk != hex_chunk):
				neighbor.hex_chunk.request_refresh()

#endregion
