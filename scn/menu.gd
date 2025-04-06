extends Node3D


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scn/cathedral/cathedral.tscn")

func _on_tutorial_pressed() -> void:
	get_tree().change_scene_to_file("res://scn/tutorial/tutorial_1.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit(0)
