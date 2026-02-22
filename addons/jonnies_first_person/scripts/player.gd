@icon("res://addons/jonnies_first_person/Player.svg")
extends CharacterBody3D
class_name Player

const MIN_VIEW_ANGLE: int = -90
const MAX_VIEW_ANGLE: int = 90

@export_group("Player Nodes")
@export var collision: CollisionShape3D
@export var camera: Camera3D
@export var footstep_detector: RayCast3D
@export var ceiling_detector: RayCast3D
@export var interact_detector: RayCast3D
@export var hold_position: Marker3D
@export var head_position: Node3D
@export var landing_animation: Node3D
@export var footstep_audio: AudioStreamPlayer
@export var reticle: Control

@export_group("Player Settings")
@export var run_speed: float = 5.0
@export var walk_speed: float = 2.5
@export var crouch_speed: float = 1.5
@export var crouch_depth: float = 0.5
@export var toggle_walk: bool = false
@export var toggle_crouch: bool = false
@export var motion_smoothing: bool = true
@export var motion_smoothing_amount: float = 10.0
@export var head_bob: bool = true
@export var head_bob_frequency: float = 3.0
@export var head_bob_amplitude: float = 0.04
@export var jump_velocity: float = 6.0
@export var out_of_bounds_y_threshold: float = -100.0
@export_subgroup("Advanced Player Settings")
@export var crouch_lerp_value: float = 0.1
@export var landing_velocity_threshold: float = 2.0
@export var landing_amplitude_value: float = 0.01
@export var min_landing_amplitude: float = 0.0
@export var max_landing_amplitude: float = 0.3

@export_group("Footstep Settings")
@export var footstep_user_library: Array[FootstepResource]
@export var footstep_default_sounds: Array[AudioStream]
@export var footstep_step_distance: float = 2.1
@export var randomize_footstep_pitch: bool = true
@export var randomize_footstep_volume: bool = true
@export var min_footstep_pitch: float = 0.95
@export var max_footstep_pitch: float = 1.05
@export var min_footstep_volume: float = -28.0
@export var max_footstep_volume: float = -23.0
@export var walk_footstep_volume: float = -30.0
@export var crouch_footstep_volume: float = -32.0

@export_group("Interact Settings")
@export var enable_reticle: bool = true
@export var max_carry_weight: float = 30.0	# In kilograms
@export var pull_power: float = 20.0
@export var force_drop_distance: float = 1.0
@export var throw_force: float = 15.0

@export_group("Input Settings")
@export var input_smoothing: bool = true
@export var input_smoothing_amount: float = 20.0
@export_subgroup("Keyboard Support")
@export_range(0.01, 1, 0.001) var mouse_sensitivity: float = 0.1
@export var keyboard_inputs: Dictionary = {
	move_left = 	"move_left",
	move_right = 	"move_right",
	move_forward = 	"move_forward",
	move_backward = "move_backward",
	jump = 			"jump",
	walk = 			"walk",
	crouch = 		"crouch",
	pause = 		"pause",
	interact = 		"interact",
	throw = 		"throw"
}

@export_subgroup("Gamepad Support")
@export var gamepad_support : bool = true
@export_range(0.01, 1, 0.001) var gamepad_sensitivity : float = 0.035
@export var gamepad_deadzone: float = 0.2
@export var invert_camera_y_axis: bool = false
@export var invert_camera_x_axis: bool = false
@export var gamepad_inputs: Dictionary = {
	look_left = 	"look_left",
	look_right = 	"look_right",
	look_up = 		"look_up",
	look_down = 	"look_down",
}

@onready var spawn_position: Vector3 = position
@onready var speed: float = run_speed
@onready var original_player_height: float = collision.shape.height

var distance: float
var landing_velocity: float
var head_bob_time: float
var target_rotation_x: float
var target_rotation_y: float

var footstep_name: String

var held_object: RigidBody3D = null

var is_walking: bool = false
var is_crouching: bool = false

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_check_input_actions()

#region Input

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var sensitivity_correction: float = 0.025
		target_rotation_y -= event.relative.x * mouse_sensitivity * sensitivity_correction
		target_rotation_x -= event.relative.y * mouse_sensitivity * sensitivity_correction
		target_rotation_x = clamp(target_rotation_x, deg_to_rad(MIN_VIEW_ANGLE), deg_to_rad(MAX_VIEW_ANGLE))

	if event.is_action_pressed(keyboard_inputs.interact):
		_handle_interaction()
	
	if event.is_action_pressed(keyboard_inputs.throw) and held_object:
		_throw_object()

