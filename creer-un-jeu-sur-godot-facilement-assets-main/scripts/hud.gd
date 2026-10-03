class_name Hud
extends CanvasLayer

## Emitted when the player presses the Start button.
signal start_game

const STARTING_MESSAGE: String = "DODGE THE ENEMIES!"
const ENDING_MESSAGE: String = "GAME OVER!"
const START_BUTTON_DELAY: float = 1.0
## The logo floats up and down like the ghost it shows.
const LOGO_FLOAT_HEIGHT: float = 20.0
const LOGO_FLOAT_DURATION: float = 1.2

@onready var _logo: TextureRect = $Logo
@onready var _message: Label = $Message
@onready var _message_timer: Timer = $MessageTimer
@onready var _start_button: Button = $StartButton
@onready var _score_label: Label = $ScoreLabel


func _ready() -> void:
	var float_tween := create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	(
		float_tween
		. tween_property(_logo, "position:y", -LOGO_FLOAT_HEIGHT, LOGO_FLOAT_DURATION)
		. as_relative()
	)
	(
		float_tween
		. tween_property(_logo, "position:y", LOGO_FLOAT_HEIGHT, LOGO_FLOAT_DURATION)
		. as_relative()
	)


func show_message(text: String) -> void:
	_message.text = text
	_message.show()
	_message_timer.start()


func show_game_over_message() -> void:
	show_message(ENDING_MESSAGE)
	await _message_timer.timeout

	_message.text = STARTING_MESSAGE
	_message.show()

	await get_tree().create_timer(START_BUTTON_DELAY).timeout
	_show_title_screen()


func update_score(score: int) -> void:
	_score_label.text = str(score)


func _show_title_screen() -> void:
	_logo.show()
	_start_button.show()


func _on_start_button_pressed() -> void:
	_logo.hide()
	_start_button.hide()
	start_game.emit()


func _on_message_timer_timeout() -> void:
	_message.hide()
