extends Node2D

const PlayerScript = preload("res://scripts/player.gd")
const EnemyScript = preload("res://scripts/enemy.gd")
const LEVEL_WIDTH = 3900.0
const MAX_HEALTH = 3
const START_LIVES = 3
const SPAWN = Vector2(100, 550)
const CHECKPOINT = Vector2(1800, 550)
const EXIT = Vector2(3740, 580)

# Rectangles use top-left x/y followed by width/height. Change these to edit the level.
const PLATFORMS = [
	Rect2(0, 580, 700, 180), Rect2(800, 580, 700, 180),
	Rect2(1620, 580, 760, 180), Rect2(2520, 580, 1380, 180),
	Rect2(250, 485, 145, 26), Rect2(440, 390, 145, 26),
	Rect2(940, 485, 140, 26), Rect2(1120, 390, 160, 26),
	Rect2(1670, 485, 140, 26), Rect2(1910, 400, 150, 26),
	Rect2(2200, 485, 130, 26), Rect2(2660, 485, 145, 26),
	Rect2(2850, 390, 145, 26), Rect2(3200, 485, 140, 26)
]
const SPIKES = [Rect2(1190, 558, 60, 22), Rect2(2050, 558, 60, 22), Rect2(3030, 558, 60, 22)]
const PATROLS = [
	Vector3(450, 620, 68), Vector3(850, 1030, 73), Vector3(1300, 1450, 78),
	Vector3(1840, 1990, 78), Vector3(2150, 2320, 82),
	Vector3(2560, 2740, 82), Vector3(2810, 2970, 88), Vector3(3290, 3500, 92)
]

var state = "title"
var health = MAX_HEALTH
var lives = START_LIVES
var coins = 0
var score = 0
var elapsed = 0.0
var checkpoint_active = false
var respawn_timer = 0.0
var world_time = 0.0
var player: CharacterBody2D
var camera: Camera2D
var level: Node2D
var enemies: Array[CharacterBody2D] = []
var pickups: Array[Dictionary] = []
var hud: Label
var status: Label
var message: Label
var message_timer = 0.0
var overlay: Control
var menu_title: Label
var menu_description: Label
var menu_button: Button
var sound_players: Array[AudioStreamPlayer] = []
var sounds: Dictionary = {}

func _ready() -> void:
	_register_inputs()
	_make_audio()
	camera = Camera2D.new()
	camera.position = Vector2(640, 360)
	add_child(camera)
	_build_level()
	_build_ui()
	_show_menu("MEADOW HOP", "A little adventure through a big green meadow.\n\nCollect coins, hop over spikes, and stomp the pink slimes.\nReach the yellow flag to win!", "Let's play")

func _register_inputs() -> void:
	var bindings = {"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT], "jump": [KEY_SPACE, KEY_W, KEY_UP], "pause": [KEY_ESCAPE, KEY_P], "restart": [KEY_R], "start": [KEY_ENTER]}
	for action in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in bindings[action]:
			var event = InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)

func _build_level() -> void:
	level = Node2D.new()
	level.name = "Level"
	add_child(level)
	for rect in PLATFORMS:
		var body = StaticBody2D.new()
		body.position = rect.position + rect.size / 2
		body.collision_layer = 1
		body.collision_mask = 0
		var shape = CollisionShape2D.new()
		var box = RectangleShape2D.new()
		box.size = rect.size
		shape.shape = box
		body.add_child(shape)
		level.add_child(body)
	for patrol in PATROLS:
		var enemy = EnemyScript.new()
		enemy.game = self
		enemy.patrol_left = patrol.x
		enemy.patrol_right = patrol.y
		enemy.speed = patrol.z
		enemy.position = Vector2((patrol.x + patrol.y) / 2, 565)
		level.add_child(enemy)
		enemies.append(enemy)
	for rect in PLATFORMS:
		if rect.size.y < 40:
			for i in range(3):
				pickups.append({"position": Vector2(rect.position.x + 28 + i * 40, rect.position.y - 28), "kind": "coin", "taken": false})
	for x in [210, 400, 630, 850, 1100, 1350, 1440, 1660, 1870, 2110, 2340, 2560, 2780, 2950, 3150, 3400, 3560, 3650]:
		pickups.append({"position": Vector2(x, 546), "kind": "coin", "taken": false})
	for p in [Vector2(520, 351), Vector2(1985, 361), Vector2(3270, 446)]:
		pickups.append({"position": p, "kind": "heart", "taken": false})
	player = PlayerScript.new()
	player.name = "Player"
	player.game = self
	player.position = SPAWN
	level.add_child(player)

