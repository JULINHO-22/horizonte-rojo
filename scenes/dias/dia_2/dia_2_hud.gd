extends Control

const Modelo := preload("res://scripts/mecanicas/recursos_mision.gd")
const DialogoEscena := preload("res://scripts/dialogo_escena.gd")

const ANCHO_GUIA := 460.0
const TINTA := Color("#0c1822")
const FONDO_PANEL := Color("#0f1c26f0")
const BORDE_CIAN := Color("#3c7880")
const PAPEL := Color("#fff2db")
const CIAN := Color("#8ff1e7")
const MUTED := Color("#a0b5be")
const ORO := Color("#ffca63")
const AZUL := Color("#75baff")
const ROJO := Color("#ff8274")
const VERDE := Color("#8eedb0")

const RECURSOS := {
	"energia": ["ENERGÃA", ORO],
	"agua": ["AGUA", AZUL],
	"oxigeno": ["OXÃGENO", CIAN],
	"alimento": ["COMIDA", ROJO],
}

var medidores := {}
var aviso_pluto: Control
var guia: Panel
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

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Barra superior de telemetrÃ­a (x=16 a x=866)
	var barra_top := _panel(self, Rect2(16, 14, 850, 78), TINTA, BORDE_CIAN)
	_texto(barra_top, Rect2(18, 10, 180, 28), "DÃA 2 Â· SOL 2", 21, PAPEL)

	solar_alerta = _texto(barra_top, Rect2(18, 42, 210, 22), "TORMENTA Â· SOLAR: PAUSADO", 12, ROJO)

	var x := 232
	for id: String in RECURSOS:
		var ficha: Array = RECURSOS[id]
		_texto(barra_top, Rect2(x, 12, 140, 18), ficha[0], 12, MUTED)
		var valor := _texto(barra_top, Rect2(x, 30, 140, 26), "", 18, ficha[1])
		var barra := ProgressBar.new()
		barra.show_percentage = false
		barra.max_value = Modelo.LIMITES[id]
		barra.position = Vector2(x, 58)
		barra.size = Vector2(124, 5)
		barra.add_theme_stylebox_override("background", _estilo(Color("#1d313d"), Color.TRANSPARENT, 0))
		barra.add_theme_stylebox_override("fill", _estilo(ficha[1], Color.TRANSPARENT, 0))
		barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
		barra_top.add_child(barra)
		medidores[id] = [valor, barra]
		x += 152

	# Botones de mapa y pausa apilados a la derecha (x=1140 a x=1264)
	mapa = _boton(self, Rect2(1140, 14, 124, 36), "M Â· Plano")
	pausa = _boton(self, Rect2(1140, 56, 124, 36), "Esc Â· Pausa")

	# Indicador de navegaciÃ³n en el suelo / objetivo
	marca = _texto(self, Rect2(0, 0, 70, 44), "â—†", 28, CIAN)
	marca.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	marca.add_theme_color_override("font_outline_color", TINTA)
	marca.add_theme_constant_override("outline_size", 8)

	aviso_pluto = DialogoEscena.new()
	add_child(aviso_pluto)

	# Panel guÃ­a de interacciÃ³n contextual
	guia = _panel(self, Rect2(24, 560, ANCHO_GUIA, 120), FONDO_PANEL, BORDE_CIAN)
	titulo = _texto(guia, Rect2(18, 10, ANCHO_GUIA - 36, 28), "", 20, CIAN)
	detalle = _texto(guia, Rect2(18, 40, ANCHO_GUIA - 36, 68), "", 15, PAPEL)
	detalle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	accion = _boton(guia, Rect2(18, 114, ANCHO_GUIA - 36, 40), "")
	alternativa = _boton(guia, Rect2(18, 162, ANCHO_GUIA - 36, 40), "")
	accion.add_theme_font_size_override("font_size", 16)
	alternativa.add_theme_font_size_override("font_size", 16)

	# Pantalla modal para inicio, pausas y desenlace
	modal = ColorRect.new()
	modal.size = Vector2(1280, 720)
	modal.color = Color(0.03, 0.06, 0.09, 0.82)
	add_child(modal)
	var caja_modal := _panel(modal, Rect2(260, 180, 760, 340), TINTA, CIAN)
	modal_titulo = _texto(caja_modal, Rect2(36, 28, 688, 44), "", 30, PAPEL)
	modal_detalle = _texto(caja_modal, Rect2(36, 84, 688, 160), "", 18, MUTED)
	modal_detalle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	confirmar = _boton(caja_modal, Rect2(36, 260, 380, 48), "")
	confirmar.add_theme_font_size_override("font_size", 18)

func actualizar(estado: Dictionary, lugar: String, mensaje: String, principal: String, otra: String,
		actuar: bool, elegir: bool, interior: bool, plano: bool, punto: Vector2, nora: Vector2) -> void:
	for id: String in medidores:
		var valor: int = estado.reservas[id]
		var medidor: Array = medidores[id]
		var maximo: int = Modelo.LIMITES[id]
		medidor[0].text = "%d / %d" % [valor, maximo]
		medidor[1].value = valor

	if estado.aire_asegurado:
		medidores.oxigeno[0].text = "%d / 8 Â· SEGURO" % estado.reservas.oxigeno
		medidores.oxigeno[0].add_theme_color_override("font_color", VERDE)
	else:
		medidores.oxigeno[0].add_theme_color_override("font_color", CIAN)

	titulo.text = lugar
	detalle.text = mensaje
	accion.text = "E Â· " + principal
	accion.disabled = not actuar
	accion.visible = actuar
	alternativa.disabled = not elegir
	alternativa.visible = not otra.is_empty() and elegir
	alternativa.text = "Q Â· " + otra

	mapa.visible = interior
	mapa.text = "M Â· Cerrar plano" if plano else "M Â· Plano"

	var visible_punto := punto.clamp(Vector2(60, 120), Vector2(1220, 660))
	_ubicar_guia(visible_punto, nora, interior)

	# Indicador de navegaciÃ³n con pulsaciÃ³n
	var diferencia := punto - visible_punto
	marca.position = visible_punto - Vector2(35, 22)
	var pulso: float = 0.72 + 0.28 * sin(Time.get_ticks_msec() * 0.007)
	marca.modulate = Color(1.0, 1.0, 1.0, pulso)
	if diferencia.length() > 5:
		if absf(diferencia.x) >= absf(diferencia.y):
			marca.text = "â†" if diferencia.x < 0 else "â†’"
		else:
			marca.text = "â†‘" if diferencia.y < 0 else "â†“"
	else:
		marca.text = "â—†"

func aviso_de_pluto(visible_en_escena: bool, posicion: Vector2, texto := "") -> void:
	if visible_en_escena:
		aviso_pluto.position = Vector2(clampf(posicion.x - 170.0, 42.0, 872.0), clampf(posicion.y - 170.0, 118.0, 471.0))
		var mensaje := texto if not texto.is_empty() else "AcÃ©rcate a la consola. Tenemos que decidir quÃ© hacer con la tormenta."
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

	# En el interior: ubicaciÃ³n inteligente que no tape a Nora ni la consola
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

	guia.position = Vector2(clampf(x, 24.0, 1256.0 - ANCHO_GUIA), clampf(y, 110.0, 705.0 - guia.size.y))

func presentar(encabezado: String, mensaje: String, avance: String) -> void:
	modal_titulo.text = encabezado
	modal_detalle.text = mensaje
	confirmar.text = "E Â· " + avance
	confirmar.visible = not avance.is_empty()
	modal.show()

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
