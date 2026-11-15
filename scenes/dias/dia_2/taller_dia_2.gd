extends Control
## Mesa de trabajo accesible con ratón o teclado. El día confirma el coste al terminar.
signal completado(tipo: String)
signal cancelado
signal sonido(correcto: bool)

const Reglas := preload("res://scenes/dias/dia_2/retos_dia_2.gd")
const UI := preload("res://scenes/dias/dia_2/dia_2_hud.gd")
const Iconos := preload("res://scripts/mecanicas/indicadores_refugio.gd")
var reglas := Reglas.new()
var tipo := "aire"
var jugando := false
var seleccionado := 0
var ui := UI.new()
var tablero: Control
var titulo: Label
var pista: Label
var respuesta: Label
var progreso: Label
var reserva: Label
var pausa: Button
var principal: Button
var volver: Button
var izquierda: Button
var derecha: Button
var piezas: Array[Button] = []

func _ready() -> void:
	size = Vector2(1280, 720)
	var velo := ColorRect.new()
	velo.size = size
	velo.color = Color(0.025, 0.05, 0.08, 0.78)
	add_child(velo)
	var panel := ui._panel(self, Rect2(220, 108, 840, 560), UI.TINTA, UI.BORDE_CIAN)
	titulo = ui._texto(panel, Rect2(30, 20, 780, 38), "", 28, UI.PAPEL)
	pista = ui._texto(panel, Rect2(30, 66, 780, 54), "", 19, UI.CIAN)
	pista.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tablero = Control.new()
	tablero.position = Vector2(260, 240)
	tablero.size = Vector2(760, 270)
	tablero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tablero.draw.connect(_dibujar)
	add_child(tablero)
	for i in 4:
		var celda: int = Reglas.PIEZAS[i]
		var boton := Button.new()
		boton.position = Vector2(280 + (celda % 3) * 82, 4 + floori(celda / 3.0) * 82)
		boton.size = Vector2(74, 74)
		boton.flat = true
		boton.focus_mode = Control.FOCUS_NONE
		boton.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		boton.pressed.connect(_girar.bind(i))
		tablero.add_child(boton)
		piezas.append(boton)
	izquierda = ui._boton(tablero, Rect2(44, 188, 140, 42), "A / ←   Mover")
	derecha = ui._boton(tablero, Rect2(576, 188, 140, 42), "Mover   D / →")
	izquierda.pressed.connect(_mover.bind(-1))
	derecha.pressed.connect(_mover.bind(1))
	progreso = ui._texto(panel, Rect2(30, 402, 780, 24), "", 17, UI.ORO)
	respuesta = ui._texto(panel, Rect2(30, 435, 780, 30), "", 18, UI.PAPEL)
	reserva = ui._texto(self, Rect2(230, 68, 630, 30), "", 18, UI.PAPEL)
	reserva.add_theme_color_override("font_outline_color", UI.TINTA)
	reserva.add_theme_constant_override("outline_size", 6)
	pausa = ui._boton(self, Rect2(860, 62, 200, 36), "Esc · Pausa")
	pausa.pressed.connect(_pausar)
	principal = ui._boton(panel, Rect2(30, 488, 510, 48), "")
	principal.pressed.connect(_confirmar)
	volver = ui._boton(panel, Rect2(560, 488, 250, 48), "Q · Volver sin gastar")
	volver.pressed.connect(func(): cancelado.emit())
	hide()

func abrir(actividad: String) -> void:
	tipo = actividad
	reglas = Reglas.new()
	jugando = false
	pausa.text = "Esc · Pausa"
	seleccionado = 0
	respuesta.text = "Puedes probar otra vez. Equivocarte no gasta recursos."
	titulo.text = "Laboratorio · Un camino para el aire" if tipo == "aire" else "Exterior · Que nada salga volando"
	pista.text = "Gira las 4 piezas hasta unir la entrada con el tanque." if tipo == "aire" else "Alinea cada cierre con su marca. Fíjalo cuando diga CALMA."
	progreso.text = "Al activar: 6 energía + 1 agua → aire seguro hasta dormir." if tipo == "aire" else "Al terminar: 4 energía + 1 comida → equipos protegidos."
	principal.text = "E · Entendido, empezar"
	izquierda.visible = tipo == "reparar"
	derecha.visible = tipo == "reparar"
	for pieza in piezas:
		pieza.visible = tipo == "aire"
	show()
	tablero.queue_redraw()

