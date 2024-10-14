class_name HexGrid
extends Node3D

#region Exported variables

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

## This is the default ShaderMaterial that will be used for the terrain in the hex grid
@export var colored_terrain_shader_material: ShaderMaterial

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

var _hex_grid_overlay_enabled: bool = false

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
	
	#Create the map
	create_map(cell_count_x, cell_count_z)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	for i in range(0, len(_hex_grid_chunks)):
		var current_chunk: HexGridChunk = _hex_grid_chunks[i]
		if (current_chunk.update_needed):
			current_chunk.refresh()
	
#endregion

#region Public methods

func create_map (map_size_x: int, map_size_z: int) -> bool:
	#Return immediately if this is an unsupported map size
	if ((map_size_x <= 0) or 
		(map_size_x % HexMetrics.CHUNK_SIZE_X != 0) or
		(map_size_z <= 0) or
		(map_size_z % HexMetrics.CHUNK_SIZE_Z != 0)):
		
		return false
	
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
	
	_create_chunks()
	_create_cells()
	
	for i in range(0, len(_hex_grid_chunks)):
		if (HexMetrics.display_mode == Enums.DisplayMode.TerrainTextures):
			_hex_grid_chunks[i].set_terrain_mesh_material(textured_terrain_shader_material)
		else:
			_hex_grid_chunks[i].set_terrain_mesh_material(colored_terrain_shader_material)
		_hex_grid_chunks[i].set_rivers_mesh_material(river_shader_material)
		_hex_grid_chunks[i].set_road_mesh_material(road_shader_material)
		_hex_grid_chunks[i].set_water_mesh_material(water_shader_material)
		_hex_grid_chunks[i].set_water_shore_mesh_material(water_shore_shader_material)
		_hex_grid_chunks[i].set_estuaries_mesh_material(estuaries_shader_material)
		_hex_grid_chunks[i].set_walls_mesh_material(walls_material)
		_hex_grid_chunks[i].refresh()
	
	#Return true, indicating the map was created successfully
	return true

func get_cell_from_coordinates (coordinates: HexCoordinates) -> HexCell:
	var z: int = coordinates.Z
	if (z < 0) or (z >= cell_count_z):
		return null
	
	var x: int = coordinates.X + z / 2
	if (x < 0) or (x >= cell_count_x):
		return null
	
	return _hex_cells[x + z * cell_count_x]

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
	
func load_hex_grid (file_reader: FileAccess, file_version: int) -> void:
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

func find_distance_to_cell (cell: HexCell) -> void:
	for i in range(0, len(_hex_cells)):
		_hex_cells[i].distance = cell.hex_coordinates.DistanceTo(_hex_cells[i].hex_coordinates)

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

#endregion
