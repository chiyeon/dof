extends Node

var potential_on_screen = []

func enter_screen(target: Node):
	var index = potential_on_screen.size()
	
	potential_on_screen.append(target)
	
	return index

func exit_screen(index: int):
	potential_on_screen.remove_at(index)

func filter_potential(origin: Node3D):
	var actual = []
	for obj in potential_on_screen:
		var space = origin.get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(origin.global_position, obj.global_position)
		# exclude obj parent (bc object is target visibility noti which should be layer 1 of parent
		query.exclude = [origin, self]
		var res = space.intersect_ray(query)
		
		# if raycast hits the object (obj.parent) there is no barrier
		if res.collider == obj.get_parent():
			# append object & the ray hit pos
			actual.append([obj.get_parent(), res.position])
	
	return actual
