extends Camera3D

@export var player: Player
@export var motion_blur_shader: Shader

var previous_position: Vector3
var previous_basis: Basis = Basis()
var current_blur: Vector2
var blur_overlay: ColorRect

func _ready() -> void:
	blur_overlay = ColorRect.new()
	blur_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	blur_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var shader_material: ShaderMaterial = ShaderMaterial.new()
	shader_material.shader = motion_blur_shader
	shader_material.set_shader_parameter("samples", player.motion_blur_samples)
	blur_overlay.material = shader_material
	
	var canvas_layer: CanvasLayer = CanvasLayer.new()
	add_child(canvas_layer)
	canvas_layer.add_child(blur_overlay)
	
	previous_position = global_position
	previous_basis = global_transform.basis

func _physics_process(delta: float) -> void:

	if player.motion_blur:

		if delta <= 0: 
			return

		var linear_velocity: Vector3 = (global_position - previous_position) / delta

		var delta_basis: Basis = previous_basis.inverse() * global_transform.basis
		var delta_quaternion: Quaternion = Quaternion(delta_basis)
		var angular_velocity: Vector3 = Vector3.ZERO

		if abs(delta_quaternion.w) < 1.0:
			var half_angle: float = acos(clamp(delta_quaternion.w, -1.0, 1.0))
			if half_angle > 0.0001:
				var sin_half: float = sin(half_angle)
				angular_velocity = Vector3(delta_quaternion.x, delta_quaternion.y, delta_quaternion.z) / sin_half * (2.0 * half_angle / delta)

		var local_velocity: Vector3 = global_transform.basis.inverse() * linear_velocity

		var raw_blur: Vector2 = Vector2(
			-angular_velocity.y - local_velocity.x,
			angular_velocity.x + local_velocity.y
		) * player.motion_blur_strength * delta

		var time: float = 1.0 - pow(player.motion_blur_smoothing, delta * 60.0)
		current_blur = current_blur.lerp(raw_blur, time)

		var material: ShaderMaterial = blur_overlay.material as ShaderMaterial
		material.set_shader_parameter("blur_direction", current_blur)

		previous_position = global_position
		previous_basis = global_transform.basis
