extends "res://scripts/estacion_umbra.gd"
## En el Sol 3 puedes comparar las rutas y luego aplicar una sola.

signal confirmada(id: String)
signal cerrar_solicitado

const VERDE := Color("#c3eaaa")

var rutas: Array[Dictionary] = []
var aviso := ""
var elegida := -1
var aplicar: Button
var _opciones: Array[Button] = []
var _indicacion: Label


func _ready() -> void:
	size = Vector2(1280, 720)
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_imagen(load("res://assets/laboratorio_banco.png"), Rect2(Vector2.ZERO, size))
	var sombra := ColorRect.new()
	sombra.size = size
	sombra.color = Color("#160f1ab5")
	sombra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sombra)
	_texto("Fallo eléctrico", Rect2(72, 28, 825, 52), 40, PAPEL)
	_texto("El regulador solo puede alimentar un circuito.", Rect2(74, 84, 800, 36), 22, ORO)
	_boton("Volver al recorrido · Esc", Rect2(976, 73, 245, 45), 19, cerrar_solicitado.emit)
	for i in rutas.size():
		var ruta := rutas[i]
		var x := 76.0 + i * 598.0
		var color := AGUA if i == 0 else VERDE
		var boton := _boton("%d   %s" % [i + 1, ruta.titulo], Rect2(x, 458, 495, 50), 28, _elegir.bind(i))
		boton.alignment = HORIZONTAL_ALIGNMENT_LEFT
		boton.add_theme_color_override("font_color", color)
		boton.disabled = not ruta.posible
		_opciones.append(boton)
		_texto(ruta.costo, Rect2(x + 4, 513, 548, 35), 19, color)
		_texto(ruta.efecto, Rect2(x + 4, 550, 548, 36), 18, PAPEL)
		if boton.disabled:
			_texto("Reservas insuficientes", Rect2(x + 4, 587, 548, 31), 17, ORO)
	_indicacion = _texto("Elige 1 o 2 para revisar la ruta.", Rect2(79, 644, 714, 42), 20, PAPEL)
	if not aviso.is_empty():
		_indicacion.text = aviso
	aplicar = _boton("Aplicar ruta · E", Rect2(828, 638, 365, 50), 24, _confirmar)
	aplicar.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	aplicar.add_theme_color_override("font_color", ORO)
	aplicar.hide()


func _unhandled_key_input(evento: InputEvent) -> void:
	if not evento is InputEventKey or not evento.pressed or evento.echo:
		return
	var tecla: Key = evento.keycode if evento.keycode != KEY_NONE else evento.physical_keycode
	if tecla not in [KEY_ESCAPE, KEY_1, KEY_2, KEY_E, KEY_ENTER]:
		return
	get_viewport().set_input_as_handled()
	match tecla:
		KEY_ESCAPE:
			cerrar_solicitado.emit()
		KEY_1, KEY_2:
			_elegir(tecla - KEY_1)
		KEY_E, KEY_ENTER:
			_confirmar()


func _elegir(indice: int) -> void:
	if _opciones[indice].disabled:
		_indicacion.text = "Revisa las reservas de esa ruta antes de accionarla."
		return
	elegida = indice
	var ruta := rutas[indice]
	_indicacion.text = "Ruta elegida · %s" % ruta.titulo
	aplicar.show()


func _confirmar() -> void:
	if elegida >= 0:
		confirmada.emit(rutas[elegida].id)
