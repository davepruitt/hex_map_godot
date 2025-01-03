class_name HexFeatureManager
extends Node3D

#region Public data members

var urban_collections: Array[HexFeatureCollection]
var farm_collections: Array[HexFeatureCollection]
var plant_collections: Array[HexFeatureCollection]

var walls: HexMesh = HexMesh.new()

var wall_tower_prefab: PackedScene = preload("res://scenes/prefabs/wall_tower.tscn")
var bridge_prefab: PackedScene = preload("res://scenes/prefabs/bridge.tscn")
var flag_prefab: PackedScene = preload("res://scenes/prefabs/flag.tscn")

var special_prefabs: Array[PackedScene] = [
	preload("res://scenes/prefabs/castle.tscn"),
	preload("res://scenes/prefabs/ziggurat.tscn"),
	preload("res://scenes/prefabs/megaflora.tscn")
]

#endregion

#region Constructor

func _init() -> void:
	#Add the walls mesh as a child
	add_child(walls)
	
	#Create the urban collections
	var small_urban_collection = HexFeatureCollection.new()
	small_urban_collection.prefabs.append(preload("res://resources/urban_features/small/feature_urban_small_01.tres"))
	small_urban_collection.prefabs.append(preload("res://resources/urban_features/small/feature_urban_small_02.tres"))
	
	var medium_urban_collection = HexFeatureCollection.new()
	medium_urban_collection.prefabs.append(preload("res://resources/urban_features/medium/feature_urban_medium_01.tres"))
	medium_urban_collection.prefabs.append(preload("res://resources/urban_features/medium/feature_urban_medium_02.tres"))
	
	var large_urban_collection = HexFeatureCollection.new()
	large_urban_collection.prefabs.append(preload("res://resources/urban_features/large/feature_urban_large_01.tres"))
	large_urban_collection.prefabs.append(preload("res://resources/urban_features/large/feature_urban_large_02.tres"))
	
	urban_collections.append(large_urban_collection)
	urban_collections.append(medium_urban_collection)
	urban_collections.append(small_urban_collection)
	
	#Create the farm collections
	var small_farm_collection = HexFeatureCollection.new()
	small_farm_collection.prefabs.append(preload("res://resources/farm_features/small/feature_farm_small_01.tres"))
	small_farm_collection.prefabs.append(preload("res://resources/farm_features/small/feature_farm_small_02.tres"))
	
	var medium_farm_collection = HexFeatureCollection.new()
	medium_farm_collection.prefabs.append(preload("res://resources/farm_features/medium/feature_farm_medium_01.tres"))
	medium_farm_collection.prefabs.append(preload("res://resources/farm_features/medium/feature_farm_medium_02.tres"))
	
	var large_farm_collection = HexFeatureCollection.new()
	large_farm_collection.prefabs.append(preload("res://resources/farm_features/large/feature_farm_large_01.tres"))
	large_farm_collection.prefabs.append(preload("res://resources/farm_features/large/feature_farm_large_02.tres"))
	
	farm_collections.append(large_farm_collection)
	farm_collections.append(medium_farm_collection)
	farm_collections.append(small_farm_collection)
	
	#Create the plant collections
	var small_plant_collection = HexFeatureCollection.new()
	small_plant_collection.prefabs.append(preload("res://resources/plant_features/small/feature_plant_small_01.tres"))
	small_plant_collection.prefabs.append(preload("res://resources/plant_features/small/feature_plant_small_02.tres"))
	
	var medium_plant_collection = HexFeatureCollection.new()
	medium_plant_collection.prefabs.append(preload("res://resources/plant_features/medium/feature_plant_medium_01.tres"))
	medium_plant_collection.prefabs.append(preload("res://resources/plant_features/medium/feature_plant_medium_02.tres"))
	
	var large_plant_collection = HexFeatureCollection.new()
	large_plant_collection.prefabs.append(preload("res://resources/plant_features/large/feature_plant_large_01.tres"))
	large_plant_collection.prefabs.append(preload("res://resources/plant_features/large/feature_plant_large_02.tres"))
	
	plant_collections.append(large_plant_collection)
	plant_collections.append(medium_plant_collection)
	plant_collections.append(small_plant_collection)
	


#endregion

#region Methods

func clear () -> void:
	for n in get_children():
		n.queue_free()
	
	walls = HexMesh.new()
	add_child(walls)
	
func apply () -> void:
	pass
	
