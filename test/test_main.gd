extends GutTest

const MAIN_SCENE: PackedScene = preload(
	"res://creer-un-jeu-sur-godot-facilement-assets-main/scenes/main.tscn"
)
const PHYSICS_FRAMES_TO_SETTLE: int = 5

var _main: Main


func before_each() -> void:
	_main = MAIN_SCENE.instantiate()
	add_child_autofree(_main)


func test_new_game_removes_leftover_monsters() -> void:
	# Arrange
	var leftovers: Array[Monster] = []
	for i in randi_range(1, 20):
		var monster: Monster = _main.monster_scene.instantiate()
		_main.add_child(monster)
		leftovers.append(monster)

	# Act
	_main.new_game()

	# Assert
	assert_true(
		leftovers.all(func(monster: Variant) -> bool: return not is_instance_valid(monster))
	)
	assert_eq(get_tree().get_nodes_in_group(Monster.GROUP).size(), 0)


func test_game_over_during_get_ready_cancels_the_round() -> void:
	# Arrange
	_main.new_game()

	# Act
	_main._on_game_over()

	# Assert
	assert_true(_main._start_timer.is_stopped())


func test_restart_over_a_leftover_monster_keeps_the_player_alive() -> void:
	# Arrange
	var monster: Monster = _main.monster_scene.instantiate()
	monster.position = _main._start_position.position
	_main.add_child(monster)
	watch_signals(_main._player)

	# Act
	_main.new_game()
	await wait_physics_frames(PHYSICS_FRAMES_TO_SETTLE)

	# Assert
	assert_signal_not_emitted(_main._player, "hit")
	assert_true(_main._player.visible)
