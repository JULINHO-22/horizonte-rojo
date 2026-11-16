extends "res://scripts/estacion_umbra.gd"
## Banco de Plantas. El sol activo controla el reloj y Recursos conserva las bandejas.

signal cerrar_solicitado
signal cultivo_atendido(cosechado: bool)

const Recursos := preload("res://scripts/mecanicas/recursos_mision.gd")
const Sostener := preload("res://scripts/mecanicas/accion_sostenida.gd")
const CultivoPixel := preload("res://scripts/cultivo_pixel.gd")
const Equipo := preload("res://scripts/equipo_pixel.gd")
const Indicadores := preload("res://scripts/mecanicas/indicadores_refugio.gd")
const CULTIVOS := ["lechuga", "rabano", "tomate", "papa"]
const CENTROS := [230.0, 506.0, 777.0, 1058.0]
const SUELO := 429.0
const VERDE := Color("#c8ef9b")
const CLARO := Color("#dec6b4")
const APAGADO := Color("#d6c1b6")
const DURACION_RIEGO := 1.1

var recursos: Recursos
var semillas_disponibles := CULTIVOS
var cosecha_guardada := ""
var comer_guardado: Callable
var bandejas: Array[Button] = []
var accion: Button
var detalles: Label
var plantas_visuales: Array[CultivoPixel] = []

var _rotulos: Array[Label] = []
var _medidores: Array[ProgressBar] = []
var _seleccion := 0
var _semilla := ""
var _ocupado := ""
var _titulo_accion: Label
var _nota: Label
var _aviso := ""
var _semilla_pixel: TextureRect
var _riego := Sostener.new()
var _boquilla: TextureRect
var _gotas: Array[TextureRect] = []
var _avance_riego := _estilo_medidor(AGUA)
var _avance_cultivo := _estilo_medidor(VERDE)


func _ready() -> void:
	size = Vector2(1280, 720)
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_imagen(load("res://assets/huerto_banco.png"), Rect2(Vector2.ZERO, size))
	_sombra_superior()
	_texto(I18n.t("inv.titulo"), Rect2(76, 22, 790, 48), 35, PAPEL)
	_texto(I18n.t("inv.subtitulo"), Rect2(78, 70, 790, 34), 20, PAPEL)
	var volver := _boton(I18n.t("inv.volver"), Rect2(890, 76, 318, 38), 19, _pedir_cierre)
	volver.alignment = HORIZONTAL_ALIGNMENT_RIGHT

	var margen := StyleBoxEmpty.new()
	margen.content_margin_top = 148
	var fondo_medidor := _estilo_medidor(Color("#2c1c1b"))
	for i in CULTIVOS.size():
		var x: float = CENTROS[i]
		var planta := CultivoPixel.new()
		planta.position = Vector2(x, SUELO)
		add_child(planta)
		plantas_visuales.append(planta)
		var bandeja := _boton("%d  %s" % [i + 1, I18n.cultivo(CULTIVOS[i], true)], Rect2(x - 111, 313, 222, 200),
			23, _tocar_bandeja.bind(i))
		for estilo in ["normal", "hover", "pressed"]:
			bandeja.add_theme_stylebox_override(estilo, margen)
		bandeja.button_down.connect(_regar_bandeja.bind(i))
		bandeja.button_up.connect(_interrumpir_riego.bind(&"puntero"))
		bandejas.append(bandeja)
		_rotulos.append(_texto("", Rect2(x - 126, 520, 252, 34), 20, PAPEL, HORIZONTAL_ALIGNMENT_CENTER))
		var medidor := ProgressBar.new()
		medidor.position = Vector2(x - 58, 558)
		medidor.max_value = 1.0
		medidor.step = 0.01
		medidor.show_percentage = false
		medidor.mouse_filter = Control.MOUSE_FILTER_IGNORE
		medidor.add_theme_stylebox_override("background", fondo_medidor)
		medidor.add_theme_stylebox_override("fill", _avance_cultivo)
		add_child(medidor)
		medidor.size = Vector2(116, 5)
		_medidores.append(medidor)

	detalles = _texto("", Rect2(76, 632, 716, 36), 19, CLARO)
	_nota = _texto("", Rect2(76, 668, 1132, 32), 18, AGUA)
	accion = _boton("", Rect2(798, 601, 411, 52), 25, _atender)
	accion.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	accion.add_theme_color_override("font_color", ORO)
	accion.button_down.connect(_iniciar_riego.bind(&"puntero"))
	accion.button_up.connect(_interrumpir_riego.bind(&"puntero"))
	_titulo_accion = _texto("", Rect2(76, 584, 716, 46), 30, PAPEL)
	var gota := Equipo.indicador(Indicadores.GOTA)
	for i in 7:
		var sprite := _imagen(gota, Rect2(0, 0, 13, 18))
		sprite.hide()
		_gotas.append(sprite)
	_boquilla = _imagen(Equipo.boquilla(), Rect2(0, 0, 116, 103))
	_boquilla.hide()
	_refrescar(false)
	recursos.cambiado.connect(_refrescar)


