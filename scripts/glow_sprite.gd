extends Node2D

var target: Node2D
var light: PointLight2D
var active: bool = false
var t: float = 0.0

func _ready() -> void:
	z_index = 10
	light = PointLight2D.new()
	light.texture = make_glow_texture(128)
	light.texture_scale = 3.25
	light.energy = 1.9
	light.color = Color(0.68, 0.88, 1.0)
	light.enabled = false
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
	t += delta
	if is_instance_valid(target):
		var desired: Vector2 = target.global_position + Vector2(42.0, -48.0 + sin(t * 2.8) * 7.0)
		var follow_weight: float = 1.0 - pow(0.002, delta)
		global_position = global_position.lerp(desired, follow_weight)
	light.enabled = active
	visible = active
	queue_redraw()

func _draw() -> void:
	if not active:
		return
	var bob: float = sin(t * 3.5)
	draw_circle(Vector2.ZERO, 17.0 + bob, Color(0.5, 0.82, 1.0, 0.10))
	draw_circle(Vector2.ZERO, 11.0, Color(0.5, 0.82, 1.0, 0.16))
	# Tiny wing-like wisps.
	draw_colored_polygon(PackedVector2Array([Vector2(-5.0, 0.0), Vector2(-16.0, -5.0 + bob), Vector2(-10.0, 5.0)]), Color(0.55, 0.82, 1.0, 0.32))
	draw_colored_polygon(PackedVector2Array([Vector2(5.0, 0.0), Vector2(16.0, -5.0 - bob), Vector2(10.0, 5.0)]), Color(0.55, 0.82, 1.0, 0.32))
	draw_circle(Vector2.ZERO, 7.0, Color(0.72, 0.92, 1.0))
	draw_circle(Vector2(-2.0, -2.0), 2.0, Color.WHITE)
	for i in range(3):
		var angle: float = -t * 1.2 + float(i) * 2.1
		var spark: Vector2 = Vector2(cos(angle) * (20.0 + float(i) * 3.0), sin(angle) * 8.0)
		draw_circle(spark, 1.8, Color(0.74, 0.92, 1.0, 0.65))
