@icon("res://addons/weather-3d/weather_3d.svg")
@tool
extends Node3D
class_name Weather3D

@export_enum("Clear", "Overcast", "Light Rain", "Heavy Rain", "Thunderstorm", "Light Snow", "Heavy Snow") var weather_type = 0
@export_group("Weather Nodes")
@export var world_environment: WorldEnvironment
@export var rain: Node3D
@export var rain_particles: GPUParticles3D
@export var puddle: MeshInstance3D
@export var lightning: DirectionalLight3D
@export var snow: Node3D
@export var snow_particles: GPUParticles3D
@export_group("Environments")
@export var clear_environment: Environment
@export var overcast_environment: Environment
@export var light_rain_environment: Environment
@export var heavy_rain_environment: Environment
@export var thunderstorm_environment: Environment
@export var light_snow_environment: Environment
@export var heavy_snow_environment: Environment
@export_group("Sounds")
@export var clear_sound: AudioStreamPlayer
@export var rain_sound: AudioStreamPlayer
@export var thunder_sound: AudioStreamPlayer
@export var snow_sound: AudioStreamPlayer
@export_group("Rain Settings")
@export var light_rain_amount: int = 1500
@export var heavy_rain_amount: int = 10250
@export var light_rain_volume: float = -12.0
@export var heavy_rain_volume: float = -8.0
@export var thunder_storm_volume: float = -7.0
@export_group("Lightning Settings")
@export var lightning_wait_duration_min: float = 0.05
@export var lightning_wait_duration_max: float = 15.0
@export var lightning_flash_duration_min: float = 0.01
@export var lightning_flash_duration_max: float = 0.2
@export var lightning_wait_duration: Timer
@export_group("Snow Settings")
@export var light_snow_amount: int = 2750
@export var heavy_snow_amount: int = 37500
@export var light_snow_volume: float = -10.0
@export var heavy_snow_volume: float = -6.0

var lightning_timer_started: bool = false

var rand_wait_duration: float
var rand_flash_duration: float

func _process(_delta: float) -> void:
	match weather_type:
		0: # Clear
			world_environment.environment = clear_environment
			rain.visible = false
			snow.visible = false
			_stop_thunderstorm()
			if !Engine.is_editor_hint():
				_play_clear_sound()
		1: # Overcast
			world_environment.environment = overcast_environment
			rain.visible = false
			snow.visible = false
			_stop_thunderstorm()
			if !Engine.is_editor_hint():
				_play_clear_sound()
		2: # Light Rain
			world_environment.environment = light_rain_environment
			rain.visible = true
			snow.visible = false
			rain_particles.amount = light_rain_amount
			rain_sound.volume_db = light_rain_volume
			_stop_thunderstorm()
			if !Engine.is_editor_hint():
				_play_rain_sound()
		3: # Heavy Rain
			world_environment.environment = heavy_rain_environment
			rain.visible = true
			snow.visible = false
			rain_particles.amount = heavy_rain_amount
			rain_sound.volume_db = heavy_rain_volume
			_stop_thunderstorm()
			if !Engine.is_editor_hint():
				_play_rain_sound()
		4: # Thunderstorm
			world_environment.environment = thunderstorm_environment
			rain.visible = true
			snow.visible = false
			rain_particles.amount = heavy_rain_amount
			rain_sound.volume_db = thunder_storm_volume
			_start_thunderstorm()
			if !Engine.is_editor_hint():
				_play_thunderstorm_sound()
		5: # Light Snow
			world_environment.environment = light_snow_environment
			rain.visible = false
			snow.visible = true
			snow_particles.amount = light_snow_amount
			snow_sound.volume_db = light_snow_volume
			_stop_thunderstorm()
			if !Engine.is_editor_hint():
				_play_snow_sound()
		6: # Heavy Snow
			world_environment.environment = heavy_snow_environment
			rain.visible = false
			snow.visible = true
			snow_particles.amount = heavy_snow_amount
			snow_sound.volume_db = heavy_snow_volume
			_stop_thunderstorm()
			if !Engine.is_editor_hint():
				_play_snow_sound()

#region Weather Sounds

func _play_clear_sound() -> void:
	if !clear_sound.is_playing():
		clear_sound.play()
	rain_sound.stop()
	thunder_sound.stop()
	snow_sound.stop()

func _play_rain_sound() -> void:
	if !rain_sound.is_playing():
		rain_sound.play()
	clear_sound.stop()
	thunder_sound.stop()
	snow_sound.stop()

func _play_snow_sound() -> void:
	if !snow_sound.is_playing():
		snow_sound.play()
	clear_sound.stop()
	rain_sound.stop()
	thunder_sound.stop()

func _play_thunderstorm_sound() -> void:
	if !thunder_sound.is_playing():
		thunder_sound.play()
	if !rain_sound.is_playing():
		rain_sound.play()

	clear_sound.stop()
	snow_sound.stop()

#endregion

#region Lightning

func _start_thunderstorm() -> void:
	if !lightning_timer_started:
		lightning_wait_duration.start()
		lightning_timer_started = true

func _stop_thunderstorm() -> void:
	lightning_wait_duration.stop()
	lightning_timer_started = false
	lightning.visible = false

func _on_lightning_wait_duration_timeout() -> void:
	# Start flash
	lightning.visible = true
	rand_flash_duration = randf_range(lightning_flash_duration_min, lightning_flash_duration_max)
	await get_tree().create_timer(rand_flash_duration).timeout
	lightning.visible = false

	# Start wait for next flash
	rand_wait_duration = randf_range(lightning_wait_duration_min, lightning_wait_duration_max)
	lightning_wait_duration.wait_time = rand_wait_duration
	lightning_wait_duration.start()

#endregion