func start_game() -> void:
	# Replace the level so restarting also resets coins, enemies, and the checkpoint.
	if is_instance_valid(level):
		remove_child(level)
		level.queue_free()
	enemies.clear()
	pickups.clear()
	health = MAX_HEALTH
	lives = START_LIVES
	coins = 0
	score = 0
	elapsed = 0.0
	checkpoint_active = false
	message_timer = 0.0
	state = "playing"
	_build_level()
	overlay.hide()
	_update_hud()
	announce("Find the yellow flag. Jump on slimes to defeat them!")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		start_game()
	elif event.is_action_pressed("pause"):
		if state == "playing":
			state = "paused"
			_show_menu("TAKE A BREATHER", "Your adventure is paused.\n\nA / D or arrow keys to move  •  Space to jump\nStomp slimes from above. Every 15 coins earns a life.", "Keep hopping")
		elif state == "paused":
			_resume()
	elif event.is_action_pressed("start"):
		_menu_action()

func _physics_process(delta: float) -> void:
	if state == "respawning":
		respawn_timer -= delta
		if respawn_timer <= 0:
			health = MAX_HEALTH
			player.respawn(CHECKPOINT if checkpoint_active else SPAWN)
			state = "playing"
			announce("Back at the checkpoint!" if checkpoint_active else "Let's try that again!")
			_update_hud()
		return
	if state != "playing":
		return
	elapsed += delta
	if player.position.y > 810:
		lose_life()
		return
	var player_rect = Rect2(player.position - Vector2(14, 21), Vector2(28, 42))
	for spike in SPIKES:
		if player_rect.intersects(spike.grow(-3)):
			damage(Vector2(spike.get_center().x, 560))
			if state != "playing":
				return
	for enemy in enemies:
		if enemy.defeated:
			continue
		var enemy_rect = Rect2(enemy.position - Vector2(20, 17), Vector2(40, 32))
		if player_rect.intersects(enemy_rect):
			if player.velocity.y > 0 and player.previous_bottom <= enemy.position.y - 8:
				enemy.stomp()
				_update_hud()
				player.velocity.y = -420
			else:
				damage(enemy.position)
				if state != "playing":
					return
	for pickup in pickups:
		if pickup.taken:
			continue
		if player.position.distance_to(pickup.position) < 34:
			if pickup.kind == "heart" and health >= MAX_HEALTH:
				continue
			pickup.taken = true
			if pickup.kind == "coin":
				coins += 1
				score += 10
				play_sound("coin")
				if coins % 15 == 0:
					lives += 1
					announce("15 coins = an extra life!")
			else:
				health = mini(MAX_HEALTH, health + 1)
				play_sound("heal")
				announce("One heart restored!")
			_update_hud()
	if not checkpoint_active and absf(player.position.x - CHECKPOINT.x) < 36 and player.position.y > 500:
		checkpoint_active = true
		play_sound("heal")
		announce("Checkpoint saved!")
	if absf(player.position.x - EXIT.x) < 45 and player.position.y > 470 and player.position.y < 600:
		win_game()

func _process(delta: float) -> void:
	if state == "playing" or state == "title":
		world_time += delta
	if state == "playing":
		message_timer = maxf(0.0, message_timer - delta)
		message.visible = message_timer > 0
	if is_instance_valid(player):
		camera.position.x = clampf(player.position.x + 120, 640.0, LEVEL_WIDTH - 640)
	status.text = "CHECKPOINT SAVED" if checkpoint_active else "REACH THE YELLOW FLAG"
	queue_redraw()

