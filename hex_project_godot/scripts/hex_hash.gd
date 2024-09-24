class_name HexHash

#region Public data members

var a: float = 0

var b: float = 0

#endregion

#region Constructor

func _init() -> void:
	pass

#endregion

#region Static functions

static func create() -> HexHash:
	var hash: HexHash = HexHash.new()
	hash.a = randf()
	hash.b = randf()
	
	return hash

#endregion
