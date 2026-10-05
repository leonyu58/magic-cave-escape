extends Node2D

var player_script: Script = preload("res://scripts/player.gd")
var enemy_script: Script = preload("res://scripts/enemy.gd")
var turret_script: Script = preload("res://scripts/turret.gd")
var rune_script: Script = preload("res://scripts/rune_pickup.gd")
var health_script: Script = preload("res://scripts/health_pickup.gd")
var portal_script: Script = preload("res://scripts/portal.gd")
var glow_script: Script = preload("res://scripts/glow_sprite.gd")
var motes_script: Script = preload("res://scripts/motes.gd")
var boss_script: Script = preload("res://scripts/boss_guardian.gd")

var player: Variant
var glow_sprite: Variant
var canvas_modulate: CanvasModulate
var health_bar: ProgressBar
var rune_label: Label
var objective_label: Label
var message_label: Label
var win_panel: ColorRect
var boss_panel: ColorRect
var boss_bar: ProgressBar
var boss_label: Label
var fade_rect: ColorRect
var water_altar_pos: Vector2 = Vector2(4050.0, 425.0)
var water_barrier: StaticBody2D
var cave_spawn: Vector2 = Vector2(175.0, 410.0)
var crystal_glow_texture: Texture2D
var game_finished: bool = false
var guardian: Variant
var exit_portal: Variant
var boss_started: bool = false
var water_pool_positions: Array[Vector2] = []
var water_platform_target_y: Array[float] = []
var water_platform_widths: Array[float] = []
var active_water_platforms: Dictionary = {}
var seal_hint_shown: bool = false

func _ready() -> void:
	setup_input_actions()
	build_background()
	build_level()
	build_player()
	build_ui()
	build_fade()
	fade_in()
	show_message("The portal drops you deep underground... and a sprite finds you.")

func setup_input_actions() -> void:
	ensure_key_action("move_left", KEY_A)
	ensure_key_action("move_right", KEY_D)
	ensure_key_action("move_up", KEY_W)
	ensure_key_action("jump", KEY_SPACE)
	ensure_mouse_action("attack", MOUSE_BUTTON_LEFT)
	ensure_key_action("magic", KEY_Q)
	ensure_key_action("dash", KEY_SHIFT)
	ensure_key_action("rune_fire", KEY_1)
	ensure_key_action("rune_water", KEY_3)
	ensure_key_action("rune_earth", KEY_2)

