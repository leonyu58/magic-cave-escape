extends Node2D

var target: Node2D
var health: int = 4
var shot_timer: float = 1.0
var anim_time: float = 0.0
var bullet_script: Script = preload("res://scripts/enemy_bullet.gd")

func _ready() -> void:
	add_to_group("enemies")
	queue_redraw()

func _process(delta: float) -> void:
	anim_time += delta
	shot_timer -= delta
	if shot_timer <= 0.0 and is_instance_valid(target) and global_position.distance_to(target.global_position) < 520.0:
		fire_burst()
		shot_timer = 1.65
	queue_redraw()

func fire_burst() -> void:
	if not is_instance_valid(target):
		return
	var aim: Vector2 = (target.global_position - global_position).normalized()
	var base_angle: float = aim.angle()
	var shot_offsets: PackedFloat32Array = PackedFloat32Array([-0.18, 0.0, 0.18])
	for offset in shot_offsets:
		var bullet: Variant = bullet_script.new()
		bullet.global_position = global_position + Vector2(0.0, 5.0)
		bullet.velocity = Vector2.from_angle(base_angle + float(offset)) * 175.0
		bullet.target = target
		get_tree().current_scene.add_child(bullet)

func take_damage(amount: int) -> void:
	health -= amount
	modulate = Color(1.0, 0.62, 0.82)
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.09)
	if health <= 0:
		if get_tree().current_scene.has_method("spawn_health"):
			get_tree().current_scene.spawn_health(global_position)
		queue_free()

func _draw() -> void:
	var pts: PackedVector2Array = PackedVector2Array([
		Vector2(0.0, -26.0), Vector2(17.0, -7.0), Vector2(12.0, 22.0),
		Vector2(-12.0, 22.0), Vector2(-17.0, -7.0)
	])
	draw_colored_polygon(pts, Color(0.66, 0.17, 0.86))
	draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[4], pts[0]]), Color(0.88, 0.52, 1.0), 2.0)
	var pulse: float = 6.0 + sin(anim_time * 5.0) * 1.8
	draw_circle(Vector2.ZERO, pulse + 5.0, Color(0.95, 0.35, 1.0, 0.13))
	draw_circle(Vector2.ZERO, pulse, Color(1.0, 0.62, 1.0))
	for i in range(4):
		var angle: float = -anim_time * 1.3 + TAU * float(i) / 4.0
		draw_circle(Vector2(cos(angle), sin(angle)) * 29.0, 2.5, Color(0.92, 0.48, 1.0, 0.72))
