extends Control
## Tarjeta discreta de divulgación científica ("¿Sabías que...?") con enlace oficial clicable.

const AccionEscena := preload("res://scripts/accion_escena.gd")
const ANCHO := 472.0
const DURACION := 20.0
const TEMAS := {
	"atmosfera": "https://science.nasa.gov/mars/atmosphere/",
	"oxigeno": "https://science.nasa.gov/mission/mars-2020-perseverance/moxie/",
	"hielo": "https://science.nasa.gov/resource/swim-map-shows-subsurface-water-ice-on-mars/",
	"agua": "https://www.nasa.gov/missions/station/iss-research/nasa-achieves-water-recovery-milestone-on-international-space-station/",
	"cultivos": "https://science.nasa.gov/mission/veggie/",
	"polvo": "https://science.nasa.gov/resource/nasas-insight-waits-out-dust-storm/",
	"soporte": "https://www.nasa.gov/pdf/473486main_iss_eclss.pdf",
	"blindaje": "https://www.nasa.gov/reference/space-radiation/",
	"tormenta_solar": "https://visualization.osdr.nasa.gov/radlab/gui/knowledgebase/MSL-RAD-Surface",
}

static var _vistos: Dictionary = {}

var panel: PanelContainer
var encabezado: Label
var cuerpo: Label
var enlace: LinkButton
var cerrar: Button

var _tema := ""
var _restante := 0.0
var _ocultando := false
var _animacion: Tween
var _zonas_evitar: Array[Rect2] = []


static func reiniciar_vistos() -> void:
	_vistos.clear()


static func ya_visto(tema: String) -> bool:
	return _vistos.has(tema)


func _ready() -> void:
	size = Vector2(1280, 720)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 9

	panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(ANCHO, 0)
	panel.size = Vector2(ANCHO, 0)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = Color("#121c26eb")
	fondo.border_color = Color("#6adbd0b0")
	fondo.set_border_width_all(1)
	fondo.border_width_left = 4
	fondo.set_corner_radius_all(8)
	fondo.shadow_color = Color("#080d12a8")
	fondo.shadow_size = 16
	panel.add_theme_stylebox_override("panel", fondo)
	add_child(panel)

	var margen := MarginContainer.new()
	margen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margen.add_theme_constant_override("margin_left", 15)
	margen.add_theme_constant_override("margin_right", 13)
	margen.add_theme_constant_override("margin_top", 10)
	margen.add_theme_constant_override("margin_bottom", 11)
	panel.add_child(margen)

	var columna := VBoxContainer.new()
	columna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	columna.add_theme_constant_override("separation", 5)
	margen.add_child(columna)

	var cabecera := HBoxContainer.new()
	cabecera.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cabecera.add_theme_constant_override("separation", 8)
	columna.add_child(cabecera)

	encabezado = Label.new()
	encabezado.custom_minimum_size = Vector2(ANCHO - 64.0, 0)
	encabezado.size.x = ANCHO - 64.0
	encabezado.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	encabezado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	encabezado.mouse_filter = Control.MOUSE_FILTER_IGNORE
	encabezado.add_theme_font_size_override("font_size", 14)
	encabezado.add_theme_color_override("font_color", Color("#7bece0"))
	cabecera.add_child(encabezado)

	cerrar = Button.new()
	cerrar.text = "×"
	cerrar.flat = true
	cerrar.focus_mode = Control.FOCUS_NONE
	cerrar.custom_minimum_size = Vector2(26, 24)
	cerrar.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	cerrar.add_theme_font_size_override("font_size", 17)
	cerrar.add_theme_color_override("font_color", Color("#b8c8d4"))
	cerrar.add_theme_color_override("font_hover_color", Color("#ffffff"))
	AccionEscena.aplicar(cerrar)
	cerrar.pressed.connect(ocultar.bind(true))
	cabecera.add_child(cerrar)

	cuerpo = Label.new()
	cuerpo.custom_minimum_size = Vector2(ANCHO - 30.0, 0)
	cuerpo.size.x = ANCHO - 30.0
	cuerpo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cuerpo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cuerpo.add_theme_font_size_override("font_size", 15)
	cuerpo.add_theme_color_override("font_color", Color("#f4ede0"))
	cuerpo.add_theme_constant_override("line_spacing", 2)
	columna.add_child(cuerpo)

	enlace = LinkButton.new()
	enlace.underline = LinkButton.UNDERLINE_MODE_ALWAYS
	enlace.focus_mode = Control.FOCUS_NONE
	enlace.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	enlace.add_theme_font_size_override("font_size", 14)
	enlace.add_theme_color_override("font_color", Color("#ffcf87"))
	enlace.add_theme_color_override("font_hover_color", Color("#fff2cc"))
	enlace.add_theme_color_override("font_focus_color", Color("#fff2cc"))
	columna.add_child(enlace)

	hide()


