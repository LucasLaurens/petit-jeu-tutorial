extends Node

const MONSTER_MIN_SPEED: float = 150.0
const MONSTER_MAX_SPEED: float = 250.0
const STARTING_MESSAGE: String = "GET READY!"

@export var monster_scene: PackedScene

var score: int

@onready var _player: Player = $Player
@onready var _start_position: Marker2D = $StartPosition
@onready var _start_timer: Timer = $StartTimer
@onready var _score_timer: Timer = $ScoreTimer
@onready var _monster_timer: Timer = $MonsterTimer
@onready var _spawn_location: PathFollow2D = $MonsterPath/MonsterSpawnLocation
@onready var _hud: Hud = $HUD
@onready var _music: AudioStreamPlayer = $Music
@onready var _game_over_sound: AudioStreamPlayer = $GameOverSound


func _on_game_over() -> void:
	_music.stop()
	_game_over_sound.play()
	_score_timer.stop()
	_monster_timer.stop()
	_hud.show_game_over_message()


func new_game() -> void:
	_music.play()
	score = 0
	_player.start(_start_position.position)
	_start_timer.start()
	_hud.update_score(score)
	_hud.show_message(STARTING_MESSAGE)


func _on_start_timer_timeout() -> void:
	_monster_timer.start()
	_score_timer.start()


func _on_score_timer_timeout() -> void:
	score += 1
	_hud.update_score(score)


func _on_monster_timer_timeout() -> void:
	var new_monster: Monster = monster_scene.instantiate()

	_spawn_location.progress_ratio = randf()
	new_monster.position = _spawn_location.position

	# The path runs along the screen edge; a quarter turn points the monster inwards.
	var direction := _spawn_location.rotation + PI / 2
	var velocity := Vector2(randf_range(MONSTER_MIN_SPEED, MONSTER_MAX_SPEED), 0.0)
	new_monster.linear_velocity = velocity.rotated(direction)

	add_child(new_monster)
