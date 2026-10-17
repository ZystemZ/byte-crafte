extends Area3D
class_name ByteCrafterDrop

var drop_id := -1
var block_id := 1
var quantity := 1
var pending_collection := false
var _elapsed := 0.0
var _base_y := 0.0
const DROP_TEXTURES := {
	1: preload("res://assets/textures/blocks/grass_side.png"),
	2: preload("res://assets/textures/blocks/dirt.png"),
	3: preload("res://assets/textures/blocks/stone_minecraft.png"),
	4: preload("res://assets/textures/blocks/oak_log_side.png"),
	5: preload("res://assets/textures/blocks/oak_leaves_minecraft.png"),
	6: preload("res://assets/textures/blocks/sand.png"),
	7: preload("res://assets/textures/blocks/oak_planks.png"),
}


func configure(id: int, voxel_id: int, amount: int = 1) -> void:
	drop_id = id
	block_id = voxel_id
	quantity = maxi(1, amount)


func _ready() -> void:
	name = "Drop_%d" % drop_id
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	monitorable = false
	_base_y = position.y
	var shape := SphereShape3D.new()
	shape.radius = 0.72
	var collision := CollisionShape3D.new()
	collision.shape = shape
	add_child(collision)
	var cube := MeshInstance3D.new()
	if block_id >= 8 and block_id <= 15:
		cube.name = "ResourceItem"
		var fruit := SphereMesh.new()
		fruit.radius = 0.20 if block_id in [8, 12, 15, 16] else 0.17
		fruit.height = 0.40 if block_id in [8, 12, 15, 16] else 0.34
		cube.mesh = fruit
	else:
		cube.name = "ResourceVoxel"
		var box := BoxMesh.new()
		box.size = Vector3(0.4, 0.4, 0.4)
		cube.mesh = box
	var material := StandardMaterial3D.new()
	if block_id == 8:
		material.albedo_color = Color("d9853c")
	elif block_id == 9:
		material.albedo_color = Color("74e5bf")
		material.emission_enabled = true
		material.emission = Color("2bb88e")
		material.emission_energy_multiplier = 0.7
	elif block_id == 10:
		material.albedo_color = Color("9d73e8")
		material.emission_enabled = true
		material.emission = Color("53219b")
		material.emission_energy_multiplier = 0.85
	elif block_id == 11:
		material.albedo_color = Color("f1c96b")
		material.emission_enabled = true
		material.emission = Color("b66c1e")
		material.emission_energy_multiplier = 1.2
	elif block_id == 12:
		material.albedo_color = Color("b85245")
	elif block_id == 13:
		material.albedo_color = Color("9a704b")
	elif block_id == 14:
		material.albedo_color = Color("eee7d2")
	elif block_id == 15:
		material.albedo_color = Color("f0c85e")
	elif block_id == 16:
		material.albedo_color = Color("c87845")
	else:
		material.albedo_color = Color.WHITE
		material.albedo_texture = DROP_TEXTURES.get(block_id, DROP_TEXTURES[3])
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		if block_id == 5:
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			material.alpha_scissor_threshold = 0.18
	material.roughness = 0.9
	cube.material_override = material
	cube.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(cube)
	if quantity > 1:
		var quantity_label := Label3D.new()
		quantity_label.name = "Quantity"
		quantity_label.text = "x%d" % quantity
		quantity_label.position = Vector3(0.0, 0.42, 0.0)
		quantity_label.font_size = 28
		quantity_label.pixel_size = 0.0035
		quantity_label.modulate = Color("fff2b0")
		quantity_label.outline_size = 6
		quantity_label.outline_modulate = Color(0.05, 0.03, 0.1, 0.95)
		quantity_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		quantity_label.no_depth_test = true
		add_child(quantity_label)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_elapsed += delta
	rotation.y += delta * 1.25
	var floor_y := _find_floor_y()
	if floor_y != INF:
		_base_y = move_toward(_base_y, floor_y, delta * 8.0)
	position.y = _base_y + sin(_elapsed * 2.5) * 0.10
	var owner_node := get_parent()
	if is_instance_valid(owner_node) and owner_node.has_method("_update_drop_position"):
		owner_node.call("_update_drop_position", drop_id, global_position)


func _find_floor_y() -> float:
	var space := get_world_3d().direct_space_state
	var origin := global_position + Vector3.UP * 0.55
	var target := global_position + Vector3.DOWN * 64.0
	var query := PhysicsRayQueryParameters3D.create(origin, target, 1)
	query.exclude = [get_rid()]
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return INF
	return float((hit.get("position") as Vector3).y) + 0.24


func _on_body_entered(body: Node3D) -> void:
	if pending_collection or not body is ByteCrafterPlayer:
		return
	pending_collection = true
	set_deferred("monitoring", false)
	var owner_node := get_parent()
	if is_instance_valid(owner_node) and owner_node.has_method("_on_drop_touched"):
		owner_node.call_deferred("_on_drop_touched", drop_id)


func allow_retry() -> void:
	pending_collection = false
	set_deferred("monitoring", true)
