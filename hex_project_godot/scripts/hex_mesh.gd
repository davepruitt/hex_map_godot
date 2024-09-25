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

#endregion

#region Overrides

func _init() -> void:
	pass

#endregion

#region Public methods

func begin () -> void:
	#Begin creating the mesh
	_surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES);
	
	#Set the smooth group to -1, which produces flat normals for the mesh
	_surface_tool.set_smooth_group(-1)

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
	

func add_triangle (v1: Vector3, v2: Vector3, v3: Vector3, c1: Color, c2: Color, c3: Color) -> void:
	#Set the color for the vertex, and then add the vertex
	if (use_colors):
		_surface_tool.set_color(c1)
	_surface_tool.add_vertex(v1)
	
	#Set the color for the vertex, and then add the vertex
	if (use_colors):
		_surface_tool.set_color(c2)
	_surface_tool.add_vertex(v2)
	
	#Set the color for the vertex, and then add the vertex
	if (use_colors):
		_surface_tool.set_color(c3)
	_surface_tool.add_vertex(v3)
	
func add_perturbed_triangle (v1: Vector3, v2: Vector3, v3: Vector3, c1: Color, c2: Color, c3: Color) -> void:
	#Set the color for the vertex, and then add the vertex
	if (use_colors):
		_surface_tool.set_color(c1)
	_surface_tool.add_vertex(HexMetrics.perturb(v1))
	
	#Set the color for the vertex, and then add the vertex
	if (use_colors):
		_surface_tool.set_color(c2)
	_surface_tool.add_vertex(HexMetrics.perturb(v2))
	
	#Set the color for the vertex, and then add the vertex
	if (use_colors):
		_surface_tool.set_color(c3)
	_surface_tool.add_vertex(HexMetrics.perturb(v3))

func add_triangle_with_uv (
	v1: Vector3, v2: Vector3, v3: Vector3, 
	c1: Color, c2: Color, c3: Color,
	uv1: Vector2, uv2: Vector2, uv3: Vector2
) -> void:
	
	#Set the color for the vertex, and then add the vertex
	if (use_colors):
		_surface_tool.set_color(c1)
	if (use_uv_coordinates):
		_surface_tool.set_uv(uv1)
	_surface_tool.add_vertex(v1)
	
	#Set the color for the vertex, and then add the vertex
	if (use_colors):
		_surface_tool.set_color(c2)
	if (use_uv_coordinates):
		_surface_tool.set_uv(uv2)
	_surface_tool.add_vertex(v2)
	
	#Set the color for the vertex, and then add the vertex
	if (use_colors):
		_surface_tool.set_color(c3)
	if (use_uv_coordinates):
		_surface_tool.set_uv(uv3)
	_surface_tool.add_vertex(v3)

func add_perturbed_triangle_with_uv (
	v1: Vector3, v2: Vector3, v3: Vector3, 
	c1: Color, c2: Color, c3: Color,
	uv1: Vector2, uv2: Vector2, uv3: Vector2
) -> void:
	
	#Set the color for the vertex, and then add the vertex
	if (use_colors):
		_surface_tool.set_color(c1)
	if (use_uv_coordinates):
		_surface_tool.set_uv(uv1)
	_surface_tool.add_vertex(HexMetrics.perturb(v1))
	
	#Set the color for the vertex, and then add the vertex
	if (use_colors):
		_surface_tool.set_color(c2)
	if (use_uv_coordinates):
		_surface_tool.set_uv(uv2)
	_surface_tool.add_vertex(HexMetrics.perturb(v2))
	
	#Set the color for the vertex, and then add the vertex
	if (use_colors):
		_surface_tool.set_color(c3)
	if (use_uv_coordinates):
		_surface_tool.set_uv(uv3)
	_surface_tool.add_vertex(HexMetrics.perturb(v3))
	
func add_perturbed_triangle_with_uv_and_uv2 (
	v1: Vector3, v2: Vector3, v3: Vector3, 
	c1: Color, c2: Color, c3: Color,
	uv1: Vector2, uv2: Vector2, uv3: Vector2,
	uv2_1: Vector2, uv2_2: Vector2, uv2_3: Vector2
) -> void:
	
	#Set the color for the vertex, and then add the vertex
	if (use_colors):
		_surface_tool.set_color(c1)
	if (use_uv_coordinates):
		_surface_tool.set_uv(uv1)
	if (use_uv2_coordinates):
		_surface_tool.set_uv2(uv2_1)
	_surface_tool.add_vertex(HexMetrics.perturb(v1))
	
	#Set the color for the vertex, and then add the vertex
	if (use_colors):
		_surface_tool.set_color(c2)
	if (use_uv_coordinates):
		_surface_tool.set_uv(uv2)
	if (use_uv2_coordinates):
		_surface_tool.set_uv2(uv2_2)
	_surface_tool.add_vertex(HexMetrics.perturb(v2))
	
	#Set the color for the vertex, and then add the vertex
	if (use_colors):
		_surface_tool.set_color(c3)
	if (use_uv_coordinates):
		_surface_tool.set_uv(uv3)
	if (use_uv2_coordinates):
		_surface_tool.set_uv2(uv2_3)
	_surface_tool.add_vertex(HexMetrics.perturb(v3))

