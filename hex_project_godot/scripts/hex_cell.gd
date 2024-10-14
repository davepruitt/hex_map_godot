class_name HexCell
extends Node3D

#region Hex cell enumerations

enum CellInformationLabelMode { Off, Position, Information }

#endregion

#region Exported variables

## This is a Label3D node that will be used to display the hex cell's position within the hex grid
@export var cell_information_label: Label3D

#endregion

#region Private data members

var _cell_label_mode: CellInformationLabelMode = CellInformationLabelMode.Off

## This is the terrain type for this cell
var _terrain_type_index: int = 0

## This is the elevation of the hex cell
var _elevation: int = -32767

var _has_incoming_river: bool = false

var _has_outgoing_river: bool = false

var _incoming_river_direction: HexDirectionsClass.HexDirections = HexDirectionsClass.HexDirections.NE

var _outgoing_river_direction: HexDirectionsClass.HexDirections = HexDirectionsClass.HexDirections.NE

var _roads: Array[bool] = [false, false, false, false, false, false]

var _water_level: int = 0

var _urban_level: int = 0

var _farm_level: int = 0

var _plant_level: int = 0

var _walled: bool = false

var _special_index: int = 0

## Distance from the selected cell to this cell
var _distance: int = 0

#endregion

#region Public data members

## This is the HexGridChunk object that this HexCell belongs to
var hex_chunk: HexGridChunk

## These are the cordinates of this hex within the hex grid
var hex_coordinates: HexCoordinates

## This is an array of all neighbors of this hex cell
var hex_neighbors: Array[HexCell] = [null, null, null, null, null, null]

#endregion

#region Public properties

## The mode for this cell's label
var cell_label_mode: CellInformationLabelMode:
	get:
		return _cell_label_mode
	set(value):
		#Set the private data member
		_cell_label_mode = value
		
		#Make changes to the label
		if (_cell_label_mode == CellInformationLabelMode.Off):
			cell_information_label.visible = false
		elif (_cell_label_mode == CellInformationLabelMode.Position):
			cell_information_label.visible = true
			cell_information_label.font_size = 32
			cell_information_label.text = str(self.hex_coordinates)
		elif (_cell_label_mode == CellInformationLabelMode.Information):
			cell_information_label.visible = true
			cell_information_label.font_size = 128
			cell_information_label.text = str(distance)

## The elevation level of this cell
var elevation: int:
	get:
		return _elevation
	set(value):
		#Check to see if the new value is different from the existing value
		if (_elevation == value):
			return
		
		#Set the elevation value for this cell
		_elevation = value
		
		#Refresh the position
		_refresh_position()
		
		#Remove any illegal/invalid rivers due to the change in this cell's elevation
		_validate_rivers()
		
		#Iterate over each road direction
		for i in range(0, len(_roads)):
			#Check to see if there is a large elevation difference
			if (_roads[i]) and (get_elevation_difference(i) > 1):
				#Clear out any roads if there is
				set_road(i, false)
		
		#Refresh this hex's chunk
		_refresh()
		
## This is the color of this hex
var hex_color: Color:
	get:
		return (HexMetrics.colors[_terrain_type_index])

## This is the terrain type of this hex
var terrain_type_index: int:
	get:
		return _terrain_type_index
	set(value):
		if (_terrain_type_index != value):
			_terrain_type_index = value
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

## This property indicates the y-position of the stream bed for this hex cell
var stream_bed_y: float:
	get:
		return ((_elevation + HexMetrics.STREAM_BED_ELEVATION_OFFSET) * HexMetrics.ELEVATION_STEP)

## The height of the river surface for this hex cell
var river_surface_y: float:
	get:
		return ((_elevation + HexMetrics.RIVER_SURFACE_ELEVATION_OFFSET) * HexMetrics.ELEVATION_STEP)

## A boolean value indicating whether this cell contains roads
var has_roads: bool:
	get:
		return _roads.any(func(x): return x)

