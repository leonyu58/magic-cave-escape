extends Node2D

var player_script = preload("res://scripts/player.gd")
var enemy_script = preload("res://scripts/enemy.gd")
var turret_script = preload("res://scripts/turret.gd")
var rune_script = preload("res://scripts/rune_pickup.gd")
var health_script = preload("res://scripts/health_pickup.gd")
var portal_script = preload("res://scripts/portal.gd")
var glow_script = preload("res://scripts/glow_sprite.gd")

var player
var glow_sprite
var canvas_modulate: CanvasModulate
var health_bar: ProgressBar
var rune_label: Label
var objective_label: Label
var message_label: Label
var win_panel: ColorRect
var water_altar_pos := Vector2(3600, 425)
var water_barrier: StaticBody2D
var cave_spawn := Vector2(890, 410)
var cave_entered := false

func _ready():
	setup_input_actions()
	build_background()
	build_level()
	build_player()
	build_ui()


func setup_input_actions():
	add_key_action("move_left", KEY_A)
	add_key_action("move_right", KEY_D)
	add_key_action("jump", KEY_SPACE)
	add_mouse_action("attack", MOUSE_BUTTON_LEFT)
	add_key_action("magic", KEY_Q)
	add_key_action("dash", KEY_SHIFT)
	add_key_action("rune_fire", KEY_1)
	add_key_action("rune_water", KEY_2)
	add_key_action("rune_earth", KEY_3)
	add_key_action("rune_air", KEY_4)

func add_key_action(action_name: String, keycode: Key):
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	InputMap.action_add_event(action_name, event)

func add_mouse_action(action_name: String, button_index: MouseButton):
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var event := InputEventMouseButton.new()
	event.button_index = button_index
	InputMap.action_add_event(action_name, event)

func build_background():
	# Surface sky
	add_visual_rect(Vector2(250, 100), Vector2(1450, 1050), Color(0.43, 0.72, 0.92), -20)
	# Cave darkness background
	add_visual_rect(Vector2(3100, 200), Vector2(5000, 1600), Color(0.075, 0.045, 0.12), -20)

	canvas_modulate = CanvasModulate.new()
	canvas_modulate.color = Color.WHITE
	add_child(canvas_modulate)

func build_level():
	# Surface section
	make_platform(Vector2(260, 500), Vector2(1450, 120), Color(0.18, 0.42, 0.18))
	add_visual_rect(Vector2(260, 455), Vector2(1450, 32), Color(0.32, 0.67, 0.25), -1)

	var entrance = portal_script.new()
	entrance.position = Vector2(510, 420)
	entrance.destination = cave_spawn
	add_child(entrance)

	# Underground floor and platform chunks
	make_platform(Vector2(1200, 535), Vector2(850, 90), Color(0.18, 0.13, 0.24))
	make_platform(Vector2(2120, 535), Vector2(750, 90), Color(0.16, 0.11, 0.22))
	make_platform(Vector2(3020, 535), Vector2(880, 90), Color(0.19, 0.12, 0.26))
	make_platform(Vector2(4150, 535), Vector2(1350, 90), Color(0.17, 0.105, 0.23))

	# Floating platforms for air-rune movement showcase
	make_platform(Vector2(1810, 390), Vector2(170, 24), Color(0.28, 0.20, 0.36))
	make_platform(Vector2(1980, 290), Vector2(160, 24), Color(0.28, 0.20, 0.36))
	make_platform(Vector2(3200, 390), Vector2(170, 24), Color(0.28, 0.20, 0.36))

	# Decorative crystals / magical cave lighting colors
	for crystal_data in [
		[Vector2(970, 470), Color(0.65, 0.25, 0.95)],
		[Vector2(1460, 470), Color(0.2, 0.85, 1.0)],
		[Vector2(2260, 470), Color(0.9, 0.3, 0.8)],
		[Vector2(2880, 470), Color(0.4, 0.95, 0.65)],
		[Vector2(3390, 470), Color(0.3, 0.65, 1.0)],
		[Vector2(4300, 470), Color(0.85, 0.32, 1.0)]
	]:
		make_crystal(crystal_data[0], crystal_data[1])

	# Elemental runes (all four are represented in the prototype)
	spawn_rune("fire", Vector2(1240, 455))
	spawn_rune("air", Vector2(1870, 335))
	spawn_rune("earth", Vector2(2720, 455))
	spawn_rune("water", Vector2(3440, 455))

	# Enemies
	spawn_enemy(Vector2(1450, 460))
	spawn_enemy(Vector2(2380, 460))
	spawn_enemy(Vector2(2920, 460))
	spawn_enemy(Vector2(4200, 460))
	spawn_turret(Vector2(3250, 440))

	# Water altar and barrier. Q with Water near the altar opens the path.
	make_altar(water_altar_pos)
	water_barrier = make_platform(Vector2(3790, 365), Vector2(44, 340), Color(0.16, 0.52, 0.82))

	# Exit portal
	var exit_portal = portal_script.new()
	exit_portal.position = Vector2(4600, 440)
	exit_portal.is_exit = true
	add_child(exit_portal)