func ensure_key_action(action_name: String, keycode: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	if not InputMap.action_get_events(action_name).is_empty():
		return
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = keycode
	InputMap.action_add_event(action_name, event)

func ensure_mouse_action(action_name: String, button_index: MouseButton) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	if not InputMap.action_get_events(action_name).is_empty():
		return
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = button_index
	InputMap.action_add_event(action_name, event)

func build_background() -> void:
	add_visual_rect(Vector2(2700.0, 260.0), Vector2(5600.0, 1600.0), Color(0.055, 0.026, 0.092), -30)

	add_polygon(PackedVector2Array([
		Vector2(-100.0, 175.0), Vector2(80.0, 110.0), Vector2(230.0, 155.0), Vector2(410.0, 92.0),
		Vector2(590.0, 165.0), Vector2(780.0, 105.0), Vector2(980.0, 158.0), Vector2(1180.0, 86.0),
		Vector2(1390.0, 160.0), Vector2(1600.0, 104.0), Vector2(1820.0, 170.0), Vector2(2050.0, 100.0),
		Vector2(2300.0, 160.0), Vector2(2550.0, 88.0), Vector2(2800.0, 160.0), Vector2(3070.0, 98.0),
		Vector2(3330.0, 155.0), Vector2(3600.0, 94.0), Vector2(3900.0, 165.0), Vector2(4200.0, 110.0),
		Vector2(4500.0, 166.0), Vector2(4800.0, 92.0), Vector2(5100.0, 154.0), Vector2(5450.0, 105.0),
		Vector2(5450.0, -200.0), Vector2(-100.0, -200.0)
	]), Color(0.085, 0.045, 0.13), -25)

	add_polygon(PackedVector2Array([
		Vector2(-100.0, 430.0), Vector2(100.0, 365.0), Vector2(300.0, 405.0), Vector2(520.0, 335.0),
		Vector2(760.0, 410.0), Vector2(1000.0, 345.0), Vector2(1230.0, 420.0), Vector2(1480.0, 350.0),
		Vector2(1720.0, 410.0), Vector2(1990.0, 350.0), Vector2(2250.0, 415.0), Vector2(2500.0, 348.0),
		Vector2(2770.0, 420.0), Vector2(3050.0, 350.0), Vector2(3350.0, 410.0), Vector2(3650.0, 344.0),
		Vector2(3950.0, 414.0), Vector2(4250.0, 350.0), Vector2(4560.0, 420.0), Vector2(4860.0, 348.0),
		Vector2(5200.0, 410.0), Vector2(5450.0, 360.0), Vector2(5450.0, 680.0), Vector2(-100.0, 680.0)
	]), Color(0.072, 0.037, 0.115), -24)

	for i in range(14):
		var x: float = 120.0 + float(i) * 405.0
		var h: float = 65.0 + float((i * 37) % 80)
		make_stalactite(Vector2(x, 0.0), h, -20)

	var motes: Variant = motes_script.new()
	motes.position = Vector2(10.0, 100.0)
	motes.area_size = Vector2(5350.0, 420.0)
	motes.count = 70
	motes.tint = Color(0.66, 0.47, 0.94, 0.42)
	motes.radius = 1.5
	motes.drift = 10.0
	add_child(motes)

	canvas_modulate = CanvasModulate.new()
	canvas_modulate.color = Color(0.43, 0.36, 0.53)
	add_child(canvas_modulate)

func build_level() -> void:
	make_platform(Vector2(300.0, 535.0), Vector2(850.0, 90.0), Color(0.17, 0.11, 0.23))
	make_platform(Vector2(1220.0, 535.0), Vector2(750.0, 90.0), Color(0.15, 0.095, 0.205))
	make_platform(Vector2(2120.0, 535.0), Vector2(880.0, 90.0), Color(0.18, 0.10, 0.245))

	make_platform(Vector2(910.0, 390.0), Vector2(170.0, 24.0), Color(0.27, 0.18, 0.35))
	make_platform(Vector2(1080.0, 290.0), Vector2(160.0, 24.0), Color(0.27, 0.18, 0.35))
	make_platform(Vector2(2300.0, 390.0), Vector2(170.0, 24.0), Color(0.27, 0.18, 0.35))
	make_platform(Vector2(2470.0, 315.0), Vector2(150.0, 24.0), Color(0.23, 0.16, 0.32))

	make_platform(Vector2(2700.0, 535.0), Vector2(180.0, 90.0), Color(0.15, 0.09, 0.22))
	make_platform(Vector2(3220.0, 535.0), Vector2(160.0, 90.0), Color(0.15, 0.09, 0.22))
	make_platform(Vector2(3740.0, 535.0), Vector2(170.0, 90.0), Color(0.16, 0.095, 0.23))
	make_platform(Vector2(4050.0, 535.0), Vector2(300.0, 90.0), Color(0.16, 0.095, 0.23))
	make_platform(Vector2(3665.0, 345.0), Vector2(180.0, 24.0), Color(0.25, 0.18, 0.35))

	make_platform(Vector2(3475.0, 50.0), Vector2(1750.0, 340.0), Color(0.115, 0.065, 0.17))
	make_stalactite(Vector2(2760.0, 220.0), 56.0, -1)
	make_stalactite(Vector2(3150.0, 220.0), 72.0, -1)
	make_stalactite(Vector2(3540.0, 220.0), 48.0, -1)
	make_stalactite(Vector2(3930.0, 220.0), 66.0, -1)
	make_stalactite(Vector2(4260.0, 220.0), 52.0, -1)

	make_platform(Vector2(4680.0, 535.0), Vector2(1000.0, 90.0), Color(0.155, 0.09, 0.215))

	var arrival_portal: Variant = portal_script.new()
	arrival_portal.position = Vector2(90.0, 440.0)
	arrival_portal.decorative_only = true
	arrival_portal.portal_color = Color(0.64, 0.30, 1.0)
	add_child(arrival_portal)

	add_visual_rect(Vector2(90.0, 325.0), Vector2(125.0, 15.0), Color(0.20, 0.12, 0.29), -1)
	make_crystal_cluster(Vector2(90.0, 300.0), Color(0.65, 0.25, 0.95))

	make_crystal_cluster(Vector2(560.0, 470.0), Color(0.20, 0.85, 1.0))
	make_crystal_cluster(Vector2(1360.0, 470.0), Color(0.90, 0.30, 0.80))
	make_crystal_cluster(Vector2(1980.0, 470.0), Color(0.40, 0.95, 0.65))
	make_crystal_cluster(Vector2(2700.0, 470.0), Color(0.24, 0.72, 1.0))
	make_crystal_cluster(Vector2(3200.0, 470.0), Color(0.20, 0.84, 1.0))
	make_crystal_cluster(Vector2(3750.0, 470.0), Color(0.30, 0.70, 1.0))
	make_crystal_cluster(Vector2(4500.0, 468.0), Color(0.42, 0.72, 1.0))
	make_crystal_cluster(Vector2(4880.0, 468.0), Color(0.72, 0.32, 1.0))

	make_mushroom_patch(Vector2(450.0, 489.0), Color(0.72, 0.38, 1.0))
	make_mushroom_patch(Vector2(1500.0, 489.0), Color(0.24, 0.76, 1.0))
	make_mushroom_patch(Vector2(2180.0, 489.0), Color(0.47, 1.0, 0.67))
	make_mushroom_patch(Vector2(2760.0, 489.0), Color(0.28, 0.78, 1.0))
	make_mushroom_patch(Vector2(3780.0, 489.0), Color(0.36, 0.82, 1.0))
	make_mushroom_patch(Vector2(5000.0, 489.0), Color(0.92, 0.40, 1.0))
	make_small_rocks(Vector2(700.0, 490.0))
	make_small_rocks(Vector2(1730.0, 490.0))
	make_small_rocks(Vector2(3220.0, 490.0))
	make_small_rocks(Vector2(4070.0, 490.0))

	spawn_rune("fire", Vector2(340.0, 455.0))
	spawn_rune("air", Vector2(970.0, 335.0))
	spawn_rune("earth", Vector2(1820.0, 455.0))
	spawn_rune("water", Vector2(2470.0, 265.0))

	spawn_enemy(Vector2(550.0, 460.0))
	spawn_enemy(Vector2(1480.0, 460.0))
	spawn_enemy(Vector2(2020.0, 460.0))
	spawn_turret(Vector2(2260.0, 462.0))

	register_water_pool(Vector2(2965.0, 565.0), 501.0, 330.0)
	register_water_pool(Vector2(3478.0, 565.0), 420.0, 340.0)

	make_altar(water_altar_pos)
	water_barrier = make_magic_barrier(Vector2(4200.0, 365.0), Vector2(44.0, 340.0))
	make_seal_hint_trigger(Vector2(3995.0, 420.0), Vector2(260.0, 240.0))

	add_visual_rect(Vector2(4650.0, 334.0), Vector2(520.0, 10.0), Color(0.16, 0.09, 0.25), -2)
	guardian = boss_script.new()
	guardian.position = Vector2(4650.0, 430.0)
	add_child(guardian)
	guardian.health_changed.connect(_on_boss_health_changed)
	guardian.defeated.connect(_on_boss_defeated)

	exit_portal = portal_script.new()
	exit_portal.position = Vector2(5100.0, 440.0)
	exit_portal.is_exit = true
	exit_portal.active = false
	exit_portal.portal_color = Color(0.38, 0.86, 1.0)
	add_child(exit_portal)

func build_player() -> void:
	player = player_script.new()
	player.position = cave_spawn
	player.combat_enabled = true
	player.sword_visible = true
	add_child(player)

	var camera: Camera2D = Camera2D.new()
	camera.position = Vector2(90.0, -55.0)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.0
	camera.limit_left = 0
	camera.limit_right = 5400
	camera.limit_top = -250
	camera.limit_bottom = 900
	player.add_child(camera)

	glow_sprite = glow_script.new()
	glow_sprite.target = player
	glow_sprite.active = true
	glow_sprite.global_position = player.global_position + Vector2(42.0, -48.0)
	add_child(glow_sprite)

	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.target = player
	if is_instance_valid(guardian):
		guardian.target = player

	player.health_changed.connect(_on_health_changed)
	player.rune_changed.connect(_on_rune_changed)
	player.rune_unlocked.connect(_on_rune_unlocked)

func build_ui() -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	add_child(layer)

	var top_bg: ColorRect = ColorRect.new()
	top_bg.position = Vector2(16.0, 14.0)
	top_bg.size = Vector2(520.0, 102.0)
	top_bg.color = Color(0.025, 0.015, 0.055, 0.80)
	layer.add_child(top_bg)

	var accent: ColorRect = ColorRect.new()
	accent.position = Vector2(16.0, 14.0)
	accent.size = Vector2(5.0, 102.0)
	accent.color = Color(0.58, 0.35, 0.88, 0.9)
	layer.add_child(accent)

	var title: Label = Label.new()
	title.position = Vector2(32.0, 22.0)
	title.text = "MAGIC CAVE ESCAPE — UNDERGROUND"
	title.add_theme_font_size_override("font_size", 17)
	layer.add_child(title)

	var hp_label: Label = Label.new()
	hp_label.position = Vector2(32.0, 52.0)
	hp_label.text = "Health"
	hp_label.add_theme_font_size_override("font_size", 14)
	layer.add_child(hp_label)

	health_bar = ProgressBar.new()
	health_bar.position = Vector2(92.0, 53.0)
	health_bar.size = Vector2(148.0, 19.0)
	health_bar.min_value = 0.0
	health_bar.max_value = float(player.max_health)
	health_bar.value = float(player.health)
	health_bar.show_percentage = false
	var hp_bg: StyleBoxFlat = StyleBoxFlat.new()
	hp_bg.bg_color = Color(0.12, 0.08, 0.16, 0.95)
	hp_bg.corner_radius_top_left = 7
	hp_bg.corner_radius_top_right = 7
	hp_bg.corner_radius_bottom_left = 7
	hp_bg.corner_radius_bottom_right = 7
	health_bar.add_theme_stylebox_override("background", hp_bg)
	var hp_fill: StyleBoxFlat = StyleBoxFlat.new()
	hp_fill.bg_color = Color(0.88, 0.28, 0.58, 0.95)
	hp_fill.corner_radius_top_left = 7
	hp_fill.corner_radius_top_right = 7
	hp_fill.corner_radius_bottom_left = 7
	hp_fill.corner_radius_bottom_right = 7
	health_bar.add_theme_stylebox_override("fill", hp_fill)
	layer.add_child(health_bar)

	rune_label = Label.new()
	rune_label.position = Vector2(260.0, 51.0)
	rune_label.text = "Rune: None"
	rune_label.add_theme_font_size_override("font_size", 15)
	layer.add_child(rune_label)

	objective_label = Label.new()
	objective_label.position = Vector2(32.0, 82.0)
	objective_label.text = "Objective: Explore, collect the runes, and find an escape."
	objective_label.add_theme_font_size_override("font_size", 14)
	objective_label.add_theme_color_override("font_color", Color(0.85, 0.81, 0.96))
	layer.add_child(objective_label)

	var controls_bg: ColorRect = ColorRect.new()
	controls_bg.position = Vector2(15.0, 662.0)
	controls_bg.size = Vector2(1250.0, 42.0)
	controls_bg.color = Color(0.025, 0.015, 0.055, 0.74)
	layer.add_child(controls_bg)

	var controls: Label = Label.new()
	controls.position = Vector2(29.0, 673.0)
	controls.text = "A/D Move  •  Space Jump  •  LMB Sword  •  Wheel / 1–3 Switch Rune  •  Q Magic  •  Shift Air Dash  •  Midair W Updraft"
	controls.add_theme_color_override("font_color", Color(0.90, 0.87, 0.98))
	controls.add_theme_font_size_override("font_size", 14)
	layer.add_child(controls)

	message_label = Label.new()
	message_label.position = Vector2(200.0, 126.0)
	message_label.size = Vector2(880.0, 88.0)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.add_theme_font_size_override("font_size", 21)
	message_label.add_theme_color_override("font_color", Color(0.94, 0.78, 1.0))
	layer.add_child(message_label)

	win_panel = ColorRect.new()
	win_panel.position = Vector2.ZERO
	win_panel.size = Vector2(1280.0, 720.0)
	win_panel.color = Color(0.018, 0.01, 0.045, 0.94)
	win_panel.visible = false
	layer.add_child(win_panel)

	var win_glow: ColorRect = ColorRect.new()
	win_glow.position = Vector2(280.0, 195.0)
	win_glow.size = Vector2(720.0, 310.0)
	win_glow.color = Color(0.20, 0.10, 0.34, 0.78)
	win_panel.add_child(win_glow)

	var win_text: Label = Label.new()
	win_text.position = Vector2(200.0, 230.0)
	win_text.size = Vector2(880.0, 150.0)
	win_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	win_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	win_text.text = "YOU ESCAPED!\n\nThe surface light is waiting beyond the portal."
	win_text.add_theme_font_size_override("font_size", 28)
	win_panel.add_child(win_text)

	var restart_button: Button = Button.new()
	restart_button.position = Vector2(540.0, 410.0)
	restart_button.size = Vector2(200.0, 48.0)
	restart_button.text = "Play Again"
	restart_button.add_theme_font_size_override("font_size", 18)
	restart_button.pressed.connect(_restart_game)
	win_panel.add_child(restart_button)

	boss_panel = ColorRect.new()
	boss_panel.position = Vector2(770.0, 18.0)
	boss_panel.size = Vector2(494.0, 78.0)
	boss_panel.color = Color(0.055, 0.02, 0.09, 0.88)
	boss_panel.visible = false
	layer.add_child(boss_panel)

	boss_label = Label.new()
	boss_label.position = Vector2(0.0, 8.0)
	boss_label.size = Vector2(494.0, 26.0)
	boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_label.text = "ANCIENT CRYSTAL GUARDIAN"
	boss_label.add_theme_font_size_override("font_size", 16)
	boss_label.add_theme_color_override("font_color", Color(0.82, 0.68, 1.0))
	boss_panel.add_child(boss_label)

	boss_bar = ProgressBar.new()
	boss_bar.position = Vector2(24.0, 41.0)
	boss_bar.size = Vector2(446.0, 20.0)
	boss_bar.min_value = 0.0
	boss_bar.max_value = 20.0
	boss_bar.value = 20.0
	boss_bar.show_percentage = false
	var boss_bg: StyleBoxFlat = StyleBoxFlat.new()
	boss_bg.bg_color = Color(0.10, 0.05, 0.14, 0.95)
	boss_bg.corner_radius_top_left = 7
	boss_bg.corner_radius_top_right = 7
	boss_bg.corner_radius_bottom_left = 7
	boss_bg.corner_radius_bottom_right = 7
	boss_bar.add_theme_stylebox_override("background", boss_bg)
	var boss_fill: StyleBoxFlat = StyleBoxFlat.new()
	boss_fill.bg_color = Color(0.52, 0.35, 0.92, 0.96)
	boss_fill.corner_radius_top_left = 7
	boss_fill.corner_radius_top_right = 7
	boss_fill.corner_radius_bottom_left = 7
	boss_fill.corner_radius_bottom_right = 7
	boss_bar.add_theme_stylebox_override("fill", boss_fill)
	boss_panel.add_child(boss_bar)

func build_fade() -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	fade_rect = ColorRect.new()
	fade_rect.position = Vector2.ZERO
	fade_rect.size = Vector2(1280.0, 720.0)
	fade_rect.color = Color.BLACK
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(fade_rect)

func fade_in() -> void:
	fade_rect.modulate.a = 1.0
	var tween: Tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, 0.65)

