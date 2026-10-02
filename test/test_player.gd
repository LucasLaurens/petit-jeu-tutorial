extends GutTest

const PLAYER_SCENE: PackedScene = preload(
	"res://creer-un-jeu-sur-godot-facilement-assets-main/scenes/player.tscn"
)
const FRAME_DELTA: float = 1.0 / 60.0
const FAR_FROM_EDGES: Vector2 = Vector2(5000, 5000)

var _player: Player


func before_each() -> void:
	_player = PLAYER_SCENE.instantiate()
	add_child_autofree(_player)
	# Frames are driven by hand so the engine never moves the player between steps.
	_player.set_process(false)
	_player.set_process_input(false)
	_player.screen_size = FAR_FROM_EDGES * 2
	_player.position = FAR_FROM_EDGES


func after_each() -> void:
	Input.action_release("move_left")


func test_moves_towards_held_finger() -> void:
	# Arrange
	var direction := Vector2.from_angle(randf_range(0, TAU))
	var finger := _player.position + direction * randf_range(100, 500)
	var expected := _player.position + direction * _player.speed * FRAME_DELTA
	_player._input(_build_touch(finger, true))

	# Act
	_player._process(FRAME_DELTA)

	# Assert
	assert_almost_eq(_player.position, expected, Vector2(0.01, 0.01))


func test_follows_finger_drag() -> void:
	# Arrange
	var start := _player.position
	_player._input(_build_touch(start + Vector2.LEFT * 200, true))
	var drag := InputEventScreenDrag.new()
	drag.position = start + Vector2.RIGHT * randf_range(100, 500)
	_player._input(drag)

	# Act
	_player._process(FRAME_DELTA)

	# Assert
	assert_gt(_player.position.x, start.x)


func test_stays_still_inside_dead_zone() -> void:
	# Arrange
	var start := _player.position
	var offset := randf_range(0, Player.TOUCH_DEAD_ZONE - 1)
	_player._input(_build_touch(start + Vector2.RIGHT * offset, true))

	# Act
	_player._process(FRAME_DELTA)

	# Assert
	assert_eq(_player.position, start)


func test_stops_when_finger_lifts() -> void:
	# Arrange
	var start := _player.position
	var finger := start + Vector2.DOWN * randf_range(100, 500)
	_player._input(_build_touch(finger, true))
	_player._input(_build_touch(finger, false))

	# Act
	_player._process(FRAME_DELTA)

	# Assert
	assert_eq(_player.position, start)


func test_keyboard_wins_over_finger() -> void:
	# Arrange
	var start := _player.position
	_player._input(_build_touch(start + Vector2.RIGHT * randf_range(100, 500), true))
	Input.action_press("move_left")

	# Act
	_player._process(FRAME_DELTA)

	# Assert
	assert_lt(_player.position.x, start.x)


func test_stays_inside_screen() -> void:
	# Arrange
	_player.screen_size = Vector2(randf_range(500, 1000), randf_range(500, 1000))
	_player.position = Vector2(_player.screen_size.x, _player.screen_size.y / 2)
	_player._input(_build_touch(_player.position + Vector2.RIGHT * 1000, true))

	# Act
	_player._process(FRAME_DELTA)

	# Assert
	assert_eq(_player.position.x, _player.screen_size.x)


func test_emits_hit_and_hides_on_collision() -> void:
	# Arrange
	var monster: Node2D = autofree(Node2D.new())
	_player.start(_player.position)
	watch_signals(_player)

	# Act
	_player._on_body_entered(monster)

	# Assert
	assert_signal_emitted(_player, "hit")
	assert_false(_player.visible)


func _build_touch(at: Vector2, pressed: bool) -> InputEventScreenTouch:
	var touch := InputEventScreenTouch.new()
	touch.position = at
	touch.pressed = pressed
	return touch
