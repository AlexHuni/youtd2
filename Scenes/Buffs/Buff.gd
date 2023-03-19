class_name Buff
extends Node2D


# Buff stores buff parameters and applies them to target
# while it is active. Define custom buffs by creating a
# subclass.
# 
# Buffs can have event handlers. To add an event handler,
# define a handler function in your subclass and call the
# appropriate add_event_handler function. All handler
# functions are called with one parameter Event which passes
# information about the event.

# TODO: what is friendly used for? It's not used as sign
# multiplier on value (confirmed by original tower scripts).
# Maybe used for stacking behavior?

# TODO: implement the following event types
# SPELL_CAST
# SPELL_TARGET
# PURGED

# NOTE: this signal is separate from the EXPIRE event type
# and used by Unit to undo buff modifiers. Do not use this
# in Tower scripts. Use EXPIRE event handler.
signal removed()


class EventHandler:
	var object: Node
	var handler_function: String
	var chance: float
	var chance_level_add: float


var user_int: int = 0
var user_int2: int = 0
var user_int3: int = 0
var user_real: float = 0.0
var user_real2: float = 0.0
var user_real3: float = 0.0

var _caster: Unit
var _target: Unit
var _modifier: Modifier = Modifier.new()
var _level: int
var _power: int
var _time_base: float
var _time_level_add: float
var _friendly: bool
var _type: String
var _timer: Timer
# Map of Event.Type -> list of EventHandler's
var event_handler_map: Dictionary = {}


# NOTE: buff type determines what happens when a buff is
# applied while the target already has active buffs. If buff
# type is empty, then buff will always be applied. If buff
# type is set to something, then buff will be applied only
# if the target doesn't already have an active buff with
# same type. If new buff has higher lever than current
# active buff, then current active buff is upgraded and
# refreshed.
func _init(type: String, time_base: float, time_level_add: float, friendly: bool):
	_type = type
	_time_base = time_base
	_time_level_add = time_level_add
	_friendly = friendly


# Base apply function. Overrides time parameters from init().
func apply_advanced(caster: Unit, target: Unit, level: int, power: int, time: float):
	_caster = caster
	_level = level
	_power = power
	_target = target

	var need_upgrade_logic: bool = !get_type().is_empty()

# 	NOTE: original tower scripts depend on upgrade behavior
# 	being implemented in this exact manner
	if need_upgrade_logic:
		var active_buff = target.get_buff_of_type(get_type())
		
		if active_buff != null:
			var this_level: int = get_level()
			var active_level: int = active_buff.get_level()

			if this_level >= active_level:
				active_buff._upgrade_or_refresh(this_level)

#				When upgrading, new buff instance is
#				discarded and not applied
				return

	_target._add_buff_internal(self)
	_target.death.connect(_on_target_death)
	_target.kill.connect(_on_target_kill)
	_target.level_up.connect(_on_target_level_up)
	_target.attack.connect(_on_target_attack)
	_target.attacked.connect(_on_target_attacked)
	_target.dealt_damage.connect(_on_target_dealt_damage)
	_target.damaged.connect(_on_target_damaged)

	if time > 0.0:
		_timer = Timer.new()
		add_child(_timer)
		_timer.timeout.connect(_on_timer_timeout)

		var buff_duration_mod: float = _caster.get_prop_buff_duration()
		var debuff_duration_mod: float = _target.get_prop_debuff_duration()

		var total_time: float = time * buff_duration_mod

		if !_friendly:
			total_time *= debuff_duration_mod

		_timer.start(total_time)

	var create_event: Event = _make_buff_event(_target)
	_call_event_handler_list(Event.Type.CREATE, create_event)


func apply_custom_power(caster: Unit, target: Unit, level: int, power: int):
	var time: float = _time_base + _time_level_add * level

	apply_advanced(caster, target, level, power, time)


# Base apply function. Overrides time parameters from init().
func apply_custom_timed(caster: Unit, target: Unit, level: int, time: float):
	apply_advanced(caster, target, level, level, time)


# Apply using time parameters that were defined in init()
func apply(caster: Unit, target: Unit, level: int):
	var time: float = _time_base + _time_level_add * level

	apply_custom_timed(caster, target, level, time)


