extends Node3D

@export var target: Node3D
@export var follow_speed := 5.0

func _process(delta: float) -> void:
	if target:
		position = position.move_toward(target.position, follow_speed * delta)
