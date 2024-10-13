class_name HexMesh
extends MeshInstance3D

#region Private data members

var _surface_tool: SurfaceTool = SurfaceTool.new()

#endregion

#region Public data members

var use_collider: bool = true

var use_colors: bool = true

var use_uv_coordinates: bool = false

var use_uv2_coordinates: bool = false

var use_terrain_types: bool = false

#endregion

#region Overrides

func _init() -> void:
	pass

#endregion

#region Public methods

func begin () -> void:
	#Begin creating the mesh
	_surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES);
	
	#Set the first custom channel to be RGB float
	if (use_terrain_types):
		_surface_tool.set_custom_format(0, SurfaceTool.CUSTOM_RGBA_FLOAT);
	
	#Set the smooth group to -1, which produces flat normals for the mesh
	_surface_tool.set_smooth_group(-1)

func commit_primitive (prim: HexMeshPrimitive) -> void:
	prim.commit(_surface_tool)

func end (mat: Material) -> void:
	#Generate the normals for the mesh
	_surface_tool.generate_normals()
	
	#Generate the tangents for the mesh
	_surface_tool.generate_tangents()
	
	#Commit the mesh
	self.mesh = _surface_tool.commit()
	
	#Create the collision object for the mesh
	if (use_collider):
		self.create_trimesh_collision()
	
	#Set the material for the mesh
	self.material_override = mat

#endregion
