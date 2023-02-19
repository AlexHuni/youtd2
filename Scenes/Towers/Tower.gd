class_name Tower
extends Building


enum TowerProperty {
#	Properties below should be defined in the .csv file and
# 	the integer values must match the columns in csv file.
	SCENE_NAME = 0,
	NAME = 1,
	ID = 2,
	FAMILY_ID = 3,
	AUTHOR = 4,
	RARITY = 5,
	ELEMENT = 6,
	ATTACK_TYPE = 7,
	ATTACK_RANGE = 8,
	ATTACK_CD = 9,
	ATTACK_DAMAGE_MIN = 10,
	ATTACK_DAMAGE_MAX = 11,
	COST = 12,
	DESCRIPTION = 13,
	TIER = 14,
	REQUIRED_ELEMENT_LEVEL = 15,
	REQUIRED_WAVE_LEVEL = 16,

	CSV_COLUMN_COUNT = 17,

#	These properties shouldn't be defined directly. Use a
#	Modifier.
	ATTACK_CRIT_CHANCE,
	ATTACK_CRIT_DAMAGE,
	MULTICRIT_COUNT,
	ATTACK_MISS_CHANCE,

	DMG_TO_MASS,
	DMG_TO_NORMAL,
	DMG_TO_CHAMPION,
	DMG_TO_BOSS,

	DMG_TO_UNDEAD,
	DMG_TO_MAGIC,
	DMG_TO_NATURE,
	DMG_TO_ORC,
	DMG_TO_HUMANOID,

# 	TODO: implement
	ITEM_CHANCE_ON_KILL,
	ITEM_QUALITY_ON_KILL,
	EXP_RECEIVED,
}

enum Element {
	ASTRAL,
	DARKNESS,
	NATURE,
	FIRE,
	ICE,
	STORM,
	IRON,
}

export(AudioStreamMP3) var attack_sound

const _tower_mod_to_property_map: Dictionary = {
	Modification.Type.MOD_ATTACK_CRIT_CHANCE: TowerProperty.ATTACK_CRIT_CHANCE, 
	Modification.Type.MOD_MULTICRIT_COUNT: TowerProperty.MULTICRIT_COUNT, 

	Modification.Type.MOD_DMG_TO_MASS: TowerProperty.DMG_TO_MASS, 
	Modification.Type.MOD_DMG_TO_NORMAL: TowerProperty.DMG_TO_NORMAL, 
	Modification.Type.MOD_DMG_TO_CHAMPION: TowerProperty.DMG_TO_CHAMPION, 
	Modification.Type.MOD_DMG_TO_BOSS: TowerProperty.DMG_TO_BOSS, 

	Modification.Type.MOD_DMG_TO_UNDEAD: TowerProperty.DMG_TO_UNDEAD, 
	Modification.Type.MOD_DMG_TO_MAGIC: TowerProperty.DMG_TO_MAGIC, 
	Modification.Type.MOD_DMG_TO_NATURE: TowerProperty.DMG_TO_NATURE, 
	Modification.Type.MOD_DMG_TO_ORC: TowerProperty.DMG_TO_ORC, 
	Modification.Type.MOD_DMG_TO_HUMANOID: TowerProperty.DMG_TO_HUMANOID, 

	Modification.Type.MOD_ITEM_CHANCE_ON_KILL: TowerProperty.ITEM_CHANCE_ON_KILL, 
	Modification.Type.MOD_ITEM_QUALITY_ON_KILL: TowerProperty.ITEM_QUALITY_ON_KILL, 

	Modification.Type.MOD_EXP_RECEIVED: TowerProperty.EXP_RECEIVED, 

	Modification.Type.MOD_ATTACK_SPEED: TowerProperty.ATTACK_CD,
}

const _mob_type_to_property_map: Dictionary = {
	Mob.Type.UNDEAD: TowerProperty.DMG_TO_MASS,
	Mob.Type.MAGIC: TowerProperty.DMG_TO_MAGIC,
	Mob.Type.NATURE: TowerProperty.DMG_TO_NATURE,
	Mob.Type.ORC: TowerProperty.DMG_TO_ORC,
	Mob.Type.HUMANOID: TowerProperty.DMG_TO_HUMANOID,
}

