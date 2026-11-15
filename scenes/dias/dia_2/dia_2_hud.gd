extends Control

const DialogoEscena := preload("res://scripts/dialogo_escena.gd")

const ANCHO_GUIA := 460.0
const TINTA := Color("#211716")
const BORDE_CIAN := Color("#976d53")
const PAPEL := Color("#fff2db")
const CIAN := Color("#8ff1e7")
const MUTED := Color("#a0b5be")
const ORO := Color("#ffca63")
const AZUL := Color("#75baff")
const ROJO := Color("#ff8274")
const VERDE := Color("#8eedb0")

var aviso_pluto: Control
var guia: Control
var titulo: Label
var detalle: Label
var marca: Label
var accion: Button
var alternativa: Button
var mapa: Button
var pausa: Button
var modal: ColorRect
var modal_titulo: Label
var modal_detalle: Label
var confirmar: Button
var solar_alerta: Label
var pasos: Label
var recordatorio: Label
var logro: Label
var animacion_logro: Tween

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_texto(self, Rect2(24, 18, 250, 28), "SOL 2 · TORMENTA DE POLVO", 19, PAPEL)
	solar_alerta = _texto(self, Rect2(24, 45, 280, 22), "CARGA SOLAR DETENIDA", 14, ROJO)
	pasos = _texto(self, Rect2(24, 76, 820, 24), "", 16, PAPEL)
	recordatorio = _texto(self, Rect2(24, 106, 825, 28), "", 17, ORO)
	recordatorio.add_theme_color_override("font_outline_color", TINTA)
	recordatorio.add_theme_constant_override("outline_size", 6)

	# Botones de mapa y pausa apilados a la derecha (x=1140 a x=1264)
	mapa = _boton(self, Rect2(1140, 14, 124, 36), "M · Plano")
	pausa = _boton(self, Rect2(1140, 56, 124, 36), "Esc · Pausa")

	# Indicador de navegación en el suelo / objetivo
	marca = _texto(self, Rect2(0, 0, 70, 44), "◆", 28, CIAN)
	marca.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	marca.add_theme_color_override("font_outline_color", TINTA)
	marca.add_theme_constant_override("outline_size", 8)

	aviso_pluto = DialogoEscena.new()
	add_child(aviso_pluto)

	# Panel guía de interacción contextual
	guia = Control.new()
	guia.position = Vector2(24, 560)
	guia.size = Vector2(ANCHO_GUIA, 120)
	guia.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(guia)
	titulo = _texto(guia, Rect2(18, 10, ANCHO_GUIA - 36, 28), "", 20, CIAN)
	detalle = _texto(guia, Rect2(18, 40, ANCHO_GUIA - 36, 68), "", 15, PAPEL)
	detalle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for etiqueta: Label in [titulo, detalle, solar_alerta, pasos]:
		etiqueta.add_theme_color_override("font_outline_color", TINTA)
		etiqueta.add_theme_constant_override("outline_size", 7)

	accion = _boton(guia, Rect2(18, 114, ANCHO_GUIA - 36, 40), "")
	alternativa = _boton(guia, Rect2(18, 162, ANCHO_GUIA - 36, 40), "")
	accion.add_theme_font_size_override("font_size", 16)
	alternativa.add_theme_font_size_override("font_size", 16)

	# Pantalla modal para inicio, pausas y desenlace
	logro = _texto(self, Rect2(340, 200, 650, 38), "", 23, VERDE)
	logro.add_theme_color_override("font_outline_color", TINTA)
	logro.add_theme_constant_override("outline_size", 12)
	logro.hide()

	modal = ColorRect.new()
	modal.size = Vector2(1280, 720)
	modal.color = Color("#1b110fdf")
	add_child(modal)
	var caja_modal := Control.new()
	caja_modal.position = Vector2(260, 138)
	modal.add_child(caja_modal)
	modal_titulo = _texto(caja_modal, Rect2(36, 28, 688, 44), "", 30, PAPEL)
	modal_detalle = _texto(caja_modal, Rect2(36, 90, 688, 252), "", 18, MUTED)
	modal_detalle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	confirmar = _boton(caja_modal, Rect2(36, 368, 688, 48), "")
	confirmar.add_theme_font_size_override("font_size", 18)

