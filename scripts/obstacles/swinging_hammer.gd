extends AnimatableBody3D
## Giant swinging pendulum mallet.
## Swings back and forth across the track to swat the ball off the open edge.

@export var swing_speed: float = 2.2      ## Oscillation frequency
@export var max_swing_angle_deg: float = 48.0  ## Max swing deflection in degrees

var _time: float = 0.0
var _max_rad: float = 0.0


func _ready() -> void:
	_max_rad = deg_to_rad(max_swing_angle_deg)
	sync_to_physics = true


func _physics_process(delta: float) -> void:
	_time += delta * swing_speed
	# Rotates around Z axis like a grandfather clock pendulum
	rotation.z = sin(_time) * _max_rad

