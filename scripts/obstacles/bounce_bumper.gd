extends Area3D
## Arcade Pinball Bounce Bumper.
## Blasts the ball backward or sideways with explosive impulse and squish animation.

@export var bounce_force: float = 14.0
@export var upward_pop: float = 2.8

@onready var _cap_mesh: MeshInstance3D = get_node_or_null("BumperCap")
@onready var _ring_mesh: MeshInstance3D = get_node_or_null("NeonRing")

var _bounce_cooldown: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if _bounce_cooldown > 0.0:
		_bounce_cooldown -= delta


func _on_body_entered(body: Node3D) -> void:
	if _bounce_cooldown > 0.0:
		return
	if body is RigidBody3D and body.name == "Ball":
		_bounce_cooldown = 0.25
		
		# Direction from bumper center to player ball
		var dir: Vector3 = body.global_position - global_position
		dir.y = 0.0
		if dir.length_squared() < 0.01:
			dir = Vector3(0.0, 0.0, 1.0)
		var norm: Vector3 = dir.normalized()
		
		# Apply authoritative explosive push
		body.linear_velocity.x = 0.0
		var impulse := norm * bounce_force + Vector3(0.0, upward_pop, 0.0)
		body.apply_central_impulse(impulse)
		
		GameManager.play_bounce_sfx()
		_play_squish_animation()


func _play_squish_animation() -> void:
	if _cap_mesh:
		var tween := create_tween()
		tween.tween_property(_cap_mesh, "scale", Vector3(1.3, 0.55, 1.3), 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(_cap_mesh, "scale", Vector3(1.0, 1.0, 1.0), 0.2).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

