extends CharacterBody2D

signal health_changed(current, maximum)
signal rune_changed(rune_name)
signal rune_unlocked(rune_name)

const SPEED: float = 210.0
const JUMP_VELOCITY: float = -520.0
const GRAVITY: float = 1200.0
const DASH_SPEED: float = 560.0

var max_health: int = 5
var health: int = 5
var facing: int = 1
var attack_hold: float = 0.0
var attack_cooldown: float = 0.0
var dash_time: float = 0.0
var dash_cooldown: float = 0.0
var updraft_cooldown: float = 0.0
var updraft_available: bool = true
var updraft_fx_time: float = 0.0
var shield_time: float = 0.0
var invuln_time: float = 0.0
var slash_time: float = 0.0
var slash_strong: bool = false
var current_rune: String = "none"
var combat_enabled: bool = true
var sword_visible: bool = true
var unlocked: Dictionary = {
	"fire": false,
	"water": false,
	"earth": false,
	"air": false
}

var fireball_script: Script = preload("res://scripts/fireball.gd")
var idle_texture: Texture2D = preload("res://assets/player.png")
var sword_texture: Texture2D = preload("res://assets/player_sword.png")
var player_sprite: Sprite2D
var walk_anim_time: float = 0.0
var walk_frame: int = 0
var idle_anim_time: float = 0.0
var idle_frame: int = 0
var fire_cooldown: float = 0.0
var earth_cooldown: float = 0.0

func _ready() -> void:
	add_to_group("player")
	collision_layer = 1
	collision_mask = 1
	var shape: CollisionShape2D = CollisionShape2D.new()
	var capsule: CapsuleShape2D = CapsuleShape2D.new()
	capsule.radius = 13.0
	capsule.height = 42.0
	shape.shape = capsule
	add_child(shape)
	player_sprite = Sprite2D.new()
	player_sprite = Sprite2D.new()

	if get_tree().current_scene.name == "Surface":
		player_sprite.texture = idle_texture
	else:
		player_sprite.texture = sword_texture

	player_sprite.hframes = 2
	player_sprite.vframes = 2
	player_sprite.frame = 0
	player_sprite.scale = Vector2(2.0, 2.0)
	player_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	player_sprite.position = Vector2(0.0, 0.0)
	add_child(player_sprite)
	queue_redraw()

func _physics_process(delta: float) -> void:
	attack_cooldown = maxf(attack_cooldown - delta, 0.0)
	dash_cooldown = maxf(dash_cooldown - delta, 0.0)
	updraft_cooldown = maxf(updraft_cooldown - delta, 0.0)
	updraft_fx_time = maxf(updraft_fx_time - delta, 0.0)
	shield_time = maxf(shield_time - delta, 0.0)
	invuln_time = maxf(invuln_time - delta, 0.0)
	slash_time = maxf(slash_time - delta, 0.0)
	fire_cooldown = maxf(fire_cooldown - delta, 0.0)
	earth_cooldown = maxf(earth_cooldown - delta, 0.0)

	if dash_time > 0.0:
		dash_time -= delta
		velocity.y = 0.0
		velocity.x = float(facing) * DASH_SPEED
	else:
		if not is_on_floor():
			velocity.y += GRAVITY * delta

		var axis: float = Input.get_axis("move_left", "move_right")
		if axis != 0.0:
			facing = 1 if axis > 0.0 else -1
			velocity.x = axis * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0.0, SPEED * 7.0 * delta)

		if is_on_floor():
			updraft_available = true

		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY

		if Input.is_action_just_pressed("move_up") and bool(unlocked["air"]) and not is_on_floor() and updraft_available and updraft_cooldown <= 0.0:
			velocity.y = -640.0
			updraft_available = false
			updraft_cooldown = 0.22
			updraft_fx_time = 0.30

		if Input.is_action_just_pressed("dash") and bool(unlocked["air"]) and dash_cooldown <= 0.0:
			dash_time = 0.17
			dash_cooldown = 0.8

	handle_attacks(delta)
	handle_runes()
	move_and_slide()

	if global_position.y > 900.0:
		take_damage(99)

	if is_instance_valid(player_sprite):
		player_sprite.flip_h = facing < 0

		if absf(velocity.x) > 10.0 and is_on_floor():
			idle_anim_time = 0.0
			walk_anim_time += delta

			if walk_anim_time >= 0.12:
				walk_anim_time = 0.0
				walk_frame = (walk_frame + 1) % 3
				player_sprite.frame = walk_frame

		elif is_on_floor():
			walk_anim_time = 0.0
			idle_anim_time += delta

			if idle_anim_time >= 0.35:
				idle_anim_time = 0.0
				idle_frame = (idle_frame + 1) % 3
				player_sprite.frame = idle_frame
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if not mouse_event.pressed:
			return
		if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
			cycle_rune(-1)
			get_viewport().set_input_as_handled()
		elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			cycle_rune(1)
			get_viewport().set_input_as_handled()

func cycle_rune(direction: int) -> void:
	var available: Array[String] = []
	var rune_order: Array[String] = ["fire", "earth", "water"]
	for rune_name: String in rune_order:
		if bool(unlocked.get(rune_name, false)):
			available.append(rune_name)
	if available.is_empty():
		return
	var current_index: int = available.find(current_rune)
	if current_index < 0:
		current_index = 0 if direction >= 0 else available.size() - 1
	else:
		current_index = (current_index + direction + available.size()) % available.size()
	select_rune(available[current_index])

