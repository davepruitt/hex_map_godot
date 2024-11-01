class_name HexGrid
extends Node3D

#region Exported variables

## This is the prefab used for instantiating units
@export var unit_prefab: PackedScene

## These are colors available for hex cells
@export var hex_colors: Array[Color] = [
	Color.YELLOW,
	Color.GREEN,
	Color.BLUE,
	Color.ORANGE,
	Color.WHITE
]

@export var hex_textures: Array[Texture2D]

## The number of cells in the X direction
@export var cell_count_x: int = 0

## The number of cells in the Z direction
@export var cell_count_z: int = 0

## This is the scene that will be used for each hex cell in the grid
@export var hex_cell_prefab: PackedScene

## This is the default ShaderMaterial that will be used for textured terrain in the hex grid
@export var textured_terrain_shader_material: ShaderMaterial

## This is the default ShaderMaterial that will be used for the rivers in the hex grid
@export var river_shader_material: ShaderMaterial

## This is the default ShaderMaterial that will be used for the roads in the hex grid
@export var road_shader_material: ShaderMaterial

## This is the default ShaderMaterial that will be used for the water in the hex grid
@export var water_shader_material: ShaderMaterial

## This is the default ShaderMaterial that will be used for the shore water in the hex grid
@export var water_shore_shader_material: ShaderMaterial

## This is the default ShaderMaterial that will be used for estuaries in the hex grid
@export var estuaries_shader_material: ShaderMaterial

## This is the default material for walls
@export var walls_material: StandardMaterial3D

#endregion

#region On-Ready variables

#@onready var hex_texture: Texture2DArray = preload("res://assets/terrain.png")

#endregion

#region Private variables

## A list of HexGridChunk objects that form the hex grid
var _hex_grid_chunks: Array[HexGridChunk] = []

## A list of all HexCell objects in the hex grid
var _hex_cells: Array[HexCell] = []

## This is the number of chunks in the x-direction of the hex grid
var _chunk_count_x: int = 2

## This is the number of chunks in the y-direction of the hex grid
var _chunk_count_z: int = 2

## This boolean value indicates whether the hex grid overlay is currently enabled
var _hex_grid_overlay_enabled: bool = false

## This priority queue contains the search frontier for the currently active search operation
var _search_frontier: HexCellPriorityQueue

var _search_frontier_phase: int = 0

var _current_path_from: HexCell = null

var _current_path_to: HexCell = null

var _current_path_exists: bool = false

var _units: Array[HexUnit] = []

var _cell_shader_data: HexCellShaderData = null

#endregion

#region Public data members

var hex_grid_overlay_enabled: bool:
	get:
		return _hex_grid_overlay_enabled
	set(value):
		if (_hex_grid_overlay_enabled != value):
			_hex_grid_overlay_enabled = value
			textured_terrain_shader_material.set_shader_parameter("grid_on", _hex_grid_overlay_enabled)

#endregion

#region Method overrides

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#Set the colors on the HexMetrics class
	HexMetrics.colors = hex_colors
	
	#Initialize the Perlin noise
	HexMetrics.initialize_noise_generator()
	
	#Initialize the hash grid
	HexMetrics.initialize_hash_grid()
	
	#Set the unit prefab on the HexUnit class
	HexUnit.unit_prefab = unit_prefab
	
	#Create the map
	create_map(cell_count_x, cell_count_z)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	for i in range(0, len(_hex_grid_chunks)):
		var current_chunk: HexGridChunk = _hex_grid_chunks[i]
		if (current_chunk.update_needed):
			current_chunk.refresh()
	
	if (_cell_shader_data):
		_cell_shader_data.late_update()
	
#endregion

#region Properties

var has_path: bool:
	get:
		return _current_path_exists

#endregion

#region Public methods

