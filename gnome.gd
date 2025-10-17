extends Area2D

var speed = 600
var color = 0

func _ready():
	# Connect collision detection
	area_entered.connect(_on_area_entered)

func _process(delta):
	position.y -= speed * delta
	
	if position.y < -100:
		queue_free()

func set_color(new_color):
	color = new_color
	
	var sprite = $Sprite2D
	match color:
		0:
			sprite.modulate = Color(1.0, 0.3, 0.3)
		1:
			sprite.modulate = Color(0.3, 0.5, 1.0)
		2:
			sprite.modulate = Color(0.3, 1.0, 0.3)
		3:
			sprite.modulate = Color(1.0, 1.0, 0.3)
	
	print("Gnome created with color: ", color)

func _on_area_entered(area):
	# Check if we hit a faerie (has a color property)
	if "color" in area and is_instance_valid(area):
		print("Gnome (color ", color, ") hit faerie (color ", area.color, ")")
		
		# If colors match, destroy the faerie
		if area.color == self.color:
			print("Colors match! Destroying faerie")
			# Tell main the faerie was destroyed
			if area.get_parent().has_method("on_faerie_destroyed"):
				area.get_parent().on_faerie_destroyed(area)
			# Destroy the faerie
			area.queue_free()
		else:
			print("Colors don't match - gnome destroyed but faerie survives")
		
		# Always destroy the gnome on contact
		queue_free()
