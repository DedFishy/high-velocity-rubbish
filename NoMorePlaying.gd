extends VideoStreamPlayer



func _on_finished() -> void:
	get_tree().change_scene_to_file("res://the_vastnessof_space.tscn")
