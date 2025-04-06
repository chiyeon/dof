extends Area3D

var gone = false
var waittime = 5

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and !gone:
		$AnimationPlayer.play("flyaway")
		gone = true



func _on_timer_timeout() -> void:
	gone = false
	$AnimationPlayer.play("flyback")


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player") and gone:
		$Timer.start(waittime)
