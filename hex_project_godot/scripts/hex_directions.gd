class_name HexDirectionsClass

#region Enumerations

enum HexDirections { NE, E, SE, SW, W, NW }

#endregion

#region Statc methods

static func opposite (direction: HexDirections) -> HexDirections:
	if int(direction) < 3:
		return int(direction) + 3
	else:
		return int(direction) - 3

static func previous (direction: HexDirections) -> HexDirections:
	if (direction == HexDirections.NE):
		return HexDirections.NW
	else:
		return direction - 1

static func next (direction: HexDirections) -> HexDirections:
	if (direction == HexDirections.NW):
		return HexDirections.NE
	else:
		return direction + 1

static func previous2 (direction: HexDirections) -> HexDirections:
	direction -= 2
	if (direction >= HexDirections.NE):
		return direction
	else:
		return (direction + 6)

static func next2 (direction: HexDirections) -> HexDirections:
	direction += 2
	if (direction <= HexDirections.NW):
		return direction
	else:
		return (direction - 6)

#endregion