func _process(delta: float) -> void:
	if not visible or _ocultando:
		return
	var pos := get_viewport().get_mouse_position()
	if is_instance_valid(panel) and panel.get_global_rect().has_point(pos):
		return
	_restante -= delta
	if _restante <= 0.0:
		ocultar(true)


func mostrar(tema: String, forzar := false) -> bool:
	if not TEMAS.has(tema):
		return false
	if not forzar and _vistos.has(tema):
		return false
	_vistos[tema] = true
	_tema = tema
	_restante = DURACION
	_ocultando = false
	_aplicar_textos()
	if is_instance_valid(_animacion):
		_animacion.kill()
	modulate.a = 0.0
	show()
	_reubicar()
	_reubicar.call_deferred()
	_animacion = create_tween()
	_animacion.tween_property(self, "modulate:a", 1.0, 0.22)
	return true


func ocultar(suave := false) -> void:
	if not visible:
		return
	if is_instance_valid(_animacion):
		_animacion.kill()
	if not suave:
		_ocultando = true
		hide()
		return
	_ocultando = true
	_animacion = create_tween()
	_animacion.tween_property(self, "modulate:a", 0.0, 0.25)
	_animacion.tween_callback(_finalizar_oculto)


func _finalizar_oculto() -> void:
	if _ocultando:
		hide()


func _aplicar_textos() -> void:
	if _tema.is_empty():
		return
	var url: String = TEMAS[_tema]
	encabezado.text = "%s · %s" % [I18n.t("ciencia.prefijo"), I18n.t("ciencia.%s.tit" % _tema)]
	cuerpo.text = I18n.t("ciencia.%s.txt" % _tema)
	enlace.text = I18n.t("ciencia.%s.fuente" % _tema)
	enlace.uri = url
	enlace.tooltip_text = url
	cerrar.tooltip_text = I18n.t("ciencia.cerrar_tip")


func evitar(zonas: Array[Rect2]) -> void:
	_zonas_evitar = zonas
	if visible and not _ocultando:
		_reubicar()


func _reubicar() -> void:
	if not is_instance_valid(panel):
		return
	encabezado.size = Vector2(ANCHO - 64.0, 0)
	cuerpo.size = Vector2(ANCHO - 30.0, 0)
	panel.size = Vector2(ANCHO, 0)
	var alto := clampf(panel.get_minimum_size().y, 70.0, 260.0)
	var ancho := clampf(panel.get_minimum_size().x, ANCHO, 540.0)
	panel.size = Vector2(ancho, alto)
	var candidatos := [
		Vector2(1256.0 - ancho, 698.0 - alto),
		Vector2(24.0, 644.0 - alto),
		Vector2(1256.0 - ancho, 102.0),
		Vector2(24.0, 148.0),
	]
	for pos: Vector2 in candidatos:
		var rect := Rect2(pos, Vector2(ancho, alto)).grow(6.0)
		var choca := false
		for zona: Rect2 in _zonas_evitar:
			if zona.size.x > 0.0 and zona.size.y > 0.0 and rect.intersects(zona):
				choca = true
				break
		if not choca:
			panel.position = pos
			return
	panel.position = candidatos[0]
