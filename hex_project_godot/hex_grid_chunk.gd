class_name HexGridChunk
extends Node3D

#region Private data members

## This is a list that contains each HexCell object in the grid
var _hex_cells: Array[HexCell] = []

var _hex_mesh: HexMesh = HexMesh.new()

var _hex_shader_material: ShaderMaterial

#endregion

#region Public data members

var update_needed: bool = false

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
	#Set the hex chunk reference on the hex cell object
	cell.hex_chunk = self
	
	#Append the cell to the list of cells in this chunk
	_hex_cells.append(cell)
	
	#Add the hex cell as a child of the chunk
	add_child(cell)

func set_mesh_material (mat: ShaderMaterial) -> void:
	_hex_shader_material = mat

func request_refresh () -> void:
	#Set the "update needed" flag
	update_needed = true

func refresh () -> void:
	#Run the triangulation of the mesh
	_hex_mesh.triangulate_cells(_hex_cells, _hex_shader_material)
	
	#Reset the "update needed" flag
	update_needed = false

#endregion
