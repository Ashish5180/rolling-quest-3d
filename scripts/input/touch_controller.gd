extends Node
## Handles all steering input: mouse drag (desktop), touch drag (mobile),
## accelerometer tilt (mobile gyro), and jump gestures (tap / swipe up).

@export var drag_sensitivity: float = 12.0  ## Mouse/touch drag responsiveness
@export var tilt_sensitivity: float = 4.0   ## Accelerometer divisor (lower = more sensitive)
@export var use_accelerometer: bool = true  ## Enable phone tilt steering

var _ball: RigidBody3D
var _drag_steer: float = 0.0

# Gesture detection for Jump
var _touch_start_time: int = 0
var _touch_start_pos: Vector2 = Vector2.ZERO
var _touch_distance: float = 0.0
const TAP_MAX_DURATION_MS: int = 250
const TAP_MAX_DIST_PX: float = 25.0
const SWIPE_UP_MIN_SPEED: float = -20.0


func _ready() -> void:
	_ball = get_parent() as RigidBody3D


func _unhandled_input(event: InputEvent) -> void:
	if not _ball or not GameManager.is_playing:
		return

	# --- Desktop Mouse Click / Drag ---
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_touch_start_time = Time.get_ticks_msec()
			_touch_start_pos = event.position
			_touch_distance = 0.0
		else:
			# If released quickly without significant dragging, trigger Jump!
			var duration := Time.get_ticks_msec() - _touch_start_time
			if duration < TAP_MAX_DURATION_MS and _touch_distance < TAP_MAX_DIST_PX:
				_ball.jump()
			_drag_steer = 0.0
		return

	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_touch_distance += event.relative.length()
		# Fast upward swipe triggers Jump
		if event.relative.y < SWIPE_UP_MIN_SPEED:
			_ball.jump()
		var vw := get_viewport().get_visible_rect().size.x
		_drag_steer = clampf(event.relative.x / vw * drag_sensitivity, -1.0, 1.0)
		return

	# --- Mobile Screen Touch / Drag ---
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_start_time = Time.get_ticks_msec()
			_touch_start_pos = event.position
			_touch_distance = 0.0
		else:
			var duration := Time.get_ticks_msec() - _touch_start_time
			if duration < TAP_MAX_DURATION_MS and _touch_distance < TAP_MAX_DIST_PX:
				_ball.jump()
			_drag_steer = 0.0
		return

	if event is InputEventScreenDrag:
		_touch_distance += event.screen_relative.length()
		# Fast upward swipe triggers Jump
		if event.screen_relative.y < SWIPE_UP_MIN_SPEED:
			_ball.jump()
		var vw := get_viewport().get_visible_rect().size.x
		_drag_steer = clampf(event.screen_relative.x / vw * drag_sensitivity, -1.0, 1.0)


func _physics_process(_delta: float) -> void:
	if not _ball:
		return

	var steer := _drag_steer

	# Accelerometer tilt — adds to drag on mobile, zero on desktop (no effect)
	if use_accelerometer:
		var accel := Input.get_accelerometer()
		if accel != Vector3.ZERO:
			steer += clampf(accel.x / tilt_sensitivity, -1.0, 1.0)

	_ball.touch_steering = clampf(steer, -1.0, 1.0)
