extends Node3D
class_name ByteCrafterAvatar

const AVATAR_IDS := ["boy", "girl", "boy2", "girl2"]
const MODELS := {
	"boy": preload("res://assets/models/players/rigged_player_boy.fbx"),
	"girl": preload("res://assets/models/players/rigged_player_girl.fbx"),
	"boy2": preload("res://assets/models/players/boy2/RIGGED_BOY2.fbx"),
	"girl2": preload("res://assets/models/players/girl2/RIGGED_GIRL2.fbx"),
}
const TEXTURES := {
	"boy": preload("res://assets/models/players/boy_shaded.png"),
	"girl": preload("res://assets/models/players/girl_shaded.png"),
	"boy2": preload("res://assets/models/players/boy2/shaded.png"),
	"girl2": preload("res://assets/models/players/girl2/shaded.png"),
}
const CLIPS := {
	"walk": preload("res://assets/models/animations/walk.tres"),
	"run": preload("res://assets/models/animations/run.tres"),
	"jump": preload("res://assets/models/animations/jump.tres"),
	"mine": preload("res://assets/models/animations/mine.tres"),
	"attack": preload("res://assets/models/animations/attack.tres"),
	"death": preload("res://assets/models/animations/death.tres"),
}
const LOCOMOTION_STATES := ["idle", "walk", "run", "jump"]
const ACTION_STATES := ["mine", "attack", "death"]
const CC_AVATARS := ["boy2", "girl2"]
const MIXAMO_TO_CC := {
	"mixamorig_Hips": "pelvis",
	"mixamorig_Spine": "spine_01",
	"mixamorig_Spine1": "spine_02",
	"mixamorig_Spine2": "spine_03",
	"mixamorig_Neck": "neck_01",
	"mixamorig_Head": "head",
	"mixamorig_LeftShoulder": "clavicle_l",
	"mixamorig_LeftArm": "upperarm_l",
	"mixamorig_LeftForeArm": "lowerarm_l",
	"mixamorig_LeftHand": "hand_l",
	"mixamorig_RightShoulder": "clavicle_r",
	"mixamorig_RightArm": "upperarm_r",
	"mixamorig_RightForeArm": "lowerarm_r",
	"mixamorig_RightHand": "hand_r",
	"mixamorig_LeftUpLeg": "thigh_l",
	"mixamorig_LeftLeg": "calf_l",
	"mixamorig_LeftFoot": "foot_l",
	"mixamorig_LeftToeBase": "ball_l",
	"mixamorig_RightUpLeg": "thigh_r",
	"mixamorig_RightLeg": "calf_r",
	"mixamorig_RightFoot": "foot_r",
	"mixamorig_RightToeBase": "ball_r",
}

var character_id := "boy"
var _model_root: Node3D
var _animation_player: AnimationPlayer
var _retarget_source_root: Node3D
var _retarget_source_skeleton: Skeleton3D
var _retarget_source_player: AnimationPlayer
var _current_animation := ""
var _desired_locomotion := "idle"
var _active_action := ""


static func is_supported_id(value: String) -> bool:
	return value in AVATAR_IDS


func configure(id: String) -> void:
	var normalized := id if is_supported_id(id) else "boy"
	if character_id == normalized and _model_root != null:
		return
	character_id = normalized
	if is_inside_tree():
		_build_model()


func _ready() -> void:
	_build_model()


func _process(_delta: float) -> void:
	_apply_retarget_overrides()


func _build_model() -> void:
	_release_retarget_source()
	if _model_root != null and is_instance_valid(_model_root):
		remove_child(_model_root)
		_model_root.queue_free()
	_model_root = (MODELS[character_id] as PackedScene).instantiate() as Node3D
	_model_root.name = "RiggedCharacter"
	# A pose de repouso importada já está em Y; o avatar vira para acompanhar o controlador em -Z.
	_model_root.rotation = Vector3(0.0, PI, 0.0)
	add_child(_model_root)
	_animation_player = _model_root.find_child("AnimationPlayer", true, false) as AnimationPlayer
	_apply_texture()
	_install_game_clips()
	_active_action = ""
	_current_animation = ""
	if _animation_player != null and not _animation_player.animation_finished.is_connected(_on_animation_finished):
		_animation_player.animation_finished.connect(_on_animation_finished)
	set_locomotion_state(_desired_locomotion)
	_apply_retarget_overrides()


func _apply_texture() -> void:
	if _model_root == null:
		return
	var mesh := _model_root.find_child("model", true, false) as MeshInstance3D
	if mesh == null:
		mesh = _find_first_mesh(_model_root)
	if mesh == null:
		push_warning("Rigged avatar has no MeshInstance3D: " + character_id)
		return
	var source_material := mesh.get_active_material(0) as StandardMaterial3D
	var material := source_material.duplicate(true) as StandardMaterial3D if source_material != null else StandardMaterial3D.new()
	material.albedo_texture = TEXTURES[character_id] as Texture2D
	material.albedo_color = Color.WHITE
	material.roughness = 0.82
	mesh.material_override = material
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON


func _find_first_mesh(parent: Node) -> MeshInstance3D:
	for child: Node in parent.get_children():
		if child is MeshInstance3D:
			return child as MeshInstance3D
		var nested := _find_first_mesh(child)
		if nested != null:
			return nested
	return null


