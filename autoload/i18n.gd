extends Node

signal locale_changed(locale: String)

const CATALOG_PATHS := {
	"pt-BR": "res://localization/pt-BR.json",
	"en": "res://localization/en.json",
	"zh-CN": "res://localization/zh-CN.json",
}

var _catalogs: Dictionary = {}
var _locale := "pt-BR"


func _ready() -> void:
	for locale: String in CATALOG_PATHS:
		_catalogs[locale] = _load_catalog(str(CATALOG_PATHS[locale]))
	# ByteCrafter is a Portuguese-only prototype; ignore prior template locale preferences.
	_locale = "pt-BR" if _catalogs.has("pt-BR") else "en"


static func detect_locale(_os_locale: String) -> String:
	return "pt-BR"


static func resolve_locale(_saved: String, _os_locale: String) -> String:
	return "pt-BR"


func _load_catalog(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("I18n: missing catalog " + path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		push_error("I18n: invalid catalog " + path)
		return {}
	return parsed


func text(key: String, replacements: Dictionary = {}) -> String:
	var active: Dictionary = _catalogs.get(_locale, {})
	var result := str(active.get(key, key))
	for token: Variant in replacements:
		result = result.replace("{%s}" % str(token), str(replacements[token]))
	return result


func t(key: String, replacements: Dictionary = {}) -> String:
	return text(key, replacements)


func get_locale() -> String:
	return _locale


func set_locale(locale: String) -> void:
	if locale != "pt-BR" or not _catalogs.has("pt-BR"):
		return
	if _locale != "pt-BR":
		_locale = "pt-BR"
		locale_changed.emit(_locale)


func toggle_locale() -> void:
	set_locale("pt-BR")


func catalog_keys(locale: String) -> Array:
	return (_catalogs.get(locale, {}) as Dictionary).keys()
