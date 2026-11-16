extends Control
## Bitácora de tareas de la computadora del refugio.
signal cerrar_solicitado
signal ruta_confirmada
const AccionEscena := preload("res://scripts/accion_escena.gd")

const TITULO := Color("#fff0d9")
const TEXTO := Color("#e6cfb5")
const MENTA := Color("#f0b879")
const ANCHO := 944.0
var _sol: int
var _regreso := false
var _extension := 0.0

func configurar(sol: int, regreso: bool, extension := 0.0) -> void:
	_sol = sol
	_regreso = regreso
	_extension = extension

func _ready() -> void:
	size = Vector2(ANCHO, 312.0 + _extension)
	position = (get_viewport_rect().size - size) * 0.5
	var velo := ColorRect.new()
	velo.color = Color("#100b09ed")
	velo.position = -position
	velo.size = get_viewport_rect().size
	add_child(velo)
	_etiqueta(I18n.tf("control.encabezado", [_sol]), Rect2(34, 26, 690, 30), 17, MENTA)
	_etiqueta(I18n.t("control.titulo"), Rect2(32, 62, 685, 60), 42, TITULO)
	var cerrar := _boton(I18n.t("ui.cerrar_esc"), Rect2(771, 26, 140, 43), cerrar_solicitado.emit)
	cerrar.grab_focus()
	if _regreso:
		mostrar_tarea(I18n.t("control.regreso_desc"))
		_boton(I18n.t("control.confirmar_ruta"), Rect2(34, 234, 262, 44), ruta_confirmada.emit)
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.16)

func mostrar_tarea(tarea: String) -> void:
	_etiqueta(tarea, Rect2(34, 137, 870, 86), 24, TEXTO)

func accion(texto: String, rect: Rect2, ejecutar: Callable) -> Button:
	return _boton(texto, rect, ejecutar)

func _etiqueta(texto: String, rect: Rect2, puntos: int, color: Color,
		alineacion := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.horizontal_alignment = alineacion
	etiqueta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	etiqueta.add_theme_font_size_override("font_size", puntos)
	etiqueta.add_theme_color_override("font_color", color)
	etiqueta.position = rect.position
	etiqueta.size = rect.size
	add_child(etiqueta)

func _boton(texto: String, rect: Rect2, accion: Callable) -> Button:
	var boton := Button.new()
	boton.text = texto
	boton.add_theme_font_size_override("font_size", 17)
	AccionEscena.aplicar(boton)
	boton.position = rect.position
	boton.size = rect.size
	boton.pressed.connect(accion)
	add_child(boton)
	return boton
