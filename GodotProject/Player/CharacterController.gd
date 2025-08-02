extends CharacterBody3D
class_name CharacterController

var _enabled = true

@export_category("Inputs")
@export var jump_held : bool = false
@export var input_vector : Vector2
var _jump_held_last_frame : bool = false

@export_category("Acceleration")
## Max move speed to target
@export var move_speed : float = 6
@export var move_speed_jump_precharge_multiplier : float = 0.4
## Rate of velocity change used to achieve move_speed.
@export var acceleration : float = 10
## Rate of velocity change when the player releases input in order to stop, or
## when they input a direction roughly in the opposite direction of their travel.
@export var deceleration : float = 20
## Rate of velocity change when the player is about to walk off a ledge.
@export var deceleration_ledgeDetected : float = 96
@export var airAcceleration : float = 10
@export var wallRunAcceleration : float = 10
@export var waterAccelerationMultiplier : float = 0.4
@export var waterDrag : float = 0
## Low acceleration values make moving feel slippery. This property helps with
## that. The player can redirect their velocity at this rate without slowing.
@export var runningSlerp_TurnRate : float = 4
@export var runningSlerp_LowSpeedMultiplier : float = 10

@export_category("Jumping")
## If true, player will not jump until they release the jump button. Jump hight
## is decided by how long they hold the jump key prior. If false, Jump hight is
## decided by how long the jump key is held after leaving the ground.
@export var jump_precharge : bool = true
@export var jump_precharge_minForceMultiplier = 0.5
@export var jump_precharge_maxTimeMS = 200
## If the player presses jump just before touching the ground the input will be buffered.
@export var jump_bufferMS : float = 200
@export var jump_cooldownMS : float = 100
@export var jump_force : float = 10.0
@export var jump_off_wall_force : float = 12.5
## must be <= jump_cooldownMS. Players can jump just after walking off a ledge.
@export var jump_coyote_timingMS : float = 100.0

@export_category("Wallrunning")
## Enable wallrunning
@export var Ability_Wallrun : bool = false
## The minimum speed the player must be moving at in order to start or
## maintain a wall run.
@export var wall_run_min_speed : float = 3
@export var wall_run_min_air_timeMS : float = 150
## Players are pushed into the wall with this force. Higher values make players
## less likely to disconnect from the wall when running around convex shapes.
@export var wall_run_magnet_force : float = 3.5
## Max wall steepness. 90 degrees = a level wall.
@export var wall_run_angle_max : float = deg_to_rad(100)
## Minimum wall steepness to wallrun. 90 degrees = a level wall. 0 = floor.
@export var wall_run_angle_min : float = deg_to_rad(65)

@export_category("Gravity")
@export var gravity_jumping : float = 25
## Character experiences more (or less) gravity after the apex of their jump, or
## after releasing the jump button if jump_precharge is false.
@export var gravity_falling : float = 50
@export var gravity_wall_running : float = 10
## Character experiences more gravity after the apex of their jump.
@export var gravity_wall_running_falling : float = 5
@export var terminal_velocity : float = 20
@export var voidout_hight : float = -12

@export_category("Visual Rotation")
@export var rotateToFaceMovement : bool = true
@export var visualRotationLerpSpeed : float = 16

@export_group("Particles", "particles_")
@export var particles_running : GPUParticles3D
@export var particles_jumping : GPUParticles3D

@export_group("AnimationTree Values", "ATV_")
@export var ATV_grounded : String = "parameters/conditions/grounded"
@export var ATV_jump_held : String = "parameters/conditions/jump_held"
@export var ATV_move_blend : String = "parameters/Movement/MovementBlend/blend_amount"
@export var ATV_move_alpha : String = "parameters/Movement/Walking/MovementScale/scale"

var move_speed_slowdown_sources = {}
var last_is_on_floor : bool = false
var last_is_wallrunning : bool = false
var last_is_in_water : bool = false
var last_is_on_floor_tick : float = 0
var last_is_wallrunning_tick : float = 0
var jump_input_last_tick : float = -100
var jump_input_released_last_tick : float = -100
var jump_last_tick : float = 0
var move_vector : Vector3
var facing_angle : float
var is_wall_running : bool = false

@export_category("References")
@export var model : Smoothing #= $Visual #find_child("Visual", false, true)
@onready var collision : CollisionShape3D = find_child("CollisionShape3D")
@onready var camera : Node3D = $"../FPSCamera/Pivot" #get_viewport().get_camera_3d()
@onready var anim_player : AnimationPlayer = find_child("AnimationPlayer", true, true)
@export var anim_tree : Node3D = find_child("AnimationTree", true, true)
## an area3D that detects when the player is about to walk off a ledge to help stop them.
@onready var ledge_detect : Area3D = find_child("LedgeDetect", false, true)
@onready var area_detect : Area3D = find_child("AreaDetect", false, true)

