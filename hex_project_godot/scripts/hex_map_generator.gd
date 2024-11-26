class_name HexMapGenerator

#region Private classes accessible only to the map generator

class MapRegion:
	var x_min: int = 0
	var x_max: int = 0
	var z_min: int = 0
	var z_max: int = 0

class ClimateData:
	var clouds: float = 0.0
	var moisture: float = 0.0

#endregion

#region Private data members

var _rng = RandomNumberGenerator.new()

var _cell_count: int = 0

var _search_frontier: HexCellPriorityQueue = HexCellPriorityQueue.new()
var _search_frontier_phase: int = 0

var _regions: Array[MapRegion] = []

var _climate: Array[ClimateData] = []
var _next_climate: Array[ClimateData] = []

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

@export_range(0, 10)
var map_border_x: int = 5

@export_range(0, 10)
var map_border_z: int = 5

@export_range(0, 10)
var region_border: int = 5

@export_range(1, 4)
var region_count: int = 3

@export_range(0, 100)
var erosion_percentage: int = 50

@export_range(0.0, 1.0)
var evaporation_factor: float = 0.5

@export_range(0.0, 1.0)
var precipitation_factor: float = 0.25

@export_range(0.0, 1.0)
var runoff_factor: float = 0.25

@export_range(0.0, 1.0)
var seepage_factor: float = 0.125

@export_range(1.0, 10.0)
var wind_strength: float = 4.0

@export_range(0.0, 1.0)
var starting_moisture: float = 0.1

#endregion

#region Public data members

var wind_direction: HexDirectionsClass.HexDirections = HexDirectionsClass.HexDirections.NW

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
	_create_regions()
	_create_land()
	_erode_land()
	_create_climate()
	_set_terrain_type()
	
	#Reset the search phases of all cells to 0
	for i in range(0, _cell_count):
		hex_grid.get_cell_from_index(i).search_phase = 0

#endregion

#region Private methods

func _get_random_cell (region: MapRegion) -> HexCell:
	var random_cell_x: int = _rng.randi_range(region.x_min, region.x_max - 1)
	var random_cell_z: int = _rng.randi_range(region.z_min, region.z_max - 1)
	return hex_grid.get_cell_from_offset(random_cell_x, random_cell_z)

func _create_regions () -> void:
	if (_regions == null):
		_regions = []
	else:
		_regions.clear()
	
	
	match region_count:
		2:
			if (randf() < 0.5):
				#Set the x/z min/max values (the borders of the terrain generation region)
				var region: MapRegion = MapRegion.new()
				region.x_min = map_border_x
				region.x_max = (hex_grid.cell_count_x / 2) - region_border
				region.z_min = map_border_z
				region.z_max = hex_grid.cell_count_z - map_border_z
				_regions.append(region)
				
				var region_02: MapRegion = MapRegion.new()
				region_02.x_min = (hex_grid.cell_count_x / 2) + region_border
				region_02.x_max = hex_grid.cell_count_x - map_border_x
				region_02.z_min = map_border_z
				region_02.z_max = hex_grid.cell_count_z - map_border_z
				_regions.append(region_02)
			else:
				#Set the x/z min/max values (the borders of the terrain generation region)
				var region: MapRegion = MapRegion.new()
				region.x_min = map_border_x
				region.x_max = hex_grid.cell_count_x - map_border_x
				region.z_min = map_border_z
				region.z_max = (hex_grid.cell_count_z / 2) - region_border
				_regions.append(region)
				
				var region_02: MapRegion = MapRegion.new()
				region.x_min = map_border_x
				region.x_max = hex_grid.cell_count_x - map_border_x
				region_02.z_min = (hex_grid.cell_count_z / 2) + region_border
				region_02.z_max = hex_grid.cell_count_z - map_border_z
				_regions.append(region_02)
		3:
			var region_01: MapRegion = MapRegion.new()
			region_01.x_min = map_border_x
			region_01.x_max = (hex_grid.cell_count_x / 3) - region_border
			region_01.z_min = map_border_z
			region_01.z_max = hex_grid.cell_count_z - map_border_z
			_regions.append(region_01)
			
			var region_02: MapRegion = MapRegion.new()
			region_02.x_min = (hex_grid.cell_count_x / 3) + region_border
			region_02.x_max = (hex_grid.cell_count_x * 2 / 3) - region_border
			region_02.z_min = map_border_z
			region_02.z_max = hex_grid.cell_count_z - map_border_z
			_regions.append(region_02)
			
			var region_03: MapRegion = MapRegion.new()
			region_03.x_min = (hex_grid.cell_count_x * 2 / 3) + region_border
			region_03.x_max = hex_grid.cell_count_x - map_border_x
			region_03.z_min = map_border_z
			region_03.z_max = hex_grid.cell_count_z - map_border_z
			_regions.append(region_03)
			
		4:
			var region_01: MapRegion = MapRegion.new()
			region_01.x_min = map_border_x
			region_01.x_max = (hex_grid.cell_count_x / 2) - region_border
			region_01.z_min = map_border_z
			region_01.z_max = (hex_grid.cell_count_z / 2) - map_border_z
			_regions.append(region_01)
			
			var region_02: MapRegion = MapRegion.new()
			region_02.x_min = hex_grid.cell_count_x / 2 + region_border
			region_02.x_max = hex_grid.cell_count_x - map_border_x
			region_02.z_min = map_border_z
			region_02.z_max = (hex_grid.cell_count_z / 2) - map_border_z
			_regions.append(region_02)
			
			var region_03: MapRegion = MapRegion.new()
			region_03.x_min = hex_grid.cell_count_x / 2 + region_border
			region_03.x_max = hex_grid.cell_count_x - map_border_x
			region_03.z_min = hex_grid.cell_count_z / 2 + region_border
			region_03.z_max = hex_grid.cell_count_z - map_border_z
			_regions.append(region_03)
			
			var region_04: MapRegion = MapRegion.new()
			region_04.x_min = map_border_x
			region_04.x_max = (hex_grid.cell_count_x / 2) - region_border
			region_04.z_min = hex_grid.cell_count_z / 2 + region_border
			region_04.z_max = hex_grid.cell_count_z - map_border_z
			_regions.append(region_04)
			
			pass
		_:
			var region: MapRegion = MapRegion.new()
			region.x_min = map_border_x
			region.x_max = hex_grid.cell_count_x - map_border_x
			region.z_min = map_border_z
			region.z_max = hex_grid.cell_count_z - map_border_z
			_regions.append(region)

