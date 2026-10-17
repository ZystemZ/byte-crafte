extends Node

const WORLD_SCRIPT := preload("res://scripts/game/voxel_world.gd")
const GAME_SCENE := preload("res://scenes/main.tscn")
const RECIPE_BOOK := preload("res://scripts/game/crafting_recipe_book.gd")

var _failures := PackedStringArray()
var _checks := 0
var _saved_user_files: Dictionary = {}


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	# Exercise saves in a disposable fixture and restore every user's file byte-for-byte.
	for path: String in ["user://bytecrafter_world.json", "user://bytecrafter_player.json", SaveStore.SAVE_PATH]:
		_saved_user_files[path] = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null
	_test_localization()
	_test_recipe_book()
	_test_seeded_world()
	_test_voxel_integrity()
	await _test_playable_loop()
	Input.action_release("move_up")
	Input.action_release("move_down")
	Input.action_release("move_left")
	Input.action_release("move_right")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await get_tree().process_frame
	_restore_user_files()
	if _failures.is_empty():
		print("[bytecrafter-tests] PASS: %d checks" % _checks)
		get_tree().quit(0)
		return
	for failure: String in _failures:
		push_error("[bytecrafter-tests] " + failure)
	print("[bytecrafter-tests] FAIL: %d failures across %d checks" % [_failures.size(), _checks])
	get_tree().quit(1)


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)


func _restore_user_files() -> void:
	for path: String in _saved_user_files:
		var original: Variant = _saved_user_files[path]
		if original == null:
			if FileAccess.file_exists(path):
				_check(DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK, "test save must be removed: " + path)
		else:
			var file := FileAccess.open(path, FileAccess.WRITE)
			_check(file != null, "original user file must be writable: " + path)
			if file != null:
				file.store_buffer(original)
				file.close()
				_check(FileAccess.get_file_as_bytes(path) == original, "original user file must be restored byte-for-byte: " + path)


func _test_recipe_book() -> void:
	var single_log: Array = [null, null, null, null, 4, null, null, null, null]
	var planks: Dictionary = RECIPE_BOOK.find_grid_recipe(single_log)
	_check(planks.get("id", "") == "oak_planks" and int(planks.get("item", -1)) == 7 and int(planks.get("quantity", 0)) == 4, "one log in any crafting cell must produce four planks")
	var vertical_pair: Array = [null, 7, null, null, 7, null, null, null, null]
	var sticks: Dictionary = RECIPE_BOOK.find_grid_recipe(vertical_pair)
	_check(sticks.get("id", "") == "sticks" and sticks.get("item", null) == "gravetos", "two vertically adjacent planks must produce sticks")
	var horizontal_pair: Array = [7, 7, null, null, null, null, null, null, null]
	_check(RECIPE_BOOK.find_grid_recipe(horizontal_pair).is_empty(), "horizontal planks must not match the vertical stick recipe")
	var pickaxe_pattern: Array = [7, 7, 7, null, "gravetos", null, null, "gravetos", null]
	var pickaxe: Dictionary = RECIPE_BOOK.find_grid_recipe(pickaxe_pattern)
	_check(pickaxe.get("id", "") == "wood_pickaxe" and int(pickaxe.get("max_stack", 0)) == 999, "the wooden pickaxe pattern and stack limit must come from the recipe catalog")
	var extra_item_pattern: Array = [7, 7, 7, 1, "gravetos", null, null, "gravetos", null]
	_check(RECIPE_BOOK.find_grid_recipe(extra_item_pattern).is_empty(), "an extra ingredient must invalidate an exact recipe pattern")
	_check(RECIPE_BOOK.get_quick_recipe("planks").get("id", "") == "oak_planks" and RECIPE_BOOK.get_quick_recipe("unknown").is_empty(), "quick crafting must use the same catalog and reject unknown actions")


func _test_localization() -> void:
	_check(I18n.get_locale() == "pt-BR", "the new game must stay in Brazilian Portuguese")
	_check(I18n.t("app.title") == "ByteCrafter", "the Portuguese catalog must carry the correct game title")
	_check(I18n.detect_locale("en_US") == "pt-BR", "OS language must not replace the requested game language")
	I18n.set_locale("en")
	_check(I18n.get_locale() == "pt-BR", "the single-language game must not switch to an inherited locale")