func avanzar(delta: float) -> void:
	if not visible or not jugando:
		return
	reglas.tiempo += delta
	tablero.queue_redraw()

func tecla(codigo: Key) -> void:
	match codigo:
		KEY_Q: cancelado.emit()
		KEY_ESCAPE: _pausar()
		KEY_E: _confirmar()
		KEY_ENTER, KEY_SPACE:
			if jugando and tipo == "aire":
				_girar(seleccionado)
			else:
				_confirmar()
		KEY_A, KEY_LEFT:
			if tipo == "reparar": _mover(-1)
			else: seleccionado = posmod(seleccionado - 1, 4)
		KEY_D, KEY_RIGHT:
			if tipo == "reparar": _mover(1)
			else: seleccionado = (seleccionado + 1) % 4
		KEY_1, KEY_2, KEY_3, KEY_4:
			if tipo == "aire": _girar(codigo - KEY_1)
	tablero.queue_redraw()

func _pausar() -> void:
	if jugando:
		jugando = false
		principal.text = "E · Continuar"
		respuesta.text = "En pausa. Tus piezas se quedan como las dejaste."
		pausa.text = "Esc · Continuar"
	else:
		_confirmar()

func mostrar_aire(estado: Dictionary) -> void:
	reserva.text = "AIRE SEGURO · ya puedes trabajar con calma" if estado.aire_asegurado else "AIRE: %d / 8 · Esc pausa el juego y conserva tus piezas" % estado.reservas.oxigeno
	reserva.add_theme_color_override("font_color", UI.VERDE if estado.aire_asegurado else (UI.ORO if estado.reservas.oxigeno > 3 else UI.ROJO))

func _girar(indice: int) -> void:
	if not jugando: return
	seleccionado = indice
	reglas.girar(indice)
	sonido.emit(true)
	respuesta.text = "¡Camino completo! Pulsa E para llenar el tanque." if reglas.aire_conectado() else "Sigue la luz azul: muestra hasta dónde llega el aire."
	tablero.queue_redraw()

func _mover(cantidad: int) -> void:
	if not jugando: return
	reglas.mover(cantidad)
	sonido.emit(true)
	tablero.queue_redraw()

func _confirmar() -> void:
	if not jugando:
		jugando = true
		pausa.text = "Esc · Pausa"
		principal.text = "E · Activar el aire" if tipo == "aire" else "E · Fijar este cierre"
		respuesta.text = "Clic para girar · o teclas 1, 2, 3, 4." if tipo == "aire" else "Mueve con A / D o los botones. Busca la marca dorada."
		tablero.queue_redraw()
		return
	if tipo == "aire":
		if reglas.aire_conectado():
			completado.emit(tipo)
		else:
			reglas.fallos += 1
			respuesta.text = "Falta unir las tuberías. Gira donde se detiene la luz azul."
			sonido.emit(false)
	else:
		var resultado := reglas.asegurar()
		match resultado:
			"listo": completado.emit(tipo)
			"siguiente":
				respuesta.text = "¡Bien! Un cierre más protegido. Vamos al siguiente."
				sonido.emit(true)
			"alinear":
				respuesta.text = "Casi. Mueve la pieza hasta la marca dorada."
				sonido.emit(false)
			"viento":
				respuesta.text = "¡Una ráfaga! Espera a que vuelva CALMA y pulsa E."
				sonido.emit(false)
	tablero.queue_redraw()

func _rotulo(texto: String, punto: Vector2, color: Color, tamano := 18) -> void:
	tablero.draw_string(ThemeDB.fallback_font, punto, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamano, color)

func _dibujar() -> void:
	if tipo == "aire":
		_dibujar_aire()
	else:
		_dibujar_cierres()

