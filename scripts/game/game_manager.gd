extends Node
## Game state singleton and global coordinator.
## Loaded as the autoload singleton "GameManager".

var coins: int = 0
var score: int = 0
var total_coins: int = 14
var is_playing: bool = true

signal coins_changed(total: int)
signal score_changed(total: int)
signal game_over
signal level_complete

# Sound effects
var _sfx_coin: AudioStream = preload("res://assets/audio/coin.wav")
var _sfx_jump: AudioStream = preload("res://assets/audio/jump.wav")
var _sfx_game_over: AudioStream = preload("res://assets/audio/game_over.wav")
var _sfx_victory: AudioStream = preload("res://assets/audio/victory.wav")
var _sfx_boost: AudioStream = preload("res://assets/audio/boost.wav")
var _sfx_bounce: AudioStream = preload("res://assets/audio/bounce.wav")
var _sfx_slam: AudioStream = preload("res://assets/audio/slam.wav")

var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_index: int = 0


func _ready() -> void:
	for i in range(4):
		var p := AudioStreamPlayer.new()
		add_child(p)
		_sfx_players.append(p)
	reset()


func reset() -> void:
	coins = 0
	score = 0
	is_playing = true


func add_coin() -> void:
	coins += 1
	score += 10
	coins_changed.emit(coins)
	score_changed.emit(score)
	_play_sfx(_sfx_coin)


func play_jump_sfx() -> void:
	_play_sfx(_sfx_jump)


func play_boost_sfx() -> void:
	_play_sfx(_sfx_boost)


func play_bounce_sfx() -> void:
	_play_sfx(_sfx_bounce)


func play_slam_sfx() -> void:
	_play_sfx(_sfx_slam)


func trigger_game_over() -> void:
	if not is_playing:
		return
	is_playing = false
	game_over.emit()
	_play_sfx(_sfx_game_over)
	print("💀 GAME OVER — Score: %d, Coins: %d" % [score, coins])


func trigger_level_complete() -> void:
	if not is_playing:
		return
	is_playing = false
	score += 100
	score_changed.emit(score)
	level_complete.emit()
	_play_sfx(_sfx_victory)
	print("🏁 LEVEL COMPLETE — Score: %d, Coins: %d" % [score, coins])


func restart(tree: SceneTree = null) -> void:
	reset()
	if tree:
		tree.reload_current_scene()
	elif get_tree():
		get_tree().reload_current_scene()


func _play_sfx(stream: AudioStream) -> void:
	if stream and not _sfx_players.is_empty():
		var p := _sfx_players[_sfx_index]
		p.stream = stream
		p.play()
		_sfx_index = (_sfx_index + 1) % _sfx_players.size()
