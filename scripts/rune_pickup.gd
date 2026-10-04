extends Area2D

var rune_type: String = "fire"
var rune_color: Color = Color.WHITE
var bob: float = 0.0
var base_y: float = 0.0
var light: PointLight2D

func setup(kind: String) -> void:
	rune_type = kind
	if kind == "fire":
		rune_color = Color(1.0, 0.3, 0.08)
	elif kind == "water":
		rune_color = Color(0.2, 0.62, 1.0)
	elif kind == "earth":
		rune_color = Color(0.38, 0.86, 0.3)
	elif kind == "air":
		rune_color = Color(0.72, 0.92, 1.0)

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	var shape: CollisionShape2D = CollisionShape2D.new()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = 22.0
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)
	base_y = position.y
	light = PointLight2D.new()
	light.texture = make_glow_texture(64)
	light.texture_scale = 1.45
	light.energy = 0.75
	light.color = rune_color
	add_child(light)
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
	bob += delta * 2.5
	position.y = base_y + sin(bob) * 5.0
	rotation = sin(bob * 0.5) * 0.08
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("unlock_rune"):
		body.unlock_rune(rune_type)
		if get_tree().current_scene.has_method("show_rune_message"):
			get_tree().current_scene.show_rune_message(rune_type)
		queue_free()

func _draw() -> void:
	var halo: float = 22.0 + sin(bob * 1.8) * 2.0
	draw_circle(Vector2.ZERO, halo, Color(rune_color.r, rune_color.g, rune_color.b, 0.13))
	var diamond: PackedVector2Array = PackedVector2Array([
		Vector2(0.0, -16.0), Vector2(13.0, 0.0), Vector2(0.0, 16.0), Vector2(-13.0, 0.0)
	])
	draw_colored_polygon(diamond, rune_color)
	draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), Color.WHITE, 2.0)
	for i in range(3):
		var angle: float = bob * 0.55 + float(i) * TAU / 3.0
		draw_circle(Vector2(cos(angle), sin(angle)) * 26.0, 2.0, Color(rune_color.r, rune_color.g, rune_color.b, 0.8))
