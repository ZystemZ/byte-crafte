extends CharacterBody3D
class_name ByteCrafterPlayer

const WALK_SPEED := 5.6
const SPRINT_SPEED := 8.2
const JUMP_VELOCITY := 7.0
const LOOK_SENSITIVITY := 0.0024
const AVATAR_SCRIPT := preload("res://scripts/game/bytecrafter_avatar.gd")
const AVATAR_IDS := ["boy", "girl", "boy2", "girl2"]

var can_control := false
var third_person := false
var avatar_id := "boy"
var camera: Camera3D
var _camera_pivot: Node3D
var _spring_arm: SpringArm3D
var _body_mesh: Node3D
var _avatar_instance: ByteCrafterAvatar
var _first_person_tool: Node3D
var _third_person_tool: Node3D
var _equipped_tool := ""
var _pitch := 0.0


func _ready() -> void:
	name = "LocalPlayer"
	floor_snap_length = 0.32
	floor_max_angle = deg_to_rad(50.0)
	_build_collision()
	_build_visual_body()
	_build_camera()


func _build_collision() -> void:
	var shape := CapsuleShape3D.new()
	shape.radius = 0.34
	shape.height = 1.8
	var collider := CollisionShape3D.new()
	collider.name = "PlayerCollider"
	collider.shape = shape
	collider.position = Vector3(0.0, 0.9, 0.0)
	add_child(collider)


func _build_visual_body() -> void:
	_body_mesh = Node3D.new()
	_body_mesh.name = "PlayerBody"
	add_child(_body_mesh)
	_avatar_instance = AVATAR_SCRIPT.new() as ByteCrafterAvatar
	_avatar_instance.name = "RiggedAvatar"
	_avatar_instance.configure(avatar_id)
	_body_mesh.add_child(_avatar_instance)


func _build_camera() -> void:
	_camera_pivot = Node3D.new()
	_camera_pivot.name = "CameraPivot"
	_camera_pivot.position = Vector3(0.0, 1.57, 0.0)
	add_child(_camera_pivot)
	_spring_arm = SpringArm3D.new()
	_spring_arm.name = "SpringArm"
	_spring_arm.spring_length = 0.0
	_spring_arm.margin = 0.15
	_spring_arm.collision_mask = 1
	_spring_arm.add_excluded_object(get_rid())
	_camera_pivot.add_child(_spring_arm)
	camera = Camera3D.new()
	camera.name = "PlayerCamera"
	camera.current = true
	camera.fov = 76.0
	camera.near = 0.05
	_spring_arm.add_child(camera)
	_build_pickaxe_models()
	set_third_person(false)


func _build_pickaxe_models() -> void:
	var wood := _material(Color("92623b"))
	var iron := _material(Color("b3b7b3"))
	_first_person_tool = Node3D.new()
	_first_person_tool.name = "FirstPersonTool"
	_first_person_tool.position = Vector3(0.42, -0.29, -0.58)
	_first_person_tool.rotation_degrees = Vector3(-12.0, 0.0, -18.0)
	camera.add_child(_first_person_tool)
	_add_box(_first_person_tool, "Handle", Vector3(0.09, 0.66, 0.09), Vector3.ZERO, wood)
	_add_box(_first_person_tool, "Head", Vector3(0.56, 0.14, 0.16), Vector3(0.0, 0.30, 0.0), iron)
	_add_box(_first_person_tool, "HeadTipLeft", Vector3(0.14, 0.20, 0.17), Vector3(-0.23, 0.26, 0.0), iron)
	_add_box(_first_person_tool, "HeadTipRight", Vector3(0.14, 0.20, 0.17), Vector3(0.23, 0.26, 0.0), iron)
	_third_person_tool = Node3D.new()
	_third_person_tool.name = "ThirdPersonTool"
	_third_person_tool.position = Vector3(0.58, 0.74, -0.14)
	_third_person_tool.rotation_degrees = Vector3(0.0, 0.0, -20.0)
	_body_mesh.add_child(_third_person_tool)
	_add_box(_third_person_tool, "Handle", Vector3(0.09, 0.66, 0.09), Vector3.ZERO, wood)
	_add_box(_third_person_tool, "Head", Vector3(0.56, 0.14, 0.16), Vector3(0.0, 0.30, 0.0), iron)
	_add_box(_third_person_tool, "HeadTipLeft", Vector3(0.14, 0.20, 0.17), Vector3(-0.23, 0.26, 0.0), iron)
	_add_box(_third_person_tool, "HeadTipRight", Vector3(0.14, 0.20, 0.17), Vector3(0.23, 0.26, 0.0), iron)
	_refresh_equipped_tool()


