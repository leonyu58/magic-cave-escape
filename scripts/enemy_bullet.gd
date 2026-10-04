extends Node2D

var velocity: Vector2 = Vector2.ZERO
var target: Node2D
var lifetime: float = 4.0
var anim_time: float = 0.0
var homing_strength: float = 2.25
var speed: float = 175.0
var orb_radius: float = 4.0
var orb_color: Color = Color(1.0, 0.72, 1.0)

func _ready() -> void:
	z_index = 5
	queue_redraw()

func _process(delta: float) -> void:
	anim_time += delta
	if is_instance_valid(target):
		var desired: Vector2 = (target.global_position - global_position).normalized() * speed
		# Gentle homing makes the projectile dodgeable while letting the Air updraft matter.
		velocity = velocity.lerp(desired, clampf(homing_strength * delta, 0.0, 1.0))
	position += velocity * delta
	lifetime -= delta
	if is_instance_valid(target) and global_position.distance_to(target.global_position) < 18.0:
		if target.has_method("take_damage"):
			target.take_damage(1)
		queue_free()
		return
	if lifetime <= 0.0:
		queue_free()
	queue_redraw()

func _draw() -> void:
	var pulse: float = orb_radius + 3.0 + sin(anim_time * 10.0) * 1.0
	draw_circle(Vector2.ZERO, pulse + 3.0, Color(orb_color.r, orb_color.g, orb_color.b, 0.18))
	draw_circle(Vector2.ZERO, orb_radius, orb_color)
	draw_circle(Vector2(-orb_radius * 0.28, -orb_radius * 0.28), maxf(1.5, orb_radius * 0.28), Color(1.0, 1.0, 1.0, 0.84))
