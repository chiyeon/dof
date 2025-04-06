extends PathFollow3D

@export var flight_speed = 0.8

func _process(delta: float) -> void:
	progress_ratio += 0.1 * delta * flight_speed