func activate_water(from_position: Vector2) -> void:
	if water_barrier != null and is_instance_valid(water_barrier) and from_position.distance_to(water_altar_pos) <= 185.0:
		water_barrier.queue_free()
		water_barrier = null
		cave_spawn = Vector2(4320.0, 455.0)
		objective_label.text = "Objective: The seal is open — defeat the Ancient Crystal Guardian."
		show_message("Water floods the ancient channels. The seal breaks... and something awakens beyond it.", 4.3)
		start_boss_encounter()
		return

	var closest_index: int = -1
	var closest_distance: float = 99999.0
	for i in range(water_pool_positions.size()):
		var pool_pos: Vector2 = water_pool_positions[i]
		var distance: float = from_position.distance_to(pool_pos)
		if distance < closest_distance:
			closest_distance = distance
			closest_index = i

	if closest_index >= 0 and closest_distance <= 340.0:
		raise_water_platform(closest_index)
		return

	if water_barrier == null or not is_instance_valid(water_barrier):
		show_message("The Water Rune ripples through the cavern air.")
	else:
		show_message("Water gathers at your fingertips. Look for glowing pools or ancient channels nearby.")

func register_water_pool(pool_position: Vector2, target_y: float, platform_width: float) -> void:
	water_pool_positions.append(pool_position)
	water_platform_target_y.append(target_y)
	water_platform_widths.append(platform_width)

	var pool_visual_width: float = platform_width + 20
	var pool_top_y: float = 490.0
	var pool_bottom_y: float = 735.0
	var pool_depth: float = pool_bottom_y - pool_top_y
	add_visual_rect(
		Vector2(pool_position.x, pool_top_y + pool_depth / 2.0),
		Vector2(pool_visual_width, pool_depth),
		Color(0.055, 0.30, 0.58, 0.58),
		-2
	)
	add_visual_rect(
		Vector2(pool_position.x, pool_top_y + 3.0),
		Vector2(pool_visual_width, 6.0),
		Color(0.35, 0.88, 1.0, 0.82),
		-1
	)
	for i in range(7):
		var bubble_x: float = -platform_width * 0.40 + float(i) * (platform_width * 0.13)
		var bubble_y: float = pool_top_y + 18.0 + float(i % 3) * 11.0
		add_circle(Vector2(pool_position.x + bubble_x, bubble_y), 3.0 + float(i % 2), Color(0.55, 0.92, 1.0, 0.58), 0)

	if crystal_glow_texture == null:
		crystal_glow_texture = make_glow_texture(64)
	var light: PointLight2D = PointLight2D.new()
	light.position = Vector2(pool_position.x, pool_top_y + 8.0)
	light.texture = crystal_glow_texture
	light.texture_scale = 2.0
	light.energy = 0.38
	light.color = Color(0.24, 0.72, 1.0)
	add_child(light)

