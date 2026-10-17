extends CharacterBody3D
class_name ByteCrafterEnemy

signal defeated(enemy: Node3D, at_position: Vector3)

const MODELS := {
	"slime": preload("res://assets/models/enemies/slime/base_basic_shaded.fbx"),
	"et": preload("res://assets/models/enemies/et/riged_ete.fbx"),
	"zombie": preload("res://assets/models/enemies/zombie/rigged_zumbi.fbx"),
	"boss": preload("res://assets/models/enemies/et/riged_ete.fbx"),
}
const TEXTURES := {
	"slime": preload("res://assets/models/enemies/slime/shaded.png"),
	"et": preload("res://assets/models/enemies/et/shaded.png"),
	"zombie": preload("res://assets/models/enemies/zombie/shaded.png"),
	"boss": preload("res://assets/models/enemies/et/shaded.png"),
}
const ANIMATION_CONTROLLER := preload("res://scripts/game/rig_animation_controller.gd")
const SPECS := {
	"slime": {"label": "Slime", "hits": 1, "speed": 2.15, "range": 1.35, "aggro_range": 0.0, "damage": 0.5, "cooldown": 1.35, "xp": 8, "reward": 9, "can_chase": false},
	"et": {"label": "ET", "hits": 2, "speed": 1.72, "range": 1.25, "aggro_range": 10.0, "damage": 1.5, "cooldown": 1.75, "xp": 13, "reward": 8, "can_chase": true},
	"zombie": {"label": "Zumbi", "hits": 3, "speed": 2.55, "range": 1.05, "aggro_range": 10.0, "damage": 3.0, "cooldown": 1.05, "xp": 18, "reward": 4, "can_chase": true},
	"boss": {"label": "Chefe Lunar", "hits": 8, "speed": 1.45, "range": 2.45, "aggro_range": 18.0, "damage": 5.0, "cooldown": 1.25, "xp": 90, "reward": 11, "can_chase": true},
}

const LOOT_TABLES := {
	"slime": [[9, 1]],
	"et": [[8, 1], [10, 1]],
	"zombie": [[4, 1], [7, 1]],
	"boss": [[11, 1], [10, 2], [8, 3]],
}

var enemy_type := "slime"
var health := 1.0
var hits_remaining := 1
var target: ByteCrafterPlayer
var game: Node
var _model_root: Node3D
var _base_model_scale := Vector3.ONE
var _base_model_position := Vector3.ZERO
var _attack_timer := 0.4
var _hit_flash_timer := 0.0
var _defeated := false
var _death_timer := 0.0
var _visual_time := 0.0
var _max_health := 1.0
var _health_bar: Label3D
var _health_text: Label3D
var _animation_controller


static func is_supported_type(value: String) -> bool:
	return SPECS.has(value)


func configure(player: ByteCrafterPlayer, owner_game: Node, requested_type := "slime") -> void:
	target = player
	game = owner_game
	enemy_type = requested_type if is_supported_type(requested_type) else "slime"
	hits_remaining = int((SPECS[enemy_type] as Dictionary).get("hits", 1))
	health = float(hits_remaining)
	_max_health = health
	if is_inside_tree():
		_clear_collider()
		_build_collider()
		_build_model()
		_build_nameplate()


func _ready() -> void:
	name = "%sHostil" % get_display_name().replace(" ", "")
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 0.24
	_build_collider()
	_build_model()
	_build_nameplate()


func _build_collider() -> void:
	var collider := CollisionShape3D.new()
	collider.name = "SlimeCollider" if enemy_type == "slime" else "EnemyCollider"
	var shape := CapsuleShape3D.new()
	if enemy_type == "slime":
		shape.radius = 0.46
		shape.height = 0.92
		collider.position.y = 0.46
	else:
		var height := _target_height()
		shape.radius = 0.38 * (height / 1.8)
		shape.height = height
		collider.position.y = height * 0.5
	collider.shape = shape
	add_child(collider)


func _clear_collider() -> void:
	var old_collider := get_node_or_null("SlimeCollider")
	if old_collider == null:
		old_collider = get_node_or_null("EnemyCollider")
	if old_collider != null:
		remove_child(old_collider)
		old_collider.queue_free()


func _build_model() -> void:
	if _model_root != null and is_instance_valid(_model_root):
		remove_child(_model_root)
		_model_root.queue_free()
	_model_root = (MODELS[enemy_type] as PackedScene).instantiate() as Node3D
	_model_root.name = "%sModelo" % get_display_name().replace(" ", "")
	# O slime já é exportado em pé; a rotação deitada usada nos rigs Mixamo
	# não pode ser aplicada a ele.
	_model_root.rotation = Vector3(0.0, PI, 0.0) if enemy_type == "slime" else Vector3(-PI * 0.5, PI, 0.0)
	var source_bounds := _find_model_bounds(_model_root)
	var target_height := _target_height()
	if source_bounds.size.y > 0.001:
		var uniform_scale := target_height / source_bounds.size.y
		_model_root.scale = Vector3.ONE * uniform_scale
		# O modelo visual encosta no mesmo plano do collider, sem afundar.
		_model_root.position.y = -source_bounds.position.y * uniform_scale
	_base_model_position = _model_root.position
	_base_model_scale = _model_root.scale
	_apply_texture()
	add_child(_model_root)
	if enemy_type != "slime":
		if _animation_controller != null and is_instance_valid(_animation_controller):
			_animation_controller.queue_free()
		_animation_controller = ANIMATION_CONTROLLER.new() as Node
		_animation_controller.name = "RigAnimationController"
		add_child(_animation_controller)
		_animation_controller.setup(_model_root)