const _mob_size_to_property_map: Dictionary = {
	Mob.Size.MASS: TowerProperty.DMG_TO_MASS,
	Mob.Size.NORMAL: TowerProperty.DMG_TO_NORMAL,
	Mob.Size.CHAMPION: TowerProperty.DMG_TO_CHAMPION,
	Mob.Size.BOSS: TowerProperty.DMG_TO_BOSS,
}

const ATTACK_CD_MIN: float = 0.2

var _target_list: Array = []
# NOTE: if your tower needs to attack more than 1 target,
# set this var once in _ready() method of subclass
var _target_count_max: int = 1
var _aoe_scene: PackedScene = preload("res://Scenes/Towers/AreaOfEffect.tscn")
var _projectile_scene: PackedScene = preload("res://Scenes/Projectile.tscn")
var _tower_properties: Dictionary = {
	TowerProperty.ID: 0,
	TowerProperty.NAME: "unknown",
	TowerProperty.FAMILY_ID: 0,
	TowerProperty.AUTHOR: "unknown",
	TowerProperty.RARITY: "unknown",
	TowerProperty.ELEMENT: Element.ASTRAL,
	TowerProperty.ATTACK_TYPE: "unknown",
	TowerProperty.COST: 0,
	TowerProperty.DESCRIPTION: "unknown",

	TowerProperty.ATTACK_RANGE: 0.0,
	TowerProperty.ATTACK_CD: 0.0,
	TowerProperty.ATTACK_DAMAGE_MIN: 0,
	TowerProperty.ATTACK_DAMAGE_MAX: 0,
	TowerProperty.ATTACK_CRIT_CHANCE: 0.0,
# NOTE: crit damage default means the default bonus damage
# from crits, so default value of 1.0 means +100%
	TowerProperty.ATTACK_CRIT_DAMAGE: 1.0,
	TowerProperty.MULTICRIT_COUNT: 1.0,
	TowerProperty.ATTACK_MISS_CHANCE: 0.0,

	TowerProperty.DMG_TO_MASS: 0.0,
	TowerProperty.DMG_TO_NORMAL: 0.0,
	TowerProperty.DMG_TO_CHAMPION: 0.0,
	TowerProperty.DMG_TO_BOSS: 0.0,

	TowerProperty.DMG_TO_UNDEAD: 0.0,
	TowerProperty.DMG_TO_MAGIC: 0.0,
	TowerProperty.DMG_TO_NATURE: 0.0,
	TowerProperty.DMG_TO_ORC: 0.0,
	TowerProperty.DMG_TO_HUMANOID: 0.0,

# 	TODO: these should probably default to something
# 	non-zero
	TowerProperty.ITEM_CHANCE_ON_KILL: 0.0,
	TowerProperty.ITEM_QUALITY_ON_KILL: 0.0,
}

const _element_string_to_enum: Dictionary = {
	"astral": Element.ASTRAL,
	"darkness": Element.DARKNESS,
	"nature": Element.NATURE,
	"fire": Element.FIRE,
	"ice": Element.ICE,
	"storm": Element.STORM,
	"iron": Element.IRON,
}

const _element_enum_to_string: Dictionary = {
	Element.ASTRAL: "astral",
	Element.DARKNESS: "darkness",
	Element.NATURE: "nature",
	Element.FIRE: "fire",
	Element.ICE: "ice",
	Element.STORM: "storm",
	Element.IRON: "iron",
}


onready var _game_scene: Node = get_tree().get_root().get_node("GameScene")
onready var _attack_cooldown_timer: Timer = $AttackCooldownTimer
onready var _targeting_area: Area2D = $TargetingArea
onready var _attack_sound: AudioStreamPlayer2D = AudioStreamPlayer2D.new()


func _ready():
	add_child(_aoe_scene.instance(), true)

	
#	NOTE: Load properties from csv first, then load from
#	subclass script to add additional values or override csv
#	values
	var csv_properties: Dictionary = Properties.get_tower_properties_by_filename(filename)

