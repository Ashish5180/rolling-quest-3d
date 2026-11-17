extends Node3D
## Hydraulic Piston Slammer.
## A heavy industrial wall pusher that telegraphs with a flashing beacon,
## then suddenly shoots across the track, violently slamming the ball into the abyss.

enum State { RETRACTED, WARNING, SLAM, HOLD, RETRACT }

@export var push_from_left: bool = true     ## If true, mounted on left and pushes right (+X). If false, pushes left (-X).
@export var stroke_distance: float = 4.2    ## How far across the track the piston extends (meters).
@export var punch_force: float = 20.0       ## Lateral impulse applied to the ball on impact.
@export var cycle_offset: float = 0.0:      ## Initial time delay to stagger multiple pushers.
	set(val):
		cycle_offset = val
		_timer = val

@export var time_retracted: float = 1.3     ## Rest time between punches.
@export var time_warning: float = 0.45      ## Windup warning time (beacon flashes red).
@export var time_slam: float = 0.12         ## Lightning-fast extension stroke.
@export var time_hold: float = 0.35         ## Time held fully extended.
@export var time_retract: float = 0.7       ## Time to smoothly pull back.

var _state: State = State.RETRACTED
var _timer: float = 0.0

@onready var _head: Node3D = $PistonHead
@onready var _rod: Node3D = $PistonRod
@onready var _beacon_mat: StandardMaterial3D = null
@onready var _hit_area: Area3D = $PistonHead/HitArea


func get_dir() -> float:
	return 1.0 if push_from_left else -1.0


func _ready() -> void:
	_timer = cycle_offset
	
	# Fetch warning beacon material
	var beacon_mesh := get_node_or_null("Housing/WarningBeacon") as MeshInstance3D
	if beacon_mesh:
		_beacon_mat = beacon_mesh.get_surface_override_material(0)
		if not _beacon_mat:
			_beacon_mat = StandardMaterial3D.new()
			beacon_mesh.set_surface_override_material(0, _beacon_mat)
	
	if _hit_area:
		_hit_area.body_entered.connect(_on_hit_body_entered)
	
	_set_beacon_color(Color(1.0, 0.7, 0.1), 0.8) # Amber rest


func _physics_process(delta: float) -> void:
	_timer += delta
	var dir := get_dir()
	
	match _state:
		State.RETRACTED:
			_head.position.x = 0.0
			_update_rod()
			if _timer >= time_retracted:
				_state = State.WARNING
				_timer = 0.0
				_set_beacon_color(Color(1.0, 0.05, 0.05), 3.0)

		State.WARNING:
			# Subtle jitter/windup shake
			var shake := sin(_timer * 35.0) * 0.04 * dir
			_head.position.x = shake
			_update_rod()
			if _timer >= time_warning:
				_state = State.SLAM
				_timer = 0.0
				GameManager.play_slam_sfx()
				_check_instant_punch()

		State.SLAM:
			var t := clampf(_timer / time_slam, 0.0, 1.0)
			# Fast cubic ease-in punch
			var progress := t * t * t
			_head.position.x = progress * stroke_distance * dir
			_update_rod()
			if _timer >= time_slam:
				_state = State.HOLD
				_timer = 0.0

		State.HOLD:
			_head.position.x = stroke_distance * dir
			_update_rod()
			if _timer >= time_hold:
				_state = State.RETRACT
				_timer = 0.0
				_set_beacon_color(Color(1.0, 0.7, 0.1), 0.8)

		State.RETRACT:
			var t := clampf(_timer / time_retract, 0.0, 1.0)
			# Smooth ease-out retraction
			var progress := 1.0 - (1.0 - (1.0 - t) * (1.0 - t))
			_head.position.x = (1.0 - progress) * stroke_distance * dir
			_update_rod()
			if _timer >= time_retract:
				_state = State.RETRACTED
				_timer = 0.0
				_head.position.x = 0.0
				_update_rod()


func _update_rod() -> void:
	if _rod and _head:
		var dist := absf(_head.position.x)
		_rod.scale.x = maxf(0.01, dist)
		_rod.position.x = _head.position.x * 0.5


func _check_instant_punch() -> void:
	if not _hit_area:
		return
	for body in _hit_area.get_overlapping_bodies():
		_punch_body(body)


func _on_hit_body_entered(body: Node3D) -> void:
	if _state == State.SLAM or _state == State.HOLD:
		_punch_body(body)


func _punch_body(body: Node3D) -> void:
	if body is RigidBody3D and body.name == "Ball":
		var dir := get_dir()
		var lateral_vel := dir * punch_force
		body.linear_velocity.x = lateral_vel
		body.apply_central_impulse(Vector3(lateral_vel * 0.9, 2.8, -1.5))
		GameManager.play_slam_sfx()


func _set_beacon_color(col: Color, emission_mult: float) -> void:
	if _beacon_mat:
		_beacon_mat.albedo_color = col
		_beacon_mat.emission_enabled = true
		_beacon_mat.emission = col
		_beacon_mat.emission_energy_multiplier = emission_mult

