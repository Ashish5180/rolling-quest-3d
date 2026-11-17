extends Node3D
## Oscillating Sweeper Wiper.
## A heavy motorized sweeper blade that sweeps back and forth across the track,
## physically sweeping any ball in its path straight into the ocean void.

@export var sweep_speed: float = 2.4        ## Sweep oscillation speed (rad/sec)
@export var min_angle_deg: float = 0.0      ## Angle when resting along the edge (parallel to track)
@export var max_angle_deg: float = 88.0     ## Angle when fully swept across the track
@export var sweep_force: float = 22.0       ## Shove impulse applied to ball on contact
@export var sweep_to_right: bool = true     ## Direction to fling ball on contact
@export var start_offset: float = 0.0:      ## Phase offset for timing
	set(val):
		start_offset = val
		_time = val

var _time: float = 0.0
@onready var _arm: Node3D = $WiperArm
@onready var _hit_area: Area3D = $WiperArm/HitArea


func _ready() -> void:
	_time = start_offset
	if _hit_area:
		_hit_area.body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	_time += delta
	# Sine wave sweep between min and max angle
	var wave := (sin(_time * sweep_speed) + 1.0) * 0.5
	var angle_deg := lerpf(min_angle_deg, max_angle_deg, wave)
	_arm.rotation.y = deg_to_rad(angle_deg)


func _on_body_entered(body: Node3D) -> void:
	if body is RigidBody3D and body.name == "Ball":
		var push_sign := 1.0 if sweep_to_right else -1.0
		body.linear_velocity.x = push_sign * sweep_force
		body.apply_central_impulse(Vector3(push_sign * sweep_force, 2.5, -2.0))
		GameManager.play_slam_sfx()

