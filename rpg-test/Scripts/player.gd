extends CharacterBody2D


const SPEED = 130.0
const JUMP_VELOCITY = -300.0
const COYOTE_TIME = 0.15 # 150 Millisekunden Coyote Time

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var ground_ray: RayCast2D = $RayCast2D

var is_dying = false
var target = 0.0
var deathspeed = 1
var fallback_y_position = 300 # length character can fall until they die
var coyote_timer = 0.0

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
	# Add Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta * deathspeed
		# Reduziere den Coyote Timer, wenn der Spieler in der Luft ist
		coyote_timer -= delta
	else:
		# Spieler hat den Boden berührt, setze Coyote Timer zurück
		coyote_timer = COYOTE_TIME

	# Handle Jump (inkl. Coyote Time)
	if Input.is_action_just_pressed("jump") and (is_on_floor() or coyote_timer > 0):
		velocity.y = JUMP_VELOCITY
		coyote_timer = 0  # Nach einem Sprung deaktivieren

	# Get the input direction and handle the movement/deceleration.
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
