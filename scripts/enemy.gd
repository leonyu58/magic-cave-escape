extends CharacterBody2D

var target: Node2D
var health: int = 3
var speed: float = 72.0
var gravity: float = 1200.0
var damage_cooldown: float = 0.0
var home_x: float = 0.0
var anim_time: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 1
	collision_mask = 1
	home_x = global_position.x
	var shape: CollisionShape2D = CollisionShape2D.new()
	var capsule: CapsuleShape2D = CapsuleShape2D.new()
	capsule.radius = 14.0
	capsule.height = 34.0
	shape.shape = capsule
	add_child(shape)
	queue_redraw()

func _physics_process(delta: float) -> void:
	anim_time += delta
	damage_cooldown = maxf(damage_cooldown - delta, 0.0)
	if not is_on_floor():
		velocity.y += gravity * delta
	if is_instance_valid(target):
		var dx: float = target.global_position.x - global_position.x
		if absf(dx) < 360.0 and absf(target.global_position.y - global_position.y) < 150.0:
			velocity.x = sign(dx) * speed
		else:
			velocity.x = sign(home_x - global_position.x) * 28.0 if absf(home_x - global_position.x) > 12.0 else 0.0
		if global_position.distance_to(target.global_position) < 34.0 and damage_cooldown <= 0.0:
			if target.has_method("take_damage"):
				target.take_damage(1)
			damage_cooldown = 0.9
	move_and_slide()
	queue_redraw()

func take_damage(amount: int) -> void:
	health -= amount
	modulate = Color(1.0, 0.55, 0.55)
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.08)
	if health <= 0:
		if get_tree().current_scene.has_method("spawn_health"):
			get_tree().current_scene.spawn_health(global_position)
		queue_free()

func _draw() -> void:
	var bounce: float = sin(anim_time * 6.0) * 1.5
	# Spiky silhouette to make melee enemies read differently from the turret.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-16.0, 2.0 + bounce), Vector2(-23.0, -7.0), Vector2(-14.0, -8.0),
		Vector2(-9.0, -22.0), Vector2(-2.0, -14.0), Vector2(7.0, -23.0),
		Vector2(11.0, -11.0), Vector2(22.0, -6.0), Vector2(16.0, 4.0 + bounce),
		Vector2(10.0, 13.0), Vector2(-10.0, 13.0)
	]), Color(0.39, 0.09, 0.52))
	draw_circle(Vector2(0.0, -4.0 + bounce), 14.0, Color(0.52, 0.14, 0.66))
	draw_circle(Vector2(-6.0, -7.0 + bounce), 3.3, Color(1.0, 0.35, 0.65))
	draw_circle(Vector2(6.0, -7.0 + bounce), 3.3, Color(1.0, 0.35, 0.65))
	draw_circle(Vector2(0.0, 2.0 + bounce), 3.0, Color(0.94, 0.42, 1.0, 0.85))
	draw_line(Vector2(-9.0, 7.0), Vector2(-16.0, 18.0), Color(0.72, 0.26, 0.8), 4.0)
	draw_line(Vector2(9.0, 7.0), Vector2(16.0, 18.0), Color(0.72, 0.26, 0.8), 4.0)