func create_map (map_size_x: int, map_size_z: int) -> bool:
	#Return immediately if this is an unsupported map size
	if ((map_size_x <= 0) or 
		(map_size_x % HexMetrics.CHUNK_SIZE_X != 0) or
		(map_size_z <= 0) or
		(map_size_z % HexMetrics.CHUNK_SIZE_Z != 0)):
		
		return false
	
	#Clear any existing path
	clear_path()
	
	#Clear any existing units
	_clear_units()
	
	#Destroy existing chunks
	if (_hex_grid_chunks != null):
		#Remove each chunk from the scene
		for i in range(0, len(_hex_grid_chunks)):
			remove_child(_hex_grid_chunks[i])
			
		#Clear the list of chunks
		_hex_grid_chunks.clear()
	
	#Set the cell counts in each axis direction
	cell_count_x = map_size_x
	cell_count_z = map_size_z
	
	#Calculate the chunk count count in the x and z directions
	_chunk_count_x = cell_count_x / HexMetrics.CHUNK_SIZE_X
	_chunk_count_z = cell_count_z / HexMetrics.CHUNK_SIZE_Z
	
	if (_cell_shader_data == null):
		_cell_shader_data = HexCellShaderData.new()
	_cell_shader_data.initialize(cell_count_x, cell_count_z)
	
	_create_chunks()
	_create_cells()
	
	for i in range(0, len(_hex_grid_chunks)):
		_hex_grid_chunks[i].set_terrain_mesh_material(textured_terrain_shader_material)
		_hex_grid_chunks[i].set_rivers_mesh_material(river_shader_material)
		_hex_grid_chunks[i].set_road_mesh_material(road_shader_material)
		_hex_grid_chunks[i].set_water_mesh_material(water_shader_material)
		_hex_grid_chunks[i].set_water_shore_mesh_material(water_shore_shader_material)
		_hex_grid_chunks[i].set_estuaries_mesh_material(estuaries_shader_material)
		_hex_grid_chunks[i].set_walls_mesh_material(walls_material)
		_hex_grid_chunks[i].refresh()
		
		#TO DO: bug.
		#Currently encountering a bug that requires me to call request refresh even though
		#we just finished calling the refresh function. This amounts to a double-refresh operation
		#after creating a new map. Not sure why this is necessary as of this moment. 
		#Needs investigation.
		_hex_grid_chunks[i].request_refresh()
	
	#Return true, indicating the map was created successfully
	return true

func get_cell_from_coordinates (coordinates: HexCoordinates) -> HexCell:
	var z: int = coordinates.Z
	if (z < 0) or (z >= cell_count_z):
		return null
	
	var x: int = coordinates.X + z / 2
	if (x < 0) or (x >= cell_count_x):
		return null
	
	var result: HexCell = _hex_cells[x + z * cell_count_x]
	return result

func get_cell_from_ray (ray_query: PhysicsRayQueryParameters3D) -> HexCell:
	var space_state = get_world_3d().direct_space_state
	
	var result = space_state.intersect_ray(ray_query)
	if result:
		var cell = get_cell(result.position)
		return cell
	
	return null

func get_cell (position: Vector3) -> HexCell:
	#Convert the global position to a position within the hex grid
	var inverse_transform_point = position * global_transform
	
	#Convert the position in the hex grid to a set of coordinates within the hex grid
	var coordinates: HexCoordinates = HexCoordinates.FromPosition(inverse_transform_point)
	
	#Find the index into the _hex_cells list for which hex object we want
	var index = coordinates.X + coordinates.Z * cell_count_x + coordinates.Z / 2.0
	
	#Get the selected hex cell object
	var cell = _hex_cells[index] as HexCell
	
	#Return the cell
	return cell
	
func set_all_cell_label_modes (label_mode: HexCell.CellInformationLabelMode) -> void:
	for i in range(0, len(_hex_cells)):
		_hex_cells[i].cell_label_mode = label_mode