func _material(color: Color) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = 0.92
	return result


func _add_box(parent: Node3D, part_name: String, dimensions: Vector3, offset: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	var instance := MeshInstance3D.new()
	instance.name = part_name
	instance.mesh = mesh
	instance.material_override = material
	instance.position = offset
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(instance)
	return instance


func set_avatar_id(value: String) -> void:
	avatar_id = value if value in AVATAR_IDS else "boy"
	if _avatar_instance != null:
		_avatar_instance.configure(avatar_id)


func get_avatar_id() -> String:
	return avatar_id


func get_avatar_yaw() -> float:
	return rotation.y + (_body_mesh.rotation.y if _body_mesh != null else 0.0)


func get_animation_state() -> String:
	return _avatar_instance.get_animation_state() if _avatar_instance != null else "idle"


func set_animation_state(state: String) -> void:
	if _avatar_instance != null:
		_avatar_instance.set_animation_state(state)


func play_action(action: String) -> void:
	if _avatar_instance != null:
		_avatar_instance.play_action(action)


func set_equipped_tool(tool_id: String) -> void:
	_equipped_tool = tool_id
	_refresh_equipped_tool()


func _refresh_equipped_tool() -> void:
	if _first_person_tool == null or _third_person_tool == null:
		return
	var has_pickaxe := _equipped_tool == "picareta"
	_first_person_tool.visible = has_pickaxe and not third_person
	_third_person_tool.visible = has_pickaxe and third_person


func _physics_process(delta: float) -> void:
	if not can_control:
		velocity.x = move_toward(velocity.x, 0.0, 20.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 20.0 * delta)
		if not is_on_floor():
			velocity.y -= 20.0 * delta
		move_and_slide()
		if _avatar_instance != null and _avatar_instance.get_animation_state() != "death":
			_avatar_instance.set_locomotion_state("idle")
		return
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var movement := Vector3(input_vector.x, 0.0, input_vector.y)
	if movement.length_squared() > 1.0:
		movement = movement.normalized()
	var direction := (global_transform.basis * movement).normalized()
	var sprinting := Input.is_key_pressed(KEY_SHIFT)
	var speed := SPRINT_SPEED if sprinting else WALK_SPEED
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	elif Input.is_key_pressed(KEY_SPACE):
		velocity.y = JUMP_VELOCITY
	move_and_slide()
	_face_move_direction(movement, delta)
	var locomotion := "idle"
	if not is_on_floor():
		locomotion = "jump"
	elif input_vector.length() > 0.05:
		locomotion = "run" if sprinting else "walk"
	if _avatar_instance != null:
		_avatar_instance.set_locomotion_state(locomotion)


func _face_move_direction(movement: Vector3, delta: float) -> void:
	if _body_mesh == null or movement.length_squared() < 0.0001:
		return
	var target_yaw := atan2(-movement.x, -movement.z)
	_body_mesh.rotation.y = lerp_angle(_body_mesh.rotation.y, target_yaw, minf(1.0, delta * 14.0))


func _input(event: InputEvent) -> void:
	if not can_control or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	if event is InputEventMouseMotion:
		_apply_mouse_look(event.relative)


func _apply_mouse_look(relative: Vector2) -> void:
	rotate_y(-relative.x * LOOK_SENSITIVITY)
	_pitch = clampf(_pitch - relative.y * LOOK_SENSITIVITY, deg_to_rad(-88.0), deg_to_rad(88.0))
	_camera_pivot.rotation.x = _pitch


func set_third_person(enabled: bool) -> void:
	third_person = enabled
	if _spring_arm != null:
		_spring_arm.spring_length = 4.2 if enabled else 0.0
	if _body_mesh != null:
		_body_mesh.visible = enabled
	_refresh_equipped_tool()


func reset_view() -> void:
	rotation.y = 0.0
	_pitch = 0.0
	if _body_mesh != null:
		_body_mesh.rotation = Vector3.ZERO
	if _camera_pivot != null:
		_camera_pivot.rotation = Vector3.ZERO
