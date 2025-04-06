extends Label3D


func _on_player_photo_taken(data: Variant) -> void:
	print(data)
	if (data.target_scores_percent.size() != 0):
		var best = data.target_scores_percent.max()
		text = "Current Score:\n" + str(round(best * 100)/10) + "/10"
