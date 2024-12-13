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

## Whether the grid is wrapped
@export var wrapping: bool = false

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
@export var walls_material: ShaderMaterial

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

var _columns: Array[Node3D] = []

var _current_center_column_index: int = -1

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
	create_map(cell_count_x, cell_count_z, wrapping)
	

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

func create_map (map_size_x: int, map_size_z: int, should_wrap: bool) -> bool:
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
	
	#Destroy existing columns
	if (_columns):
		for i in range(0, len(_columns)):
			remove_child(_columns[i])
	
	#Set the cell counts in each axis direction
	cell_count_x = map_size_x
	cell_count_z = map_size_z
	
	#Set the wrapping stauts
	wrapping = should_wrap
	
	#Set the HexMetrics wrapping variable
	HexMetrics.wrap_size = cell_count_x if wrapping else 0
	
	#Set the center column index
	_current_center_column_index = -1
	
	#Calculate the chunk count count in the x and z directions
	_chunk_count_x = cell_count_x / HexMetrics.CHUNK_SIZE_X
	_chunk_count_z = cell_count_z / HexMetrics.CHUNK_SIZE_Z
	
	if (_cell_shader_data == null):
		_cell_shader_data = HexCellShaderData.new()
	_cell_shader_data.initialize(cell_count_x, cell_count_z)
	_cell_shader_data.hex_grid = self
	
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

func get_cell_from_offset (x_offset: int, z_offset: int) -> HexCell:
	return _hex_cells[x_offset + (z_offset * cell_count_x)]

func get_cell_from_index (cell_index: int) -> HexCell:
	return _hex_cells[cell_index]

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
	
	#Return the cell
	return get_cell_from_coordinates(coordinates)
	
func set_all_cell_label_modes (label_mode: HexCell.CellInformationLabelMode) -> void:
	for i in range(0, len(_hex_cells)):
		_hex_cells[i].cell_label_mode = label_mode

func save_hex_grid (file_writer: FileAccess) -> void:
	#Save the map size
	file_writer.store_32(cell_count_x)
	file_writer.store_32(cell_count_z)
	
	#Save the wrapping stauts
	file_writer.store_8(wrapping)
	
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
	
	var should_wrap: bool = false
	if (file_version >= 5):
		should_wrap = bool(file_reader.get_8())
	
	#Create the map
	if (new_map_size_x != cell_count_x) or (new_map_size_z != cell_count_z) or (wrapping != should_wrap):
		var create_map_success: bool = create_map(new_map_size_x, new_map_size_z, should_wrap)
		if (not create_map_success):
			return
	
	#Load each cell
	for i in range(0, len(_hex_cells)):
		_hex_cells[i].load_hex_cell(file_reader, file_version)
	
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

func find_path (from_cell: HexCell, to_cell: HexCell, unit: HexUnit) -> void:
	#Return immediatley if either the start or destination is null
	if (from_cell == null) or (to_cell == null):
		return
	
	#Clear any old path visualization that may exist
	clear_path()
	
	#Run the path finding algorithm
	_current_path_from = from_cell
	_current_path_to = to_cell
	_current_path_exists = _dijkstra_search_from_to(from_cell, to_cell, unit)
	
	#If a path was found, display the visualization on the hex map
	_show_path(unit.speed)

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
	
	#Set the grid property on the unit
	unit.hex_grid = self
	
	#Set the location and orientation of the unit
	unit.location = location
	unit.orientation = orientation

func remove_unit (unit: HexUnit) -> void:
	_units.erase(unit)
	unit.die()

func increase_visibility_in_game (from_cell: HexCell, visibility_range: int) -> void:
	var cells: Array[HexCell] = _dijkstra_get_visible_cells(from_cell, visibility_range)
	for i in range(0, len(cells)):
		cells[i].increase_visibility_in_game()
	
func decrease_visibility_in_game (from_cell: HexCell, visibility_range: int) -> void:
	var cells: Array[HexCell] = _dijkstra_get_visible_cells(from_cell, visibility_range)
	for i in range(0, len(cells)):
		cells[i].decrease_visibility_in_game()

func reset_visibility () -> void:
	for i in range(0, len(_hex_cells)):
		_hex_cells[i].reset_visibility()
	
	for i in range(0, len(_units)):
		var unit: HexUnit = _units[i]
		increase_visibility_in_game(unit.location, unit.vision_range)

func center_map (x_position: float) -> void:
	var center_column_index: int = int(x_position / (HexMetrics.INNER_DIAMETER * HexMetrics.CHUNK_SIZE_X))
	
	if (center_column_index == _current_center_column_index):
		return
	
	_current_center_column_index = center_column_index
	
	var min_column_index: int = center_column_index - (_chunk_count_x / 2)
	var max_column_index: int = center_column_index + (_chunk_count_x / 2)
	
	var pos: Vector3 = Vector3.ZERO
	for i in range(0, len(_columns)):
		if (i < min_column_index):
			pos.x = _chunk_count_x * (HexMetrics.INNER_DIAMETER * HexMetrics.CHUNK_SIZE_X)
		elif (i > max_column_index):
			pos.x = _chunk_count_x * -(HexMetrics.INNER_DIAMETER * HexMetrics.CHUNK_SIZE_X)
		else:
			pos.x = 0.0
		
		_columns[i].position = pos

#endregion

#region Private methods

