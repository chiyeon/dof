extends Node3D

@export var target: Node3D
@export var follow_speed := 2.0

func _process(delta: float) -> void:
	if target:
		global_position = global_position.move_toward(target.global_position, follow_speed * delta)