func _process(delta: float) -> void:
	if not _riego.activa():
		return
	if _riego.avanzar(delta):
		_ocultar_riego()
		_regar(_semilla)
	else:
		_mostrar_riego()


func _notification(que: int) -> void:
	if que in [NOTIFICATION_DISABLED, NOTIFICATION_APPLICATION_FOCUS_OUT] and is_node_ready():
		_interrumpir_riego(&"")


func _unhandled_key_input(evento: InputEvent) -> void:
	if not evento is InputEventKey or evento.echo:
		return
	var tecla: Key = evento.keycode if evento.keycode != KEY_NONE else evento.physical_keycode
	if not evento.pressed:
		if tecla in [KEY_E, KEY_ENTER]:
			_interrumpir_riego(&"teclado")
		return
	if tecla not in [KEY_ESCAPE, KEY_1, KEY_2, KEY_3, KEY_4, KEY_E, KEY_ENTER]:
		return
	get_viewport().set_input_as_handled()
	match tecla:
		KEY_ESCAPE:
			_pedir_cierre()
		KEY_1, KEY_2, KEY_3, KEY_4:
			_elegir(tecla - KEY_1)
		KEY_E, KEY_ENTER:
			if _semilla == CULTIVOS[_seleccion]:
				_iniciar_riego(&"teclado")
			else:
				_atender()


func _elegir(indice: int) -> void:
	_interrumpir_riego(&"")
	_seleccion = indice
	_aviso = ""
	_refrescar()


func _tocar_bandeja(indice: int) -> void:
	if indice == _seleccion:
		_atender()
	else:
		_elegir(indice)


func _pedir_cierre() -> void:
	cerrar_solicitado.emit()


