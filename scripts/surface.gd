extends Node2D

var player_script: Script = preload("res://scripts/player.gd")
var portal_script: Script = preload("res://scripts/portal.gd")
var motes_script: Script = preload("res://scripts/motes.gd")

var player: Variant
var fade_rect: ColorRect
var transitioning: bool = false

func _ready() -> void:
	setup_input_actions()
	build_background()
	build_level()
	build_player()
	build_ui()
	build_fade()
	fade_in()

func setup_input_actions() -> void:
	ensure_key_action("move_left", KEY_A)
	ensure_key_action("move_right", KEY_D)
	ensure_key_action("jump", KEY_SPACE)
	ensure_mouse_action("attack", MOUSE_BUTTON_LEFT)
	ensure_key_action("magic", KEY_Q)
	ensure_key_action("dash", KEY_SHIFT)
	ensure_key_action("rune_fire", KEY_1)
	ensure_key_action("rune_water", KEY_2)
	ensure_key_action("rune_earth", KEY_3)
	ensure_key_action("rune_air", KEY_4)

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
	#  bright nature scene
	var top_color: Color = Color(0.31, 0.58, 0.86)
	var bottom_color: Color = Color(0.73, 0.88, 0.92)
	for i in range(10):
		var t: float = float(i) / 9.0
		add_visual_rect(Vector2(640.0, 36.0 + float(i) * 72.0), Vector2(1280.0, 74.0), top_color.lerp(bottom_color, t), -30)

	add_circle(Vector2(1050.0, 112.0), 50.0, Color(1.0, 0.91, 0.58, 0.82), -27)
	make_cloud(Vector2(200.0, 120.0), 1.0)
	make_cloud(Vector2(715.0, 168.0), 0.75)
	make_cloud(Vector2(1160.0, 225.0), 0.58)

	# distant rolling hills continue past both sides of the viewport.
	add_polygon(PackedVector2Array([
		Vector2(-80.0, 470.0), Vector2(0.0, 390.0), Vector2(165.0, 330.0), Vector2(350.0, 400.0),
		Vector2(545.0, 320.0), Vector2(745.0, 392.0), Vector2(955.0, 315.0), Vector2(1145.0, 378.0),
		Vector2(1360.0, 320.0), Vector2(1360.0, 590.0), Vector2(-80.0, 590.0)
	]), Color(0.19, 0.43, 0.32), -24)
	add_polygon(PackedVector2Array([
		Vector2(-80.0, 500.0), Vector2(65.0, 430.0), Vector2(240.0, 472.0), Vector2(430.0, 390.0),
		Vector2(620.0, 468.0), Vector2(835.0, 402.0), Vector2(1010.0, 470.0), Vector2(1190.0, 398.0),
		Vector2(1360.0, 452.0), Vector2(1360.0, 600.0), Vector2(-80.0, 600.0)
	]), Color(0.14, 0.34, 0.25), -22)

	var fireflies: Variant = motes_script.new()
	fireflies.position = Vector2(55.0, 270.0)
	fireflies.area_size = Vector2(1170.0, 235.0)
	fireflies.count = 24
	fireflies.tint = Color(1.0, 0.93, 0.47, 0.7)
	fireflies.radius = 1.5
	fireflies.drift = 7.0
	add_child(fireflies)

func build_level() -> void:
	# deep ground fill keeps the bottom of the larger viewport covered without changing the clearing layout.
	make_surface_platform(Vector2(640.0, 645.0), Vector2(1480.0, 170.0))
	make_invisible_wall(Vector2(-18.0, 360.0), Vector2(36.0, 780.0))
	make_invisible_wall(Vector2(1298.0, 360.0), Vector2(36.0, 780.0))

	# nature framing
	make_tree(Vector2(75.0, 563.0), 1.15)
	make_tree(Vector2(178.0, 568.0), 0.82)
	make_tree(Vector2(1080.0, 566.0), 1.05)
	make_tree(Vector2(1220.0, 568.0), 0.78)
	make_bush(Vector2(280.0, 558.0), 1.0)
	make_bush(Vector2(725.0, 560.0), 0.85)
	make_bush(Vector2(1040.0, 562.0), 0.75)
	make_bush(Vector2(1165.0, 562.0), 0.65)
	make_rock(Vector2(350.0, 562.0), 1.0)
	make_rock(Vector2(1015.0, 565.0), 0.72)
	make_flower_patch(Vector2(450.0, 565.0), Color(0.95, 0.62, 1.0))
	make_flower_patch(Vector2(635.0, 565.0), Color(1.0, 0.8, 0.38))
	make_flower_patch(Vector2(805.0, 565.0), Color(0.58, 0.82, 1.0))
	make_flower_patch(Vector2(1130.0, 565.0), Color(1.0, 0.66, 0.76))
	make_grass_tuft(Vector2(235.0, 568.0), 1.0)
	make_grass_tuft(Vector2(390.0, 568.0), 0.8)
	make_grass_tuft(Vector2(570.0, 568.0), 1.1)
	make_grass_tuft(Vector2(750.0, 568.0), 0.9)
	make_grass_tuft(Vector2(1000.0, 568.0), 1.0)
	make_grass_tuft(Vector2(1200.0, 568.0), 0.85)

	# portal clearing and surrounding rune-stones.
	for i in range(7):
		var angle: float = PI + (TAU * 0.5) * float(i) / 6.0
		var stone_pos: Vector2 = Vector2(900.0, 553.0) + Vector2(cos(angle) * 73.0, sin(angle) * 22.0)
		make_rock(stone_pos, 0.42)

	var entrance: Variant = portal_script.new()
	entrance.position = Vector2(900.0, 502.0)
	entrance.target_scene_path = "res://Underground.tscn"
	entrance.portal_color = Color(0.72, 0.32, 1.0)
	add_child(entrance)

