extends Control
## Mesa de trabajo accesible con ratón o teclado. El día confirma el coste al terminar.
signal completado(tipo: String)
signal cancelado
signal sonido(correcto: bool)

const Reglas := preload("res://scenes/dias/dia_2/retos_dia_2.gd")
const UI := preload("res://scenes/dias/dia_2/dia_2_hud.gd")
const Iconos := preload("res://scripts/mecanicas/indicadores_refugio.gd")
const ARTE := preload("res://assets/dias/dia_2/piezas_mantenimiento.png")
const CODO := Rect2(68, 62, 444, 456)
const TUBO := Rect2(668, 235, 534, 218)
const PESTILLO := Rect2(51, 770, 336, 367)
const RIEL := Rect2(463, 878, 768, 207)
var reglas := Reglas.new()
var tipo := "aire"
var jugando := false
var seleccionado := 0
var ui := UI.new()
var fondo: TextureRect
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
var angulos := PackedFloat32Array()
var giros_visuales := PackedFloat32Array()
var ajuste_visual := 0.0

func _ready() -> void:
	size = Vector2(1280, 720)
	fondo = TextureRect.new()
	fondo.size = size
	fondo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fondo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fondo)
	var velo := ColorRect.new()
	velo.size = size
	velo.color = Color("#18111bcb")
	velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(velo)
	var panel := Control.new()
	panel.position = Vector2(220, 108)
	panel.size = Vector2(840, 560)
	add_child(panel)
	titulo = ui._texto(panel, Rect2(30, 20, 780, 38), "", 28, UI.PAPEL)
	pista = ui._texto(panel, Rect2(30, 66, 780, 54), "", 19, UI.CIAN)
	pista.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tablero = Control.new()
	tablero.position = Vector2(260, 240)
	tablero.size = Vector2(760, 270)
	tablero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tablero.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
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
	izquierda = ui._boton(tablero, Rect2(44, 188, 140, 42), I18n.t("taller.mover_izq"))
	derecha = ui._boton(tablero, Rect2(576, 188, 140, 42), I18n.t("taller.mover_der"))
	izquierda.pressed.connect(_mover.bind(-1))
	derecha.pressed.connect(_mover.bind(1))
	progreso = ui._texto(panel, Rect2(30, 402, 780, 24), "", 17, UI.ORO)
	respuesta = ui._texto(panel, Rect2(30, 435, 780, 30), "", 18, UI.PAPEL)
	reserva = ui._texto(self, Rect2(230, 68, 630, 30), "", 18, UI.PAPEL)
	reserva.add_theme_color_override("font_outline_color", UI.TINTA)
	reserva.add_theme_constant_override("outline_size", 6)
	pausa = ui._boton(self, Rect2(860, 62, 200, 36), I18n.t("ui.esc_pausa"))
	pausa.pressed.connect(_pausar)
	principal = ui._boton(panel, Rect2(30, 488, 510, 48), "")
	principal.pressed.connect(_confirmar)
	volver = ui._boton(panel, Rect2(560, 488, 250, 48), I18n.t("taller.volver"))
	volver.pressed.connect(func(): cancelado.emit())
	hide()

func abrir(actividad: String) -> void:
	tipo = actividad
	reglas = Reglas.new()
	fondo.texture = load("res://assets/laboratorio_banco.png") if tipo == "aire" else PuestoUmbra.TORMENTA
	angulos.clear()
	for giro in reglas.giros:
		angulos.append(giro * PI / 2.0)
	giros_visuales = angulos.duplicate()
	ajuste_visual = reglas.ajuste
	jugando = false
	pausa.text = I18n.t("ui.esc_pausa")
	seleccionado = 0
	respuesta.text = I18n.t("taller.nota")
	var prefijo := "taller.tubo" if tipo == "aire" else "taller.cierre"
	titulo.text = I18n.t(prefijo + ".tit")
	pista.text = I18n.t(prefijo + ".inst")
	progreso.text = I18n.t(prefijo + ".costo")
	principal.text = I18n.t("taller.empezar")
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
	for i in giros_visuales.size():
		giros_visuales[i] = move_toward(giros_visuales[i], angulos[i], delta * 11.0)
	ajuste_visual = move_toward(ajuste_visual, reglas.ajuste, delta * 10.0)
	tablero.queue_redraw()

