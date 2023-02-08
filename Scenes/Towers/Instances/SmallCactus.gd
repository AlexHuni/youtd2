class_name SmallCactus
extends Tower


func _init_tower():
	var splash_attack_buff = SplashAttack.new({320: 0.5})
	splash_attack_buff.apply_to_unit_permanent(self, self, 0, true)


func _get_specials_modifier() -> Modifier:
	var specials_modifier: Modifier = get_cactus_special(0.15, 0.01)

	return specials_modifier


static func get_cactus_special(value: float, value_add: float) -> Modifier:
	var cactus_special: Modifier = Modifier.new()
	cactus_special.add_modification(Modification.Type.MOD_DMG_TO_MASS, 0.15, 0.01)
	cactus_special.add_modification(Modification.Type.MOD_DMG_TO_HUMANOID, 0.15, 0.01)

	return cactus_special