func _test_seeded_world() -> void:
	var world_a := WORLD_SCRIPT.new() as ByteCrafterWorld
	var world_b := WORLD_SCRIPT.new() as ByteCrafterWorld
	_check(ByteCrafterWorld.atlas_tile_coords(1) == Vector2i(1, 0), "grass side must map to atlas row 0")
	_check(ByteCrafterWorld.atlas_tile_coords(5) == Vector2i(1, 1), "log top must map to atlas row 1")
	_check(ByteCrafterWorld.atlas_tile_coords(8) == Vector2i(0, 2), "oak planks must map to atlas tile 8")
	_check(ByteCrafterWorld.atlas_tile_coords(9) == Vector2i(1, 2), "cobblestone must map to atlas row 2")
	_check(int(ByteCrafterWorld.BLOCK_ATLAS_TILES[7][2]) == 8, "planks must sample the oak planks tile")
	world_a.configure(120303788, [], 1)
	world_b.configure(120303788, [], 1)
	var height_a := world_a.terrain_height(17, -29)
	var height_b := world_b.terrain_height(17, -29)
	_check(height_a == height_b, "the same world seed must reproduce terrain height")
	_check(height_a > 0 and height_a < ByteCrafterWorld.WORLD_HEIGHT, "terrain must remain within the playable world bounds")
	var spawn_position: Vector3 = world_a.get_spawn_position()
	var spawn_cell := Vector3i(floori(spawn_position.x), floori(spawn_position.y), floori(spawn_position.z))
	_check(world_a.get_block_at(spawn_cell) == 0, "the selected spawn cell must remain clear of trunks and canopy")
	_check(world_a.get_block_at(spawn_cell - Vector3i.UP) > 0, "the selected spawn must have a solid support block")
	var ground_leaf_cell := spawn_cell + Vector3i.UP
	_check(world_a.get_block_at(ground_leaf_cell) != 5, "world generation must never use leaves as a ground block")
	_check(not world_a.set_block_at(ground_leaf_cell, 5), "leaves must be rejected outside generated tree crowns")
	_check(world_a.get_block_at(ground_leaf_cell) != 5, "a rejected ground leaf must remain absent")
	var surface := Vector3i(17, height_a, -29)
	var original_block := world_a.get_block_at(surface)
	_check(original_block > 0, "generated terrain must have a solid surface block")
	_check(world_a.set_block_at(surface, 0), "a surface voxel must be breakable")
	_check(world_a.get_block_at(surface) == 0, "a broken voxel must become air")
	_check(world_a.set_block_at(surface, 7), "a block can be placed back into the world")
	_check(world_a.get_block_at(surface) == 7, "the placed block must be visible in world data")
	_check(world_a.get_block_at(Vector3i(0, -1, 0)) == 0, "positions below the world must be empty")
	_check(world_a.get_block_at(Vector3i(0, ByteCrafterWorld.WORLD_HEIGHT + 1, 0)) == 0, "positions above the generated world must be empty")
	_check(not world_a.set_block_at(Vector3i(0, ByteCrafterWorld.WORLD_HEIGHT + 1, 0), 7), "placing above the generated world must be rejected")
	var loaded_chunks: Dictionary = world_a.get("_chunks")
	_check(not loaded_chunks.is_empty(), "the configured world must build its center chunk immediately")
	var collision_chunks := 0
	var valid_chunk_collisions := true
	for chunk_value: Variant in loaded_chunks.values():
		var chunk_body := chunk_value as StaticBody3D
		var chunk_collision := chunk_body.get_node_or_null("ChunkCollision") as CollisionShape3D if chunk_body != null else null
		var chunk_shape := chunk_collision.shape as ConcavePolygonShape3D if chunk_collision != null else null
		if chunk_shape != null and not chunk_shape.get_faces().is_empty():
			collision_chunks += 1
		else:
			valid_chunk_collisions = false
	_check(collision_chunks == loaded_chunks.size() and valid_chunk_collisions, "every loaded chunk must have a non-empty collision shape")
	world_a.call("_build_chunk", Vector2i(0, 0))
	world_a.call("_build_chunk", Vector2i(1, 0))
	var left_body_before := (world_a.get("_chunks") as Dictionary).get(Vector2i(0, 0)) as StaticBody3D
	var right_body_before := (world_a.get("_chunks") as Dictionary).get(Vector2i(1, 0)) as StaticBody3D
	var boundary := Vector3i(16, world_a.terrain_height(16, 0), 0)
	_check(world_a.get_block_at(boundary) > 0, "a chunk-boundary surface voxel must be solid before editing")
	_check(world_a.set_block_at(boundary, 0), "editing a boundary voxel must rebuild its owning chunk")
	var rebuilt_chunks: Dictionary = world_a.get("_chunks")
	_check(rebuilt_chunks.has(Vector2i(0, 0)) and rebuilt_chunks.has(Vector2i(1, 0)), "editing a border voxel must keep both adjacent chunks available")
	var left_body := rebuilt_chunks.get(Vector2i(0, 0)) as StaticBody3D
	var right_body := rebuilt_chunks.get(Vector2i(1, 0)) as StaticBody3D
	_check(left_body != left_body_before and right_body != right_body_before, "editing a border voxel must replace both affected chunk bodies")
	_check(left_body.get_node_or_null("ChunkCollision") != null and right_body.get_node_or_null("ChunkCollision") != null, "both chunks adjacent to an edited border must retain collision nodes")
	var tree_cell := Vector3i(999999, -1, 999999)
	for tree_x: int in range(-48, 49):
		for tree_z: int in range(-48, 49):
			var tree_ground := world_a.terrain_height(tree_x, tree_z)
			for tree_y: int in range(tree_ground + 1, tree_ground + 8):
				var candidate := Vector3i(tree_x, tree_y, tree_z)
				if world_a.get_block_at(candidate) in [4, 5]:
					tree_cell = candidate
					break
			if tree_cell.y >= 0:
				break
		if tree_cell.y >= 0:
			break
	_check(tree_cell.y >= 0, "the generated world must expose a testable tree trunk or leaf block")
	if tree_cell.y >= 0:
		var tree_kind := world_a.get_block_at(tree_cell)
		_check(tree_kind in [4, 5], "the test tree block must be a trunk or leaf")
		_check(world_a.set_block_at(tree_cell, 0), "a generated tree block must be breakable through world editing")
		_check(world_a.get_block_at(tree_cell) == 0, "a broken tree block must stay empty")
		_check(world_a.set_block_at(tree_cell, 7), "a block must be placeable in a cleared tree cell")
		_check(world_a.get_block_at(tree_cell) == 7, "a placed block must not be replaced by the procedural tree cache")
		var remaining_tree := tree_cell + Vector3i.UP
		_check(world_a.get_block_at(remaining_tree) in [0, 4, 5], "editing one tree cell must not delete neighboring tree blocks")
		world_a.update_streaming(Vector3(320.0, 0.0, 320.0))
		world_a.update_streaming(world_a.get_spawn_position())
		_check(world_a.get_block_at(tree_cell) == 7, "a placed block in a tree must survive streaming rebuilds")
	world_a.free()
	world_b.free()


