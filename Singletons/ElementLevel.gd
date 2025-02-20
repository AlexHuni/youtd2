extends Node

signal changed()

var _element_level_map: Dictionary = {}


func _init():
	var starting_level = Config.starting_research_level()

	for element in Element.enm.values():
		_element_level_map[element] = starting_level


func increment(element: Element.enm):
	_element_level_map[element] += 1
	changed.emit()


func get_current(element: Element.enm) -> int:
	var level: int = _element_level_map[element]

	return level


func get_research_cost(element: Element.enm) -> int:
	var level: int = get_current(element)
	var cost: int = 20 + level

	return cost


func can_afford_research(element: Element.enm) -> bool:
	var cost: int = ElementLevel.get_research_cost(element)
	var tome_count: int = KnowledgeTomesManager.get_current()
	var can_afford: bool = tome_count >= cost

	return can_afford