func add_feature (cell: HexCell, pos: Vector3) -> void:
	#If this cell contains a special feature, then suppress adding any other features
	if (cell.is_special):
		return
	
	#Get a random value to be used for this feature
	var hash: HexHash = HexMetrics.sample_hash_grid(pos)
	
	#Pick an urban prefab
	var urban_prefab: BoxMesh = _pick_prefab(urban_collections, cell.urban_level, hash.a, hash.d)
	
	#Pick a farm prefab
	var farm_prefab: BoxMesh = _pick_prefab(farm_collections, cell.farm_level, hash.b, hash.d)
	
	#Pick a plant prefab
	var plant_prefab: BoxMesh = _pick_prefab(plant_collections, cell.plant_level, hash.c, hash.d)
	
	#Choose which prefab to use for this location
	var prefab: BoxMesh = urban_prefab
	var used_hash: float = hash.a
	if (urban_prefab):
		if (farm_prefab) and (hash.b < hash.a):
			prefab = farm_prefab
			used_hash = hash.b
	elif (farm_prefab):
		prefab = farm_prefab
		used_hash = hash.b
	
	if (prefab):
		if (plant_prefab) and (hash.c < used_hash):
			prefab = plant_prefab
	elif (plant_prefab):
		prefab = plant_prefab
	else:
		return
	
	#var feature_mesh = feature_prefab.duplicate()
	var feature: MeshInstance3D = MeshInstance3D.new()
	feature.mesh = prefab
	feature.position = HexMetrics.perturb(pos)
	feature.set_instance_shader_parameter("_index", float(cell.index))
	
	#Increase the height so the entire feature is above-ground
	var feature_height = feature.mesh.get_aabb().size.y
	feature.position.y += feature_height / 2.0
	
	#Randomize the rotation angle of the feature
	feature.quaternion = Quaternion.from_euler(Vector3(0, 360.0 * hash.e, 0))
	
	#Add this feature as a child of the hex grid chunk
	add_child(feature)
	

func add_wall (near: EdgeVertices, near_cell: HexCell, 
	far: EdgeVertices, far_cell: HexCell,
	has_river: bool, has_road: bool) -> void:
	
	if ((near_cell.walled != far_cell.walled) and 
		(not near_cell.is_underwater) and 
		(not far_cell.is_underwater) and 
		(near_cell.get_edge_type_from_other_cell(far_cell) != Enums.HexEdgeType.Cliff)):
		
		#First wall segment
		_add_wall_segment(near_cell, near.v1, far.v1, near.v2, far.v2)
		
		if (has_river or has_road):
			_add_wall_cap(near_cell, near.v2, far.v2)
			_add_wall_cap(near_cell, far.v4, near.v4)
		else:
			#Add these wall segments if no river or road
			_add_wall_segment(near_cell, near.v2, far.v2, near.v3, far.v3)
			_add_wall_segment(near_cell, near.v3, far.v3, near.v4, far.v4)
			
		#Last wall segment
		_add_wall_segment(near_cell, near.v4, far.v4, near.v5, far.v5)

func add_wall_three_cells (c1: Vector3, cell1: HexCell, 
	c2: Vector3, cell2: HexCell,
	c3: Vector3, cell3: HexCell):
	
	if (cell1.walled):
		if (cell2.walled):
			if (not cell3.walled):
				_add_wall_segment_with_pivot(c3, cell3, c1, cell1, c2, cell2)
		elif (cell3.walled):
			_add_wall_segment_with_pivot(c2, cell2, c3, cell3, c1, cell1)
		else:
			_add_wall_segment_with_pivot(c1, cell1, c2, cell2, c3, cell3)
	elif (cell2.walled):
		if (cell3.walled):
			_add_wall_segment_with_pivot(c1, cell1, c2, cell2, c3, cell3)
		else:
			_add_wall_segment_with_pivot(c2, cell2, c3, cell3, c1, cell1)
	elif (cell3.walled):
		_add_wall_segment_with_pivot(c3, cell3, c1, cell1, c2, cell2)
	

func add_bridge (cell: HexCell, road_center_1: Vector3, road_center_2: Vector3) -> void:
	road_center_1 = HexMetrics.perturb(road_center_1)
	road_center_2 = HexMetrics.perturb(road_center_2)
	
	#There seems to be some issue with correctly rotating the bridges if road_center_2's Z value
	#is less than road_center_1's Z value. So, if this is the case, let's just swap the two
	if (road_center_2.z < road_center_1.z):
		var temp: Vector3 = road_center_2
		road_center_2 = road_center_1
		road_center_1 = temp
	
	var bridge_instance: Node3D = bridge_prefab.instantiate() as Node3D
	bridge_instance.position = (road_center_1 + road_center_2) * 0.5
	bridge_instance.quaternion = Quaternion(bridge_instance.global_transform.basis.z, road_center_2 - road_center_1)
	
	#Set the cell index on each child of the feature's primary Node3D object
	for N in bridge_instance.get_children():
		for Nc in N.get_children():
			var N_geom3d: GeometryInstance3D = Nc as GeometryInstance3D
			if (N_geom3d != null):
				N_geom3d.set_instance_shader_parameter("_index", float(cell.index))
	
	var bridge_length: float = road_center_1.distance_to(road_center_2)
	bridge_instance.scale = Vector3(1.0, 1.0, bridge_length * (1.0 / HexMetrics.BRIDGE_DESIGN_LENGTH))
	
	add_child(bridge_instance)

