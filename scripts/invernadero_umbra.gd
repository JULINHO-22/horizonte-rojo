extends Control
## Banco de Plantas. El sol activo controla el reloj y Recursos conserva las bandejas.

signal cerrar_solicitado
signal cultivo_atendido(cosechado: bool)

const Recursos := preload("res://scripts/mecanicas/recursos_mision.gd")
const AccionEscena := preload("res://scripts/accion_escena.gd")
const CultivoPixel := preload("res://scripts/cultivo_pixel.gd")
const Indicadores := preload("res://scripts/mecanicas/indicadores_refugio.gd")
const CULTIVOS := ["lechuga", "rabano", "tomate", "papa"]
const NOMBRES := ["Lechuga", "Rábano", "Tomate", "Papa"]
const CENTROS := [230.0, 506.0, 777.0, 1058.0]
const SUELO := 429.0
const PAPEL := Color("#fff1db")
const VERDE := Color("#c8ef9b")
const AGUA := Color("#a2e5ff")
const ORO := Color("#ffcd91")
const CLARO := Color("#dec6b4")
const APAGADO := Color("#d6c1b6")

var recursos: Recursos
var semillas_disponibles := CULTIVOS
var cosecha_guardada := ""
var comer_guardado: Callable
var bandejas: Array[Button] = []
var accion: Button
var detalles: Label
var plantas_visuales: Array[CultivoPixel] = []

var _rotulos: Array[Label] = []
var _seleccion := 0
var _semilla := ""
var _ocupado := ""
var _titulo_accion: Label
var _nota: Label
var _aviso := ""
var _gota := AtlasTexture.new()
var _semilla_pixel: TextureRect


func _ready() -> void:
	size = Vector2(1280, 720)
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_imagen(load("res://assets/huerto_banco.png"), Rect2(Vector2.ZERO, size))
	_sombra_superior()
	_texto("Invernadero de Umbra", Rect2(76, 22, 790, 48), 35, PAPEL)
	_texto("Elige una bandeja con 1–4 o con el ratón.", Rect2(78, 70, 790, 34), 20, PAPEL)
	_boton("Volver a Plantas · Esc", Rect2(990, 76, 218, 38), 19, _pedir_cierre)

	var margen := StyleBoxEmpty.new()
	margen.content_margin_top = 164
	for i in CULTIVOS.size():
		var x: float = CENTROS[i]
		var planta := CultivoPixel.new()
		planta.position = Vector2(x, SUELO)
		add_child(planta)
		plantas_visuales.append(planta)
		var bandeja := _boton("%d  %s" % [i + 1, NOMBRES[i]], Rect2(x - 111, 313, 222, 200),
			25, _tocar_bandeja.bind(i))
		for estilo in ["normal", "hover", "pressed"]:
			bandeja.add_theme_stylebox_override(estilo, margen)
		bandejas.append(bandeja)
		_rotulos.append(_texto("", Rect2(x - 126, 518, 252, 34), 20, PAPEL, HORIZONTAL_ALIGNMENT_CENTER))

	detalles = _texto("", Rect2(76, 632, 716, 36), 19, CLARO)
	_nota = _texto("", Rect2(76, 668, 1132, 32), 18, AGUA)
	accion = _boton("", Rect2(798, 601, 411, 52), 25, _atender)
	accion.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	accion.add_theme_color_override("font_color", ORO)
	_titulo_accion = _texto("", Rect2(76, 584, 716, 46), 30, PAPEL)
	_gota.atlas = Indicadores.ICONOS
	var volumen := Indicadores.ICONOS.get_size()
	_gota.region = Rect2(Indicadores.GOTA.position * volumen, Indicadores.GOTA.size * volumen)
	_gota.filter_clip = true
	_refrescar(false)
	recursos.cambiado.connect(_refrescar)