func build_player() -> void:
	player = player_script.new()
	player.position = Vector2(145.0, 515.0)
	player.combat_enabled = false
	player.sword_visible = false
	add_child(player)

	var camera: Camera2D = Camera2D.new()
	camera.position = Vector2(0.0, -30.0)
	camera.limit_left = 0
	camera.limit_right = 1280
	camera.limit_top = 0
	camera.limit_bottom = 720
	player.add_child(camera)

func build_ui() -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	add_child(layer)

	var panel: ColorRect = ColorRect.new()
	panel.position = Vector2(18.0, 18.0)
	panel.size = Vector2(455.0, 90.0)
	panel.color = Color(0.035, 0.07, 0.09, 0.74)
	layer.add_child(panel)

	var title: Label = Label.new()
	title.position = Vector2(32.0, 27.0)
	title.text = "MAGIC CAVE ESCAPE"
	title.add_theme_font_size_override("font_size", 18)
	layer.add_child(title)

	var objective: Label = Label.new()
	objective.position = Vector2(32.0, 62.0)
	objective.text = "A strange portal is humming in the clearing..."
	objective.add_theme_font_size_override("font_size", 15)
	objective.add_theme_color_override("font_color", Color(0.88, 0.96, 0.9))
	layer.add_child(objective)

	var controls_bg: ColorRect = ColorRect.new()
	controls_bg.position = Vector2(18.0, 662.0)
	controls_bg.size = Vector2(430.0, 40.0)
	controls_bg.color = Color(0.03, 0.05, 0.07, 0.65)
	layer.add_child(controls_bg)

	var controls: Label = Label.new()
	controls.position = Vector2(30.0, 672.0)
	controls.text = "A / D  Move     Space  Jump     Enter the portal →"
	controls.add_theme_font_size_override("font_size", 14)
	layer.add_child(controls)

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
	tween.tween_property(fade_rect, "modulate:a", 0.0, 0.55)

func transition_to_scene(scene_path: String) -> void:
	if transitioning:
		return
	transitioning = true
	player.set_physics_process(false)
	var tween: Tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, 0.48)
	await tween.finished
	get_tree().change_scene_to_file(scene_path)

func make_surface_platform(center: Vector2, size: Vector2) -> void:
	var body: StaticBody2D = StaticBody2D.new()
	body.position = center
	body.collision_layer = 1
	body.collision_mask = 1
	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	var dirt: Polygon2D = Polygon2D.new()
	dirt.polygon = rect_points(size)
	dirt.color = Color(0.19, 0.23, 0.13)
	dirt.z_index = -1
	body.add_child(dirt)
	var grass: Polygon2D = Polygon2D.new()
	grass.position = Vector2(0.0, -size.y / 2.0 + 9.0)
	grass.polygon = rect_points(Vector2(size.x, 18.0))
	grass.color = Color(0.25, 0.58, 0.23)
	body.add_child(grass)
	var grass_light: Polygon2D = Polygon2D.new()
	grass_light.position = Vector2(0.0, -size.y / 2.0 + 2.5)
	grass_light.polygon = rect_points(Vector2(size.x, 5.0))
	grass_light.color = Color(0.49, 0.76, 0.33)
	body.add_child(grass_light)
	add_child(body)

func make_invisible_wall(center: Vector2, size: Vector2) -> void:
	var body: StaticBody2D = StaticBody2D.new()
	body.position = center
	body.collision_layer = 1
	body.collision_mask = 1
	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	add_child(body)

