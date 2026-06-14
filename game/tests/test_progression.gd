extends BoardTestBase
## Unit tests for leveling (Leveling) and the skill tree (SkillTreeService),
## including persistence through PlayerProfile serialization.

const ST := StatTypes.Stat


func _profile() -> PlayerProfile:
	var profile := PlayerProfile.new()
	profile.stats.set_base(ST.ATTACK_PER_TILE, 5)
	profile.stats.set_base(ST.MAX_HP, 100)
	return profile


func test_xp_curve_grows() -> void:
	check_eq(Leveling.xp_to_next(1), 50, "level 1 needs 50 XP")
	check(Leveling.xp_to_next(2) > Leveling.xp_to_next(1), "later levels cost more")
	check(Leveling.xp_to_next(5) > Leveling.xp_to_next(4), "curve keeps growing")


func test_apply_xp_levels_up_and_grants_points() -> void:
	var profile := _profile()
	profile.xp = 50 # exactly one level
	var gained := Leveling.apply_xp(profile)
	check_eq(gained, 1, "50 XP at level 1 must grant one level")
	check_eq(profile.level, 2, "level must become 2")
	check_eq(profile.skill_points, 1, "one skill point per level")
	check_eq(profile.xp, 0, "the spent XP is consumed")


func test_apply_xp_handles_multiple_levels_and_remainder() -> void:
	var profile := _profile()
	profile.xp = Leveling.xp_to_next(1) + Leveling.xp_to_next(2) + 5
	var gained := Leveling.apply_xp(profile)
	check_eq(gained, 2, "enough XP for two levels")
	check_eq(profile.level, 3, "level must be 3")
	check_eq(profile.xp, 5, "the remainder carries over")


func test_unlock_spends_points_and_applies_stat_mod() -> void:
	var profile := _profile()
	profile.skill_points = 2
	var mods: Array = [{"stat": "attack_per_tile", "amount": 2}]
	check(SkillTreeService.can_unlock(profile, &"might", 1, []), "a no-prereq node is unlockable")
	check(SkillTreeService.unlock(profile, &"might", 1, [], mods), "unlocking must succeed")
	check_eq(profile.skill_points, 1, "one point spent")
	check_eq(profile.stats.get_value(ST.ATTACK_PER_TILE), 7, "the +2 attack modifier applied")
	check(SkillTreeService.is_unlocked(profile, &"might"), "the node is now unlocked")
	check(not SkillTreeService.unlock(profile, &"might", 1, [], mods), "cannot unlock twice")
	check_eq(profile.skill_points, 1, "a failed re-unlock spends nothing")


func test_unlock_requires_points_and_prereqs() -> void:
	var profile := _profile()
	profile.skill_points = 0
	check(not SkillTreeService.can_unlock(profile, &"might", 1, []), "no points means no unlock")
	profile.skill_points = 5
	check(not SkillTreeService.can_unlock(profile, &"might2", 2, [&"might"]), "missing prereq blocks unlock")
	SkillTreeService.unlock(profile, &"might", 1, [], [])
	check(SkillTreeService.can_unlock(profile, &"might2", 2, [&"might"]), "prereq met unlocks the next node")


func test_progression_persists_through_save() -> void:
	var profile := _profile()
	profile.level = 4
	profile.skill_points = 3
	profile.xp = 20
	SkillTreeService.unlock(profile, &"might", 1, [], [{"stat": "attack_per_tile", "amount": 2}])
	var restored := PlayerProfile.from_dict(profile.to_dict())
	check_eq(restored.level, 4, "level persists")
	check_eq(restored.skill_points, 2, "remaining points persist")
	check_eq(restored.xp, 20, "xp progress persists")
	check(SkillTreeService.is_unlocked(restored, &"might"), "unlocked nodes persist")
	check_eq(restored.stats.get_value(ST.ATTACK_PER_TILE), 7, "the permanent skill-tree modifier persists")
	# Unlocking is idempotent after reload (no double-apply).
	check(not SkillTreeService.unlock(restored, &"might", 1, [], [{"stat": "attack_per_tile", "amount": 2}]),
			"already-unlocked node stays unlocked after reload")
	check_eq(restored.stats.get_value(ST.ATTACK_PER_TILE), 7, "no double application on reload")
