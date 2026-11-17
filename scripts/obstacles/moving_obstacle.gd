extends AnimatableBody3D
## Moves horizontally back and forth across the track.
## Uses sync_to_physics to ensure accurate physical collision with RigidBody3D.

@export var move_distance: float = 0.85 ## Distance to move left/right from origin
@export var move_speed: float = 2.4     ## Oscillation speed

var _start_x: float = 0.0
var _time: float = 0.0


func _ready() -> void:
	_start_x = position.x
	sync_to_physics = true


func _physics_process(delta: float) -> void:
	_time += delta * move_speed
	position.x = _start_x + sin(_time) * move_distance