func _dibujar_aire() -> void:
	var ruta := reglas.recorrido()
	_rotulo("ENTRADA", Vector2(32, 70), UI.CIAN)
	_rotulo("Agua + energía", Vector2(32, 98), UI.MUTED, 16)
	var atlas := Iconos.ICONOS.get_size()
	tablero.draw_texture_rect_region(Iconos.ICONOS, Rect2(32, 18, 30, 38), Rect2(Iconos.GOTA.position * atlas, Iconos.GOTA.size * atlas))
	tablero.draw_texture_rect_region(Iconos.ICONOS, Rect2(83, 18, 30, 38), Rect2(Iconos.RAYO.position * atlas, Iconos.RAYO.size * atlas))
	tablero.draw_line(Vector2(164, 41), Vector2(280, 41), UI.CIAN, 8)
	_rotulo("TANQUE", Vector2(582, 168), UI.CIAN)
	_rotulo("Oxígeno", Vector2(582, 195), UI.MUTED, 16)
	for i in 3:
		var y := 84.0 - fposmod(reglas.tiempo * 12.0 + i * 23.0, 60.0)
		tablero.draw_texture_rect_region(Iconos.ICONOS, Rect2(594 + (i % 2) * 24, y, 22, 22), Rect2(Iconos.BURBUJA.position * atlas, Iconos.BURBUJA.size * atlas), Color.WHITE if 9 in ruta else Iconos.APAGADO)
	tablero.draw_line(Vector2(518, 205), Vector2(570, 205), UI.VERDE if 9 in ruta else UI.BORDE_CIAN, 8)
	for celda in [0, 1, 4, 5, 8]:
		var origen := Vector2(280 + (celda % 3) * 82, 4 + floori(celda / 3.0) * 82)
		var centro := origen + Vector2(37, 37)
		tablero.draw_rect(Rect2(origen, Vector2(74, 74)), Color("#19333e"))
		var indice := Reglas.PIEZAS.find(celda)
		var color := UI.CIAN if celda in ruta else UI.MUTED
		for direccion: int in reglas.conexiones(celda):
			var vector: Vector2 = [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT][direccion]
			tablero.draw_line(centro, centro + vector * 41, color, 10)
		tablero.draw_circle(centro, 8, color)
		if indice >= 0:
			tablero.draw_rect(Rect2(origen, Vector2(74, 74)), UI.ORO if indice == seleccionado else UI.BORDE_CIAN, false, 2)
			_rotulo(str(indice + 1), origen + Vector2(5, 17), UI.ORO, 15)
	_rotulo("GIRAR", Vector2(32, 172), UI.ORO, 16)
	_rotulo("Clic en las piezas", Vector2(32, 198), UI.PAPEL, 16)
	_rotulo("o teclas 1 · 2 · 3 · 4", Vector2(32, 222), UI.MUTED, 16)

func _dibujar_cierres() -> void:
	var cierre := mini(reglas.cierre, 2)
	var nombres := ["PANEL IZQUIERDO", "PANEL DERECHO", "TOMA DEL LABORATORIO"]
	for i in 3:
		var color := UI.VERDE if i < reglas.cierre else (UI.ORO if i == cierre else UI.MUTED)
		_rotulo(("LISTO  " if i < reglas.cierre else str(i + 1) + "  ") + nombres[i], Vector2(i * 250 + 4, 20), color, 15)
	var calma := reglas.calma()
	_rotulo("CALMA · puedes fijar" if calma else "RÁFAGA · espera un momento", Vector2(200, 64), UI.VERDE if calma else UI.ORO, 23)
	tablero.draw_rect(Rect2(180, 78, 400, 5), UI.BORDE_CIAN)
	tablero.draw_rect(Rect2(180, 78, 400 * fposmod(reglas.tiempo, 4.0) / 4.0, 5), UI.VERDE if calma else UI.ORO)
	for i in 9:
		var x := 112.0 + i * 66
		tablero.draw_rect(Rect2(x, 111, 20, 42), Color("#29434c"))
		if i == Reglas.METAS[cierre]:
			tablero.draw_rect(Rect2(x - 10, 102, 40, 60), UI.ORO, false, 3)
		if i == reglas.ajuste:
			tablero.draw_rect(Rect2(x - 4, 117, 28, 30), UI.CIAN)
	_rotulo("Pieza azul → marca dorada", Vector2(240, 216), UI.PAPEL, 19)

func _exit_tree() -> void:
	ui.free()