func _install_game_clips() -> void:
	if _animation_player == null:
		push_warning("Rigged avatar has no AnimationPlayer: " + character_id)
		return
	var library := _animation_player.get_animation_library("")
	if library == null:
		library = AnimationLibrary.new()
		_animation_player.add_animation_library("", library)
	if character_id in CC_AVATARS:
		_prepare_retarget_source()
	for clip_name: String in CLIPS:
		if library.has_animation(clip_name):
			library.remove_animation(clip_name)
		var clip := _make_placeholder_clip(CLIPS[clip_name] as Animation) if character_id in CC_AVATARS else (CLIPS[clip_name] as Animation).duplicate(true) as Animation
		library.add_animation(clip_name, clip)


func _make_placeholder_clip(source: Animation) -> Animation:
	var placeholder := Animation.new()
	placeholder.length = source.length
	placeholder.loop_mode = source.loop_mode
	return placeholder


func _prepare_retarget_source() -> void:
	_retarget_source_root = (MODELS["boy"] as PackedScene).instantiate() as Node3D
	_retarget_source_root.name = "MixamoRetargetSource"
	_retarget_source_root.visible = false
	add_child(_retarget_source_root)
	_retarget_source_skeleton = _retarget_source_root.find_child("Skeleton3D", true, false) as Skeleton3D
	_retarget_source_player = _retarget_source_root.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if _retarget_source_skeleton == null or _retarget_source_player == null:
		push_warning("Unable to create the hidden Mixamo retarget source")
		return
	var library := _retarget_source_player.get_animation_library("")
	if library == null:
		library = AnimationLibrary.new()
		_retarget_source_player.add_animation_library("", library)
	for clip_name: String in CLIPS:
		if library.has_animation(clip_name):
			library.remove_animation(clip_name)
		library.add_animation(clip_name, (CLIPS[clip_name] as Animation).duplicate(true))


func _play_retarget_source(clip_name: String, paused := false) -> void:
	if _retarget_source_player == null or not _retarget_source_player.has_animation(clip_name):
		return
	_retarget_source_player.speed_scale = 1.0
	_retarget_source_player.play(clip_name, 0.08)
	if paused:
		_retarget_source_player.seek(0.0, true)
		_retarget_source_player.pause()


func _apply_retarget_overrides() -> void:
	if _retarget_source_skeleton == null:
		return
	var target_skeleton := get_skeleton()
	if target_skeleton == null:
		return
	for source_bone: String in MIXAMO_TO_CC:
		var target_bone := str(MIXAMO_TO_CC[source_bone])
		var source_bone_index := _retarget_source_skeleton.find_bone(source_bone)
		var target_bone_index := target_skeleton.find_bone(target_bone)
		if source_bone_index < 0 or target_bone_index < 0:
			continue
		var source_delta := _retarget_source_skeleton.get_bone_global_rest(source_bone_index).affine_inverse() * _retarget_source_skeleton.get_bone_global_pose(source_bone_index)
		var target_pose := target_skeleton.get_bone_global_rest(target_bone_index)
		target_pose.basis = target_pose.basis * source_delta.basis
		target_skeleton.set_bone_global_pose_override(target_bone_index, target_pose, 1.0, true)


func _release_retarget_source() -> void:
	var target_skeleton := get_skeleton()
	if target_skeleton != null:
		target_skeleton.clear_bones_global_pose_override()
	if _retarget_source_root != null and is_instance_valid(_retarget_source_root):
		remove_child(_retarget_source_root)
		_retarget_source_root.queue_free()
	_retarget_source_root = null
	_retarget_source_skeleton = null
	_retarget_source_player = null


func set_locomotion_state(state: String) -> void:
	var normalized := state if LOCOMOTION_STATES.has(state) else "idle"
	_desired_locomotion = normalized
	if not _active_action.is_empty() or _animation_player == null:
		return
	if normalized == "idle":
		if _current_animation != "idle":
			_animation_player.speed_scale = 1.0
			_animation_player.play("walk", 0.12)
			_animation_player.seek(0.0, true)
			_animation_player.pause()
			_play_retarget_source("walk", true)
			_current_animation = "idle"
		return
	if _current_animation == normalized and _animation_player.is_playing():
		return
	_current_animation = normalized
	_animation_player.speed_scale = 1.0
	_animation_player.play(normalized, 0.12)
	_play_retarget_source(normalized)


func set_animation_state(state: String) -> void:
	if ACTION_STATES.has(state):
		if _active_action != state:
			play_action(state)
		return
	set_locomotion_state(state)


func play_action(action: String) -> void:
	if not ACTION_STATES.has(action) or _animation_player == null or not _animation_player.has_animation(action):
		return
	if _active_action == action and _animation_player.is_playing():
		return
	_active_action = action
	_current_animation = action
	_animation_player.speed_scale = 1.0
	_animation_player.play(action, 0.08)
	_play_retarget_source(action)


func _on_animation_finished(animation_name: StringName) -> void:
	var finished := str(animation_name)
	if finished != _active_action or finished == "death":
		return
	_active_action = ""
	_current_animation = ""
	set_locomotion_state(_desired_locomotion)


func get_animation_state() -> String:
	return _active_action if not _active_action.is_empty() else _desired_locomotion


func get_skeleton() -> Skeleton3D:
	return _model_root.find_child("Skeleton3D", true, false) as Skeleton3D if _model_root != null else null


func get_animation_player() -> AnimationPlayer:
	return _animation_player


func is_retargeting() -> bool:
	return _retarget_source_skeleton != null and _retarget_source_player != null


func get_retarget_source_animation_player() -> AnimationPlayer:
	return _retarget_source_player


func get_retarget_mapping_count() -> int:
	return MIXAMO_TO_CC.size() if is_retargeting() else 0


func get_retargeted_track_count(clip_name: String) -> int:
	if _animation_player == null or not _animation_player.has_animation(clip_name):
		return 0
	return _animation_player.get_animation(clip_name).get_track_count()