signal Jump_precharging
signal Jumped
signal Landed

func set_enabled(enabled : bool):
	_enabled = enabled
	model.visible = enabled
	collision.disabled = not enabled

func project_on_plane(point : Vector3, plane : Vector3):
	return point - point.project(plane)

func register_slowdown_source(source_name : String, new_move_speed : float):
	move_speed_slowdown_sources[source_name] = new_move_speed

func clear_registered_slowdown_source(source_name : String):
	move_speed_slowdown_sources[source_name] = null

func get_move_speed():
	var slowest : float = move_speed
	for source : String in move_speed_slowdown_sources:
		var slowdown = move_speed_slowdown_sources[source]
		if not slowdown: continue
		if slowdown < slowest: slowest = slowdown
	return slowest

func jump(force : Vector3):
	var tick : float = ScaledTime.CurrentTime
	
	#velocity.y = force
	velocity = force
	
	jump_input_last_tick = -100
	jump_input_released_last_tick = -100
	jump_last_tick = tick
	Jumped.emit()
	
	if particles_jumping:
		particles_jumping.restart()
		particles_jumping.emitting = true
	
	#if anim_player:
		#anim_player.play("Jump")
	#if anim_tree:
		#var state_machine = anim_tree.get("parameters/playback")
		#state_machine.travel("Jump")

