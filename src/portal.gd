extends MeshInstance3D

class_name CameraPortal

@export var current = false

func _ready() -> void:
	if current:
		$Inside.visible = true
