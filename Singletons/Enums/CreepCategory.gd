extends Node

enum enm {
	UNDEAD,
	MAGIC,
	NATURE,
	ORC,
	HUMANOID,
}


const _string_map: Dictionary = {
	CreepCategory.enm.UNDEAD: "undead",
	CreepCategory.enm.MAGIC: "magic",
	CreepCategory.enm.NATURE: "nature",
	CreepCategory.enm.ORC: "orc",
	CreepCategory.enm.HUMANOID: "humanoid",
}

const _color_map: Dictionary = {
	CreepCategory.enm.UNDEAD: Color.BLUE_VIOLET,
	CreepCategory.enm.MAGIC: Color.CORNFLOWER_BLUE,
	CreepCategory.enm.NATURE: Color.LIME_GREEN,
	CreepCategory.enm.ORC: Color.DARK_SEA_GREEN,
	CreepCategory.enm.HUMANOID: Color.TAN,
}

func convert_to_string(type: CreepCategory.enm) -> String:
	return _string_map[type]


func convert_to_colored_string(type: CreepCategory.enm) -> String:
	var string: String = convert_to_string(type).capitalize()
	var color: Color = _color_map[type]
	var out: String = Utils.get_colored_string(string, color)

	return out
