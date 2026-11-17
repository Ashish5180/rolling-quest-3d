extends CanvasLayer
## In-game HUD, Live Coin/Score display, and Game Over / Victory / Pause overlays.

@onready var coin_label: Label = $SafeMargin/Header/CoinHBox/CoinLabel
@onready var score_label: Label = $SafeMargin/Header/ScoreHBox/ScoreLabel
@onready var pause_btn: Button = $SafeMargin/Header/PauseButton

@onready var game_over_panel: Control = $GameOverPanel
@onready var game_over_stats: Label = $GameOverPanel/CenterContainer/VBox/StatsLabel
@onready var retry_btn: Button = $GameOverPanel/CenterContainer/VBox/RetryButton

@onready var victory_panel: Control = $VictoryPanel
@onready var victory_stats: Label = $VictoryPanel/CenterContainer/VBox/StatsLabel
@onready var play_again_btn: Button = $VictoryPanel/CenterContainer/VBox/PlayAgainButton

@onready var pause_panel: Control = $PausePanel
@onready var resume_btn: Button = $PausePanel/CenterContainer/VBox/ResumeButton
@onready var pause_restart_btn: Button = $PausePanel/CenterContainer/VBox/RestartButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # Keeps UI interactive during pause

	# Hide overlays initially
	game_over_panel.visible = false
	victory_panel.visible = false
	pause_panel.visible = false

	# Connect button callbacks
	pause_btn.pressed.connect(_on_pause_pressed)
	retry_btn.pressed.connect(_on_retry_pressed)
	play_again_btn.pressed.connect(_on_retry_pressed)
	resume_btn.pressed.connect(_on_resume_pressed)
	pause_restart_btn.pressed.connect(_on_retry_pressed)

	# Connect to GameManager events
	GameManager.coins_changed.connect(_on_coins_changed)
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.game_over.connect(_on_game_over)
	GameManager.level_complete.connect(_on_level_complete)

	# Initialize values
	_on_coins_changed(GameManager.coins)
	_on_score_changed(GameManager.score)


func _on_coins_changed(total: int) -> void:
	coin_label.text = "🪙 %d" % total


func _on_score_changed(total: int) -> void:
	score_label.text = "🏆 %d" % total


func _on_game_over() -> void:
	game_over_stats.text = "Score: %d  •  Coins: %d" % [GameManager.score, GameManager.coins]
	game_over_panel.visible = true


func _on_level_complete() -> void:
	victory_stats.text = "Final Score: %d  •  Coins: %d / %d" % [GameManager.score, GameManager.coins, GameManager.total_coins]
	victory_panel.visible = true


func _on_pause_pressed() -> void:
	get_tree().paused = true
	pause_panel.visible = true


func _on_resume_pressed() -> void:
	get_tree().paused = false
	pause_panel.visible = false


func _on_retry_pressed() -> void:
	get_tree().paused = false
	GameManager.restart(get_tree())

