extends Area3D
## Dynamic Crosswind Zone.
## Exerts lateral force on the ball, requiring counter-steering to avoid falling into the ocean.

@export var wind_force_x: float = 18.0    ## Direction and strength of the crosswind (positive = right, negative = left)
@export var gust_amplitude: float = 6.0   ## Oscillating gust variance
@export var gust_frequency: float = 2.5   ## Gust oscillation frequency (rad/s)

var _ball_inside: RigidBody3D = null
var _time: float = 0.0

@onready var _streamers: Node3D = get_node_or_null("Streamers")


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _physics_process(delta: float) -> void:
	_time += delta
	if _ball_inside and GameManager.is_playing:
		var current_gust := wind_force_x + sin(_time * gust_frequency) * gust_amplitude
		_ball_inside.apply_central_force(Vector3(current_gust, 0.0, 0.0))
	
	# Scroll visual wind streamers laterally across track
	if _streamers:
		for child in _streamers.get_children():
			if child is Node3D:
				var sign_dir := 1.0 if wind_force_x >= 0.0 else -1.0
				child.position.x += sign_dir * delta * 7.0
				if absf(child.position.x) > 3.5:
					child.position.x = -sign_dir * 3.5


func _on_body_entered(body: Node3D) -> void:
	if body is RigidBody3D and body.name == "Ball":
		_ball_inside = body


func _on_body_exited(body: Node3D) -> void:
	if body == _ball_inside:
		_ball_inside = null

