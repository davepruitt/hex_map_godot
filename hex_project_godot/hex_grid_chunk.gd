class_name HexGridChunk
extends Node3D

#region Private data members

## This is a list that contains each HexCell object in the grid
var _hex_cells: Array[HexCell] = []

var _hex_mesh: HexMesh = HexMesh.new()

#endregion

#region Method overrides

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_child(_hex_mesh)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
#endregion

#region Public methods

func add_cell (index: int, cell: HexCell) -> void:
	_hex_cells.append(cell)
	add_child(cell)
	
func refresh (hex_shader_material: ShaderMaterial) -> void:
	_hex_mesh.triangulate_cells(_hex_cells, hex_shader_material)

#endregion