# Apply overriding time parameters from init() and without
# specifying level. This is a convenience function
func apply_only_timed(caster: Unit, target: Unit, time: float):
	apply_custom_timed(caster, target, 0, time)


func apply_to_unit_permanent(caster: Unit, target: Unit, level: int):
	apply_custom_timed(caster, target, level, -1.0)


func refresh_duration():
	_timer.start(_timer.wait_time)


func set_buff_modifier(modifier: Modifier):
	_modifier = modifier


# TODO: implement
func set_buff_icon(_buff_icon: String):
	pass


# TODO: implement
func set_stacking_group(_stacking_group: String):
	pass


func get_modifier() -> Modifier:
	return _modifier


# Level is used to compare this buff with another buff of
# same type that is active on target and determine which
# buff is stronger. Stronger buff will end up remaining
# active on the target.
func get_level() -> int:
	return _level


# Power level is used to calculate the total time and total
# value of modifiers.
func get_power() -> int:
	return _power


func set_type(type: String):
	_type = type


func get_type() -> String:
	return _type


func get_caster() -> Unit:
	return _caster


func get_buffed_unit() -> Unit:
	return _target


func expire():
	_on_timer_timeout()


func add_event_handler(event_type: Event.Type, handler_object: Node, handler_function: String, chance: float, chance_level_add: float):
	if !_check_handler_exists(handler_object, handler_function):
		return

	var handler: EventHandler = EventHandler.new()
	handler.object = handler_object
	handler.handler_function = handler_function
	handler.chance = chance
	handler.chance_level_add = chance_level_add

	_add_event_handler_internal(event_type, handler)


func add_periodic_event(handler_object: Node, handler_function: String, period: float):
	if !_check_handler_exists(handler_object, handler_function):
		return

	var timer: Timer = Timer.new()
	add_child(timer)
	timer.wait_time = period
	timer.one_shot = false
	timer.autostart = true
	timer.timeout.connect(_on_periodic_event_timer_timeout.bind(handler_object, handler_function, timer))


func add_event_handler_unit_comes_in_range(handler_object: Node, handler_function: String, radius: float, target_type: TargetType):
	if !_check_handler_exists(handler_object, handler_function):
		return

	var buff_range_area_scene: PackedScene = load("res://Scenes/Buffs/BuffRangeArea.tscn")
	var buff_range_area = buff_range_area_scene.instantiate()
#	NOTE: use call_deferred() adding child immediately causes an error about
# 	setting shape during query flushing
	call_deferred("add_child", buff_range_area)
	buff_range_area.init(radius, target_type, handler_object, handler_function)

	buff_range_area.unit_came_in_range.connect(_on_unit_came_in_range)


func add_autocast(autocast: Autocast):
	autocast.set_caster(_target)
	add_child(autocast)


func set_event_on_cleanup(handler_object: Node, handler_function: String):
	add_event_handler(Event.Type.CLEANUP, handler_object, handler_function, 1.0, 0.0)


func add_event_on_create(handler_object: Node, handler_function: String):
	add_event_handler(Event.Type.CREATE, handler_object, handler_function, 1.0, 0.0)


func add_event_on_upgrade(handler_object: Node, handler_function: String):
	add_event_handler(Event.Type.UPGRADE, handler_object, handler_function, 1.0, 0.0)


func add_event_on_refresh(handler_object: Node, handler_function: String):
	add_event_handler(Event.Type.REFRESH, handler_object, handler_function, 1.0, 0.0)


func add_event_on_death(handler_object: Node, handler_function: String):
	add_event_handler(Event.Type.DEATH, handler_object, handler_function, 1.0, 0.0)


func add_event_on_kill(handler_object: Node, handler_function: String):
	add_event_handler(Event.Type.KILL, handler_object, handler_function, 1.0, 0.0)


func add_event_on_level_up(handler_object: Node, handler_function: String):
	add_event_handler(Event.Type.LEVEL_UP, handler_object, handler_function, 1.0, 0.0)


func add_event_on_attack(handler_object: Node, handler_function: String, chance: float, chance_level_add: float):
	add_event_handler(Event.Type.ATTACK, handler_object, handler_function, chance, chance_level_add)


