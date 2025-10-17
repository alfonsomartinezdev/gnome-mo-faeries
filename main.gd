extends Node2D

const COLUMNS = [150, 345, 540, 735, 930]
const ROWS = [100, 300, 500, 700, 900, 1100, 1300, 1500]
const NUM_COLORS = 4
const NUM_COLUMNS = 5
const BOTTOM_ROW = 7
const GAME_OVER_DELAY = 2.0

const LEVEL_DESIGNS = {
	1: {
		"waves": [
			[1, 1],
			[1, 1],
			[1, 1],
		]
	},
	2: {
		"waves": [
			[2, 1, 1, 1, 1, 1, 1, 1],
			[1, 1, 2, 1, 1, 2, 1, 1],
			[1, 1, 1, 1, 1, 2, 2, 3],
		]
	},
	3: {
		"waves": [
			[2, 2, 1, 1, 1, 1, 2, 2],
			[1, 2, 1, 2, 1, 2, 1, 2],
			[3, 2, 1, 1, 1, 1, 2, 3],
		]
	}
}

var faerie_scene = preload("res://Faerie.tscn")

@export var tick_rate = 3
@export var max_health = 20

var player_moves = 0
var player_health
var current_level = 1
var current_wave = 1
var current_tick_in_wave = 0
var current_wave_data = []
var current_level_waves = []
var faeries_in_wave = []
var wave_active = false


func _ready():
	player_health = max_health
	_connect_buttons()
	start_level(current_level)
	_update_all_displays()
	spawn_for_current_tick()

func _connect_buttons():
	if has_node("VictoryScreen/NextLevelButton"):
		$VictoryScreen/NextLevelButton.pressed.connect(_on_next_level_button_pressed)
	if has_node("WaveClearedScreen/NextWaveButton"):
		$WaveClearedScreen/NextWaveButton.pressed.connect(_on_next_wave_button_pressed)

func start_level(level_num: int):
	current_level = level_num
	current_wave = 1
	
	if not LEVEL_DESIGNS.has(level_num):
		print("ERROR: Level ", level_num, " not found in level_designs!")
		print("=== YOU WIN! No more levels! ===")
		return
	
	current_level_waves = LEVEL_DESIGNS[level_num]["waves"]
	start_wave(1)

func start_wave(wave_num: int):
	current_wave = wave_num
	current_tick_in_wave = 0
	wave_active = true

	if wave_num > current_level_waves.size():
		print("ERROR: Wave ", wave_num, " doesn't exist!")
		return
	
	current_wave_data = current_level_waves[wave_num - 1]
	print("=== Level ", current_level, " - Wave ", current_wave, "/", current_level_waves.size(), " ===")
	print("Wave pattern: ", current_wave_data)

func on_cannon_moved():
	player_moves += 1
	_update_move_display()
	
	if player_moves % tick_rate == 0:
		on_tick()

func on_tick():
	print("=== TICK at move ", player_moves, " ===")
	
	_process_faeries_at_bottom()
	_advance_all_faeries()
	
	current_tick_in_wave += 1

	if current_tick_in_wave <= current_wave_data.size():
		spawn_for_current_tick()

func _process_faeries_at_bottom():
	var faeries_at_bottom = faeries_in_wave.filter(
		func(f): return is_instance_valid(f) and f.current_row == BOTTOM_ROW
	)
	
	for faerie in faeries_at_bottom:
		on_faerie_reached_bottom(faerie)

func _advance_all_faeries():
	for faerie in faeries_in_wave:
		if is_instance_valid(faerie):
			faerie.advance()

func spawn_for_current_tick():
	if current_tick_in_wave >= current_wave_data.size():
		print("Wave spawning complete!")
		return
	
	var faeries_to_spawn = current_wave_data[current_tick_in_wave]
	print("Tick ", current_tick_in_wave + 1, "/", current_wave_data.size(), ": Spawning ", faeries_to_spawn, " faeries")
	
	for i in range(faeries_to_spawn):
		_spawn_single_faerie()

