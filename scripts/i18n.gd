extends RefCounted
class_name I18n
## Localización en los seis idiomas oficiales de la ONU (es, en, fr, ru, ar, zh).

const IDIOMAS := ["es", "en", "fr", "ru", "ar", "zh"]
const ETIQUETAS := {
	"es": "Español",
	"en": "English",
	"fr": "Français",
	"ru": "Русский",
	"ar": "العربية",
	"zh": "简体中文",
}
const RUTA_CONFIG := "user://idioma.cfg"
const LOCALES := {
	"es": preload("res://scripts/idiomas/es.gd"),
	"en": preload("res://scripts/idiomas/en.gd"),
	"fr": preload("res://scripts/idiomas/fr.gd"),
	"ru": preload("res://scripts/idiomas/ru.gd"),
	"ar": preload("res://scripts/idiomas/ar.gd"),
	"zh": preload("res://scripts/idiomas/zh.gd"),
}
const LOCALES_GODOT := {
	"es": "es",
	"en": "en",
	"fr": "fr",
	"ru": "ru",
	"ar": "en",
	"zh": "zh_CN",
}
const HABLANTES := {
	"Pluto": "speaker.pluto",
	"Percy": "speaker.percy",
	"Iris": "speaker.iris",
	"Nora": "speaker.nora",
	"Teo": "speaker.teo",
	"Tierra": "speaker.tierra",
	"Equipo científico": "speaker.equipo_cientifico",
	"Directora de misión": "speaker.directora_mision",
	"Presentadora": "speaker.presentadora",
	"Reservas del refugio": "speaker.reservas_refugio",
}

static var _actual := ""
static var _fuentes_listas := false


static func _asegurar_fuentes() -> void:
	if _fuentes_listas:
		return
	_fuentes_listas = true
	var base: Font = ThemeDB.fallback_font
	if base == null:
		return
	var extras: Array[Font] = []
	for existente: Font in base.fallbacks:
		extras.append(existente)
	for ruta: String in [
		"res://assets/fonts/NotoSansArabic-SemiBold.ttf",
		"res://assets/fonts/NotoSansSC-SemiBold.ttf",
	]:
		if ResourceLoader.exists(ruta):
			var fuente := ResourceLoader.load(ruta) as Font
			if fuente != null and fuente not in extras:
				extras.append(fuente)
	base.fallbacks = extras


static func _normalizar(codigo: String) -> String:
	var limpio := codigo.strip_edges().to_lower().replace("-", "_")
	if limpio.begins_with("zh"):
		return "zh"
	if "_" in limpio:
		limpio = limpio.split("_")[0]
	return limpio if limpio in IDIOMAS else ""


static func _asegurar_inicio() -> void:
	_asegurar_fuentes()
	if not _actual.is_empty():
		return
	var desde_args := ""
	var args := OS.get_cmdline_user_args()
	for i in range(args.size()):
		var arg := args[i]
		if arg.begins_with("--lang="):
			desde_args = _normalizar(arg.trim_prefix("--lang="))
		elif arg == "--lang" and i + 1 < args.size():
			desde_args = _normalizar(args[i + 1])
	if not desde_args.is_empty():
		set_idioma(desde_args, true)
		return
	var cfg := ConfigFile.new()
	if cfg.load(RUTA_CONFIG) == OK:
		var guardado := _normalizar(str(cfg.get_value("idioma", "codigo", "en")))
		if not guardado.is_empty():
			_actual = guardado
			TranslationServer.set_locale(LOCALES_GODOT.get(_actual, _actual))
			return
	_actual = "en"
	TranslationServer.set_locale("en")


static func idioma() -> String:
	_asegurar_inicio()
	return _actual


static func set_idioma(codigo: String, guardar := true) -> void:
	_asegurar_fuentes()
	var valido := _normalizar(codigo)
	if valido.is_empty():
		valido = "en"
	_actual = valido
	TranslationServer.set_locale(LOCALES_GODOT.get(valido, valido))
	if guardar:
		var cfg := ConfigFile.new()
		cfg.set_value("idioma", "codigo", valido)
		cfg.save(RUTA_CONFIG)


static func es_rtl() -> bool:
	return idioma() == "ar"


static func etiqueta(codigo: String) -> String:
	return ETIQUETAS.get(codigo, codigo)


static func t(clave: String, defecto := "") -> String:
	_asegurar_inicio()
	var tabla: Variant = LOCALES.get(_actual, LOCALES["es"])
	if tabla != null and tabla.TEXTOS.has(clave):
		return tabla.TEXTOS[clave]
	var base: Variant = LOCALES["es"]
	if base != null and base.TEXTOS.has(clave):
		return base.TEXTOS[clave]
	return defecto if not defecto.is_empty() else clave


static func tf(clave: String, args: Array) -> String:
	return t(clave) % args


static func hablante(nombre: String) -> String:
	var clave: String = HABLANTES.get(nombre, "")
	return t(clave, nombre) if not clave.is_empty() else nombre


static func encabezado_hablante(nombre: String) -> String:
	return tf("speaker.fmt", [hablante(nombre)])


static func cultivo(id: String, minuscula := false) -> String:
	var prefijo := "crop.low." if minuscula else "crop.cap."
	return t(prefijo + id, id.capitalize())


static func clima(nivel: String, titulo := false) -> String:
	var prefijo := "climate.cap." if titulo else "climate.low."
	return t(prefijo + nivel, nivel)