func _physics_process(delta):
	if not _enabled: return
	
	var tick : float = ScaledTime.CurrentTime # Time.get_unix_time_from_system()
	var jump_just_pressed = jump_held and not _jump_held_last_frame
	var jump_just_released = (not jump_held) and _jump_held_last_frame
	
	
	# check if in water
	var is_in_water : bool = false
	if area_detect:
		for body in area_detect.get_overlapping_areas():
			if body.is_in_group("Water"): is_in_water = true
	if last_is_in_water != is_in_water:
		last_is_in_water = is_in_water
		velocity *= waterAccelerationMultiplier
		if is_in_water:
			register_slowdown_source(
				"water", move_speed * waterAccelerationMultiplier)
		else:
			clear_registered_slowdown_source("water")
	
	var jump_force_calc : float = jump_force
	var jump_off_wall_force_calc : float = jump_off_wall_force
	var gravity_jumping_calc : float = gravity_jumping
	var gravity_falling_calc : float = gravity_falling
	var gravity_wall_running_calc : float = gravity_wall_running
	var gravity_wall_running_falling_calc : float = gravity_wall_running_falling
	if is_in_water:
		jump_force_calc *= sqrt(waterAccelerationMultiplier)
		jump_off_wall_force_calc *= sqrt(waterAccelerationMultiplier)
		gravity_jumping_calc *= waterAccelerationMultiplier
		gravity_falling_calc = gravity_jumping_calc #*= waterAccelerationMultiplier
		gravity_wall_running_calc *= waterAccelerationMultiplier
		gravity_wall_running_falling_calc *= waterAccelerationMultiplier
	
	var physics_space : RID = PhysicsServer3D.body_get_space(self)
	var gravity_vector : Vector3 = PhysicsServer3D.area_get_param(
		physics_space, PhysicsServer3D.AREA_PARAM_GRAVITY_VECTOR)
	up_direction = -gravity_vector.normalized()
	
	var wall_angle : float = get_wall_normal().angle_to(up_direction)
	
	is_wall_running = is_on_wall_only()\
		and wall_angle < wall_run_angle_max\
		and wall_angle > wall_run_angle_min\
		and project_on_plane(velocity, Vector3.UP).length() > wall_run_min_speed\
		and tick - last_is_on_floor_tick > wall_run_min_air_timeMS/1000 \
		and Ability_Wallrun
	
	if is_on_floor(): last_is_on_floor_tick = tick
	if is_wall_running: last_is_wallrunning_tick = tick
	
	
	# gravity
	if not is_on_floor():
		var velocity_vertical_signed : float = velocity.project(up_direction).length() * velocity.project(up_direction).normalized().dot(up_direction) # velocity.y
		if is_wall_running: # and velocity.y < 0:
			if velocity_vertical_signed > 0:
				velocity += gravity_vector * gravity_wall_running_calc * delta
			else:
				velocity +=  gravity_vector * gravity_wall_running_falling_calc * delta
			
			# calculate normal max jump height
			var maxJumpHeight = 0.5 * (jump_force_calc * jump_force_calc / gravity_jumping_calc)
			
			# clamp max vertical velocity to not exceed normal jump height
			var maxVertVel = sqrt(2*gravity_wall_running_calc*maxJumpHeight)
			
			#velocity.y = clamp(velocity.y, -maxVertVel, maxVertVel)
			# these 3 lines do the same thing as the single line above but indipendent of which way is down.
			var projectedOnVector = velocity.project(gravity_vector.normalized())
			var projectedOnPlane = project_on_plane(velocity, gravity_vector.normalized())
			velocity = projectedOnPlane + projectedOnVector.limit_length(maxVertVel)
			
		elif velocity_vertical_signed >= 0 and (jump_precharge or jump_held):
			velocity += gravity_vector * gravity_jumping_calc * delta
		else:
			velocity += gravity_vector * gravity_falling_calc * delta
	
	
	# jumping
	if jump_just_pressed:
		jump_input_last_tick = tick
		if jump_precharge:
			Jump_precharging.emit()
			register_slowdown_source(
				"jump_precharge",
				move_speed * move_speed_jump_precharge_multiplier
			)
	
	if jump_just_released:
		jump_input_released_last_tick = tick
		if jump_precharge: clear_registered_slowdown_source("jump_precharge")
	
	var jump_requested_power_multiplier = 1
	var jump_requested_last_tick : float = jump_input_last_tick
	if jump_precharge:
		jump_requested_last_tick = jump_input_released_last_tick
		var blend = (tick #jump_input_released_last_tick
			- jump_input_last_tick) / (jump_precharge_maxTimeMS / 1000.0)
		jump_requested_power_multiplier = lerpf(
			jump_precharge_minForceMultiplier,
			1,
			min(blend, 1)
		)
		# not a good idea. Player might not learn that they need to release
		# the key to jump.
		#if Input.is_action_pressed("jump") and blend >= 1: Input.action_release("jump")
	
	if tick - jump_requested_last_tick < jump_bufferMS/1000 \
	and tick - jump_last_tick > jump_cooldownMS/1000.0:
		
		if (is_wall_running and last_is_wallrunning):
			jump((get_wall_normal() + up_direction).normalized() \
				* jump_off_wall_force_calc * jump_requested_power_multiplier)
		elif (is_on_floor() and last_is_on_floor) \
		or tick - last_is_on_floor_tick < jump_coyote_timingMS/1000.0:
			# Make sure the player is on the floor for at least 2 frames or the
			# floating disk won't reset.
			
			jump(project_on_plane(velocity, up_direction) \
				+ up_direction * jump_force_calc * jump_requested_power_multiplier)
	
	if last_is_on_floor != is_on_floor():
		last_is_on_floor = is_on_floor()
		if is_on_floor(): Landed.emit()
	
	
	# walking
	var input = input_vector
	var input_vector3 = Vector3(input.x, 0, input.y)
	var cameraFlattenedTransform : Basis = Basis.looking_at(
		project_on_plane(camera.global_basis * Vector3.FORWARD, up_direction),
		up_direction
	)
	if (camera.global_basis * up_direction).y < 0: input_vector3 *= -1
	move_vector = cameraFlattenedTransform * input_vector3
	if is_wall_running and \
	project_on_plane(move_vector, get_wall_normal()).length() > 0.1:
		move_vector = project_on_plane(move_vector, get_wall_normal()).normalized()\
		* move_vector.length()
	
	var rateOfVelocityChange : float = deceleration
	var turnedVelocity : Vector3 = Vector3(velocity.x, 0, velocity.z)
	if not is_on_floor():
		if is_wall_running:
			rateOfVelocityChange = wallRunAcceleration
		else:
			rateOfVelocityChange = airAcceleration
	elif input.length() > 0 and (velocity.length() <= 0 \
	or move_vector.normalized().dot(velocity.normalized())>0):
		rateOfVelocityChange = acceleration
		
		if not is_in_water and turnedVelocity.length() <= move_speed:
			var inverseSpeedAlpha = 1-(turnedVelocity.length() / move_speed)
			var blend = 1-pow(0.5, delta * runningSlerp_TurnRate * (1+inverseSpeedAlpha*runningSlerp_LowSpeedMultiplier))
			turnedVelocity = turnedVelocity.slerp(move_vector.normalized() * turnedVelocity.length(), blend)
	else: # deceleration
		#print("bodies: ",ledge_detect.has_overlapping_bodies())
		#print("areas: ", ledge_detect.has_overlapping_areas())
		if ledge_detect and not ledge_detect.has_overlapping_bodies():
			rateOfVelocityChange = deceleration_ledgeDetected
	
	if is_in_water:
		rateOfVelocityChange *= waterAccelerationMultiplier
	
	#velocity.x = move_toward(turnedVelocity.x, move_vector.x * move_speed, rateOfVelocityChange * delta)
	#velocity.z = move_toward(turnedVelocity.z, move_vector.z * move_speed, rateOfVelocityChange * delta)
	#velocity = velocity.move_toward(velocity.project(up_direction) + move_vector * move_speed, rateOfVelocityChange * delta)
	velocity = velocity.project(up_direction) + turnedVelocity.move_toward(move_vector * get_move_speed(), rateOfVelocityChange * delta)
	
	
	# drag
	var v = velocity.length()
	if is_in_water:
		velocity = velocity.move_toward(Vector3.ZERO, waterDrag * (v * v * 0.7 * 0.5))
	
	velocity = velocity.clampf(-terminal_velocity, terminal_velocity)
	
	# wall running
	if is_wall_running and tick - jump_last_tick > jump_cooldownMS/1000:
		velocity = project_on_plane(velocity, get_wall_normal()) + -get_wall_normal() * wall_run_magnet_force
	
	if is_wall_running:
		var wall_dot : float = (global_basis * Vector3.RIGHT).normalized().dot(get_wall_normal())
		if model: model.basis = Basis.from_euler( Vector3(0,0,deg_to_rad(-20) * wall_dot) )
	else:
		if model: model.basis = Basis()
	
	if last_is_wallrunning != is_wall_running:
		last_is_wallrunning = is_wall_running
	
	move_and_slide()
	
	
	# rotate to face walking direction
	if rotateToFaceMovement:
		var visualRotationBlend = 1-pow(0.5, delta * visualRotationLerpSpeed)
		if project_on_plane(velocity, up_direction).length() > 0.1: # input.length() > 0:
			#facing_angle = Vector2(velocity.z, velocity.x).angle()
			#model.rotation.y = lerp_angle(model.rotation.y, facing_angle, visualRotationLerpSpeed)
			global_basis = global_basis.slerp(Basis.looking_at(project_on_plane(velocity, up_direction), up_direction), visualRotationBlend)
		else:
			global_basis = global_basis.slerp(Basis.looking_at(global_basis * Vector3.FORWARD, up_direction), visualRotationBlend)
	
	
	## void out
	#if global_position.y < voidout_hight:
		#global_position.y += -voidout_hight * 2
		#if model: model.teleport()
		##game_over()
	
	
	# particles
	if particles_running:
		var collision_radius = 0.4
		var collision_height = 1.8
		var collision_normal = up_direction
		if is_on_floor():
			collision_normal = get_floor_normal()
		if is_wall_running:
			collision_normal = get_wall_normal()
		
		var pivot_pos = global_transform * (Vector3.DOWN * (collision_height/2 - collision_radius))
		var particle_pos = pivot_pos + -collision_normal * collision_radius
		particles_running.global_position = particle_pos
		
		if is_on_floor() or last_is_wallrunning:
			particles_running.amount_ratio = input.limit_length(1).length()
		else:
			particles_running.amount_ratio = 0
	
	
	# animation
	#if anim_player:
		#if (is_on_floor() and velocity.length() > 0) or is_wall_running: #if move_vector.length() > 0.1 and is_on_floor():
			##anim_player.play("Running", -1, input.limit_length(1).length() * 1.666)
			#anim_player.play("Running", .333, (velocity.length() / move_speed) * 1.666)
		#elif not is_on_floor() and not is_wall_running:
			#if anim_player.current_animation == "Jump":
				#anim_player.queue("Falling")
			#else:
				#anim_player.play("Falling", .1);
		#else:
			#anim_player.play("Idle", .333, .5)
	
	if anim_tree:
		anim_tree.set(ATV_grounded, (is_on_floor() or is_wall_running))
		anim_tree.set(ATV_jump_held, jump_held)
		anim_tree.set(ATV_move_blend, project_on_plane(velocity, up_direction).length() / move_speed)
		anim_tree.set(ATV_move_alpha, project_on_plane(velocity, up_direction).length() / move_speed)
	
	_jump_held_last_frame = jump_held

func _process(_delta: float) -> void:
	# void out
	if global_position.y < voidout_hight:
		global_position.y += -voidout_hight - 1
		if model: model.teleport()
		#game_over()

func game_over():
	get_tree().reload_current_scene()
