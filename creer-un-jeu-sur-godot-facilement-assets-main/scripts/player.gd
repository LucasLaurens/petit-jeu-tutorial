class_name Player
extends Area2D

signal hit

## Below this distance the player stops instead of jittering around the finger.
const TOUCH_DEAD_ZONE: float = 10.0

@export var speed: int = 400

var screen_size: Vector2

var _is_touching: bool = false
var _touch_target: Vector2 = Vector2.ZERO

@onready var _animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	screen_size = get_viewport_rect().size
	hide()


func _process(delta: float) -> void:
	var direction := _read_direction()

	if direction != Vector2.ZERO:
		_animated_sprite.play()
	else:
		_animated_sprite.stop()

	position += direction * speed * delta
	position = position.clamp(Vector2.ZERO, screen_size)


func _input(event: InputEvent) -> void:
	var touch := event as InputEventScreenTouch
	if touch:
		_is_touching = touch.pressed
		_touch_target = touch.position
		return

	var drag := event as InputEventScreenDrag
	if drag:
		_touch_target = drag.position


## Keyboard wins; otherwise the player follows the finger while it is held down.
func _read_direction() -> Vector2:
	var keyboard_direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if keyboard_direction != Vector2.ZERO or not _is_touching:
		return keyboard_direction
	if position.distance_to(_touch_target) < TOUCH_DEAD_ZONE:
		return Vector2.ZERO
	return position.direction_to(_touch_target)


func _on_body_entered(_body: Node2D) -> void:
	hide()
	hit.emit()
	_collision_shape.set_deferred("disabled", true)


func start(new_position: Vector2) -> void:
	position = new_position
	show()
	_collision_shape.disabled = false
