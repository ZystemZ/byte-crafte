extends Node3D
class_name ByteCrafterWorld

signal chunk_ready(chunk_coord: Vector2i)
signal blocks_changed

const CHUNK_SIZE := 16
const WORLD_HEIGHT := 40
const STREAM_RADIUS := 2
const SPAWN_CLEAR_RADIUS := 7
const SAVE_PATH := "user://bytecrafter_world.json"
const TEMP_SAVE_PATH := "user://bytecrafter_world.json.tmp"
const MAX_SAVED_OVERRIDES := 250000
const BLOCK_NAMES := {
	0: "Ar",
	1: "Grama",
	2: "Terra",
	3: "Pedra",
	4: "Tronco",
	5: "Folhas",
	6: "Areia",
	7: "Tábuas",
	8: "Musgo",
	9: "Gelo",
	10: "Basalto",
	11: "Cristal",
	12: "Pedra antiga",
	13: "Minério brilhante",
}
const BLOCK_COLORS := {
	1: Color("79a95a"),
	2: Color("8f6242"),
	3: Color("777c82"),
	4: Color("91633f"),
	5: Color("4f8b4c"),
	6: Color("d2bd82"),
	7: Color("bd8c50"),
	8: Color("4f9b67"),
	9: Color("b8e6f2"),
	10: Color("3e414b"),
	11: Color("9f7bea"),
	12: Color("806c58"),
	13: Color("e2b75a"),
}
const BLOCK_ATLAS_TILES := {
	1: [1, 1, 0, 2, 1, 1],
	2: [2, 2, 2, 2, 2, 2],
	3: [3, 3, 3, 3, 3, 3],
	4: [4, 4, 5, 5, 4, 4],
	5: [6, 6, 10, 10, 6, 6],
	6: [7, 7, 7, 7, 7, 7],
	7: [8, 8, 8, 8, 8, 8],
	8: [6, 6, 6, 6, 6, 6],
	9: [7, 7, 7, 7, 7, 7],
	10: [3, 3, 3, 3, 3, 3],
	11: [3, 3, 3, 3, 3, 3],
	12: [3, 3, 3, 3, 3, 3],
	13: [3, 3, 3, 3, 3, 3],
}
const ATLAS_COLUMNS := 4
const ATLAS_ROWS := 3
const FACE_DIRS := [
	Vector3i(1, 0, 0), Vector3i(-1, 0, 0),
	Vector3i(0, 1, 0), Vector3i(0, -1, 0),
	Vector3i(0, 0, 1), Vector3i(0, 0, -1),
]

var world_seed: int = 0
var _terrain_noise := FastNoiseLite.new()
var _height_cache: Dictionary = {}
var _cave_noise := FastNoiseLite.new()
var _biome_noise := FastNoiseLite.new()
var _chunks: Dictionary = {}
var _chunk_queue: Array[Vector2i] = []
var _queued: Dictionary = {}
var _overrides: Dictionary = {}
var _tree_blocks: Dictionary = {}
var _structure_cells: Dictionary = {}
var _built_structure_chunks: Dictionary = {}
var _built_tree_chunks: Dictionary = {}
var _center_chunk := Vector2i(999999, 999999)
var _spawn_column := Vector2i.ZERO
var _voxel_material := StandardMaterial3D.new()
var _stream_radius := STREAM_RADIUS


func _ready() -> void:
	_voxel_material.albedo_texture = load("res://assets/textures/voxel_atlas.png")
	_voxel_material.vertex_color_use_as_albedo = true
	_voxel_material.roughness = 1.0
	_voxel_material.metallic = 0.0
	_voxel_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_voxel_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_voxel_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	_voxel_material.alpha_scissor_threshold = 0.18


