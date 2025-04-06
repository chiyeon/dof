extends CharacterBody3D

signal photo_taken(data)

@export var camera_idle_overlay: Texture2D
@export var camera_aim_overlay: Texture2D

@export var shutter_sounds: Array[AudioStream] = []

var film_roll = []
var start_time = 0;

var shot_cooldown = 1.0
var can_shoot = true
var freeze_input = false
@export var shots_left = 24

# in meters
var focus_plane_width = 0.5
var min_focus_dist = 1.0
var max_focus_dist = 32
var current_focus = 5.0
var focus_adjust_speed = 4.0
var blur_buffer = 5.0

var normal_fov = 75.0
var camera_fov = 27

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var acceleration = 13.0
var deceleration = 15.0
var move_speed = 4.0

var jump_force = 4.0
var air_forward_acceleration = 3.0
var air_sideways_acceleration = 5.0
var air_deceleration = 2.0

var mouse_sens = 0.0005
var max_vert_rot = 70

var is_in_camera = false

@onready var camera = $Camera3D
@onready var focusbar = $camera_active/focus_bar
@onready var shotsleftlabel = $Camera3D/CameraTarget/camera_inactive/CanvasLayer/ShotsLeftLabel

func _ready():
	Targets.reset_targets()
	start_time = 0
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	focusbar.max_value = max_focus_dist
	focusbar.min_value = min_focus_dist
	shotsleftlabel.text = str(shots_left) + " shots left"
	$Stats.visible = false
	exit_camera()

func _process(delta: float) -> void:
	start_time += delta
	if (freeze_input): return
	var focus_dir = Input.get_axis("focus_out", "focus_in")
	current_focus += focus_dir * delta * focus_adjust_speed
	current_focus = clamp(current_focus, min_focus_dist, max_focus_dist)
	update_focus()
	
	if Input.is_key_pressed(KEY_L):
		develop_film()

func _physics_process(delta: float) -> void:
	if (freeze_input): return
	velocity.y += -gravity * delta
	
	var input = Input.get_vector("left", "right", "forward", "back")
	var direction = transform.basis * Vector3(input.x, 0, input.y)
	direction.y = 0
	direction = direction.normalized()
	
	var target_vel = direction * move_speed

	if is_on_floor():
		velocity.x = move_toward(velocity.x, target_vel.x, (acceleration if direction.x != 0 else deceleration) * delta)
		velocity.z = move_toward(velocity.z, target_vel.z, (acceleration if direction.z != 0 else deceleration) * delta)
	else:
		velocity.x = move_toward(velocity.x, target_vel.x, (air_forward_acceleration if direction.x != 0 else air_deceleration) * delta)
		velocity.z = move_toward(velocity.z, target_vel.z, (air_sideways_acceleration if direction.z != 0 else air_deceleration) * delta)
	
	move_and_slide()
	
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = jump_force

