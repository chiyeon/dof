extends VisibleOnScreenNotifier3D

var key = -1

func _on_screen_entered() -> void:
	key = Targets.enter_screen(self)


func _on_screen_exited() -> void:
	Targets.exit_screen(key)