func configure(seed_value: int, saved_overrides: Array = [], radius: int = STREAM_RADIUS) -> void:
	world_seed = seed_value
	_stream_radius = clampi(radius, 1, 4)
	_terrain_noise.seed = world_seed
	_terrain_noise.frequency = 0.028
	_terrain_noise.fractal_octaves = 4
	_terrain_noise.fractal_gain = 0.48
	_terrain_noise.fractal_lacunarity = 2.0
	_cave_noise.seed = world_seed ^ 0x5f3759df
	_cave_noise.frequency = 0.065
	_cave_noise.fractal_octaves = 2
	_biome_noise.seed = world_seed ^ 0x13579bdf
	_biome_noise.frequency = 0.012
	_biome_noise.fractal_octaves = 2
	_height_cache.clear()
	_spawn_column = _select_spawn_column()
	_overrides.clear()
	_tree_blocks.clear()
	_built_tree_chunks.clear()
	_structure_cells.clear()
	_built_structure_chunks.clear()
	var accepted := 0
	for entry: Variant in saved_overrides:
		if accepted >= MAX_SAVED_OVERRIDES:
			break
		if not entry is Array or entry.size() < 4:
			continue
		var coords := Vector3i(int(entry[0]), int(entry[1]), int(entry[2]))
		var block_id := int(entry[3])
		if coords.y < 0 or coords.y > WORLD_HEIGHT + 8 or absi(coords.x) > 1000000 or absi(coords.z) > 1000000:
			continue
		if block_id < 0 or block_id > 13:
			continue
		_overrides[coords] = block_id
		accepted += 1
	_center_chunk = Vector2i(999999, 999999)
	update_streaming(get_spawn_position())
	_sanitize_leaf_overrides()


func update_streaming(world_position: Vector3) -> void:
	var center := Vector2i(floori(world_position.x / CHUNK_SIZE), floori(world_position.z / CHUNK_SIZE))
	if center == _center_chunk:
		return
	_center_chunk = center
	# Bound procedural caches to the active streaming area. Tree edits are kept
	# in _overrides, so clearing this derived cache does not regrow mined blocks.
	_height_cache.clear()
	_tree_blocks.clear()
	_built_tree_chunks.clear()
	_structure_cells.clear()
	_built_structure_chunks.clear()
	var keep_distance := _stream_radius + 1
	var retained_queue: Array[Vector2i] = []
	_queued.clear()
	for queued_coord: Vector2i in _chunk_queue:
		if absi(queued_coord.x - center.x) <= keep_distance and absi(queued_coord.y - center.y) <= keep_distance:
			retained_queue.append(queued_coord)
			_queued[queued_coord] = true
	_chunk_queue = retained_queue
	# Cache trees for the visible ring as well as the chunks being generated,
	# because retained edge chunks may contain trees rooted just across a border.
	for x: int in range(center.x - keep_distance, center.x + keep_distance + 1):
		for z: int in range(center.y - keep_distance, center.y + keep_distance + 1):
			var coord := Vector2i(x, z)
			_populate_tree_cache(coord)
			if absi(x - center.x) <= _stream_radius and absi(z - center.y) <= _stream_radius:
				_enqueue_chunk(coord)
	for key: Variant in _chunks.keys():
		var coord: Vector2i = key
		if absi(coord.x - center.x) > keep_distance or absi(coord.y - center.y) > keep_distance:
			var old_chunk: Node = _chunks[coord]
			_chunks.erase(coord)
			old_chunk.queue_free()
	_chunk_queue.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return _chunk_distance_sq(a, center) < _chunk_distance_sq(b, center)
	)
	# The chunk under the player must never depend on the asynchronous queue.
	# Build it immediately when entering a new chunk; surrounding chunks can stream
	# one per frame without leaving a temporary hole directly beneath the player.
	if not _chunks.has(center):
		_build_chunk(center)


func _process(_delta: float) -> void:
	if _chunk_queue.is_empty():
		return
	var coord: Vector2i = _chunk_queue.pop_front()
	_queued.erase(coord)
	if absf(float(coord.x - _center_chunk.x)) > float(_stream_radius + 1) or absf(float(coord.y - _center_chunk.y)) > float(_stream_radius + 1):
		return
	if not _chunks.has(coord):
		_build_chunk(coord)