func add_event_on_attacked(handler_object: Node, handler_function: String, chance: float, chance_level_add: float):
	add_event_handler(Event.Type.ATTACKED, handler_object, handler_function, chance, chance_level_add)


func add_event_on_damage(handler_object: Node, handler_function: String, chance: float, chance_level_add: float):
	add_event_handler(Event.Type.DAMAGE, handler_object, handler_function, chance, chance_level_add)


func add_event_on_damaged(handler_object: Node, handler_function: String, chance: float, chance_level_add: float):
	add_event_handler(Event.Type.DAMAGED, handler_object, handler_function, chance, chance_level_add)


func add_event_on_expire(handler_object: Node, handler_function: String):
	add_event_handler(Event.Type.EXPIRE, handler_object, handler_function, 1.0, 0.0)


func _on_unit_came_in_range(handler_object: Node, handler_function: String, unit: Unit):
	var range_event: Event = _make_buff_event(unit)

	handler_object.call(handler_function, range_event)


func _add_event_handler_internal(event_type: Event.Type, handler: EventHandler):
	if !event_handler_map.has(event_type):
		event_handler_map[event_type] = []

	event_handler_map[event_type].append(handler)


func _call_event_handler_list(event_type: Event.Type, event: Event):
	if !event_handler_map.has(event_type):
		return

	event._buff = self

	var handler_list: Array = event_handler_map[event_type]

	for handler in handler_list:
		var caster_level: int = _caster.get_level()
		var total_chance: float = handler.chance + handler.chance_level_add * (1 - caster_level)
		var chance_success: bool = _caster.calc_chance(total_chance)

		if !chance_success:
			continue

		handler.object.call(handler.handler_function, event)


func _on_timer_timeout():
	var cleanup_event: Event = _make_buff_event(_target)
	_call_event_handler_list(Event.Type.CLEANUP, cleanup_event)

	removed.emit()

	var expire_event: Event = _make_buff_event(_target)
	_call_event_handler_list(Event.Type.EXPIRE, expire_event)


func _on_target_death(event: Event):
	_call_event_handler_list(Event.Type.DEATH, event)
	_call_event_handler_list(Event.Type.CLEANUP, event)


func _on_target_kill(event: Event):
	_call_event_handler_list(Event.Type.KILL, event)


func _on_target_level_up():
	var level_up_event: Event = _make_buff_event(_target)
	_call_event_handler_list(Event.Type.LEVEL_UP, level_up_event)


func _on_target_attack(event: Event):
	_call_event_handler_list(Event.Type.ATTACK, event)


func _on_target_attacked(event: Event):
	_call_event_handler_list(Event.Type.ATTACKED, event)


func _on_target_dealt_damage(event: Event):
	_call_event_handler_list(Event.Type.DAMAGE, event)


func _on_target_damaged(event: Event):
	_call_event_handler_list(Event.Type.DAMAGED, event)


func _on_periodic_event_timer_timeout(handler_object: Node, handler_function: String, timer: Timer):
	var periodic_event: Event = _make_buff_event(_target)
	periodic_event._timer = timer
	handler_object.call(handler_function, periodic_event)


func _check_handler_exists(handler_object: Node, handler_function: String) -> bool:
	var exists: bool = handler_object.has_method(handler_function)

	if !exists:
		print_debug("Attempted to register an event handler that doesn't exist: ", handler_function)

	return exists


# Convenience function to make an event with "_buff" variable set to self
func _make_buff_event(target_arg: Unit) -> Event:
	var event: Event = Event.new(target_arg)
	event._buff = self

	return event


func _upgrade_or_refresh(new_level: int):
	var current_level: int = get_level()

	if current_level > new_level:
		refresh_duration()
		
		_level = new_level
		_target._change_modifier_level(get_modifier(), current_level, new_level)

		var upgrade_event: Event = _make_buff_event(_target)
		_call_event_handler_list(Event.Type.UPGRADE, upgrade_event)
	elif current_level == new_level:
		refresh_duration()

		var refresh_event: Event = _make_buff_event(_target)
		_call_event_handler_list(Event.Type.REFRESH, refresh_event)
