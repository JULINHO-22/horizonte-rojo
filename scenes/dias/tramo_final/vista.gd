extends Control
## Presentación compartida. Los botones invocan las mismas acciones que el teclado.
const FONDO := Color("#101e26")
const PAPEL := Color("#fff0d9")
const MENTA := Color("#9ce6d8")
const AMBAR := Color("#f5bb75")

var _titulo: Label
var _objetivo: Label
var _reservas: Label
var _dialogo: Control
var _accion: Button
var _ventana: Panel

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	placa(self, Rect2(22, 18, 1236, 88))
	_titulo = rotulo(self, "", Rect2(46, 30, 750, 31), 25, PAPEL)
	_objetivo = rotulo(self, "", Rect2(46, 66, 1168, 30), 18, MENTA)
	_reservas = rotulo(self, "", Rect2(700, 34, 534, 28), 18, PAPEL)
	_reservas.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_dialogo = preload("res://scripts/dialogo_escena.gd").new()
	_dialogo.position = Vector2(48, 141)
	add_child(_dialogo)
	_accion = boton(self, "", Rect2(432, 646, 416, 49), Callable())
	_accion.focus_mode = FOCUS_NONE
	_accion.hide()

func conectar_accion(accion: Callable) -> void:
	_accion.pressed.connect(accion)

func actualizar(titulo: String, objetivo: String, r: Dictionary) -> void:
	_titulo.text = titulo
	_objetivo.text = objetivo
	_reservas.text = "Energía %d    Agua %d    Oxígeno %d    Comida %d" % [r.energia, r.agua, r.oxigeno, r.alimento]

func instruccion(texto: String) -> void:
	_accion.text = "E · " + texto
	_accion.visible = not texto.is_empty() and not abierta()

func decir(quien: String, frase: String) -> void:
	_dialogo.decir(quien, frase)

func abierta() -> bool:
	return is_instance_valid(_ventana)

func abrir(titulo: String, frase: String, alto := 478.0) -> Panel:
	cerrar()
	var velo := ColorRect.new()
	velo.name = "Velo"
	velo.color = Color(0.01, 0.03, 0.06, 0.68)
	velo.size = Vector2(1280, 720)
	add_child(velo)
	_ventana = placa(velo, Rect2(188, (720 - alto) * 0.5, 904, alto))
	rotulo(_ventana, titulo, Rect2(32, 25, 827, 45), 31, PAPEL)
	rotulo(_ventana, frase, Rect2(32, 79, 827, 65), 20, MENTA)
	_accion.hide()
	return _ventana

func cerrar() -> void:
	if is_instance_valid(_ventana):
		var velo := _ventana.get_parent()
		remove_child(velo)
		velo.queue_free()
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
	b.add_theme_color_override("font_color", PAPEL)
	b.add_theme_stylebox_override("normal", _estilo(Color("#233740"), Color("#5d8085")))
	b.add_theme_stylebox_override("hover", _estilo(Color("#304e52"), MENTA))
	b.add_theme_stylebox_override("pressed", _estilo(Color("#19333a"), MENTA))
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