func add_special_feature (cell: HexCell, pos: Vector3) -> void:
	#Instantiate the selected special feature
	var instance: Node3D = special_prefabs[cell.special_index - 1].instantiate() as Node3D
	
	#Give it a position
	instance.position = HexMetrics.perturb(pos)
	
	#Set the cell index on each child of the feature's primary Node3D object
	for N in instance.get_children():
		var N_geom3d: GeometryInstance3D = N as GeometryInstance3D
		if (N_geom3d != null):
			N_geom3d.set_instance_shader_parameter("_index", float(cell.index))
	
	#Give it an orientation
	var hash: HexHash = HexMetrics.sample_hash_grid(pos)
	instance.quaternion = Quaternion.from_euler(Vector3(0, 360.0 * hash.e, 0))
	
	#Add it as a child of this node
	add_child(instance)

#endregion

#region Private methods

func _pick_prefab (collection: Array[HexFeatureCollection], level: int, hash: float, choice: float) -> BoxMesh:
	if (level > 0):
		var thresholds: Array[float] = HexMetrics.get_feature_thresholds(level - 1)
		for i in range(0, len(thresholds)):
			if (hash < thresholds[i]):
				return collection[i].pick(choice)
	
	return null

func _add_wall_segment_with_pivot (
	pivot: Vector3, pivot_cell: HexCell,
	left: Vector3, left_cell: HexCell,
	right: Vector3, right_cell: HexCell
) -> void:
	
	if (pivot_cell.is_underwater):
		return
		
	var has_left_wall: bool = (not left_cell.is_underwater) and (pivot_cell.get_edge_type_from_other_cell(left_cell) != Enums.HexEdgeType.Cliff)
	var has_right_wall: bool = (not right_cell.is_underwater) and (pivot_cell.get_edge_type_from_other_cell(right_cell) != Enums.HexEdgeType.Cliff)
	
	if (has_left_wall):
		if (has_right_wall):
			var has_tower: bool = false
			if (left_cell.elevation == right_cell.elevation):
				var hash: HexHash = HexMetrics.sample_hash_grid((pivot + left + right) / (1.0 / 3.0))
				has_tower = (hash.e < HexMetrics.WALL_TOWER_THRESHOLD)
			
			_add_wall_segment(pivot_cell, pivot, left, pivot, right, has_tower)
		elif (left_cell.elevation < right_cell.elevation):
			_add_wall_wedge(pivot_cell, pivot, left, right)
		else:
			_add_wall_cap(pivot_cell, pivot, left)
	elif (has_right_wall):
		if (right_cell.elevation < left_cell.elevation):
			_add_wall_wedge(pivot_cell, right, pivot, left)
		else:
			_add_wall_cap(pivot_cell, right, pivot)

func _add_wall_segment (cell: HexCell, near_left: Vector3, far_left: Vector3, near_right: Vector3, far_right: Vector3, 
	add_tower: bool = false) -> void:
	
	#Perturb the vertices
	near_left = HexMetrics.perturb(near_left)
	far_left = HexMetrics.perturb(far_left)
	near_right = HexMetrics.perturb(near_right)
	far_right = HexMetrics.perturb(far_right)
	
	var left: Vector3 = HexMetrics.wall_lerp(near_left, far_left)
	var right: Vector3 = HexMetrics.wall_lerp(near_right, far_right)
	
	var left_thickness_offset: Vector3 = HexMetrics.wall_thickness_offset(near_left, far_left)
	var right_thickness_offset: Vector3 = HexMetrics.wall_thickness_offset(near_right, far_right)
	
	var left_top: float = left.y + HexMetrics.WALL_HEIGHT
	var right_top: float = right.y + HexMetrics.WALL_HEIGHT
	
	var v1: Vector3 = left - left_thickness_offset
	var v2: Vector3 = right - right_thickness_offset
	var v3: Vector3 = left - left_thickness_offset
	var v4: Vector3 = right - right_thickness_offset
	v3.y = left_top
	v4.y = right_top
	
	var indices: Vector3 = Vector3(cell.index, cell.index, cell.index)
	
	var w1: HexMeshPrimitive = HexMeshPrimitive.new(HexMeshPrimitive.PrimitiveType.QUAD)
	w1.add_quad_unperturbed_vertices(v1, v2, v3, v4)
	w1.add_quad_cell_data_unified(indices, Color.BLACK)
	walls.commit_primitive(w1)
	
	#Wall top
	var t1: Vector3 = v3
	var t2: Vector3 = v4
	
	v1 = left + left_thickness_offset
	v3 = v1
	v2 = right + right_thickness_offset
	v4 = v2
	
	v3.y = left_top
	v4.y = right_top
	
	var w2: HexMeshPrimitive = HexMeshPrimitive.new(HexMeshPrimitive.PrimitiveType.QUAD)
	w2.add_quad_unperturbed_vertices(v2, v1, v4, v3)
	w2.add_quad_cell_data_unified(indices, Color.BLACK)
	walls.commit_primitive(w2)
	
	var w3: HexMeshPrimitive = HexMeshPrimitive.new(HexMeshPrimitive.PrimitiveType.QUAD)
	w3.add_quad_unperturbed_vertices(t1, t2, v3, v4)
	w3.add_quad_cell_data_unified(indices, Color.BLACK)
	walls.commit_primitive(w3)
	
	if (add_tower):
		var tower_instance: Node3D = wall_tower_prefab.instantiate() as Node3D
		tower_instance.position = (left + right) * 0.5
		
		#Set the cell index on each child of the feature's primary Node3D object
		for N in tower_instance.get_children():
			var N_geom3d: GeometryInstance3D = N as GeometryInstance3D
			if (N_geom3d != null):
				N_geom3d.set_instance_shader_parameter("_index", float(cell.index))
		
		var right_direction: Vector3 = right - left
		right_direction.y = 0
		tower_instance.quaternion = Quaternion(tower_instance.basis.x, right_direction)
		
		add_child(tower_instance)