func damage(source: Vector2) -> void:
	if state != "playing" or player.invincible > 0:
		return
	health -= 1
	play_sound("hurt")
	if health <= 0:
		lose_life()
	else:
		player.invincible = 1.35
		player.knockback_time = 0.22
		player.velocity = Vector2(-235 if source.x >= player.position.x else 235, -280)
	_update_hud()

func lose_life() -> void:
	if state != "playing":
		return
	lives -= 1
	health = 0
	player.velocity = Vector2.ZERO
	play_sound("hurt")
	_update_hud()
	if lives <= 0:
		state = "game_over"
		_show_menu("ONE MORE HOP?", "Game over — the meadow got the better of you.\n\nYou collected %d coins and scored %d points.\nTry again with three fresh lives!" % [coins, score], "Try again")
	else:
		state = "respawning"
		respawn_timer = 0.8
		announce("Life lost! %d remaining." % lives)

func win_game() -> void:
	if state != "playing":
		return
	state = "won"
	play_sound("heal")
	_show_menu("YOU MADE IT!", "The meadow is yours. Nice hopping!\n\n%d coins  •  %d points  •  %d:%02d\n%d lives left. Can you collect every coin next time?" % [coins, score, int(elapsed) / 60, int(elapsed) % 60, lives], "Play again")

func announce(text: String) -> void:
	message.text = text
	message_timer = 3.5
	message.show()

func _resume() -> void:
	state = "playing"
	overlay.hide()

func _menu_action() -> void:
	if state == "paused":
		_resume()
	elif state in ["title", "won", "game_over"]:
		start_game()

func _build_ui() -> void:
	var layer = CanvasLayer.new()
	add_child(layer)
	var root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	var bar = Panel.new()
	bar.position = Vector2(24, 22)
	bar.size = Vector2(1232, 72)
	bar.add_theme_stylebox_override("panel", _style(Color("fff8e8"), 18))
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bar)
	_label(root, "MEADOW HOP", Vector2(48, 38), Vector2(245, 36), 28, Color("264f54"))
	hud = _label(root, "", Vector2(340, 41), Vector2(780, 36), 24, Color("264f54"))
	status = _label(root, "", Vector2(30, 110), Vector2(1220, 32), 16, Color("466b6e"))
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message = _label(root, "", Vector2(100, 617), Vector2(1080, 38), 22, Color("fff8e8"))
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.add_theme_color_override("font_shadow_color", Color("264f54"))
	message.add_theme_constant_override("shadow_offset_x", 2)
	message.add_theme_constant_override("shadow_offset_y", 2)
	_label(root, "A / D or ← / →  MOVE     SPACE / W / ↑  JUMP     ESC / P  PAUSE     R  RESTART", Vector2(100, 681), Vector2(1080, 30), 16, Color("fff8e8")).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(overlay)
	var dim = ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.08, 0.19, 0.23, 0.5)
	overlay.add_child(dim)
	var panel = Panel.new()
	panel.position = Vector2(300, 172)
	panel.size = Vector2(680, 392)
	panel.add_theme_stylebox_override("panel", _style(Color("fff8e8"), 26))
	overlay.add_child(panel)
	_label(panel, "A SMALL ADVENTURE", Vector2(40, 28), Vector2(600, 26), 16, Color("b66a48")).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_title = _label(panel, "", Vector2(30, 68), Vector2(620, 62), 46, Color("264f54"))
	menu_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_description = _label(panel, "", Vector2(35, 146), Vector2(610, 146), 20, Color("547078"))
	menu_description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_button = Button.new()
	menu_button.position = Vector2(225, 310)
	menu_button.size = Vector2(230, 58)
	menu_button.add_theme_font_size_override("font_size", 24)
	menu_button.add_theme_color_override("font_color", Color("fff8e8"))
	menu_button.add_theme_color_override("font_hover_color", Color("fff8e8"))
	menu_button.add_theme_color_override("font_focus_color", Color("fff8e8"))
	menu_button.add_theme_stylebox_override("normal", _style(Color("2d7770"), 14))
	menu_button.add_theme_stylebox_override("hover", _style(Color("3b9385"), 14))
	menu_button.add_theme_stylebox_override("pressed", _style(Color("21594f"), 14))
	menu_button.pressed.connect(_menu_action)
	panel.add_child(menu_button)
	_update_hud()