#endregion

#region Physics Process

func _physics_process(delta: float) -> void:

	if not is_on_floor():
		velocity += get_gravity() * (delta * 2)
		landing_velocity = -velocity.y
		distance = 0.0

	elif is_on_floor():
		if landing_velocity != 0:
			_play_landing_animation(landing_velocity)
			landing_velocity = 0

		if Input.is_action_just_pressed(keyboard_inputs.jump) and is_on_floor():
			velocity.y = jump_velocity
			_play_random_footstep_sound()

		if toggle_walk:
			if Input.is_action_just_pressed(keyboard_inputs.walk):
				is_walking = !is_walking
				is_crouching = false
		else:
			is_walking = Input.is_action_pressed(keyboard_inputs.walk)
		
		if toggle_crouch:
			if Input.is_action_just_pressed(keyboard_inputs.crouch):
				is_crouching = !is_crouching
				is_walking = false
		else:
			is_crouching = Input.is_action_pressed(keyboard_inputs.crouch)
				
		if is_crouching:
			speed = crouch_speed
			footstep_audio.volume_db = crouch_footstep_volume	
			collision.shape.height = lerp(collision.shape.height, crouch_depth, crouch_lerp_value)
		elif is_walking:
			speed = walk_speed
			footstep_audio.volume_db = walk_footstep_volume
			collision.shape.height = lerp(collision.shape.height, original_player_height, crouch_lerp_value)
		else:
			speed = run_speed
			collision.shape.height = lerp(collision.shape.height, original_player_height, crouch_lerp_value)
		
		if ceiling_detector.is_colliding():
			speed = crouch_speed
			collision.shape.height = crouch_depth

	distance += get_real_velocity().length() * delta

	if distance >= footstep_step_distance:
		distance = 0.0
		if speed >= crouch_speed:
			_play_random_footstep_sound()

	if held_object:
		var target_position: Vector3 = hold_position.global_transform.origin
		var current_position: Vector3 = held_object.global_transform.origin

		var object_direction: Vector3 = target_position - current_position
		var object_distance: float = object_direction.length()

		held_object.linear_velocity = object_direction * pull_power

		if object_distance > force_drop_distance:
			_drop_object()

	var input_dir: Vector2 = Input.get_vector(keyboard_inputs.move_left, keyboard_inputs.move_right, keyboard_inputs.move_forward, keyboard_inputs.move_backward)
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if gamepad_support:
		var gamepad_view_rotation: Vector2 = Input.get_vector(
			gamepad_inputs.look_left, 
			gamepad_inputs.look_right, 
			gamepad_inputs.look_down, 
			gamepad_inputs.look_up,
			gamepad_deadzone
		)
	
		var yaw_input = gamepad_view_rotation.x * gamepad_sensitivity
		var pitch_input = gamepad_view_rotation.y * gamepad_sensitivity
		
		if invert_camera_x_axis: yaw_input *= -1.
		if invert_camera_y_axis: pitch_input *= -1.

		target_rotation_y -= yaw_input
		target_rotation_x += pitch_input
		target_rotation_x = clamp(target_rotation_x, deg_to_rad(MIN_VIEW_ANGLE), deg_to_rad(MAX_VIEW_ANGLE))

	if direction:
		if motion_smoothing:
			velocity.x = lerp(velocity.x, direction.x * speed, motion_smoothing_amount * delta)
			velocity.z = lerp(velocity.z, direction.z * speed, motion_smoothing_amount * delta)
		else:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	_check_reticle_visible()

	_check_player_out_of_bounds()
	
	_apply_input_smoothing(delta)

	_handle_head_bob(delta)

	move_and_slide()

#endregion

#region Check Funcs