# NOTE: tower properties may omit keys for convenience, so
# 	need to iterate over keys in properties to avoid
# 	triggering "invalid key" error

	# Most properties should be defined in the .csv file.
	var base_properties: Dictionary = _get_base_properties()

	for property in base_properties.keys():
		_tower_properties[property] = base_properties[property]
	
	for property in csv_properties.keys():
		_tower_properties[property] = convert_csv_string_to_property_value(csv_properties[property], property)

	_apply_properties_to_scene_children()

	$AreaOfEffect.hide()

	_attack_cooldown_timer.connect("timeout", self, "_on_AttackCooldownTimer_timeout")
	_attack_cooldown_timer.one_shot = true

	_targeting_area.connect("body_entered", self, "_on_TargetingArea_body_entered")
	_targeting_area.connect("body_exited", self, "_on_TargetingArea_body_exited")

	_attack_sound.set_stream(attack_sound)
	add_child(_attack_sound)



static func element_enum_to_string(element: int) -> String:
	return _element_enum_to_string[element]


static func convert_csv_string_to_property_value(csv_string: String, property: int):
	if property > TowerProperty.CSV_COLUMN_COUNT:
		return csv_string

	match property:
		TowerProperty.SCENE_NAME: return csv_string
		TowerProperty.NAME: return csv_string
		TowerProperty.ID: return csv_string.to_int()
		TowerProperty.FAMILY_ID: return csv_string.to_int()
		TowerProperty.AUTHOR: return csv_string
		TowerProperty.RARITY: return csv_string
		TowerProperty.ELEMENT: return _element_string_to_enum.get(csv_string, Element.ASTRAL)
		TowerProperty.ATTACK_TYPE: return csv_string
		TowerProperty.ATTACK_RANGE: return csv_string.to_float()
		TowerProperty.ATTACK_CD: return csv_string.to_float()
		TowerProperty.ATTACK_DAMAGE_MIN : return csv_string.to_float()
		TowerProperty.ATTACK_DAMAGE_MAX : return csv_string.to_float()
		TowerProperty.COST : return csv_string.to_int()
		TowerProperty.DESCRIPTION : return csv_string
		TowerProperty.TIER : return csv_string.to_int()
		TowerProperty.REQUIRED_ELEMENT_LEVEL : return csv_string.to_int()
		TowerProperty.REQUIRED_WAVE_LEVEL : return csv_string.to_int()
		_:
			print_debug("Unhandled property in Tower.convert_csv_string_to_property_value(): ", property)

			return csv_string


func get_name() -> String:
	return _tower_properties[TowerProperty.NAME]


func get_id() -> int:
	return _tower_properties[TowerProperty.ID]


func get_tier() -> int:
	return _tower_properties[TowerProperty.TIER]


func get_element() -> int:
	return _tower_properties[TowerProperty.ELEMENT]


func build_init():
	.build_init()
	$AreaOfEffect.show()


func change_level(new_level: int):
	set_level(new_level)

# 	NOTE: properties could've change due to level up so
# 	re-apply them
	_apply_properties_to_scene_children()


func _add_target(new_target: Mob):
	if new_target == null:
		return

	new_target.connect("death", self, "_on_target_death", [new_target])
	_target_list.append(new_target)


func _remove_target(target: Mob):
	target.disconnect("death", self, "_on_target_death")
	_target_list.erase(target)


func _on_target_death(_event: Event, target: Mob):
	_remove_target(target)


func _on_AttackCooldownTimer_timeout():
	if _have_target_space():
		var new_target: Mob = _find_new_target()
		_add_target(new_target)
		
	_try_to_attack()


func _have_target_space() -> bool:
	return _target_list.size() < _target_count_max


func _on_TargetingArea_body_entered(body):
	if !body is Mob:
		return

	if _have_target_space():
		var new_target: Mob = body as Mob
		_add_target(new_target)
		_try_to_attack()


func _on_TargetingArea_body_exited(body):
	var target_went_out_of_range: bool = _target_list.has(body)

	if target_went_out_of_range:
		var new_target: Mob = _find_new_target()
		var old_target: Mob = body as Mob
		_remove_target(old_target)
		_add_target(new_target)
		_try_to_attack()


# Find a target that is currently in range
# TODO: prioritizing closest mob here, but maybe change behavior
# based on tower properties or other game design considerations
func _find_new_target() -> Mob:
	var body_list: Array = _targeting_area.get_overlapping_bodies()
	var closest_mob: Mob = null
	var distance_min: float = 1000000.0

