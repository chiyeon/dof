extends CanvasLayer

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("cancel"):
		get_tree().change_scene_to_file("res://scn/menu.tscn")