func _chunk_distance_sq(a: Vector2i, b: Vector2i) -> int:
	return (a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y)


func _enqueue_chunk(coord: Vector2i) -> void:
	if _chunks.has(coord) or _queued.has(coord):
		return
	_queued[coord] = true
	_chunk_queue.append(coord)


func _populate_tree_cache(chunk_coord: Vector2i) -> void:
	if _built_tree_chunks.has(chunk_coord):
		return
	_built_tree_chunks[chunk_coord] = true
	var start_x := chunk_coord.x * CHUNK_SIZE - 2
	var end_x := (chunk_coord.x + 1) * CHUNK_SIZE + 2
	var start_z := chunk_coord.y * CHUNK_SIZE - 2
	var end_z := (chunk_coord.y + 1) * CHUNK_SIZE + 2
	for x: int in range(start_x, end_x):
		for z: int in range(start_z, end_z):
			if not _is_tree_root(x, z):
				continue
			var ground := terrain_height(x, z)
			for y: int in range(ground + 1, ground + 5):
				_tree_blocks[Vector3i(x, y, z)] = 4
			var crown_y := ground + 4
			for y: int in range(crown_y, crown_y + 3):
				var radius := 2 if y >= crown_y + 1 else 1
				for dx: int in range(-radius, radius + 1):
						for dz: int in range(-radius, radius + 1):
							if absi(dx) + absi(dz) <= radius + 1:
								var leaf_pos := Vector3i(x + dx, y, z + dz)
								# Copas em encostas não podem substituir terreno sólido.
								if not _tree_blocks.has(leaf_pos) and _base_block(leaf_pos) == 0:
									_tree_blocks[leaf_pos] = 5


func _populate_structure_cache(chunk_coord: Vector2i) -> void:
	if _built_structure_chunks.has(chunk_coord):
		return
	_built_structure_chunks[chunk_coord] = true
	var hash_value := absi(chunk_coord.x * 92821 + chunk_coord.y * 68917 + world_seed * 31)
	if hash_value % 13 != 0:
		return
	var center_x := chunk_coord.x * CHUNK_SIZE + 8
	var center_z := chunk_coord.y * CHUNK_SIZE + 8
	if Vector2(center_x - _spawn_column.x, center_z - _spawn_column.y).length() < 24.0:
		return
	var ground := terrain_height(center_x, center_z)
	var structure_block := 12 if get_biome(center_x, center_z) != "crystal" else 13
	for dx: int in range(-2, 3):
		for dz: int in range(-2, 3):
			if absi(dx) == 2 or absi(dz) == 2:
				_structure_cells[Vector3i(center_x + dx, ground + 1, center_z + dz)] = structure_block
	for tower_height: int in range(1, 4):
		_structure_cells[Vector3i(center_x, ground + tower_height, center_z)] = structure_block
	_structure_cells[Vector3i(center_x, ground + 4, center_z)] = 13


func get_biome(x: int, z: int) -> String:
	var climate := _biome_noise.get_noise_2d(float(x), float(z))
	if climate > 0.58:
		return "crystal"
	if climate < -0.62:
		return "volcanic"
	if climate < -0.18:
		return "frozen"
	if climate > 0.18:
		return "mossland"
	return "plains"


func _is_tree_root(x: int, z: int) -> bool:
	if absi(x - _spawn_column.x) <= SPAWN_CLEAR_RADIUS and absi(z - _spawn_column.y) <= SPAWN_CLEAR_RADIUS:
		return false
	var height := terrain_height(x, z)
	if height < 7 or height > WORLD_HEIGHT - 8:
		return false
	if _base_block(Vector3i(x, height, z)) != 1:
		return false
	var seed_value := float(x * 127 + z * 311 + world_seed * 17)
	var roll := int(absf(sin(seed_value * 0.0174533) * 43758.5453)) % 37
	return roll == 0


