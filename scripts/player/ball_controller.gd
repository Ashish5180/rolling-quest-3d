extends RigidBody3D
## Rolls the ball forward automatically and steers left/right from input.
## Uses proportional force control — never writes to position directly.

@export var forward_speed: float = 6.8    ## Target forward speed (units/sec) — controlled, high-stakes pace
@export var base_forward_speed: float = 6.8
@export var steer_speed: float = 4.8       ## Max lateral speed when fully steering
@export var forward_accel: float = 18.0    ## Force multiplier for forward correction
@export var lateral_accel: float = 28.0    ## Force multiplier for lateral correction
@export var jump_impulse: float = 3.6      ## Tight athletic hop impulse (prevents skipping tall obstacles)

## Touch steering input — set by touch_controller.gd (M2), 0.0 until then.
var touch_steering: float = 0.0

var _boost_time_left: float = 0.0
var _boost_duration: float = 1.6
var _boost_target_speed: float = 13.5

var _sfx_roll: AudioStream = preload("res://assets/audio/rolling.wav")
var _roll_player: AudioStreamPlayer = null


func _ready() -> void:
	_roll_player = AudioStreamPlayer.new()
	_roll_player.stream = _sfx_roll
	_roll_player.volume_db = -80.0
	add_child(_roll_player)
	_roll_player.play()


func _unhandled_input(event: InputEvent) -> void:
	if not GameManager.is_playing:
		return
	# Spacebar or Up Arrow on keyboard
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_up"):
		jump()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			jump()


func _physics_process(delta: float) -> void:
	if not GameManager.is_playing:
		if _roll_player:
			_roll_player.volume_db = -80.0
		return

	_update_boost(delta)
	_apply_forward()
	_apply_steering()
	_update_roll_audio()


func _update_roll_audio() -> void:
	if not _roll_player:
		return
	var grounded := is_grounded()
	if grounded and GameManager.is_playing:
		var speed := linear_velocity.length()
		_roll_player.pitch_scale = clampf(speed / 10.0, 0.7, 1.6)
		_roll_player.volume_db = lerpf(-26.0, -4.0, clampf(speed / 12.0, 0.0, 1.0))
		if not _roll_player.playing:
			_roll_player.play()
	else:
		_roll_player.volume_db = -80.0


func apply_boost(boost_target: float = 13.5, duration: float = 1.6, impulse: float = 6.0) -> void:
	_boost_target_speed = boost_target
	_boost_duration = duration
	_boost_time_left = duration
	forward_speed = boost_target
	if linear_velocity.y < 0.0:
		linear_velocity.y = 0.0
	apply_central_impulse(Vector3(0.0, 0.0, -impulse))


func _update_boost(delta: float) -> void:
	if _boost_time_left > 0.0:
		_boost_time_left -= delta
		var t := clampf(_boost_time_left / _boost_duration, 0.0, 1.0)
		forward_speed = lerpf(base_forward_speed, _boost_target_speed, t)
	else:
		forward_speed = base_forward_speed


func jump() -> void:
	if is_grounded():
		# Cancel any downward velocity so the jump height is always crisp and consistent
		linear_velocity.y = maxf(linear_velocity.y, 0.0)
		apply_central_impulse(Vector3(0.0, jump_impulse, 0.0))
		GameManager.play_jump_sfx()


func is_grounded() -> bool:
	var space_state := get_world_3d().direct_space_state
	# Radius is 0.45, so checking 0.55 reaches 0.1 below bottom of the ball
	var query := PhysicsRayQueryParameters3D.create(
		global_position,
		global_position + Vector3(0.0, -0.55, 0.0),
		collision_mask,
		[get_rid()]
	)
	var result := space_state.intersect_ray(query)
	return not result.is_empty()


func _apply_forward() -> void:
	# Ball moves in -Z direction. Positive speed_error = needs more force.
	var speed_error := forward_speed - (-linear_velocity.z)
	if speed_error > 0.0:
		# Clamped to 75.0 N so ball accelerates smoothly but cannot bulldozer through solid obstacles
		var force := clampf(speed_error * forward_accel, 0.0, 75.0)
		apply_central_force(Vector3(0.0, 0.0, -force))


func _apply_steering() -> void:
	# Keyboard (ui_left/ui_right = arrow keys) + touch input combined
	var steer_input := Input.get_axis("ui_left", "ui_right") + touch_steering
	steer_input = clampf(steer_input, -1.0, 1.0)

	# Proportional controller: force pushes lateral vel toward desired.
	var desired_lateral := steer_input * steer_speed
	var lateral_error := desired_lateral - linear_velocity.x
	apply_central_force(Vector3(lateral_error * lateral_accel, 0.0, 0.0))
