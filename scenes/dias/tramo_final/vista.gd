extends Control
## Presentación compartida. Los botones invocan las mismas acciones que el teclado.
const FONDO := Color("#101e26")
const PAPEL := Color("#fff0d9")
const MENTA := Color("#9ce6d8")
const AMBAR := Color("#f5bb75")

const PanelControl := preload("res://scripts/panel_control.gd")
const AccionEscena := preload("res://scripts/accion_escena.gd")
var _dialogo: Control
var _ventana: PanelControl
var _salida_plano: Label
var _informe: Control

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	_dialogo = preload("res://scripts/dialogo_escena.gd").new()
	_dialogo.position = Vector2(48, 141)
	add_child(_dialogo)
	_salida_plano = rotulo(self, I18n.t("vista.volver"), Rect2(25, 677, 230, 31), 18, PAPEL)
	_salida_plano.hide()

func mostrar_plano(activo: bool) -> void:
	_dialogo.visible = not activo
	_salida_plano.visible = activo

func decir(quien: String, frase: String, origen := Vector2(48, 141)) -> void:
	_dialogo.position = origen
	_dialogo.decir(quien, frase)

func mostrar_lecturas(registro: Dictionary, causa: String, donki: String, curiosity: String) -> void:
	var antes: Dictionary = registro.antes
	var despues: Dictionary = registro.despues
	_informe = Control.new()
	_informe.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_informe)
	var lectura := preload("res://scripts/dialogo_escena.gd").new()
	lectura.position = Vector2(868, 128)
	_informe.add_child(lectura)
	lectura.frase.add_theme_constant_override("line_spacing", 1)
	var cambios := I18n.tf("vista.cambios", [
		antes.energia, despues.energia, antes.oxigeno, despues.oxigeno,
		antes.agua, despues.agua, antes.alimento, despues.alimento])
	lectura.decir("Reservas del refugio", cambios + "\n" + causa)
	var enlaces: Array[LinkButton] = []
	for opcion in [{"titulo": I18n.t("vista.link.donki"), "url": donki}, {"titulo": I18n.t("vista.link.curiosity"), "url": curiosity}]:
		var enlace := LinkButton.new()
		enlace.text = opcion.titulo
		enlace.uri = opcion.url
		enlace.position = Vector2(872, 357)
		enlace.add_theme_color_override("font_color", PAPEL)
		enlace.add_theme_color_override("font_outline_color", Color("#101b23"))
		enlace.add_theme_constant_override("outline_size", 5)
		_informe.add_child(enlace)
		enlaces.append(enlace)
	_ubicar_enlaces_informe(lectura, enlaces)
	_ubicar_enlaces_informe.call_deferred(lectura, enlaces)

func _ubicar_enlaces_informe(lectura: Variant, enlaces: Array[LinkButton]) -> void:
	if not is_instance_valid(lectura):
		return
	var frase: Label = lectura.frase
	var alto_frase := maxf(frase.size.y, frase.get_minimum_size().y)
	var y_enlaces := maxf(357.0, lectura.position.y + frase.position.y + alto_frase + 12.0)
	var x := 872.0
	for enlace in enlaces:
		if not is_instance_valid(enlace):
			continue
		var ancho := maxf(enlace.size.x, enlace.get_minimum_size().x)
		if x > 872.0 and x + ancho > 1252.0:
			x = 872.0
			y_enlaces += 28.0
		enlace.position = Vector2(x, y_enlaces)
		x += maxf(143.0, ancho + 24.0)

func cerrar_lecturas() -> void:
	if is_instance_valid(_informe):
		_informe.hide()
		_informe.queue_free()
		_informe = null

func abierta() -> bool:
	return is_instance_valid(_ventana)

func abrir_control(sol: int, objetivo: String, opciones := false) -> Control:
	cerrar()
	_ventana = PanelControl.new()
	_ventana.configurar(sol, false, 120.0 if opciones else 0.0)
	_ventana.cerrar_solicitado.connect(cerrar)
	add_child(_ventana)
	_ventana.mostrar_tarea(objetivo)
	return _ventana

func cerrar() -> void:
	if is_instance_valid(_ventana):
		remove_child(_ventana)
		_ventana.queue_free()
		_ventana = null

static func placa(padre: Control, rect: Rect2) -> Panel:
	var panel := Panel.new()
	panel.mouse_filter = MOUSE_FILTER_IGNORE
	panel.position = rect.position
	panel.size = rect.size
	panel.add_theme_stylebox_override("panel", _estilo(FONDO, Color("#47636a")))
	padre.add_child(panel)
	return panel

static func rotulo(padre: Control, texto: String, rect: Rect2, fuente: int, color: Color) -> Label:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.position = rect.position
	etiqueta.size = rect.size
	etiqueta.mouse_filter = MOUSE_FILTER_IGNORE
	etiqueta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	etiqueta.add_theme_font_size_override("font_size", fuente)
	etiqueta.add_theme_color_override("font_color", color)
	padre.add_child(etiqueta)
	return etiqueta

static func boton(padre: Control, texto: String, rect: Rect2, accion: Callable) -> Button:
	var b := Button.new()
	b.text = texto
	b.position = rect.position
	b.size = rect.size
	b.add_theme_font_size_override("font_size", 18)
	AccionEscena.aplicar(b)
	if accion.is_valid():
		b.pressed.connect(accion)
	padre.add_child(b)
	return b

static func _estilo(fondo: Color, borde: Color) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = fondo
	estilo.border_color = borde
	estilo.set_border_width_all(1)
	estilo.set_corner_radius_all(8)
	return estilo