func terrain_height(x: int, z: int) -> int:
	var key := Vector2i(x, z)
	if _height_cache.has(key):
		return int(_height_cache[key])
	var broad := _terrain_noise.get_noise_2d(float(x), float(z))
	var ridge := sin(float(x) * 0.065 + float(world_seed % 97)) * cos(float(z) * 0.053)
	var result := clampi(10 + roundi(broad * 7.0 + ridge * 2.0), 4, WORLD_HEIGHT - 7)
	_height_cache[key] = result
	return result


func _select_spawn_column() -> Vector2i:
	var best := Vector2i.ZERO
	var best_score: float = INF
	for x: int in range(-12, 13, 2):
		for z: int in range(-12, 13, 2):
			var center_height := terrain_height(x, z)
			var min_height := center_height
			var max_height := center_height
			var height_deviation := 0.0
			for dx: int in range(-4, 5, 2):
				for dz: int in range(-4, 5, 2):
					var neighbor_height := terrain_height(x + dx, z + dz)
					min_height = mini(min_height, neighbor_height)
					max_height = maxi(max_height, neighbor_height)
					height_deviation += absf(float(neighbor_height - center_height))
			var distance_penalty := Vector2(float(x), float(z)).length() * 0.035
			var score := float(max_height - min_height) * 4.0 + height_deviation + distance_penalty
			if score < best_score:
				best_score = score
				best = Vector2i(x, z)
	return best


func get_block_at(coords: Vector3i) -> int:
	if coords.y < 0 or coords.y > WORLD_HEIGHT:
		return 0
	if _overrides.has(coords):
		var override_id := int(_overrides[coords])
		# Perfis antigos podem conter folhas colocadas no chão. Nunca as
		# devolva ao renderer fora de uma célula de copa procedural válida.
		if override_id == 5 and int(_tree_blocks.get(coords, 0)) != 5:
			return _base_block(coords)
		return override_id
	if _tree_blocks.has(coords):
		return int(_tree_blocks[coords])
	if _structure_cells.has(coords):
		return int(_structure_cells[coords])
	return _base_block(coords)


func _base_block(coords: Vector3i) -> int:
	var height := terrain_height(coords.x, coords.z)
	if coords.y > height:
		return 0
	if coords.y > 2 and coords.y < height - 3 and _cave_noise.get_noise_3d(float(coords.x), float(coords.y), float(coords.z)) > 0.52:
		return 0
	var biome := get_biome(coords.x, coords.z)
	if coords.y == height:
		if biome == "frozen":
			return 9
		if biome == "volcanic":
			return 10
		if biome == "crystal":
			return 11
		if biome == "mossland":
			return 8
		return 6 if height <= 7 else 1
	if coords.y >= height - 3:
		return 10 if biome == "volcanic" and coords.y == height - 1 else 2
	return 3


func get_spawn_position() -> Vector3:
	var x := _spawn_column.x
	var z := _spawn_column.y
	return Vector3(float(x) + 0.5, float(terrain_height(x, z)) + 1.12, float(z) + 0.5)


func set_block_at(coords: Vector3i, block_id: int) -> bool:
	if coords.y < 0 or coords.y > WORLD_HEIGHT or block_id < 0 or block_id > 13:
		return false
	# Folhas são parte da copa procedural; não podem ser usadas como piso ou
	# colocadas livremente no mundo. Uma célula de copa ainda pode ser restaurada.
	if block_id == 5 and int(_tree_blocks.get(coords, 0)) != 5:
		return false
	if get_block_at(coords) == block_id:
		return false
	_overrides[coords] = block_id
	_rebuild_chunk_and_neighbours(coords)
	blocks_changed.emit()
	return true


func _sanitize_leaf_overrides() -> void:
	var invalid_leaf_cells: Array[Vector3i] = []
	for coords: Vector3i in _overrides.keys():
		if int(_overrides[coords]) == 5 and int(_tree_blocks.get(coords, 0)) != 5:
			invalid_leaf_cells.append(coords)
	for coords: Vector3i in invalid_leaf_cells:
		_overrides.erase(coords)
		_rebuild_chunk_and_neighbours(coords)


