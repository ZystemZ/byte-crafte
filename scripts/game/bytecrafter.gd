extends Node3D
class_name ByteCrafterGame

const WORLD_SCRIPT := preload("res://scripts/game/voxel_world.gd")
const PLAYER_SCRIPT := preload("res://scripts/game/bytecrafter_player.gd")
const AVATAR_SCRIPT := preload("res://scripts/game/bytecrafter_avatar.gd")
const MENU_BACKGROUND_TEXTURE := preload("res://assets/ui/menu_background.png")
const LOADING_SCREEN_TEXTURE := preload("res://assets/ui/loading_initial.png")
const GAME_ICON_TEXTURE := preload("res://assets/share/favicon.png")
const VOXEL_ATLAS_TEXTURE := preload("res://assets/textures/voxel_atlas.png")
const CREATURE_SCRIPT := preload("res://scripts/game/bytecrafter_creature.gd")
const ENEMY_SCRIPT := preload("res://scripts/game/bytecrafter_enemy.gd")
const DROP_SCRIPT := preload("res://scripts/game/bytecrafter_drop.gd")
const RECIPE_BOOK := preload("res://scripts/game/crafting_recipe_book.gd")
const INVENTORY_SLOT_SCRIPT := preload("res://scripts/game/inventory_slot.gd")
const UI := preload("res://scripts/ui/screen_factory.gd")
const LICENSES := preload("res://scripts/manus/open_source_licenses.gd")
const LAN_PORT := 24567
const PROFILE_PATH := "user://bytecrafter_player.json"
const QUICKBAR_IDS := [1, 2, 3, 4, 6, 7, "gravetos", "picareta", "picareta_ferro"]
const BREAK_DIST := 7.0
const ITEM_NAMES := {8: "Fruta", 9: "Gelatina", 10: "Fragmento lunar", 11: "Núcleo lunar", 12: "Carne", 13: "Couro", 14: "Lã", 15: "Banha", 17: "Ferro", 18: "Cristal", "sementes_trigo": "Sementes de trigo", "trigo": "Trigo", "mesa_craft": "Mesa de craft", "tocha": "Tocha", "fogueira": "Fogueira", "lanterna_cristal": "Lanterna de cristal", "picareta_ferro": "Picareta de ferro", "machado_ferro": "Machado de ferro", "espada_ferro": "Espada de ferro", "armadura_couro_cabeca": "Capacete de couro", "armadura_couro_peito": "Peitoral de couro", "armadura_couro_pernas": "Calças de couro", "armadura_couro_botas": "Botas de couro"}
const AVATAR_IDS := ["boy", "girl", "boy2", "girl2"]
const PROFILE_VERSION := 2
const XP_BY_BLOCK := {1: 1, 2: 1, 3: 3, 4: 2, 5: 1, 6: 1, 7: 1}
const PLAYER_DEATH_DURATION := 1.25

var _world: ByteCrafterWorld
var _player: ByteCrafterPlayer
var _creatures: Array[ByteCrafterCreature] = []
var _enemies: Array[ByteCrafterEnemy] = []
var _environment: Environment
var _sun: DirectionalLight3D
var _sky_material: ProceduralSkyMaterial
var _cloud_layer: MeshInstance3D
var _screen := "title"
var _network_active := false
var _is_host := false
var _join_pending := false
var _remote_avatars: Dictionary = {}
var _remote_positions: Dictionary = {}
var _pose_timer := 0.0
var _stream_timer := 0.0
var _save_timer := 0.0
var _day_phase := 0.22
var _health := 20.0
var _food := 20.0
var _xp := 0
var _level := 1
var _survival_timer := 0.0
var _hunger_tick := 0.0
var _mine_held := false
var _mine_position := Vector3i.ZERO
var _mine_timer := 0.0
var _mine_duration := 1.0
var _attack_cooldown := 0.0
var _damage_invulnerability := 0.0
var _death_in_progress := false
var _selected_slot := 0
var _selected_avatar_id := "boy"
var _inventory: Dictionary = {}
var _profile_seed := -1
var _profile_position := Vector3.ZERO
var _profile_loaded := false
var _profile_drops: Array = []
var _drop_nodes: Dictionary = {}
var _drop_records: Dictionary = {}
var _next_drop_id := 1
var _crafting_tables: Array[Node3D] = []
var _crops: Dictionary = {}
var _crop_nodes: Dictionary = {}
var _profile_crops: Array = []

var _ui_layer: CanvasLayer
var _title_screen: Control
var _title_label: Label
var _title_status: Label
var _ip_input: LineEdit
var _lan_host_button: Button
var _lan_join_button: Button
var _avatar_boy_button: Button
var _avatar_girl_button: Button
var _avatar_boy2_button: Button
var _avatar_girl2_button: Button
var _startup_loading_layer: CanvasLayer
var _startup_loading_started_msec := 0
var _game_hud: Control
var _health_bar: ProgressBar
var _food_bar: ProgressBar
var _level_label: Label
var _xp_bar: ProgressBar
var _position_label: Label
var _game_status: Label
var _hotbar: HBoxContainer
var _hotbar_slots: Array[PanelContainer] = []
var _selected_item_label: Label
var _crosshair: Label
var _mine_progress: ProgressBar
var _craft_panel: PanelContainer
var _craft_info: Label
var _inventory_grid: GridContainer
var _inventory_item_ids: Array = [1, 2, 3, 4, 5, 6, 7, "gravetos", "picareta", "picareta_ferro", "machado_ferro", "espada_ferro", "frutas", "sementes_trigo", "trigo", "gelatina", "fragmento_lunar", "nucleo_lunar", 12, 13, 14, 15, 16, 17, 18, "mesa_craft", "tocha", "fogueira", "lanterna_cristal", "armadura_couro_cabeca", "armadura_couro_peito", "armadura_couro_pernas", "armadura_couro_botas"]
var _craft_table_slots: Array[PanelContainer] = []
var _craft_grid_items: Array = [null, null, null, null, null, null, null, null, null]
var _craft_output_slot: PanelContainer
var _craft_output_icon: Label
var _craft_output_item: Variant = null
var _craft_output_quantity: int = 0
var _craft_planks: Button
var _craft_sticks: Button
var _craft_pickaxe: Button
var _eat_fruit: Button
var _pause_screen: Control
var _paused := false
var _target_outline: MeshInstance3D
var _placement_preview: MeshInstance3D
var _placement_material: StandardMaterial3D


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_create_native_loading_screen()
	if I18n.has_method("set_locale"):
		I18n.set_locale("pt-BR")
	_build_environment()
	_build_interface()
	_connect_network_signals()
	_load_profile()
	_refresh_avatar_selector()
	var saved_world: Dictionary = WORLD_SCRIPT.load_from_disk()
	var seed_value := int(saved_world.get("seed", randi_range(100000, 999999999)))
	var overrides: Array = saved_world.get("overrides", [])
	_create_world(seed_value, overrides)
	_refresh_hud()


func _process(delta: float) -> void:
	# A tela inicial de carregamento deve ser removida uma única vez. A lógica
	# de jogo precisa continuar executando depois que ela desaparecer.
	if _startup_loading_layer != null and Time.get_ticks_msec() - _startup_loading_started_msec >= 3000:
		_startup_loading_layer.queue_free()
		_startup_loading_layer = null

	if _screen == "game" and not _paused:
		_day_phase = fposmod(_day_phase + delta / 720.0, 1.0)
		_update_day_night()
		_update_enemy_schedule()
		_update_interaction_helpers()
		_process_mining(delta)
		_process_crops(delta)
		_refresh_survival(delta)
		_refresh_position_label()
	else:
		if _target_outline != null:
			_target_outline.visible = false
		if _placement_preview != null:
			_placement_preview.visible = false

	_update_cloud_layer()
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	_damage_invulnerability = maxf(0.0, _damage_invulnerability - delta)
	_stream_timer -= delta
	if _stream_timer <= 0.0 and _world != null and _player != null:
		_stream_timer = 0.25
		_world.update_streaming(_player.global_position)
	_pose_timer -= delta
	if _network_active and _player != null and _pose_timer <= 0.0:
		_pose_timer = 0.12
		_send_player_pose()
	_save_timer -= delta
	if _save_timer <= 0.0:
		_save_timer = 12.0
		_save_game()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_G and _screen == "game" and not _paused and _craft_panel != null and not _craft_panel.visible:
		_mine_held = event.pressed
		if event.pressed:
			_mine_timer = 0.0
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if _craft_panel != null and _craft_panel.visible:
				_toggle_crafting()
			elif _screen == "game":
				_toggle_pause()
			get_viewport().set_input_as_handled()
		elif _screen == "game" and not _paused:
			if event.keycode == KEY_V:
				_player.set_third_person(not _player.third_person)
				_set_game_status("Câmera: %s" % ("3ª pessoa" if _player.third_person else "1ª pessoa"))
			elif event.keycode == KEY_F:
				_interact_contextual()
			elif event.keycode == KEY_E:
				_toggle_crafting()
			elif event.keycode == KEY_T:
				_place_crafting_table()
			elif event.keycode == KEY_P:
				_use_farming_action()
			elif event.keycode >= KEY_1 and event.keycode <= KEY_9:
				_select_slot(int(event.keycode - KEY_1))
			elif event.keycode == KEY_F5:
				_save_game()
	if not event is InputEventMouseButton or _screen != "game" or _paused:
		return
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and not _craft_panel.visible and _try_attack_enemy():
			_mine_held = false
			get_viewport().set_input_as_handled()
			return
		_mine_held = event.pressed and not _craft_panel.visible
		if event.pressed and not _craft_panel.visible:
			_mine_timer = 0.0
	elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed and not _craft_panel.visible:
		_place_selected_block()
	elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
		_select_slot(posmod(_selected_slot - 1, QUICKBAR_IDS.size()))
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
		_select_slot(posmod(_selected_slot + 1, QUICKBAR_IDS.size()))


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		if _world != null and (not _network_active or _is_host):
			_save_game()


func _build_environment() -> void:
	_environment = Environment.new()
	_environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	_sky_material = ProceduralSkyMaterial.new()
	_sky_material.sky_top_color = Color("438ad3")
	_sky_material.sky_horizon_color = Color("b6d7ef")
	_sky_material.ground_bottom_color = Color("263336")
	_sky_material.ground_horizon_color = Color("8c9e8f")
	_sky_material.sun_angle_max = 16.0
	_sky_material.use_debanding = true
	sky.sky_material = _sky_material
	_environment.sky = sky
	_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_environment.ambient_light_color = Color("b7d6ed")
	_environment.ambient_light_energy = 0.55
	_environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	_environment.fog_enabled = true
	_environment.fog_light_color = Color("a7c9e3")
	_environment.fog_density = 0.0012
	var world_environment := WorldEnvironment.new()
	world_environment.environment = _environment
	add_child(world_environment)
	_create_cloud_layer()
	_sun = DirectionalLight3D.new()
	_sun.name = "Daylight"
	_sun.rotation_degrees = Vector3(-38.0, -28.0, 0.0)
	_sun.light_color = Color("fff2d9")
	_sun.light_energy = 1.05
	_sun.shadow_enabled = true
	_sun.directional_shadow_max_distance = 72.0
	add_child(_sun)
	_update_day_night()


func _create_cloud_layer() -> void:
	var cloud_mesh := SphereMesh.new()
	cloud_mesh.radius = 180.0
	cloud_mesh.height = 360.0
	cloud_mesh.radial_segments = 64
	cloud_mesh.rings = 32
	_cloud_layer = MeshInstance3D.new()
	_cloud_layer.name = "PixelCloudDome"
	_cloud_layer.mesh = cloud_mesh
	_cloud_layer.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var cloud_material := ShaderMaterial.new()
	cloud_material.shader = load("res://assets/shaders/cloud_mask.gdshader")
	cloud_material.set_shader_parameter("cloud_texture", load("res://assets/textures/clouds.png"))
	cloud_material.set_shader_parameter("cloud_scale", 0.75)
	_cloud_layer.material_override = cloud_material
	add_child(_cloud_layer)


func _update_cloud_layer() -> void:
	if _cloud_layer == null or _player == null:
		return
	_cloud_layer.global_position = _player.global_position


func _update_day_night() -> void:
	if _sun == null or _environment == null:
		return
	var sunlight := clampf(sin(_day_phase * TAU), 0.0, 1.0)
	_sun.rotation_degrees.x = _day_phase * 360.0 - 90.0
	_sun.light_energy = 0.08 + sunlight * 1.15
	_environment.ambient_light_energy = 0.18 + sunlight * 0.52
	_environment.fog_light_color = Color("142239").lerp(Color("a9cde8"), sunlight)
	if _sky_material != null:
		_sky_material.sky_top_color = Color("07142d").lerp(Color("438ad3"), sunlight)
		_sky_material.sky_horizon_color = Color("1b3153").lerp(Color("b6d7ef"), sunlight)
		_sky_material.ground_bottom_color = Color("080c15").lerp(Color("263336"), sunlight)
		_sky_material.ground_horizon_color = Color("171f2b").lerp(Color("8c9e8f"), sunlight)
	if _cloud_layer != null and _cloud_layer.material_override is ShaderMaterial:
		var cloud_material := _cloud_layer.material_override as ShaderMaterial
		cloud_material.set_shader_parameter("cloud_opacity", 0.10 + sunlight * 0.24)


func get_sunlight_strength() -> float:
	return clampf(sin(_day_phase * TAU), 0.0, 1.0)


func is_daytime() -> bool:
	return get_sunlight_strength() > 0.18


func _build_interface() -> void:
	_ui_layer = CanvasLayer.new()
	_ui_layer.layer = 10
	_ui_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_ui_layer)
	_build_title_screen()
	_build_hud()
	_build_crafting_panel()
	_build_pause_screen()
	_build_interaction_helpers()


