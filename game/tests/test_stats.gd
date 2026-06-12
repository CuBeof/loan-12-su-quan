extends BoardTestBase
## Unit tests for the stat framework (StatBlock/StatModifier), the
## armor/penetration rules, and PlayerProfile serialization.

const ST := StatTypes.Stat
const LT := StatTypes.Lifetime


func test_flat_and_percent_modifiers_stack() -> void:
	var block := StatBlock.new()
	block.set_base(ST.ATTACK_PER_TILE, 10)
	block.add_modifier(StatModifier.make(ST.ATTACK_PER_TILE, 5, &"equip_sword", LT.PERMANENT))
	block.add_modifier(StatModifier.make(ST.ATTACK_PER_TILE, 20, &"npc_blessing", LT.RUN, StatModifier.Kind.PERCENT))
	check_eq(block.get_value(ST.ATTACK_PER_TILE), 18, "(10 + 5) * 120% must be 18")
	check_eq(block.get_value(ST.ARMOR), 0, "untouched stats default to 0")


func test_remove_source_drops_only_that_source() -> void:
	var block := StatBlock.new()
	block.set_base(ST.ARMOR, 1)
	block.add_modifier(StatModifier.make(ST.ARMOR, 3, &"equip_iron_vest", LT.PERMANENT))
	block.add_modifier(StatModifier.make(ST.ARMOR, 2, &"item_charm", LT.RUN))
	check_eq(block.get_value(ST.ARMOR), 6, "all sources must stack")
	block.remove_source(&"equip_iron_vest")
	check_eq(block.get_value(ST.ARMOR), 3, "unequipping must remove only that source")


func test_clear_lifetime_expires_battle_mods_only() -> void:
	var block := StatBlock.new()
	block.add_modifier(StatModifier.make(ST.ARMOR, 4, &"skill_iron_wall", LT.BATTLE))
	block.add_modifier(StatModifier.make(ST.ARMOR, 2, &"npc_blessing", LT.RUN))
	block.clear_lifetime(LT.BATTLE)
	check_eq(block.get_value(ST.ARMOR), 2, "battle buffs expire, run buffs stay")


func test_serialization_skips_battle_mods_and_roundtrips() -> void:
	var block := StatBlock.new()
	block.set_base(ST.MAX_HP, 100)
	block.set_base(ST.ARMOR, 1)
	block.add_modifier(StatModifier.make(ST.ARMOR, 2, &"item_charm", LT.RUN))
	block.add_modifier(StatModifier.make(ST.ARMOR, 9, &"skill_iron_wall", LT.BATTLE))
	var restored := StatBlock.from_dict(block.to_dict())
	check_eq(restored.get_value(ST.MAX_HP), 100, "base values must roundtrip")
	check_eq(restored.get_value(ST.ARMOR), 3, "RUN modifier kept, BATTLE modifier never saved")
	check_eq(restored.modifier_count(), 1, "exactly one persisted modifier expected")


func test_unknown_stats_in_save_are_skipped() -> void:
	var data := {
		"base": {"armor": 3, "future_mystery_stat": 99},
		"modifiers": [
			{"stat": "future_mystery_stat", "amount": 5, "kind": "flat", "source": "x", "lifetime": "run"},
			{"stat": "armor", "amount": 1, "kind": "flat", "source": "item_charm", "lifetime": "run"},
		],
	}
	var block := StatBlock.from_dict(data)
	check_eq(block.get_value(ST.ARMOR), 4, "known data must load")
	check_eq(block.modifier_count(), 1, "unknown-stat modifiers must be skipped, not crash")


func test_armor_blocks_damage_but_one_always_passes() -> void:
	var state := CombatantState.make(100, 5, 4, 5, 50, 99)
	var hit: Dictionary = state.take_damage(5)
	check_eq(int(hit.dealt), 1, "a non-zero hit always deals at least 1")
	check_eq(int(hit.blocked), 4, "the rest is blocked by armor")
	check_eq(state.hp, 99, "hp must drop by exactly the dealt amount")
	var nothing: Dictionary = state.take_damage(0)
	check_eq(int(nothing.dealt), 0, "zero damage stays zero")


func test_armor_pen_pierces_armor() -> void:
	var state := CombatantState.make(100, 5, 4, 5, 50, 3)
	var hit: Dictionary = state.take_damage(10, 2)
	check_eq(int(hit.dealt), 9, "pen 2 leaves armor 1: 10 - 1 = 9")
	check_eq(int(hit.blocked), 1, "blocked must report the remaining armor")
	var overkill_pen: Dictionary = state.take_damage(10, 50)
	check_eq(int(overkill_pen.dealt), 10, "pen beyond armor must not add damage")


func test_battle_damage_respects_armor_and_pen() -> void:
	var turns := TurnManager.new()
	# player: pen 1; enemy: armor 2 -> effective armor 1
	turns.setup(CombatantState.make(100, 5, 4, 5, 50, 0, 1), CombatantState.make(80, 4, 3, 5, 50, 2), 7)
	var effects := turns.apply_move(_attack_move())
	check_eq(turns.enemy.hp, 66, "15 raw - 1 effective armor = 14 damage")
	check_eq(int(effects[0].blocked), 1, "effect must report the blocked amount")


func test_penalty_damage_respects_player_armor() -> void:
	var turns := TurnManager.new()
	# player armor 3; enemy pen 1 -> effective armor 2; penalty 2 * 4 = 8 raw
	turns.setup(CombatantState.make(100, 5, 4, 5, 50, 3), CombatantState.make(80, 4, 3, 5, 50, 0, 1), 7)
	var rejected := MoveResult.new()
	rejected.penalty_attack_tiles = BoardLogic.INVALID_SWAP_PENALTY_ATTACK_TILES
	turns.apply_rejected(rejected)
	check_eq(turns.player.hp, 94, "8 raw - 2 effective armor = 6 damage")


func test_player_profile_roundtrips() -> void:
	var profile := PlayerProfile.new()
	profile.character_id = &"hero"
	profile.level = 3
	profile.xp = 120
	profile.gold = 45
	profile.current_hp = 37
	profile.cleared_nodes[&"bandit_camp"] = true
	profile.stats.set_base(ST.MAX_HP, 110)
	profile.stats.add_modifier(StatModifier.make(ST.ARMOR, 2, &"npc_blessing", LT.RUN))
	var restored := PlayerProfile.from_dict(profile.to_dict())
	check_eq(restored.level, 3, "level must roundtrip")
	check_eq(restored.gold, 45, "gold must roundtrip")
	check_eq(restored.current_hp, 37, "persistent hp must roundtrip")
	check(restored.cleared_nodes.has(&"bandit_camp"), "map progress must roundtrip")
	check_eq(restored.stats.get_value(ST.ARMOR), 2, "run modifiers must roundtrip")
	check_eq(restored.max_hp(), 110, "stat base must roundtrip")


func test_profile_from_empty_dict_gets_safe_defaults() -> void:
	var profile := PlayerProfile.from_dict({})
	check_eq(profile.level, 1, "missing fields fall back to defaults")
	check_eq(profile.current_hp, -1, "missing hp means full")
	check(profile.cleared_nodes.is_empty(), "no progress by default")


func _attack_move() -> MoveResult:
	var result := MoveResult.new()
	result.valid = true
	result.cleared_counts = {TileTypes.Type.ATTACK: 3}
	return result
