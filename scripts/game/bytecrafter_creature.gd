extends CharacterBody3D
class_name ByteCrafterCreature

signal defeated(creature: ByteCrafterCreature, at_position: Vector3)

const SPECIES := {
	"rabbit": {"label": "Coelho", "health": 1, "speed": 2.8, "size": Vector3(0.7, 0.75, 0.55), "color": Color("d8d0b6"), "drops": [[12, 1]], "xp": 3},
	"cow": {"label": "Vaca", "health": 4, "speed": 1.0, "size": Vector3(1.25, 1.35, 0.8), "color": Color("6c5546"), "drops": [[12, 2], [13, 1]], "xp": 8},
	"sheep": {"label": "Ovelha", "health": 3, "speed": 1.35, "size": Vector3(1.05, 1.15, 0.72), "color": Color("eee7d2"), "drops": [[14, 2], [12, 1]], "xp": 6},
	"pig": {"label": "Porco", "health": 3, "speed": 1.55, "size": Vector3(0.95, 0.9, 0.65), "color": Color("d98f8f"), "drops": [[12, 2], [15, 1]], "xp": 6},
}

var species := "rabbit"
var health := 1
var _max_health := 1
var wander_origin := Vector3.ZERO
var _wander_target := Vector3.ZERO
var _turn_timer := 0.0
var _flee_timer := 0.0
var _walk_speed := 1.15
var _defeated := false

static func is_supported_species(value: String) -> bool:
	return SPECIES.has(value)

func configure(requested_species: String) -> void:
	species = requested_species if is_supported_species(requested_species) else "rabbit"
	var spec: Dictionary = SPECIES[species]
	health = int(spec["health"])
	_max_health = health
	_walk_speed = float(spec["speed"])

func get_display_name() -> String:
	return str((SPECIES.get(species, SPECIES["rabbit"]) as Dictionary)["label"])

func get_drops() -> Array:
	return (SPECIES.get(species, SPECIES["rabbit"]) as Dictionary)["drops"]

func get_xp_reward() -> int:
	return int((SPECIES.get(species, SPECIES["rabbit"]) as Dictionary)["xp"])

func _ready() -> void:
	name = get_display_name().replace(" ", "")
	floor_snap_length = 0.28
	var shape := CapsuleShape3D.new()
	var size: Vector3 = (SPECIES.get(species, SPECIES["rabbit"]) as Dictionary)["size"]
	shape.radius = size.x * 0.32
	shape.height = size.y
	var collider := CollisionShape3D.new()
	collider.name = "AnimalCollider"
	collider.shape = shape
	collider.position.y = size.y * 0.5
	add_child(collider)
	_build_model(size)
	wander_origin = global_position
	_pick_target()

func _build_model(size: Vector3) -> void:
	var spec: Dictionary = SPECIES[species]
	var coat := StandardMaterial3D.new()
	coat.albedo_color = spec["color"]
	coat.roughness = 0.92
	_add_box("Body", size, Vector3(0.0, size.y * 0.52, 0.0), coat)
	_add_box("Head", size * Vector3(0.5, 0.62, 0.72), Vector3(0.0, size.y * 0.88, -size.z * 0.42), coat)
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color("342923")
	_add_box("Eye", Vector3(0.055, 0.055, 0.035), Vector3(size.x * 0.18, size.y * 0.96, -size.z * 0.78), dark)
	for x: float in [-size.x * 0.28, size.x * 0.28]:
		for z: float in [-size.z * 0.25, size.z * 0.25]:
			_add_box("Leg", Vector3(size.x * 0.16, size.y * 0.32, size.z * 0.16), Vector3(x, size.y * 0.16, z), dark)
	var plate := Label3D.new()
	plate.name = "SpeciesLabel"
	plate.text = get_display_name().to_upper()
	plate.position.y = size.y + 0.18
	plate.font_size = 24
	plate.pixel_size = 0.0035
	plate.modulate = Color("f4f0c4")
	plate.outline_size = 6
	plate.outline_modulate = Color(0.03, 0.05, 0.04, 0.95)
	plate.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	plate.no_depth_test = true
	add_child(plate)

func _add_box(part_name: String, dimensions: Vector3, offset: Vector3, material: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	var instance := MeshInstance3D.new()
	instance.name = part_name
	instance.mesh = mesh
	instance.material_override = material
	instance.position = offset
	add_child(instance)

func _physics_process(delta: float) -> void:
	if _defeated:
		return
	_turn_timer -= delta
	_flee_timer = maxf(0.0, _flee_timer - delta)
	if _turn_timer <= 0.0 or global_position.distance_to(_wander_target) < 0.5:
		_pick_target()
	var flat_target := _wander_target - global_position
	flat_target.y = 0.0
	var direction := flat_target.normalized()
	velocity.x = direction.x * _walk_speed * (1.7 if _flee_timer > 0.0 else 1.0)
	velocity.z = direction.z * _walk_speed * (1.7 if _flee_timer > 0.0 else 1.0)
	if direction.length_squared() > 0.01:
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), minf(delta * 3.0, 1.0))
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	else:
		velocity.y = 0.0
	move_and_slide()

func _pick_target() -> void:
	_turn_timer = randf_range(2.5, 6.0)
	var offset := Vector3(randf_range(-5.0, 5.0), 0.0, randf_range(-5.0, 5.0))
	_wander_target = wander_origin + offset

func take_damage(amount: int = 1) -> void:
	if _defeated:
		return
	health = maxi(0, health - maxi(1, amount))
	_flee_timer = 2.5
	_pick_target()
	if health <= 0:
		_defeated = true
		collision_layer = 0
		var collider := get_node_or_null("AnimalCollider") as CollisionShape3D
		if collider != null:
			collider.set_deferred("disabled", true)
		rotation.z = -PI * 0.5
		defeated.emit(self, global_position)
		var timer := get_tree().create_timer(0.25)
		timer.timeout.connect(queue_free)