func save_hex_grid (file_writer: FileAccess) -> void:
	#Save the map size
	file_writer.store_32(cell_count_x)
	file_writer.store_32(cell_count_z)
	
	#Save each cell
	for i in range(0, len(_hex_cells)):
		_hex_cells[i].save_hex_cell(file_writer)
	
	#Save the number of units
	file_writer.store_32(len(_units))
	
	#Save each unit
	for i in range(0, len(_units)):
		_units[i].save_to_file(file_writer)
	
func load_hex_grid (file_reader: FileAccess, file_version: int) -> void:
	#Clear any path visualization that may currently exist
	clear_path()

	#Clear any existing units
	_clear_units()
	
	#Set the default map size
	var new_map_size_x: int = 20
	var new_map_size_z: int = 15
	
	#Load the map size if the file version is high enough
	if (file_version >= 1):
		new_map_size_x = file_reader.get_32()
		new_map_size_z = file_reader.get_32()
	
	#Create the map
	if (new_map_size_x != cell_count_x) or (new_map_size_z != cell_count_z):
		var create_map_success: bool = create_map(new_map_size_x, new_map_size_z)
		if (not create_map_success):
			return
	
	#Load each cell
	for i in range(0, len(_hex_cells)):
		_hex_cells[i].load_hex_cell(file_reader)
	
	#Refresh each cell
	for i in range(0, len(_hex_cells)):
		_hex_cells[i]._refresh()
	
	#If this is file version 2 or greater...
	if (file_version >= 2):
		#Read how many units to load from the file
		var unit_count: int = file_reader.get_32()
		
		#Read in each unit
		for i in range(0, unit_count):
			HexUnit.load_from_file(file_reader, self)

func find_path (from_cell: HexCell, to_cell: HexCell, speed: int) -> void:
	#Return immediatley if either the start or destination is null
	if (from_cell == null) or (to_cell == null):
		return
	
	#Clear any old path visualization that may exist
	clear_path()
	
	#Run the path finding algorithm
	_current_path_from = from_cell
	_current_path_to = to_cell
	_current_path_exists = _dijkstra_search_from_to(from_cell, to_cell, speed)
	
	#If a path was found, display the visualization on the hex map
	_show_path(speed)

func clear_path () -> void:
	if (_current_path_exists):
		var current: HexCell = _current_path_to
		while (current != _current_path_from):
			current.set_label("")
			current.disable_highlight()
			current = current.path_from
		
		current.disable_highlight()
		_current_path_exists = false
	elif (_current_path_from):
		_current_path_from.disable_highlight()
		_current_path_to.disable_highlight()
	
	_current_path_from = null
	_current_path_to = null

func get_unit_path () -> Array[HexCell]:
	if (not _current_path_exists):
		return []
	
	var path: Array[HexCell] = []
	var c: HexCell = _current_path_to
	while (c != _current_path_from):
		path.append(c)
		c = c.path_from
	
	path.append(_current_path_from)
	path.reverse()
	
	return path

func disable_all_cell_highlights () -> void:
	for i in range(0, len(_hex_cells)):
		_hex_cells[i].disable_highlight()

func reset_all_cell_distances () -> void:
	for i in range(0, len(_hex_cells)):
		_hex_cells[i].distance = GodotConstants.MAX_INT

func reset_all_cell_labels () -> void:
	for i in range(0, len(_hex_cells)):
		_hex_cells[i].set_label("")

func add_unit (unit: HexUnit, location: HexCell, orientation: float) -> void:
	#Add the unit to the list of units for the hex map
	_units.append(unit)
	
	#Add the unit as a child of the hex map scene
	add_child(unit)
	
	#Set the location and orientation of the unit
	unit.location = location
	unit.orientation = orientation

func remove_unit (unit: HexUnit) -> void:
	_units.erase(unit)
	unit.die()

#endregion

#region Private methods

func _create_chunks () -> void:
	#Clear the hex grid chunks array
	_hex_grid_chunks = []
	
	#Iterate over each chunk
	for z in range(0, _chunk_count_z):
		for x in range(0, _chunk_count_x):
			#Instantiate this chunk
			var chunk: HexGridChunk = HexGridChunk.new()
			
			#Add it to the list of chunks
			_hex_grid_chunks.append(chunk)
			
			#Add this chunk as a child of the hex grid
			add_child(chunk)

