extends Node
## P8 smoke test: campaign gates, skill-tree tiers/keystones, modifier stack, and save snapshot API.

func _ready() -> void:
	var campaign: Campaign = Campaign.new()
	campaign.record_result(1, 1, "normal", 3)
	assert(campaign.is_level_unlocked(1, 2), "The next level should unlock after a win.")
	for level: int in range(2, 11):
		campaign.record_result(1, level, "normal", 2)
	assert(campaign.is_world_unlocked(2), "World 2 needs boss defeat plus 15 stars.")
	var tree: SkillTree = SkillTree.new()
	var remaining: int = 100
	for node_id: String in ["sharpness", "eagle_eye", "nimble_hands"]:
		var result: Dictionary = tree.unlock(node_id, remaining, 3)
		assert(bool(result["valid"]), "Tier I node should unlock: %s" % node_id)
		remaining -= int(result["cost"])
	var tier_two: Dictionary = tree.unlock("weak_point", remaining, 3)
	assert(bool(tier_two["valid"]), "Tier II should unlock after 9 branch SP and World 3.")
	remaining -= int(tier_two["cost"])
	var tier_three: Dictionary = tree.unlock("glass_cannon", remaining, 6)
	assert(not bool(tier_three["valid"]), "Tier III should still require 24 branch SP.")
	var stack: StatModifierStack = tree.build_modifier_stack()
	assert(stack.multiplier("tower_damage") > 1.0, "Unlocked damage node must enter the modifier stack.")
	SaveManager.set_active_run({"level_id": "1-1", "wave": 2, "gold": 500, "base_hp": 20, "towers": []})
	SaveManager.load_save()
	assert(String(SaveManager.get_active_run().get("level_id", "")) == "1-1", "Active run snapshot should round-trip.")
	SaveManager.clear_active_run()
	print("P8 campaign/save/skill-tree smoke test passed.")
	get_tree().quit()
