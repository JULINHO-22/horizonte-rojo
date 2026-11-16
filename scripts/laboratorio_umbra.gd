extends "res://scripts/estacion_umbra.gd"
## Primer plano del filtro y de la válvula. Solo el modelo aplica costes y resultados.

signal cerrar_solicitado
signal trabajo_completado(ganancia: int)

const Recursos := preload("res://scripts/mecanicas/recursos_mision.gd")
const Sostener := preload("res://scripts/mecanicas/accion_sostenida.gd")
const Equipo := preload("res://scripts/equipo_pixel.gd")
const BANCO := "res://assets/laboratorio_banco.png"
const AMBAR := Color("#fbc790")
const VERDE := Color("#bcf4b2")
const RIESGO := Color("#ffc5aa")
const CUBETA := Rect2(107, 351, 336, 84)
const REPOSO_HIELO := Vector2(127, 502)
const CAMARA_HIELO := Vector2(592, 326)
const BOTON_FILTRO := Rect2(554, 386, 83, 76)
const VALVULA := Rect2(906, 303, 131, 125)
const CICLO := 1.35

var recursos: Recursos
var tipo := "agua"
var accion: Button
var mando: Button
var muestra_cargada := false

var _sostener := Sostener.new()
var _hielo: TextureRect
var _particulas: Array[TextureRect] = []
var _titulo: Label
var _detalle: Label
var _nota: Label
var _guia: Label
var _feedback := ""
var _feedback_ok := false
var _arrastrando := false


func _ready() -> void:
	size = Vector2(1280, 720)
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_imagen(load(BANCO), Rect2(Vector2.ZERO, size))
	_sombra_superior()
	var encabezado := I18n.t("lab.agua.encabezado" if tipo == "agua" else "lab.ox.encabezado")
	_texto(encabezado, Rect2(69, 23, 720, 47), 36, PAPEL)
	_texto(I18n.t("lab.subtitulo"), Rect2(71, 69, 650, 34), 20, AMBAR)
	var volver := _boton(I18n.t("lab.volver"), Rect2(890, 74, 326, 43), 19, cerrar_solicitado.emit)
	volver.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_guia = _texto("", Rect2(0, 0, 336, 31), 19, AGUA, HORIZONTAL_ALIGNMENT_CENTER)
	_hielo = _imagen(Equipo.hielo(), Rect2(Vector2.ZERO, Vector2(72, 68)))
	_hielo.pivot_offset = _hielo.size * 0.5

	var region := Equipo.Indicadores.GOTA if tipo == "agua" else Equipo.Indicadores.BURBUJA
	var textura := Equipo.indicador(region)
	for i in 8:
		var particula := _imagen(textura, Rect2(0, 0, 17, 22))
		particula.hide()
		_particulas.append(particula)

	mando = _boton("", BOTON_FILTRO if tipo == "agua" else VALVULA, 19)
	mando.button_down.connect(_iniciar_ciclo.bind(&"puntero"))
	mando.button_up.connect(_interrumpir.bind(&"puntero"))
	accion = _boton("", Rect2(772, 602, 442, 60), 24)
	accion.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	accion.add_theme_color_override("font_color", AMBAR)
	accion.button_down.connect(_usar_accion.bind(&"puntero"))
	accion.button_up.connect(_interrumpir.bind(&"puntero"))
	_titulo = _texto("", Rect2(69, 586, 695, 49), 31, PAPEL)
	_detalle = _texto("", Rect2(71, 635, 675, 29), 20, PAPEL)
	_nota = _texto("", Rect2(71, 666, 1143, 30), 18, AGUA)
	_ubicar_hielo(REPOSO_HIELO)
	_refrescar()
	recursos.cambiado.connect(_refrescar)


func _notification(que: int) -> void:
	if que in [NOTIFICATION_DISABLED, NOTIFICATION_APPLICATION_FOCUS_OUT] and is_node_ready():
		_interrumpir(&"")
		_cancelar_arrastre()


