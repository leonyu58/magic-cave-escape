extends Node2D

var count: int = 18
var area_size: Vector2 = Vector2(900.0, 400.0)
var tint: Color = Color(0.7, 0.9, 1.0, 0.55)
var radius: float = 1.8
var drift: float = 8.0
var time: float = 0.0
var points: Array[Vector2] = []
var phases: Array[float] = []

func _ready() -> void:
	z_index = -2
	for i in range(count):
		var fx: float = fmod(float(i * 97 + 31), 101.0) / 101.0
		var fy: float = fmod(float(i * 53 + 17), 103.0) / 103.0
		points.append(Vector2(fx * area_size.x, fy * area_size.y))
		phases.append(float(i) * 0.73)
	queue_redraw()

func _process(delta: float) -> void:
	time += delta
	queue_redraw()

func _draw() -> void:
	for i in range(points.size()):
		var p: Vector2 = points[i]
		var phase: float = phases[i]
		var sway: Vector2 = Vector2(sin(time * 0.7 + phase) * drift, cos(time * 0.9 + phase) * drift * 0.55)
		var twinkle: float = 0.55 + 0.45 * sin(time * 2.0 + phase)
		var c: Color = Color(tint.r, tint.g, tint.b, tint.a * twinkle)
		draw_circle(p + sway, radius + twinkle * 0.7, c)
