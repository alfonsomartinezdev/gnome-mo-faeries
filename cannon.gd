extends Node2D

const SLOT_POSITIONS = [150, 345, 540, 735, 930]
const COLOR_NAMES = ["Red", "Green", "Blue", "Yellow"]
const COLORS = [
	Color(1.0, 0.3, 0.3),  # Red
	Color(0.3, 0.5, 1.0),  # Blue
	Color(0.3, 1.0, 0.3),  # Green
	Color(1.0, 1.0, 0.3)   # Yellow
]
const NUM_COLORS = 4
const NUM_SLOTS = 5

var gnome_scene = preload("res://gnome.tscn")

var current_slot = 2
var current_color = 0
var is_moving = false
var can_fire = true

@export var move_duration = 0.2
@export var reload_time = 0.25

func _ready():
	position = Vector2(SLOT_POSITIONS[current_slot], 1750)
	update_cannon_color()

func _process(_delta):
	if is_moving or _are_screens_visible():
		return
	
	if Input.is_action_just_pressed("ui_left"):
		move_left()
	elif Input.is_action_just_pressed("ui_right"):
		move_right()
	elif Input.is_action_just_pressed("ui_accept"):
		fire()

func _are_screens_visible() -> bool:
	return _is_screen_visible("VictoryScreen") or _is_screen_visible("WaveClearedScreen")

func _is_screen_visible(screen_name: String) -> bool:
	var parent = get_parent()
	return parent.has_node(screen_name) and parent.get_node(screen_name).visible

func move_left():
	_rotate_color(-1)
	if current_slot > 0:
		_move_to_slot(current_slot - 1)
	else:
		print("Rotated at edge! Color: ", COLOR_NAMES[current_color])

func move_right():
	_rotate_color(1)
	if current_slot < NUM_SLOTS - 1:
		_move_to_slot(current_slot + 1)
	else:
		print("Rotated at edge! Color: ", COLOR_NAMES[current_color])

func _rotate_color(direction: int):
	current_color = (current_color + direction) % NUM_COLORS
	if current_color < 0:
		current_color += NUM_COLORS
	
	animate_rotation(direction * 90)
	update_cannon_color()
	get_parent().on_cannon_moved()

func _move_to_slot(slot: int):
	is_moving = true
	current_slot = slot
	animate_to_slot()

func animate_rotation(degrees: float):
	is_moving = true
	var sprite = $Sprite2D
	var tween = create_tween()
	tween.tween_property(sprite, "rotation_degrees", sprite.rotation_degrees + degrees, move_duration)
	tween.finished.connect(_on_movement_finished)

func animate_to_slot():
	var tween = create_tween()
	tween.tween_property(self, "position:x", SLOT_POSITIONS[current_slot], move_duration)
	tween.finished.connect(_on_movement_finished)

func _on_movement_finished():
	is_moving = false
	print("Arrived at slot ", current_slot, " Color: ", COLOR_NAMES[current_color])

func update_cannon_color():
	$Sprite2D.modulate = COLORS[current_color]

func fire():
	if is_moving or not can_fire:
		return
	
	_spawn_gnome()
	_start_reload()

func _spawn_gnome():
	var gnome = gnome_scene.instantiate()
	gnome.position = position
	gnome.set_color(current_color)
	get_parent().add_child(gnome)

func _start_reload():
	can_fire = false
	await get_tree().create_timer(reload_time).timeout
	can_fire = true