func _spawn_single_faerie():
	var free_columns = _get_free_columns()
	
	if free_columns.is_empty():
		print("No free columns at row 0!")
		free_columns = range(NUM_COLUMNS)
	
	var col = free_columns[randi() % free_columns.size()]
	var random_color = randi() % NUM_COLORS
	
	var faerie = faerie_scene.instantiate()
	faerie.set_properties(random_color, col, ROWS, COLUMNS)
	add_child(faerie)
	faeries_in_wave.append(faerie)
	
	print("Spawned faerie in column ", col, " (color ", random_color, ")")

func _get_free_columns() -> Array:
	var occupied = []
	for faerie in faeries_in_wave:
		if is_instance_valid(faerie) and faerie.current_row == 0:
			occupied.append(faerie.current_column)
	
	var free = []
	for i in range(NUM_COLUMNS):
		if not occupied.has(i):
			free.append(i)
	
	return free

func on_faerie_destroyed(faerie):
	faeries_in_wave.erase(faerie)
	print("Faerie destroyed! ", faeries_in_wave.size(), " remaining")
	
	if _is_wave_complete():
		wave_complete()

func _is_wave_complete() -> bool:
	var all_spawned = current_tick_in_wave >= current_wave_data.size()
	return faeries_in_wave.size() == 0 and all_spawned

func wave_complete():
	print("=== Wave ", current_wave, " Complete! ===")
	wave_active = false
	
	if current_wave >= current_level_waves.size():
		level_complete()
	else:
		_show_wave_cleared_screen()

func _show_wave_cleared_screen():
	if has_node("WaveClearedScreen"):
		$WaveClearedScreen.visible = true
		if has_node("WaveClearedScreen/WaveClearedLabel"):
			$WaveClearedScreen/WaveClearedLabel.text = "Wave " + str(current_wave) + " Cleared!"

func level_complete():
	print("=== LEVEL ", current_level, " COMPLETE! ===")
	wave_active = false
	_show_victory_screen()

func _show_victory_screen():
	if has_node("VictoryScreen"):
		$VictoryScreen.visible = true
		if has_node("VictoryScreen/VictoryLabel"):
			$VictoryScreen/VictoryLabel.text = "Level " + str(current_level) + " Complete!"

func on_faerie_reached_bottom(faerie):
	print("FAERIE REACHED BOTTOM! Taking damage!")
	
	player_health -= 1
	_update_health_display()
	
	if player_health <= 0:
		game_over()
	
	faerie.queue_free()
	on_faerie_destroyed(faerie)

func game_over():
	print("=== GAME OVER ===")
	await get_tree().create_timer(GAME_OVER_DELAY).timeout
	get_tree().reload_current_scene()

func _on_next_level_button_pressed():
	print("Starting next level...")
	
	if has_node("VictoryScreen"):
		$VictoryScreen.visible = false
	
	_reset_player_state()
	start_level(current_level + 1)
	_update_all_displays()
	spawn_for_current_tick()

func _on_next_wave_button_pressed():
	print("Starting next wave...")
	
	if has_node("WaveClearedScreen"):
		$WaveClearedScreen.visible = false
	
	current_wave += 1
	start_wave(current_wave)
	_update_level_wave_display()
	spawn_for_current_tick()

func _reset_player_state():
	player_health = max_health
	player_moves = 0
	faeries_in_wave.clear()

func _update_all_displays():
	_update_health_display()
	_update_level_wave_display()
	_update_move_display()

func _update_health_display():
	if has_node("HealthLabel"):
		$HealthLabel.text = "Health: " + str(player_health) + "/" + str(max_health)

func _update_move_display():
	if has_node("MoveCounterLabel"):
		$MoveCounterLabel.text = "Moves: " + str(player_moves)

func _update_level_wave_display():
	if has_node("LevelLabel"):
		$LevelLabel.text = "Level: " + str(current_level)
	if has_node("WaveLabel"):
		var total_waves = current_level_waves.size() if current_level_waves.size() > 0 else 0
		$WaveLabel.text = "Wave: " + str(current_wave) + "/" + str(total_waves)