func _build_title_screen() -> void:
	_title_screen = Control.new()
	_title_screen.name = "TitleScreen"
	UI.full_rect(_title_screen)
	_title_screen.process_mode = Node.PROCESS_MODE_ALWAYS
	_ui_layer.add_child(_title_screen)
	var background := TextureRect.new()
	background.name = "MenuBackground"
	background.texture = MENU_BACKGROUND_TEXTURE
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.full_rect(background)
	_title_screen.add_child(background)
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.035, 0.05, 0.18)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.full_rect(shade)
	_title_screen.add_child(shade)
	var margin := MarginContainer.new()
	UI.full_rect(margin)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	_title_screen.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	margin.add_child(row)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	var panel_width := clampf(get_viewport().get_visible_rect().size.x * 0.36, 320.0, 460.0)
	var button_width := panel_width - 40.0
	var panel := UI.holo_panel(Color("89b578"), Vector2(18.0, 14.0))
	panel.name = "MenuPanel"
	panel.custom_minimum_size = Vector2(panel_width, 0.0)
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 7)
	panel.add_child(content)
	var eyebrow := UI.display_label("MUNDO ABERTO · SOBREVIVÊNCIA · CONSTRUÇÃO", 10, Color("b5d49b"), "eyebrow")
	content.add_child(eyebrow)
	_title_label = UI.display_label("BYTECRAFTER", 36, Color("f4f4e8"), "title")
	_title_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.65))
	_title_label.add_theme_constant_override("shadow_offset_y", 3)
	content.add_child(_title_label)
	var subtitle := UI.label("Explore, sobreviva e construa bloco a bloco.", 12, Color("c5c9bc"))
	content.add_child(subtitle)
	content.add_child(UI.accent_rule(52.0, Color("94bc73")))
	var avatar_heading := UI.label("PERSONAGEM", 10, Color("b5d49b"))
	content.add_child(avatar_heading)
	var avatar_grid := GridContainer.new()
	avatar_grid.columns = 2
	avatar_grid.add_theme_constant_override("h_separation", 10)
	avatar_grid.add_theme_constant_override("v_separation", 6)
	content.add_child(avatar_grid)
	_avatar_boy_button = UI.button("GAROTO", (button_width - 10.0) * 0.5)
	_avatar_boy_button.pressed.connect(_set_selected_avatar.bind("boy"))
	avatar_grid.add_child(_avatar_boy_button)
	_avatar_girl_button = UI.button("GAROTA", (button_width - 10.0) * 0.5)
	_avatar_girl_button.pressed.connect(_set_selected_avatar.bind("girl"))
	avatar_grid.add_child(_avatar_girl_button)
	_avatar_boy2_button = UI.button("GAROTO 2", (button_width - 10.0) * 0.5)
	_avatar_boy2_button.pressed.connect(_set_selected_avatar.bind("boy2"))
	avatar_grid.add_child(_avatar_boy2_button)
	_avatar_girl2_button = UI.button("GAROTA 2", (button_width - 10.0) * 0.5)
	_avatar_girl2_button.pressed.connect(_set_selected_avatar.bind("girl2"))
	avatar_grid.add_child(_avatar_girl2_button)
	_refresh_avatar_selector()
	var play_button := UI.button("CONTINUAR EXPLORAÇÃO", button_width)
	UI.primary(play_button)
	play_button.pressed.connect(_start_singleplayer)
	content.add_child(play_button)
	var new_world_button := UI.button("CRIAR NOVO MUNDO", button_width)
	new_world_button.pressed.connect(_start_new_world)
	content.add_child(new_world_button)
	var separator := UI.label("COOPERATIVO NA REDE LOCAL", 10, Color("a8b4a2"))
	content.add_child(separator)
	_ip_input = LineEdit.new()
	_ip_input.custom_minimum_size = Vector2(button_width, 38.0)
	_ip_input.placeholder_text = "IP do anfitrião (ex.: 192.168.1.20)"
	_ip_input.text = "127.0.0.1"
	_ip_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(_ip_input)
	var lan_row := HBoxContainer.new()
	lan_row.add_theme_constant_override("separation", 10)
	content.add_child(lan_row)
	_lan_host_button = UI.button("HOSPEDAR LAN", (button_width - 10.0) * 0.5)
	_lan_host_button.pressed.connect(_host_lan)
	lan_row.add_child(_lan_host_button)
	_lan_join_button = UI.button("ENTRAR", (button_width - 10.0) * 0.5)
	_lan_join_button.pressed.connect(_join_lan)
	lan_row.add_child(_lan_join_button)
	if OS.has_feature("web"):
		_lan_host_button.disabled = true
		_lan_join_button.disabled = true
		_ip_input.editable = false
	var web_note := UI.label("A rede LAN requer uma build nativa do Godot; o Preview web é para testar o protótipo.", 10, Color("d0c5a0"))
	web_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	web_note.visible = OS.has_feature("web")
	content.add_child(web_note)
	_title_status = UI.label("", 11, Color("b5d49b"))
	_title_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_title_status)
	var controls := UI.label("W/S avançar/recuar · A/D deslocar e orientar o avatar · mouse olhar\nEspaço saltar · Shift correr · clique minerar/colocar · 1–7 blocos · E inventário · V câmera · Esc pausar", 10, Color("9ca69a"))
	controls.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(controls)
	var licenses_button := UI.quiet_button("Licenças de código aberto", 10)
	licenses_button.pressed.connect(LICENSES.open.bind(self))
	licenses_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content.add_child(licenses_button)


func _create_native_loading_screen() -> void:
	if OS.has_feature("web") or DisplayServer.get_name() == "headless":
		return
	_startup_loading_layer = CanvasLayer.new()
	_startup_loading_layer.name = "InitialLoadingScreen"
	_startup_loading_layer.layer = 120
	_startup_loading_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_startup_loading_layer)
	var root := Control.new()
	root.name = "LoadingOverlay"
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	UI.full_rect(root)
	_startup_loading_layer.add_child(root)
	var artwork := TextureRect.new()
	artwork.texture = LOADING_SCREEN_TEXTURE
	artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	artwork.mouse_filter = Control.MOUSE_FILTER_STOP
	UI.full_rect(artwork)
	root.add_child(artwork)
	var panel := UI.holo_panel(Color("89b578"), Vector2(14.0, 10.0))
	panel.anchor_left = 0.0
	panel.anchor_right = 0.0
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = 24.0
	panel.offset_right = 338.0
	panel.offset_top = -108.0
	panel.offset_bottom = -24.0
	root.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)
	var icon := TextureRect.new()
	icon.texture = GAME_ICON_TEXTURE
	icon.custom_minimum_size = Vector2(48.0, 48.0)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon)
	var labels := VBoxContainer.new()
	labels.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	labels.add_child(UI.display_label("BYTECRAFTER", 18, Color("f4f4e8"), "title"))
	labels.add_child(UI.label("Preparando o mundo...", 11, Color("c5c9bc")))
	row.add_child(labels)
	_startup_loading_started_msec = Time.get_ticks_msec()


func _refresh_avatar_selector() -> void:
	var buttons := {
		"boy": _avatar_boy_button,
		"girl": _avatar_girl_button,
		"boy2": _avatar_boy2_button,
		"girl2": _avatar_girl2_button,
	}
	for avatar_id: String in buttons:
		var button := buttons[avatar_id] as Button
		if button == null:
			continue
		button.text = ("✓ " if _selected_avatar_id == avatar_id else "") + _avatar_label(avatar_id)
		button.modulate = Color.WHITE if _selected_avatar_id == avatar_id else Color(0.72, 0.76, 0.72)


func _avatar_label(avatar_id: String) -> String:
	return {
		"boy": "GAROTO",
		"girl": "GAROTA",
		"boy2": "GAROTO 2",
		"girl2": "GAROTA 2",
	}.get(avatar_id, "GAROTO")


func _set_selected_avatar(value: String) -> void:
	if value not in AVATAR_IDS:
		return
	_selected_avatar_id = value
	_refresh_avatar_selector()
	if _player != null:
		_player.set_avatar_id(_selected_avatar_id)
	_save_game()
	if _title_status != null:
		_title_status.text = "Personagem selecionado: %s" % _avatar_label(value).capitalize()


func _build_hud() -> void:
	_game_hud = Control.new()
	_game_hud.name = "GameHUD"
	UI.full_rect(_game_hud)
	_game_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_game_hud.visible = false
	_game_hud.process_mode = Node.PROCESS_MODE_ALWAYS
	_ui_layer.add_child(_game_hud)
	var top := UI.holo_panel(Color("94bc73"), Vector2(14.0, 9.0))
	top.position = Vector2(18.0, 18.0)
	top.custom_minimum_size = Vector2(250.0, 0.0)
	_game_hud.add_child(top)
	var stats := VBoxContainer.new()
	stats.add_theme_constant_override("separation", 5)
	top.add_child(stats)
	var health_row := HBoxContainer.new()
	stats.add_child(health_row)
	health_row.add_child(UI.label("VIDA", 12, Color("edc0ad")))
	_health_bar = ProgressBar.new()
	_health_bar.custom_minimum_size = Vector2(174.0, 14.0)
	_health_bar.max_value = 20.0
	_health_bar.show_percentage = false
	health_row.add_child(_health_bar)
	var food_row := HBoxContainer.new()
	stats.add_child(food_row)
	food_row.add_child(UI.label("FOME", 12, Color("e8d79f")))
	_food_bar = ProgressBar.new()
	_food_bar.custom_minimum_size = Vector2(174.0, 14.0)
	_food_bar.max_value = 20.0
	_food_bar.show_percentage = false
	food_row.add_child(_food_bar)
	var level_row := HBoxContainer.new()
	stats.add_child(level_row)
	_level_label = UI.label("NÍVEL 1", 12, Color("b9dc9a"))
	level_row.add_child(_level_label)
	_xp_bar = ProgressBar.new()
	_xp_bar.custom_minimum_size = Vector2(174.0, 10.0)
	_xp_bar.show_percentage = false
	level_row.add_child(_xp_bar)
	_position_label = UI.label("", 12, Color("e5eadb"))
	_position_label.anchor_left = 1.0
	_position_label.anchor_right = 1.0
	_position_label.anchor_top = 0.0
	_position_label.anchor_bottom = 0.0
	_position_label.offset_left = -320.0
	_position_label.offset_right = -18.0
	_position_label.offset_top = 20.0
	_position_label.offset_bottom = 70.0
	_position_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_game_hud.add_child(_position_label)
	_crosshair = UI.display_label("+", 28, Color("f5f4e9"), "heading")
	_crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_crosshair.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_crosshair.anchor_left = 0.5
	_crosshair.anchor_right = 0.5
	_crosshair.anchor_top = 0.5
	_crosshair.anchor_bottom = 0.5
	_crosshair.offset_left = -16.0
	_crosshair.offset_right = 16.0
	_crosshair.offset_top = -18.0
	_crosshair.offset_bottom = 18.0
	_crosshair.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
	_crosshair.add_theme_constant_override("shadow_offset_x", 1)
	_crosshair.add_theme_constant_override("shadow_offset_y", 1)
	_crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_game_hud.add_child(_crosshair)
	_mine_progress = ProgressBar.new()
	_mine_progress.anchor_left = 0.5
	_mine_progress.anchor_right = 0.5
	_mine_progress.anchor_top = 0.5
	_mine_progress.anchor_bottom = 0.5
	_mine_progress.offset_left = -70.0
	_mine_progress.offset_right = 70.0
	_mine_progress.offset_top = 26.0
	_mine_progress.offset_bottom = 38.0
	_mine_progress.show_percentage = false
	_mine_progress.visible = false
	_game_hud.add_child(_mine_progress)
	var hotbar_panel := PanelContainer.new()
	hotbar_panel.anchor_left = 0.5
	hotbar_panel.anchor_right = 0.5
	hotbar_panel.anchor_top = 1.0
	hotbar_panel.anchor_bottom = 1.0
	hotbar_panel.offset_left = -360.0
	hotbar_panel.offset_right = 360.0
	hotbar_panel.offset_top = -92.0
	hotbar_panel.offset_bottom = -14.0
	hotbar_panel.add_theme_stylebox_override("panel", UI.style_box(Color(0.035, 0.045, 0.052, 0.82), Color(0.75, 0.83, 0.69, 0.24), 8, 1))
	_game_hud.add_child(hotbar_panel)
	_hotbar = HBoxContainer.new()
	_hotbar.alignment = BoxContainer.ALIGNMENT_CENTER
	_hotbar.add_theme_constant_override("separation", 5)
	hotbar_panel.add_child(_hotbar)
	for index: int in QUICKBAR_IDS.size():
		var item_id: Variant = QUICKBAR_IDS[index]
		var slot := PanelContainer.new()
		slot.custom_minimum_size = Vector2(74.0, 60.0)
		slot.tooltip_text = "%d — %s" % [index + 1, _item_short_name(item_id)]
		var slot_content := VBoxContainer.new()
		slot_content.alignment = BoxContainer.ALIGNMENT_CENTER
		slot_content.add_theme_constant_override("separation", 1)
		var number := UI.label(str(index + 1), 10, Color("b3bea9"))
		number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot_content.add_child(number)
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 5)
		var icon := TextureRect.new()
		icon.name = "ItemIcon"
		icon.texture = _make_block_icon(int(item_id)) if item_id is int else _item_texture(item_id)
		icon.custom_minimum_size = Vector2(22.0, 22.0)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon)
		var glyph := UI.label(_item_glyph(item_id), 19, Color("f4f0dc"))
		glyph.name = "ItemGlyph"
		glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
		glyph.visible = icon.texture == null
		row.add_child(glyph)
		var amount := UI.label("0", 11, Color("f1f3e9"))
		amount.name = "Amount"
		row.add_child(amount)
		slot_content.add_child(row)
		slot.add_child(slot_content)
		_hotbar.add_child(slot)
		_hotbar_slots.append(slot)
	_selected_item_label = UI.label("", 12, Color("f0f3e8"))
	_selected_item_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_selected_item_label.anchor_left = 0.5
	_selected_item_label.anchor_right = 0.5
	_selected_item_label.anchor_top = 1.0
	_selected_item_label.anchor_bottom = 1.0
	_selected_item_label.offset_left = -180.0
	_selected_item_label.offset_right = 180.0
	_selected_item_label.offset_top = -116.0
	_selected_item_label.offset_bottom = -94.0
	_game_hud.add_child(_selected_item_label)
	var status_panel := UI.holo_panel(Color("91b67a"), Vector2(14.0, 8.0))
	status_panel.anchor_left = 0.5
	status_panel.anchor_right = 0.5
	status_panel.anchor_top = 0.0
	status_panel.anchor_bottom = 0.0
	status_panel.offset_left = -170.0
	status_panel.offset_right = 170.0
	status_panel.offset_top = 14.0
	status_panel.offset_bottom = 54.0
	status_panel.visible = false
	_game_hud.add_child(status_panel)
	_game_status = UI.label("", 12, Color("e9efdf"))
	_game_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_panel.add_child(_game_status)
	var help := UI.label("Esquerdo: atacar/minerar · F: atacar · G: minerar · E: inventário · V: câmera · F5: salvar · Esc: menu", 11, Color("d8dfd0"))
	help.anchor_left = 0.0
	help.anchor_right = 0.0
	help.anchor_top = 1.0
	help.anchor_bottom = 1.0
	help.offset_left = 18.0
	help.offset_right = 360.0
	help.offset_top = -38.0
	help.offset_bottom = -12.0
	_game_hud.add_child(help)