## Integridade voxel (P0): malha, colisão e dados de bloco precisam concordar.
func _count_expected_faces(world: ByteCrafterWorld, coord: Vector2i) -> int:
	var faces := 0
	for local_x: int in ByteCrafterWorld.CHUNK_SIZE:
		for local_z: int in ByteCrafterWorld.CHUNK_SIZE:
			for y: int in range(0, ByteCrafterWorld.WORLD_HEIGHT + 1):
				var pos := Vector3i(coord.x * ByteCrafterWorld.CHUNK_SIZE + local_x, y, coord.y * ByteCrafterWorld.CHUNK_SIZE + local_z)
				if world.get_block_at(pos) == 0:
					continue
				for dir: Vector3i in ByteCrafterWorld.FACE_DIRS:
					if ByteCrafterWorld._face_is_exposed(world.get_block_at(pos), world.get_block_at(pos + dir)):
						faces += 1
	return faces


func _count_blocks(world: ByteCrafterWorld, coord: Vector2i, block_id: int) -> int:
	var count := 0
	for local_x: int in ByteCrafterWorld.CHUNK_SIZE:
		for local_z: int in ByteCrafterWorld.CHUNK_SIZE:
			for y: int in range(0, ByteCrafterWorld.WORLD_HEIGHT + 1):
				if world.get_block_at(Vector3i(coord.x * ByteCrafterWorld.CHUNK_SIZE + local_x, y, coord.y * ByteCrafterWorld.CHUNK_SIZE + local_z)) == block_id:
					count += 1
	return count


