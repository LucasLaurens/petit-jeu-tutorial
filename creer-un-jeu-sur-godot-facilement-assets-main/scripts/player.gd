extends Area2D

signal hit

@export var speed: int = 400;

var screen_size: Vector2;

@onready var _animated_sprite: AnimatedSprite2D = $AnimatedSprite2D;
@onready var _collision_shape: CollisionShape2D = $CollisionShape2D;



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screen_size = get_viewport_rect().size;
	hide();


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down");
 
	if direction != Vector2.ZERO:
		_animated_sprite.play();
	else:
		_animated_sprite.stop();
 
	position += direction * speed * delta;
	position = position.clamp(Vector2.ZERO, screen_size);


func _on_body_entered(body: Node2D) -> void:
	hide();
	hit.emit();
	_collision_shape.set_deferred("disabled", true);
	
	
func start(new_position: Vector2) -> void:
	position = new_position;
	show();
	_collision_shape.disabled = false;