func _build_crafting_panel() -> void:
	# Inventário inspirado no layout clássico de survival crafting:
	# grade de itens à esquerda e bancada/receitas à direita.
	_craft_panel = PanelContainer.new()
	_craft_panel.name = "InventoryCraftPanel"
	_craft_panel.anchor_left = 0.5
	_craft_panel.anchor_right = 0.5
	_craft_panel.anchor_top = 0.5
	_craft_panel.anchor_bottom = 0.5
	_craft_panel.offset_left = -470.0
	_craft_panel.offset_right = 470.0
	_craft_panel.offset_top = -290.0
	_craft_panel.offset_bottom = 290.0
	_craft_panel.visible = false
	_craft_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	_craft_panel.add_theme_stylebox_override("panel", UI.style_box(Color("20242a"), Color("8a9a83"), 8, 2))
	_ui_layer.add_child(_craft_panel)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)
	_craft_panel.add_child(outer)
	var header_row := HBoxContainer.new()
	outer.add_child(header_row)
	var heading := UI.display_label("INVENTÁRIO", 24, Color("f2f2e8"), "heading")
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(heading)
	var close := UI.quiet_button("✕  Fechar  (E / Esc)", 14)
	close.pressed.connect(_toggle_crafting)
	header_row.add_child(close)

	var separator := HSeparator.new()
	outer.add_child(separator)
	var main_row := HBoxContainer.new()
	main_row.add_theme_constant_override("separation", 18)
	main_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(main_row)

	var inventory_column := VBoxContainer.new()
	inventory_column.custom_minimum_size.x = 390.0
	inventory_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inventory_column.add_theme_constant_override("separation", 8)
	main_row.add_child(inventory_column)
	var inventory_heading := UI.label("ITENS", 13, Color("c9d6c0"))
	inventory_heading.add_theme_font_size_override("font_size", 14)
	inventory_column.add_child(inventory_heading)
	var inventory_scroll := ScrollContainer.new()
	inventory_scroll.name = "InventoryScroll"
	inventory_scroll.custom_minimum_size = Vector2(390.0, 300.0)
	inventory_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inventory_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	inventory_column.add_child(inventory_scroll)
	_inventory_grid = GridContainer.new()
	_inventory_grid.columns = 5
	_inventory_grid.add_theme_constant_override("h_separation", 6)
	_inventory_grid.add_theme_constant_override("v_separation", 6)
	inventory_scroll.add_child(_inventory_grid)
	for item_id in _inventory_item_ids:
		_inventory_grid.add_child(_make_inventory_slot(item_id))
	_craft_info = UI.label("", 11, Color("c4cbbf"))
	_craft_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_craft_info.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inventory_column.add_child(_craft_info)

	var craft_column := VBoxContainer.new()
	craft_column.custom_minimum_size.x = 390.0
	craft_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	craft_column.add_theme_constant_override("separation", 8)
	main_row.add_child(craft_column)
	var table_heading := UI.label("MESA DE CRAFT", 14, Color("e3c58c"))
	table_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	craft_column.add_child(table_heading)
	var table_frame := PanelContainer.new()
	table_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	table_frame.add_theme_stylebox_override("panel", UI.style_box(Color("493526"), Color("96714a"), 6, 2))
	craft_column.add_child(table_frame)
	var table_content := VBoxContainer.new()
	table_content.add_theme_constant_override("separation", 8)
	table_frame.add_child(table_content)
	var table_caption := UI.label("Clique direito no item para colocar · clique na célula para devolver", 10, Color("f0d7ad"))
	table_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	table_content.add_child(table_caption)
	var craft_row := HBoxContainer.new()
	craft_row.alignment = BoxContainer.ALIGNMENT_CENTER
	craft_row.add_theme_constant_override("separation", 8)
	table_content.add_child(craft_row)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	craft_row.add_child(grid)
	for i in range(9):
		var slot := _make_craft_table_slot(i)
		grid.add_child(slot)
		_craft_table_slots.append(slot)
	var arrow := UI.label("➜", 26, Color("e8d7ad"))
	arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	craft_row.add_child(arrow)
	_craft_output_slot = _make_craft_table_slot(9)
	_craft_output_slot.custom_minimum_size = Vector2(58, 58)
	craft_row.add_child(_craft_output_slot)
	_craft_output_icon = _craft_output_slot.find_child("CraftIcon", true, false) as Label
	var recipe_heading := UI.label("RESULTADO DA GRADE · clique no resultado para fabricar", 11, Color("d8dfd0"))
	craft_column.add_child(recipe_heading)
	_craft_planks = UI.button("▦  4 tábuas  ·  1 tronco", 350.0)
	_craft_planks.custom_minimum_size.y = 38.0
	_craft_planks.pressed.connect(_craft.bind("planks"))
	craft_column.add_child(_craft_planks)
	_craft_sticks = UI.button("╱╲  4 gravetos  ·  2 tábuas", 350.0)
	_craft_sticks.custom_minimum_size.y = 38.0
	_craft_sticks.pressed.connect(_craft.bind("sticks"))
	craft_column.add_child(_craft_sticks)
	_craft_pickaxe = UI.button("⛏  Picareta  ·  3 tábuas + 2 gravetos", 350.0)
	_craft_pickaxe.custom_minimum_size.y = 38.0
	_craft_pickaxe.pressed.connect(_craft.bind("pickaxe"))
	craft_column.add_child(_craft_pickaxe)
	_eat_fruit = UI.button("Comer fruta  ·  recupera fome", 350.0)
	_eat_fruit.custom_minimum_size.y = 38.0
	_eat_fruit.pressed.connect(_craft.bind("eat"))
	craft_column.add_child(_eat_fruit)


func _make_inventory_slot(item_id: Variant) -> PanelContainer:
	var slot := INVENTORY_SLOT_SCRIPT.new() as PanelContainer
	slot.name = "ItemSlot_%s" % str(item_id)
	slot.custom_minimum_size = Vector2(86.0, 76.0)
	slot.call("configure", "inventory", -1, item_id)
	slot.connect("slot_activated", _on_inventory_slot_gui_input)
	slot.connect("item_dropped", _on_slot_item_dropped)
	var slot_style := UI.style_box(Color("343a3e"), Color("68716d"), 4, 1)
	slot_style.content_margin_left = 3.0
	slot_style.content_margin_right = 3.0
	slot_style.content_margin_top = 2.0
	slot_style.content_margin_bottom = 2.0
	slot.add_theme_stylebox_override("panel", slot_style)
	var content := VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", 0)
	slot.add_child(content)
	var icon := TextureRect.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.name = "ItemTexture"
	icon.custom_minimum_size = Vector2(34.0, 34.0)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.texture = _item_texture(item_id)
	content.add_child(icon)
	var glyph := UI.label(_item_glyph(item_id), 20, Color("f4f0dc"))
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glyph.name = "ItemGlyph"
	glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	glyph.custom_minimum_size.y = 32.0
	glyph.visible = icon.texture == null
	content.add_child(glyph)
	var name_label := UI.label(_item_short_name(item_id), 9, Color("dfe4d9"))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.name = "ItemName"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	content.add_child(name_label)
	var amount := UI.label("0", 11, Color("ffffff"))
	amount.mouse_filter = Control.MOUSE_FILTER_IGNORE
	amount.name = "ItemAmount"
	amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	content.add_child(amount)
	slot.set_item(item_id, int(_inventory.get(item_id, 0)))
	return slot


func _on_inventory_slot_gui_input(slot: PanelContainer, mouse_event: InputEventMouseButton) -> void:
	var item_id: Variant = slot.get("item_id")
	var available := int(_inventory.get(item_id, 0))
	if mouse_event.button_index == MOUSE_BUTTON_LEFT:
		# Clique esquerdo continua selecionando blocos da barra rápida.
		if item_id is int:
			var quickbar_index := QUICKBAR_IDS.find(int(item_id))
			if quickbar_index >= 0:
				_select_slot(quickbar_index)
				_set_game_status("Selecionado: %s." % WORLD_SCRIPT.BLOCK_NAMES.get(int(item_id), "item"))
			else:
				_set_game_status("%s: %d no inventário." % [_item_short_name(item_id), available])
		else:
			_set_game_status("%s: %d no inventário." % [_item_short_name(item_id), available])
	elif mouse_event.button_index == MOUSE_BUTTON_RIGHT:
		# Clique direito coloca uma unidade na primeira célula livre da grade.
		if available > 0:
			var empty_index := _craft_grid_items.find(null)
			if empty_index >= 0:
				_inventory[item_id] = available - 1
				_craft_grid_items[empty_index] = item_id
				_set_game_status("%s colocado na mesa de craft." % _item_short_name(item_id))
			else:
				_set_game_status("A grade de craft está cheia.")
	_refresh_crafting()
	get_viewport().set_input_as_handled()


func _on_slot_item_dropped(slot: PanelContainer, data: Dictionary) -> void:
	var item_id: Variant = data.get("item_id", null)
	if item_id == null:
		return
	var source_kind := str(data.get("source_kind", ""))
	var source_index := int(data.get("source_index", -1))
	if str(slot.get("slot_kind")) == "craft":
		var target_index := int(slot.get("slot_index"))
		if target_index < 0 or target_index >= _craft_grid_items.size():
			return
		if source_kind == "inventory":
			if _craft_grid_items[target_index] != null or int(_inventory.get(item_id, 0)) <= 0:
				return
			_inventory[item_id] = int(_inventory.get(item_id, 0)) - 1
			_craft_grid_items[target_index] = item_id
		elif source_kind == "craft" and source_index >= 0 and source_index < _craft_grid_items.size() and source_index != target_index:
			var target_item: Variant = _craft_grid_items[target_index]
			_craft_grid_items[target_index] = item_id
			_craft_grid_items[source_index] = target_item
		else:
			return
		_set_game_status("Ingrediente colocado na grade.")
	elif str(slot.get("slot_kind")) == "inventory" and source_kind == "craft" and source_index >= 0 and source_index < _craft_grid_items.size():
		if slot.get("item_id") != item_id:
			return
		_inventory[item_id] = mini(99999, int(_inventory.get(item_id, 0)) + 1)
		_craft_grid_items[source_index] = null
		_set_game_status("Ingrediente devolvido ao inventário.")
	else:
		return
	_refresh_crafting()
	_refresh_hud()


func _make_craft_table_slot(index: int) -> PanelContainer:
	var slot := INVENTORY_SLOT_SCRIPT.new() as PanelContainer
	slot.custom_minimum_size = Vector2(48.0, 48.0)
	slot.call("configure", "craft", index, null)
	slot.connect("slot_activated", _on_craft_slot_gui_input)
	slot.connect("item_dropped", _on_slot_item_dropped)
	var craft_style := UI.style_box(Color("292d2d"), Color("777b70"), 3, 1)
	craft_style.content_margin_left = 2.0
	craft_style.content_margin_right = 2.0
	craft_style.content_margin_top = 2.0
	craft_style.content_margin_bottom = 2.0
	slot.add_theme_stylebox_override("panel", craft_style)
	var content := VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", 0)
	slot.add_child(content)
	var texture := TextureRect.new()
	texture.name = "CraftTexture"
	texture.custom_minimum_size = Vector2(28.0, 28.0)
	texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(texture)
	var icon := UI.label("", 17, Color("f3e7cc"))
	icon.name = "CraftIcon"
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	icon.custom_minimum_size.y = 16.0
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(icon)
	return slot


func _on_craft_slot_gui_input(slot: PanelContainer, mouse_event: InputEventMouseButton) -> void:
	if not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	var index := int(slot.get("slot_index"))
	if index == 9:
		_craft_from_grid()
	elif index >= 0 and index < _craft_grid_items.size():
		var item_id: Variant = _craft_grid_items[index]
		if item_id != null:
			_inventory[item_id] = mini(99999, int(_inventory.get(item_id, 0)) + 1)
			_craft_grid_items[index] = null
			_set_game_status("%s devolvido ao inventário." % _item_short_name(item_id))
		_refresh_crafting()
	get_viewport().set_input_as_handled()


func _craft_recipe_for_grid() -> Dictionary:
	return RECIPE_BOOK.find_grid_recipe(_craft_grid_items)


func _craft_from_grid() -> void:
	var recipe := _craft_recipe_for_grid()
	if recipe.is_empty():
		_set_game_status("Receita inválida. Organize os ingredientes na grade.")
		return
	var output_id: Variant = recipe["item"]
	var output_quantity := int(recipe["quantity"])
	var output_limit := int(recipe.get("max_stack", 99999))
	if int(_inventory.get(output_id, 0)) + output_quantity > output_limit:
		_set_game_status("Não há espaço para o resultado.")
		return
	_inventory[output_id] = int(_inventory.get(output_id, 0)) + output_quantity
	for i in range(_craft_grid_items.size()):
		_craft_grid_items[i] = null
	_set_game_status("Fabricado: %s." % str(recipe["name"]))
	_refresh_crafting()
	_refresh_hud()


