class_name HexMesh
extends MeshInstance3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var surface_tool = SurfaceTool.new();
	
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES);
	
	surface_tool.set_normal(Vector3(0, 0, -1));
	surface_tool.set_color(Color(1, 0, 0, 1));
	surface_tool.add_vertex(Vector3(-1, 0, 0));
	
	surface_tool.set_normal(Vector3(0, 0, -1));
	surface_tool.set_color(Color(0, 1, 0, 1));
	surface_tool.add_vertex(Vector3(1, 0, 0));
	
	surface_tool.set_normal(Vector3(0, 0, -1));
	surface_tool.set_color(Color(0, 0, 1, 1));
	surface_tool.add_vertex(Vector3(0, 0, 1));
	
	surface_tool.add_index(0);
	surface_tool.add_index(1);
	surface_tool.add_index(2);
	
	mesh = surface_tool.commit()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
