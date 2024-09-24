class_name HexFeatureManager

#region Public data members

var urban_collections: Array[HexFeatureCollection]

#endregion

#region Private data members

var _features: Array[MeshInstance3D] = []

#endregion

#region Constructor

func _init() -> void:
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
	
	var prefab: BoxMesh = _pick_prefab(cell.urban_level, hash.a, hash.b)
	if (prefab == null):
		return
	
	#var feature_mesh = feature_prefab.duplicate()
	var feature: MeshInstance3D = MeshInstance3D.new()
	feature.mesh = prefab
	feature.position = HexMetrics.perturb(pos)
	
	#Increase the height so the entire feature is above-ground
	var feature_height = feature.mesh.get_aabb().size.y
	feature.position.y += feature_height / 2.0
	
	#Randomize the rotation angle of the feature
	feature.quaternion = Quaternion.from_euler(Vector3(0, 360.0 * hash.c, 0))
	
	#Add this feature to the private list of features
	_features.append(feature)
	
	#Add this feature as a child of the hex grid chunk
	parent_hex_grid_chunk.add_child(feature)
	

#endregion

#region Private methods

func _pick_prefab (level: int, hash: float, choice: float) -> BoxMesh:
	if (level > 0):
		var thresholds: Array[float] = HexMetrics.get_feature_thresholds(level - 1)
		for i in range(0, len(thresholds)):
			if (hash < thresholds[i]):
				return urban_collections[i].pick(choice)
	
	return null

#endregion
