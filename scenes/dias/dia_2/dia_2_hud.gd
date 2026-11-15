extends Control

const Modelo := preload("res://scripts/mecanicas/recursos_mision.gd")
const DialogoEscena := preload("res://scripts/dialogo_escena.gd")
const ANCHO_GUIA := 450.0
const TINTA := Color("#101c28")
const PAPEL := Color("#fff1db")
const CIAN := Color("#83eadc")
const MUTED := Color("#b3c5cc")
const OCRE := Color("#f6a44e")
const RECURSOS := {
	"energia": ["ENERGÍA · SOLAR 0", OCRE], "agua": ["AGUA", Color("#82bfff")],
	"oxigeno": ["OXÍGENO", CIAN], "alimento": ["ALIMENTO", Color("#bcda81")],
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


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel(self, Rect2(24, 20, 864, 82), TINTA, Color("#435660"))
	_texto(self, Rect2(43, 33, 150, 32), "DÍA 2", 26, PAPEL)
	_texto(self, Rect2(45, 68, 180, 20), "TORMENTA DE POLVO", 14, CIAN)
	var x := 237
	for id: String in RECURSOS:
		var ficha: Array = RECURSOS[id]
		_texto(self, Rect2(x, 34, 145, 20), ficha[0], 13, MUTED)
		var valor := _texto(self, Rect2(x, 56, 148, 28), "", 19, ficha[1])
		var barra := ProgressBar.new()
		barra.show_percentage = false
		barra.max_value = Modelo.LIMITES[id]
		barra.position = Vector2(x, 85)
		barra.size = Vector2(129, 4)
		barra.add_theme_stylebox_override("background", _estilo(Color("#314451"), Color.TRANSPARENT, 0))
		barra.add_theme_stylebox_override("fill", _estilo(ficha[1], Color.TRANSPARENT, 0))
		barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(barra)
		medidores[id] = [valor, barra]
		x += 168
	mapa = _boton(self, Rect2(932, 43, 141, 36), "M · Plano")
	pausa = _boton(self, Rect2(1084, 43, 150, 36), "Esc · Pausa")

	marca = _texto(self, Rect2(0, 0, 66, 42), "◆", 29, CIAN)
	marca.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	marca.add_theme_color_override("font_outline_color", TINTA)
	marca.add_theme_constant_override("outline_size", 8)

	aviso_pluto = DialogoEscena.new()
	add_child(aviso_pluto)
	guia = _panel(self, Rect2(24, 580, ANCHO_GUIA, 106), Color("#101c28ee"), Color("#435660"))
	titulo = _texto(guia, Rect2(16, 10, ANCHO_GUIA - 32, 29), "", 21, CIAN)
	detalle = _texto(guia, Rect2(16, 43, ANCHO_GUIA - 32, 57), "", 16, PAPEL)
	detalle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	accion = _boton(guia, Rect2(16, 102, ANCHO_GUIA - 32, 36), "")
	alternativa = _boton(guia, Rect2(16, 146, ANCHO_GUIA - 32, 36), "")
	accion.add_theme_font_size_override("font_size", 16)
	alternativa.add_theme_font_size_override("font_size", 16)

	modal = ColorRect.new()
	modal.size = Vector2(1280, 720)
	modal.color = Color(0.04, 0.07, 0.10, 0.74)
	add_child(modal)
	_panel(modal, Rect2(290, 217, 700, 286), TINTA, CIAN)
	modal_titulo = _texto(modal, Rect2(328, 250, 624, 50), "", 34, PAPEL)
	modal_detalle = _texto(modal, Rect2(330, 316, 618, 82), "", 20, MUTED)
	modal_detalle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	confirmar = _boton(modal, Rect2(330, 425, 360, 44), "")


func actualizar(estado: Dictionary, lugar: String, mensaje: String, principal: String, otra: String,
		actuar: bool, elegir: bool, interior: bool, plano: bool, punto: Vector2, nora: Vector2) -> void:
	for id: String in medidores:
		var valor: int = estado.reservas[id]
		var medidor: Array = medidores[id]
		var maximo: int = Modelo.LIMITES[id]
		medidor[0].text = "%d / %d" % [valor, maximo]
		medidor[1].value = valor
	if estado.aire_asegurado:
		medidores.oxigeno[0].text += " · seguro"
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
	var visible_punto := punto.clamp(Vector2(59, 123), Vector2(1221, 657))
	_ubicar_guia(visible_punto, nora)
	var diferencia := punto - visible_punto
	marca.position = visible_punto - Vector2(33, 21)
	marca.text = "◆"
	if diferencia.length() > 4:
		if absf(diferencia.x) >= absf(diferencia.y):
			marca.text = "←" if diferencia.x < 0 else "→"
		else:
			marca.text = "↑" if diferencia.y < 0 else "↓"


func aviso_de_pluto(visible_en_escena: bool, posicion: Vector2) -> void:
	if visible_en_escena:
		aviso_pluto.position = Vector2(clampf(posicion.x - 170.0, 42.0, 872.0), clampf(posicion.y - 170.0, 118.0, 471.0))
		aviso_pluto.decir("Pluto", "Acércate a la consola. Tenemos que decidir qué hacer con la tormenta.")
	else:
		aviso_pluto.hide()


func _ubicar_guia(punto: Vector2, nora: Vector2) -> void:
	var opciones := int(accion.visible) + int(alternativa.visible)
	guia.size.y = 108.0 + opciones * 44.0
	alternativa.position.y = 146.0 if accion.visible else 102.0
	if opciones == 0:
		guia.position = Vector2(24, 588)
		if punto.x < 494 and punto.y > 570:
			guia.position.x = 806
		return
	var derecha := punto.x + 56.0
	var izquierda := punto.x - 56.0 - ANCHO_GUIA
	var x := derecha
	if derecha + ANCHO_GUIA > 1256.0 or (izquierda >= 24.0 and nora.x > punto.x + 12.0):
		x = izquierda
	var y := punto.y - 54.0
	if nora.x >= x - 25.0 and nora.x <= x + ANCHO_GUIA + 25.0:
		y = nora.y + 18.0
	guia.position = Vector2(x, clampf(y, 114.0, 696.0 - guia.size.y))


func presentar(encabezado: String, mensaje: String, avance: String) -> void:
	modal_titulo.text = encabezado
	modal_detalle.text = mensaje
	confirmar.text = "E · " + avance
	confirmar.visible = not avance.is_empty()
	modal.show()


func _estilo(color: Color, borde: Color, grosor: int) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = color
	estilo.border_color = borde
	estilo.set_border_width_all(grosor)
	return estilo


func _panel(padre: Control, rect: Rect2, color: Color, borde: Color) -> Panel:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _estilo(color, borde, 1))
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
	boton.add_theme_font_size_override("font_size", 17)
	boton.add_theme_color_override("font_color", PAPEL)
	boton.add_theme_color_override("font_disabled_color", MUTED)
	boton.add_theme_stylebox_override("normal", _estilo(Color("#19333d"), CIAN, 1))
	boton.add_theme_stylebox_override("hover", _estilo(Color("#28515b"), CIAN, 2))
	boton.add_theme_stylebox_override("pressed", _estilo(Color("#13252d"), PAPEL, 2))
	boton.add_theme_stylebox_override("disabled", _estilo(Color("#16252f"), Color("#435660"), 1))
	padre.add_child(boton)
	return boton
