extends Area3D
## Neon Speed Boost Pad.
## Launches the player ball forward at high velocity with audio-visual warp effect.

@export var boost_speed: float = 13.5
@export var boost_duration: float = 1.6
@export var boost_impulse: float = 6.0

var _cooldown: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta


func _on_body_entered(body: Node3D) -> void:
	if _cooldown > 0.0:
		return
	if body.has_method("apply_boost"):
		_cooldown = 0.5
		body.apply_boost(boost_speed, boost_duration, boost_impulse)
		GameManager.play_boost_sfx()
		_play_pulse()


func _play_pulse() -> void:
	var mesh_node := get_node_or_null("PadMesh") as MeshInstance3D
	if mesh_node:
		var tween := create_tween()
		tween.tween_property(mesh_node, "scale", Vector3(1.15, 1.8, 1.15), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(mesh_node, "scale", Vector3(1.0, 1.0, 1.0), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

