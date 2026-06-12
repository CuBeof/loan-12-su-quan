extends BoardTestBase
## Unit tests for the item/inventory/shop rules (ItemService) and their
## persistence through PlayerProfile serialization.

const ST := StatTypes.Stat

const ARMOR_VEST_EFFECTS: Array[Dictionary] = [
	{"kind": "stat_mod", "stat": "armor", "amount": 5},
]
const GINSENG_EFFECTS: Array[Dictionary] = [
	{"kind": "heal", "amount": 50},
]


func _profile(gold: int = 500) -> PlayerProfile:
	var profile := PlayerProfile.new()
	profile.gold = gold
	profile.stats.set_base(ST.MAX_HP, 100)
	return profile


func test_buy_deducts_gold_and_adds_item() -> void:
	var profile := _profile(500)
	check(ItemService.buy(profile, &"armor_vest", 200), "buying with enough gold must succeed")
	check_eq(profile.gold, 300, "200 gold must be spent")
	check_eq(ItemService.count(profile, &"armor_vest"), 1, "the item must land in the inventory")
	check(ItemService.buy(profile, &"ginseng", 100), "second purchase must succeed")
	check(ItemService.buy(profile, &"ginseng", 100), "stacking a consumable must succeed")
	check_eq(ItemService.count(profile, &"ginseng"), 2, "consumables must stack")


func test_buy_fails_without_enough_gold() -> void:
	var profile := _profile(150)
	check(not ItemService.buy(profile, &"armor_vest", 200), "buying beyond gold must fail")
	check_eq(profile.gold, 150, "gold must not change on a failed purchase")
	check_eq(ItemService.count(profile, &"armor_vest"), 0, "nothing must be added on a failed purchase")


func test_equip_applies_armor_and_unequip_removes_it() -> void:
	var profile := _profile()
	ItemService.buy(profile, &"armor_vest", 200)
	check(ItemService.equip(profile, &"armor_vest", ARMOR_VEST_EFFECTS), "equipping an owned item must succeed")
	check_eq(profile.stats.get_value(ST.ARMOR), 5, "the vest must grant +5 armor")
	check(ItemService.is_equipped(profile, &"armor_vest"), "the vest must be marked equipped")
	check(not ItemService.equip(profile, &"armor_vest", ARMOR_VEST_EFFECTS), "double-equipping must fail")
	check_eq(profile.stats.get_value(ST.ARMOR), 5, "armor must not stack from double-equip")
	check(ItemService.unequip(profile, &"armor_vest"), "unequip must succeed")
	check_eq(profile.stats.get_value(ST.ARMOR), 0, "armor must return to base after unequip")
	check_eq(ItemService.count(profile, &"armor_vest"), 1, "unequip must not consume the item")


func test_equip_requires_owning_the_item() -> void:
	var profile := _profile()
	check(not ItemService.equip(profile, &"armor_vest", ARMOR_VEST_EFFECTS), "equipping an unowned item must fail")


func test_ginseng_heals_and_is_consumed() -> void:
	var profile := _profile()
	profile.current_hp = 30
	ItemService.buy(profile, &"ginseng", 100)
	check(ItemService.use(profile, &"ginseng", GINSENG_EFFECTS), "using a ginseng must succeed")
	check_eq(profile.current_hp, 80, "30 + 50 = 80 HP")
	check_eq(ItemService.count(profile, &"ginseng"), 0, "the ginseng must be consumed")
	check(not ItemService.use(profile, &"ginseng", GINSENG_EFFECTS), "using with none left must fail")


func test_heal_clamps_at_max_hp() -> void:
	var profile := _profile()
	profile.current_hp = 80
	ItemService.buy(profile, &"ginseng", 100)
	ItemService.use(profile, &"ginseng", GINSENG_EFFECTS)
	check_eq(profile.current_hp, 100, "healing must clamp at max HP")


func test_cannot_use_heal_at_full_hp() -> void:
	var profile := _profile()
	ItemService.buy(profile, &"ginseng", 100)
	check(not ItemService.can_use(profile, GINSENG_EFFECTS), "full HP (-1) means no healing needed")
	check(not ItemService.use(profile, &"ginseng", GINSENG_EFFECTS), "using at full HP must fail")
	check_eq(ItemService.count(profile, &"ginseng"), 1, "the item must not be wasted")


func test_inventory_and_equipment_survive_save_roundtrip() -> void:
	var profile := _profile()
	ItemService.buy(profile, &"armor_vest", 200)
	ItemService.buy(profile, &"ginseng", 100)
	ItemService.equip(profile, &"armor_vest", ARMOR_VEST_EFFECTS)
	var restored := PlayerProfile.from_dict(profile.to_dict())
	check_eq(ItemService.count(restored, &"armor_vest"), 1, "inventory must roundtrip")
	check_eq(ItemService.count(restored, &"ginseng"), 1, "stacks must roundtrip")
	check(ItemService.is_equipped(restored, &"armor_vest"), "equipped list must roundtrip")
	check_eq(restored.stats.get_value(ST.ARMOR), 5, "the equip modifier must roundtrip (permanent lifetime)")
	check(ItemService.unequip(restored, &"armor_vest"), "unequip must work after a reload")
	check_eq(restored.stats.get_value(ST.ARMOR), 0, "the reloaded modifier must be removable by source")


func test_equipped_armor_reaches_battle_state() -> void:
	var profile := _profile()
	ItemService.buy(profile, &"armor_vest", 200)
	ItemService.equip(profile, &"armor_vest", ARMOR_VEST_EFFECTS)
	var state := CombatantState.from_block(profile.stats)
	check_eq(state.armor, 5, "battle state wrapping the profile must see the vest's armor")
