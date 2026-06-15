extends Node
## Cross-scene game state. Persistent progress lives in `profile`
## (saved via SaveManager); the rest is session-only routing data the
## map uses to launch battles.

const HERO_PATH := "res://data/combatants/hero.tres"
const SKILL_TREE_PATH := "res://data/skilltree/hero_skill_tree.tres"

var player_def: CombatantDefinition
var skill_tree: SkillTree
var profile: PlayerProfile # null until New Game or a save is loaded
var current_enemy: CombatantDefinition # set by the map before a battle
var current_node: StringName = &"" # map node that started the current battle
var battle_modifiers: Array = [] # raw StatModifier dicts applied to the enemy (region passives)
var last_battle_won: bool = false


func _ready() -> void:
	player_def = load(HERO_PATH) as CombatantDefinition
	skill_tree = load(SKILL_TREE_PATH) as SkillTree
	profile = SaveManager.load_profile()


## The player's battle skills: the character's base skills plus any
## granted by unlocked skill-tree nodes.
func player_skills() -> Array[SkillDefinition]:
	var out: Array[SkillDefinition] = []
	if player_def != null:
		out.append_array(player_def.skills)
	if skill_tree != null and profile != null:
		for node_id in profile.unlocked_nodes:
			var node := skill_tree.get_node_by_id(node_id)
			if node != null and node.granted_skill != null and not out.has(node.granted_skill):
				out.append(node.granted_skill)
	return out


## Banks XP into the profile and processes level-ups. Returns levels gained.
func award_xp(amount: int) -> int:
	if profile == null or amount <= 0:
		return 0
	profile.xp += amount
	return Leveling.apply_xp(profile)


func has_profile() -> bool:
	return profile != null


## Starts a fresh run with the chosen character and saves immediately.
func start_new_game() -> void:
	profile = new_profile_for(player_def)
	current_enemy = null
	current_node = &""
	battle_modifiers.clear()
	last_battle_won = false
	SaveManager.save_profile(profile)


static func new_profile_for(def: CombatantDefinition) -> PlayerProfile:
	var new_profile := PlayerProfile.new()
	new_profile.character_id = def.id
	new_profile.stats = stat_block_from_def(def)
	return new_profile


## Single place mapping a CombatantDefinition onto base stats.
static func stat_block_from_def(def: CombatantDefinition) -> StatBlock:
	var block := StatBlock.new()
	block.set_base(StatTypes.Stat.MAX_HP, def.max_hp)
	block.set_base(StatTypes.Stat.MAX_ENERGY, def.max_energy)
	block.set_base(StatTypes.Stat.ATTACK_PER_TILE, def.attack_per_tile)
	block.set_base(StatTypes.Stat.HEAL_PER_TILE, def.heal_per_tile)
	block.set_base(StatTypes.Stat.ENERGY_PER_TILE, def.energy_per_tile)
	block.set_base(StatTypes.Stat.ARMOR, def.armor)
	block.set_base(StatTypes.Stat.ARMOR_PEN, def.armor_pen)
	block.set_base(StatTypes.Stat.CRIT_CHANCE, def.crit_chance)
	block.set_base(StatTypes.Stat.CRIT_DAMAGE, def.crit_damage)
	block.set_base(StatTypes.Stat.LUCK, def.luck)
	return block


func is_node_cleared(node_id: StringName) -> bool:
	return profile != null and profile.cleared_nodes.has(node_id)


func mark_node_cleared(node_id: StringName) -> void:
	if profile != null and node_id != &"":
		profile.cleared_nodes[node_id] = true