func _unhandled_key_input(evento: InputEvent) -> void:
	if not evento is InputEventKey or not evento.pressed or evento.echo:
		return
	var tecla: Key = evento.keycode if evento.keycode != KEY_NONE else evento.physical_keycode
	if tecla not in [KEY_ESCAPE, KEY_1, KEY_2, KEY_3, KEY_4, KEY_E, KEY_ENTER]:
		return
	get_viewport().set_input_as_handled()
	match tecla:
		KEY_ESCAPE:
			_pedir_cierre()
		KEY_1, KEY_2, KEY_3, KEY_4:
			_elegir(tecla - KEY_1)
		KEY_E, KEY_ENTER:
			_atender()


func _elegir(indice: int) -> void:
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
		var rotulo := "Tierra lista"
		var color := CLARO
		if cultivo == cosecha_guardada or restante == 0.0:
			rotulo = "Lista para recoger"
			color = VERDE
		elif restante > 0.0:
			var fase := "Brote" if plantas_visuales[i].etapa <= 0 else "En crecimiento"
			if cultivo == _ocupado:
				fase = "Regando"
			rotulo = "%s · 00:%02d" % [fase, ceili(restante)]
			color = AGUA if fase == "Regando" else VERDE
		elif cultivo == _semilla:
			rotulo = "Semilla colocada"
			color = AGUA
		elif cultivo not in semillas_disponibles:
			rotulo = "Sin semillas"
			color = APAGADO
		if _rotulos[i].text != rotulo:
			_rotulos[i].text = rotulo
			_rotulos[i].add_theme_color_override("font_color", color)
			bandejas[i].tooltip_text = "%s · %s" % [NOMBRES[i], rotulo]
		var color_nombre := ORO if i == _seleccion else PAPEL
		if bandejas[i].get_theme_color("font_color") != color_nombre:
			bandejas[i].add_theme_color_override("font_color", color_nombre)
	_actualizar_accion(estado)


func _actualizar_accion(estado: Dictionary) -> void:
	var cultivo: String = CULTIVOS[_seleccion]
	var ficha: Dictionary = Recursos.CULTIVOS[cultivo]
	var restante: float = estado.bandejas.get(cultivo, -1.0)
	var etapa := "Preparar la siembra"
	var texto_accion := "Colocar semilla"
	var disponibles := "Coloca una semilla con E o toca la bandeja elegida."
	var habilitada: bool = estado.en_curso and _ocupado.is_empty()
	detalles.text = "%d energía + 1 agua  ·  %d s  ·  Hasta +%d comida" % [
		ficha.energia, int(ficha.segundos), ficha.alimento]
	if cultivo == _ocupado and restante < 0.0:
		etapa = "Recogiendo la cosecha"
		texto_accion = ""
		detalles.text = "La cosecha se suma a tu reserva de comida."
		disponibles = ""
	elif cultivo == cosecha_guardada or restante == 0.0:
		etapa = "Cosecha lista"
		texto_accion = "Recoger y comer"
		var espacio := Recursos.LIMITES.alimento - int(estado.reservas.alimento)
		detalles.text = "Comida %d/%d  ·  Recuperas +%d" % [
			estado.reservas.alimento, Recursos.LIMITES.alimento, mini(ficha.alimento, espacio)]
		disponibles = "Comida al máximo. Deja la cosecha en la bandeja." if espacio == 0 else ""
		habilitada = habilitada and espacio > 0
	elif restante > 0.0:
		etapa = "Regando" if cultivo == _ocupado else "Creciendo"
		texto_accion = ""
		detalles.text = "Quedan %d s. Puedes volver al pasillo mientras crece." % ceili(restante)
		disponibles = ""
	elif cultivo not in semillas_disponibles:
		etapa = "Sin semillas de este cultivo"
		texto_accion = ""
		detalles.text = "Elige otra bandeja para sembrar."
		disponibles = ""
	else:
		if cultivo == _semilla:
			etapa = "La semilla necesita agua"
			texto_accion = "Regar la bandeja"
			disponibles = "Toca la tierra o pulsa E para regar."
		if estado.reservas.agua < 1 or estado.reservas.energia < ficha.energia:
			disponibles = "Revisa las reservas. Esta bandeja necesita %d energía y 1 agua." % ficha.energia
			habilitada = false
	_titulo_accion.text = "%s  ·  %s" % [NOMBRES[_seleccion], etapa]
	accion.text = texto_accion + " · E"
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
	elif cultivo == _semilla:
		_regar(cultivo)
	else:
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