func _input(event: InputEvent) -> void:
	if (freeze_input): return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sens)
		camera.rotate_x(-event.relative.y * mouse_sens)
		camera.rotation.x = clampf(camera.rotation.x, -deg_to_rad(max_vert_rot), deg_to_rad(max_vert_rot))
	elif event.is_action_pressed("cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event.is_action_pressed("capture"):
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		elif is_in_camera and can_shoot:
			take_picture()
	elif event.is_action_pressed("toggle_cam"):
		is_in_camera = !is_in_camera
		$AnimationPlayer.play("enter_camera" if is_in_camera else "exit_camera")
		#enter_camera() if is_in_camera else exit_camera()
	elif event.is_action_pressed("focus_in"):
		current_focus += 0.25
		current_focus = clamp(current_focus, min_focus_dist, max_focus_dist)
		update_focus()
	elif event.is_action_pressed("focus_out"):
		current_focus -= 0.25
		current_focus = clamp(current_focus, min_focus_dist, max_focus_dist)
		update_focus()

func enter_camera():
	$Camera3D.fov = camera_fov
	$camera_active.visible = true
	$Camera3D/CameraTarget/camera_inactive.visible = false
	$Camera3D.attributes.dof_blur_far_enabled = true
	$Camera3D.attributes.dof_blur_near_enabled = true
	update_focus()

func exit_camera():
	$Camera3D.fov = normal_fov
	$camera_active.visible = false
	$Camera3D/CameraTarget/camera_inactive.visible = true
	$Camera3D.attributes.dof_blur_far_enabled = false
	$Camera3D.attributes.dof_blur_near_enabled = false

func get_score(true_distance):
	return max(0.0, 1.0 - abs(true_distance - current_focus) / max(true_distance, current_focus))

func screenshot():
	
	$camera_active.visible = false
	$Camera3D/CameraTarget/camera_inactive/CanvasLayer/ShotsLeftLabel.visible = false
	await RenderingServer.frame_post_draw
	var viewport = get_viewport()
	var img = viewport.get_texture().get_image()
	$camera_active.visible = true
	$Camera3D/CameraTarget/camera_inactive/CanvasLayer/ShotsLeftLabel.visible = true
	
	return img

func take_picture():
	if shots_left <= 0: return
	can_shoot = false
	$CameraShotTimer.start(shot_cooldown)
	var targets = Targets.filter_potential($Camera3D)
	var scores = []
	
	shots_left -= 1
	if shots_left <= 0:
		shotsleftlabel.text = "No shots left, develop reel"
	else:
		shotsleftlabel.text = str(shots_left) + " shots left"
	
	$AudioPlayer.stream = shutter_sounds.pick_random()
	$AudioPlayer.play()
	
	var obj = []
	var score_val = []
	for t in targets:
		obj.append(t[0])
		var dist = $Camera3D.global_position.distance_to(t[1])
		print("Object " + t[0].name + " was " + str(dist) + "m away and focus was " + str(current_focus) + "m")
		print("Score: " + str(get_score(dist)))
		scores.append(get_score(dist)) # score * value
		score_val.append(get_score(dist) * t[2])
	
	var data = {
		"target_scores_percent": scores,
		"targets": obj,
		"target_scores_value": score_val,
		"image": await screenshot()
	}
	
	photo_taken.emit(data)
	
	film_roll.append(data)
	
	$camera_active/AnimationPlayer.play("flash")

func develop_film():
	var stats = save_film_roll()
	exit_camera()
	freeze_input = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# open new scene to display
	
	var missing_subs = 16 - stats.unique_subjects
	
	$Stats.visible = true
	$Stats/ColorRect/Label.text = "I apologize for the lackluster end screen T-T. Your photos are also saved in this game's appdata!"
	
	var end_time = start_time
	var min = floor(end_time / 60.0)
	var sec = fmod(end_time, 60.0)
	
	$Stats/ColorRect/Label.text += "\n\nFINAL TIME: %d min and %.3f sec" % [min, sec]
	
	$Stats/ColorRect/Label.text += "\n\nYou took %d total photos of %d unique subjects.\n\nYour average Depth of Field score was %.2f/1.0.\n\nYour Total score was %.2f/28.0" % [stats.photos_taken, stats.unique_subjects, stats.average_dof_score, stats.score]
	if missing_subs == 0:
		$Stats/ColorRect/Label.text += "\n\nYou took pictures of every item!"
	elif missing_subs == 1:
		$Stats/ColorRect/Label.text += "\n\nYou are only missing a photo of ONE last item"
	else:
		$Stats/ColorRect/Label.text += "\n\nYou didn't take pictures of %d other items in the area" % missing_subs
	

func show_reel():
	$Stats.visible = false
	$ViewReel.visible = true
	
	for i in film_roll:
		var imgrect = TextureRect.new()
		imgrect.texture = ImageTexture.create_from_image(i.image)
		imgrect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		imgrect.custom_minimum_size = Vector2(320, 240)
		$ViewReel/ColorRect/ImageScroll/ImageList.add_child(imgrect)

func save_film_roll():
	var odir = DirAccess.open("user://")
	odir.make_dir("reels")
	
	var time = Time.get_datetime_string_from_system().replace(":", "-")
	
	var dir = DirAccess.open("user://reels")
	dir.make_dir(time)
	
	var encountered = {}
	var percent = {}
	var key = 0
	for i in film_roll:
		# i = { "target_scores_percent": [0.6454644252382], "targets": [Sculpture1:<StaticBody3D#43872421649>], "target_scores_value": [0.6454644252382], "image": <Image#-9223371978939824706> }
		for j in range(i.targets.size()):
			if i.targets[j] in encountered:
				# check if our saved score is better than this score
				# if not, replace it
				if i.target_scores_value[j] > encountered[i.targets[j]]:
					encountered[i.targets[j]] = i.target_scores_value[j]
					percent[i.targets[j]] = i.target_scores_percent[j]
			else:
				encountered[i.targets[j]] = i.target_scores_value[j]
				percent[i.targets[j]] = i.target_scores_percent[j]
		i.image.save_jpg("user://reels/" + time + "/photo_" + str(key) + ".jpg", 1.0)
		key += 1
	
	var score = 0
	for k in encountered:
		score += encountered[k]
	
	var avg_percent = 0
	for k in percent:
		avg_percent += percent[k]
	avg_percent /= percent.size()
	
	var stats = {
		"photos_taken": film_roll.size(),
		"unique_subjects": encountered.size(),
		"score": score,
		"average_dof_score": avg_percent
	}
	
	return stats
	
	print(stats)

func update_focus():
	if is_in_camera:
		# change dof settings
		# set focus
		# for transition, make it so we transition smoothly from
		# min - blur buffer to current
		# current to max + blur buffer
		# makes it so we smoothly blur
		$Camera3D.attributes.dof_blur_far_distance = current_focus + focus_plane_width
		$Camera3D.attributes.dof_blur_near_distance = current_focus
		$Camera3D.attributes.dof_blur_far_transition = max_focus_dist - current_focus + blur_buffer
		$Camera3D.attributes.dof_blur_near_transition = current_focus - min_focus_dist + 1
		
		# update focus meter in ui
		focusbar.value = current_focus


func _on_camera_shot_timer_timeout() -> void:
	# reset
	can_shoot = true
