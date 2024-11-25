class_name HexMapGenerator

#region Private data members

var _rng = RandomNumberGenerator.new()

var _cell_count: int = 0

var _search_frontier: HexCellPriorityQueue = HexCellPriorityQueue.new()
var _search_frontier_phase: int = 0

#endregion

#region Exported public data members

@export_range(0.0, 0.5)
var jitter_probability: float = 0.25

@export_range(20, 200)
var chunk_size_min: int = 30

@export_range(20, 200)
var chunk_size_max: int = 100

@export_range(5, 95)
var land_percentage: int = 50

@export_range(1, 5)
var water_level: int = 3

@export_range(0.0, 1.0)
var high_rise_probability: float = 0.25

@export_range(0.0, 0.4)
var sink_probability: float = 0.2

@export_range(-4, 0)
var elevation_minimum: int = -2

@export_range(6, 10)
var elevation_maximum: int = 8

#endregion

#region Public data members

var hex_grid: HexGrid = null

#endregion

#region Public methods

func generate_map (x: int, z: int) -> void:
	#Set the seed to 0 for reproducibility
	_rng.set_seed(0)
	
	#Set the cell count
	_cell_count = x * z
	
	#Create a blank map
	hex_grid.create_map(x, z)
	
	#Set the water level for the map
	for i in range(0, _cell_count):
		hex_grid.get_cell_from_index(i).water_level = water_level
	
	#Raise some terrain
	_create_land()
	_set_terrain_type()
	
	#Reset the search phases of all cells to 0
	for i in range(0, _cell_count):
		hex_grid.get_cell_from_index(i).search_phase = 0

#endregion

#region Private methods

func _get_random_cell () -> HexCell:
	var random_cell_index: int = _rng.randi_range(0, _cell_count)
	return hex_grid.get_cell_from_index(random_cell_index)

func _create_land () -> void:
	var land_budget: int = roundi(_cell_count * land_percentage * 0.01)
	
	while (land_budget > 0):
		var chunk_size: int = _rng.randi_range(chunk_size_min, chunk_size_max + 1)
		var random_value: float = _rng.randf()
		if (random_value < sink_probability):
			land_budget = _sink_terrain(chunk_size, land_budget)
		else:
			land_budget = _raise_terrain(chunk_size, land_budget)

func _set_terrain_type () -> void:
	for i in range(0, _cell_count):
		var cell: HexCell = hex_grid.get_cell_from_index(i)
		if (not cell.is_underwater):
			cell.terrain_type_index = cell.elevation - cell.water_level

func _raise_terrain (chunk_size: int, budget: int) -> int:
	_search_frontier_phase += 1
	var first_cell: HexCell = _get_random_cell()
	first_cell.search_phase = _search_frontier_phase
	first_cell.distance = 0
	first_cell.search_heuristic = 0
	_search_frontier.enqueue(first_cell)
	
	var center_coordinates: HexCoordinates = first_cell.hex_coordinates
	
	var rise: int = 2 if _rng.randf() < high_rise_probability else 1
	var size: int = 0
	while (size < chunk_size and _search_frontier.count > 0):
		var current: HexCell = _search_frontier.dequeue()
		var original_elevation: int = current.elevation
		var new_elevation: int = original_elevation + rise
		if (new_elevation > elevation_maximum):
			continue
		
		current.elevation = new_elevation
		if (original_elevation < water_level) and (new_elevation >= water_level):
			budget -= 1
			if (budget == 0):
				break
		
		size += 1
		
		for d in range(0, 6):
			var neighbor: HexCell = current.get_neighbor(d)
			if (neighbor) and (neighbor.search_phase < _search_frontier_phase):
				neighbor.search_phase = _search_frontier_phase
				neighbor.distance = neighbor.hex_coordinates.DistanceTo(center_coordinates)
				
				var search_heuristic_randomizer: float = _rng.randf()
				if (search_heuristic_randomizer < jitter_probability):
					neighbor.search_heuristic = 1
				else:
					neighbor.search_heuristic = 0
				_search_frontier.enqueue(neighbor)
		
	_search_frontier.clear()
	
	return budget

func _sink_terrain (chunk_size: int, budget: int) -> int:
	_search_frontier_phase += 1
	var first_cell: HexCell = _get_random_cell()
	first_cell.search_phase = _search_frontier_phase
	first_cell.distance = 0
	first_cell.search_heuristic = 0
	_search_frontier.enqueue(first_cell)
	
	var center_coordinates: HexCoordinates = first_cell.hex_coordinates
	
	var sink: int = 2 if _rng.randf() < high_rise_probability else 1
	var size: int = 0
	while (size < chunk_size and _search_frontier.count > 0):
		var current: HexCell = _search_frontier.dequeue()
		var original_elevation: int = current.elevation
		var new_elevation: int = current.elevation - sink
		if (new_elevation < elevation_minimum):
			continue
		
		current.elevation = new_elevation
		if (original_elevation >= water_level) and (new_elevation < water_level):
			budget += 1
		
		size += 1
		
		for d in range(0, 6):
			var neighbor: HexCell = current.get_neighbor(d)
			if (neighbor) and (neighbor.search_phase < _search_frontier_phase):
				neighbor.search_phase = _search_frontier_phase
				neighbor.distance = neighbor.hex_coordinates.DistanceTo(center_coordinates)
				
				var search_heuristic_randomizer: float = _rng.randf()
				if (search_heuristic_randomizer < jitter_probability):
					neighbor.search_heuristic = 1
				else:
					neighbor.search_heuristic = 0
				_search_frontier.enqueue(neighbor)
		
	_search_frontier.clear()
	
	return budget

#endregion