func _create_cells () -> void:
	#Clear the list of hex cells
	_hex_cells = []
	
	#Iterate over the height and width of the hex grid
	var i = 0
	for z in range(0, cell_count_z):
		for x in range(0, cell_count_x):
			#Create the hex cell at this position in the grid
			_create_cell(z, x, i)
			
			#Increment i
			i += 1

func _create_cell(z: int, x: int, i: int) -> void:
	#Create a Vector3 to store the new hex's position
	var hex_position: Vector3 = Vector3(
		(x + z * 0.5 - (z / 2)) * (HexMetrics.INNER_RADIUS * 2.0), 
		0.0, 
		z * (HexMetrics.OUTER_RADIUS * 1.5)
	)
	
	#Instantiate a hex cell object
	var hex_cell: HexCell = hex_cell_prefab.instantiate() as HexCell
	
	#Set the west neighbor of the hex cell
	if (x > 0):
		hex_cell.set_neighbor(HexDirectionsClass.HexDirections.W, _hex_cells[i - 1])
	
	#Set the south-east and south-west neighbors of the hex cell
	if (z > 0):
		if (z & 1) == 0:
			#If this is an even row...
			
			#Set the south-east neighbor of the hex cell
			hex_cell.set_neighbor(HexDirectionsClass.HexDirections.SE, _hex_cells[i - cell_count_x])
			
			if (x > 0):
				#Set the south-west neighbor of the hex cell
				hex_cell.set_neighbor(HexDirectionsClass.HexDirections.SW, _hex_cells[i - cell_count_x - 1])
		else:
			#If this is an odd row...
			
			#Set the south-west neighbor of the hex cell
			hex_cell.set_neighbor(HexDirectionsClass.HexDirections.SW, _hex_cells[i - cell_count_x])
			
			if (x < cell_count_x - 1):
				#Set the south-east neighbor of the hex cell
				hex_cell.set_neighbor(HexDirectionsClass.HexDirections.SE, _hex_cells[i - cell_count_x + 1])
	
	#Set the position of the hex cell in the scene
	hex_cell.position = hex_position
	
	#Set the initial elevation of the hex cell
	hex_cell.elevation = 0
	
	#Set the coordinates of the hex cell within the grid
	hex_cell.hex_coordinates = HexCoordinates.FromOffsetCoordinates(x, z)
	
	#Set the cell index
	hex_cell.index = i
	
	#Set the shader data
	hex_cell.shader_data = _cell_shader_data
	
	#Set the initial distance value to max int
	hex_cell.distance = GodotConstants.MAX_INT
	
	#Set the coordinates/position label on the hex cell
	hex_cell.cell_label_mode = HexCell.CellInformationLabelMode.Position
	
	#Add the cell to the array of cells
	_hex_cells.append(hex_cell)
	
	#Add the cell to the chunk
	_add_cell_to_chunk(x, z, hex_cell)

func _add_cell_to_chunk (x: int, z: int, cell: HexCell) -> void:
	var chunk_x: int = x / HexMetrics.CHUNK_SIZE_X
	var chunk_z: int = z / HexMetrics.CHUNK_SIZE_Z
	
	var chunk_index: int = chunk_x + chunk_z * _chunk_count_x
	var chunk: HexGridChunk = _hex_grid_chunks[chunk_index]
	
	if (chunk_index == 0):
		cell.hex_color = Color.YELLOW
	elif (chunk_index == 1):
		cell.hex_color = Color.GREEN
	elif (chunk_index == 2):
		cell.hex_color = Color.BLUE
	elif (chunk_index == 3):
		cell.hex_color = Color.WHITE
	
	var local_x: int = x - chunk_x * HexMetrics.CHUNK_SIZE_X
	var local_z: int = z - chunk_z * HexMetrics.CHUNK_SIZE_Z
	
	chunk.add_cell(local_x + local_z * HexMetrics.CHUNK_SIZE_X, cell)