func _add_wall_cap (cell: HexCell, near: Vector3, far: Vector3) -> void:
	near = HexMetrics.perturb(near)
	far = HexMetrics.perturb(far)
	
	var center: Vector3 = HexMetrics.wall_lerp(near, far)
	var thickness: Vector3 = HexMetrics.wall_thickness_offset(near, far)
	
	var v1: Vector3 = Vector3.ZERO
	var v2: Vector3 = Vector3.ZERO
	var v3: Vector3 = Vector3.ZERO
	var v4: Vector3 = Vector3.ZERO

	v1 = center - thickness
	v3 = v1
	v2 = center + thickness
	v4 = v2
	
	v3.y = center.y + HexMetrics.WALL_HEIGHT
	v4.y = v3.y
	
	var indices: Vector3 = Vector3(cell.index, cell.index, cell.index)
	
	var w1: HexMeshPrimitive = HexMeshPrimitive.new(HexMeshPrimitive.PrimitiveType.QUAD)
	w1.add_quad_unperturbed_vertices(v1, v2, v3, v4)
	w1.add_quad_cell_data_unified(indices, Color.BLACK)
	walls.commit_primitive(w1)

func _add_wall_wedge (cell: HexCell, near: Vector3, far: Vector3, point: Vector3) -> void:
	near = HexMetrics.perturb(near)
	far = HexMetrics.perturb(far)
	point = HexMetrics.perturb(point)
	
	var center: Vector3 = HexMetrics.wall_lerp(near, far)
	var thickness: Vector3 = HexMetrics.wall_thickness_offset(near, far)
	
	var v1: Vector3 = Vector3.ZERO
	var v2: Vector3 = Vector3.ZERO
	var v3: Vector3 = Vector3.ZERO
	var v4: Vector3 = Vector3.ZERO
	
	var point_top: Vector3 = point
	point.y = center.y

	v1 = center - thickness
	v3 = v1
	v2 = center + thickness
	v4 = v2
	
	v3.y = center.y + HexMetrics.WALL_HEIGHT
	v4.y = v3.y
	point_top.y = v3.y
	
	var indices: Vector3 = Vector3(cell.index, cell.index, cell.index)
	
	var w1: HexMeshPrimitive = HexMeshPrimitive.new(HexMeshPrimitive.PrimitiveType.QUAD)
	w1.add_quad_unperturbed_vertices(v1, point, v3, point_top)
	w1.add_quad_cell_data_unified(indices, Color.BLACK)
	walls.commit_primitive(w1)

	var w2: HexMeshPrimitive = HexMeshPrimitive.new(HexMeshPrimitive.PrimitiveType.QUAD)
	w2.add_quad_unperturbed_vertices(point, v2, point_top, v4)
	w2.add_quad_cell_data_unified(indices, Color.BLACK)
	walls.commit_primitive(w2)
	
	var w3: HexMeshPrimitive = HexMeshPrimitive.new(HexMeshPrimitive.PrimitiveType.TRIANGLE)
	w3.add_triangle_unperturbed_vertices(point_top, v3, v4)
	w3.add_triangle_cell_data_uniform(indices, Color.BLACK)
	walls.commit_primitive(w3)

#endregion
