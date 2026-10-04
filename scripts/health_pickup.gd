extends Area2D

var bob: float = 0.0
var base_y: float = 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	var shape: CollisionShape2D = CollisionShape2D.new()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = 14.0
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)
	base_y = position.y
	queue_redraw()

func _process(delta: float) -> void:
	bob += delta * 4.0
	position.y = base_y + sin(bob) * 3.0
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("heal"):
		body.heal(1)
		queue_free()

func _draw() -> void:
	var pulse: float = 13.0 + sin(bob * 0.7) * 1.5
	draw_circle(Vector2.ZERO, pulse + 5.0, Color(1.0, 0.2, 0.45, 0.10))
	draw_circle(Vector2.ZERO, 12.0, Color(1.0, 0.2, 0.45, 0.24))
	draw_rect(Rect2(-3.0, -9.0, 6.0, 18.0), Color(1.0, 0.42, 0.62))
	draw_rect(Rect2(-9.0, -3.0, 18.0, 6.0), Color(1.0, 0.42, 0.62))
