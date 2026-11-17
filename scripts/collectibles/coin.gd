extends Area3D
## Realistic floating arcade coin with gold luster, smooth rotation, and vertical hover.

@export var spin_speed: float = 2.5  ## Radians per second
@export var bob_amplitude: float = 0.08
@export var bob_speed: float = 3.5

var _base_y: float = 0.0
var _time: float = 0.0


func _ready() -> void:
	_base_y = position.y
	# Randomize starting angle so coins along the track aren't in robotic unison
	rotate_y(randf_range(0.0, TAU))
	body_entered.connect(_on_collected)


func _physics_process(delta: float) -> void:
	_time += delta
	rotate_y(spin_speed * delta)
	position.y = _base_y + sin(_time * bob_speed) * bob_amplitude


func _on_collected(body: Node3D) -> void:
	if body.name == "Ball":
		GameManager.add_coin()
		queue_free()