func _label(parent: Node, text: String, at: Vector2, dimensions: Vector2, font_size: int, color: Color) -> Label:
	var label = Label.new()
	label.text = text
	label.position = at
	label.size = dimensions
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _style(color: Color, radius: int) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	return style

func _show_menu(title: String, description: String, button_text: String) -> void:
	menu_title.text = title
	menu_description.text = description
	menu_button.text = button_text
	overlay.show()
	# Enter works even when the game window receives focus for the first time.
	menu_button.grab_focus()

func _update_hud() -> void:
	hud.text = "%s%s    |    LIVES %d    |    COINS %02d    |    SCORE %d" % ["♥".repeat(health), "♡".repeat(MAX_HEALTH - health), lives, coins, score]

func _draw() -> void:
	if not is_instance_valid(camera):
		return
	var left = camera.position.x - 640
	draw_rect(Rect2(left - 50, -100, 1380, 1000), Color("c4e4ed"))
	draw_circle(Vector2(left + 1030, 184), 54, Color("ffefbd"))
	for i in range(12):
		var x = i * 460.0 - camera.position.x * 0.18
		_cloud(Vector2(x, 185 + (i % 3) * 36))
	for i in range(12):
		var x = i * 450.0 - camera.position.x * 0.12
		draw_colored_polygon(PackedVector2Array([Vector2(x - 230, 640), Vector2(x + 140, 285 + (i % 3) * 42), Vector2(x + 430, 640)]), Color("99c9bd"))
	for i in range(14):
		var x = i * 380.0 - camera.position.x * 0.06
		draw_colored_polygon(PackedVector2Array([Vector2(x - 140, 660), Vector2(x + 110, 420 + (i % 2) * 38), Vector2(x + 360, 660)]), Color("72b7a5"))
	draw_rect(Rect2(left - 40, 700, 1360, 110), Color("355b5a"))
	for rect in PLATFORMS:
		draw_style_box(_style(Color("b28662"), 7), rect)
		draw_rect(Rect2(rect.position + Vector2(0, 7), Vector2(rect.size.x, 10)), Color("527e58"))
		draw_style_box(_style(Color("83b761"), 5), Rect2(rect.position, Vector2(rect.size.x, 10)))
		if rect.size.y > 40:
			for i in range(int(rect.size.x / 32)):
				var at = rect.position + Vector2(16 + i * 32, 36 + (i % 3) * 25)
				draw_circle(at, 3, Color("946e52"))
	for rect in SPIKES:
		for i in range(3):
			var at = rect.position + Vector2(i * 20, 0)
			draw_colored_polygon(PackedVector2Array([at + Vector2(0, 22), at + Vector2(10, 0), at + Vector2(20, 22)]), Color("506775"))
			draw_line(rect.position + Vector2(0, 22), rect.end, Color("364d57"), 3)
	for pickup in pickups:
		if pickup.taken:
			continue
		var at: Vector2 = pickup.position + Vector2(0, sin(world_time * 3 + pickup.position.x) * 4)
		if pickup.kind == "coin":
			draw_circle(at, 12, Color("d79739"))
			draw_circle(at + Vector2(0, -2), 10, Color("ffd575"))
			draw_line(at + Vector2(0, -8), at + Vector2(0, 4), Color("d79739"), 3)
		else:
			_heart(at)
	_flag(Vector2(CHECKPOINT.x, 580), Color("62bea1") if checkpoint_active else Color("e2f3e4"), 65)
	_flag(EXIT, Color("ffd575"), 135)
	_sign(Vector2(90, 580), "GO! →")
	_sign(Vector2(1730, 580), "SAVE")
	for x in [160, 300, 660, 890, 1390, 1690, 2240, 2610, 2900, 3180, 3590, 3820]:
		_flower(Vector2(x, 580))
	var font = ThemeDB.fallback_font
	draw_string(font, Vector2(3600, 414), "FINISH", HORIZONTAL_ALIGNMENT_CENTER, 280, 26, Color("264f54"))