func _refrescar(animar := true) -> void:
	var estado := recursos.estado()
	for i in CULTIVOS.size():
		var cultivo: String = CULTIVOS[i]
		var restante: float = estado.bandejas.get(cultivo, -1.0)
		if _ocupado != cultivo:
			var etapa := -1
			if restante >= 0.0:
				etapa = CultivoPixel.etapa_del_cultivo(restante, Recursos.CULTIVOS[cultivo].segundos)
			elif cultivo == cosecha_guardada:
				etapa = 2
			plantas_visuales[i].mostrar(cultivo, etapa, animar)
		var rotulo := I18n.t("inv.rot.tierra_lista")
		var color := CLARO
		var regando := cultivo == _semilla and _riego.activa()
		if cultivo == cosecha_guardada or restante == 0.0:
			rotulo = I18n.t("inv.rot.lista")
			color = VERDE
		elif restante > 0.0:
			var fase := I18n.t("inv.rot.brote" if plantas_visuales[i].etapa <= 0 else "inv.rot.creciendo")
			rotulo = "%s · 00:%02d" % [fase, ceili(restante)]
			color = VERDE
		elif regando:
			rotulo = I18n.tf("inv.rot.regando", [floori(_riego.progreso * 100)])
			color = AGUA
		elif cultivo == _semilla:
			rotulo = I18n.t("inv.rot.semilla")
			color = AGUA
		elif cultivo not in semillas_disponibles:
			rotulo = I18n.t("inv.rot.sin_semillas")
			color = APAGADO
		if _rotulos[i].text != rotulo:
			_rotulos[i].text = rotulo
			_rotulos[i].add_theme_color_override("font_color", color)
		_medidores[i].visible = restante >= 0.0 or regando
		if _medidores[i].visible:
			var estilo := _avance_riego if regando else _avance_cultivo
			if _medidores[i].get_theme_stylebox("fill") != estilo:
				_medidores[i].add_theme_stylebox_override("fill", estilo)
			_medidores[i].value = _riego.progreso if regando else 1.0 - restante / Recursos.CULTIVOS[cultivo].segundos
		var color_nombre := ORO if i == _seleccion else PAPEL
		if bandejas[i].get_theme_color("font_color") != color_nombre:
			bandejas[i].add_theme_color_override("font_color", color_nombre)
	_actualizar_accion(estado)


func _actualizar_accion(estado: Dictionary) -> void:
	var cultivo: String = CULTIVOS[_seleccion]
	var ficha: Dictionary = Recursos.CULTIVOS[cultivo]
	var restante: float = estado.bandejas.get(cultivo, -1.0)
	var etapa := I18n.t("inv.etapa.preparar")
	var texto_accion := I18n.t("inv.act.colocar")
	var disponibles := I18n.t("inv.disp.colocar")
	var habilitada: bool = estado.en_curso and _ocupado.is_empty()
	detalles.text = I18n.tf("inv.det.costo", [
		ficha.energia, int(ficha.segundos), ficha.alimento])
	if cultivo == _ocupado and restante < 0.0:
		etapa = I18n.t("inv.etapa.recogiendo")
		texto_accion = ""
		detalles.text = I18n.t("inv.det.recogiendo")
		disponibles = ""
	elif cultivo == cosecha_guardada or restante == 0.0:
		etapa = I18n.t("inv.etapa.lista")
		texto_accion = I18n.t("inv.act.recoger")
		var espacio := Recursos.LIMITES.alimento - int(estado.reservas.alimento)
		detalles.text = I18n.tf("inv.det.recoger", [
			estado.reservas.alimento, Recursos.LIMITES.alimento, mini(ficha.alimento, espacio)])
		disponibles = I18n.t("inv.disp.llena") if espacio == 0 else ""
		habilitada = habilitada and espacio > 0
	elif restante > 0.0:
		etapa = I18n.t("inv.etapa.creciendo")
		texto_accion = ""
		detalles.text = I18n.tf("inv.det.creciendo", [ceili(restante)])
		disponibles = ""
	elif cultivo not in semillas_disponibles:
		etapa = I18n.t("inv.etapa.sin_semillas")
		texto_accion = ""
		detalles.text = I18n.t("inv.det.sin_semillas")
		disponibles = ""
	else:
		if cultivo == _semilla:
			etapa = I18n.t("inv.etapa.regando" if _riego.activa() else "inv.etapa.necesita_agua")
			texto_accion = I18n.t("inv.act.regar")
			disponibles = I18n.t("inv.disp.regar")
		if estado.reservas.agua < 1 or estado.reservas.energia < ficha.energia:
			disponibles = I18n.tf("inv.disp.falta", [ficha.energia])
			habilitada = false
	_titulo_accion.text = "%s  ·  %s" % [I18n.cultivo(cultivo, true), etapa]
	accion.text = I18n.tf("inv.act.sufijo_e", [texto_accion])
	accion.visible = not texto_accion.is_empty()
	accion.disabled = not habilitada
	_nota.text = _aviso if not _aviso.is_empty() else disponibles