func add_quad (v1: Vector3, v2: Vector3, v3: Vector3, v4: Vector3, c1: Color, c2: Color, c3: Color, c4: Color) -> void:
	add_triangle(v1, v2, v3, c1, c2, c3)
	add_triangle(v2, v4, v3, c2, c4, c3)
	
func add_perturbed_quad (v1: Vector3, v2: Vector3, v3: Vector3, v4: Vector3, c1: Color, c2: Color, c3: Color, c4: Color) -> void:
	add_perturbed_triangle(v1, v2, v3, c1, c2, c3)
	add_perturbed_triangle(v2, v4, v3, c2, c4, c3)

func add_quad_with_uv (
	v1: Vector3, v2: Vector3, v3: Vector3, v4: Vector3, 
	c1: Color, c2: Color, c3: Color, c4: Color,
	uMin: float, uMax: float, vMin: float, vMax: float
) -> void:
	
	var uv1: Vector2 = Vector2(uMin, vMin)
	var uv2: Vector2 = Vector2(uMax, vMin)
	var uv3: Vector2 = Vector2(uMin, vMax)
	var uv4: Vector2 = Vector2(uMax, vMax)
	
	add_triangle_with_uv(
		v1, v2, v3, 
		c1, c2, c3,
		uv1, uv2, uv3
	)
	
	add_triangle_with_uv(
		v2, v4, v3,
		c2, c4, c3,
		uv2, uv4, uv3
	)


func add_perturbed_quad_with_uv (
	v1: Vector3, v2: Vector3, v3: Vector3, v4: Vector3, 
	c1: Color, c2: Color, c3: Color, c4: Color,
	uMin: float, uMax: float, vMin: float, vMax: float
) -> void:
	
	var uv1: Vector2 = Vector2(uMin, vMin)
	var uv2: Vector2 = Vector2(uMax, vMin)
	var uv3: Vector2 = Vector2(uMin, vMax)
	var uv4: Vector2 = Vector2(uMax, vMax)
	
	add_perturbed_triangle_with_uv(
		v1, v2, v3, 
		c1, c2, c3,
		uv1, uv2, uv3
	)
	
	add_perturbed_triangle_with_uv(
		v2, v4, v3,
		c2, c4, c3,
		uv2, uv4, uv3
	)

func add_perturbed_quad_with_uv_vectors (
	v1: Vector3, v2: Vector3, v3: Vector3, v4: Vector3, 
	c1: Color, c2: Color, c3: Color, c4: Color,
	uv1: Vector2, uv2: Vector2, uv3: Vector2, uv4: Vector2
) -> void:
	
	add_perturbed_triangle_with_uv(
		v1, v2, v3, 
		c1, c2, c3,
		uv1, uv2, uv3
	)
	
	add_perturbed_triangle_with_uv(
		v2, v4, v3,
		c2, c4, c3,
		uv2, uv4, uv3
	)

func add_perturbed_quad_with_uv_and_uv2 (
	v1: Vector3, v2: Vector3, v3: Vector3, v4: Vector3, 
	c1: Color, c2: Color, c3: Color, c4: Color,
	uMin: float, uMax: float, vMin: float, vMax: float,
	u2Min: float, u2Max: float, v2Min: float, v2Max: float
) -> void:
	
	var uv1: Vector2 = Vector2(uMin, vMin)
	var uv2: Vector2 = Vector2(uMax, vMin)
	var uv3: Vector2 = Vector2(uMin, vMax)
	var uv4: Vector2 = Vector2(uMax, vMax)
	
	var uv2_1: Vector2 = Vector2(u2Min, v2Min)
	var uv2_2: Vector2 = Vector2(u2Max, v2Min)
	var uv2_3: Vector2 = Vector2(u2Min, v2Max)
	var uv2_4: Vector2 = Vector2(u2Max, v2Max)
	
	add_perturbed_triangle_with_uv_and_uv2(
		v1, v2, v3, 
		c1, c2, c3,
		uv1, uv2, uv3,
		uv2_1, uv2_2, uv2_3
	)
	
	add_perturbed_triangle_with_uv_and_uv2(
		v2, v4, v3,
		c2, c4, c3,
		uv2, uv4, uv3,
		uv2_2, uv2_4, uv2_3
	)

func add_perturbed_quad_with_uv_and_uv2_vectors (
	v1: Vector3, v2: Vector3, v3: Vector3, v4: Vector3, 
	c1: Color, c2: Color, c3: Color, c4: Color,
	uv1: Vector2, uv2: Vector2, uv3: Vector2, uv4: Vector2,
	uv2_1: Vector2, uv2_2: Vector2, uv2_3: Vector2, uv2_4: Vector2
) -> void:
	
	add_perturbed_triangle_with_uv_and_uv2(
		v1, v2, v3, 
		c1, c2, c3,
		uv1, uv2, uv3,
		uv2_1, uv2_2, uv2_3
	)
	
	add_perturbed_triangle_with_uv_and_uv2(
		v2, v4, v3,
		c2, c4, c3,
		uv2, uv4, uv3,
		uv2_2, uv2_4, uv2_3
	)

#endregion