func _show_path (speed: int) -> void:
	if (_current_path_exists):
		var current: HexCell = _current_path_to
		while (current != _current_path_from):
			var turn: int = (current.distance - 1) / speed
			current.set_label(str(turn))
			current.enable_highlight(Color.WHITE)
			current = current.path_from
	
	_current_path_from.enable_highlight(Color.BLUE)
	_current_path_to.enable_highlight(Color.RED)

func _dijkstra_search_from_to (from_cell: HexCell, to_cell: HexCell, speed: int) -> bool:
	_search_frontier_phase += 2
	
	#Instantiate the search frontier
	if (_search_frontier == null):
		_search_frontier = HexCellPriorityQueue.new()
	else:
		_search_frontier.clear()
	
	#Enable the highlight on the from cell
	from_cell.enable_highlight(Color.BLUE)
	
	#Set the distance of the selected cell as 0
	from_cell.search_phase = _search_frontier_phase
	from_cell.distance = 0
	
	#Add the selected cell to the frontier queue
	_search_frontier.enqueue(from_cell)
	
	#Iterate while the frontier queue has elements in it
	while (_search_frontier.count > 0):
		#Dequeue the front
		var current: HexCell = _search_frontier.dequeue() as HexCell
		current.search_phase += 1
		
		#If the current cell is the destination cell
		if (current == to_cell):
			#Return true, indicating a path was found
			return true
		
		var current_turn: int = (current.distance - 1) / speed
		
		#Iterate over the cell's neighbors
		for d in range(0, 6):
			#Get the neighbor
			var neighbor: HexCell = current.get_neighbor(d)
			
			##Skip the neighbor if certain criteria are met
			if (neighbor == null) or (neighbor.search_phase > _search_frontier_phase):
				continue
			
			if (neighbor.is_underwater) or (neighbor.unit):
				continue

			var edge_type: Enums.HexEdgeType = current.get_edge_type_from_other_cell(neighbor)
			if (edge_type == Enums.HexEdgeType.Cliff):
				continue
			
			var movement_cost: int = 0
			
			#If there is a road going through the edge of the direction of travel, 
			#then increase the distance by 1 (roads provide fast travel)
			if (current.has_road_through_edge(d)):
				movement_cost = 1
			elif (current.walled != neighbor.walled):
				#Walls block movement if there is no road
				continue
			else:
				if (edge_type == Enums.HexEdgeType.Flat):
					#If the terrain is flat, increase distance by 5
					movement_cost = 5
				else:
					#Otherwise, increase the distance by 10 (slower travel)
					movement_cost = 10
				
				#If there are any terrain features (buildings, trees, etc), then add
				#some extra distance for traversing through that cell
				movement_cost += neighbor.urban_level + neighbor.farm_level + neighbor.plant_level
			
			var distance: int = current.distance + movement_cost
			var turn: int = (distance - 1) / speed
			if (turn > current_turn):
				distance = turn * speed + movement_cost
			
			#If the neighbor cell has no computed distance yet, 
			#set the distance and add it to the frontier
			if (neighbor.search_phase < _search_frontier_phase):
				neighbor.search_phase = _search_frontier_phase
				neighbor.distance = distance
				neighbor.path_from = current
				neighbor.search_heuristic = neighbor.hex_coordinates.DistanceTo(to_cell.hex_coordinates)
				_search_frontier.enqueue(neighbor)
			elif (distance < neighbor.distance):
				#Otherwise, if the newly computed distance is less than a previously computed
				#distance, then set it
				var old_priority: int = neighbor.search_priority
				neighbor.distance = distance
				neighbor.path_from = current
				_search_frontier.change(neighbor, old_priority)
			
	#Return false, indicating no path was found
	return false

func _clear_units () -> void:
	for i in range(0, len(_units)):
		_units[i].die()
	_units.clear()

#endregion
