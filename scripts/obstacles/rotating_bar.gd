extends AnimatableBody3D
## Rotates continuously around the Y axis.
## Swings across the track to swat or block the ball.

@export var rotation_speed: float = 2.0  ## Radians per second


func _ready() -> void:
	sync_to_physics = true


func _physics_process(delta: float) -> void:
	rotate_y(rotation_speed * delta)

