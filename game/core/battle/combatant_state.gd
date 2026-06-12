class_name CombatantState
extends RefCounted
## Runtime battle stats of one combatant (player or enemy). Pure logic:
## built from primitive values so the core never touches Resources.

var max_hp: int
var hp: int
var max_energy: int
var energy: int = 0
var attack_per_tile: int
var heal_per_tile: int
var energy_per_tile: int
var gold: int = 0 # earned this battle, awarded only on victory (SPEC)
var xp: int = 0 # earned this battle, awarded only on victory (SPEC)


static func make(max_hp_: int, attack_per_tile_: int, heal_per_tile_: int,
		energy_per_tile_: int, max_energy_: int) -> CombatantState:
	var state := CombatantState.new()
	state.max_hp = max_hp_
	state.hp = max_hp_
	state.attack_per_tile = attack_per_tile_
	state.heal_per_tile = heal_per_tile_
	state.energy_per_tile = energy_per_tile_
	state.max_energy = max_energy_
	return state


func is_alive() -> bool:
	return hp > 0


## Returns the damage actually dealt.
func take_damage(amount: int) -> int:
	var dealt := mini(amount, hp)
	hp -= dealt
	return dealt


## Returns the HP actually restored (no overheal yet — character-specific
## overheal buffs come later per SPEC).
func heal(amount: int) -> int:
	var restored := mini(amount, max_hp - hp)
	hp += restored
	return restored


## Returns the energy actually gained.
func gain_energy(amount: int) -> int:
	var gained := mini(amount, max_energy - energy)
	energy += gained
	return gained
