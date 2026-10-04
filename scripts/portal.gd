extends Area2D

var destination: Vector2 = Vector2.ZERO
var target_scene_path: String = ""
var is_exit: bool = false
var decorative_only: bool = false
var portal_color: Color = Color(0.72, 0.34, 1.0)
var pulse: float = 0.0
var transition_locked: bool = false
var active: bool = true
var portal_light: PointLight2D

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(54.0, 94.0)
	shape.shape = rect
	add_child(shape)
	body_entered.connect(_on_body_entered)
	portal_light = PointLight2D.new()
	portal_light.texture = make_glow_texture(64)
	portal_light.texture_scale = 2.4
	portal_light.energy = 0.75 if active else 0.12
	portal_light.color = portal_color if active else Color(0.34, 0.38, 0.48)
	add_child(portal_light)
	queue_redraw()

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

func _process(delta: float) -> void:
	pulse += delta
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if not active or decorative_only or transition_locked or not body.is_in_group("player"):
		return
	transition_locked = true
	set_deferred("monitoring", false)
	if is_exit:
		if get_tree().current_scene.has_method("finish_game"):
			get_tree().current_scene.finish_game()
		return
	if not target_scene_path.is_empty():
		if get_tree().current_scene.has_method("transition_to_scene"):
			get_tree().current_scene.transition_to_scene(target_scene_path)
		else:
			get_tree().change_scene_to_file(target_scene_path)
		return
	body.global_position = destination
	if body is CharacterBody2D:
		var character: CharacterBody2D = body as CharacterBody2D
		character.velocity = Vector2.ZERO

func set_active(value: bool) -> void:
	active = value
	transition_locked = false
	if is_instance_valid(portal_light):
		portal_light.energy = 0.75 if active else 0.12
		portal_light.color = portal_color if active else Color(0.34, 0.38, 0.48)
	queue_redraw()

func _draw() -> void:
	var shown_color: Color = portal_color if active else Color(0.32, 0.34, 0.44)
	var pulse_alpha: float = (0.26 + sin(pulse * 3.0) * 0.07) if active else 0.10
	var outer: Color = Color(shown_color.r, shown_color.g, shown_color.b, pulse_alpha)
	var rim: Color = shown_color.lightened(0.24)
	var inner: Color = shown_color.darkened(0.72)
	draw_circle(Vector2.ZERO, 47.0 + sin(pulse * 2.2) * 2.0, outer)
	draw_arc(Vector2.ZERO, 32.0, 0.0, TAU, 48, rim, 7.0)
	draw_arc(Vector2.ZERO, 24.0, 0.0, TAU, 40, Color(rim.r, rim.g, rim.b, 0.58), 3.0)
	draw_circle(Vector2.ZERO, 21.0, Color(inner.r, inner.g, inner.b, 0.94))
	for i in range(7):
		var angle: float = pulse * (0.7 + float(i) * 0.03) + TAU * float(i) / 7.0
		var orbit: float = 39.0 + sin(pulse * 1.4 + float(i)) * 4.0
		var dot_pos: Vector2 = Vector2(cos(angle), sin(angle)) * orbit
		draw_circle(dot_pos, 2.5 + float(i % 2), Color(rim.r, rim.g, rim.b, 0.82))