func actualizar(lugar: String, mensaje: String, principal: String, otra: String,
		actuar: bool, elegir: bool, interior: bool, plano: bool, punto: Vector2, nora: Vector2) -> void:
	titulo.text = lugar
	detalle.text = mensaje
	accion.text = "E · " + principal
	accion.disabled = not actuar
	accion.visible = actuar
	alternativa.disabled = not elegir
	alternativa.visible = not otra.is_empty() and elegir
	alternativa.text = "Q · " + otra

	mapa.visible = interior
	mapa.text = "M · Cerrar plano" if plano else "M · Plano"

	var visible_punto := punto.clamp(Vector2(60, 120), Vector2(1220, 660))
	_ubicar_guia(visible_punto, nora, interior)

	# Indicador de navegación con pulsación
	var diferencia := punto - visible_punto
	marca.position = visible_punto - Vector2(35, 22)
	var pulso: float = 0.72 + 0.28 * sin(Time.get_ticks_msec() * 0.007)
	marca.modulate = Color(1.0, 1.0, 1.0, pulso)
	if diferencia.length() > 5:
		if absf(diferencia.x) >= absf(diferencia.y):
			marca.text = "←" if diferencia.x < 0 else "→"
		else:
			marca.text = "↑" if diferencia.y < 0 else "↓"
	else:
		marca.text = "◆"

func aviso_de_pluto(visible_en_escena: bool, posicion: Vector2, texto := "") -> void:
	if visible_en_escena:
		aviso_pluto.position = Vector2(clampf(posicion.x - 170.0, 42.0, 872.0), clampf(posicion.y - 170.0, 118.0, 471.0))
		var mensaje := texto if not texto.is_empty() else "Acércate a la consola. Tenemos que decidir qué hacer con la tormenta."
		aviso_pluto.decir("Pluto", mensaje)
	else:
		aviso_pluto.hide()

func _ubicar_guia(punto: Vector2, nora: Vector2, interior: bool) -> void:
	var opciones := int(accion.visible) + int(alternativa.visible)
	var alto_base := 116.0
	guia.size.y = alto_base + opciones * 48.0
	alternativa.position.y = 162.0 if accion.visible else 114.0

	if not interior:
		# En el exterior, anclar en la esquina contraria a Nora para no tapar los paneles ni a los astronautas
		if nora.x < 580.0:
			guia.position = Vector2(1280.0 - ANCHO_GUIA - 24.0, 700.0 - guia.size.y)
		else:
			guia.position = Vector2(24.0, 700.0 - guia.size.y)
		return

	if opciones == 0:
		guia.position = Vector2(24, 570)
		if punto.x < 500 and punto.y > 550:
			guia.position.x = 780
		return

	# En el interior: ubicación inteligente que no tape a Nora ni la consola
	var x := punto.x + 52.0
	if x + ANCHO_GUIA > 1250.0:
		x = punto.x - 52.0 - ANCHO_GUIA
	if x < 24.0:
		x = 24.0

	var y := punto.y - 48.0
	if nora.x >= x - 30.0 and nora.x <= x + ANCHO_GUIA + 30.0:
		if nora.y > 360.0:
			y = maxf(110.0, nora.y - guia.size.y - 30.0)
		else:
			y = minf(700.0 - guia.size.y, nora.y + 40.0)

	guia.position = Vector2(clampf(x, 24.0, 1256.0 - ANCHO_GUIA), clampf(y, 184.0, 705.0 - guia.size.y))

