extends PanelContainer

signal slot_activated(slot: PanelContainer, event: InputEventMouseButton)
signal item_dropped(slot: PanelContainer, data: Dictionary)

var slot_kind := "inventory"
var slot_index := -1
var item_id: Variant = null
var quantity := 0

func configure(kind: String, index: int, value: Variant) -> void:
	slot_kind = kind
	slot_index = index
	item_id = value
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_meta("item_id", value)
	set_meta("slot_kind", kind)
	set_meta("slot_index", index)

func set_item(value: Variant, amount: int) -> void:
	item_id = value
	quantity = maxi(0, amount)
	set_meta("item_id", value)
	set_meta("quantity", quantity)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		slot_activated.emit(self, event as InputEventMouseButton)
		accept_event()

func _get_drag_data(_at_position: Vector2) -> Variant:
	if item_id == null or quantity <= 0:
		return null
	var preview := Label.new()
	preview.text = "  %s ×%d  " % [str(item_id), quantity]
	preview.add_theme_color_override("font_color", Color("f4edcf"))
	preview.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	preview.add_theme_constant_override("shadow_offset_x", 2)
	preview.add_theme_constant_override("shadow_offset_y", 2)
	preview.add_theme_font_size_override("font_size", 14)
	set_drag_preview(preview)
	return {"kind": "bytecrafter_item", "item_id": item_id, "quantity": quantity, "source": self, "source_kind": slot_kind, "source_index": slot_index}

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and str(data.get("kind", "")) == "bytecrafter_item"

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if data is Dictionary:
		item_dropped.emit(self, data as Dictionary)