func _regar(cultivo: String) -> void:
	var x: float = CENTROS[_seleccion]
	_ocupado = cultivo
	if not recursos.sembrar(cultivo):
		_ocupado = ""
		_aviso = "Revisa que tengas agua, energía y una bandeja libre."
		_refrescar()
		return
	_semilla = ""
	_retirar_semilla()
	var chorro := create_tween().set_parallel()
	for i in 6:
		var inicio := Vector2(x - 30 + (i % 3) * 22.0, SUELO - 72.0)
		var gota := _imagen(_gota, Rect2(inicio, Vector2(17, 23)))
		gota.modulate.a = 0.0
		var demora := i * 0.055
		chorro.tween_property(gota, "modulate:a", 1.0, 0.05).set_delay(demora)
		chorro.tween_property(gota, "position:y", SUELO - 3.0, 0.22).set_delay(demora)
		chorro.tween_property(gota, "modulate:a", 0.0, 0.10).set_delay(demora + 0.22).from(1.0)
		chorro.tween_callback(gota.queue_free).set_delay(demora + 0.32)
	chorro.finished.connect(_terminar_riego)
	_refrescar()
	cultivo_atendido.emit(false)


func _terminar_riego() -> void:
	_ocupado = ""
	_refrescar()


func _recoger(cultivo: String, anterior: Dictionary) -> void:
	_ocupado = cultivo
	var guardada := cultivo == cosecha_guardada
	var comida: bool = comer_guardado.call(cultivo) if guardada else recursos.comer(cultivo)
	if not comida:
		_ocupado = ""
		_aviso = "Comprueba que la cosecha esté lista y quede espacio para comer."
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
	_aviso = "Cosecha recogida  ·  +%d comida" % ganancia
	_refrescar(false)


func _retirar_semilla() -> void:
	if is_instance_valid(_semilla_pixel):
		_semilla_pixel.hide()
		_semilla_pixel.queue_free()


func _sombra_superior() -> void:
	var degradado := Gradient.new()
	degradado.colors = PackedColorArray([Color("#160f16e8"), Color("#160f1600")])
	var textura := GradientTexture2D.new()
	textura.gradient = degradado
	textura.fill_to = Vector2(0, 1)
	_imagen(textura, Rect2(0, 0, size.x, 154))


func _imagen(textura: Texture2D, marco: Rect2) -> TextureRect:
	var imagen := TextureRect.new()
	imagen.texture = textura
	imagen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagen.position = marco.position
	imagen.size = marco.size
	imagen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(imagen)
	return imagen


func _texto(contenido: String, marco: Rect2, tamano: int, color: Color,
		alineacion := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var rotulo := Label.new()
	rotulo.text = contenido
	rotulo.position = marco.position
	rotulo.size = marco.size
	rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rotulo.horizontal_alignment = alineacion
	rotulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rotulo.add_theme_font_size_override("font_size", tamano)
	rotulo.add_theme_color_override("font_color", color)
	rotulo.add_theme_color_override("font_outline_color", Color("#1b1114"))
	rotulo.add_theme_constant_override("outline_size", 7)
	add_child(rotulo)
	return rotulo


func _boton(contenido: String, marco: Rect2, tamano: int, al_pulsar: Callable) -> Button:
	var control := Button.new()
	control.text = contenido
	control.position = marco.position
	control.size = marco.size
	control.focus_mode = Control.FOCUS_NONE
	control.add_theme_font_size_override("font_size", tamano)
	AccionEscena.aplicar(control)
	control.pressed.connect(al_pulsar)
	add_child(control)
	return control
