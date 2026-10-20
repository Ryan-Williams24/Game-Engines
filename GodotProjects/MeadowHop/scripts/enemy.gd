extends CharacterBody2D

var game: Node2D
var patrol_left = 0.0
var patrol_right = 0.0
var direction = 1.0
var speed = 75.0
var defeated = false
var clock = 0.0

func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	var shape = CollisionShape2D.new()
	var box = RectangleShape2D.new()
	box.size = Vector2(38, 30)
	shape.shape = box
	add_child(shape)

func _physics_process(delta: float) -> void:
	if defeated or game.state != "playing":
		return
	clock += delta
	velocity.y += 1550 * delta
	if position.x >= patrol_right:
		direction = -1.0
	elif position.x <= patrol_left:
		direction = 1.0
	velocity.x = direction * speed
	move_and_slide()
	if is_on_wall():
		direction *= -1
	queue_redraw()

func stomp() -> void:
	defeated = true
	hide()
	set_physics_process(false)
	game.score += 100
	game.play_sound("stomp")

func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0, Vector2(1.0, 0.9 + sin(clock * 7) * 0.06))
	draw_circle(Vector2(0, 0), 20, Color("bd6580"))
	draw_rect(Rect2(-20, 0, 40, 14), Color("bd6580"))
	draw_circle(Vector2(-9, -4), 6, Color("fff1dd"))
	draw_circle(Vector2(9, -4), 6, Color("fff1dd"))
	draw_circle(Vector2(-9 + direction * 2, -3), 2.5, Color("443147"))
	draw_circle(Vector2(9 + direction * 2, -3), 2.5, Color("443147"))
	draw_line(Vector2(-5, 7), Vector2(5, 7), Color("7b3854"), 2)
	draw_set_transform(Vector2.ZERO)
