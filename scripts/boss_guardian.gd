extends Node2D

signal health_changed(current: int, maximum: int)
signal defeated

var target: Node2D
var max_health: int = 20
var health: int = 20
var active: bool = false
var shot_timer: float = 1.2
var summon_timer: float = 4.8
var anim_time: float = 0.0
var summon_flip: bool = false

var bullet_script: Script = preload("res://scripts/enemy_bullet.gd")
var enemy_script: Script = preload("res://scripts/enemy.gd")

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("boss")
	build_collision()
	queue_redraw()

func build_collision() -> void:
	var body: StaticBody2D = StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 1
	var shape_node: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(82.0, 92.0)
	shape_node.shape = shape
	body.add_child(shape_node)
	add_child(body)

func activate() -> void:
	if active:
		return
	active = true
	shot_timer = 0.8
	summon_timer = 3.8
	health_changed.emit(health, max_health)
	queue_redraw()

func _process(delta: float) -> void:
	anim_time += delta
	if active and is_instance_valid(target):
		shot_timer -= delta
		summon_timer -= delta
		if shot_timer <= 0.0 and global_position.distance_to(target.global_position) < 820.0:
			fire_volley()
			shot_timer = 1.85
		if summon_timer <= 0.0:
			summon_minions()
			summon_timer = 5.6
	queue_redraw()

func fire_volley() -> void:
	if not is_instance_valid(target):
		return
	var aim: Vector2 = (target.global_position - global_position).normalized()
	var base_angle: float = aim.angle()
	var shot_offsets: PackedFloat32Array = PackedFloat32Array([-0.28, -0.14, 0.0, 0.14, 0.28])
	for offset in shot_offsets:
		var bullet: Variant = bullet_script.new()
		bullet.global_position = global_position + Vector2(0.0, -8.0)
		bullet.velocity = Vector2.from_angle(base_angle + float(offset)) * 195.0
		bullet.speed = 195.0
		bullet.homing_strength = 1.9
		bullet.orb_radius = 6.5
		bullet.orb_color = Color(0.50, 0.84, 1.0)
		bullet.target = target
		get_tree().current_scene.add_child(bullet)

func summon_minions() -> void:
	if not is_instance_valid(target):
		return
	var current_minions: int = get_tree().get_nodes_in_group("boss_minions").size()
	if current_minions >= 3:
		return
	var spawn_count: int = 2 if current_minions == 0 else 1
	for i in range(spawn_count):
		var minion: Variant = enemy_script.new()
		var side: float = -1.0 if summon_flip else 1.0
		summon_flip = not summon_flip
		minion.position = position + Vector2(side * (85.0 + float(i) * 28.0), 25.0)
		get_tree().current_scene.add_child(minion)
		minion.add_to_group("boss_minions")
		minion.target = target

func take_damage(amount: int) -> void:
	if not active:
		return
	health = maxi(health - amount, 0)
	health_changed.emit(health, max_health)
	modulate = Color(1.0, 0.60, 0.86)
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.10)
	if health <= 0:
		defeated.emit()
		for minion in get_tree().get_nodes_in_group("boss_minions"):
			if is_instance_valid(minion):
				minion.queue_free()
		queue_free()

func _draw() -> void:
	var pulse: float = 1.0 + sin(anim_time * 3.8) * 0.05
	var dormant_alpha: float = 1.0 if active else 0.46
	var crystal_color: Color = Color(0.54, 0.17, 0.82, dormant_alpha)
	var edge_color: Color = Color(0.86, 0.52, 1.0, dormant_alpha)
	var core_color: Color = Color(0.48, 0.88, 1.0, dormant_alpha)

	for i in range(8):
		var angle: float = TAU * float(i) / 8.0 + anim_time * 0.18
		var inner: Vector2 = Vector2(cos(angle), sin(angle)) * 38.0 * pulse
		var outer: Vector2 = Vector2(cos(angle), sin(angle)) * 68.0 * pulse
		draw_line(inner, outer, edge_color, 8.0)
		draw_circle(outer, 6.0, Color(edge_color.r, edge_color.g, edge_color.b, 0.24))

	var body_points: PackedVector2Array = PackedVector2Array([
		Vector2(0.0, -60.0), Vector2(40.0, -24.0), Vector2(34.0, 38.0),
		Vector2(0.0, 58.0), Vector2(-34.0, 38.0), Vector2(-40.0, -24.0)
	])
	draw_colored_polygon(body_points, crystal_color)
	draw_polyline(PackedVector2Array([body_points[0], body_points[1], body_points[2], body_points[3], body_points[4], body_points[5], body_points[0]]), edge_color, 3.0)
	draw_circle(Vector2.ZERO, 25.0 + sin(anim_time * 5.0) * 2.0, Color(core_color.r, core_color.g, core_color.b, 0.16))
	draw_circle(Vector2.ZERO, 13.0 + sin(anim_time * 5.0) * 1.5, core_color)
	draw_circle(Vector2(-4.0, -4.0), 4.0, Color(1.0, 1.0, 1.0, dormant_alpha))