func _cloud(at: Vector2) -> void:
	for offset in [Vector2(-33, 7), Vector2(0, -7), Vector2(35, 8)]:
		draw_circle(at + offset, 28, Color("eaf5f4"))
	draw_rect(Rect2(at + Vector2(-35, 7), Vector2(72, 24)), Color("eaf5f4"))

func _flag(at: Vector2, color: Color, height: float) -> void:
	draw_line(at, at - Vector2(0, height), Color("49676c"), 6)
	draw_circle(at - Vector2(0, height + 3), 5, Color("fff8e8"))
	draw_colored_polygon(PackedVector2Array([at - Vector2(0, height), at + Vector2(64, -height + 10), at + Vector2(0, -height + 35)]), color)
	draw_rect(Rect2(at - Vector2(12, 4), Vector2(24, 4)), Color("49676c"))

func _sign(at: Vector2, text: String) -> void:
	draw_line(at, at - Vector2(0, 54), Color("896449"), 6)
	draw_style_box(_style(Color("fff0c9"), 5), Rect2(at - Vector2(35, 70), Vector2(70, 30)))
	draw_string(ThemeDB.fallback_font, at - Vector2(30, 49), text, HORIZONTAL_ALIGNMENT_CENTER, 60, 14, Color("6e624f"))

func _flower(at: Vector2) -> void:
	draw_line(at, at - Vector2(0, 17), Color("4d8757"), 2)
	for offset in [Vector2(-4, -17), Vector2(4, -17), Vector2(0, -21), Vector2(0, -13)]:
		draw_circle(at + offset, 4, Color("fff2d5"))
	draw_circle(at - Vector2(0, 17), 3, Color("e6b65d"))

func _heart(at: Vector2) -> void:
	draw_circle(at + Vector2(-6, -4), 7, Color("e7777b"))
	draw_circle(at + Vector2(6, -4), 7, Color("e7777b"))
	draw_colored_polygon(PackedVector2Array([at + Vector2(-12, -2), at + Vector2(12, -2), at + Vector2(0, 13)]), Color("e7777b"))

func _make_audio() -> void:
	for kind in ["jump", "coin", "stomp", "hurt", "heal"]:
		var frequency = {"jump": 430.0, "coin": 950.0, "stomp": 160.0, "hurt": 110.0, "heal": 620.0}[kind]
		var length = 0.12 if kind != "heal" else 0.3
		var bytes = PackedByteArray()
		var count = int(22050 * length)
		bytes.resize(count * 2)
		for i in range(count):
			var t = float(i) / 22050
			var pitch = frequency * (1.0 + t * 2.0) if kind != "hurt" else frequency * (1.0 - t * 2.0)
			var sample = int(sin(TAU * pitch * t) * 7000 * (1.0 - float(i) / count))
			bytes.encode_s16(i * 2, sample)
		var wav = AudioStreamWAV.new()
		wav.format = AudioStreamWAV.FORMAT_16_BITS
		wav.mix_rate = 22050
		wav.data = bytes
		sounds[kind] = wav
	for i in range(6):
		var audio = AudioStreamPlayer.new()
		audio.volume_db = -10
		add_child(audio)
		sound_players.append(audio)

func play_sound(kind: String) -> void:
	for audio in sound_players:
		if not audio.playing:
			audio.stream = sounds[kind]
			audio.play()
			return