func raise_water_platform(index: int) -> void:
	var existing: Variant = active_water_platforms.get(index, null)
	if is_instance_valid(existing):
		show_message("The current is already holding a path.", 1.8)
		return

	var platform_width: float = water_platform_widths[index]
	var platform: StaticBody2D = make_water_platform_body(platform_width)
	platform.position = Vector2(water_pool_positions[index].x, water_pool_positions[index].y + 20.0)
	add_child(platform)
	active_water_platforms[index] = platform

	var target_y: float = water_platform_target_y[index]
	var rise_height: float = water_pool_positions[index].y - target_y
	if rise_height > 90.0:
		var water_column: Polygon2D = Polygon2D.new()
		water_column.position = Vector2(0.0, rise_height / 2.0 + 10.0)
		water_column.polygon = rect_points(Vector2(platform_width * 0.58, rise_height))
		water_column.color = Color(0.12, 0.55, 0.92, 0.30)
		water_column.z_index = -1
		platform.add_child(water_column)

	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(platform, "position:y", target_y, 0.38)
	show_message("The Water Rune pulls a path from the glowing pool.", 2.4)
	get_tree().create_timer(7.0).timeout.connect(lower_water_platform.bind(index, platform))

func lower_water_platform(index: int, platform: StaticBody2D) -> void:
	if not is_instance_valid(platform):
		return
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(platform, "position:y", water_pool_positions[index].y + 26.0, 0.48)
	await tween.finished
	var current: Variant = active_water_platforms.get(index, null)
	if current == platform:
		active_water_platforms.erase(index)
	if is_instance_valid(platform):
		platform.queue_free()