func tecla(codigo: Key) -> void:
	match codigo:
		KEY_F: cancelado.emit()
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
		principal.text = I18n.t("taller.pausa_cont")
		respuesta.text = I18n.t("taller.pausa_msg")
		pausa.text = I18n.t("ui.esc_continuar")
	else:
		_confirmar()

func mostrar_aire(estado: Dictionary) -> void:
	reserva.text = I18n.t("taller.aire_ok") if estado.aire_asegurado else I18n.tf("taller.aire_reloj", [estado.reservas.oxigeno])
	reserva.add_theme_color_override("font_color", UI.VERDE if estado.aire_asegurado else (UI.ORO if estado.reservas.oxigeno > 3 else UI.ROJO))

func _girar(indice: int) -> void:
	if not jugando: return
	seleccionado = indice
	reglas.girar(indice)
	angulos[indice] += PI / 2.0
	sonido.emit(true)
	respuesta.text = I18n.t("taller.tubo.completo" if reglas.aire_conectado() else "taller.tubo.luz")
	tablero.queue_redraw()

func _mover(cantidad: int) -> void:
	if not jugando: return
	reglas.mover(cantidad)
	sonido.emit(true)
	tablero.queue_redraw()

func _confirmar() -> void:
	if not jugando:
		jugando = true
		pausa.text = I18n.t("ui.esc_pausa")
		principal.text = I18n.t("taller.btn.activar_aire" if tipo == "aire" else "taller.btn.fijar_cierre")
		respuesta.text = I18n.t("taller.ayuda.tubo" if tipo == "aire" else "taller.ayuda.cierre")
		tablero.queue_redraw()
		return
	if tipo == "aire":
		if reglas.aire_conectado():
			completado.emit(tipo)
		else:
			reglas.fallos += 1
			respuesta.text = I18n.t("taller.tubo.falta")
			sonido.emit(false)
	else:
		var resultado := reglas.asegurar()
		match resultado:
			"listo": completado.emit(tipo)
			"siguiente":
				respuesta.text = I18n.t("taller.cierre.bien")
				sonido.emit(true)
			"alinear":
				respuesta.text = I18n.t("taller.cierre.casi")
				sonido.emit(false)
			"viento":
				respuesta.text = I18n.t("taller.cierre.rafaga")
				sonido.emit(false)
	tablero.queue_redraw()

func _rotulo(texto: String, punto: Vector2, color: Color, tamano := 18) -> void:
	tablero.draw_string_outline(ThemeDB.fallback_font, punto, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamano, 5, UI.TINTA)
	tablero.draw_string(ThemeDB.fallback_font, punto, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamano, color)

func _dibujar() -> void:
	if tipo == "aire":
		_dibujar_aire()
	else:
		_dibujar_cierres()

