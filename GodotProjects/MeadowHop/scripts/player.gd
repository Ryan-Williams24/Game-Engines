extends CharacterBody2D

const SPEED = 285.0
const JUMP_SPEED = -575.0
const GRAVITY = 1550.0
var game: Node2D
var invincible = 0.0
var coyote_time = 0.0
var jump_buffer = 0.0
var knockback_time = 0.0
var facing = 1.0
var previous_bottom = 0.0
var animation_time = 0.0

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 6.0
	var shape = CollisionShape2D.new()
	var box = RectangleShape2D.new()
	box.size = Vector2(28, 42)
	shape.shape = box
	add_child(shape)

func _physics_process(delta: float) -> void:
	if game.state != "playing":
		return
	previous_bottom = position.y + 21
	invincible = maxf(0.0, invincible - delta)
	knockback_time = maxf(0.0, knockback_time - delta)
	animation_time += delta
	coyote_time = 0.12 if is_on_floor() else maxf(0.0, coyote_time - delta)
	jump_buffer = maxf(0.0, jump_buffer - delta)
	if Input.is_action_just_pressed("jump"):
		jump_buffer = 0.14
	if jump_buffer > 0 and coyote_time > 0:
		velocity.y = JUMP_SPEED
		jump_buffer = 0.0
		coyote_time = 0.0
		game.play_sound("jump")
	if Input.is_action_just_released("jump") and velocity.y < -210:
		velocity.y = -210
	velocity.y = minf(velocity.y + GRAVITY * delta, 900.0)
	var direction = Input.get_axis("move_left", "move_right")
	if knockback_time <= 0:
		velocity.x = move_toward(velocity.x, direction * SPEED, 1900.0 * delta)
	if direction != 0:
		facing = direction
	move_and_slide()
	position.x = clampf(position.x, 20.0, game.LEVEL_WIDTH - 20.0)
	queue_redraw()

func respawn(at: Vector2) -> void:
	position = at
	velocity = Vector2.ZERO
	previous_bottom = position.y + 21
	invincible = 1.8
	knockback_time = 0.0
	coyote_time = 0.0
	jump_buffer = 0.0
	queue_redraw()

func _draw() -> void:
	if invincible > 0 and int(invincible * 12) % 2 == 0:
		return
	var step = sin(animation_time * 16) * 3 if is_on_floor() and absf(velocity.x) > 20 else 0.0
	draw_ellipse_shadow()
	draw_style_box(_box(Color("22535b")), Rect2(-13, -9, 26, 27))
	draw_rect(Rect2(-13, -8, 26, 7), Color("f8c96b"))
	draw_rect(Rect2(-11, 17, 9, 5 + step), Color("254450"))
	draw_rect(Rect2(3, 17, 9, 5 - step), Color("254450"))
	draw_circle(Vector2(0, -15), 15, Color("ffe0b1"))
	draw_style_box(_box(Color("e37159")), Rect2(-17, -29, 33, 12))
	draw_rect(Rect2(-19, -20, 40, 5), Color("b74f46"))
	draw_circle(Vector2(facing * 6, -14), 2.3, Color("253f48"))
	draw_line(Vector2(facing * 5, -7), Vector2(facing * 10, -8), Color("b96a59"), 2)
	draw_rect(Rect2(-19, 1, 6, 10), Color("ffe0b1"))
	draw_rect(Rect2(13, 1, 6, 10), Color("ffe0b1"))

func draw_ellipse_shadow() -> void:
	draw_set_transform(Vector2(0, 22), 0, Vector2(1.0, 0.25))
	draw_circle(Vector2.ZERO, 18, Color(0.12, 0.22, 0.2, 0.16))
	draw_set_transform(Vector2.ZERO)

func _box(color: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(5)
	return style