func _rebuild_chunk_and_neighbours(coords: Vector3i) -> void:
	var base := Vector2i(floori(float(coords.x) / CHUNK_SIZE), floori(float(coords.z) / CHUNK_SIZE))
	var candidates := [base]
	if posmod(coords.x, CHUNK_SIZE) == 0:
		candidates.append(base + Vector2i(-1, 0))
	elif posmod(coords.x, CHUNK_SIZE) == CHUNK_SIZE - 1:
		candidates.append(base + Vector2i(1, 0))
	if posmod(coords.z, CHUNK_SIZE) == 0:
		candidates.append(base + Vector2i(0, -1))
	elif posmod(coords.z, CHUNK_SIZE) == CHUNK_SIZE - 1:
		candidates.append(base + Vector2i(0, 1))
	for coord: Vector2i in candidates:
		if _chunks.has(coord):
			_build_chunk(coord)


const _PAD_X := CHUNK_SIZE + 2
const _PAD_Z := CHUNK_SIZE + 2
const _PAD_Y := WORLD_HEIGHT + 3


static func _snapshot_index(local_x: int, y: int, local_z: int) -> int:
	return ((local_x + 1) * _PAD_Z + (local_z + 1)) * _PAD_Y + (y + 1)


## Amostra uma única vez todos os blocos do chunk com 1 bloco de margem em cada
## direção. A malha, as colisões e as faces de borda saem do mesmo snapshot, que
## por sua vez vem de get_block_at() (única fonte de verdade: overrides + árvores
## + estruturas + terreno procedural).
func _sample_chunk_snapshot(coord: Vector2i) -> PackedByteArray:
	var origin_x := coord.x * CHUNK_SIZE
	var origin_z := coord.y * CHUNK_SIZE
	var snapshot := PackedByteArray()
	snapshot.resize(_PAD_X * _PAD_Z * _PAD_Y)
	for local_x: int in range(-1, CHUNK_SIZE + 1):
		for local_z: int in range(-1, CHUNK_SIZE + 1):
			var x := origin_x + local_x
			var z := origin_z + local_z
			# y=-1 e y=WORLD_HEIGHT+1 ficam como ar (get_block_at já retorna 0).
			for y: int in range(0, WORLD_HEIGHT + 1):
				snapshot[_snapshot_index(local_x, y, local_z)] = get_block_at(Vector3i(x, y, z))
	return snapshot


func _build_chunk(coord: Vector2i) -> void:
	var origin_x := coord.x * CHUNK_SIZE
	var origin_z := coord.y * CHUNK_SIZE
	var snapshot := _sample_chunk_snapshot(coord)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var face_count := 0
	var trunk_cells: Array[Vector3i] = []
	for local_x: int in CHUNK_SIZE:
		for local_z: int in CHUNK_SIZE:
			# Copas podem ultrapassar a altura local do terreno quando a raiz está em
			# uma coluna vizinha mais alta; varremos toda a altura jogável.
			for y: int in range(0, WORLD_HEIGHT + 1):
				var block_id := int(snapshot[_snapshot_index(local_x, y, local_z)])
				if block_id == 0:
					continue
				var block_pos := Vector3i(origin_x + local_x, y, origin_z + local_z)
				if block_id == 4:
					trunk_cells.append(Vector3i(local_x, y, local_z))
				for face_index: int in FACE_DIRS.size():
					var dir: Vector3i = FACE_DIRS[face_index]
					if snapshot[_snapshot_index(local_x + dir.x, y + dir.y, local_z + dir.z)] == 0:
						_add_face(surface, Vector3(float(local_x), float(y), float(local_z)), block_id, face_index, block_pos)
						face_count += 1
	if face_count == 0:
		_discard_chunk(coord)
		return
	var mesh := surface.commit() as ArrayMesh
	if mesh == null:
		return
	var collision_mesh := mesh.create_trimesh_shape() as ConcavePolygonShape3D
	if collision_mesh == null or collision_mesh.get_faces().is_empty():
		# Mantém o corpo anterior (se houver) em vez de abrir um buraco no mundo.
		push_error("ByteCrafter: não foi possível gerar a colisão do chunk %s." % [coord])
		return
	collision_mesh.backface_collision = true
	var body := StaticBody3D.new()
	body.name = "Chunk_%d_%d" % [coord.x, coord.y]
	body.position = Vector3(float(origin_x), 0.0, float(origin_z))
	body.collision_layer = 1
	body.collision_mask = 0
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _voxel_material
	body.add_child(mesh_instance)
	var collider := CollisionShape3D.new()
	collider.name = "ChunkCollision"
	collider.shape = collision_mesh
	body.add_child(collider)
	# Troncos continuam com caixas próprias: baratas e inequívocas.
	for cell: Vector3i in trunk_cells:
		var trunk_shape := BoxShape3D.new()
		trunk_shape.size = Vector3.ONE * 0.98
		var trunk_collider := CollisionShape3D.new()
		trunk_collider.name = "TreeTrunkCollision"
		trunk_collider.shape = trunk_shape
		trunk_collider.position = Vector3(float(cell.x) + 0.5, float(cell.y) + 0.5, float(cell.z) + 0.5)
		body.add_child(trunk_collider)
	# Troca sem lacuna: o corpo novo já está pronto antes de o antigo sair da
	# árvore física, e o antigo é removido imediatamente (sem colisão duplicada).
	var previous: Node = _chunks.get(coord)
	if previous != null:
		_detach_chunk_body(previous)
	add_child(body)
	_chunks[coord] = body
	chunk_ready.emit(coord)


