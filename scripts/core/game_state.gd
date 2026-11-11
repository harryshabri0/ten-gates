extends Node
## Runtime-only counters for the P0 debug overlay.

signal enemy_count_changed(value: int)
signal projectile_count_changed(value: int)
signal gold_changed(value: int)
signal base_hp_changed(value: int)
signal wave_changed(value: int)

var active_enemy_count: int = 0
var active_projectile_count: int = 0
var gold: int = 0
var base_hp: int = 20
var current_wave: int = 1

func set_active_enemy_count(value: int) -> void:
	if active_enemy_count == value:
		return
	active_enemy_count = max(0, value)
	enemy_count_changed.emit(active_enemy_count)

func set_active_projectile_count(value: int) -> void:
	if active_projectile_count == value:
		return
	active_projectile_count = max(0, value)
	projectile_count_changed.emit(active_projectile_count)

func set_gold(value: int) -> void:
	gold = max(0, value)
	gold_changed.emit(gold)

func set_base_hp(value: int) -> void:
	base_hp = max(0, value)
	base_hp_changed.emit(base_hp)

func set_current_wave(value: int) -> void:
	current_wave = max(1, value)
	wave_changed.emit(current_wave)