func _build_nameplate() -> void:
	var old_plate := get_node_or_null("Nameplate")
	if old_plate != null:
		old_plate.queue_free()
	var plate := Label3D.new()
	plate.name = "Nameplate"
	plate.text = get_display_name().to_upper()
	plate.position.y = _target_height() + 0.28
	plate.font_size = 32
	plate.pixel_size = 0.0035
	plate.modulate = Color("f4f0c4")
	plate.outline_size = 8
	plate.outline_modulate = Color(0.03, 0.05, 0.04, 0.95)
	plate.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	plate.no_depth_test = true
	plate.render_priority = 4
	add_child(plate)
	_build_health_bar()


func _build_health_bar() -> void:
	for child_name: String in ["HealthBarBack", "HealthBar"]:
		var old_bar := get_node_or_null(child_name)
		if old_bar != null:
			old_bar.queue_free()
	var y := _target_height() + 0.08
	_health_bar = Label3D.new()
	_health_bar.name = "HealthBarBack"
	_health_bar.text = "■■■■■■■■"
	_health_bar.position = Vector3(0.0, y, 0.0)
	_health_bar.font_size = 26
	_health_bar.pixel_size = 0.0032
	_health_bar.modulate = Color(0.06, 0.08, 0.06, 0.9)
	_health_bar.outline_size = 2
	_health_bar.outline_modulate = Color(0.02, 0.02, 0.02, 0.95)
	_health_bar.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_health_bar.no_depth_test = true
	_health_bar.render_priority = 5
	add_child(_health_bar)
	_health_text = Label3D.new()
	_health_text.name = "HealthBar"
	_health_text.position = Vector3(0.0, y, 0.01)
	_health_text.font_size = 26
	_health_text.pixel_size = 0.0032
	_health_text.outline_size = 2
	_health_text.outline_modulate = Color(0.02, 0.02, 0.02, 0.95)
	_health_text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_health_text.no_depth_test = true
	_health_text.render_priority = 6
	add_child(_health_text)
	_refresh_health_bar()


func _refresh_health_bar() -> void:
	if _health_text == null:
		return
	var ratio := clampf(health / maxf(_max_health, 1.0), 0.0, 1.0)
	var filled := clampi(ceili(ratio * 8.0), 0, 8)
	_health_text.text = "■".repeat(filled)
	_health_text.modulate = Color("8ee388") if ratio > 0.5 else (Color("f4d35e") if ratio > 0.25 else Color("ed786f"))
	_health_text.position.x = -0.03 * float(8 - filled)


func _find_model_bounds(root: Node3D) -> AABB:
	var result := _collect_model_bounds(root, Transform3D.IDENTITY)
	return result if result.size != Vector3.ZERO else AABB(Vector3.ZERO, Vector3.ONE)


func _collect_model_bounds(node: Node, parent_transform: Transform3D) -> AABB:
	var current := parent_transform * (node as Node3D).transform if node is Node3D else parent_transform
	var result := AABB()
	if node is MeshInstance3D:
		result = current * (node as MeshInstance3D).get_aabb()
	for child: Node in node.get_children():
		var child_bounds := _collect_model_bounds(child, current)
		if child_bounds.size != Vector3.ZERO:
			result = child_bounds if result.size == Vector3.ZERO else result.merge(child_bounds)
	return result


func _apply_texture() -> void:
	var meshes := _find_meshes(_model_root)
	if meshes.is_empty():
		push_warning("Enemy model has no MeshInstance3D: " + enemy_type)
		return
	for mesh: MeshInstance3D in meshes:
		var source_material := mesh.get_active_material(0) as StandardMaterial3D
		var material := source_material.duplicate(true) as StandardMaterial3D if source_material != null else StandardMaterial3D.new()
		material.albedo_texture = TEXTURES[enemy_type] as Texture2D
		material.albedo_color = Color.WHITE
		if enemy_type == "boss":
			material.albedo_color = Color("bf78ff")
			material.emission_enabled = true
			material.emission = Color("57218f")
			material.emission_energy_multiplier = 0.55
		material.roughness = 0.84
		mesh.material_override = material
		mesh.visible = true
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON


func _find_first_mesh(parent: Node) -> MeshInstance3D:
	for child: Node in parent.get_children():
		if child is MeshInstance3D:
			return child as MeshInstance3D
		var nested := _find_first_mesh(child)
		if nested != null:
			return nested
	return null


func _find_meshes(parent: Node) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	for child: Node in parent.get_children():
		if child is MeshInstance3D:
			result.append(child as MeshInstance3D)
		result.append_array(_find_meshes(child))
	return result


