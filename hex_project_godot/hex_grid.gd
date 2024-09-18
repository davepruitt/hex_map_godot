class_name HexGrid
extends Node3D

#region Exported variables

## This is the number of chunks in the x-direction of the hex grid
@export var chunk_count_x: int = 2

## This is the number of chunks in the y-direction of the hex grid
@export var chunk_count_z: int = 2

## This is the scene that will be used for each hex cell in the grid
@export var hex_cell_prefab: PackedScene

## This is the default color for each hex in the grid
@export var default_hex_color: Color

## This is the default ShaderMaterial that will be used for the hex cell's mesh
@export var hex_shader_material: ShaderMaterial

#endregion

#region Private variables

## A list of HexGridChunk objects that form the hex grid
var _hex_grid_chunks: Array[HexGridChunk] = []

## A list of all HexCell objects in the hex grid
var _hex_cells: Array[HexCell] = []

var _hex_colors : Array[Color] = [Color.YELLOW, Color.GREEN, Color.BLUE, Color.WHITE]

var _rng = RandomNumberGenerator.new()

var _cell_count_x: int = 0

var _cell_count_z: int = 0

#endregion

#region Method overrides

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#Set the seed of the random number generator
	_rng.set_seed(1)
	
	#Initialize the Perlin noise
	HexMetrics.initialize_noise_generator()
	
	#Calculate the cell count in the x and z directions
	_cell_count_x = chunk_count_x * HexMetrics.CHUNK_SIZE_X
	_cell_count_z = chunk_count_z * HexMetrics.CHUNK_SIZE_Z
	
	_create_chunks()
	_create_cells()
	
	for i in range(0, len(_hex_grid_chunks)):
		_hex_grid_chunks[i].set_mesh_material(hex_shader_material)
		_hex_grid_chunks[i].refresh()
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	for i in range(0, len(_hex_grid_chunks)):
		var current_chunk: HexGridChunk = _hex_grid_chunks[i]
		if (current_chunk.update_needed):
			current_chunk.refresh()
	
#endregion

#region Public methods

func get_cell_from_coordinates (coordinates: HexCoordinates) -> HexCell:
	var z: int = coordinates.Z
	if (z < 0) or (z >= _cell_count_z):
		return null
	
	var x: int = coordinates.X + z / 2
	if (x < 0) or (x >= _cell_count_x):
		return null
	
	return _hex_cells[x + z * _cell_count_x]

func get_cell (position: Vector3) -> HexCell:
	#Convert the global position to a position within the hex grid
	var inverse_transform_point = position * global_transform
	
	#Convert the position in the hex grid to a set of coordinates within the hex grid
	var coordinates: HexCoordinates = HexCoordinates.FromPosition(inverse_transform_point)
	
	#Find the index into the _hex_cells list for which hex object we want
	var index = coordinates.X + coordinates.Z * _cell_count_x + coordinates.Z / 2.0
	
	#Get the selected hex cell object
	var cell = _hex_cells[index] as HexCell
	
	#Return the cell
	return cell
	

#endregion

#region Private methods

func _create_chunks () -> void:
	#Clear the hex grid chunks array
	_hex_grid_chunks = []
	
	#Iterate over each chunk
	for z in range(0, chunk_count_z):
		for x in range(0, chunk_count_x):
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
	for z in range(0, _cell_count_z):
		for x in range(0, _cell_count_x):
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
			hex_cell.set_neighbor(HexDirectionsClass.HexDirections.SE, _hex_cells[i - _cell_count_x])
			
			if (x > 0):
				#Set the south-west neighbor of the hex cell
				hex_cell.set_neighbor(HexDirectionsClass.HexDirections.SW, _hex_cells[i - _cell_count_x - 1])
		else:
			#If this is an odd row...
			
			#Set the south-west neighbor of the hex cell
			hex_cell.set_neighbor(HexDirectionsClass.HexDirections.SW, _hex_cells[i - _cell_count_x])
			
			if (x < _cell_count_x - 1):
				#Set the south-east neighbor of the hex cell
				hex_cell.set_neighbor(HexDirectionsClass.HexDirections.SE, _hex_cells[i - _cell_count_x + 1])
	
	#Set the position of the hex cell in the scene
	hex_cell.position = hex_position
	
	#Set the color of the hex cell
	#var idx = _rng.randi_range(0, 3)
	#hex_cell.hex_color = _hex_colors[idx]
	hex_cell.hex_color = default_hex_color
	
	#Set the initial elevation of the hex cell
	hex_cell.elevation = 0
	#if (hex_cell.hex_color == Color.BLUE):
		#hex_cell.elevation = 0
	#elif (hex_cell.hex_color == Color.WHITE):
		#hex_cell.elevation = 2
	#else:
		#hex_cell.elevation = 1
	
	#Set the coordinates of the hex cell within the grid
	hex_cell.hex_coordinates = HexCoordinates.FromOffsetCoordinates(x, z)
	
	#Set the coordinates/position label on the hex cell
	hex_cell.position_label.text = str(hex_cell.hex_coordinates)
	
	#Add the cell to the array of cells
	_hex_cells.append(hex_cell)
	
	#Add the cell to the chunk
	_add_cell_to_chunk(x, z, hex_cell)

func _add_cell_to_chunk (x: int, z: int, cell: HexCell) -> void:
	var chunk_x: int = x / HexMetrics.CHUNK_SIZE_X
	var chunk_z: int = z / HexMetrics.CHUNK_SIZE_Z
	
	var chunk_index: int = chunk_x + chunk_z * chunk_count_x
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