func _item_texture(item_id: Variant) -> Texture2D:
	var paths := {
		1: "res://assets/textures/blocks/grass_top.png",
		2: "res://assets/textures/blocks/dirt.png",
		3: "res://assets/textures/blocks/stone_minecraft.png",
		4: "res://assets/textures/blocks/oak_log_side.png",
		5: "res://assets/textures/blocks/oak_leaves_minecraft.png",
		6: "res://assets/textures/blocks/sand.png",
		7: "res://assets/textures/blocks/oak_planks.png"
	}
	var path := str(paths.get(item_id, ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


func _item_short_name(item_id: Variant) -> String:
	var names := {1:"Grama", 2:"Terra", 3:"Pedra", 4:"Tronco", 5:"Folhas", 6:"Areia", 7:"Tábuas", 12:"Carne", 13:"Couro", 14:"Lã", 15:"Banha", 16:"Carne cozida", 17:"Ferro", 18:"Cristal", "sementes_trigo":"Sementes de trigo", "trigo":"Trigo", "gravetos":"Gravetos", "picareta":"Picareta", "picareta_ferro":"Picareta de ferro", "machado_ferro":"Machado de ferro", "espada_ferro":"Espada de ferro", "armadura_couro_cabeca":"Capacete de couro", "armadura_couro_peito":"Peitoral de couro", "armadura_couro_pernas":"Calças de couro", "armadura_couro_botas":"Botas de couro", "frutas":"Frutas", "gelatina":"Gelatina", "fragmento_lunar":"Fragmento lunar", "nucleo_lunar":"Núcleo lunar", "mesa_craft":"Mesa de craft", "tocha":"Tocha", "fogueira":"Fogueira"}
	return str(names.get(item_id, item_id))


func _item_glyph(item_id: Variant) -> String:
	var glyphs := {
		1: "▦", 2: "▪", 3: "◆", 4: "▤", 5: "✿", 6: "▧", 7: "▥",
			"gravetos":"╱╲", "picareta":"⛏", "sementes_trigo":"⁙", "trigo":"▥", "frutas":"●", "gelatina":"◆",
		"fragmento_lunar":"✦", "nucleo_lunar":"✧", 12:"●", 13:"⬟", 14:"✿", 15:"◉", 16:"◉", 17:"⬢", "picareta_ferro":"⛏", "machado_ferro":"⚒", "espada_ferro":"†", "armadura_couro_cabeca":"⌂", "armadura_couro_peito":"▣", "armadura_couro_pernas":"▥", "armadura_couro_botas":"∩", "mesa_craft":"⌂", "tocha":"♨", "fogueira":"♨", "lanterna_cristal":"✧"
	}
	return str(glyphs.get(item_id, "■"))


func _build_pause_screen() -> void:
	_pause_screen = Control.new()
	_pause_screen.name = "PauseScreen"
	UI.full_rect(_pause_screen)
	_pause_screen.visible = false
	_pause_screen.process_mode = Node.PROCESS_MODE_ALWAYS
	_ui_layer.add_child(_pause_screen)
	var shade := ColorRect.new()
	shade.color = Color(0.01, 0.02, 0.025, 0.72)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	UI.full_rect(shade)
	_pause_screen.add_child(shade)
	var center := CenterContainer.new()
	UI.full_rect(center)
	_pause_screen.add_child(center)
	var panel := UI.holo_panel(Color("94bc73"), Vector2(34.0, 26.0))
	panel.custom_minimum_size = Vector2(420.0, 0.0)
	center.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	panel.add_child(content)
	var title := UI.display_label("PAUSADO", 30, Color("eef1e5"), "heading")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)
	var resume := UI.button("VOLTAR AO JOGO", 340.0)
	UI.primary(resume)
	resume.pressed.connect(_resume_game)
	content.add_child(resume)
	var save_button := UI.button("SALVAR AGORA", 340.0)
	save_button.pressed.connect(_save_game)
	content.add_child(save_button)
	var exit_button := UI.button("VOLTAR AO MENU", 340.0)
	exit_button.pressed.connect(_return_to_title)
	content.add_child(exit_button)


func _connect_network_signals() -> void:
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)


func _load_profile() -> void:
	_inventory = _default_inventory()
	_selected_avatar_id = "boy"
	_profile_seed = -1
	_profile_loaded = false
	_profile_drops.clear()
	if not FileAccess.file_exists(PROFILE_PATH):
		return
	var file := FileAccess.open(PROFILE_PATH, FileAccess.READ)
	if file == null:
		return
	var parser := JSON.new()
	var parse_error := parser.parse(file.get_as_text())
	file.close()
	if parse_error != OK:
		return
	var parsed: Variant = parser.data
	if not parsed is Dictionary or int(parsed.get("version", 0)) not in [1, PROFILE_VERSION]:
		return
	_profile_seed = int(parsed.get("seed", -1))
	_selected_avatar_id = str(parsed.get("avatar_id", "boy"))
	if _selected_avatar_id not in AVATAR_IDS:
		_selected_avatar_id = "boy"
	var inventory_value: Variant = parsed.get("inventory", {})
	if not inventory_value is Dictionary:
		return
	var inventory_data: Dictionary = inventory_value
	for block_id: int in range(1, 8):
		_inventory[block_id] = clampi(int(inventory_data.get(str(block_id), _inventory[block_id])), 0, 99999)
	_inventory["sementes_trigo"] = clampi(int(inventory_data.get("sementes_trigo", _inventory["sementes_trigo"])), 0, 9999)
	_inventory["trigo"] = clampi(int(inventory_data.get("trigo", 0)), 0, 9999)
	_inventory["gravetos"] = clampi(int(inventory_data.get("gravetos", 0)), 0, 99999)
	_inventory["picareta"] = clampi(int(inventory_data.get("picareta", 0)), 0, 999)
	_inventory["frutas"] = clampi(int(inventory_data.get("frutas", 0)), 0, 9999)
	_inventory["gelatina"] = clampi(int(inventory_data.get("gelatina", 0)), 0, 9999)
	_inventory["fragmento_lunar"] = clampi(int(inventory_data.get("fragmento_lunar", 0)), 0, 9999)
	_inventory["nucleo_lunar"] = clampi(int(inventory_data.get("nucleo_lunar", 0)), 0, 9999)
	for item_id: Variant in [12, 13, 14, 15, 16, 17, 18, "sementes_trigo", "trigo", "mesa_craft", "tocha", "fogueira", "lanterna_cristal", "picareta_ferro", "machado_ferro", "espada_ferro", "armadura_couro_cabeca", "armadura_couro_peito", "armadura_couro_pernas", "armadura_couro_botas"]:
		_inventory[item_id] = clampi(int(inventory_data.get(str(item_id), 0)), 0, 9999)
	var saved_craft_grid: Variant = parsed.get("craft_grid", [])
	if saved_craft_grid is Array and saved_craft_grid.size() == 9:
		var valid_ids: Array = [1, 2, 3, 4, 5, 6, 7, 12, 13, 14, 15, 16, 17, 18, "sementes_trigo", "trigo", "gravetos", "picareta", "picareta_ferro", "machado_ferro", "espada_ferro", "armadura_couro_cabeca", "armadura_couro_peito", "armadura_couro_pernas", "armadura_couro_botas", "frutas", "gelatina", "fragmento_lunar", "nucleo_lunar", "mesa_craft", "tocha", "fogueira", "lanterna_cristal"]
		for i in range(9):
			var craft_id: Variant = saved_craft_grid[i]
			_craft_grid_items[i] = craft_id if craft_id == null or valid_ids.has(craft_id) else null
	_health = clampf(float(parsed.get("health", 20.0)), 0.0, 20.0)
	_food = clampf(float(parsed.get("food", 20.0)), 0.0, 20.0)
	_xp = clampi(int(parsed.get("xp", 0)), 0, 999999999)
	_recalculate_level()
	var position_value: Variant = parsed.get("position", [])
	if position_value is Array and position_value.size() >= 3:
		_profile_position = Vector3(float(position_value[0]), float(position_value[1]), float(position_value[2]))
		# Evita restaurar posições corrompidas ou absurdamente distantes.
		if absf(_profile_position.x) > 1000000.0 or absf(_profile_position.y) > 1000000.0 or absf(_profile_position.z) > 1000000.0:
			_profile_position = Vector3.ZERO
	var drops_data: Variant = parsed.get("drops", [])
	if drops_data is Array:
		_profile_drops = drops_data.slice(0, 5000)
	var crops_data: Variant = parsed.get("crops", [])
	if crops_data is Array:
		_profile_crops = crops_data.slice(0, 500)
	_profile_loaded = true


func _default_inventory() -> Dictionary:
	return {1: 24, 2: 40, 3: 24, 4: 16, 5: 8, 6: 8, 7: 0, "gravetos": 0, "picareta": 0, "picareta_ferro": 0, "frutas": 0, "sementes_trigo": 6, "trigo": 0, "gelatina": 0, "fragmento_lunar": 0, "nucleo_lunar": 0, 12: 0, 13: 0, 14: 0, 15: 0, 16: 0, 17: 0, 18: 0, "mesa_craft": 0, "tocha": 0, "fogueira": 0, "armadura_couro_cabeca": 0, "armadura_couro_peito": 0, "armadura_couro_pernas": 0, "armadura_couro_botas": 0}


func _reset_player_profile() -> void:
	_inventory = _default_inventory()
	_health = 20.0
	_food = 20.0
	_xp = 0
	_level = 1
	_survival_timer = 0.0
	_hunger_tick = 0.0
	_profile_seed = -1
	_profile_loaded = false
	_profile_drops.clear()
	_profile_crops.clear()


func _create_world(seed_value: int, saved_overrides: Array) -> void:
	_clear_world()
	_world = WORLD_SCRIPT.new() as ByteCrafterWorld
	_world.name = "VoxelWorld"
	_world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_world)
	_world.configure(seed_value, saved_overrides, 2)
	_world.blocks_changed.connect(_refresh_hud)
	_crops.clear()
	_crop_nodes.clear()
	_player = PLAYER_SCRIPT.new() as ByteCrafterPlayer
	_player.set_avatar_id(_selected_avatar_id)
	_player.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(_player)
	_player.global_position = _world.get_spawn_position()
	if _profile_loaded and _profile_seed == seed_value:
		_player.global_position = _profile_position
	_spawn_creatures()
	_spawn_enemies()
	if _profile_loaded and _profile_seed == seed_value:
		_restore_profile_drops()
	_selected_slot = 0
	_remote_positions.clear()


func _clear_world() -> void:
	for drop_value: Variant in _drop_nodes.values():
		var drop := drop_value as ByteCrafterDrop
		if is_instance_valid(drop):
			remove_child(drop)
			drop.free()
	_drop_nodes.clear()
	_drop_records.clear()
	_next_drop_id = 1
	for table: Node3D in _crafting_tables:
		if is_instance_valid(table):
			table.queue_free()
	_crafting_tables.clear()
	for crop_value: Variant in _crop_nodes.values():
		var crop_node := crop_value as Node3D
		if is_instance_valid(crop_node):
			crop_node.queue_free()
	_crop_nodes.clear()
	_crops.clear()
	for creature: ByteCrafterCreature in _creatures:
		if is_instance_valid(creature):
			creature.queue_free()
	_creatures.clear()
	for enemy: ByteCrafterEnemy in _enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	_enemies.clear()
	if _player != null and is_instance_valid(_player):
		remove_child(_player)
		_player.free()
		_player = null
	if _world != null and is_instance_valid(_world):
		remove_child(_world)
		_world.free()
		_world = null


func _spawn_creatures() -> void:
	var species_list := ["rabbit", "rabbit", "cow", "sheep", "pig"]
	var species_index := 0
	for x: int in range(-12, 13, 4):
		for z: int in range(-12, 13, 4):
			if _creatures.size() >= species_list.size():
				return
			if absi(x) < 5 and absi(z) < 5:
				continue
			var ground := _world.terrain_height(x, z)
			var above := _world.get_block_at(Vector3i(x, ground + 1, z))
			if above != 0:
				continue
			var creature := CREATURE_SCRIPT.new() as ByteCrafterCreature
			creature.configure(str(species_list[species_index]))
			creature.process_mode = Node.PROCESS_MODE_PAUSABLE
			creature.position = Vector3(float(x) + 0.5, float(ground) + 1.05, float(z) + 0.5)
			add_child(creature)
			_creatures.append(creature)
			creature.defeated.connect(_on_creature_defeated)
			species_index += 1


func _on_creature_defeated(creature: ByteCrafterCreature, at_position: Vector3) -> void:
	_creatures.erase(creature)
	if not _network_active or _is_host:
		_award_xp(creature.get_xp_reward())
		for index: int in creature.get_drops().size():
			var entry: Array = creature.get_drops()[index]
			_spawn_drop_local(_allocate_drop_id(), int(entry[0]), at_position + Vector3(float(index) * 0.35, 0.3, 0.0), int(entry[1]))
	_set_game_status("%s caçado · carne e materiais disponíveis." % creature.get_display_name())


func _spawn_enemies() -> void:
	if _network_active and not _is_host:
		return
	var spawn := _world.get_spawn_position()
	var center := Vector2i(floori(spawn.x), floori(spawn.z))
	var encounters := [
		{"type": "slime", "point": center + Vector2i(7, 3)},
		{"type": "zombie", "point": center + Vector2i(8, -6)},
	]
	if not is_daytime():
		encounters.append({"type": "et", "point": center + Vector2i(-7, 5)})
	if _is_boss_night():
		encounters.append({"type": "boss", "point": center + Vector2i(-11, -9)})
	for encounter: Dictionary in encounters:
		_spawn_enemy(str(encounter.get("type", "slime")), encounter.get("point", Vector2i.ZERO))
	_set_game_status("Inimigos próximos: observe os nomes acima deles.")


