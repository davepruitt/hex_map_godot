class_name HexFeatureManager

#region Public data members

var feature_prefab: BoxMesh = preload("res://resources/feature.tres")

#endregion

#region Private data members

var _features: Array[MeshInstance3D] = []

#endregion

#region Constructor

func _init() -> void:
	pass

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
	
func add_feature (parent_hex_grid_chunk: HexGridChunk, pos: Vector3) -> void:
	#var feature_mesh = feature_prefab.duplicate()
	var feature: MeshInstance3D = MeshInstance3D.new()
	feature.mesh = feature_prefab
	feature.position = HexMetrics.perturb(pos)
	
	#Increase the height so the entire feature is above-ground
	var feature_height = feature.mesh.get_aabb().size.y
	feature.position.y += feature_height / 2.0
	
	#Randomize the rotation angle of the feature
	feature.quaternion = Quaternion.from_euler(Vector3(0, 360.0 * randf(), 0))
	
	#Add this feature to the private list of features
	_features.append(feature)
	
	#Add this feature as a child of the hex grid chunk
	parent_hex_grid_chunk.add_child(feature)
	

#endregion
