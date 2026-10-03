extends GutTest

const HUD_SCENE: PackedScene = preload(
	"res://creer-un-jeu-sur-godot-facilement-assets-main/scenes/hud.tscn"
)

var _hud: Hud


func before_each() -> void:
	_hud = HUD_SCENE.instantiate()
	add_child_autofree(_hud)


func test_title_screen_shows_logo_and_start_button() -> void:
	# Act & Assert
	assert_true(_hud._logo.visible)
	assert_true(_hud._start_button.visible)


func test_start_hides_title_screen_and_starts_game() -> void:
	# Arrange
	watch_signals(_hud)

	# Act
	_hud._on_start_button_pressed()

	# Assert
	assert_false(_hud._logo.visible)
	assert_false(_hud._start_button.visible)
	assert_signal_emitted(_hud, "start_game")


func test_title_screen_returns_after_game_over() -> void:
	# Arrange
	_hud._on_start_button_pressed()

	# Act
	_hud._show_title_screen()

	# Assert
	assert_true(_hud._logo.visible)
	assert_true(_hud._start_button.visible)
