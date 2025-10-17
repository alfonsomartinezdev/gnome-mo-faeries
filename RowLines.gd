extends Node2D

var row_positions = [100, 300, 500, 700, 900, 1100, 1300, 1500]
var line_color = Color(1, 1, 1, .1 )

func _ready():
	queue_redraw()

func _draw():
	for row_y in row_positions:
		draw_line(
			Vector2(0, row_y),
			Vector2(1080, row_y),
			line_color,
			3.0 
		)