func _spawn_enemy(enemy_type: String, spawn_point: Vector2i) -> void:
	spawn_point = _find_safe_enemy_spawn_point(spawn_point)
	var ground := _world.terrain_height(spawn_point.x, spawn_point.y)
	var enemy := ENEMY_SCRIPT.new() as ByteCrafterEnemy
	enemy.process_mode = Node.PROCESS_MODE_PAUSABLE
	enemy.position = Vector3(float(spawn_point.x) + 0.5, float(ground) + 1.18, float(spawn_point.y) + 0.5)
	enemy.configure(_player, self, enemy_type)
	add_child(enemy)
	enemy.defeated.connect(_on_enemy_defeated)
	_enemies.append(enemy)


func _find_safe_enemy_spawn_point(preferred: Vector2i) -> Vector2i:
	for radius: int in range(0, 7):
		for dx: int in range(-radius, radius + 1):
			for dz: int in range(-radius, radius + 1):
				if radius > 0 and absi(dx) != radius and absi(dz) != radius:
					continue
				var candidate := preferred + Vector2i(dx, dz)
				var ground := _world.terrain_height(candidate.x, candidate.y)
				var feet := Vector3i(candidate.x, ground + 1, candidate.y)
				var head := feet + Vector3i.UP
				if _world.get_block_at(feet) == 0 and _world.get_block_at(head) == 0:
					return candidate
	return preferred


func _is_boss_night() -> bool:
	return not is_daytime() and get_sunlight_strength() < 0.035


func _update_enemy_schedule() -> void:
	if _world == null or _player == null or (_network_active and not _is_host):
		return
	var et_present := false
	var boss_present := false
	for enemy: ByteCrafterEnemy in _enemies:
		if not is_instance_valid(enemy):
			continue
		if enemy.enemy_type == "et":
			et_present = true
			if is_daytime():
				# A pele do ET não suporta a luz: a morte também cria o drop normal.
				enemy.take_damage(10.0)
		if enemy.enemy_type == "boss":
			boss_present = true
			if is_daytime():
				enemy.take_damage(10.0)
	if not is_daytime() and not et_present:
		var spawn := _world.get_spawn_position()
		var center := Vector2i(floori(spawn.x), floori(spawn.z))
		_spawn_enemy("et", center + Vector2i(-7, 5))
	if _is_boss_night() and not boss_present:
		var spawn := _world.get_spawn_position()
		var center := Vector2i(floori(spawn.x), floori(spawn.z))
		_spawn_enemy("boss", center + Vector2i(-11, -9))


func _on_enemy_defeated(enemy: Node3D, at_position: Vector3) -> void:
	if enemy is ByteCrafterEnemy:
		_enemies.erase(enemy)
	var reward_item_id: int = enemy.get_reward_item_id() if enemy is ByteCrafterEnemy else 9
	var enemy_name: String = enemy.get_display_name() if enemy is ByteCrafterEnemy else "Inimigo"
	var xp_reward: int = enemy.get_xp_reward() if enemy is ByteCrafterEnemy else 8
	if not _network_active or _is_host:
		_award_xp(xp_reward)
	if enemy is ByteCrafterEnemy:
		_spawn_enemy_loot(enemy as ByteCrafterEnemy, at_position)
	else:
		_spawn_drop_local(_allocate_drop_id(), reward_item_id, at_position + Vector3(0.0, 0.3, 0.0), 1)
	_set_game_status("%s derrotado · loot disponível." % enemy_name)


func _spawn_enemy_loot(enemy: ByteCrafterEnemy, at_position: Vector3) -> void:
	var loot := enemy.get_loot_table()
	for index: int in loot.size():
		var entry: Array = loot[index]
		if entry.size() < 2:
			continue
		var item_id := int(entry[0])
		var quantity := maxi(1, int(entry[1]))
		var offset := Vector3(float(index - loot.size() * 0.5) * 0.42, 0.35 + float(index) * 0.08, 0.0)
		if _network_active:
			_apply_inventory_delta(item_id, 0, quantity)
		else:
			_spawn_drop_local(_allocate_drop_id(), item_id, at_position + offset, quantity)


func _start_singleplayer() -> void:
	_enter_game()


func _start_new_world() -> void:
	_reset_player_profile()
	var new_seed := randi_range(100000, 999999999)
	_create_world(new_seed, [])
	_enter_game()


func _enter_game() -> void:
	if _player == null or _world == null:
		return
	get_tree().paused = false
	_paused = false
	_screen = "game"
	_title_screen.visible = false
	_pause_screen.visible = false
	_game_hud.visible = true
	_craft_panel.visible = false
	_player.process_mode = Node.PROCESS_MODE_PAUSABLE
	_player.can_control = true
	if _player.global_position.y < 0.0 or _player.global_position.distance_to(_world.get_spawn_position()) > 200.0:
		_player.global_position = _world.get_spawn_position()
	_player.velocity = Vector3.ZERO
	_world.update_streaming(_player.global_position)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_refresh_hud()


func _host_lan() -> void:
	if OS.has_feature("web"):
		_set_title_status("Hospedagem LAN está disponível somente na build nativa do Godot.")
		return
	var peer := ENetMultiplayerPeer.new()
	var result := peer.create_server(LAN_PORT, 8)
	if result != OK:
		_set_title_status("Não foi possível abrir a porta UDP %d (código %d)." % [LAN_PORT, result])
		return
	multiplayer.multiplayer_peer = peer
	_network_active = true
	_is_host = true
	_join_pending = false
	_set_title_status("Mundo hospedado na LAN · porta UDP %d" % LAN_PORT)
	_enter_game()


func _join_lan() -> void:
	if OS.has_feature("web"):
		_set_title_status("Para jogar em LAN, abra a build nativa do Godot.")
		return
	var address := _ip_input.text.strip_edges()
	if address.is_empty():
		_set_title_status("Digite o IP local do anfitrião.")
		return
	var peer := ENetMultiplayerPeer.new()
	var result := peer.create_client(address, LAN_PORT)
	if result != OK:
		_set_title_status("Não foi possível iniciar a conexão (código %d)." % result)
		return
	multiplayer.multiplayer_peer = peer
	_network_active = true
	_is_host = false
	_join_pending = true
	_set_title_status("Conectando a %s:%d…" % [address, LAN_PORT])


func _on_connected_to_server() -> void:
	if _join_pending:
		_set_title_status("Conectado. Recebendo o mundo do anfitrião…")
		rpc_id(1, "request_world_state")


func _on_connection_failed() -> void:
	_network_active = false
	_join_pending = false
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	_set_title_status("Conexão falhou. Confira o IP, a mesma rede local e a porta UDP %d." % LAN_PORT)


func _on_server_disconnected() -> void:
	_network_active = false
	_is_host = false
	_join_pending = false
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	_set_game_status("Conexão LAN encerrada pelo anfitrião.")
	_return_to_title()


