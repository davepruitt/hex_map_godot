class_name HexMeshPrimitive

#region Member enums

enum PrimitiveType { QUAD, TRIANGLE }

#endregion

#region Private data members

var _primitive_type: PrimitiveType = PrimitiveType.TRIANGLE

var _vertices: Array[Vector3] = []

var _colors: Array[Color] = []

var _uv1: Array[Vector2] = []

var _uv2: Array[Vector2] = []

var _terrain_types: Array[Vector3] = []

#endregion

#region Constructor

func _init(prim_type: PrimitiveType) -> void:
	_primitive_type = prim_type

#endregion

#region Public Methods

func add_triangle_unperturbed_vertices (v1: Vector3, v2: Vector3, v3: Vector3) -> void:
	_vertices.append(v1)
	_vertices.append(v2)
	_vertices.append(v3)

func add_triangle_perturbed_vertices (v1: Vector3, v2: Vector3, v3: Vector3) -> void:
	_vertices.append(HexMetrics.perturb(v1))
	_vertices.append(HexMetrics.perturb(v2))
	_vertices.append(HexMetrics.perturb(v3))

func add_quad_unperturbed_vertices (v1: Vector3, v2: Vector3, v3: Vector3, v4: Vector3) -> void:
	_vertices.append(v1)
	_vertices.append(v2)
	_vertices.append(v3)
	_vertices.append(v4)

func add_quad_perturbed_vertices (v1: Vector3, v2: Vector3, v3: Vector3, v4: Vector3) -> void:
	_vertices.append(HexMetrics.perturb(v1))
	_vertices.append(HexMetrics.perturb(v2))
	_vertices.append(HexMetrics.perturb(v3))
	_vertices.append(HexMetrics.perturb(v4))
	
func add_triangle_colors (c1: Color, c2: Color, c3: Color) -> void:
	_colors.append(c1)
	_colors.append(c2)
	_colors.append(c3)

func add_quad_colors (c1: Color, c2: Color, c3: Color, c4: Color) -> void:
	_colors.append(c1)
	_colors.append(c2)
	_colors.append(c3)
	_colors.append(c4)

func add_triangle_uv1 (v1: Vector2, v2: Vector2, v3: Vector2) -> void:
	_uv1.append(v1)
	_uv1.append(v2)
	_uv1.append(v3)

func add_triangle_uv2 (v1: Vector2, v2: Vector2, v3: Vector2) -> void:
	_uv2.append(v1)
	_uv2.append(v2)
	_uv2.append(v3)

func add_quad_uv1_floats (uMin: float, uMax: float, vMin: float, vMax: float) -> void:
	var uv1: Vector2 = Vector2(uMin, vMin)
	var uv2: Vector2 = Vector2(uMax, vMin)
	var uv3: Vector2 = Vector2(uMin, vMax)
	var uv4: Vector2 = Vector2(uMax, vMax)
	
	add_quad_uv1_vectors(uv1, uv2, uv3, uv4)

func add_quad_uv2_floats (uMin: float, uMax: float, vMin: float, vMax: float) -> void:
	var uv1: Vector2 = Vector2(uMin, vMin)
	var uv2: Vector2 = Vector2(uMax, vMin)
	var uv3: Vector2 = Vector2(uMin, vMax)
	var uv4: Vector2 = Vector2(uMax, vMax)
	
	add_quad_uv2_vectors(uv1, uv2, uv3, uv4)

func add_quad_uv1_vectors (v1: Vector2, v2: Vector2, v3: Vector2, v4: Vector2) -> void:
	_uv1.append(v1)
	_uv1.append(v2)
	_uv1.append(v3)
	_uv1.append(v4)

func add_quad_uv2_vectors (v1: Vector2, v2: Vector2, v3: Vector2, v4: Vector2) -> void:
	_uv2.append(v1)
	_uv2.append(v2)
	_uv2.append(v3)
	_uv2.append(v4)

func add_triangle_terrain_types (terrain_types: Vector3) -> void:
	_terrain_types.append(terrain_types)
	_terrain_types.append(terrain_types)
	_terrain_types.append(terrain_types)

func add_quad_terrain_types (terrain_types: Vector3) -> void:
	_terrain_types.append(terrain_types)
	_terrain_types.append(terrain_types)
	_terrain_types.append(terrain_types)
	_terrain_types.append(terrain_types)

func commit (st: SurfaceTool) -> void:
	if (_primitive_type == PrimitiveType.QUAD):
		_commit_quad(st)
	else:
		_commit_triangle(st)

#endregion

#region Private methods

func _commit_vertex (st: SurfaceTool, vertex_idx: int) -> void:
	
	#Set the color of the vertex
	if (len(_colors) > vertex_idx):
		var c: Color = _colors[vertex_idx];
		st.set_color(c)
	
	#Set the uv1 of the vertex
	if (len(_uv1) > vertex_idx):
		var uv1: Vector2 = _uv1[vertex_idx]
		st.set_uv(uv1)
	
	#Set the uv2 of the vertex
	if (len(_uv2) > vertex_idx):
		var uv2: Vector2 = _uv2[vertex_idx]
		st.set_uv2(uv2)
	
	#Set the terrain index of the vertex
	if (len(_terrain_types) > vertex_idx):
		var t: Vector3 = _terrain_types[vertex_idx]
		var c: Color = Color(t.x, t.y, t.z, 0);
		st.set_custom(0, c)
	
	#Add the vertex itself
	if (len(_vertices) > vertex_idx):
		st.add_vertex(_vertices[vertex_idx])
	
	return

func _commit_triangle_with_indices (st: SurfaceTool, idx: Array[int]) -> void:
	#Add the first vertex
	_commit_vertex(st, idx[0])
	
	#Add the second vertex
	_commit_vertex(st, idx[1])
	
	#Add the third vertex
	_commit_vertex(st, idx[2])

func _commit_triangle (st: SurfaceTool) -> void:
	_commit_triangle_with_indices(st, [0, 2, 1])

func _commit_quad (st: SurfaceTool) -> void:
	_commit_triangle_with_indices(st, [0, 1, 2])
	_commit_triangle_with_indices(st, [1, 3, 2])

#endregion