func build_player():
	player = player_script.new()
	player.position = Vector2(120, 420)
	add_child(player)

	var camera := Camera2D.new()
	camera.position = Vector2(120, -55)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.0
	camera.limit_left = -450
	camera.limit_right = 5000
	camera.limit_top = -300
	camera.limit_bottom = 850
	player.add_child(camera)

	glow_sprite = glow_script.new()
	glow_sprite.target = player
	glow_sprite.global_position = player.global_position + Vector2(40, -50)
	add_child(glow_sprite)

	# Assign target after player exists
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.target = player

	player.health_changed.connect(_on_health_changed)
	player.rune_changed.connect(_on_rune_changed)
	player.rune_unlocked.connect(_on_rune_unlocked)

func build_ui():
	var layer := CanvasLayer.new()
	add_child(layer)

	var top_bg := ColorRect.new()
	top_bg.position = Vector2(12, 12)
	top_bg.size = Vector2(470, 104)
	top_bg.color = Color(0.03, 0.02, 0.06, 0.78)
	layer.add_child(top_bg)

	var title := Label.new()
	title.position = Vector2(26, 20)
	title.text = "MAGIC CAVE ESCAPE — PROTOTYPE"
	title.add_theme_font_size_override("font_size", 18)
	layer.add_child(title)

	var hp_label := Label.new()
	hp_label.position = Vector2(26, 50)
	hp_label.text = "Health"
	layer.add_child(hp_label)

	health_bar = ProgressBar.new()
	health_bar.position = Vector2(86, 50)
	health_bar.size = Vector2(150, 22)
	health_bar.min_value = 0
	health_bar.max_value = player.max_health
	health_bar.value = player.health
	health_bar.show_percentage = false
	layer.add_child(health_bar)

	rune_label = Label.new()
	rune_label.position = Vector2(255, 50)
	rune_label.text = "Rune: None"
	layer.add_child(rune_label)

	objective_label = Label.new()
	objective_label.position = Vector2(26, 79)
	objective_label.text = "Objective: Step into the portal."
	layer.add_child(objective_label)

	var controls := Label.new()
	controls.position = Vector2(18, 574)
	controls.text = "A/D Move   Space Jump   LMB Attack (hold = strong)   1-4 Runes   Q Magic   Shift Air Dash"
	controls.add_theme_color_override("font_color", Color(0.92, 0.9, 1.0))
	controls.add_theme_font_size_override("font_size", 15)
	layer.add_child(controls)

	message_label = Label.new()
	message_label.position = Vector2(390, 125)
	message_label.size = Vector2(430, 60)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 22)
	message_label.add_theme_color_override("font_color", Color(0.94, 0.78, 1.0))
	layer.add_child(message_label)

	win_panel = ColorRect.new()
	win_panel.position = Vector2(0, 0)
	win_panel.size = Vector2(1152, 648)
	win_panel.color = Color(0.025, 0.015, 0.06, 0.91)
	win_panel.visible = false
	layer.add_child(win_panel)

	var win_text := Label.new()
	win_text.position = Vector2(250, 225)
	win_text.size = Vector2(650, 200)
	win_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	win_text.text = "YOU ESCAPED THE MAGIC CAVE!\n\nPrototype Complete\n\nPress F6 / restart the scene to play again."
	win_text.add_theme_font_size_override("font_size", 30)
	win_panel.add_child(win_text)

