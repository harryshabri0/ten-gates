extends Node2D
## P7 smoke test: runs all six spell pathways and validates World 4 loadout limits.

@onready var _spells: SpellSystem = $GameRoot/SpellSystem

func _ready() -> void:
	await get_tree().process_frame
	for spell_id: String in ["meteor_shower", "time_freeze", "reinforcements", "overcharge", "gold_rush", "holy_barrier"]:
		_spells.equip_spells([spell_id])
		assert(_spells.request_cast(spell_id), "Spell could not be cast: %s" % spell_id)
		if spell_id == "meteor_shower" or spell_id == "reinforcements":
			assert(_spells.confirm_target(Vector2(960, 540)), "Target spell was not confirmed: %s" % spell_id)
	var loadout: LoadoutManager = LoadoutManager.new()
	var unlocked: Array[String] = ["archer", "cannon", "barracks", "ice", "arcane"]
	var result: Dictionary = loadout.validate_selection(unlocked, unlocked, ["skyfang"])
	assert(bool(result["valid"]), "World 4 borrowed tower should fit in six slots.")
	var overfull: Array[String] = unlocked.duplicate()
	overfull.append("arcane")
	assert(not bool(loadout.validate_selection(overfull, unlocked, ["skyfang"])["valid"]), "More than six towers must be rejected.")
	print("P7 spell/loadout smoke test passed.")
	get_tree().quit()
