extends Control
class_name Pause

@export_group("Pause Nodes")
@export var player: Player
@export var reticle: Control
@export var title: Label
@export var resume_button: Button
@export var quit_button: Button

var is_paused: bool = false

func _ready() -> void:
	title.text = ProjectSettings.get("application/config/name")
	visible = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed(player.keyboard_inputs.pause):
		if !is_paused:
			_pause()
		else:
			_resume()

	if event.is_action_pressed(player.keyboard_inputs.jump):
		if is_paused and resume_button.has_focus():
			_resume()
		elif is_paused and quit_button.has_focus():
			get_tree().quit()

func _pause() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	resume_button.grab_focus()
	visible = true
	reticle.visible = false
	get_tree().paused = true
	is_paused = true

func _resume() -> void:
	# wait at least a couple frames before resuming so player doesn't instantly jump
	await get_tree().create_timer(0.02).timeout		

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	visible = false
	reticle.visible = true
	get_tree().paused = false
	is_paused = false

func _on_resume_pressed() -> void:
	_resume()

func _on_quit_pressed() -> void:
	get_tree().quit()
