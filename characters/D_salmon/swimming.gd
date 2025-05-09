extends PlayerState

@export var swim_speed: float = 300.0
@export var acceleration: float = 800.0
@export var deceleration: float = 600.0
@export var waterfall_boost: float = 300.0  # Extra push when swimming up waterfalls
@export var jump_boost: float = -500.00     # Boost upon breaching the water (extra jump height)
@export var sink_speed: float = 40.0        # How fast the fish sinks
@export var drift_speed: float = -60.0      # Leftward drift speed in water
@export var rotation_recovery_speed: float = 250.0  # Speed of rotation reset

func enter():
	# Ensure the player sprite exists and the swimming animation is valid
	if player.sprite:
		if player.anim_player.has_animation("swimming"):
			##print("Playing swimming animation")
			player.anim_player.play("swimming")  # Play swimming animation
		else:
			print("No 'swimming' animation found in player sprite.")
	else:
		print("Player sprite not found!")
	
	player.velocity = player.velocity * 0.8  # Slow velocity when entering water

func exit():
	if player.anim_player:
		##print("Stopping swimming animation")
		player.anim_player.stop()

func physics_process(delta):
	swim_movement(delta)
	reset_rotation(delta)  # Smoothly reset rotation
	player.move_and_slide()

func swim_movement(delta):
	# Apply smooth movement in water
	var direction = Vector2.ZERO
	
	if Input.is_action_pressed("move_right"):
		direction.x += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_up"):
		direction.y -= 1
	if Input.is_action_pressed("move_down"):
		direction.y += 1
	
	# Left/Right Movement with Acceleration & Deceleration
	if direction.x != 0:
		player.velocity.x = move_toward(player.velocity.x, direction.x * swim_speed, acceleration * delta)
		player.facing_direction = direction.x  # Update facing direction
	else:
		player.velocity.x = move_toward(player.velocity.x, 0, deceleration * delta)  # Decelerate if no input
	
	# Apply Vertical Movement
	if direction.y < 0:  # Moving up
		player.velocity.y = move_toward(player.velocity.y, direction.y * swim_speed, acceleration * delta)
	elif direction.y > 0:  # Moving down faster than sink speed
		player.velocity.y = move_toward(player.velocity.y, direction.y * swim_speed, acceleration * delta)
	else:  # No input = apply constant sinking effect
		player.velocity.y = move_toward(player.velocity.y, sink_speed, deceleration * delta)
	
	# Apply leftward drift force while in water (If in current)
	if player.is_in_current:
		player.velocity.x += drift_speed * delta  
	
	# Apply waterfall boost
	if player.is_in_waterfall:
		player.velocity.y -= waterfall_boost * delta  # Extra push upwards
	
	# Jump boost when breaching water
	if player.just_exited_water:
		player.velocity.y = jump_boost  # Apply jump boost
		player.change_state(player.flopping_state)  # Switch to flopping state
	
	# Flip horizontally when moving left or right
	if player.facing_direction != 0:
		player.sprite.flip_h = player.facing_direction < 0  # True if left, False if right

func reset_rotation(delta):
	# Smoothly rotate back to upright (0 degrees)
	player.rotation_degrees = move_toward(player.rotation_degrees, 0, rotation_recovery_speed * delta)