func _dibujar_aire() -> void:
	var ruta := reglas.recorrido()
	var brillo := 0.94 + 0.06 * sin(reglas.tiempo * 5.0)
	var conectado := Color(0.71, 1.0, 1.0, brillo)
	_rotulo(I18n.t("taller.entrada"), Vector2(32, 70), UI.CIAN)
	_rotulo(I18n.t("taller.agua_energia"), Vector2(32, 98), UI.MUTED, 16)
	var atlas := Iconos.ICONOS.get_size()
	tablero.draw_texture_rect_region(Iconos.ICONOS, Rect2(32, 18, 30, 38), Rect2(Iconos.GOTA.position * atlas, Iconos.GOTA.size * atlas))
	tablero.draw_texture_rect_region(Iconos.ICONOS, Rect2(83, 18, 30, 38), Rect2(Iconos.RAYO.position * atlas, Iconos.RAYO.size * atlas))
	tablero.draw_texture_rect_region(ARTE, Rect2(161, 25, 116, 32), TUBO, conectado)
	_rotulo(I18n.t("taller.tanque"), Vector2(582, 168), UI.CIAN)
	_rotulo(I18n.t("ind.oxigeno"), Vector2(582, 195), UI.MUTED, 16)
	for i in 3:
		var y := 84.0 - fposmod(reglas.tiempo * 12.0 + i * 23.0, 60.0)
		tablero.draw_texture_rect_region(Iconos.ICONOS, Rect2(594 + (i % 2) * 24, y, 22, 22), Rect2(Iconos.BURBUJA.position * atlas, Iconos.BURBUJA.size * atlas), Color.WHITE if 9 in ruta else Iconos.APAGADO)
	tablero.draw_texture_rect_region(ARTE, Rect2(520, 189, 61, 32), TUBO, conectado if 9 in ruta else Color("#928885"))
	for celda in [0, 1, 4, 5, 8]:
		var origen := Vector2(280 + (celda % 3) * 82, 4 + floori(celda / 3.0) * 82)
		var centro := origen + Vector2(37, 37)
		var indice := Reglas.PIEZAS.find(celda)
		var tinta := conectado if celda in ruta else Color("#a99d95")
		if indice < 0:
			tablero.draw_texture_rect_region(ARTE, Rect2(centro - Vector2(42, 16), Vector2(84, 32)), TUBO, tinta)
			continue
		# El pivote del codo coincide con el cruce de sus dos puertos.
		tablero.draw_set_transform(centro, giros_visuales[indice])
		tablero.draw_texture_rect_region(ARTE, Rect2(-15, -42, 57, 57), CODO, tinta)
		tablero.draw_set_transform(Vector2.ZERO)
		_rotulo(str(indice + 1), origen + Vector2(7, 19), UI.ORO if indice == seleccionado else UI.PAPEL, 17)
	_rotulo(I18n.t("taller.girar"), Vector2(32, 172), UI.ORO, 16)
	_rotulo(I18n.t("taller.clic_piezas"), Vector2(32, 198), UI.PAPEL, 16)
	_rotulo(I18n.t("taller.teclas_14"), Vector2(32, 222), UI.MUTED, 16)

func _dibujar_cierres() -> void:
	var cierre := mini(reglas.cierre, 2)
	for i in 3:
		var color := UI.VERDE if i < reglas.cierre else (UI.ORO if i == cierre else UI.MUTED)
		_rotulo((I18n.t("taller.listo") + "  " if i < reglas.cierre else str(i + 1) + "  ") + I18n.t("taller.col.%d" % i), Vector2(i * 250 + 4, 20), color, 15)
	var calma := reglas.calma()
	_rotulo(I18n.t("taller.calma" if calma else "taller.rafaga"), Vector2(200, 64), UI.VERDE if calma else UI.ORO, 23)
	tablero.draw_texture_rect_region(ARTE, Rect2(85, 104, 592, 64), RIEL)
	var objetivo: float = 116.0 + Reglas.METAS[cierre] * 66.0
	var meta_txt := I18n.t("taller.meta")
	var meta_w := ThemeDB.fallback_font.get_string_size(meta_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	_rotulo(meta_txt, Vector2(objetivo - meta_w * 0.5, 98), UI.ORO, 16)
	var ajuste := 116.0 + ajuste_visual * 66.0
	tablero.draw_texture_rect_region(ARTE, Rect2(ajuste - 26, 104, 52, 59), PESTILLO)
	_rotulo(I18n.t("taller.leyenda"), Vector2(212, 216), UI.PAPEL, 18)

func _exit_tree() -> void:
	ui.free()
