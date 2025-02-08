extends CharacterBody2D


const SPEED = 130.0
const JUMP_VELOCITY = -300.0
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var ground_ray: RayCast2D = $RayCast2D
var is_dying = false
var target = 0.0
var deathspeed = 1
var fallback_y_position = 300 # length character can fall until they die

func die() -> void:
	# Check if Player Character is on floor
	if ground_ray.is_colliding():
		target = ground_ray.get_collision_point()
	else:
			target = Vector2(position.x, fallback_y_position) 
	
	is_dying = true

func _process(_delta):
	if is_dying:
			Engine.time_scale = 0.5
			
		# position = lerp(position,target,0.15) # Speed
			if abs(position.y - target.y) < 1.0:
				is_dying = false
				animated_sprite.play("death")
				set_physics_process(false)
				get_node("CollisionShape2D").queue_free()
				await animated_sprite.animation_finished # Wait till animation is over
				get_tree().reload_current_scene() # Reload new level
				Engine.time_scale= 1


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta * deathspeed

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# This gets the key input: -1, 0, 1
	var direction := Input.get_axis("move_left", "move_right")
	
	# Flip the Sprite
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true
	
	# Play Animations
	if is_on_floor():
		if direction == 0:
			animated_sprite.play("idle")
		else:
			animated_sprite.play("run")
	else:
			animated_sprite.play("jump")
	
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