## If this cell contains the beginning or end of a river, this indicates the direction of it
var river_begin_or_end_direction: HexDirectionsClass.HexDirections:
	get:
		if (has_incoming_river):
			return incoming_river_direction
		else:
			return outgoing_river_direction

## The water level of this cell
var water_level: int:
	get:
		return _water_level
	set(value):
		if (_water_level == value):
			return
		
		_water_level = value
		
		_validate_rivers()
		_refresh()

## A boolean value indicating whether this cell is underwater
var is_underwater: bool:
	get:
		return (_water_level > _elevation)

## The height of the water surface for this cell
var water_surface_y: float:
	get:
		return (_water_level + HexMetrics.WATER_ELEVATION_OFFSET) * HexMetrics.ELEVATION_STEP

## The urban level of this cell - how "urban" this cell is
var urban_level: int:
	get:
		return _urban_level
	set(value):
		if (_urban_level != value):
			_urban_level = value
			_refresh_self_only()

## The farm level of this cell - how much "farm" is this cell
var farm_level: int:
	get:
		return _farm_level
	set(value):
		if (_farm_level != value):
			_farm_level = value
			_refresh_self_only()

## The plant level of this cell - how much "plant life" is this cell
var plant_level: int:
	get:
		return _plant_level
	set(value):
		if (_plant_level != value):
			_plant_level = value
			_refresh_self_only()

## Whether this cell is walled or not
var walled: bool:
	get:
		return _walled
	set(value):
		if (_walled != value):
			_walled = value
			_refresh()

## If this cell contains a special prefab, the identiy of that special prefab as an index into the list of special prefabs
var special_index: int:
	get:
		return _special_index
	set(value):
		if (_special_index != value) and (not has_river):
			_special_index = value
			remove_roads()
			_refresh_self_only()

## A boolean value indicating whether this cell contains a special prefab
var is_special: bool:
	get:
		return (_special_index > 0)

var distance: int:
	get:
		return _distance
	set(value):
		_distance = value
		

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

func set_outgoing_river (direction: HexDirectionsClass.HexDirections) -> void:
	#Return immediately if we already have an outgoing river in the specified direction
	if (_has_outgoing_river and _outgoing_river_direction == direction):
		return
	
	#Get the neighbor in the specified direction
	var neighbor: HexCell = get_neighbor(direction)
	
	#If no neighbor exists in the specified direction, or if the neighbor
	#has a higher elevation than the current cell, then return immediately
	if (not _is_valid_river_destination(neighbor)):
		return
	
	#Remove any previously existing outgoing river
	remove_outgoing_river()
	
	#If the new river overlaps an existing incoming river, then also remove
	#the previously existing incoming river
	if (_has_incoming_river) and (_incoming_river_direction == direction):
		remove_incoming_river()
	
	#Set the outgoing river flag
	_has_outgoing_river = true
	
	#Set the direction of the outgoing river
	_outgoing_river_direction = direction
	
	#Set the special feature index to 0 (indicating that no special feature exists)
	_special_index = 0
	
	#Set the incoming river of the neighbor cell
	neighbor.remove_incoming_river()
	neighbor._has_incoming_river = true
	neighbor._incoming_river_direction = HexDirectionsClass.opposite(direction)
	neighbor._special_index = 0
	
	#Clear out any road that exists in this direction
	#This will also call the function to refresh the cell and its neighbors
	set_road(int(direction), false)

func has_road_through_edge (direction: HexDirectionsClass.HexDirections) -> bool:
	return _roads[int(direction)]

func add_road (direction: HexDirectionsClass.HexDirections) -> void:
	if ((!_roads[int(direction)]) and 
		(!has_river_through_edge(direction)) and 
		(not is_special) and
		(not get_neighbor(direction).is_special) and
		(get_elevation_difference(direction) <= 1)):
		
		set_road(int(direction), true)

func remove_roads () -> void:
	#Iterate through all directions of roads
	for i in range(0, len(_roads)):
		#If a road exist in this direction...
		if (_roads[i]):
			set_road(i, false)