func _atender() -> void:
	if not accion.visible or accion.disabled:
		return
	var cultivo: String = CULTIVOS[_seleccion]
	var estado := recursos.estado()
	_aviso = ""
	if cultivo == cosecha_guardada or estado.bandejas.get(cultivo, -1.0) == 0.0:
		_recoger(cultivo, estado)
	elif cultivo != _semilla:
		_colocar_semilla(cultivo)


func _colocar_semilla(cultivo: String) -> void:
	_semilla = cultivo
	_retirar_semilla()
	# Una pequeña hebra de la textura de la patata sirve como semilla en el suelo.
	var grano := AtlasTexture.new()
	grano.atlas = CultivoPixel.ATLAS
	grano.region = Rect2(872, 1114, 104, 75)
	var sitio := Vector2(CENTROS[_seleccion] - 9.0, SUELO - 9.0)
	_semilla_pixel = _imagen(grano, Rect2(sitio - Vector2(0, 38), Vector2(18, 13)))
	_semilla_pixel.modulate = Color("#b97a50")
	var caida := _semilla_pixel.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	caida.tween_property(_semilla_pixel, "position", sitio, 0.24)
	_refrescar()


func _regar_bandeja(indice: int) -> void:
	if indice == _seleccion:
		_iniciar_riego(&"puntero")


func _iniciar_riego(fuente: StringName) -> void:
	if not accion.disabled and _semilla == CULTIVOS[_seleccion] and _riego.iniciar(fuente, DURACION_RIEGO):
		_aviso = ""
		_mostrar_riego()


func _interrumpir_riego(fuente: StringName) -> void:
	if _riego.soltar(fuente):
		_ocultar_riego()
		_refrescar()


func _mostrar_riego() -> void:
	var x: float = CENTROS[_seleccion] + lerpf(-44.0, 56.0, _riego.progreso)
	_boquilla.position = Vector2(x, SUELO - 170)
	_boquilla.show()
	for i in _gotas.size():
		var gota := _gotas[i]
		var caida := fposmod(_riego.progreso * 3.5 + i * 0.16, 1.0)
		gota.position = Vector2(x + 14.0 - caida * 32.0, SUELO - 76.0 + caida * 65.0)
		gota.modulate.a = 1.0 - smoothstep(0.72, 1.0, caida)
		gota.show()
	_refrescar()


func _ocultar_riego() -> void:
	_boquilla.hide()
	for gota in _gotas:
		gota.hide()


func _regar(cultivo: String) -> void:
	if not recursos.sembrar(cultivo):
		_aviso = I18n.t("inv.aviso.no_regar")
		_refrescar()
		return
	_semilla = ""
	_retirar_semilla()
	_refrescar()
	cultivo_atendido.emit(false)


func _recoger(cultivo: String, anterior: Dictionary) -> void:
	_ocupado = cultivo
	var guardada := cultivo == cosecha_guardada
	var comida: bool = comer_guardado.call(cultivo) if guardada else recursos.comer(cultivo)
	if not comida:
		_ocupado = ""
		_aviso = I18n.t("inv.aviso.no_recoger")
		_refrescar()
		return
	var ganancia: int = recursos.estado().reservas.alimento - anterior.reservas.alimento
	if guardada:
		cosecha_guardada = ""
	var planta := plantas_visuales[_seleccion]
	planta.levantar().connect(_terminar_cosecha.bind(planta, ganancia), CONNECT_ONE_SHOT)
	_refrescar()
	cultivo_atendido.emit(true)


func _terminar_cosecha(planta: CultivoPixel, ganancia: int) -> void:
	planta.mostrar("", -1, false)
	_ocupado = ""
	_aviso = I18n.tf("inv.aviso.recogida", [ganancia])
	_refrescar(false)


func _retirar_semilla() -> void:
	if is_instance_valid(_semilla_pixel):
		_semilla_pixel.hide()
		_semilla_pixel.queue_free()


func _estilo_medidor(color: Color) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = color
	return estilo
