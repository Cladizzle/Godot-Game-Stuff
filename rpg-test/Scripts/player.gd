extends CharacterBody2D

const SPEED = 130.0
const JUMP_VELOCITY = -300.0
const COYOTE_TIME = 0.15
const DODGE_SPEED = 300.0
const DODGE_DURATION = 0.3
const DODGE_COOLDOWN = 0
const DOUBLE_TAP_TIME = 0.3  

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var ground_ray: RayCast2D = $RayCast2D

var is_dying = false
var is_invincible = false
var can_dodge = true
var is_dodging = false
var dodge_direction = 0

var last_tap_time = {}  # Tracks last press time
var released_since_last_tap = {}  # Tracks if the key was released

var target = 0.0
var deathspeed = 1
var fallback_y_position = 300
var coyote_timer = 0.0

func die() -> void:
	if is_invincible:
		return  # Prevent death while dodging

	print("Player died!")
	
	is_dying = true
	Engine.time_scale = 0.5  # Slow motion effect

	# Disable movement but allow falling
	set_physics_process(false)  # Stop player input
	velocity = Vector2(0, 0)  # Reset velocity to prevent weird movement
	deathspeed = 1  # Apply normal gravity

	# Wait until the player lands
	await wait_until_landed()

	# Play death animation after landing
	animated_sprite.play("death")
	get_node("CollisionShape2D").queue_free()

	await animated_sprite.animation_finished  # Wait until animation ends
	get_tree().reload_current_scene()  # Reload level
	Engine.time_scale = 1  # Reset time scale

func wait_until_landed() -> void:
	while not is_on_floor():
		velocity.y += ProjectSettings.get_setting("physics/2d/default_gravity") * get_process_delta_time()
		move_and_slide()  # Ensure the player keeps falling
		await get_tree().process_frame  # Wait for the next frame

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta * deathspeed
		coyote_timer -= delta
	else:
		coyote_timer = COYOTE_TIME

	# Handle Jump (Coyote Time)
	if Input.is_action_just_pressed("jump") and (is_on_floor() or coyote_timer > 0):
		velocity.y = JUMP_VELOCITY
		coyote_timer = 0

	# Handle Movement
	var direction := Input.get_axis("move_left", "move_right")

	# Debugging - Track inputs
	if Input.is_action_just_pressed("move_left"):
		print("Left pressed")
		handle_double_tap(-1)

	if Input.is_action_just_pressed("move_right"):
		print("Right pressed")
		handle_double_tap(1)

	# Track key releases properly
	if Input.is_action_just_released("move_left"):
		released_since_last_tap[-1] = true
		print("Left released")

	if Input.is_action_just_released("move_right"):
		released_since_last_tap[1] = true
		print("Right released")

	# Dodge Movement
	if is_dodging:
		velocity.x = dodge_direction * DODGE_SPEED
	else:
		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

	# Flip the Sprite
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true

	# Play Animations
	if not is_dodging:
		if is_on_floor():
			if direction == 0:
				animated_sprite.play("idle")
			else:
				animated_sprite.play("run")
		else:
			animated_sprite.play("jump")

	move_and_slide()

func handle_double_tap(direction: int) -> void:
	var current_time = Time.get_ticks_msec()

	# Check for a valid double tap
	if direction in last_tap_time and released_since_last_tap.get(direction, false):
		var time_since_last_tap = current_time - last_tap_time[direction]
		print("Time since last tap:", time_since_last_tap)

		if time_since_last_tap < DOUBLE_TAP_TIME * 1000:
			print("Double tap detected! Dodging...")
			start_dodge(direction)

	# Update tracking variables
	last_tap_time[direction] = current_time
	released_since_last_tap[direction] = false  # Reset release tracking

func start_dodge(direction: int) -> void:
	if not can_dodge or is_dodging:
		return  

	is_dodging = true
	is_invincible = true
	dodge_direction = direction
	can_dodge = false  

	animated_sprite.play("dodge")

	await get_tree().create_timer(DODGE_DURATION).timeout
	is_dodging = false
	is_invincible = false

	await get_tree().create_timer(DODGE_COOLDOWN).timeout
	can_dodge = true
