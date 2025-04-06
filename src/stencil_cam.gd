extends Camera3D

@export var player: NodePath

var main_cam: Camera3D

func _ready() -> void:
	main_cam = get_node(str(player) + "/Camera3D")

func _process(delta):
	if main_cam:
		global_transform = main_cam.global_transform
