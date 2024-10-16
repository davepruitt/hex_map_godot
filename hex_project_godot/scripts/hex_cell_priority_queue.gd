class_name HexCellPriorityQueue

#region Private data members

var _list: Array[HexCell] = []

var _count: int = 0

var _minimum: int = GodotConstants.MAX_INT

#endregion

#region Constructor

func _init() -> void:
	pass

#endregion

#region Properties

var count: int:
	get:
		return _count

#endregion

#region Public Methods

func enqueue (cell: HexCell) -> void:
	_count += 1
	
	var priority: int = cell.search_priority
	while (priority >= len(_list)):
		_list.append(null)
	cell.next_with_same_priority = _list[priority]
	_list[priority] = cell
	
	if (priority < _minimum):
		_minimum = priority

func dequeue () -> HexCell:
	_count -= 1
	
	while (_minimum < len(_list)):
		var cell: HexCell = _list[_minimum] as HexCell
		if (cell != null):
			_list[_minimum] = cell.next_with_same_priority
			return cell
		
		_minimum += 1
	
	return null

func change (cell: HexCell, old_priority: int) -> void:
	var current: HexCell = _list[old_priority]
	var next: HexCell = current.next_with_same_priority
	if (current == cell):
		_list[old_priority] = next
	else:
		while (next != cell):
			current = next
			next = current.next_with_same_priority
		
		current.next_with_same_priority = cell.next_with_same_priority
	
	#Put the cell back into the queue
	enqueue(cell)
	
	#The enqueue function increments the count, which we don't actually
	#want to do, so let's just decrement the count right here
	_count -= 1

func clear () -> void:
	_list.clear()
	_count = 0
	_minimum = GodotConstants.MAX_INT

#endregion
