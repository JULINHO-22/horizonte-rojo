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
	_salida_plano = rotulo(self, "M · Volver al recorrido", Rect2(25, 677, 230, 31), 18, PAPEL)
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
	lectura.position = Vector2(868, 145)
	_informe.add_child(lectura)
	var cambios := "Energía  %d → %d    Aire  %d → %d\nAgua  %d → %d    Comida  %d → %d" % [
		antes.energia, despues.energia, antes.oxigeno, despues.oxigeno,
		antes.agua, despues.agua, antes.alimento, despues.alimento]
	lectura.decir("Reservas del refugio", cambios + "\n" + causa)
	for opcion in [{"titulo": "Alerta DONKI", "url": donki, "x": 872}, {"titulo": "Curiosity en Marte", "url": curiosity, "x": 1015}]:
		var enlace := LinkButton.new()
		enlace.text = opcion.titulo
		enlace.uri = opcion.url
		enlace.position = Vector2(opcion.x, 357)
		enlace.add_theme_color_override("font_color", PAPEL)
		enlace.add_theme_color_override("font_outline_color", Color("#101b23"))
		enlace.add_theme_constant_override("outline_size", 5)
		_informe.add_child(enlace)

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
