class_name HexCellShaderData

#region Private data members

var _cell_texture_source_image: Image = null
var _cell_texture: ImageTexture = null

var _cell_texture_data: PackedColorArray

var _requires_update: bool = false

#endregion

#region Constructor

func _init() -> void:
	pass

#endregion

#region Public methods

func initialize (x: int, z: int) -> void:
	#Calculate the texel size
	var texel_size: Vector4 = Vector4(1.0 / float(x), 1.0 / float(z), x, z)
	
	#Set the size of the texture data color array
	if (len(_cell_texture_data) != (x * z)):
		_cell_texture_data.resize(x * z)
	
	#Initialize each color to all zeros
	#In this case, the color object is being used to store NON-COLOR information
	#Each color object in the array represents a cell in the hex grid
	#The final element of each color object (the last 4 bytes) will store the terrain index of the cell
	for i in range(0, len(_cell_texture_data)):
		_cell_texture_data[i] = Color(0, 0, 0, 0)
	
	#Create an empty source image
	_cell_texture_source_image = Image.create_empty(x, z, false, Image.FORMAT_RGBAF)	
	
	#Create the texture object from the source image
	_cell_texture = ImageTexture.create_from_image(_cell_texture_source_image)
	
	#Set the global shader parameters
	RenderingServer.global_shader_parameter_set("_HexCellData", _cell_texture)
	RenderingServer.global_shader_parameter_set("_HexCellData_TexelSize", texel_size)
	
	#Set a flag indicating that an update is required
	_requires_update = true

func refresh_terrain (cell: HexCell) -> void:
	_cell_texture_data[cell.index].a = cell.terrain_type_index
	_requires_update = true
	
func refresh_visibility (cell: HexCell) -> void:
	_cell_texture_data[cell.index].r = int(cell.is_visible_in_game)
	_requires_update = true

func late_update () -> void:
	if _requires_update:
		_requires_update = false
		
		var x: int = _cell_texture_source_image.get_width()
		var z: int = _cell_texture_source_image.get_height()
		
		var temp_byte_array: PackedByteArray = _cell_texture_data.to_byte_array()
		_cell_texture_source_image.set_data(x, z, false, Image.FORMAT_RGBAF, temp_byte_array)
		_cell_texture.update(_cell_texture_source_image)
	

#endregion