func make_water_platform_body(platform_width: float) -> StaticBody2D:
	var body: StaticBody2D = StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 1
	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(platform_width, 22.0)
	collision.shape = shape
	body.add_child(collision)

	var water: Polygon2D = Polygon2D.new()
	water.polygon = rect_points(Vector2(platform_width, 22.0))
	water.color = Color(0.18, 0.68, 1.0, 0.72)
	body.add_child(water)

	var surface: Line2D = Line2D.new()
	surface.points = PackedVector2Array([Vector2(-platform_width / 2.0, -10.0), Vector2(platform_width / 2.0, -10.0)])
	surface.width = 4.0
	surface.default_color = Color(0.65, 0.95, 1.0, 0.92)
	body.add_child(surface)

	for i in range(4):
		var bubble: Polygon2D = Polygon2D.new()
		bubble.position = Vector2(-platform_width * 0.3 + float(i) * platform_width * 0.2, 2.0 + float(i % 2) * 5.0)
		var bubble_points: PackedVector2Array = PackedVector2Array()
		for p in range(12):
			var angle: float = TAU * float(p) / 12.0
			bubble_points.append(Vector2(cos(angle), sin(angle)) * 3.0)
		bubble.polygon = bubble_points
		bubble.color = Color(0.78, 0.97, 1.0, 0.72)
		body.add_child(bubble)
	return body