func _on_peer_connected(peer_id: int) -> void:
	if multiplayer.is_server():
		rpc("register_remote_player", peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
	_remove_remote_player(peer_id)


@rpc("any_peer", "call_remote", "reliable")
func request_world_state() -> void:
	if not multiplayer.is_server() or _world == null:
		return
	var sender := multiplayer.get_remote_sender_id()
	rpc_id(sender, "receive_world_state", _world.world_seed, _world.get_overrides_array())


@rpc("authority", "call_remote", "reliable")
func receive_world_state(seed_value: int, saved_overrides: Array) -> void:
	if not _join_pending:
		return
	_join_pending = false
	_profile_loaded = false
	_create_world(seed_value, saved_overrides)
	_enter_game()
	rpc_id(1, "request_player_roster")
	_set_game_status("Na LAN · sincronizado com o anfitrião")


@rpc("any_peer", "call_remote", "reliable")
func request_player_roster() -> void:
	if not multiplayer.is_server():
		return
	var ids: Array[int] = [1]
	for id: int in multiplayer.get_peers():
		ids.append(id)
	rpc_id(multiplayer.get_remote_sender_id(), "populate_remote_players", ids)


@rpc("authority", "call_remote", "reliable")
func populate_remote_players(peer_ids: Array) -> void:
	for peer_value: Variant in peer_ids:
		_register_remote_player(int(peer_value))


@rpc("authority", "call_local", "reliable")
func register_remote_player(peer_id: int) -> void:
	_register_remote_player(peer_id)


func _register_remote_player(peer_id: int) -> void:
	if peer_id == multiplayer.get_unique_id() or _remote_avatars.has(peer_id):
		return
	var avatar := AVATAR_SCRIPT.new() as ByteCrafterAvatar
	avatar.name = "LANPlayer_%d" % peer_id
	avatar.configure("boy")
	add_child(avatar)
	if _world != null:
		avatar.global_position = _world.get_spawn_position() + Vector3(float(peer_id % 3) * 1.5, 0.0, 2.0)
	_remote_avatars[peer_id] = avatar
	_remote_positions[peer_id] = avatar.global_position


func _remove_remote_player(peer_id: int) -> void:
	if _remote_avatars.has(peer_id):
		var avatar: Node = _remote_avatars[peer_id]
		if is_instance_valid(avatar):
			avatar.queue_free()
		_remote_avatars.erase(peer_id)
	_remote_positions.erase(peer_id)


func _send_player_pose() -> void:
	if not _network_active or _player == null or multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
		return
	var position := _player.global_position
	var yaw := _player.get_avatar_yaw()
	var avatar_id := _player.get_avatar_id()
	var animation_state := _player.get_animation_state()
	if multiplayer.is_server():
		_remote_positions[1] = position
		rpc("receive_player_pose", 1, position, yaw, avatar_id, animation_state)
	else:
		rpc_id(1, "submit_player_pose", position, yaw, avatar_id, animation_state)


@rpc("any_peer", "call_remote", "unreliable_ordered")
func submit_player_pose(position: Vector3, yaw: float, avatar_id: String, animation_state: String) -> void:
	if not multiplayer.is_server():
		return
	var sender := multiplayer.get_remote_sender_id()
	var last: Vector3 = _remote_positions.get(sender, _world.get_spawn_position() if _world != null else Vector3.ZERO)
	if position.distance_to(last) > 14.0:
		return
	if avatar_id not in AVATAR_IDS:
		avatar_id = "boy"
	if animation_state not in ["idle", "walk", "run", "jump", "mine", "attack", "death"]:
		animation_state = "idle"
	_remote_positions[sender] = position
	rpc("receive_player_pose", sender, position, yaw, avatar_id, animation_state)


@rpc("authority", "call_remote", "unreliable_ordered")
func receive_player_pose(peer_id: int, position: Vector3, yaw: float, avatar_id: String, animation_state: String) -> void:
	if peer_id == multiplayer.get_unique_id():
		return
	if not _remote_avatars.has(peer_id):
		_register_remote_player(peer_id)
	var avatar := _remote_avatars.get(peer_id) as ByteCrafterAvatar
	if is_instance_valid(avatar):
		avatar.configure(avatar_id)
		avatar.global_position = position
		avatar.rotation.y = yaw
		avatar.set_animation_state(animation_state)
	_remote_positions[peer_id] = position


func _request_block_change(coords: Vector3i, new_block_id: int, spent_block_id: int) -> void:
	if _world == null:
		return
	var old_block := _world.get_block_at(coords)
	if old_block == new_block_id:
		return
	if not _network_active:
		if _world.set_block_at(coords, new_block_id):
			if new_block_id == 0 and old_block > 0:
				_spawn_drop_local(_allocate_drop_id(), _drop_item_for_block(old_block), Vector3(float(coords.x) + 0.5, float(coords.y) + 0.5, float(coords.z) + 0.5))
				_award_xp(_xp_for_block(old_block))
			if spent_block_id > 0:
				_apply_inventory_delta(0, spent_block_id)
		return
	if multiplayer.is_server():
		if _world.set_block_at(coords, new_block_id):
			var reward_item_id := _drop_item_for_block(old_block) if new_block_id == 0 else 0
			var drop_id := _allocate_drop_id() if reward_item_id > 0 else -1
			var xp_reward := _xp_for_block(old_block) if new_block_id == 0 and old_block > 0 else 0
			rpc("sync_world_block", coords, new_block_id, reward_item_id, spent_block_id, multiplayer.get_unique_id(), drop_id, xp_reward)
	else:
		rpc_id(1, "request_world_block", coords, new_block_id, spent_block_id)


## F: ação contextual. Ataca o alvo à frente; sem alvo, interage com uma mesa
## de craft próxima (abre o crafting); caso contrário, informa o jogador.
func _interact_contextual() -> void:
	if _craft_panel != null and _craft_panel.visible:
		return
	if _try_attack_enemy():
		return
	if _player != null:
		for table: Node3D in _crafting_tables:
			if is_instance_valid(table) and table.global_position.distance_to(_player.global_position) <= 3.2:
				_toggle_crafting()
				return
	_set_game_status("Nada para interagir aqui.")


func _try_attack_enemy() -> bool:
	if _player == null or _attack_cooldown > 0.0:
		return false
	var ray_start := _player.camera.global_position
	var ray_direction := -_player.camera.global_basis.z + Vector3.DOWN * 0.22
	var ray_end := ray_start + ray_direction.normalized() * 3.4
	var query := PhysicsRayQueryParameters3D.create(ray_start, ray_end, 2)
	query.exclude = [_player.get_rid()]
	query.collide_with_bodies = true
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	var enemy := result.get("collider") as ByteCrafterEnemy if not result.is_empty() else null
	if enemy == null:
		# O zumbi e o ET têm colliders muito pequenos por design. O cone curto
		# abaixo evita que um golpe falhe só porque o raio passou ao lado deles.
		var best_distance := 3.4
		var forward := -_player.camera.global_basis.z
		for candidate: ByteCrafterEnemy in _enemies:
			if not is_instance_valid(candidate) or candidate.get("_defeated"):
				continue
			var to_enemy := candidate.global_position + Vector3.UP * 0.45 - ray_start
			var forward_distance := to_enemy.dot(forward)
			var lateral_distance := (to_enemy - forward * forward_distance).length()
			if forward_distance > 0.0 and forward_distance <= best_distance and lateral_distance <= 0.72:
					enemy = candidate
					best_distance = forward_distance
		if enemy == null:
			var best_creature: ByteCrafterCreature = null
			var best_creature_distance := 3.4
			var creature_forward := -_player.camera.global_basis.z
			for candidate: ByteCrafterCreature in _creatures:
				if not is_instance_valid(candidate) or candidate.get("_defeated"):
					continue
				var to_creature := candidate.global_position + Vector3.UP * 0.45 - ray_start
				var forward_distance := to_creature.dot(creature_forward)
				var lateral_distance := (to_creature - creature_forward * forward_distance).length()
				if forward_distance > 0.0 and forward_distance <= best_creature_distance and lateral_distance <= 0.9:
					best_creature = candidate
					best_creature_distance = forward_distance
			if best_creature != null:
				_attack_cooldown = 0.48
				_player.play_action("attack")
				best_creature.take_damage(3 if int(_inventory.get("espada_ferro", 0)) > 0 else (2 if int(_inventory.get("picareta_ferro", 0)) > 0 or int(_inventory.get("picareta", 0)) > 0 else 1))
				_set_game_status("Caçando %s · vida %d" % [best_creature.get_display_name(), best_creature.health])
				return true
	if enemy == null:
		return false
	_attack_cooldown = 0.48
	_player.play_action("attack")
	var damage := 5.0 if int(_inventory.get("espada_ferro", 0)) > 0 else (3.0 if int(_inventory.get("picareta_ferro", 0)) > 0 or int(_inventory.get("picareta", 0)) > 0 else 1.5)
	enemy.take_damage(damage)
	_set_game_status("Golpe acertou %s · vida %.1f" % [enemy.get_display_name(), enemy.health])
	return true


@rpc("any_peer", "call_remote", "reliable")
func request_world_block(coords: Vector3i, new_block_id: int, spent_block_id: int) -> void:
	if not multiplayer.is_server() or _world == null:
		return
	var sender := multiplayer.get_remote_sender_id()
	if new_block_id < 0 or new_block_id > 7 or spent_block_id < 0 or spent_block_id > 7:
		return
	var player_position: Vector3 = _remote_positions.get(sender, _world.get_spawn_position())
	var block_center := Vector3(float(coords.x) + 0.5, float(coords.y) + 0.5, float(coords.z) + 0.5)
	if player_position.distance_to(block_center) > BREAK_DIST:
		return
	var old_block := _world.get_block_at(coords)
	if old_block == new_block_id or (new_block_id == 0 and old_block == 0):
		return
	if _world.set_block_at(coords, new_block_id):
		var reward_item_id := _drop_item_for_block(old_block) if new_block_id == 0 else 0
		var drop_id := _allocate_drop_id() if reward_item_id > 0 else -1
		var xp_reward := _xp_for_block(old_block) if new_block_id == 0 and old_block > 0 else 0
		rpc("sync_world_block", coords, new_block_id, reward_item_id, spent_block_id, sender, drop_id, xp_reward)


@rpc("authority", "call_local", "reliable")
func sync_world_block(coords: Vector3i, new_block_id: int, reward_item_id: int, spent_block_id: int, actor_id: int, drop_id: int, xp_reward := 0) -> void:
	if _world != null:
		_world.set_block_at(coords, new_block_id)
	if reward_item_id > 0 and drop_id >= 0:
		_spawn_drop_local(drop_id, reward_item_id, Vector3(float(coords.x) + 0.5, float(coords.y) + 0.5, float(coords.z) + 0.5))
	if actor_id == multiplayer.get_unique_id() and spent_block_id > 0:
		_apply_inventory_delta(0, spent_block_id)
	if actor_id == multiplayer.get_unique_id() and xp_reward > 0:
		_award_xp(xp_reward)


func _apply_inventory_delta(reward_id: int, spent_id: int, reward_quantity: int = 1) -> void:
	if reward_id > 0:
		if reward_id == 8:
			_inventory["frutas"] = mini(9999, int(_inventory.get("frutas", 0)) + reward_quantity)
		elif reward_id == 9:
			_inventory["gelatina"] = mini(9999, int(_inventory.get("gelatina", 0)) + reward_quantity)
		elif reward_id == 10:
			_inventory["fragmento_lunar"] = mini(9999, int(_inventory.get("fragmento_lunar", 0)) + reward_quantity)
		elif reward_id == 11:
			_inventory["nucleo_lunar"] = mini(9999, int(_inventory.get("nucleo_lunar", 0)) + reward_quantity)
		else:
			_inventory[reward_id] = mini(99999, int(_inventory.get(reward_id, 0)) + reward_quantity)
	if spent_id > 0:
		_inventory[spent_id] = maxi(0, int(_inventory.get(spent_id, 0)) - 1)
	_refresh_hud()


func _drop_item_for_block(block_id: int) -> int:
	if block_id == 11 or block_id == 13:
		return 18
	if block_id == 12:
		return 3
	return 8 if block_id == 5 and randf() < 0.24 else block_id


func _xp_for_block(block_id: int) -> int:
	return int(XP_BY_BLOCK.get(block_id, 0))


func _xp_for_next_level(level: int) -> int:
	return 20 + maxi(0, level - 1) * 12


func _recalculate_level() -> void:
	_level = 1
	var remaining := _xp
	while remaining >= _xp_for_next_level(_level) and _level < 999:
		remaining -= _xp_for_next_level(_level)
		_level += 1


func _xp_into_current_level() -> int:
	var remaining := _xp
	for level: int in range(1, _level):
		remaining -= _xp_for_next_level(level)
	return maxi(0, remaining)


func _award_xp(amount: int) -> void:
	if amount <= 0:
		return
	var previous_level := _level
	_xp = clampi(_xp + amount, 0, 999999999)
	_recalculate_level()
	if _level > previous_level:
		_set_game_status("Nível %d alcançado!" % _level)
	_refresh_hud()


func _allocate_drop_id() -> int:
	var result := _next_drop_id
	_next_drop_id += 1
	return result


func _spawn_drop_local(drop_id: int, item_id: int, drop_position: Vector3, quantity: int = 1) -> void:
	if drop_id < 0 or item_id <= 0 or _drop_nodes.has(drop_id):
		return
	var drop := DROP_SCRIPT.new() as ByteCrafterDrop
	drop.configure(drop_id, item_id, maxi(1, quantity))
	drop.process_mode = Node.PROCESS_MODE_PAUSABLE
	drop.position = drop_position
	add_child(drop)
	_drop_nodes[drop_id] = drop
	_drop_records[drop_id] = {"item_id": item_id, "quantity": maxi(1, quantity), "position": drop_position}
	_next_drop_id = maxi(_next_drop_id, drop_id + 1)


func _update_drop_position(drop_id: int, drop_position: Vector3) -> void:
	if _drop_records.has(drop_id):
		(_drop_records[drop_id] as Dictionary)["position"] = drop_position


func _restore_profile_drops() -> void:
	for entry: Variant in _profile_drops:
		if not entry is Array or entry.size() < 5:
			continue
		var drop_id := int(entry[0])
		var item_id := int(entry[1])
		if item_id <= 0 or item_id > 18:
			continue
		var quantity := maxi(1, int(entry[5])) if entry.size() >= 6 else 1
		_spawn_drop_local(drop_id, item_id, Vector3(float(entry[2]), float(entry[3]), float(entry[4])), quantity)


func _serialize_drops() -> Array:
	var result: Array = []
	for key: Variant in _drop_records.keys():
		var drop_id := int(key)
		var record: Dictionary = _drop_records[drop_id]
		var drop_position: Vector3 = record.get("position", Vector3.ZERO)
		result.append([drop_id, int(record.get("item_id", 0)), drop_position.x, drop_position.y, drop_position.z, int(record.get("quantity", 1))])
	return result


func _remove_drop_local(drop_id: int) -> void:
	var drop: Variant = _drop_nodes.get(drop_id)
	if drop is ByteCrafterDrop and is_instance_valid(drop):
		drop.queue_free()
	_drop_nodes.erase(drop_id)
	_drop_records.erase(drop_id)


func _on_drop_touched(drop_id: int) -> void:
	if not _drop_records.has(drop_id):
		return
	if not _network_active:
		var item_id := int((_drop_records[drop_id] as Dictionary).get("item_id", 0))
		var quantity := int((_drop_records[drop_id] as Dictionary).get("quantity", 1))
		_remove_drop_local(drop_id)
		_apply_inventory_delta(item_id, 0, quantity)
	elif multiplayer.is_server():
		_collect_drop_authoritatively(drop_id, multiplayer.get_unique_id())
	else:
		rpc_id(1, "request_collect_drop", drop_id)


func _collect_drop_authoritatively(drop_id: int, actor_id: int) -> void:
	if not _drop_records.has(drop_id):
		if actor_id != multiplayer.get_unique_id():
			rpc_id(actor_id, "drop_collection_rejected", drop_id)
		return
	var record: Dictionary = _drop_records[drop_id]
	var drop_position: Vector3 = record.get("position", Vector3.ZERO)
	var player_position := _player.global_position if actor_id == multiplayer.get_unique_id() and _player != null else Vector3.ZERO
	if actor_id != multiplayer.get_unique_id():
		player_position = _remote_positions.get(actor_id, Vector3.ZERO)
	if player_position.distance_to(drop_position) > 2.1:
		if actor_id != multiplayer.get_unique_id():
			rpc_id(actor_id, "drop_collection_rejected", drop_id)
		return
	var item_id := int(record.get("item_id", 0))
	_drop_records.erase(drop_id)
	rpc("sync_drop_collected", drop_id, item_id, actor_id)


@rpc("any_peer", "call_remote", "reliable")
func request_collect_drop(drop_id: int) -> void:
	if not _network_active or not multiplayer.is_server():
		return
	_collect_drop_authoritatively(drop_id, multiplayer.get_remote_sender_id())


@rpc("authority", "call_local", "reliable")
func sync_drop_collected(drop_id: int, item_id: int, actor_id: int) -> void:
	var quantity := 1
	if _drop_records.has(drop_id):
		quantity = int((_drop_records[drop_id] as Dictionary).get("quantity", 1))
	_remove_drop_local(drop_id)
	if actor_id == multiplayer.get_unique_id():
		_apply_inventory_delta(item_id, 0, quantity)


@rpc("authority", "call_remote", "reliable")
func drop_collection_rejected(drop_id: int) -> void:
	var drop: Variant = _drop_nodes.get(drop_id)
	if drop is ByteCrafterDrop and is_instance_valid(drop):
		drop.allow_retry()


func _raycast_target() -> Dictionary:
	if _player == null or _player.camera == null:
		return {}
	var camera := _player.camera
	var origin := camera.global_position
	var end := origin + (-camera.global_transform.basis.z * BREAK_DIST)
	var query := PhysicsRayQueryParameters3D.create(origin, end, 1)
	query.exclude = [_player.get_rid()]
	query.collide_with_bodies = true
	query.collide_with_areas = false
	return get_world_3d().direct_space_state.intersect_ray(query)


func _hit_block_position(hit: Dictionary, outside: bool) -> Vector3i:
	var point: Vector3 = hit.get("position", Vector3.ZERO)
	var normal: Vector3 = hit.get("normal", Vector3.UP)
	if outside:
		point += normal * 0.02
	else:
		point -= normal * 0.02
	return Vector3i(floori(point.x), floori(point.y), floori(point.z))


func _process_mining(delta: float) -> void:
	if not _mine_held or _world == null or _player == null or (_craft_panel != null and _craft_panel.visible):
		_mine_progress.visible = false
		return
	var hit := _raycast_target()
	if hit.is_empty():
		_mine_timer = 0.0
		_mine_progress.visible = false
		return
	var coords := _hit_block_position(hit, false)
	var block_id := _world.get_block_at(coords)
	if block_id == 0:
		_mine_progress.visible = false
		return
	if block_id == 3 and int(_inventory.get("picareta", 0)) <= 0 and int(_inventory.get("picareta_ferro", 0)) <= 0:
		_mine_progress.visible = false
		_set_game_status("Pedra exige uma picareta equipada.")
		_mine_held = false
		return
	if coords != _mine_position:
		_mine_position = coords
		_mine_timer = 0.0
		_mine_duration = _break_duration(block_id)
		_player.play_action("mine")
	_mine_timer += delta
	_mine_progress.visible = true
	_mine_progress.value = clampf(_mine_timer / _mine_duration, 0.0, 1.0) * 100.0
	if _mine_timer >= _mine_duration:
		_request_block_change(coords, 0, 0)
		_mine_held = false
		_mine_timer = 0.0
		_mine_progress.visible = false


func _break_duration(block_id: int) -> float:
	var base := 1.0
	if block_id in [1, 2, 6]:
		base = 0.43
	elif block_id in [4, 5, 7]:
		base = 0.72
	elif block_id == 3:
		base = 1.25
	if block_id == 3 and (int(_inventory.get("picareta_ferro", 0)) > 0 or int(_inventory.get("picareta", 0)) > 0):
		base *= 0.22 if int(_inventory.get("picareta_ferro", 0)) > 0 else 0.34
	if block_id in [4, 5] and int(_inventory.get("machado_ferro", 0)) > 0:
		base *= 0.28
	return base


func _place_crafting_table() -> void:
	if _player == null or int(_inventory.get("mesa_craft", 0)) <= 0:
		_set_game_status("Fabrique uma mesa de craft primeiro.")
		return
	var point := _player.global_position - _player.global_basis.z * 1.7
	point.y = _player.global_position.y - 0.85
	var table := StaticBody3D.new()
	table.name = "CraftingTable_%d" % (_crafting_tables.size() + 1)
	table.position = point
	var top := MeshInstance3D.new()
	var top_mesh := BoxMesh.new()
	top_mesh.size = Vector3(1.2, 0.18, 0.9)
	top.mesh = top_mesh
	top.position.y = 0.9
	top.material_override = _simple_material(Color("8d5c38"))
	table.add_child(top)
	for x: float in [-0.42, 0.42]:
		for z: float in [-0.28, 0.28]:
			var leg := MeshInstance3D.new()
			var leg_mesh := BoxMesh.new()
			leg_mesh.size = Vector3(0.14, 0.9, 0.14)
			leg.mesh = leg_mesh
			leg.position = Vector3(x, 0.45, z)
			leg.material_override = _simple_material(Color("5b3a27"))
			table.add_child(leg)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.2, 1.0, 0.9)
	shape.shape = box
	shape.position.y = 0.5
	table.add_child(shape)
	var label := Label3D.new()
	label.text = "MESA DE CRAFT"
	label.position.y = 1.25
	label.font_size = 24
	label.pixel_size = 0.0035
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	table.add_child(label)
	add_child(table)
	_crafting_tables.append(table)
	_inventory["mesa_craft"] = maxi(0, int(_inventory.get("mesa_craft", 0)) - 1)
	_refresh_hud()
	_set_game_status("Mesa colocada. Pressione E próximo dela para abrir o crafting.")