func _create_land () -> void:
	var land_budget: int = roundi(_cell_count * land_percentage * 0.01)
	
	for guard in range(0, 10000):
		#Generate a value indicating whether we should sink or raise land
		var should_sink: bool = _rng.randf() < sink_probability
		
		#Iterate over each region
		for i in range(0, len(_regions)):
			var region: MapRegion = _regions[i]
			var chunk_size: int = _rng.randi_range(chunk_size_min, chunk_size_max)
			if (should_sink):
				land_budget = _sink_terrain(chunk_size, land_budget, region)
			else:
				land_budget = _raise_terrain(chunk_size, land_budget, region)
				if (land_budget == 0):
					return
		
	if (land_budget > 0):
		print_debug("Failed to use up " + str(land_budget) + " land budget.")

func _set_terrain_type () -> void:
	for i in range(0, _cell_count):
		var cell: HexCell = hex_grid.get_cell_from_index(i)
		var moisture: float = _climate[i].moisture
		if (not cell.is_underwater):
			if (moisture < 0.05):
				cell.terrain_type_index = 4
			elif (moisture < 0.12):
				cell.terrain_type_index = 0
			elif (moisture < 0.28):
				cell.terrain_type_index = 3
			elif (moisture < 0.85):
				cell.terrain_type_index = 1
			else:
				cell.terrain_type_index = 2
		else:
			cell.terrain_type_index = 2
			
		cell.set_map_data(moisture)

func _raise_terrain (chunk_size: int, budget: int, region: MapRegion) -> int:
	_search_frontier_phase += 1
	var first_cell: HexCell = _get_random_cell(region)
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

func _sink_terrain (chunk_size: int, budget: int, region: MapRegion) -> int:
	_search_frontier_phase += 1
	var first_cell: HexCell = _get_random_cell(region)
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

func _erode_land () -> void:
	var erodible_cells: Array[HexCell] = []
	
	for i in range(0, _cell_count):
		var cell: HexCell = hex_grid.get_cell_from_index(i)
		if (_is_erodible(cell)):
			erodible_cells.append(cell)
	
	var target_erodible_count: int = int(len(erodible_cells) * (100 - erosion_percentage) * 0.01)
	
	while (len(erodible_cells) > target_erodible_count):
		var index: int = _rng.randi_range(0, len(erodible_cells) - 1)
		var cell: HexCell = erodible_cells[index]
		var target_cell: HexCell = _get_erosion_target(cell)
		
		cell.elevation -= 1
		target_cell.elevation += 1
		
		if (not _is_erodible(cell)):
			erodible_cells.erase(cell)
	
		for d in range(0, 6):
			var neighbor: HexCell = cell.get_neighbor(d)
			if ((neighbor) and 
				(neighbor.elevation == cell.elevation + 2) and
				(neighbor not in erodible_cells)):
				
				erodible_cells.append(neighbor)
		
		if (_is_erodible(target_cell) and (target_cell not in erodible_cells)):
			erodible_cells.append(target_cell)
		
		for d in range(0, 6):
			var neighbor: HexCell = target_cell.get_neighbor(d)
			if ((neighbor) and 
				(neighbor != cell) and 
				(neighbor.elevation == (target_cell.elevation + 1)) and 
				(not _is_erodible(neighbor))):
				
				erodible_cells.erase(neighbor)
	
