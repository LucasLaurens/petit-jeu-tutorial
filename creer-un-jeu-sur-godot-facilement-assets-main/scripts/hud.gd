class_name Hud
extends CanvasLayer

## Emitted when the player presses the Start button.
signal start_game

const STARTING_MESSAGE: String = "DODGE THE ENEMIES!"
const ENDING_MESSAGE: String = "GAME OVER!"
const START_BUTTON_DELAY: float = 1.0

@onready var _message: Label = $Message
@onready var _message_timer: Timer = $MessageTimer
@onready var _start_button: Button = $StartButton
@onready var _score_label: Label = $ScoreLabel


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
	_start_button.show()


func update_score(score: int) -> void:
	_score_label.text = str(score)


func _on_start_button_pressed() -> void:
	_start_button.hide()
	start_game.emit()


func _on_message_timer_timeout() -> void:
	_message.hide()
