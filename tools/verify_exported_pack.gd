extends SceneTree

var _failures: Array[String] = []
var _checks := 0
var _saved_user_files: Dictionary = {}


func _initialize() -> void:
	call_deferred("_verify")


func _verify() -> void:
	for path: String in ["user://bytecrafter_world.json", "user://bytecrafter_player.json", SaveStore.SAVE_PATH]:
		_saved_user_files[path] = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null
	_check(ProjectSettings.get_setting("application/config/name") == "ByteCrafter", "exported game identity")
	_check(ResourceLoader.exists("res://assets/template/fonts/ui_regular.tres"), "exported UI font")
	_check(ResourceLoader.exists("res://assets/share/favicon.png"), "game-specific favicon")
	_check(ResourceLoader.exists("res://localization/pt-BR.json"), "Brazilian Portuguese catalog")
	_check(not ResourceLoader.exists("res://test/test_suite.tscn"), "test scene excluded")
	_check(not ResourceLoader.exists("res://tools/capture_native.gd"), "native capture tool excluded")
	_check(not root.has_node("GlobalLeaderboard"), "no dormant network autoload")
	var font := load("res://assets/template/fonts/ui_regular.tres") as Font
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://localization/pt-BR.json"))
	_check(font != null and not catalog.is_empty(), "exported font and localization load")
	if font != null:
		for value: Variant in catalog.values():
			var text := str(value)
			for index: int in text.length():
				var codepoint := text.unicode_at(index)
				if codepoint >= 32:
					_check(font.has_char(codepoint), "exported Portuguese glyph: %d" % codepoint)
	var packed := load("res://scenes/main.tscn") as PackedScene
	_check(packed != null, "exported main scene")
	if packed != null:
		var main := packed.instantiate()
		root.add_child(main)
		for _frame: int in 8:
			await process_frame
		_check(str(main.get("_screen")) == "title", "pack boots to ByteCrafter title")
		_check(not main.has_method("_maybe_capture"), "capture routing excluded from runtime")
		_check(not main.has_method("_open_tuning"), "release tuning entry point excluded")
		main.call("_start_new_world")
		for _frame: int in 8:
			await process_frame
		var world := main.get("_world") as ByteCrafterWorld
		var player := main.get("_player") as ByteCrafterPlayer
		_check(str(main.get("_screen")) == "game", "new world enters gameplay")
		_check(world != null and world.get_chunk_count() > 0, "voxel terrain streams into the world")
		_check((main.get("_creatures") as Array).size() == 3, "passive creatures spawn")
		_check(player != null and player.can_control, "player becomes controllable")
		if player != null:
			player.set_third_person(true)
			_check(player.third_person and player.get_node("PlayerBody").visible, "third-person camera shows the avatar")
			player.set_third_person(false)
			_check(not player.third_person and not player.get_node("PlayerBody").visible, "first-person camera hides the avatar")
		if world != null:
			var coords := Vector3i(3, world.terrain_height(3, 3), 3)
			var block_id := world.get_block_at(coords)
			main.call("_request_block_change", coords, 0, 0)
			_check(block_id > 0 and world.get_block_at(coords) == 0, "mining breaks a terrain voxel")
			var drops: Dictionary = main.get("_drop_nodes")
			_check(not drops.is_empty(), "mined block creates a collectible")
			if not drops.is_empty():
				var drop_id := int(drops.keys()[0])
				var records: Dictionary = main.get("_drop_records")
				var record: Dictionary = records.get(drop_id, {})
				var item_id := int(record.get("item_id", block_id))
				var inventory: Dictionary = main.get("_inventory")
				var before := int(inventory.get("frutas", 0)) if item_id == 8 else int(inventory.get(item_id, 0))
				main.call("_on_drop_touched", drop_id)
				var after := int(inventory.get("frutas", 0)) if item_id == 8 else int(inventory.get(item_id, 0))
				_check(after == before + 1, "collecting a drop adds the resource")
			main.call("_request_block_change", coords, 2, 0)
			_check(world.get_block_at(coords) == 2, "building places a selected block")
		main.call("_craft", "planks")
		main.call("_craft", "sticks")
		main.call("_craft", "planks")
		main.call("_craft", "pickaxe")
		var crafted_inventory: Dictionary = main.get("_inventory")
		_check(int(crafted_inventory.get("picareta", 0)) == 1, "crafting produces a pickaxe")
		if player != null:
			player.set_third_person(false)
			_check((player.get("_first_person_tool") as Node3D).visible, "equipped pickaxe appears in first person")
			player.set_third_person(true)
			_check((player.get("_third_person_tool") as Node3D).visible, "equipped pickaxe appears in third person")
		main.free()
		await process_frame
	var audio := root.get_node_or_null("AudioDirector")
	if audio != null:
		_check(not bool(audio.call("play_cue", "ui.confirm")), "missing SFX remains silent")
		_check(not bool(audio.call("play_music", "music.gameplay")), "missing BGM remains silent")
		audio.call("release_streams")
	_restore_user_files()
	if _failures.is_empty():
		print("[exported-pack] PASS: ByteCrafter identity, pt-BR, world, mining, pickup, building, crafting and cameras (%d checks)" % _checks)
		quit(0)
	else:
		for failure: String in _failures:
			push_error("[exported-pack] " + failure)
		quit(1)


func _restore_user_files() -> void:
	for path: String in _saved_user_files:
		var original: Variant = _saved_user_files[path]
		if original == null:
			if FileAccess.file_exists(path):
				_check(DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK, "test save removed: " + path)
		else:
			var file := FileAccess.open(path, FileAccess.WRITE)
			_check(file != null, "original user file remains writable: " + path)
			if file != null:
				file.store_buffer(original)
				file.close()
				_check(FileAccess.get_file_as_bytes(path) == original, "original user file restored: " + path)


func _check(condition: bool, context: String) -> void:
	_checks += 1
	if not condition and context not in _failures:
		_failures.append(context)