func make_seal_hint_trigger(center: Vector2, size: Vector2) -> void:
	var area: Area2D = Area2D.new()
	area.position = center
	area.collision_layer = 0
	area.collision_mask = 1
	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	area.add_child(collision)
	area.body_entered.connect(_on_seal_hint_entered)
	add_child(area)

func _on_seal_hint_entered(body: Node2D) -> void:
	if seal_hint_shown or water_barrier == null or not is_instance_valid(water_barrier):
		return
	if not body.is_in_group("player"):
		return
	seal_hint_shown = true
	objective_label.text = "Objective: Discover what vital force can break the ancient seal."
	show_message("A vital force of life is required to unseal this ancient force.", 4.6)

func respawn_player(body: Node2D) -> void:
	body.global_position = cave_spawn
	if body is CharacterBody2D:
		var character: CharacterBody2D = body as CharacterBody2D
		character.velocity = Vector2.ZERO
	show_message("You were knocked out and returned to the last safe point.")

func spawn_health(at_position: Vector2) -> void:
	var drop: Variant = health_script.new()
	drop.position = at_position + Vector2(0.0, -22.0)
	add_child(drop)

func finish_game() -> void:
	if game_finished:
		return
	game_finished = true
	player.set_physics_process(false)
	win_panel.visible = true

func _restart_game() -> void:
	get_tree().change_scene_to_file("res://Surface.tscn")


func show_rune_message(rune_name: String) -> void:
	var text: String = ""
	if rune_name == "fire":
		text = "Heat coils around your hands. The Fire Rune answers your call. Press Q to cast flame."
	elif rune_name == "water":
		text = "A quiet current gathers at your fingertips. Water can shape the cave itself. Press Q near glowing pools to raise temporary paths."
	elif rune_name == "earth":
		text = "Stone steadies your body. The Earth Rune can shield you from harm. Press Q to guard yourself."
	elif rune_name == "air":
		text = "You feel the winds rush into you and hold their place. Air is now passive: Shift to dash, then press W once while airborne to updraft."
	else:
		text = rune_name.capitalize() + " Rune acquired!"
	show_message(text, 4.8)

func show_message(text: String, duration: float = 2.6) -> void:
	if not is_instance_valid(message_label):
		return
	message_label.text = text
	var token: int = Time.get_ticks_msec()
	message_label.set_meta("message_token", token)
	get_tree().create_timer(duration).timeout.connect(_clear_message.bind(token))

func _clear_message(token: int) -> void:
	if is_instance_valid(message_label) and int(message_label.get_meta("message_token", -1)) == token:
		message_label.text = ""

func _on_health_changed(current: int, maximum: int) -> void:
	health_bar.max_value = float(maximum)
	health_bar.value = float(current)

func _on_rune_changed(rune_name: String) -> void:
	rune_label.text = "Rune: " + rune_name.capitalize()
	var rune_color: Color = Color(0.88, 0.84, 0.94)
	if rune_name == "fire":
		rune_color = Color(1.0, 0.45, 0.24)
	elif rune_name == "water":
		rune_color = Color(0.38, 0.75, 1.0)
	elif rune_name == "earth":
		rune_color = Color(0.54, 0.94, 0.43)
	rune_label.add_theme_color_override("font_color", rune_color)

