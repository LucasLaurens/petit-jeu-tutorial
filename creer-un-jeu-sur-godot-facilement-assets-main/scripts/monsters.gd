extends RigidBody2D

@onready var _animated_sprite: AnimatedSprite2D = $AnimatedSprite2D;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var monster_type_name_list = _animated_sprite.sprite_frames.get_animation_names();
	_animated_sprite.play(monster_type_name_list[randi() % monster_type_name_list.size()]);

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free();