func presentar(encabezado: String, mensaje: String, avance: String) -> void:
	logro.hide()
	modal_titulo.text = encabezado
	modal_detalle.text = mensaje
	confirmar.text = "E · " + avance
	confirmar.visible = not avance.is_empty()
	modal.show()

func celebrar(mensaje: String) -> void:
	if is_instance_valid(animacion_logro):
		animacion_logro.kill()
	logro.text = mensaje
	logro.modulate.a = 1.0
	logro.show()
	animacion_logro = create_tween()
	animacion_logro.tween_interval(2.5)
	animacion_logro.tween_property(logro, "modulate:a", 0.0, 0.6)
	animacion_logro.tween_callback(logro.hide)

func _estilo(color: Color, borde: Color, grosor: int) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = color
	estilo.border_color = borde
	estilo.set_border_width_all(grosor)
	estilo.corner_radius_top_left = 3
	estilo.corner_radius_top_right = 3
	estilo.corner_radius_bottom_left = 3
	estilo.corner_radius_bottom_right = 3
	return estilo

func _panel(padre: Control, rect: Rect2, color: Color, borde: Color) -> Panel:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _estilo(color, borde, 2))
	padre.add_child(panel)
	return panel

func _texto(padre: Control, rect: Rect2, texto: String, tamano: int, color: Color) -> Label:
	var etiqueta := Label.new()
	etiqueta.position = rect.position
	etiqueta.size = rect.size
	etiqueta.text = texto
	etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	etiqueta.add_theme_font_size_override("font_size", tamano)
	etiqueta.add_theme_color_override("font_color", color)
	padre.add_child(etiqueta)
	return etiqueta

func _boton(padre: Control, rect: Rect2, texto: String) -> Button:
	var boton := Button.new()
	boton.position = rect.position
	boton.size = rect.size
	boton.focus_mode = Control.FOCUS_NONE
	boton.text = texto
	boton.add_theme_font_size_override("font_size", 15)
	boton.add_theme_color_override("font_color", PAPEL)
	boton.add_theme_color_override("font_disabled_color", MUTED)
	boton.add_theme_stylebox_override("normal", _estilo(Color("#16323c"), CIAN, 1))
	boton.add_theme_stylebox_override("hover", _estilo(Color("#245361"), CIAN, 2))
	boton.add_theme_stylebox_override("pressed", _estilo(Color("#10222a"), PAPEL, 2))
	boton.add_theme_stylebox_override("disabled", _estilo(Color("#14222a"), Color("#3b4f57"), 1))
	padre.add_child(boton)
	return boton

func ruta_del_dia(estado: Dictionary, salida_pendiente: bool, descansando: bool) -> void:
	var decidido: bool = salida_pendiente or not estado.decisiones.is_empty()
	var protegido: bool = "dia_2_reparar" in estado.decisiones
	var dentro: bool = "dia_2_resguardarse" in estado.decisiones
	pasos.text = "%s PLAN     →     %s AIRE     →     %s EQUIPOS     →     %s DESCANSO" % [
		"✓" if decidido else "1", "✓" if estado.aire_asegurado else "2",
		"✓" if protegido else ("–" if dentro else "3"), "4" if not descansando else "→"]
	if estado.reservas.alimento <= 1 and estado.aire_asegurado:
		recordatorio.text = "Hace falta comida · visita Plantas antes de dormir."
		recordatorio.add_theme_color_override("font_color", ORO)
	elif estado.aire_asegurado:
		recordatorio.text = "Aire seguro · ya puedes explorar con calma."
		recordatorio.add_theme_color_override("font_color", VERDE)
	else:
		recordatorio.text = "Primero el aire · busca los tanques verdes." if estado.reservas.oxigeno > 3 else "Queda poco aire · sigue la marca hasta los tanques verdes."
		recordatorio.add_theme_color_override("font_color", ORO if estado.reservas.oxigeno > 3 else ROJO)