func handle_attacks(delta: float) -> void:
	if not combat_enabled:
		attack_hold = 0.0
		return
	if Input.is_action_just_pressed("attack"):
		attack_hold = 0.0
	if Input.is_action_pressed("attack"):
		attack_hold += delta
	if Input.is_action_just_released("attack") and attack_cooldown <= 0.0:
		var strong: bool = attack_hold >= 0.45
		sword_attack(2 if strong else 1, 105.0 if strong else 80.0)
		slash_strong = strong
		slash_time = 0.18 if strong else 0.12
		attack_cooldown = 0.45 if strong else 0.25
		attack_hold = 0.0

func sword_attack(damage: int, reach: float) -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or not enemy.has_method("take_damage"):
			continue
		var offset: Vector2 = enemy.global_position - global_position
		var in_front: bool = sign(offset.x) == facing or absf(offset.x) < 18.0
		if in_front and absf(offset.x) <= reach and absf(offset.y) <= 58.0:
			enemy.take_damage(damage)

func handle_runes() -> void:
	if Input.is_action_just_pressed("rune_fire"):
		select_rune("fire")
	if Input.is_action_just_pressed("rune_water"):
		select_rune("water")
	if Input.is_action_just_pressed("rune_earth"):
		select_rune("earth")
	if Input.is_action_just_pressed("magic"):
		use_magic()

func select_rune(rune_name: String) -> void:
	if bool(unlocked.get(rune_name, false)):
		current_rune = rune_name
		rune_changed.emit(current_rune)
		queue_redraw()

func unlock_rune(rune_name: String) -> void:
	if bool(unlocked.get(rune_name, false)):
		return
	unlocked[rune_name] = true
	rune_unlocked.emit(rune_name)
	if rune_name != "air":
		current_rune = rune_name
		rune_changed.emit(current_rune)

func use_magic() -> void:
	if current_rune == "fire" and bool(unlocked["fire"]) and fire_cooldown <= 0.0:
		var fireball: Variant = fireball_script.new()
		fireball.global_position = global_position + Vector2(float(facing) * 28.0, -5.0)
		fireball.direction = facing
		get_tree().current_scene.add_child(fireball)
		fire_cooldown = 0.8
	elif current_rune == "water" and bool(unlocked["water"]):
		if get_tree().current_scene.has_method("activate_water"):
			get_tree().current_scene.activate_water(global_position)
	elif current_rune == "earth" and bool(unlocked["earth"]) and earth_cooldown <= 0.0:
		shield_time = 4.0
		earth_cooldown = 5.0

func take_damage(amount: int) -> void:
	if invuln_time > 0.0:
		return
	if shield_time > 0.0:
		shield_time = maxf(shield_time - 0.8, 0.0)
		invuln_time = 0.2
		return
	health -= amount
	invuln_time = 0.7
	health_changed.emit(health, max_health)
	if health <= 0:
		health = max_health
		velocity = Vector2.ZERO
		if get_tree().current_scene.has_method("respawn_player"):
			get_tree().current_scene.respawn_player(self)
		health_changed.emit(health, max_health)

func heal(amount: int) -> void:
	health = mini(max_health, health + amount)
	health_changed.emit(health, max_health)

func _draw() -> void:
	if shield_time > 0.0:
		draw_circle(Vector2.ZERO, 29.0, Color(0.55, 0.92, 0.48, 0.30))
		draw_arc(Vector2.ZERO, 30.0, 0.0, TAU, 32, Color(0.68, 1.0, 0.58), 3.0)

	if dash_time > 0.0:
		for i in range(3):
			var trail_x: float = -float(facing) * (18.0 + float(i) * 12.0)
			draw_circle(Vector2(trail_x, 1.0), 12.0 - float(i) * 2.4, Color(0.62, 0.86, 1.0, 0.16 - float(i) * 0.035))

	if updraft_fx_time > 0.0:
		var fx_alpha: float = clampf(updraft_fx_time / 0.30, 0.0, 1.0)
		draw_circle(Vector2(0.0, 24.0), 24.0, Color(0.54, 0.90, 1.0, 0.11 * fx_alpha))
		for i in range(5):
			var x_offset: float = -22.0 + float(i) * 11.0
			var y_offset: float = 22.0 + float(i % 2) * 7.0
			draw_line(Vector2(x_offset, y_offset + 28.0), Vector2(x_offset * 0.65, y_offset - 7.0), Color(0.68, 0.94, 1.0, 0.82 * fx_alpha), 3.0)
		draw_arc(Vector2(0.0, 27.0), 29.0, PI, TAU, 18, Color(0.74, 0.94, 1.0, 0.62 * fx_alpha), 3.0)

	
	if slash_time > 0.0:
		var slash_color: Color = Color(0.98, 0.82, 1.0, 0.9) if not slash_strong else Color(0.72, 0.9, 1.0, 0.95)
		var radius: float = 42.0 if not slash_strong else 55.0
		var start_angle: float = -0.8 if facing > 0 else PI - 0.8
		var end_angle: float = 0.8 if facing > 0 else PI + 0.8
		draw_arc(Vector2(0.0, -2.0), radius, start_angle, end_angle, 18, slash_color, 5.0 if slash_strong else 3.0)

	var rune_color: Color = Color(0.5, 0.5, 0.5)
	if current_rune == "fire":
		rune_color = Color(1.0, 0.32, 0.12)
	elif current_rune == "water":
		rune_color = Color(0.2, 0.62, 1.0)
	elif current_rune == "earth":
		rune_color = Color(0.42, 0.85, 0.32)
	if current_rune != "none":
		draw_circle(Vector2(0.0, -35.0), 8.0, Color(rune_color.r, rune_color.g, rune_color.b, 0.16))
		draw_circle(Vector2(0.0, -35.0), 5.0, rune_color)
