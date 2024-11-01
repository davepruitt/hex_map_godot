class_name HexCellShaderData

#region Private data members

var _cell_texture_source_image: Image = null
var _cell_texture: ImageTexture = null

var _cell_texture_data: PackedColorArray

#endregion

#region Constructor

func _init() -> void:
	pass

#endregion

#region Public methods

func initialize (x: int, z: int) -> void:
	if (_cell_texture and _cell_texture_source_image):
		_cell_texture_source_image.resize(x, z)
		_cell_texture = ImageTexture.create_from_image(_cell_texture_source_image)
	else:
		_cell_texture_source_image = Image.create_empty(x, z, false, Image.FORMAT_RGBA8)	
		_cell_texture = ImageTexture.create_from_image(_cell_texture_source_image)
		
		RenderingServer.global_shader_parameter_set("_HexCellData", _cell_texture)
	
	var texel_size: Vector4 = Vector4(1.0 / float(x), 1.0 / float(z), x, z)
	RenderingServer.global_shader_parameter_set("_HexCellData_TexelSize", texel_size)
	
	if (len(_cell_texture_data) != (x * z)):
		_cell_texture_data.resize(x * z)
	else:
		for i in range(0, len(_cell_texture_data)):
			_cell_texture_data[i] = Color(0, 0, 0, 0)

func refresh_terrain (cell: HexCell) -> void:
	_cell_texture_data[cell.index].a8 = cell.terrain_type_index

func late_update () -> void:
	var x: int = _cell_texture_source_image.get_width()
	var z: int = _cell_texture_source_image.get_height()
	
	_cell_texture_source_image.set_data(x, z, false, Image.FORMAT_RGBA8, _cell_texture_data.to_byte_array())
	_cell_texture.update(_cell_texture_source_image)
	

#endregion
