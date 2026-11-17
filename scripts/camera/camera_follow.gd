extends Camera3D
## Follows the ball from behind and above with smooth interpolation.
## Looks ahead of the ball for better forward visibility.

@export var target: NodePath              ## Path to the ball node
@export var offset := Vector3(0.0, 5.0, 8.0)   ## Position offset from ball
@export var smooth_speed: float = 5.0     ## Position lerp weight
@export var look_ahead: float = 3.0       ## How far ahead of ball to look (units)

var _target_node: Node3D


func _ready() -> void:
	_target_node = get_node_or_null(target)
	if _target_node:
		global_position = _target_node.global_position + offset
		look_at(_target_node.global_position + Vector3(0, 0, -look_ahead), Vector3.UP)


func _physics_process(delta: float) -> void:
	if not _target_node:
		return
	var desired_pos := _target_node.global_position + offset
	global_position = global_position.lerp(desired_pos, smooth_speed * delta)
	# Look ahead of the ball — gives the player visibility of upcoming track
	var look_target := _target_node.global_position + Vector3(0, 0, -look_ahead)
	look_at(look_target, Vector3.UP)
