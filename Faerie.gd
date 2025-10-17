extends Area2D

const COLORS = [
	Color(1.0, 0.3, 0.3),
	Color(0.3, 0.5, 1.0),
	Color(0.3, 1.0, 0.3),
	Color(1.0, 1.0, 0.3)
]
const MAX_ROW = 7
const MOVE_DURATION = 0.3

var color = 0
var current_row = 0
var current_column = 0
var row_positions = []
var column_positions = []

func _ready():
	update_color()

func set_properties(new_color: int, col: int, row_pos: Array, col_pos: Array):
	color = new_color
	current_column = col
	row_positions = row_pos
	column_positions = col_pos
	current_row = 0
	
	position = Vector2(column_positions[current_column], row_positions[current_row])
	update_color()

func update_color():
	$Sprite2D.modulate = COLORS[color]

func advance():
	current_row += 1
	
	if current_row > MAX_ROW:
		get_parent().on_faerie_reached_bottom(self)
	else:
		_animate_to_row()

func _animate_to_row():
	var tween = create_tween()
	tween.tween_property(self, "position:y", row_positions[current_row], MOVE_DURATION)