func _chunk_mesh_vertex_count(body: StaticBody3D) -> int:
	for child: Node in body.get_children():
		var instance := child as MeshInstance3D
		if instance != null and instance.mesh != null and instance.mesh.get_surface_count() > 0:
			return (instance.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	return -1


func _test_voxel_integrity() -> void:
	var world := WORLD_SCRIPT.new() as ByteCrafterWorld
	world.configure(120303788, [], 1)
	var chunks: Dictionary = world.get("_chunks")
	for coord: Vector2i in [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(-1, -1), Vector2i(1, 0)]:
		world.call("_build_chunk", coord)
		var body := chunks.get(coord) as StaticBody3D
		_check(body != null, "chunk %s must be built" % [coord])
		if body == null:
			continue
		var expected_faces := _count_expected_faces(world, coord)
		var vertex_count := _chunk_mesh_vertex_count(body)
		_check(vertex_count == expected_faces * 6, "chunk %s mesh must contain exactly the faces implied by block data (%d vs %d)" % [coord, vertex_count / 6, expected_faces])
		var collision := body.get_node_or_null("ChunkCollision") as CollisionShape3D
		var shape := collision.shape as ConcavePolygonShape3D if collision != null else null
		_check(shape != null and shape.get_faces().size() == vertex_count, "chunk %s collision triangles must match the visible mesh" % [coord])
		var trunk_colliders := 0
		for child: Node in body.get_children():
			if child.name.begins_with("TreeTrunkCollision"):
				trunk_colliders += 1
		_check(trunk_colliders == _count_blocks(world, coord, 4), "chunk %s must have one trunk collider per trunk block" % [coord])
	# Reconstruir um chunk não pode deixar corpos obsoletos nem lacunas.
	var rebuilt_coord := Vector2i(0, 0)
	var before := chunks.get(rebuilt_coord) as StaticBody3D
	world.call("_build_chunk", rebuilt_coord)
	var after := chunks.get(rebuilt_coord) as StaticBody3D
	_check(after != null and after != before, "rebuilding must install a fresh chunk body")
	_check(before != null and before.get_parent() == null, "the replaced chunk body must leave the physics tree immediately")
	var chunk_children := 0
	for child: Node in world.get_children():
		if child is StaticBody3D:
			chunk_children += 1
	_check(chunk_children == chunks.size(), "the world must keep exactly one body per loaded chunk (no stale colliders)")
	_check(ByteCrafterWorld._face_is_exposed(2, 5) and ByteCrafterWorld._face_is_exposed(4, 5) and ByteCrafterWorld._face_is_exposed(3, 0), "faces behind transparent leaves must be drawn")
	_check(not ByteCrafterWorld._face_is_exposed(5, 5) and not ByteCrafterWorld._face_is_exposed(2, 3), "leaf-to-leaf and solid-to-solid faces must stay culled")
	# Copas nunca substituem terreno sólido.
	var tree_blocks: Dictionary = world.get("_tree_blocks")
	var leaves_over_terrain := 0
	for key: Variant in tree_blocks.keys():
		var cell: Vector3i = key
		if int(tree_blocks[cell]) == 5 and int(world.call("_base_block", cell)) != 0:
			leaves_over_terrain += 1
	_check(leaves_over_terrain == 0, "tree crowns must not overwrite solid terrain")
	# Borda de chunk: remover o bloco e recolocar mantém as duas faces coerentes.
	var edge := Vector3i(15, world.terrain_height(15, 4), 4)
	var original := world.get_block_at(edge)
	_check(world.set_block_at(edge, 0), "an edge voxel must be removable")
	_check(world.set_block_at(edge, original), "an edge voxel must be restorable")
	for coord: Vector2i in [Vector2i(0, 0), Vector2i(1, 0)]:
		var edge_body := chunks.get(coord) as StaticBody3D
		if edge_body != null:
			_check(_chunk_mesh_vertex_count(edge_body) == _count_expected_faces(world, coord) * 6, "chunk %s must stay consistent after an edge edit" % [coord])
	world.free()


func _test_playable_loop() -> void:
	var game := GAME_SCENE.instantiate()
	get_tree().root.add_child(game)
	for _frame: int in 8:
		await get_tree().process_frame
	_check(str(game.get("_screen")) == "title", "the game must open on its title screen")
	_check(I18n.t("app.title") == "ByteCrafter", "the game autoloads must be available in the playable scene")
	var title_screen := game.get("_title_screen") as Control
	var menu_background := title_screen.find_child("MenuBackground", true, false) as TextureRect if title_screen != null else null
	_check(menu_background != null and menu_background.texture != null, "the title menu must show the user-provided full-screen artwork")
	game.call("_reset_player_profile")
	game.call("_create_world", 120303788, [])
	game.call("_set_selected_avatar", "girl2")
	game.call("_enter_game")
	for _frame: int in 18:
		await get_tree().physics_frame
	var world: ByteCrafterWorld = game.get("_world") as ByteCrafterWorld
	var player: ByteCrafterPlayer = game.get("_player") as ByteCrafterPlayer
	var inventory: Dictionary = game.get("_inventory")
	var enemies: Array = game.get("_enemies")
	var player_cell := Vector3i(floori(player.global_position.x), floori(player.global_position.y), floori(player.global_position.z))
	_check(bool(game.call("_placement_overlaps_player", player_cell)), "placement validation must detect overlap with the player collider")
	_check(str(game.get("_screen")) == "game", "starting a new world must enter gameplay")
	_check(player != null and player.can_control, "the player must become controllable in a new world")
	# Hotbar de nove slots: as teclas 1–9 precisam alcançar todos os slots.
	for key_offset: int in 9:
		var hotbar_key := InputEventKey.new()
		hotbar_key.keycode = KEY_1 + key_offset
		hotbar_key.pressed = true
		game.call("_input", hotbar_key)
		_check(int(game.get("_selected_slot")) == key_offset, "hotbar key %d must select slot %d" % [key_offset + 1, key_offset])
	var interact_key := InputEventKey.new()
	interact_key.keycode = KEY_F
	interact_key.pressed = true
	game.call("_input", interact_key)
	_check(not (game.get("_craft_panel") as Control).visible, "F without a target or nearby table must not open the crafting panel")
	game.call("_select_slot", 0)
	_check(world != null and world.get_chunk_count() > 0, "the open world must stream terrain chunks")
	var voxel_material := world.get("_voxel_material") as StandardMaterial3D if world != null else null
	_check(voxel_material != null and voxel_material.cull_mode == BaseMaterial3D.CULL_DISABLED, "voxel chunks must render both sides of faces so top surfaces cannot vanish")
	var game_hud := game.get("_game_hud") as Control
	_check(game_hud != null and game_hud.mouse_filter == Control.MOUSE_FILTER_IGNORE, "the full-screen gameplay HUD must pass mouse events through")
	var cloud_layer := game.get("_cloud_layer") as MeshInstance3D
	_check(cloud_layer != null and cloud_layer.mesh is SphereMesh, "the cloud dome must remain visible across the sky at horizon level")
	if player != null and world != null:
		var spawn_position: Vector3 = world.get_spawn_position()
		var spawn_height := world.terrain_height(floori(spawn_position.x), floori(spawn_position.z))
		_check(player.is_on_floor() and player.global_position.y >= float(spawn_height) + 0.9, "the player must stand on solid terrain at spawn instead of falling through it")
		var creatures: Array = game.get("_creatures")
		_check(creatures.size() == 5, "a new world must populate rabbits, cow, sheep and pig away from spawn")
		var creature_species: Array[String] = []
		for creature_value: Variant in creatures:
			var creature := creature_value as ByteCrafterCreature
			if creature != null:
				creature_species.append(creature.species)
		_check("rabbit" in creature_species and "cow" in creature_species and "sheep" in creature_species and "pig" in creature_species, "the world must include all requested huntable animal species")
		_check(ByteCrafterCreature.SPECIES["cow"]["drops"] == [[12, 2], [13, 1]], "cow must provide meat and leather")
		_check(ByteCrafterCreature.SPECIES["sheep"]["drops"] == [[14, 2], [12, 1]], "sheep must provide wool and meat")
		_check(ByteCrafterCreature.SPECIES["pig"]["drops"] == [[12, 2], [15, 1]], "pig must provide meat and lard")
		_check(RECIPE_BOOK.find_grid_recipe([7, null, 7, null, null, null, 7, null, 7]).get("id", "") == "crafting_table", "four planks must craft a physical crafting table")
		_check(RECIPE_BOOK.find_grid_recipe([12, null, null, null, 15, null, null, null, null]).get("id", "") == "cooked_meat", "raw meat and lard must have a cooking recipe")
		_check(game.has_method("_place_crafting_table"), "the game must expose physical crafting table placement")
		_check(game.has_method("_break_duration"), "the game must expose tool-aware block breaking")
		_check(float(game.call("_break_duration", 3)) > 1.0, "stone must be slow without a pickaxe")
		_check(float(game.call("_break_duration", 4)) < 1.0 and float(game.call("_break_duration", 5)) < 1.0, "tree trunks and leaves must be breakable without a tool")
		_check(ByteCrafterWorld.BLOCK_NAMES[8] == "Musgo" and ByteCrafterWorld.BLOCK_NAMES[9] == "Gelo" and ByteCrafterWorld.BLOCK_NAMES[10] == "Basalto" and ByteCrafterWorld.BLOCK_NAMES[11] == "Cristal", "the world must expose the new biome block types")
		_check(world.has_method("get_biome") and world.get_biome(0, 0) in ["plains", "mossland", "frozen", "volcanic", "crystal"], "terrain generation must classify every coordinate into a known biome")
		_check(RECIPE_BOOK.find_grid_recipe([18, null, null, null, 15, null, null, null, null]).get("id", "") == "crystal_lantern", "crystal biomes must unlock a crystal lantern craft")
		_check(world.has_method("_populate_structure_cache") and world.has_method("get_biome"), "the world must expose deterministic structure and biome generation")
		var atlas_texture := load("res://assets/textures/voxel_atlas.png") as Texture2D
		var atlas_image := atlas_texture.get_image()
		var leaf_alpha_clear := true
		var leaf_side_is_transparent := false
		for y in range(16, 32):
			for x in range(32, 48):
				if atlas_image.get_pixel(x, y).a < 1.0:
					leaf_side_is_transparent = true
				if atlas_image.get_pixel(x, y).a <= 0.0:
					leaf_alpha_clear = false
		var leaf_cap_alpha_clear := true
		for y in range(32, 48):
			for x in range(32, 48):
				if atlas_image.get_pixel(x, y).a < 1.0:
					leaf_cap_alpha_clear = false
		_check(leaf_side_is_transparent and not leaf_alpha_clear and leaf_cap_alpha_clear, "leaf sides must retain transparency while top and bottom caps block the view through the ground")
		_check(RECIPE_BOOK.find_grid_recipe([3, 3, null, 3, 15, null, null, null, null]).get("id", "") == "iron_ingot", "stone and lard must smelt into an iron ingot")
		_check(RECIPE_BOOK.find_grid_recipe(["ferro", "ferro", "ferro", null, "gravetos", null, null, "gravetos", null]).get("id", "") == "iron_pickaxe", "iron pickaxe must have a complete shaped recipe")
		_check(RECIPE_BOOK.find_grid_recipe([13, 13, 13, 13, null, 13, null, null, null]).get("id", "") == "leather_helmet", "leather helmet must have a complete shaped recipe")
		_check(RECIPE_BOOK.find_grid_recipe([13, null, 13, 13, 13, 13, 13, 13, 13]).get("id", "") == "leather_chestplate", "leather chestplate must have a complete shaped recipe")
		_check(game.has_method("_armor_damage_reduction"), "leather armor must expose a damage reduction calculation")
		var armor_inventory: Dictionary = game.get("_inventory")
		armor_inventory["armadura_couro_cabeca"] = 1
		armor_inventory["armadura_couro_peito"] = 1
		_check(is_equal_approx(float(game.call("_armor_damage_reduction")), 0.30), "two leather armor pieces must reduce incoming damage by thirty percent")
		armor_inventory["armadura_couro_cabeca"] = 0
		armor_inventory["armadura_couro_peito"] = 0
		_check(enemies.size() == 2, "a new daytime world must spawn slime and zombie; ET only appears at night")
		var enemy_types: Array[String] = []
		for enemy_value: Variant in enemies:
			var enemy := enemy_value as ByteCrafterEnemy
			if enemy != null:
				enemy_types.append(enemy.enemy_type)
				_check(enemy.get_node_or_null("SlimeAnimado") == null, "the legacy 2D slime sprite must not be used by the 3D enemy models")
				var collider_name := "SlimeCollider" if enemy.enemy_type == "slime" else "EnemyCollider"
				var collider := enemy.get_node_or_null(collider_name) as CollisionShape3D
				var capsule := collider.shape as CapsuleShape3D if collider != null else null
				var expected_height := 0.92 if enemy.enemy_type == "slime" else 1.8
				_check(capsule != null and is_equal_approx(capsule.height, expected_height), "each enemy must use a floor-respecting collider sized to its visual body")
				_check(enemy.get_node_or_null("Nameplate") != null and (enemy.get_node("Nameplate") as Label3D).text != "", "each enemy must remain identifiable in the world")
				var animation_controller := enemy.get_node_or_null("RigAnimationController")
				_check((enemy.enemy_type == "slime" and animation_controller == null) or (enemy.enemy_type != "slime" and animation_controller != null and animation_controller.has_functional_animation()), "all rigged enemies except slime must have a functional animation controller")
				var health_bar := enemy.get_node_or_null("HealthBar") as Label3D
				var health_back := enemy.get_node_or_null("HealthBarBack") as Label3D
				_check(health_bar != null and health_back != null and health_bar.text.length() == 8, "each enemy must show a full floating health bar at spawn")
				_check(enemy.global_position.distance_to(player.global_position) < 16.0, "enemies must spawn close enough to be seen before they attack")
		_check("slime" in enemy_types and "zombie" in enemy_types and not ("et" in enemy_types), "daytime must keep ETs out of the encounter")
		_check(ByteCrafterEnemy.SPECS["boss"].get("hits", 0) == 8, "the lunar boss must require eight hits")
		_check(ByteCrafterEnemy.SPECS["boss"].get("aggro_range", 0.0) > 15.0, "the lunar boss must have an extended aggro range")
		_check((ByteCrafterEnemy.LOOT_TABLES["boss"] as Array).size() == 3, "the lunar boss must have a multi-item loot table")
		_check(game.has_method("_try_attack_enemy"), "the game must expose the shared attack action for mouse and keyboard input")

		if not enemies.is_empty():
			var slime: ByteCrafterEnemy = enemies[0] as ByteCrafterEnemy
			var attack_origin: Vector3 = player.camera.global_position
			var attack_direction: Vector3 = -player.camera.global_basis.z + Vector3.DOWN * 0.22
			slime.global_position = attack_origin + attack_direction.normalized() * 2.0 - Vector3.UP * 0.67
			slime.set_physics_process(false)
			game.set("_attack_cooldown", 0.0)
			await get_tree().physics_frame
			var health_before := slime.health
			var xp_before_enemy := int(game.get("_xp"))
			var attack_landed := bool(game.call("_try_attack_enemy"))
			_check(attack_landed and slime.health < health_before, "the player's melee ray must hit a slime in reach")
			var slime_health_bar := slime.get_node_or_null("HealthBar") as Label3D
			_check(slime_health_bar != null and slime_health_bar.text.is_empty(), "a defeated enemy health bar must empty before its death cleanup")
			_check(bool(game.call("_try_attack_enemy")) == false, "attack cooldown must prevent an immediate second hit")
			slime.take_damage(10.0)
			_check(enemies.size() == 1, "defeating a slime must remove it from the active encounter")
			_check(int(game.get("_xp")) >= xp_before_enemy + slime.get_xp_reward(), "defeating an enemy must grant its configured XP reward")
			var drop_records: Dictionary = game.get("_drop_records")
			var gel_drop_id := -1
			for drop_id: Variant in drop_records.keys():
				if int((drop_records[drop_id] as Dictionary).get("item_id", 0)) == 9:
					gel_drop_id = int(drop_id)
					break
			_check(gel_drop_id >= 0, "defeated slimes must produce a collectible gel core")
			if gel_drop_id >= 0:
				game.call("_on_drop_touched", gel_drop_id)
			_check(int(inventory.get("gelatina", 0)) == 1, "collecting the slime core must add gel to the inventory")

		for avatar_id: String in ["boy", "girl", "boy2", "girl2"]:
			player.set_avatar_id(avatar_id)
			await get_tree().process_frame
			var avatar := player.get("_avatar_instance") as ByteCrafterAvatar
			_check(avatar != null and avatar.character_id == avatar_id, "each selectable avatar must be used by the local player: " + avatar_id)
			_check(avatar != null and avatar.get_skeleton() != null and avatar.get_animation_player() != null, "each imported player rig must include its skeleton and animation player: " + avatar_id)
			var avatar_animation := avatar.get_animation_player() if avatar != null else null
			_check(avatar_animation != null and avatar_animation.has_animation("walk") and avatar_animation.has_animation("run") and avatar_animation.has_animation("jump") and avatar_animation.has_animation("mine") and avatar_animation.has_animation("attack") and avatar_animation.has_animation("death"), "each selected rig must expose movement, jump, mining, attack, and death clips: " + avatar_id)
			var avatar_mesh := avatar.find_child("model", true, false) as MeshInstance3D if avatar != null else null
			var avatar_material := avatar_mesh.get_active_material(0) as StandardMaterial3D if avatar_mesh != null else null
			_check(avatar_material != null and avatar_material.albedo_texture != null, "each selected rig must keep its supplied shaded texture: " + avatar_id)
			if avatar_id in ["boy2", "girl2"] and avatar != null and avatar_animation != null:
				var skeleton := avatar.get_skeleton()
				var source_animation := avatar.get_retarget_source_animation_player()
				_check(avatar.is_retargeting() and avatar.get_retarget_mapping_count() >= 20 and source_animation != null and source_animation.has_animation("walk"), "boy2/girl2 must retain a mapped Mixamo source for the CC retarget")
				var thigh_index := skeleton.find_bone("thigh_l")
				var rest_rotation := skeleton.get_bone_global_rest(thigh_index).basis.get_rotation_quaternion()
				avatar.set_locomotion_state("walk")
				await get_tree().process_frame
				var override_rotation := skeleton.get_bone_global_pose_override(thigh_index).basis.get_rotation_quaternion()
				_check(not rest_rotation.is_equal_approx(override_rotation), "the retargeted walk clip must animate the CC thigh: " + avatar_id)
		player.set_avatar_id("girl2")
		await get_tree().process_frame
		var remote_id := 321
		game.call("_register_remote_player", remote_id)
		game.call("receive_player_pose", remote_id, Vector3(2.0, 5.0, 3.0), 0.65, "girl2", "walk")
		var remote_avatars: Dictionary = game.get("_remote_avatars")
		var remote_avatar := remote_avatars.get(remote_id) as ByteCrafterAvatar
		_check(remote_avatar != null and remote_avatar.character_id == "girl2" and remote_avatar.get_animation_state() == "walk", "LAN remote avatars must synchronize the chosen rig and locomotion state")
		game.call("_remove_remote_player", remote_id)
		player.set_third_person(true)
		_check(player.third_person and player.get_node("PlayerBody").visible, "third-person mode must show the player model")
		player.set_third_person(false)
		_check(not player.third_person and not player.get_node("PlayerBody").visible, "first-person mode must hide the player model")
		var start_position := player.global_position
		var forward_key := InputEventKey.new()
		forward_key.keycode = KEY_W
		forward_key.physical_keycode = KEY_W
		forward_key.pressed = true
		Input.parse_input_event(forward_key)
		for _frame: int in 12:
			await get_tree().physics_frame
		forward_key.pressed = false
		Input.parse_input_event(forward_key)
		_check(player.global_position.distance_to(start_position) > 0.08, "a physical W key event must move the player")
		player.set_third_person(true)
		var body_mesh := player.get_node("PlayerBody") as Node3D
		var right_start := player.global_position
		var body_yaw_before := body_mesh.rotation.y
		var right_key := InputEventKey.new()
		right_key.keycode = KEY_D
		right_key.physical_keycode = KEY_D
		right_key.pressed = true
		Input.parse_input_event(right_key)
		for _frame: int in 12:
			await get_tree().physics_frame
		right_key.pressed = false
		Input.parse_input_event(right_key)
		_check(player.global_position.x > right_start.x + 0.08, "D must retain lateral player movement")
		_check(absf(wrapf(body_mesh.rotation.y - body_yaw_before, -PI, PI)) > 0.25, "A/D movement must turn the visible body toward the movement direction")
		var spring_arm := player.get("_spring_arm") as SpringArm3D
		_check(spring_arm != null and spring_arm.get_hit_length() > 3.0, "third-person camera must extend behind the player rather than hit its own collider")
		var yaw_before_mouse := player.rotation.y
		var avatar_yaw_before_mouse := body_mesh.global_rotation.y
		var mouse_event := InputEventMouseMotion.new()
		mouse_event.relative = Vector2(150.0, 0.0)
		player.call("_apply_mouse_look", mouse_event.relative)
		await get_tree().process_frame
		_check(absf(wrapf(player.rotation.y - yaw_before_mouse, -PI, PI)) > 0.05, "horizontal mouse motion must rotate the player and camera")
		_check(absf(wrapf(body_mesh.global_rotation.y - avatar_yaw_before_mouse, -PI, PI)) > 0.05, "horizontal mouse motion must rotate the visible avatar with the camera")
		var pitch_before_mouse: float = float(player.get("_pitch"))
		var pitch_event := InputEventMouseMotion.new()
		pitch_event.relative = Vector2(0.0, 100.0)
		player.call("_apply_mouse_look", pitch_event.relative)
		await get_tree().process_frame
		_check(absf(float(player.get("_pitch")) - pitch_before_mouse) > 0.05, "vertical mouse motion must tilt the camera")
		player.set_third_person(false)
	if world != null:
		var coords := Vector3i(3, world.terrain_height(3, 3), 3)
		var block_id := world.get_block_at(coords)
		game.call("_request_block_change", coords, 0, 0)
		_check(world.get_block_at(coords) == 0, "the gameplay interaction must break a world block")
		var drop_nodes: Dictionary = game.get("_drop_nodes")
		var drop_ids: Array = drop_nodes.keys()
		_check(not drop_ids.is_empty(), "mined resources must appear as 3D collectibles")
		if not drop_ids.is_empty():
			var drop_records: Dictionary = game.get("_drop_records")
			var item_id := int((drop_records[int(drop_ids[0])] as Dictionary).get("item_id", block_id))
			for _drop_frame: int in 12:
				await get_tree().physics_frame
			var drop := drop_nodes[int(drop_ids[0])] as ByteCrafterDrop
			var drop_floor := world.terrain_height(floori(drop.global_position.x), floori(drop.global_position.z)) if drop != null else -999
			_check(drop != null and drop.global_position.y >= float(drop_floor) + 0.2, "drops must remain above the effective ground after terrain edits")
			var before_count := int(inventory.get("frutas", 0)) if item_id == 8 else int(inventory.get(item_id, 0))
			game.call("_on_drop_touched", int(drop_ids[0]))
			var after_count := int(inventory.get("frutas", 0)) if item_id == 8 else int(inventory.get(item_id, 0))
			_check(after_count == before_count + 1, "collecting a drop must add its resource to inventory")
			game.call("_request_block_change", coords, 2, 0)
			_check(world.get_block_at(coords) == 2, "the gameplay interaction must place a selected block")
		_check(game.get("_target_outline") != null and game.get("_placement_preview") != null, "block targeting must expose a 3D outline and placement preview")
		var hotbar_slots: Array = game.get("_hotbar_slots")
		var has_item_icons := hotbar_slots.size() == 9
		for slot_value: Variant in hotbar_slots:
			var slot := slot_value as PanelContainer
			has_item_icons = has_item_icons and slot != null and (slot.find_child("ItemIcon", true, false) as TextureRect) != null
		_check(has_item_icons and (game.get("_selected_item_label") as Label).text.contains("Grama"), "the hotbar must show atlas item icons and the readable selected item name")
	game.call("_craft", "planks")
	game.call("_craft", "sticks")
	game.call("_craft", "planks")
	game.call("_craft", "pickaxe")
	var crafted_inventory: Dictionary = game.get("_inventory")
	_check(int(crafted_inventory.get("picareta", 0)) == 1, "wood, planks and sticks must craft a pickaxe")
	var saved_plank_count := int(crafted_inventory.get(7, 0))
	var saved_log_count := int(crafted_inventory.get(4, 0))
	crafted_inventory[7] = 99999
	crafted_inventory[4] = 1
	game.call("_craft", "planks")
	_check(int(crafted_inventory.get(4, 0)) == 1 and int(crafted_inventory.get(7, 0)) == 99999, "quick crafting must not consume a log when its output stack is full")
	var saved_grid: Array = (game.get("_craft_grid_items") as Array).duplicate(true)
	game.set("_craft_grid_items", [4, null, null, null, null, null, null, null, null])
	game.call("_craft_from_grid")
	var blocked_grid: Array = game.get("_craft_grid_items")
	_check(blocked_grid[0] == 4 and int(crafted_inventory.get(7, 0)) == 99999, "grid crafting must preserve ingredients when the output stack is full")
	crafted_inventory[7] = saved_plank_count
	crafted_inventory[4] = saved_log_count
	game.set("_craft_grid_items", saved_grid)
	game.call("_refresh_crafting")
	var spawn_position: Vector3 = world.get_spawn_position() if world != null else Vector3.ZERO
	game.call("_damage_player", 999.0, "Teste")
	await get_tree().process_frame
	var defeated_player: ByteCrafterPlayer = game.get("_player") as ByteCrafterPlayer
	_check(float(game.get("_health")) == 0.0 and bool(game.get("_death_in_progress")), "lethal damage must enter the explicit death state before respawn")
	_check(defeated_player != null and not defeated_player.can_control and defeated_player.get_animation_state() == "death", "death must lock controls and play the death animation")
	await get_tree().create_timer(1.35).timeout
	_check(float(game.get("_health")) == 12.0 and not bool(game.get("_death_in_progress")), "the player must respawn after the death animation window")
	_check(defeated_player != null and defeated_player.can_control and defeated_player.global_position.distance_to(spawn_position) < 0.2, "respawn must restore controls at the seeded spawn")
	if player != null:
		player.set_third_person(false)
		_check((player.get("_first_person_tool") as Node3D).visible, "an equipped pickaxe must render in first person")
		player.set_third_person(true)
		_check((player.get("_third_person_tool") as Node3D).visible, "an equipped pickaxe must render in third person")
		player.set_third_person(false)
	game.call("_save_game")
	var saved_world: Dictionary = WORLD_SCRIPT.load_from_disk()
	_check(int(saved_world.get("seed", -1)) == int(world.world_seed if world != null else -2), "the active world seed must persist")
	_check(FileAccess.file_exists("user://bytecrafter_player.json"), "the player profile must be persisted")
	var player_profile := JSON.parse_string(FileAccess.get_file_as_string("user://bytecrafter_player.json")) as Dictionary
	var saved_inventory: Dictionary = player_profile.get("inventory", {}) if player_profile != null else {}
	_check(int(saved_inventory.get("gelatina", 0)) == 1, "the collected slime resource must persist in the player profile")
	var saved_avatar_id := str(player_profile.get("avatar_id", "")) if player_profile != null else ""
	_check(saved_avatar_id == "girl2", "the selected avatar, including girl2, must persist in the player profile")
	_check(int(player_profile.get("xp", 0)) == int(game.get("_xp")) and int(player_profile.get("level", 0)) == int(game.get("_level")), "XP and level must persist in the player profile")
	game.free()
	await get_tree().process_frame