func enter_cave():
	if cave_entered:
		return
	cave_entered = true
	canvas_modulate.color = Color(0.34, 0.28, 0.43)
	glow_sprite.active = true
	objective_label.text = "Objective: Explore the cave, collect runes, and escape."
	show_message("You wake up underground... a sprite begins to follow you.")

func activate_water(from_position: Vector2):
	if water_barrier == null or not is_instance_valid(water_barrier):
		show_message("The water rune ripples through the cave.")
		return
	if from_position.distance_to(water_altar_pos) <= 170.0:
		water_barrier.queue_free()
		water_barrier = null
		objective_label.text = "Objective: The seal is open — reach the exit portal!"
		show_message("Water Rune activated the ancient seal!")
	else:
		show_message("Water magic splashes outward. Try it near a blue altar.")

func respawn_player(body):
	body.global_position = cave_spawn if cave_entered else Vector2(120, 420)
	show_message("You were knocked out and returned to safety.")

func spawn_health(at_position: Vector2):
	var drop = health_script.new()
	drop.position = at_position + Vector2(0, -22)
	add_child(drop)

func finish_game():
	player.set_physics_process(false)
	win_panel.visible = true

func show_message(text: String):
	message_label.text = text
	var token := Time.get_ticks_msec()
	message_label.set_meta("message_token", token)
	get_tree().create_timer(2.6).timeout.connect(_clear_message.bind(token))

func _clear_message(token: int):
	if is_instance_valid(message_label) and message_label.get_meta("message_token", -1) == token:
		message_label.text = ""

func _on_health_changed(current, maximum):
	health_bar.max_value = maximum
	health_bar.value = current

func _on_rune_changed(rune_name):
	rune_label.text = "Rune: " + rune_name.capitalize()

func _on_rune_unlocked(rune_name):
	objective_label.text = "Objective: Keep exploring. Use 1-4 to switch collected runes."

func spawn_rune(kind: String, at_position: Vector2):
	var rune = rune_script.new()
	rune.setup(kind)
	rune.position = at_position
	add_child(rune)

func spawn_enemy(at_position: Vector2):
	var enemy = enemy_script.new()
	enemy.position = at_position
	add_child(enemy)

func spawn_turret(at_position: Vector2):
	var turret = turret_script.new()
	turret.position = at_position
	add_child(turret)

func make_platform(center: Vector2, size: Vector2, color: Color) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = center
	body.collision_layer = 1
	body.collision_mask = 1

	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)

	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array([
		Vector2(-size.x / 2.0, -size.y / 2.0),
		Vector2(size.x / 2.0, -size.y / 2.0),
		Vector2(size.x / 2.0, size.y / 2.0),
		Vector2(-size.x / 2.0, size.y / 2.0)
	])
	poly.color = color
	poly.z_index = -1
	body.add_child(poly)
	add_child(body)
	return body

func add_visual_rect(center: Vector2, size: Vector2, color: Color, z: int):
	var poly := Polygon2D.new()
	poly.position = center
	poly.polygon = PackedVector2Array([
		Vector2(-size.x / 2.0, -size.y / 2.0),
		Vector2(size.x / 2.0, -size.y / 2.0),
		Vector2(size.x / 2.0, size.y / 2.0),
		Vector2(-size.x / 2.0, size.y / 2.0)
	])
	poly.color = color
	poly.z_index = z
	add_child(poly)

func make_crystal(at_position: Vector2, color: Color):
	var poly := Polygon2D.new()
	poly.position = at_position
	poly.polygon = PackedVector2Array([
		Vector2(0, -44), Vector2(17, -8), Vector2(10, 18), Vector2(-11, 18), Vector2(-17, -8)
	])
	poly.color = color
	poly.z_index = 0
	add_child(poly)

func make_altar(at_position: Vector2):
	var base := Polygon2D.new()
	base.position = at_position
	base.polygon = PackedVector2Array([
		Vector2(-36, 30), Vector2(36, 30), Vector2(26, 4), Vector2(-26, 4)
	])
	base.color = Color(0.12, 0.34, 0.58)
	add_child(base)

	var gem := Polygon2D.new()
	gem.position = at_position + Vector2(0, -14)
	gem.polygon = PackedVector2Array([
		Vector2(0, -22), Vector2(17, 0), Vector2(0, 22), Vector2(-17, 0)
	])
	gem.color = Color(0.25, 0.75, 1.0)
	add_child(gem)