func _discard_chunk(coord: Vector2i) -> void:
	var previous: Node = _chunks.get(coord)
	if previous != null:
		_chunks.erase(coord)
		_detach_chunk_body(previous)


func _detach_chunk_body(body: Node) -> void:
	if body.get_parent() == self:
		remove_child(body)
	body.queue_free()


func _add_face(surface: SurfaceTool, origin: Vector3, block_id: int, face_index: int, block_pos: Vector3i) -> void:
	var points: Array[Vector3]
	var normal: Vector3
	match face_index:
		0:
			normal = Vector3.RIGHT
			points = [Vector3(1, 0, 0), Vector3(1, 1, 0), Vector3(1, 1, 1), Vector3(1, 0, 1)]
		1:
			normal = Vector3.LEFT
			points = [Vector3(0, 0, 0), Vector3(0, 0, 1), Vector3(0, 1, 1), Vector3(0, 1, 0)]
		2:
			normal = Vector3.UP
			points = [Vector3(0, 1, 0), Vector3(0, 1, 1), Vector3(1, 1, 1), Vector3(1, 1, 0)]
		3:
			normal = Vector3.DOWN
			points = [Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(1, 0, 1), Vector3(0, 0, 1)]
		4:
			normal = Vector3.BACK
			points = [Vector3(0, 0, 1), Vector3(1, 0, 1), Vector3(1, 1, 1), Vector3(0, 1, 1)]
		_:
			normal = Vector3.FORWARD
			points = [Vector3(0, 0, 0), Vector3(0, 1, 0), Vector3(1, 1, 0), Vector3(1, 0, 0)]
	var shade := 1.0 if face_index == 2 else (0.58 if face_index == 3 else 0.82)
	var variation := 0.94 + float(absi(block_pos.x * 13 + block_pos.y * 29 + block_pos.z * 7) % 7) * 0.018
	var brightness := shade * variation
	var base_tint: Color = BLOCK_COLORS.get(block_id, Color.WHITE)
	var color := Color(base_tint.r * brightness, base_tint.g * brightness, base_tint.b * brightness, 1.0) if block_id >= 8 else Color(brightness, brightness, brightness, 1.0)
	var tile_indices: Array = BLOCK_ATLAS_TILES.get(block_id, BLOCK_ATLAS_TILES[3])
	var tile_index := int(tile_indices[face_index])
	var tile_size := Vector2(1.0 / float(ATLAS_COLUMNS), 1.0 / float(ATLAS_ROWS))
	var tile_origin := Vector2(atlas_tile_coords(tile_index)) * tile_size
	var pixel_inset := Vector2(0.5 / 64.0, 0.5 / 48.0)
	var uv_min := tile_origin + pixel_inset
	var uv_max := tile_origin + tile_size - pixel_inset
	# As faces verticais percorrem a malha de baixo para cima. Inverter V
	# nelas mantém a grama no topo e a terra na parte inferior do tile lateral.
	var face_uvs: Array[Vector2]
	if face_index == 0 or face_index == 1 or face_index == 4 or face_index == 5:
		face_uvs = [Vector2(0, 1), Vector2(0, 0), Vector2(1, 0), Vector2(1, 1)]
	else:
		face_uvs = [Vector2(0, 0), Vector2(0, 1), Vector2(1, 1), Vector2(1, 0)]
	for point_index: int in [0, 1, 2, 0, 2, 3]:
		surface.set_normal(normal)
		surface.set_color(color)
		var uv_factor: Vector2 = face_uvs[point_index]
		surface.set_uv(Vector2(lerpf(uv_min.x, uv_max.x, uv_factor.x), lerpf(uv_min.y, uv_max.y, uv_factor.y)))
		surface.add_vertex(origin + points[point_index])


