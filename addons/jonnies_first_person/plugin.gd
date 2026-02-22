@tool
extends EditorPlugin

func _enable_plugin() -> void:
	# Add Keyboard input actions
	add_action_event("move_left", create_key_event(KEY_A))
	add_action_event("move_right", create_key_event(KEY_D))
	add_action_event("move_forward", create_key_event(KEY_W))
	add_action_event("move_backward", create_key_event(KEY_S))
	add_action_event("jump", create_key_event(KEY_SPACE))
	add_action_event("walk", create_key_event(KEY_SHIFT))
	add_action_event("crouch", create_key_event(KEY_CTRL))
	add_action_event("pause", create_key_event(KEY_ESCAPE))
	add_action_event("interact", create_key_event(KEY_E))

	add_action_event("throw", create_mouse_event(MOUSE_BUTTON_LEFT))

	# Add Gamepad input actions
	add_action_event("move_left", create_joy_axis_event(JOY_AXIS_LEFT_X, -1.0))
	add_action_event("move_right", create_joy_axis_event(JOY_AXIS_LEFT_X, 1.0))
	add_action_event("move_forward", create_joy_axis_event(JOY_AXIS_LEFT_Y, -1.0))
	add_action_event("move_backward", create_joy_axis_event(JOY_AXIS_LEFT_Y, 1.0))
	add_action_event("look_left", create_joy_axis_event(JOY_AXIS_RIGHT_X, -1.0))
	add_action_event("look_right", create_joy_axis_event(JOY_AXIS_RIGHT_X, 1.0))
	add_action_event("look_up", create_joy_axis_event(JOY_AXIS_RIGHT_Y, -1.0))
	add_action_event("look_down", create_joy_axis_event(JOY_AXIS_RIGHT_Y, 1.0))
	add_action_event("throw", create_joy_axis_event(JOY_AXIS_TRIGGER_RIGHT, 1.0))
	add_action_event("walk", create_joy_axis_event(JOY_AXIS_TRIGGER_LEFT, 1.0))

	add_action_event("jump", create_joy_button_event(JOY_BUTTON_A))
	add_action_event("crouch", create_joy_button_event(JOY_BUTTON_B))
	add_action_event("interact", create_joy_button_event(JOY_BUTTON_X))
	add_action_event("pause", create_joy_button_event(JOY_BUTTON_START))
	
	ProjectSettings.save()

	# Give plugin time to map out inputs
	await get_tree().create_timer(1.25).timeout

	create_dialog_box("Jonnie's First Person: Input actions mapped to Project Settings! Press OK to restart editor.")

func _disable_plugin() -> void:
	var actions_to_remove: Array[String] = [
		"move_left", "move_right", "move_forward", "move_backward",
		"jump", "walk", "crouch", "pause", "interact", "throw",
		"look_left", "look_right", "look_up", "look_down"
	]
	for action in actions_to_remove:
		remove_action(action)

	ProjectSettings.save()

	#! BUG - When disabling plugin, we lose the ability to restart the editor automatically. So user will need to restart the editor manually for changes to take effect.

	create_dialog_box("Jonnie's First Person: Input actions removed from Project Settings. Restart editor manually or remove an input action for change to take effect.")

#region Event Helpers

func create_key_event(code: int) -> InputEventKey:
	var key_event: InputEventKey = InputEventKey.new()
	key_event.physical_keycode = code
	return key_event

func create_mouse_event(code: int) -> InputEventMouseButton:
	var mouse_event: InputEventMouseButton = InputEventMouseButton.new()
	mouse_event.button_index = code
	return mouse_event

func create_joy_button_event(code: int) -> InputEventJoypadButton:
	var joypad_button_event: InputEventJoypadButton = InputEventJoypadButton.new()
	joypad_button_event.button_index = code
	return joypad_button_event

func create_joy_axis_event(axis: int, value: float) -> InputEventJoypadMotion:
	var joy_axis_event: InputEventJoypadMotion = InputEventJoypadMotion.new()
	joy_axis_event.axis = axis
	joy_axis_event.axis_value = value
	return joy_axis_event

func create_dialog_box(text: String) -> void:
	var dialog: AcceptDialog = AcceptDialog.new()
	dialog.dialog_text = text
	get_editor_interface().get_base_control().add_child(dialog)
	dialog.popup_centered()

	# NOTE - Unfortunately Godot doesn't have an API to refresh the Input Map Project Settings tab directly.
	# So we need to restart the editor in order for changes to be visible. 

	# Confirm dialog box
	await dialog.confirmed
	# Restart editor
	get_editor_interface().restart_editor(true)

#endregion

#region Action Helpers

func add_action_event(action_name: String, event: InputEvent):
	var property: String = "input/" + action_name

	var action_data: Dictionary = ProjectSettings.get_setting(property, { "deadzone": 0.5, "events": [] })
	
	var already_has_event: bool = false
	for existing in action_data["events"]:
		if _is_same_input(existing, event):
			already_has_event = true
			break
	
	if not already_has_event:
		action_data["events"].append(event)
		ProjectSettings.set_setting(property, action_data)

		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
		InputMap.action_add_event(action_name, event)

func remove_action(action_name: String):
	var property: String = "input/" + action_name
	
	if ProjectSettings.has_setting(property):
		ProjectSettings.set_setting(property, null)
	
	if InputMap.has_action(action_name):
		InputMap.erase_action(action_name)

func _is_same_input(a: InputEvent, b: InputEvent) -> bool:
	if a.get_class() != b.get_class(): return false

	if a is InputEventKey and b is InputEventKey:
		return a.physical_keycode == b.physical_keycode
	if a is InputEventMouseButton and b is InputEventMouseButton:
		return a.button_index == b.button_index
	if a is InputEventJoypadButton and b is InputEventJoypadButton:
		return a.button_index == b.button_index
	if a is InputEventJoypadMotion and b is InputEventJoypadMotion:
		return a.axis == b.axis and sign(a.axis_value) == sign(b.axis_value)
	return false

#endregion