func _process(delta: float) -> void:
	if not _sostener.activa():
		return
	if _sostener.avanzar(delta):
		_detener_efecto()
		_terminar_ciclo()
	else:
		_animar_ciclo()


func _unhandled_key_input(evento: InputEvent) -> void:
	if not evento is InputEventKey or evento.echo:
		return
	var tecla: Key = evento.keycode if evento.keycode != KEY_NONE else evento.physical_keycode
	if tecla == KEY_ESCAPE and evento.pressed:
		get_viewport().set_input_as_handled()
		cerrar_solicitado.emit()
	elif tecla in [KEY_E, KEY_ENTER]:
		get_viewport().set_input_as_handled()
		if not evento.pressed:
			_interrumpir(&"teclado")
		else:
			_usar_accion(&"teclado")


func _input(evento: InputEvent) -> void:
	if not evento is InputEventMouse or not is_node_ready() or tipo != "agua" or muestra_cargada or not _hielo.visible:
		return
	var local: Vector2 = get_global_transform_with_canvas().affine_inverse() * evento.position
	if evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT:
		if evento.pressed and not accion.disabled and _hielo.get_rect().grow(10).has_point(local):
			_arrastrando = true
			get_viewport().set_input_as_handled()
		elif not evento.pressed and _arrastrando:
			get_viewport().set_input_as_handled()
			_cancelar_arrastre()
			if CUBETA.has_point(local):
				_colocar_muestra()
			else:
				_feedback = I18n.t("lab.agua.err_cubeta")
				_feedback_ok = false
				_refrescar()
	elif evento is InputEventMouseMotion and _arrastrando:
		_ubicar_hielo(local)
		get_viewport().set_input_as_handled()


func _cancelar_arrastre() -> void:
	if _arrastrando:
		_arrastrando = false
		_ubicar_hielo(REPOSO_HIELO)


func _usar_accion(origen: StringName) -> void:
	if tipo == "agua" and not muestra_cargada:
		_colocar_muestra()
	else:
		_iniciar_ciclo(origen)


func _colocar_muestra() -> void:
	if not accion.visible or accion.disabled:
		return
	muestra_cargada = true
	_feedback = ""
	_feedback_ok = false
	_ubicar_hielo(CAMARA_HIELO)
	_refrescar()


func _iniciar_ciclo(origen: StringName) -> void:
	if (tipo == "agua" and not muestra_cargada) or accion.disabled or not accion.visible:
		return
	if _sostener.iniciar(origen, CICLO):
		_feedback = ""
		_feedback_ok = false
		_animar_ciclo()


func _interrumpir(origen: StringName) -> void:
	if _sostener.soltar(origen):
		_detener_efecto()
		_feedback = I18n.t("lab.err_soltar")
		_feedback_ok = false
		_refrescar()


func _terminar_ciclo() -> void:
	var anterior := recursos.estado()
	var hecho := recursos.purificar_hielo() if tipo == "agua" else recursos.activar_oxigeno()
	if not hecho:
		_feedback = I18n.t("lab.err_reservas")
		_feedback_ok = false
		_refrescar()
		return
	muestra_cargada = false
	_ubicar_hielo(REPOSO_HIELO)
	var reserva := "agua" if tipo == "agua" else "oxigeno"
	var recuperado: int = recursos.estado().reservas[reserva] - anterior.reservas[reserva]
	_feedback = I18n.tf("lab.agua.ok", [recuperado]) if tipo == "agua" else I18n.t("lab.ox.ok")
	_feedback_ok = true
	_refrescar()
	trabajo_completado.emit(recuperado)


func _animar_ciclo() -> void:
	var proporcion := _sostener.progreso
	if tipo == "agua":
		_hielo.scale = Vector2.ONE * lerpf(1.0, 0.17, proporcion)
		_ubicar_hielo(CAMARA_HIELO - Vector2(0, proporcion * 46.0))
	for i in _particulas.size():
		var punto := fposmod(proporcion * 2.2 + i * 0.125, 1.0)
		var x := 570.0 + (i % 3) * 22.0 if tipo == "agua" else 830.0 + (i % 4) * 86.0
		var y := lerpf(207, 330, punto) if tipo == "agua" else lerpf(321, 225, punto)
		_particulas[i].position = Vector2(x, y)
		_particulas[i].modulate.a = 0.9 - punto * 0.5
		_particulas[i].show()
	_refrescar()


