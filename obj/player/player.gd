extends CharacterBody3D

@export var camera_idle_overlay: Texture2D
@export var camera_aim_overlay: Texture2D

# in meters
var focus_plane_width = 0.5
var min_focus_dist = 1.0
var max_focus_dist = 16.0
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

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	$camera_active/focus_bar.max_value = max_focus_dist
	$camera_active/focus_bar.min_value = min_focus_dist
	exit_camera()

func _process(delta: float) -> void:
	var focus_dir = Input.get_axis("focus_in", "focus_out")
	current_focus += focus_dir * delta * focus_adjust_speed
	current_focus = clamp(current_focus, min_focus_dist, max_focus_dist)
	update_focus()

func _physics_process(delta: float) -> void:
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
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sens)
		camera.rotate_x(-event.relative.y * mouse_sens)
		camera.rotation.x = clampf(camera.rotation.x, -deg_to_rad(max_vert_rot), deg_to_rad(max_vert_rot))
	elif event.is_action_pressed("cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event.is_action_pressed("capture"):
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		elif is_in_camera:
			take_picture()
	elif event.is_action_pressed("toggle_cam"):
		is_in_camera = !is_in_camera
		enter_camera() if is_in_camera else exit_camera()
	elif event.is_action("focus_in"):
		current_focus += 0.25
		current_focus = clamp(current_focus, min_focus_dist, max_focus_dist)
		update_focus()
	elif event.is_action("focus_out"):
		current_focus -= 0.25
		current_focus = clamp(current_focus, min_focus_dist, max_focus_dist)
		update_focus()

func enter_camera():
	$Camera3D.fov = camera_fov
	$camera_active.visible = true
	$camera_inactive.visible = false
	$Camera3D.attributes.dof_blur_far_enabled = true
	$Camera3D.attributes.dof_blur_near_enabled = true
	update_focus()

func exit_camera():
	$Camera3D.fov = normal_fov
	$camera_active.visible = false
	$camera_inactive.visible = true
	$Camera3D.attributes.dof_blur_far_enabled = false
	$Camera3D.attributes.dof_blur_near_enabled = false

func take_picture():
	var ss = get_viewport().get_texture().get_image()
	ss.save_jpg(".")

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
		$camera_active/focus_bar.value = current_focus