func set_road (index: int, state: bool) -> void:
	#Set it to false
	_roads[index] = state
	
	#Remove the road from its neighbor as well
	var opposite_direction: HexDirectionsClass.HexDirections = int(HexDirectionsClass.opposite(index))
	hex_neighbors[index]._roads[int(opposite_direction)] = state
	hex_neighbors[index]._refresh_self_only()
	
	#Refresh this cell
	_refresh_self_only()

func get_elevation_difference (direction: HexDirectionsClass.HexDirections) -> int:
	var difference: int = _elevation - get_neighbor(direction).elevation
	if (difference >= 0):
		return difference
	else:
		return -difference

func save_hex_cell (file_writer: FileAccess) -> void:
	file_writer.store_8(_terrain_type_index)
	file_writer.store_8(_elevation)
	file_writer.store_8(_water_level)
	file_writer.store_8(_urban_level)
	file_writer.store_8(_farm_level)
	file_writer.store_8(_plant_level)
	file_writer.store_8(_special_index)
	file_writer.store_8(_walled)
	
	if (_has_incoming_river):
		file_writer.store_8(int(_incoming_river_direction) + 128)
	else:
		file_writer.store_8(0)
	
	if (_has_outgoing_river):
		file_writer.store_8(int(_outgoing_river_direction) + 128)
	else:
		file_writer.store_8(0)
	
	var road_flags: int = 0
	for i in range(0, len(_roads)):
		if (_roads[i]):
			road_flags |= 1 << i
	file_writer.store_8(road_flags)

func load_hex_cell (file_reader: FileAccess) -> void:
	_terrain_type_index = file_reader.get_8()
	
	_elevation = file_reader.get_8()
	_refresh_position()
	
	_water_level = file_reader.get_8()
	_urban_level = file_reader.get_8()
	_farm_level = file_reader.get_8()
	_plant_level = file_reader.get_8()
	_special_index = file_reader.get_8()
	
	_walled = bool(file_reader.get_8())
	
	var incoming_river_info: int = file_reader.get_8()
	if (incoming_river_info >= 128):
		_has_incoming_river = true
		_incoming_river_direction = incoming_river_info - 128
	else:
		_has_incoming_river = false
	
	var outgoing_river_info: int = file_reader.get_8()
	if (outgoing_river_info >= 128):
		_has_outgoing_river = true
		_outgoing_river_direction = outgoing_river_info - 128
	else:
		_has_outgoing_river = false
	
	var road_flags: int = file_reader.get_8()
	for i in range(0, len(_roads)):
		_roads[i] = ((road_flags & (1 << i)) != 0)

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

func _refresh_position () -> void:
	#Set the position of the cell
	position.y = _elevation * HexMetrics.ELEVATION_STEP
	
	var noise_sample: Vector4 = HexMetrics.sample_noise(position)
	var perturbation_amount: float = ((noise_sample.y * 2.0 - 1.0) * HexMetrics.ELEVATION_PERTURB_STRENGTH)
	position.y += perturbation_amount
	
	#Set the y-axis position of the "position label" for the cell
	cell_information_label.position.y = 0.1 + abs(perturbation_amount)

func _is_valid_river_destination (neighbor: HexCell) -> bool:
	if (neighbor != null):
		var condition_1: bool = (elevation >= neighbor.elevation)
		var condition_2: bool = (water_level == neighbor.elevation)
		return (condition_1 or condition_2)
	else:
		return false

func _validate_rivers () -> void:
	var outgoing_neighbor: HexCell = get_neighbor(outgoing_river_direction)
	if (has_outgoing_river and (not _is_valid_river_destination(outgoing_neighbor))):
		remove_outgoing_river()
	
	var incoming_neighbor: HexCell = get_neighbor(incoming_river_direction)
	if (has_incoming_river and (not incoming_neighbor._is_valid_river_destination(self))):
		remove_incoming_river()

func _update_distance_label () -> void:
	if (_cell_label_mode == CellInformationLabelMode.Information):
		cell_information_label.text = str(distance)

#endregion