static func atlas_tile_coords(tile_index: int) -> Vector2i:
	return Vector2i(posmod(tile_index, ATLAS_COLUMNS), floori(float(tile_index) / float(ATLAS_COLUMNS)))


func get_chunk_count() -> int:
	return _chunks.size()


func get_override_count() -> int:
	return _overrides.size()


func get_overrides_array() -> Array:
	var result: Array = []
	for key: Variant in _overrides.keys():
		var coords: Vector3i = key
		result.append([coords.x, coords.y, coords.z, int(_overrides[coords])])
	return result


func save_to_disk() -> bool:
	var file := FileAccess.open(TEMP_SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("ByteCrafter: não foi possível abrir o arquivo temporário do mundo para gravação.")
		return false
	file.store_string(JSON.stringify({"version": 1, "seed": world_seed, "overrides": get_overrides_array()}, "  "))
	file.flush()
	file.close()

	var temporary := ProjectSettings.globalize_path(TEMP_SAVE_PATH)
	var destination := ProjectSettings.globalize_path(SAVE_PATH)
	var backup := ProjectSettings.globalize_path(SAVE_PATH + ".bak")
	var had_previous := FileAccess.file_exists(SAVE_PATH)
	if had_previous:
		if FileAccess.file_exists(SAVE_PATH + ".bak"):
			DirAccess.remove_absolute(backup)
		var backup_error := DirAccess.rename_absolute(destination, backup)
		if backup_error != OK:
			push_error("ByteCrafter: não foi possível proteger o save anterior.")
			return false
	var commit_error := DirAccess.rename_absolute(temporary, destination)
	if commit_error != OK:
		if had_previous:
			DirAccess.rename_absolute(backup, destination)
		push_error("ByteCrafter: falha ao finalizar o salvamento do mundo.")
		return false
	if FileAccess.file_exists(SAVE_PATH + ".bak"):
		DirAccess.remove_absolute(backup)
	return true

static func load_from_disk() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary or int(parsed.get("version", 0)) != 1:
		return {}
	var raw_overrides: Variant = parsed.get("overrides", [])
	if not raw_overrides is Array:
		return {}
	var clean_overrides: Array = []
	for entry: Variant in raw_overrides:
		if clean_overrides.size() >= MAX_SAVED_OVERRIDES:
			break
		if not entry is Array or entry.size() < 4:
			continue
		var x := int(entry[0])
		var y := int(entry[1])
		var z := int(entry[2])
		var block_id := int(entry[3])
		if y < 0 or y > WORLD_HEIGHT + 8 or absi(x) > 1000000 or absi(z) > 1000000:
			continue
		if block_id < 0 or block_id > 13:
			continue
		clean_overrides.append([x, y, z, block_id])
	return {"version": 1, "seed": int(parsed.get("seed", 0)), "overrides": clean_overrides}
