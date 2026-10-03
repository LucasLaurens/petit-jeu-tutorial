class_name Monster
extends RigidBody2D

## Every live monster joins this group, so a new game can clear the previous one's.
const GROUP: StringName = &"monsters"

@onready var _animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	add_to_group(GROUP)
	var monster_type_names := _animated_sprite.sprite_frames.get_animation_names()
	_animated_sprite.play(monster_type_names[randi() % monster_type_names.size()])


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
