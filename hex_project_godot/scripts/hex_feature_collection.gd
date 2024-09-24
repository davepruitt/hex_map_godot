class_name HexFeatureCollection

#region Public data members

var prefabs: Array[BoxMesh] = []

#endregion

#region Constructor

func _init() -> void:
	pass

#endregion

#region Methods

func pick (choice: float) -> BoxMesh:
	return prefabs[int(choice * len(prefabs))]

#endregion
