class_name HexFeatureManager

#region Public data members

var urban_collections: Array[HexFeatureCollection]
var farm_collections: Array[HexFeatureCollection]
var plant_collections: Array[HexFeatureCollection]

var walls: HexMesh = HexMesh.new()

#endregion

#region Private data members

var _features: Array[MeshInstance3D] = []

#endregion

#region Constructor

func _init() -> void:
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
	#Queue each feature to be free'd by Godot
	for i in range(0, len(_features)):
		var current_feature: MeshInstance3D = _features[i]
		current_feature.queue_free()
	
	#Clear the list of features
	_features.clear()
	
func apply () -> void:
	pass
	
func add_feature (parent_hex_grid_chunk: HexGridChunk, cell: HexCell, pos: Vector3) -> void:
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
	
	#Increase the height so the entire feature is above-ground
	var feature_height = feature.mesh.get_aabb().size.y
	feature.position.y += feature_height / 2.0
	
	#Randomize the rotation angle of the feature
	feature.quaternion = Quaternion.from_euler(Vector3(0, 360.0 * hash.e, 0))
	
	#Add this feature to the private list of features
	_features.append(feature)
	
	#Add this feature as a child of the hex grid chunk
	parent_hex_grid_chunk.add_child(feature)
	

func add_wall (near: EdgeVertices, near_cell: HexCell, far: EdgeVertices, far_cell: HexCell) -> void:
	
	if (near_cell.walled != far_cell.walled):
		_add_wall_segment(near.v1, far.v1, near.v5, far.v5)


#endregion

#region Private methods

func _pick_prefab (collection: Array[HexFeatureCollection], level: int, hash: float, choice: float) -> BoxMesh:
	if (level > 0):
		var thresholds: Array[float] = HexMetrics.get_feature_thresholds(level - 1)
		for i in range(0, len(thresholds)):
			if (hash < thresholds[i]):
				return collection[i].pick(choice)
	
	return null

func _add_wall_segment (near_left: Vector3, far_left: Vector3, near_right: Vector3, far_right: Vector3) -> void:
	
	var left: Vector3 = near_left.lerp(far_left, 0.5)
	var right: Vector3 = near_right.lerp(far_right, 0.5)
	
	var v1: Vector3 = left
	var v2: Vector3 = right
	var v3: Vector3 = left
	var v4: Vector3 = right
	
	v3.y = left.y + HexMetrics.WALL_HEIGHT
	v4.y = v3.y
	
	walls.add_perturbed_quad(v1, v2, v3, v4, Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE)
	walls.add_perturbed_quad(v2, v1, v4, v3, Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE)

#endregion
