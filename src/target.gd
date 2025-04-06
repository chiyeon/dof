extends VisibleOnScreenNotifier3D

@export var value = 1

func _on_screen_entered() -> void:
	Targets.enter_screen(self)


func _on_screen_exited() -> void:
	Targets.exit_screen(self)