func _check_input_actions() -> void:
	var input_actions: Array[String] = [
		keyboard_inputs.move_left,
		keyboard_inputs.move_right,
		keyboard_inputs.move_forward,
		keyboard_inputs.move_backward,
		keyboard_inputs.jump,
		keyboard_inputs.walk,
		keyboard_inputs.crouch,
		keyboard_inputs.pause,
		keyboard_inputs.interact,
		keyboard_inputs.throw,

		gamepad_inputs.look_left,
		gamepad_inputs.look_right,
		gamepad_inputs.look_up,
		gamepad_inputs.look_down
	]

	var check_passed: bool = true

	for action in input_actions.size():
		if !InputMap.has_action(input_actions[action]):
			printerr(input_actions[action] + " action is missing!")
			check_passed = false

	if !check_passed:
		print("Input Map is not set up correctly. Either enable the plugin in Project Settings or add missing actions manually.")
		print("Press F8 to stop currently running project")

func _check_reticle_visible() -> void:
	if enable_reticle:
		reticle.visible = true
	else:
		reticle.visible = false

func _check_player_out_of_bounds() -> void:
	if position.y < out_of_bounds_y_threshold:
		position = spawn_position

#endregion

#region Interact

func _handle_interaction() -> void:
	# Interaction is handled based on whether a CollisionObject3D has an interact() function,
	# or if it's a RigidBody3D that weighs under the Player's max carry weight.

	if interact_detector.is_colliding():
		var target = interact_detector.get_collider()

		if target.has_method("interact"):
			target.interact()
		
		if target is RigidBody3D and target.mass < max_carry_weight:
			if !held_object:
				_pick_up_object()
			else:
				_drop_object()

func _pick_up_object() -> void:
	var object = interact_detector.get_collider()
	if object is RigidBody3D and object.mass < max_carry_weight:
		held_object = object
		held_object.lock_rotation = true
		held_object.gravity_scale = 0.0

func _drop_object() -> void:
	if held_object:
		held_object.lock_rotation = false
		held_object.gravity_scale = 1.0
		held_object = null

func _throw_object() -> void:
	var throw_direction: Vector3 = -camera.global_transform.basis.z

	held_object.lock_rotation = false
	held_object.gravity_scale = 1.0
	held_object.remove_collision_exception_with(self)

	held_object.apply_central_impulse(throw_direction * throw_force)

	held_object = null

#endregion

#region Smoothing

func _apply_input_smoothing(delta: float) -> void:
	if input_smoothing:
		rotation.y = lerp_angle(rotation.y, target_rotation_y, input_smoothing_amount * delta)
		camera.rotation.x = lerp_angle(camera.rotation.x, target_rotation_x, input_smoothing_amount * delta)
	else:
		rotation.y = target_rotation_y
		camera.rotation.x = target_rotation_x

#endregion

#region Head Bob

func _handle_head_bob(delta: float) -> void:
	if head_bob:
		if is_on_floor() and velocity.length() > 0.1:
			head_bob_time += delta * velocity.length() * float(is_on_floor())
			camera.transform.origin = _head_bob_calculation(head_bob_time)

func _head_bob_calculation(time: float) -> Vector3:
	var head_position = Vector3.ZERO
	head_position.y = sin(time * head_bob_frequency) * head_bob_amplitude
	head_position.x = cos(time * head_bob_frequency / 2) * head_bob_amplitude
	return head_position

#endregion

#region Play Functions

func _play_landing_animation(landing_velocity: float) -> void:
	if landing_velocity >= landing_velocity_threshold:
		_play_random_footstep_sound()

	var tween: Tween = get_tree().create_tween().set_trans(Tween.TRANS_SINE)
	var amplitude: float = clamp(landing_velocity * landing_amplitude_value, min_landing_amplitude, max_landing_amplitude)

	tween.tween_property(landing_animation, "position:y", -amplitude, amplitude)
	tween.tween_property(landing_animation, "position:y", 0, amplitude)

func _play_random_footstep_sound() -> void:

	if footstep_detector.is_colliding():

		if footstep_detector.get_collider() is FootstepBody3D:

			footstep_name = footstep_detector.get_collider().footstep_type

			for footstep_resource in footstep_user_library.size():
				match footstep_user_library[footstep_resource].footstep_name:
					footstep_name:
						footstep_audio.stream = footstep_user_library[footstep_resource].footstep_sounds.pick_random()

		elif footstep_default_sounds.size() != 0:
			footstep_audio.stream = footstep_default_sounds.pick_random()

	if randomize_footstep_pitch:
		footstep_audio.pitch_scale = randf_range(min_footstep_pitch, max_footstep_pitch)

	if randomize_footstep_volume:
		footstep_audio.volume_db = randf_range(max_footstep_volume, min_footstep_volume)

	footstep_audio.play()

#endregion