func _use_farming_action() -> void:
	if _world == null or _player == null:
		return
	var hit := _raycast_target()
	if hit.is_empty():
		_set_game_status("Aponte para terra ou grama para plantar.")
		return
	var cell := _hit_block_position(hit, true)
	if _crops.has(cell):
		var crop_data: Dictionary = _crops[cell]
		if int(crop_data.get("stage", 0)) < 3:
			_set_game_status("O trigo ainda está crescendo.")
			return
		_crops.erase(cell)
		var old_node := _crop_nodes.get(cell) as Node3D
		if is_instance_valid(old_node):
			old_node.queue_free()
		_crop_nodes.erase(cell)
		_inventory["trigo"] = mini(9999, int(_inventory.get("trigo", 0)) + 2)
		_inventory["sementes_trigo"] = mini(9999, int(_inventory.get("sementes_trigo", 0)) + 1)
		_award_xp(2)
		_set_game_status("Trigo colhido: +2 trigo e +1 semente.")
		_refresh_hud()
		return
	var support := _world.get_block_at(cell - Vector3i.UP)
	if support not in [1, 2] or _world.get_block_at(cell) != 0:
		_set_game_status("Plante sobre terra ou grama vazia.")
		return
	if int(_inventory.get("sementes_trigo", 0)) <= 0:
		_set_game_status("Você precisa de sementes de trigo.")
		return
	_inventory["sementes_trigo"] = int(_inventory.get("sementes_trigo", 0)) - 1
	_crops[cell] = {"stage": 0, "age": 0.0}
	_create_or_update_crop(cell)
	_set_game_status("Semente plantada. Pressione P novamente quando o trigo amadurecer.")
	_refresh_hud()


func _process_crops(delta: float) -> void:
	for cell_value: Variant in _crops.keys():
		var cell := cell_value as Vector3i
		var crop_data: Dictionary = _crops[cell]
		var stage := int(crop_data.get("stage", 0))
		if stage < 3:
			crop_data["age"] = float(crop_data.get("age", 0.0)) + delta
			crop_data["stage"] = mini(3, int(floor(float(crop_data["age"]) / 8.0)))
			_crops[cell] = crop_data
		_create_or_update_crop(cell)


func _create_or_update_crop(cell: Vector3i) -> void:
	if not _crops.has(cell):
		return
	var stage := int((_crops[cell] as Dictionary).get("stage", 0))
	var crop := _crop_nodes.get(cell) as Node3D
	if not is_instance_valid(crop):
		crop = Node3D.new()
		crop.name = "Trigo_%d_%d_%d" % [cell.x, cell.y, cell.z]
		add_child(crop)
		_crop_nodes[cell] = crop
	for child: Node in crop.get_children():
		child.queue_free()
	var stalk := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.12 + stage * 0.05, 0.22 + stage * 0.20, 0.12 + stage * 0.05)
	stalk.mesh = mesh
	stalk.position.y = mesh.size.y * 0.5
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("6c9e36") if stage < 3 else Color("d8b43d")
	material.roughness = 0.9
	stalk.material_override = material
	crop.add_child(stalk)
	crop.position = Vector3(float(cell.x) + 0.5, float(cell.y), float(cell.z) + 0.5)


func _restore_profile_crops() -> void:
	for entry_value: Variant in _profile_crops:
		if not entry_value is Dictionary:
			continue
		var entry: Dictionary = entry_value
		var position_value: Variant = entry.get("position", [])
		if not position_value is Array or position_value.size() < 3:
			continue
		var cell := Vector3i(int(position_value[0]), int(position_value[1]), int(position_value[2]))
		if _world.get_block_at(cell - Vector3i.UP) not in [1, 2] or _world.get_block_at(cell) != 0:
			continue
		_crops[cell] = {"stage": clampi(int(entry.get("stage", 0)), 0, 3), "age": maxf(0.0, float(entry.get("age", 0.0)))}
		_create_or_update_crop(cell)


func _simple_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.86
	return material


func _armor_damage_reduction() -> float:
	var pieces := 0
	for item_id: String in ["armadura_couro_cabeca", "armadura_couro_peito", "armadura_couro_pernas", "armadura_couro_botas"]:
		pieces += mini(1, int(_inventory.get(item_id, 0)))
	return minf(0.60, float(pieces) * 0.15)


func _place_selected_block() -> void:
	if _world == null or _player == null:
		return
	var selected_item: Variant = QUICKBAR_IDS[_selected_slot]
	if not selected_item is int:
		_set_game_status("Selecione um bloco para colocar.")
		return
	var block_id := int(selected_item)
	if int(_inventory.get(block_id, 0)) <= 0:
		_set_game_status("Sem %s no inventário." % WORLD_SCRIPT.BLOCK_NAMES.get(block_id, "bloco").to_lower())
		return
	var hit := _raycast_target()
	if hit.is_empty():
		return
	var coords := _hit_block_position(hit, true)
	if _world.get_block_at(coords) != 0:
		return
	if _placement_overlaps_player(coords):
		return
	_request_block_change(coords, block_id, block_id)


func _placement_overlaps_player(coords: Vector3i) -> bool:
	if _player == null or get_world_3d() == null:
		return false
	var query_shape := BoxShape3D.new()
	query_shape.size = Vector3.ONE * 0.98
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = query_shape
	query.transform = Transform3D(Basis.IDENTITY, Vector3(coords) + Vector3.ONE * 0.5)
	query.collision_mask = 1
	query.collide_with_bodies = true
	for result: Dictionary in get_world_3d().direct_space_state.intersect_shape(query, 16):
		if result.get("collider") == _player:
			return true
	var player_collider := _player.get_node_or_null("PlayerCollider") as CollisionShape3D
	var capsule := player_collider.shape as CapsuleShape3D if player_collider != null else null
	if capsule == null:
		return false
	var capsule_center := _player.global_position + player_collider.position
	var capsule_min := capsule_center - Vector3(capsule.radius, capsule.height * 0.5, capsule.radius)
	var capsule_max := capsule_center + Vector3(capsule.radius, capsule.height * 0.5, capsule.radius)
	var block_min := Vector3(coords)
	var block_max := block_min + Vector3.ONE
	return capsule_min.x < block_max.x and capsule_max.x > block_min.x and capsule_min.y < block_max.y and capsule_max.y > block_min.y and capsule_min.z < block_max.z and capsule_max.z > block_min.z


func _select_slot(index: int) -> void:
	_selected_slot = posmod(index, QUICKBAR_IDS.size())
	_refresh_hud()


func _toggle_crafting() -> void:
	if _craft_panel == null:
		return
	var will_close := _craft_panel.visible
	if will_close:
		_return_craft_grid_to_inventory()
	_craft_panel.visible = not _craft_panel.visible
	_mine_held = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if _craft_panel.visible else Input.MOUSE_MODE_CAPTURED
	_refresh_crafting()


func _return_craft_grid_to_inventory() -> void:
	for i in range(_craft_grid_items.size()):
		var item_id: Variant = _craft_grid_items[i]
		if item_id == null:
			continue
		_inventory[item_id] = mini(99999, int(_inventory.get(item_id, 0)) + 1)
		_craft_grid_items[i] = null


func _craft(recipe: String) -> void:
	var crafted := false
	var failure_message := "Recursos insuficientes ou não é possível usar isso agora."
	var result_name := ""
	if recipe == "eat":
		if int(_inventory.get("frutas", 0)) > 0 and _food < 20.0:
			_inventory["frutas"] = int(_inventory["frutas"]) - 1
			_food = minf(20.0, _food + 5.0)
			crafted = true
			result_name = "fruta consumida"
	else:
		var recipe_data: Dictionary = RECIPE_BOOK.get_quick_recipe(recipe)
		if not recipe_data.is_empty():
			var ingredients: Array = recipe_data.get("ingredients", [])
			var has_ingredients := true
			for ingredient_value: Variant in ingredients:
				if not ingredient_value is Dictionary:
					has_ingredients = false
					break
				var ingredient: Dictionary = ingredient_value
				var ingredient_id: Variant = ingredient.get("item", null)
				var ingredient_quantity := int(ingredient.get("quantity", 0))
				if ingredient_id == null or ingredient_quantity <= 0 or int(_inventory.get(ingredient_id, 0)) < ingredient_quantity:
					has_ingredients = false
					break
			var output_id: Variant = recipe_data.get("item", null)
			var output_quantity := int(recipe_data.get("quantity", 0))
			var output_limit := int(recipe_data.get("max_stack", 99999))
			var has_space := output_id != null and output_quantity > 0 and output_limit > 0 and int(_inventory.get(output_id, 0)) + output_quantity <= output_limit
			if not has_space:
				failure_message = "Não há espaço para o resultado."
			elif has_ingredients:
				for ingredient_value: Variant in ingredients:
					var ingredient: Dictionary = ingredient_value
					var ingredient_id: Variant = ingredient["item"]
					_inventory[ingredient_id] = int(_inventory.get(ingredient_id, 0)) - int(ingredient["quantity"])
				_inventory[output_id] = int(_inventory.get(output_id, 0)) + output_quantity
				crafted = true
				result_name = str(recipe_data.get("name", recipe))
	if crafted:
		_set_game_status("Receita concluída: %s." % result_name)
	else:
		_set_game_status(failure_message)
	_refresh_crafting()
	_refresh_hud()

func _refresh_crafting() -> void:
	if _craft_panel == null:
		return
	if _craft_info != null:
		_craft_info.text = "Itens carregados: %d tipos\nGravetos: %d · Picaretas: %d\nFrutas: %d · Gelatina: %d\nFragmentos lunares: %d · Núcleos lunares: %d" % [
			_inventory_item_ids.size(), int(_inventory.get("gravetos", 0)), int(_inventory.get("picareta", 0)),
			int(_inventory.get("frutas", 0)), int(_inventory.get("gelatina", 0)),
			int(_inventory.get("fragmento_lunar", 0)), int(_inventory.get("nucleo_lunar", 0))]
	if _inventory_grid != null:
		for slot in _inventory_grid.get_children():
			var item_id: Variant = slot.get_meta("item_id", null)
			slot.call("set_item", item_id, int(_inventory.get(item_id, 0)))
			var amount_label := slot.find_child("ItemAmount", true, false) as Label
			if amount_label != null:
				amount_label.text = str(int(_inventory.get(item_id, 0)))
			var texture_rect := slot.find_child("ItemTexture", true, false) as TextureRect
			var glyph := slot.find_child("ItemGlyph", true, false) as Label
			if texture_rect != null and glyph != null:
				texture_rect.texture = _item_texture(item_id)
				glyph.visible = texture_rect.texture == null
	for i in range(_craft_table_slots.size()):
		var craft_slot := _craft_table_slots[i]
		var craft_icon := craft_slot.find_child("CraftIcon", true, false) as Label
		var craft_texture := craft_slot.find_child("CraftTexture", true, false) as TextureRect
		var craft_item: Variant = _craft_grid_items[i]
		craft_slot.call("set_item", craft_item, 1 if craft_item != null else 0)
		if craft_icon != null:
			craft_icon.text = "" if craft_item == null else _item_glyph(craft_item)
		if craft_texture != null:
			craft_texture.texture = null if craft_item == null else _item_texture(craft_item)
			craft_texture.visible = craft_texture.texture != null
		if craft_icon != null and craft_texture != null and craft_texture.visible and craft_item is int:
			craft_icon.text = ""
	var grid_recipe := _craft_recipe_for_grid()
	_craft_output_item = grid_recipe.get("item", null)
	_craft_output_quantity = int(grid_recipe.get("quantity", 0))
	if _craft_output_icon != null:
		var output_texture: TextureRect = null
		if _craft_output_slot != null:
			output_texture = _craft_output_slot.find_child("CraftTexture", true, false) as TextureRect
		if _craft_output_item == null:
			_craft_output_icon.text = "?"
			if output_texture != null:
				output_texture.texture = null
				output_texture.visible = false
		else:
			var output_item_texture := _item_texture(_craft_output_item)
			if output_texture != null:
				output_texture.texture = output_item_texture
				output_texture.visible = output_item_texture != null
			_craft_output_icon.text = "×%d" % _craft_output_quantity if output_item_texture != null else "%s\n×%d" % [_item_glyph(_craft_output_item), _craft_output_quantity]
	if _craft_planks != null:
		_craft_planks.disabled = int(_inventory.get(4, 0)) < 1
	if _craft_sticks != null:
		_craft_sticks.disabled = int(_inventory.get(7, 0)) < 2
	if _craft_pickaxe != null:
		_craft_pickaxe.disabled = int(_inventory.get(7, 0)) < 3 or int(_inventory.get("gravetos", 0)) < 2
	if _eat_fruit != null:
		_eat_fruit.disabled = int(_inventory.get("frutas", 0)) < 1 or _food >= 20.0