func _target_height() -> float:
	match enemy_type:
		"zombie":
			return 1.8
		"et":
			return 1.8
		"boss":
			return 3.0
		_:
			return 0.9


func _physics_process(delta: float) -> void:
	_visual_time += delta
	if _defeated:
		_process_death(delta)
		return
	_attack_timer = maxf(0.0, _attack_timer - delta)
	_hit_flash_timer = maxf(0.0, _hit_flash_timer - delta)
	_process_visuals(delta)
	if target == null or not is_instance_valid(target) or not target.can_control:
		_set_animation_state("idle")
		velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 12.0 * delta)
		_apply_gravity(delta)
		move_and_slide()
		return
	var daytime := true
	if game != null and game.has_method("is_daytime"):
		daytime = game.is_daytime()
	if (enemy_type == "et" and daytime) or (enemy_type == "zombie" and not daytime) or (enemy_type == "boss" and daytime):
		_set_animation_state("idle")
		velocity.x = 0.0
		velocity.z = 0.0
		_apply_gravity(delta)
		move_and_slide()
		return
	var offset := target.global_position - global_position
	offset.y = 0.0
	var distance := offset.length()
	var direction := offset.normalized() if distance > 0.01 else Vector3.ZERO
	if direction.length_squared() > 0.01:
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), minf(delta * (3.2 if enemy_type == "zombie" else 2.3), 1.0))
	var spec: Dictionary = SPECS[enemy_type]
	var attack_range := float(spec.get("range", 1.35))
	var can_move := bool(spec.get("can_chase", false)) and distance <= float(spec.get("aggro_range", 0.0))
	if distance > attack_range and can_move:
		_set_animation_state("walk")
		var speed := float(spec.get("speed", 2.0))
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		_set_animation_state("idle")
		velocity.x = move_toward(velocity.x, 0.0, 14.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 14.0 * delta)
		if distance <= attack_range and _attack_timer <= 0.0 and _has_clear_attack_path() and game != null and game.has_method("_damage_player"):
			_attack_timer = float(spec.get("cooldown", 1.35))
			if _animation_controller != null:
				_animation_controller.play_action("attack")
			game.call("_damage_player", float(spec.get("damage", 2.0)), get_display_name())
	_apply_gravity(delta)
	move_and_slide()


func _has_clear_attack_path() -> bool:
	if target == null or get_world_3d() == null:
		return false
	var origin := global_position + Vector3.UP * minf(_target_height() * 0.72, 1.25)
	var destination := target.global_position + Vector3.UP * 0.9
	var query := PhysicsRayQueryParameters3D.create(origin, destination, 3)
	query.exclude = [get_rid()]
	query.collide_with_bodies = true
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or hit.get("collider") == target


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	else:
		velocity.y = 0.0


func _process_visuals(_delta: float) -> void:
	if _model_root == null:
		return
	if enemy_type == "et":
		_model_root.position = _base_model_position + Vector3(0.0, sin(_visual_time * 2.4) * 0.035, 0.0)
	else:
		_model_root.position = _base_model_position + Vector3(0.0, sin(_visual_time * 4.2) * 0.025, 0.0)


func _process_death(delta: float) -> void:
	if _model_root != null:
		_model_root.position = _base_model_position
	_death_timer -= delta
	if _death_timer <= 0.0:
		queue_free()


func take_damage(amount: float) -> void:
	if _defeated or amount <= 0.0:
		return
	# O combate é contado em golpes: slime 1, ET 2, zumbi 3.
	# Dano alto continua sendo letal para chamadas de sistema/testes.
	hits_remaining = 0 if amount >= 10.0 else maxi(0, hits_remaining - 1)
	health = float(hits_remaining)
	_hit_flash_timer = 0.16
	_refresh_health_bar()
	if health <= 0.0:
		_defeated = true
		_death_timer = 0.9
		if _animation_controller != null:
			_animation_controller.play_action("death")
		collision_layer = 0
		var collider := get_node_or_null("SlimeCollider") as CollisionShape3D
		if collider == null:
			collider = get_node_or_null("EnemyCollider") as CollisionShape3D
		if collider != null:
			collider.set_deferred("disabled", true)
			defeated.emit(self, global_position)


func _set_animation_state(state: String) -> void:
	if _animation_controller != null:
		_animation_controller.set_locomotion_state(state)


func get_display_name() -> String:
	return str((SPECS.get(enemy_type, SPECS["slime"]) as Dictionary).get("label", "Slime"))


func get_reward_item_id() -> int:
	return int((SPECS.get(enemy_type, SPECS["slime"]) as Dictionary).get("reward", 9))


func get_xp_reward() -> int:
	return int((SPECS.get(enemy_type, SPECS["slime"]) as Dictionary).get("xp", 8))


func get_loot_table() -> Array:
	return (LOOT_TABLES.get(enemy_type, LOOT_TABLES["slime"]) as Array).duplicate(true)


func is_boss() -> bool:
	return enemy_type == "boss"
