extends CharacterBody2D

const SPEED = 130.0
const JUMP_VELOCITY = -300.0
const COYOTE_TIME = 0.15
const DODGE_SPEED = 300.0
const DODGE_DURATION = 0.3
const DODGE_COOLDOWN = 0  

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var ground_ray: RayCast2D = $RayCast2D

var is_dying = false
var is_invincible = false
var can_dodge = true
var is_dodging = false
var dodge_direction = 0

var target = 0.0
var deathspeed = 1
var fallback_y_position = 300
var coyote_timer = 0.0
var can_double_jump = true  # Allows a second jump in mid-air

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
	
	var collision_shape = get_node_or_null("CollisionShape2D")
	if collision_shape:
		collision_shape.queue_free()

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
		can_double_jump = true  # Reset double jump when landing

	# Handle Jump (Coyote Time & Double Jump)
	if Input.is_action_just_pressed("jump"):
		if is_on_floor() or coyote_timer > 0:
			velocity.y = JUMP_VELOCITY
			coyote_timer = 0
		elif can_double_jump:
			velocity.y = JUMP_VELOCITY
			can_double_jump = false  # Disable double jump after use

	# Handle Movement
	var direction := Input.get_axis("move_left", "move_right")

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

# Dodge with 'v' instead of double tap
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("dodge"):
		start_dodge()

func start_dodge() -> void:
	if not can_dodge or is_dodging or is_dying:
		return  # Prevent dodging while dying

	is_dodging = true
	is_invincible = true

	# Determine dodge direction based on movement input
	var direction := Input.get_axis("move_left", "move_right")
	if direction == 0:
		direction = 1 if not animated_sprite.flip_h else -1  # Default to facing direction
	dodge_direction = direction

	animated_sprite.play("dodge")

	await get_tree().create_timer(DODGE_DURATION).timeout
	is_dodging = false
	is_invincible = false

	await get_tree().create_timer(DODGE_COOLDOWN).timeout
	can_dodge = true