func _refresh_hud() -> void:
	if _player != null:
		_player.set_equipped_tool("picareta" if int(_inventory.get("picareta_ferro", 0)) > 0 or int(_inventory.get("picareta", 0)) > 0 else "")
	if _game_hud == null:
		return
	if _health_bar != null:
		_health_bar.value = _health
	if _food_bar != null:
		_food_bar.value = _food
	if _level_label != null:
		_level_label.text = "NÍVEL %d" % _level
	if _xp_bar != null:
		_xp_bar.max_value = _xp_for_next_level(_level)
		_xp_bar.value = _xp_into_current_level()
	for index: int in _hotbar_slots.size():
		var slot := _hotbar_slots[index]
		var item_id: Variant = QUICKBAR_IDS[index]
		var amount := slot.find_child("Amount", true, false) as Label
		var icon := slot.find_child("ItemIcon", true, false) as TextureRect
		var glyph := slot.find_child("ItemGlyph", true, false) as Label
		if icon != null:
			icon.texture = _make_block_icon(int(item_id)) if item_id is int else _item_texture(item_id)
		if glyph != null:
			glyph.text = _item_glyph(item_id)
			glyph.visible = icon == null or icon.texture == null
		if amount != null:
			amount.text = str(_inventory.get(item_id, 0))
			var accent := Color("c0d899") if index == _selected_slot else Color(0.75, 0.83, 0.69, 0.2)
			var background := Color(0.13, 0.16, 0.12, 0.94) if index == _selected_slot else Color(0.035, 0.045, 0.052, 0.9)
			slot.add_theme_stylebox_override("panel", UI.style_box(background, accent, 6, 2 if index == _selected_slot else 1))
	if _selected_item_label != null:
		var selected_item: Variant = QUICKBAR_IDS[_selected_slot]
		_selected_item_label.text = "%d · %s  (%d)" % [_selected_slot + 1, _item_short_name(selected_item), int(_inventory.get(selected_item, 0))]
	if _position_label != null and _player != null and _world != null:
		_position_label.text = "SEMENTE %d\nX %d · Y %d · Z %d\nNÍVEL %d · XP %d/%d" % [_world.world_seed, floori(_player.global_position.x), floori(_player.global_position.y), floori(_player.global_position.z), _level, _xp_into_current_level(), _xp_for_next_level(_level)]
	_refresh_crafting()


func _refresh_position_label() -> void:
	if _position_label == null or _player == null or _world == null:
		return
	_position_label.text = "SEMENTE %d\nX %d · Y %d · Z %d\nNÍVEL %d · XP %d/%d" % [_world.world_seed, floori(_player.global_position.x), floori(_player.global_position.y), floori(_player.global_position.z), _level, _xp_into_current_level(), _xp_for_next_level(_level)]


func _make_block_icon(block_id: int) -> AtlasTexture:
	var tiles: Array = WORLD_SCRIPT.BLOCK_ATLAS_TILES.get(block_id, [0])
	var tile_index := int(tiles[0]) if not tiles.is_empty() else 0
	var atlas_size := VOXEL_ATLAS_TEXTURE.get_size()
	var tile_size := Vector2(atlas_size.x / float(WORLD_SCRIPT.ATLAS_COLUMNS), atlas_size.y / float(WORLD_SCRIPT.ATLAS_ROWS))
	var icon := AtlasTexture.new()
	icon.atlas = VOXEL_ATLAS_TEXTURE
	icon.region = Rect2(Vector2(float(tile_index % WORLD_SCRIPT.ATLAS_COLUMNS), float(tile_index / WORLD_SCRIPT.ATLAS_COLUMNS)) * tile_size, tile_size)
	icon.filter_clip = true
	return icon


func _set_title_status(message: String) -> void:
	if _title_status != null:
		_title_status.text = message


func _set_game_status(message: String) -> void:
	if _game_status != null:
		_game_status.text = message
		var status_panel := _game_status.get_parent() as Control
		if status_panel != null:
			status_panel.visible = not message.is_empty()


func _toggle_pause() -> void:
	if _screen != "game":
		return
	if _paused:
		_resume_game()
	else:
		_paused = true
		_mine_held = false
		_craft_panel.visible = false
		_pause_screen.visible = true
		get_tree().paused = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_save_game()


func _resume_game() -> void:
	get_tree().paused = false
	_paused = false
	_pause_screen.visible = false
	_player.can_control = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _return_to_title() -> void:
	_save_game()
	get_tree().paused = false
	_paused = false
	if multiplayer.multiplayer_peer != null and not multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
		multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	_network_active = false
	_is_host = false
	_join_pending = false
	_screen = "title"
	_player.can_control = false
	_player.process_mode = Node.PROCESS_MODE_DISABLED
	_title_screen.visible = true
	_game_hud.visible = false
	_pause_screen.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _save_game() -> void:
	if _world == null or (_network_active and not _is_host):
		return
	_world.save_to_disk()
	if _player == null:
		return
	var player_position := _player.position
	if _player.is_inside_tree():
		player_position = _player.global_position
	var inventory_data: Dictionary = {}
	for block_id: int in range(1, 8):
		inventory_data[str(block_id)] = int(_inventory.get(block_id, 0))
	inventory_data["gravetos"] = int(_inventory.get("gravetos", 0))
	inventory_data["picareta"] = int(_inventory.get("picareta", 0))
	inventory_data["frutas"] = int(_inventory.get("frutas", 0))
	inventory_data["gelatina"] = int(_inventory.get("gelatina", 0))
	inventory_data["fragmento_lunar"] = int(_inventory.get("fragmento_lunar", 0))
	inventory_data["nucleo_lunar"] = int(_inventory.get("nucleo_lunar", 0))
	for item_id: Variant in [12, 13, 14, 15, 16, 17, 18, "sementes_trigo", "trigo", "mesa_craft", "tocha", "fogueira", "lanterna_cristal", "picareta_ferro", "machado_ferro", "espada_ferro", "armadura_couro_cabeca", "armadura_couro_peito", "armadura_couro_pernas", "armadura_couro_botas"]:
		inventory_data[str(item_id)] = int(_inventory.get(item_id, 0))
	var save_data := {
		"version": PROFILE_VERSION,
		"avatar_id": _selected_avatar_id,
		"seed": _world.world_seed,
		"inventory": inventory_data,
		"craft_grid": _craft_grid_items.duplicate(true),
		"health": _health,
		"food": _food,
		"xp": _xp,
		"level": _level,
		"drops": _serialize_drops(),
		"crops": _serialize_crops(),
		"position": [player_position.x, player_position.y, player_position.z],
	}
	var temporary_path := PROFILE_PATH + ".tmp"
	var temporary_file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if temporary_file == null:
		push_error("ByteCrafter: não foi possível abrir o save temporário do jogador.")
		return
	temporary_file.store_string(JSON.stringify(save_data, "  "))
	temporary_file.flush()
	temporary_file.close()
	var temporary_absolute := ProjectSettings.globalize_path(temporary_path)
	var destination_absolute := ProjectSettings.globalize_path(PROFILE_PATH)
	var backup_absolute := ProjectSettings.globalize_path(PROFILE_PATH + ".bak")
	var had_previous := FileAccess.file_exists(PROFILE_PATH)
	if had_previous:
		if FileAccess.file_exists(PROFILE_PATH + ".bak"):
			DirAccess.remove_absolute(backup_absolute)
		if DirAccess.rename_absolute(destination_absolute, backup_absolute) != OK:
			push_error("ByteCrafter: não foi possível proteger o save anterior do jogador.")
			return
	if DirAccess.rename_absolute(temporary_absolute, destination_absolute) != OK:
		if had_previous:
			DirAccess.rename_absolute(backup_absolute, destination_absolute)
		push_error("ByteCrafter: falha ao finalizar o salvamento do jogador.")
		return
	if FileAccess.file_exists(PROFILE_PATH + ".bak"):
		DirAccess.remove_absolute(backup_absolute)


func _serialize_crops() -> Array:
	var result: Array = []
	for cell_value: Variant in _crops.keys():
		var cell := cell_value as Vector3i
		var crop_data: Dictionary = _crops[cell]
		result.append({"position": [cell.x, cell.y, cell.z], "stage": int(crop_data.get("stage", 0)), "age": float(crop_data.get("age", 0.0))})
	return result


func _start_survival_tick(delta: float) -> void:
	var previous_health := _health
	var previous_food := _food
	_survival_timer += delta
	if _survival_timer >= 50.0:
		_survival_timer = 0.0
		_food = maxf(0.0, _food - 1.0)
	if _food <= 0.0:
		_hunger_tick += delta
		if _hunger_tick >= 9.0:
			_hunger_tick = 0.0
			_health = maxf(0.0, _health - 1.0)
	elif _food >= 18.0 and _health < 20.0:
		_hunger_tick += delta
		if _hunger_tick >= 25.0:
			_hunger_tick = 0.0
			_health = minf(20.0, _health + 1.0)
	if _health != previous_health or _food != previous_food:
		_refresh_hud()
	if _health <= 0.0:
		_begin_player_respawn()


func _refresh_survival(delta: float) -> void:
	if _screen != "game" or _paused:
		return
	_start_survival_tick(delta)
	if _player != null and _player.global_position.y < -12.0:
		_health = maxf(1.0, _health - 3.0)
		_player.global_position = _world.get_spawn_position()
		_player.velocity = Vector3.ZERO
		_refresh_hud()


func _damage_player(amount: float, attacker_name := "Slime") -> void:
	if _screen != "game" or _paused or _player == null or amount <= 0.0:
		return
	if _damage_invulnerability > 0.0 or _death_in_progress:
		return
	_damage_invulnerability = 0.7
	var protected_amount := amount * (1.0 - _armor_damage_reduction())
	_health = maxf(0.0, _health - protected_amount)
	_set_game_status("%s atacou você · -%.1f de vida" % [attacker_name, protected_amount])
	if _health <= 0.0:
		_begin_player_respawn()
	_refresh_hud()


func _begin_player_respawn() -> void:
	if _death_in_progress or _player == null or _world == null:
		return
	_death_in_progress = true
	_mine_held = false
	_attack_cooldown = 0.0
	_player.can_control = false
	_player.velocity = Vector3.ZERO
	_player.play_action("death")
	_set_game_status("Você foi derrotado...")
	_refresh_hud()
	await get_tree().create_timer(PLAYER_DEATH_DURATION).timeout
	if not is_inside_tree() or _player == null or not is_instance_valid(_player):
		_death_in_progress = false
		return
	_health = 12.0
	_food = maxf(8.0, _food)
	_player.global_position = _world.get_spawn_position()
	_player.velocity = Vector3.ZERO
	_player.can_control = true
	_player.set_animation_state("idle")
	_death_in_progress = false
	_set_game_status("Você renasceu no ponto inicial.")
	_refresh_hud()


func _on_window_focus_out() -> void:
	if _screen == "game" and not _paused:
		_toggle_pause()


func _on_ui_button_focus() -> void:
	pass


func _notification_unused() -> void:
	pass


func _save_profile_only() -> void:
	_save_game()


func _build_interaction_helpers() -> void:
	var outline_material := StandardMaterial3D.new()
	outline_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	outline_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	outline_material.albedo_color = Color(0.97, 0.92, 0.63, 0.94)
	outline_material.no_depth_test = true
	outline_material.render_priority = 3
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_LINES)
	surface.set_material(outline_material)
	var corners: Array[Vector3] = [
		Vector3(-0.505, -0.505, -0.505), Vector3(0.505, -0.505, -0.505),
		Vector3(0.505, 0.505, -0.505), Vector3(-0.505, 0.505, -0.505),
		Vector3(-0.505, -0.505, 0.505), Vector3(0.505, -0.505, 0.505),
		Vector3(0.505, 0.505, 0.505), Vector3(-0.505, 0.505, 0.505),
	]
	var edges: Array[Vector2i] = [
		Vector2i(0, 1), Vector2i(1, 2), Vector2i(2, 3), Vector2i(3, 0),
		Vector2i(4, 5), Vector2i(5, 6), Vector2i(6, 7), Vector2i(7, 4),
		Vector2i(0, 4), Vector2i(1, 5), Vector2i(2, 6), Vector2i(3, 7),
	]
	for edge: Vector2i in edges:
		surface.add_vertex(corners[edge.x])
		surface.add_vertex(corners[edge.y])
	_target_outline = MeshInstance3D.new()
	_target_outline.name = "TargetBlockOutline"
	_target_outline.mesh = surface.commit()
	_target_outline.material_override = outline_material
	_target_outline.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_target_outline.visible = false
	add_child(_target_outline)
	var preview_box := BoxMesh.new()
	preview_box.size = Vector3.ONE * 1.003
	_placement_material = StandardMaterial3D.new()
	_placement_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_placement_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_placement_material.albedo_color = Color(0.56, 0.88, 0.43, 0.34)
	_placement_material.render_priority = 1
	_placement_preview = MeshInstance3D.new()
	_placement_preview.name = "PlacementPreview"
	_placement_preview.mesh = preview_box
	_placement_preview.material_override = _placement_material
	_placement_preview.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_placement_preview.visible = false
	add_child(_placement_preview)


func _update_interaction_helpers() -> void:
	if _target_outline == null or _placement_preview == null:
		return
	if _screen != "game" or _paused or _world == null or _player == null or (_craft_panel != null and _craft_panel.visible):
		_target_outline.visible = false
		_placement_preview.visible = false
		return
	var hit := _raycast_target()
	if hit.is_empty():
		_target_outline.visible = false
		_placement_preview.visible = false
		return
	var target_coords := _hit_block_position(hit, false)
	if _world.get_block_at(target_coords) == 0:
		_target_outline.visible = false
		_placement_preview.visible = false
		return
	_target_outline.position = Vector3(target_coords) + Vector3.ONE * 0.5
	_target_outline.visible = true
	var placement_coords := _hit_block_position(hit, true)
	var placement_center := Vector3(placement_coords) + Vector3.ONE * 0.5
	var selected_item: Variant = QUICKBAR_IDS[_selected_slot]
	var selected_block := int(selected_item) if selected_item is int else 0
	var has_item := selected_item is int and int(_inventory.get(selected_item, 0)) > 0
	var overlaps_player := _placement_overlaps_player(placement_coords)
	var can_place := _world.get_block_at(placement_coords) == 0 and has_item and not overlaps_player
	_placement_preview.visible = can_place
	if can_place:
		_placement_preview.position = placement_center
		var color: Color = WORLD_SCRIPT.BLOCK_COLORS.get(selected_block, Color.WHITE)
		_placement_material.albedo_color = Color(color.r, color.g, color.b, 0.34)