func _on_rune_unlocked(rune_name: String) -> void:
	if rune_name == "water":
		objective_label.text = "Objective: Use Water near glowing pools to shape a path through the flooded gallery."
	elif rune_name == "air":
		objective_label.text = "Objective: Air is passive — Shift to dash, press W once in midair to updraft."
	else:
		objective_label.text = "Objective: Keep exploring. Scroll or use 1–3 to switch collected runes."

func start_boss_encounter() -> void:
	if boss_started or not is_instance_valid(guardian):
		return
	boss_started = true
	guardian.target = player
	guardian.activate()
	boss_panel.visible = true
	boss_bar.max_value = float(guardian.max_health)
	boss_bar.value = float(guardian.health)

func _on_boss_health_changed(current: int, maximum: int) -> void:
	if not is_instance_valid(boss_bar):
		return
	boss_bar.max_value = float(maximum)
	boss_bar.value = float(current)

func _on_boss_defeated() -> void:
	if is_instance_valid(boss_panel):
		boss_panel.visible = false
	objective_label.text = "Objective: The Guardian has fallen — the exit portal has awakened!"
	show_message("The Guardian shatters. Its magic pours into the portal — escape!", 4.0)
	if is_instance_valid(exit_portal):
		exit_portal.set_active(true)

func spawn_rune(kind: String, at_position: Vector2) -> void:
	var rune: Variant = rune_script.new()
	rune.setup(kind)
	rune.position = at_position
	add_child(rune)

func spawn_enemy(at_position: Vector2) -> void:
	var enemy: Variant = enemy_script.new()
	enemy.position = at_position
	add_child(enemy)

func spawn_turret(at_position: Vector2) -> void:
	var turret: Variant = turret_script.new()
	turret.position = at_position
	add_child(turret)

func make_platform(center: Vector2, size: Vector2, color: Color) -> StaticBody2D:
	var body: StaticBody2D = StaticBody2D.new()
	body.position = center
	body.collision_layer = 1
	body.collision_mask = 1
	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)

	var base: Polygon2D = Polygon2D.new()
	base.polygon = rect_points(size)
	base.color = color
	base.z_index = -1
	body.add_child(base)

	var cap_points: PackedVector2Array = PackedVector2Array()
	var left: float = -size.x / 2.0
	var right: float = size.x / 2.0
	cap_points.append(Vector2(left, -size.y / 2.0 + 12.0))
	cap_points.append(Vector2(left, -size.y / 2.0 + 2.0))
	var segments: int = maxi(4, int(size.x / 90.0))
	for i in range(segments + 1):
		var px: float = lerpf(left, right, float(i) / float(segments))
		var py: float = -size.y / 2.0 + (2.0 if i % 2 == 0 else 7.0)
		cap_points.append(Vector2(px, py))
	cap_points.append(Vector2(right, -size.y / 2.0 + 12.0))
	var cap: Polygon2D = Polygon2D.new()
	cap.polygon = cap_points
	cap.color = color.lightened(0.19)
	body.add_child(cap)

	add_child(body)
	return body

func make_magic_barrier(center: Vector2, size: Vector2) -> StaticBody2D:
	var body: StaticBody2D = StaticBody2D.new()
	body.position = center
	body.collision_layer = 1
	body.collision_mask = 1
	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	var barrier: Polygon2D = Polygon2D.new()
	barrier.polygon = rect_points(size)
	barrier.color = Color(0.16, 0.60, 0.90, 0.34)
	body.add_child(barrier)
	for i in range(7):
		var line: Line2D = Line2D.new()
		var y: float = -size.y / 2.0 + 25.0 + float(i) * 48.0
		line.points = PackedVector2Array([Vector2(-size.x / 2.0 - 5.0, y), Vector2(size.x / 2.0 + 5.0, y + 12.0)])
		line.width = 3.0
		line.default_color = Color(0.35, 0.82, 1.0, 0.74)
		body.add_child(line)
	add_child(body)
	return body

func make_crystal_cluster(at_position: Vector2, color: Color) -> void:
	make_crystal(at_position, color, 1.0)
	make_crystal(at_position + Vector2(-24.0, 9.0), color.darkened(0.10), 0.62)
	make_crystal(at_position + Vector2(22.0, 12.0), color.lightened(0.12), 0.48)
	if crystal_glow_texture == null:
		crystal_glow_texture = make_glow_texture(64)
	var light: PointLight2D = PointLight2D.new()
	light.position = at_position + Vector2(0.0, -12.0)
	light.texture = crystal_glow_texture
	light.texture_scale = 1.7
	light.energy = 0.55
	light.color = color
	add_child(light)