#	NOTE: can't use existing targets as new targets
	for target in _target_list:
		body_list.erase(target)
	
	for body in body_list:
		if body is Mob:
			var mob: Mob = body
			var distance: float = (mob.position - self.position).length()
			
			if distance < distance_min:
				closest_mob = mob
				distance_min = distance
	
	return closest_mob


func _try_to_attack():
	if building_in_progress:
		return

	var attack_on_cooldown: bool = _attack_cooldown_timer.time_left > 0
	
	if attack_on_cooldown:
		return

	for target in _target_list:
		._do_attack(target)

		var projectile = _projectile_scene.instance()
		projectile.init(target, global_position)
		projectile.connect("reached_mob", self, "_on_projectile_reached_mob")
		_game_scene.call_deferred("add_child", projectile)

		_attack_sound.play()
		
		_attack_cooldown_timer.start()


func _select():
	._select()


func _unselect():
	._unselect()


func _on_projectile_reached_mob(mob: Mob):
	var attack_miss_chance: float = _tower_properties[TowerProperty.ATTACK_MISS_CHANCE]
	var is_miss: bool = Utils.rand_chance(attack_miss_chance)

	if is_miss:
		return

	var damage_base: float = _get_rand_damage_base()
	var damage: float = _get_damage_to_mob(mob, damage_base)
	
	._do_damage(mob, damage, true)


func _apply_properties_to_scene_children():
	var cast_range: float = _tower_properties[TowerProperty.ATTACK_RANGE]
	Utils.circle_shape_set_radius($TargetingArea/CollisionShape2D, cast_range)
	$AreaOfEffect.set_radius(cast_range)

	var attack_cd: float = _tower_properties[TowerProperty.ATTACK_CD]
	attack_cd = max(ATTACK_CD_MIN, attack_cd)
	_attack_cooldown_timer.wait_time = attack_cd


# NOTE: returns random damage within range without any mods applied
func _get_rand_damage_base() -> float:
	var damage_min: float = _tower_properties[TowerProperty.ATTACK_DAMAGE_MIN]
	var damage_max: float = _tower_properties[TowerProperty.ATTACK_DAMAGE_MAX]
	var damage: float = rand_range(damage_min, damage_max)

	return damage


func _get_base_properties() -> Dictionary:
	return {}


func _modify_property_subclass(modification_type: int, modification_value: float, modify_direction: int):
	_modify_property_general(_tower_properties, _tower_mod_to_property_map, modification_type, modification_value, modify_direction)

	_apply_properties_to_scene_children()


func _get_crit_count() -> int:
	var crit_count: int = 0

	var multicrit_count: int = int(max(0, _tower_properties[TowerProperty.MULTICRIT_COUNT]))

	for _i in range(multicrit_count):
		var attack_crit_chance: float = _tower_properties[TowerProperty.ATTACK_CRIT_CHANCE]
		var is_critical: bool = Utils.rand_chance(attack_crit_chance)

		if is_critical:
			crit_count += 1
		else:
			break

	return crit_count


func _get_damage_mod_for_mob_type(mob: Mob) -> float:
	var mob_type: int = mob.get_type()
	var property: int = _mob_type_to_property_map[mob_type]
	var damage_mod: float = _tower_properties[property]

	return damage_mod


func _get_damage_mod_for_mob_size(mob: Mob) -> float:
	var mob_size: int = mob.get_size()
	var property: int = _mob_size_to_property_map[mob_size]
	var damage_mod: float = _tower_properties[property]

	return damage_mod


func _get_damage_to_mob(mob: Mob, damage_base: float) -> float:
	var damage: float = damage_base
	
	var damage_mod_list: Array = [
		_get_damage_mod_for_mob_size(mob),
		_get_damage_mod_for_mob_type(mob),
	]

# 	NOTE: crit count can go above 1 because of the multicrit
# 	property
	var crit_count: int = _get_crit_count()
	var crit_mod: float = _tower_properties[TowerProperty.ATTACK_CRIT_DAMAGE]

	for _i in range(crit_count):
		damage_mod_list.append(crit_mod)

#	NOTE: clamp at 0.0 to prevent damage from turning
#	negative
	for damage_mod in damage_mod_list:
		damage *= max(0.0, (1.0 + damage_mod))

	return damage
