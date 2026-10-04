extends Node2D

var direction: int = 1
var speed: float = 480.0
var lifetime: float = 1.6
var anim_time: float = 0.0

func _ready() -> void:
	z_index = 6
	queue_redraw()

func _process(delta: float) -> void:
	anim_time += delta
	position.x += float(direction) * speed * delta
	lifetime -= delta
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or not enemy.has_method("take_damage"):
			continue

		var hit_radius: float = 28.0

		if enemy.is_in_group("boss"):
			hit_radius = 75.0

		if global_position.distance_to(enemy.global_position) < hit_radius:
			enemy.take_damage(2)
			queue_free()
			return
	if lifetime <= 0.0:
		queue_free()
	queue_redraw()

func _draw() -> void:
	for i in range(3):
		var trail_x: float = -float(direction) * (10.0 + float(i) * 8.0)
		draw_circle(Vector2(trail_x, 0.0), 7.0 - float(i) * 1.4, Color(1.0, 0.28, 0.06, 0.18 - float(i) * 0.035))
	draw_circle(Vector2.ZERO, 11.0 + sin(anim_time * 14.0), Color(1.0, 0.25, 0.08, 0.28))
	draw_circle(Vector2.ZERO, 6.0, Color(1.0, 0.52, 0.12))
	draw_circle(Vector2.ZERO, 2.5, Color(1.0, 0.95, 0.65))