func _detener_efecto() -> void:
	_hielo.scale = Vector2.ONE
	if muestra_cargada:
		_ubicar_hielo(CAMARA_HIELO)
	for particula in _particulas:
		particula.hide()


func _ubicar_hielo(centro: Vector2) -> void:
	_hielo.position = centro - _hielo.size * 0.5


func _refrescar() -> void:
	var estado := recursos.estado()
	var reservas: Dictionary = estado.reservas
	var avance := floori(_sostener.progreso * 100)
	var instruccion := ""
	var disponible := false
	_hielo.visible = tipo == "agua" and estado.hielo > 0
	accion.show()
	if tipo == "agua":
		_titulo.text = I18n.t("lab.agua.tit_cargada" if muestra_cargada else "lab.agua.tit_vacia")
		_detalle.text = I18n.tf("lab.agua.detalle", [
			estado.hielo, reservas.agua, Recursos.LIMITES.agua])
		_guia.position = Vector2(CUBETA.position.x, 376) if not muestra_cargada else Vector2(427, 468)
		_guia.text = I18n.t("lab.agua.guia_cubeta" if not muestra_cargada else "lab.agua.guia_mando")
		accion.text = I18n.t("lab.agua.act_cargar" if not muestra_cargada else "lab.agua.act_filtrar")
		disponible = estado.hielo > 0
		if not disponible:
			instruccion = I18n.t("lab.agua.inst_sin_hielo")
		elif reservas.agua >= Recursos.LIMITES.agua:
			instruccion = I18n.t("lab.agua.inst_lleno")
			disponible = false
		elif reservas.energia < 2 and muestra_cargada:
			instruccion = I18n.t("lab.agua.inst_sin_energia")
			disponible = false
		else:
			instruccion = I18n.t("lab.agua.inst_filtrar" if muestra_cargada else "lab.agua.inst_cargar")
		if _sostener.activa():
			var paso_txt := I18n.t("lab.agua.derritiendo" if avance < 48 else "lab.agua.filtrando")
			_titulo.text = I18n.tf("tramo.progreso_pct", [paso_txt, avance])
	else:
		_titulo.text = I18n.t("lab.ox.tit_ok" if estado.aire_asegurado else "lab.ox.tit_valvula")
		_detalle.text = I18n.tf("lab.ox.detalle", [reservas.oxigeno, Recursos.LIMITES.oxigeno])
		_guia.position = Vector2(802, 433)
		_guia.text = I18n.t("lab.ox.guia_listo" if estado.aire_asegurado else "lab.ox.guia_valvula")
		accion.text = I18n.t("lab.ox.act_abrir")
		accion.visible = not estado.aire_asegurado
		disponible = not estado.aire_asegurado and reservas.energia >= 6 and reservas.agua >= 1
		instruccion = I18n.t("lab.ox.inst_listo_hacer" if disponible else "lab.ox.inst_falta")
		if estado.aire_asegurado:
			instruccion = I18n.t("lab.ox.inst_asegurado")
		elif _sostener.activa():
			_titulo.text = I18n.tf("lab.ox.estabilizando", [avance])
			_guia.text = I18n.tf("lab.ox.presion", [avance])
	accion.disabled = not disponible or not estado.en_curso
	mando.disabled = accion.disabled or (tipo == "agua" and not muestra_cargada)
	_nota.text = _feedback if not _feedback.is_empty() else instruccion
	_nota.add_theme_color_override("font_color", VERDE if not _feedback.is_empty() and (_feedback_ok or (tipo == "oxigeno" and estado.aire_asegurado)) else (AGUA if disponible else RIESGO))