func _is_erodible (cell: HexCell) -> bool:
	var erodible_elevation: int = cell.elevation - 2
	for d in range(0, 6):
		var neighbor: HexCell = cell.get_neighbor(d)
		if (neighbor) and (neighbor.elevation <= erodible_elevation):
			return true
	
	return false

func _get_erosion_target (cell: HexCell) -> HexCell:
	var candidates: Array[HexCell] = []
	var erodible_elevation: int = cell.elevation - 2
	
	for d in range(0, 6):
		var neighbor: HexCell = cell.get_neighbor(d)
		if (neighbor) and (neighbor.elevation <= erodible_elevation):
			candidates.append(neighbor)
	
	var target: HexCell = candidates[_rng.randi_range(0, len(candidates) - 1)]
	return target

func _create_climate () -> void:
	#Clear the list
	_climate.clear()
	
	#Add an empty climate object for each cell
	for i in range(0, _cell_count):
		var initial_data: ClimateData = ClimateData.new()
		initial_data.moisture = starting_moisture
		_climate.append(initial_data)
		
		var initial_data_02: ClimateData = ClimateData.new()
		_next_climate.append(initial_data_02)
	
	#Evolve the climate of each cell
	for cycle in range(0, 40):
		for i in range(0, _cell_count):
			_evolve_climate(i)
		
		var swap_list: Array[ClimateData] = _climate
		_climate = _next_climate
		_next_climate = swap_list

func _evolve_climate (cell_index: int) -> void:
	var cell: HexCell = hex_grid.get_cell_from_index(cell_index)
	var cell_climate: ClimateData = _climate[cell_index]
	
	if (cell.is_underwater):
		cell_climate.clouds += evaporation_factor
	else:
		var evaporation: float = cell_climate.moisture * evaporation_factor
		cell_climate.moisture -= evaporation
		cell_climate.clouds += evaporation
		
	var precipitation: float = cell_climate.clouds * precipitation_factor
	cell_climate.clouds -= precipitation
	cell_climate.moisture += precipitation
	
	var cloud_maximum: float = 1.0 - float(cell.view_elevation / float(elevation_maximum + 1.0))
	if (cell_climate.clouds > cloud_maximum):
		cell_climate.moisture += cell_climate.clouds - cloud_maximum
		cell_climate.clouds = cloud_maximum
	
	var main_dispersal_direction: HexDirectionsClass.HexDirections = HexDirectionsClass.opposite(wind_direction)
	var cloud_dispersal: float = cell_climate.clouds * (1.0 / (5.0 + wind_strength))
	var runoff: float = cell_climate.moisture * runoff_factor * (1.0 / 6.0)
	var seepage: float = cell_climate.moisture * seepage_factor * (1.0 / 6.0) 
	for d in range(0, 6):
		var neighbor: HexCell = cell.get_neighbor(d)
		if (neighbor == null):
			continue
		
		var neighbor_climate: ClimateData = _next_climate[neighbor.index]
		if (d == main_dispersal_direction):
			neighbor_climate.clouds += cloud_dispersal * wind_strength
		else:
			neighbor_climate.clouds += cloud_dispersal
		
		var elevation_data: int = neighbor.view_elevation - cell.view_elevation
		if (elevation_data < 0):
			cell_climate.moisture -= runoff
			neighbor_climate.moisture += runoff
		elif (elevation_data == 0):
			cell_climate.moisture -= seepage
			neighbor_climate.moisture += seepage
		
		_next_climate[neighbor.index] = neighbor_climate
	
	cell_climate.clouds = 0.0
	
	var next_cell_climate: ClimateData = _next_climate[cell_index]
	next_cell_climate.moisture += minf(cell_climate.moisture, 1.0)
	_next_climate[cell_index] = next_cell_climate
	_climate[cell_index] = ClimateData.new()


#endregion