func make_tree(pos: Vector2, scale_amount: float) -> void:
	add_visual_rect(pos + Vector2(0.0, -56.0 * scale_amount), Vector2(24.0, 112.0) * scale_amount, Color(0.25, 0.16, 0.09), -4)
	add_circle(pos + Vector2(-22.0, -125.0) * scale_amount, 39.0 * scale_amount, Color(0.10, 0.34, 0.19), -3)
	add_circle(pos + Vector2(20.0, -136.0) * scale_amount, 45.0 * scale_amount, Color(0.12, 0.40, 0.22), -3)
	add_circle(pos + Vector2(2.0, -170.0) * scale_amount, 38.0 * scale_amount, Color(0.16, 0.46, 0.25), -2)
	add_circle(pos + Vector2(45.0, -106.0) * scale_amount, 32.0 * scale_amount, Color(0.11, 0.36, 0.20), -3)

func make_bush(pos: Vector2, scale_amount: float) -> void:
	add_circle(pos + Vector2(-22.0, -16.0) * scale_amount, 24.0 * scale_amount, Color(0.12, 0.39, 0.20), -1)
	add_circle(pos + Vector2(0.0, -25.0) * scale_amount, 30.0 * scale_amount, Color(0.16, 0.48, 0.24), -1)
	add_circle(pos + Vector2(27.0, -15.0) * scale_amount, 23.0 * scale_amount, Color(0.11, 0.36, 0.19), -1)
	for i in range(4):
		var berry_pos: Vector2 = pos + Vector2(-18.0 + float(i) * 13.0, -27.0 - float(i % 2) * 8.0) * scale_amount
		add_circle(berry_pos, 2.6 * scale_amount, Color(0.78, 0.48, 0.92), 0)

func make_rock(pos: Vector2, scale_amount: float) -> void:
	add_polygon(PackedVector2Array([
		pos + Vector2(-26.0, 0.0) * scale_amount,
		pos + Vector2(-18.0, -18.0) * scale_amount,
		pos + Vector2(2.0, -25.0) * scale_amount,
		pos + Vector2(24.0, -12.0) * scale_amount,
		pos + Vector2(29.0, 0.0) * scale_amount
	]), Color(0.33, 0.36, 0.34), -1)
	add_polygon(PackedVector2Array([
		pos + Vector2(-13.0, -17.0) * scale_amount,
		pos + Vector2(1.0, -22.0) * scale_amount,
		pos + Vector2(11.0, -16.0) * scale_amount,
		pos + Vector2(-2.0, -12.0) * scale_amount
	]), Color(0.48, 0.51, 0.48), 0)

func make_flower_patch(pos: Vector2, flower_color: Color) -> void:
	for i in range(3):
		var xoff: float = float(i - 1) * 18.0
		var stem: Line2D = Line2D.new()
		stem.points = PackedVector2Array([pos + Vector2(xoff, 0.0), pos + Vector2(xoff + 2.0, -18.0 - float(i % 2) * 5.0)])
		stem.width = 2.0
		stem.default_color = Color(0.28, 0.58, 0.24)
		stem.z_index = 0
		add_child(stem)
		var flower_center: Vector2 = pos + Vector2(xoff + 2.0, -20.0 - float(i % 2) * 5.0)
		for p in range(5):
			var a: float = TAU * float(p) / 5.0
			add_circle(flower_center + Vector2(cos(a), sin(a)) * 5.0, 3.1, flower_color, 1)
		add_circle(flower_center, 2.4, Color(1.0, 0.86, 0.35), 2)

func make_grass_tuft(pos: Vector2, scale_amount: float) -> void:
	for i in range(5):
		var line: Line2D = Line2D.new()
		var xoff: float = float(i - 2) * 3.0 * scale_amount
		line.points = PackedVector2Array([pos + Vector2(xoff, 0.0), pos + Vector2(xoff + float(i - 2) * 2.0, -16.0 * scale_amount - float(i % 2) * 5.0)])
		line.width = 2.0
		line.default_color = Color(0.31, 0.68, 0.27)
		line.z_index = 0
		add_child(line)

func make_cloud(pos: Vector2, scale_amount: float) -> void:
	var cloud_color: Color = Color(1.0, 1.0, 1.0, 0.58)
	add_circle(pos + Vector2(-28.0, 3.0) * scale_amount, 24.0 * scale_amount, cloud_color, -26)
	add_circle(pos + Vector2(0.0, -9.0) * scale_amount, 31.0 * scale_amount, cloud_color, -26)
	add_circle(pos + Vector2(31.0, 5.0) * scale_amount, 22.0 * scale_amount, cloud_color, -26)
	add_visual_rect(pos + Vector2(0.0, 10.0) * scale_amount, Vector2(85.0, 25.0) * scale_amount, cloud_color, -26)

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
