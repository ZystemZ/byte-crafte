extends Node
class_name RigAnimationController

const SOURCE_MODEL := preload("res://assets/models/players/rigged_player_boy.fbx")
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

var _target_root: Node3D
var _target_skeleton: Skeleton3D
var _target_player: AnimationPlayer
var _source_root: Node3D
var _source_skeleton: Skeleton3D
var _source_player: AnimationPlayer
var _desired_locomotion := "idle"
var _active_action := ""
var _current_state := ""
var _ready_for_animation := false


func setup(target_root: Node3D) -> void:
	_target_root = target_root
	_target_skeleton = target_root.find_child("Skeleton3D", true, false) as Skeleton3D
	_target_player = target_root.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if _target_skeleton == null or _target_player == null:
		return
	var is_cc_target := _target_skeleton.find_bone("pelvis") >= 0 and _target_skeleton.find_bone("mixamorig_Hips") < 0
	if is_cc_target:
		_build_retarget_source()
	else:
		_install_clips(_target_player)
	_ready_for_animation = true
	set_locomotion_state("idle")


func _build_retarget_source() -> void:
	_source_root = (SOURCE_MODEL as PackedScene).instantiate() as Node3D
	_source_root.name = "AnimationRetargetSource"
	_source_root.visible = false
	add_child(_source_root)
	_source_skeleton = _source_root.find_child("Skeleton3D", true, false) as Skeleton3D
	_source_player = _source_root.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if _source_skeleton == null or _source_player == null:
		return
	_install_clips(_source_player)


func _install_clips(player: AnimationPlayer) -> void:
	var library := player.get_animation_library("")
	if library == null:
		library = AnimationLibrary.new()
		player.add_animation_library("", library)
	for clip_name: String in CLIPS:
		if library.has_animation(clip_name):
			library.remove_animation(clip_name)
		library.add_animation(clip_name, (CLIPS[clip_name] as Animation).duplicate(true))
	if not player.animation_finished.is_connected(_on_animation_finished):
		player.animation_finished.connect(_on_animation_finished)


func _process(_delta: float) -> void:
	if _ready_for_animation and _source_skeleton != null:
		_apply_retarget_overrides()


func set_locomotion_state(state: String) -> void:
	if not _ready_for_animation:
		return
	var normalized := state if state in LOCOMOTION_STATES else "idle"
	_desired_locomotion = normalized
	if not _active_action.is_empty():
		return
	if normalized == "idle":
		_play_clip("walk", true)
		_current_state = "idle"
	else:
		_play_clip(normalized, false)
		_current_state = normalized


func play_action(action: String) -> void:
	if not _ready_for_animation or action not in ACTION_STATES:
		return
	if _active_action == action and _is_playing(action):
		return
	_active_action = action
	_current_state = action
	_play_clip(action, false)


func _play_clip(clip_name: String, paused: bool) -> void:
	var player := _source_player if _source_player != null else _target_player
	if player == null or not player.has_animation(clip_name):
		return
	player.speed_scale = 1.0
	player.play(clip_name, 0.08)
	if paused:
		player.seek(0.0, true)
		player.pause()


func _is_playing(clip_name: String) -> bool:
	var player := _source_player if _source_player != null else _target_player
	return player != null and player.is_playing() and player.current_animation == clip_name


func _on_animation_finished(animation_name: StringName) -> void:
	var finished := str(animation_name)
	if finished != _active_action or finished == "death":
		return
	_active_action = ""
	set_locomotion_state(_desired_locomotion)


func _apply_retarget_overrides() -> void:
	if _source_skeleton == null or _target_skeleton == null:
		return
	for source_bone: String in MIXAMO_TO_CC:
		var target_bone := str(MIXAMO_TO_CC[source_bone])
		var source_index := _source_skeleton.find_bone(source_bone)
		var target_index := _target_skeleton.find_bone(target_bone)
		if source_index < 0 or target_index < 0:
			continue
		var source_delta := _source_skeleton.get_bone_global_rest(source_index).affine_inverse() * _source_skeleton.get_bone_global_pose(source_index)
		var target_pose := _target_skeleton.get_bone_global_rest(target_index)
		target_pose.basis = target_pose.basis * source_delta.basis
		_target_skeleton.set_bone_global_pose_override(target_index, target_pose, 1.0, true)


func has_functional_animation() -> bool:
	return _ready_for_animation and (_source_player != null or _target_player != null)


func get_state() -> String:
	return _active_action if not _active_action.is_empty() else _current_state