func make_crystal(at_position: Vector2, color: Color, scale_amount: float) -> void:
	var poly: Polygon2D = Polygon2D.new()
	poly.position = at_position
	poly.polygon = PackedVector2Array([
		Vector2(0.0, -44.0) * scale_amount,
		Vector2(17.0, -8.0) * scale_amount,
		Vector2(10.0, 18.0) * scale_amount,
		Vector2(-11.0, 18.0) * scale_amount,
		Vector2(-17.0, -8.0) * scale_amount
	])
	poly.color = color
	poly.z_index = 0
	add_child(poly)
	var shine: Line2D = Line2D.new()
	shine.points = PackedVector2Array([at_position + Vector2(-3.0, -31.0) * scale_amount, at_position + Vector2(-8.0, -7.0) * scale_amount])
	shine.width = 2.0
	shine.default_color = Color(1.0, 1.0, 1.0, 0.48)
	add_child(shine)

func make_mushroom_patch(pos: Vector2, color: Color) -> void:
	for i in range(3):
		var xoff: float = float(i - 1) * 19.0
		var height: float = 15.0 + float(i % 2) * 7.0
		add_visual_rect(pos + Vector2(xoff, -height / 2.0), Vector2(4.0, height), Color(0.64, 0.56, 0.72), 0)
		add_circle(pos + Vector2(xoff, -height - 2.0), 8.0 - float(i) * 0.8, Color(color.r, color.g, color.b, 0.88), 1)
		add_circle(pos + Vector2(xoff - 2.0, -height - 4.0), 2.0, Color(1.0, 1.0, 1.0, 0.65), 2)

func make_small_rocks(pos: Vector2) -> void:
	for i in range(3):
		var xoff: float = float(i - 1) * 18.0
		add_polygon(PackedVector2Array([
			pos + Vector2(xoff - 10.0, 0.0),
			pos + Vector2(xoff - 6.0, -10.0 - float(i) * 2.0),
			pos + Vector2(xoff + 4.0, -14.0 + float(i) * 2.0),
			pos + Vector2(xoff + 10.0, 0.0)
		]), Color(0.25, 0.18, 0.31), -1)

func make_altar(at_position: Vector2) -> void:
	var base: Polygon2D = Polygon2D.new()
	base.position = at_position
	base.polygon = PackedVector2Array([
		Vector2(-40.0, 30.0), Vector2(40.0, 30.0), Vector2(29.0, 3.0), Vector2(-29.0, 3.0)
	])
	base.color = Color(0.10, 0.28, 0.49)
	add_child(base)
	var gem: Polygon2D = Polygon2D.new()
	gem.position = at_position + Vector2(0.0, -14.0)
	gem.polygon = PackedVector2Array([
		Vector2(0.0, -24.0), Vector2(18.0, 0.0), Vector2(0.0, 24.0), Vector2(-18.0, 0.0)
	])
	gem.color = Color(0.25, 0.75, 1.0)
	add_child(gem)
	if crystal_glow_texture == null:
		crystal_glow_texture = make_glow_texture(64)
	var light: PointLight2D = PointLight2D.new()
	light.position = at_position + Vector2(0.0, -15.0)
	light.texture = crystal_glow_texture
	light.texture_scale = 1.7
	light.energy = 0.7
	light.color = Color(0.2, 0.7, 1.0)
	add_child(light)

func make_stalactite(pos: Vector2, height: float, z: int) -> void:
	add_polygon(PackedVector2Array([
		pos + Vector2(-24.0, 0.0), pos + Vector2(25.0, 0.0), pos + Vector2(7.0, height * 0.72), pos + Vector2(0.0, height)
	]), Color(0.12, 0.065, 0.17), z)

func make_glow_texture(size: int) -> Texture2D:
	var image: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center: Vector2 = Vector2(float(size) / 2.0, float(size) / 2.0)
	var radius: float = float(size) / 2.0
	for y in range(size):
		for x in range(size):
			var dist: float = Vector2(float(x), float(y)).distance_to(center) / radius
			var alpha: float = clampf(1.0 - dist, 0.0, 1.0)
			alpha *= alpha
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	return ImageTexture.create_from_image(image)

func add_visual_rect(center: Vector2, size: Vector2, color: Color, z: int) -> void:
	var poly: Polygon2D = Polygon2D.new()
	poly.position = center
	poly.polygon = rect_points(size)
	poly.color = color
	poly.z_index = z
	add_child(poly)

func add_circle(center: Vector2, radius: float, color: Color, z: int) -> void:
	var poly: Polygon2D = Polygon2D.new()
	poly.position = center
	var points: PackedVector2Array = PackedVector2Array()
	for i in range(24):
		var angle: float = TAU * float(i) / 24.0
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	poly.polygon = points
	poly.color = color
	poly.z_index = z
	add_child(poly)

func add_polygon(points: PackedVector2Array, color: Color, z: int) -> void:
	var poly: Polygon2D = Polygon2D.new()
	poly.polygon = points
	poly.color = color
	poly.z_index = z
	add_child(poly)

func rect_points(size: Vector2) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(-size.x / 2.0, -size.y / 2.0),
		Vector2(size.x / 2.0, -size.y / 2.0),
		Vector2(size.x / 2.0, size.y / 2.0),
		Vector2(-size.x / 2.0, size.y / 2.0)
	])
