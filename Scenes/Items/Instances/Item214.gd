# Brimstone Helmet
extends Item


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Breath of Fire[/color]\n"
	text += "On attack, this item can change the carrier's attacktype to Elemental at the cost of 100 charges. Regenerates 50 charges per attack. This effect is not visible on the tower itself.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+1 charge regenerated\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_damage(on_damage)


func on_attack(event: Event):
	var itm: Item = self
	itm.user_real = itm.user_real + 50.0 + 1.0 * itm.get_carrier().get_level()
	itm.set_charges(int(itm.user_real))


func on_damage(event: Event):
	var itm: Item = self
	var T: Tower = itm.get_carrier()
	var C: Creep = event.get_target()

	if itm.user_real >= 100.0:
		event.damage = event.damage / AttackType.get_damage_against(T.get_attack_type(), C.get_armor_type()) * AttackType.get_damage_against(AttackType.enm.ELEMENTAL, C.get_armor_type())
		SFX.sfx_on_unit("IncinerateBuff.mdl", C, "chest")
		itm.user_real = itm.user_real - 100.0
		itm.set_charges(int(itm.user_real))


func on_pickip():
	var itm: Item = self
	itm.user_real = 0.0
	itm.ser_charges(0)
