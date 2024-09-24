class_name HexHash

#region Public data members

var a: float = 0

var b: float = 0

var c: float = 0

var d: float = 0

var e: float = 0

#endregion

#region Constructor

func _init() -> void:
	pass

#endregion

#region Static functions

static func create() -> HexHash:
	var hash: HexHash = HexHash.new()
	hash.a = randf() * 0.999
	hash.b = randf() * 0.999
	hash.c = randf() * 0.999
	hash.d = randf() * 0.999
	hash.e = randf() * 0.999
	
	return hash

#endregion
