extends SceneTree

var failures = 0
var checks = 0
var game: Node2D

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS: ", description)
	else:
		failures += 1
		push_error("FAIL: " + description)

func frames(count: int) -> void:
	for i in range(count):
		await physics_frame
		await process_frame

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames(3)
	check(game.state == "title" and game.overlay.visible, "Title menu opens")
	game.start_game()
	await frames(40)
	check(game.health == 3 and game.lives == 3 and game.player.is_on_floor(), "Start with full health and lives on solid ground")
	var start_x = game.player.position.x
	Input.action_press("move_right")
	await frames(24)
	Input.action_release("move_right")
	check(game.player.position.x > start_x + 70, "Right input moves the actual physics body")
	Input.action_press("jump")
	await frames(8)
	check(game.player.position.y < 525, "Jump rises above ground")
	Input.action_release("jump")
	await frames(40)
	check(game.player.is_on_floor(), "Jump lands on solid terrain")
	game.player.invincible = 0
	game.damage(game.player.position + Vector2(30, 0))
	check(game.health == 2 and game.player.velocity.x < 0, "Enemy damage removes a heart and pushes away")
	game.damage(game.player.position)
	check(game.health == 2, "Invincibility prevents repeated damage")
	game.player.set_physics_process(false)
	for pickup in game.pickups:
		if pickup.kind == "heart":
			game.player.position = pickup.position
			game._physics_process(0.0)
			check(game.health == 3 and pickup.taken, "Heart pickup heals and is consumed")
			break
	game.start_game()
	game.player.set_physics_process(false)
	game.player.position = Vector2(1800, 550)
	game._physics_process(0.0)
	check(game.checkpoint_active, "Crossing the checkpoint saves respawn position")
	game.player.invincible = 0
	for i in range(3):
		game.player.invincible = 0
		game.damage(Vector2(1850, 550))
	check(game.state == "respawning" and game.lives == 2, "Losing all hearts costs exactly one life")
	await frames(55)
	check(game.state == "playing" and game.health == 3 and game.player.position == game.CHECKPOINT, "Respawn restores health at the checkpoint")
	game.player.position.y = 850
	game._physics_process(0.0)
	check(game.lives == 1 and game.state == "respawning", "Falling into a pit costs a life")
	await frames(55)
	game.lose_life()
	check(game.state == "game_over" and game.lives == 0 and game.overlay.visible, "Last life opens game-over menu")
	game.start_game()
	check(game.health == 3 and game.lives == 3 and game.coins == 0 and not game.checkpoint_active, "Restart clears previous run state")
	game.player.set_physics_process(false)
	var collected = 0
	for pickup in game.pickups:
		if pickup.kind == "coin" and not pickup.taken:
			game.player.position = pickup.position
			game._physics_process(0.0)
			collected += 1
			if game.coins >= 15:
				break
	check(game.coins >= 15 and game.lives == 4 and game.score == game.coins * 10, "Collecting 15 coins awards an extra life and score")
	game.start_game()
	var enemy = game.enemies[0]
	enemy.set_physics_process(false)
	enemy.position = Vector2(500, 565)
	game.player.position = Vector2(500, 510)
	game.player.velocity = Vector2(0, 500)
	await frames(7)
	check(enemy.defeated and game.player.velocity.y < 0 and game.score >= 100, "Falling onto a slime stomps it and bounces the player")
	check("SCORE %d" % game.score in game.hud.text, "Stomping updates the visible score immediately")
	game.start_game()
	await frames(40)
	game.player.position = Vector2(1220, 550)
	game.player.invincible = 0
	await frames(3)
	check(game.health == 2, "Spike collision removes a heart")
	var pause_event = InputEventAction.new()
	pause_event.action = "pause"
	pause_event.pressed = true
	game._unhandled_input(pause_event)
	var paused_position = game.player.position
	var paused_time = game.elapsed
	await frames(12)
	check(game.state == "paused" and game.player.position == paused_position and game.elapsed == paused_time, "Pause freezes player physics and elapsed time")
	game._unhandled_input(pause_event)
	check(game.state == "playing" and not game.overlay.visible, "Pause key resumes")
	game.player.position = Vector2(3740, 550)
	game._physics_process(0.0)
	check(game.state == "won" and game.overlay.visible, "Reaching the finish flag opens victory menu")
	game.start_game()
	check(game.enemies.size() == 8 and not game.enemies[0].defeated, "Play again rebuilds enemies")
	var all_pickups_reset = true
	for pickup in game.pickups:
		all_pickups_reset = all_pickups_reset and not pickup.taken
	check(all_pickups_reset, "Play again resets every pickup")
	# Traverse the full level with only movement and jump input, without teleporting.
	await frames(40)
	Input.action_press("move_right")
	var jump_frames = 0
	for i in range(2000):
		if game.state == "won" or game.state == "game_over":
			break
		var x: float = game.player.position.x
		var need_jump = (x > 635 and x < 705) or (x > 1435 and x < 1505) or (x > 2315 and x < 2385)
		need_jump = need_jump or (x > 1120 and x < 1250) or (x > 1980 and x < 2110) or (x > 2960 and x < 3090)
		for slime in game.enemies:
			if not slime.defeated and slime.position.x > x and slime.position.x - x < 95:
				need_jump = true
		if need_jump and game.player.is_on_floor() and jump_frames == 0:
			Input.action_press("jump")
			jump_frames = 32
		if jump_frames > 0:
			jump_frames -= 1
			if jump_frames == 0:
				Input.action_release("jump")
		await frames(1)
	Input.action_release("move_right")
	Input.action_release("jump")
	print("Traversal end: state=%s position=%s lives=%d elapsed=%.2f" % [game.state, game.player.position, game.lives, game.elapsed])
	check(game.state == "won", "Full level is reachable using real movement and jump input")
	print("RESULT: %d checks, %d failures" % [checks, failures])
	game.queue_free()
	await process_frame
	quit.call_deferred(0 if failures == 0 else 1)