func _create_chunks () -> void:
	#Resize the columns array
	if (_columns):
		_columns.clear()
	_columns.resize(_chunk_count_x)
	
	#Add each column's Node3D object to the scene hierarchy
	for x in range(0, _chunk_count_x):
		_columns[x] = Node3D.new()
		add_child(_columns[x])
	
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
			_columns[x].add_child(chunk)

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
		(x + z * 0.5 - (z / 2)) * HexMetrics.INNER_DIAMETER, 
		0.0, 
		z * (HexMetrics.OUTER_RADIUS * 1.5)
	)
	
	#Instantiate a hex cell object
	var hex_cell: HexCell = hex_cell_prefab.instantiate() as HexCell
	
	#Set the west neighbor of the hex cell
	if (x > 0):
		hex_cell.set_neighbor(HexDirectionsClass.HexDirections.W, _hex_cells[i - 1])
		
		if (wrapping) and (x == cell_count_x - 1):
			hex_cell.set_neighbor(HexDirectionsClass.HexDirections.E, _hex_cells[i - x])
	
	#Set the south-east and south-west neighbors of the hex cell
	if (z > 0):
		if (z & 1) == 0:
			#If this is an even row...
			
			#Set the south-east neighbor of the hex cell
			hex_cell.set_neighbor(HexDirectionsClass.HexDirections.SE, _hex_cells[i - cell_count_x])
			
			if (x > 0):
				#Set the south-west neighbor of the hex cell
				hex_cell.set_neighbor(HexDirectionsClass.HexDirections.SW, _hex_cells[i - cell_count_x - 1])
			elif (wrapping):
				hex_cell.set_neighbor(HexDirectionsClass.HexDirections.SW, _hex_cells[i - 1])
		else:
			#If this is an odd row...
			
			#Set the south-west neighbor of the hex cell
			hex_cell.set_neighbor(HexDirectionsClass.HexDirections.SW, _hex_cells[i - cell_count_x])
			
			if (x < cell_count_x - 1):
				#Set the south-east neighbor of the hex cell
				hex_cell.set_neighbor(HexDirectionsClass.HexDirections.SE, _hex_cells[i - cell_count_x + 1])
			elif (wrapping):
				hex_cell.set_neighbor(HexDirectionsClass.HexDirections.SE, _hex_cells[i - cell_count_x * 2 + 1])
	
	#Set the position of the hex cell in the scene
	hex_cell.position = hex_position
	
	#Set the initial elevation of the hex cell
	hex_cell.elevation = 0
	
	#Set the coordinates of the hex cell within the grid
	hex_cell.hex_coordinates = HexCoordinates.FromOffsetCoordinates(x, z)
	
	#Set the cell index
	hex_cell.index = i
	
	#Set the cell's column index
	hex_cell.column_index = x / HexMetrics.CHUNK_SIZE_X
	
	#Set the shader data
	hex_cell.shader_data = _cell_shader_data
	
	#Set whether the cell is explorable
	hex_cell.explorable = (x > 0) and (z > 0) and (x < (cell_count_x - 1)) and (z < (cell_count_z - 1))
	
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

func _dijkstra_search_from_to (from_cell: HexCell, to_cell: HexCell, unit: HexUnit) -> bool:
	var speed: int = unit.speed
	
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
			
			if (not unit.is_valid_destination(neighbor)):
				continue
			
			var movement_cost:int = unit.get_move_cost(current, neighbor, d)
			if (movement_cost < 0):
				continue
			
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

func _dijkstra_get_visible_cells (from_cell: HexCell, vision_range: int) -> Array[HexCell]:
	#Initialize an empty result list
	var visible_cells: Array[HexCell] = []
	
	#Initialize the search frontier
	_search_frontier_phase += 2
	if (_search_frontier == null):
		_search_frontier = HexCellPriorityQueue.new()
	else:
		_search_frontier.clear()
	
	vision_range += from_cell.view_elevation
	from_cell.search_phase = _search_frontier_phase
	from_cell.distance = 0
	_search_frontier.enqueue(from_cell)
	
	var from_coordinates: HexCoordinates = from_cell.hex_coordinates
	
	#Iterate over the frontier
	while (_search_frontier.count > 0):
		#Get the next cell from the search frontier
		var current: HexCell = _search_frontier.dequeue()
		current.search_phase += 1
		
		#Add the current cell to the list of visible cells
		visible_cells.append(current)
		
		#Iterate over each direction
		for d in range(0, 6):
			#Get the neighbor in the specified direction
			var neighbor: HexCell = current.get_neighbor(d) as HexCell
			
			#Exit the loop if no neighbor exists, or if this is beyond the search phase
			if (neighbor == null) or (neighbor.search_phase > _search_frontier_phase) or (not neighbor.explorable):
				continue
			
			var distance: int = current.distance + 1
			if (((distance + neighbor.view_elevation) > vision_range) or 
				(distance > from_coordinates.DistanceTo(neighbor.hex_coordinates))):
				
				continue
			
			if (neighbor.search_phase < _search_frontier_phase):
				neighbor.search_phase = _search_frontier_phase
				neighbor.distance = distance
				neighbor.search_heuristic = 0
				_search_frontier.enqueue(neighbor)
			elif (distance < neighbor.distance):
				var old_priority: int = neighbor.search_priority
				neighbor.distance = distance
				_search_frontier.change(neighbor, old_priority)
	
	return visible_cells

func _clear_units () -> void:
	for i in range(0, len(_units)):
		_units[i].die()
	_units.clear()

#endregion






































#region long_file_region
#endregion
