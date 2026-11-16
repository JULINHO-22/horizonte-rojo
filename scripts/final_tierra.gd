extends Control
## Vista previa autónoma. La campaña decidirá qué escena lanzar cuando se definan sus reglas.
const DialogoEscena := preload("res://scripts/dialogo_escena.gd")
const Viaje = preload("res://scripts/viaje_espacial.gd")
const ControlesTactiles := preload("res://scripts/controles_tactiles.gd")
const HANGAR := preload("res://assets/Finales/hangar.png")
const SALON := preload("res://assets/Finales/ceremonia.png")
const DIRECTORA := preload("res://assets/Finales/directora.png")
const MEDALLA := preload("res://assets/Finales/medalla.png")
const NOTICIERO := preload("res://assets/Finales/noticiero_regreso.png")
const TRIPULACION := [PuestoUmbra.TEO_NORMAL, PuestoUmbra.IRIS, PuestoUmbra.NORA]
const MARCHA := [PuestoUmbra.TEO_PASOS, PuestoUmbra.IRIS_PASOS, PuestoUmbra.NORA_PASOS]
const TAMANO := Vector2(1280, 720)
const RECONOCIMIENTO := 7.5
const LLEGADA := [
	[2.9, "Directora de misión", "final.llegada.0"],
	[5.7, "Directora de misión", "final.llegada.1"],
]
const LLEGADA_EMERGENCIA := [
	[2.9, "Directora de misión", "final.emg.0"],
	[5.7, "Iris", "final.emg.1"],
]
const ACTO := [
	[2.5, "Directora de misión", "final.acto.0"],
	[5.4, "Directora de misión", "final.acto.1"],
	[9.0, "Nora", "final.acto.2"],
]
const NOTICIA := [
	[0.25, "Presentadora", "final.noticia.0"],
	[4.95, "Presentadora", "final.noticia.1"],
	[10.0, "Presentadora", "final.noticia.2"],
]
const FIN_NOTICIA := 15.5
const VENTANA_NOTICIERO := Rect2(696, 133, 523, 277)

@export var mision_cumplida := false
var fase := "viaje"
var reloj := 0.0
var regreso: Control
var titulo: Label
var voz: Control
var salida: Button
var accion: Button
var recortes := {}
var indicacion: Label

func _ready() -> void:
	for textura in TRIPULACION + [DIRECTORA, MEDALLA]:
		recortes[textura] = [Rect2(textura.get_image().get_used_rect())]
	for textura in MARCHA:
		var imagen: Image = textura.get_image()
		var celda := imagen.get_size() / Vector2i(4, 2)
		var poses: Array[Rect2] = []
		for indice in range(8):
			var inicio := Vector2i(indice % 4, indice / 4) * celda
			var visible := imagen.get_region(Rect2i(inicio, celda)).get_used_rect()
			poses.append(Rect2(inicio + visible.position, visible.size))
		recortes[textura] = poses
	regreso = Viaje.new()
	regreso.regreso = true
	add_child(regreso)
	titulo = _etiqueta(Vector2(42, 38), 30)
	voz = DialogoEscena.new()
	add_child(voz)
	accion = Button.new()
	accion.position = Vector2(1006, 34)
	accion.custom_minimum_size = Vector2(232, 45)
	accion.text = I18n.t("final.btn.ir_llegada")
	accion.pressed.connect(_omitir)
	add_child(accion)
	salida = Button.new()
	salida.position = Vector2(1006, 93)
	salida.custom_minimum_size = Vector2(232, 45)
	salida.text = I18n.t("final.btn.salir_menu")
	salida.pressed.connect(_salir)
	add_child(salida)
	indicacion = _etiqueta(Vector2(1007, 150), 17)
	_presentar()

func _process(delta: float) -> void:
	reloj += delta
	if fase == "viaje":
		regreso.progreso = reloj / 6.0
		if reloj >= 6.0:
			_cambiar("hangar")
	elif fase == "hangar" and reloj >= (9.5 if mision_cumplida else 10.8):
		_escena_despues_del_hangar()
	elif fase == "ceremonia" and reloj >= 12.4:
		_cambiar("victoria")
	_presentar()
	queue_redraw()

func _input(evento: InputEvent) -> void:
	if evento is InputEventKey and evento.pressed and not evento.echo and evento.physical_keycode == KEY_SPACE:
		get_viewport().set_input_as_handled()
		_avanzar_dialogo()
	elif evento is InputEventScreenTouch and evento.pressed:
		if _punto_en_boton(evento.position):
			return
		ControlesTactiles.activar(true)
		get_viewport().set_input_as_handled()
		_avanzar_dialogo()

func _punto_en_boton(posicion: Vector2) -> bool:
	return (is_instance_valid(accion) and accion.visible and accion.get_global_rect().has_point(posicion)) or (is_instance_valid(salida) and salida.visible and salida.get_global_rect().has_point(posicion))

func _gui_input(evento: InputEvent) -> void:
	if evento is InputEventMouseButton and evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT and ControlesTactiles.activo():
		if evento.device != InputEvent.DEVICE_ID_EMULATION and not _punto_en_boton(evento.global_position):
			accept_event()
			_avanzar_dialogo()

func _unhandled_key_input(evento: InputEvent) -> void:
	if evento is InputEventKey and evento.pressed and not evento.echo:
		if evento.physical_keycode == KEY_ESCAPE and fase != "viaje":
			_salir()
		elif evento.physical_keycode in [KEY_E, KEY_ESCAPE] and accion.visible:
			_omitir()

func _salir() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.get_interface("location").reload()
	else:
		get_tree().change_scene_to_file.call_deferred("res://scenes/umbra.tscn")

func _lineas() -> Array:
	match fase:
		"hangar":
			return LLEGADA if mision_cumplida else LLEGADA_EMERGENCIA
		"ceremonia":
			return ACTO
		"noticia":
			return NOTICIA
	return []

func _avanzar_dialogo() -> void:
	for linea: Array in _lineas():
		if reloj < float(linea[0]):
			reloj = float(linea[0])
			_presentar()
			queue_redraw()
			return
	if fase not in ["victoria", "noticia"] or (fase == "noticia" and reloj < FIN_NOTICIA):
		_omitir()
	elif fase == "victoria" and reloj < 2.5:
		reloj = 2.5
		_presentar()
		queue_redraw()

func _escena_despues_del_hangar() -> void:
	_cambiar("ceremonia" if mision_cumplida else "noticia")

func _omitir() -> void:
	match fase:
		"viaje":
			_cambiar("hangar")
		"hangar":
			_escena_despues_del_hangar()
		"ceremonia":
			_cambiar("victoria")
		"noticia":
			if reloj < FIN_NOTICIA:
				reloj = FIN_NOTICIA
				_presentar()
				queue_redraw()
			else:
				_cambiar("viaje")
		"victoria":
			_cambiar("viaje")

func _cambiar(destino: String) -> void:
	fase = destino
	reloj = 0.0
	regreso.visible = fase == "viaje"
	regreso.progreso = 0.0
	_presentar()
	queue_redraw()

func _presentar() -> void:
	voz.hide()
	salida.visible = fase != "viaje"
	var en_tv := fase == "noticia"
	accion.position = Vector2(974, 529) if en_tv else Vector2(1006, 34)
	salida.position = Vector2(974, 583) if en_tv else Vector2(1006, 93)
	indicacion.position = Vector2(978, 635) if en_tv else Vector2(1007, 150)
	indicacion.text = I18n.t("final.pista.tocar" if ControlesTactiles.activo() else "final.pista.avanzar")
	indicacion.visible = fase != "victoria" and not (fase == "noticia" and reloj >= FIN_NOTICIA)
	titulo.position = Vector2(42, 38)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	titulo.add_theme_font_size_override("font_size", 30)
	titulo.modulate = Color.WHITE
	accion.visible = true
	match fase:
		"viaje":
			titulo.text = ""
			accion.text = I18n.t("final.btn.omitir_viaje")
		"hangar":
			titulo.text = I18n.t("final.tit.de_vuelta")
			accion.text = I18n.t("final.btn.omitir_llegada")
		"ceremonia":
			titulo.text = I18n.t("final.tit.acto")
			accion.text = I18n.t("final.btn.omitir_acto")
		"noticia":
			titulo.position = Vector2(693, 65)
			titulo.text = I18n.t("final.tit.noticia")
			accion.text = I18n.t("final.btn.omitir_noticia") if reloj < FIN_NOTICIA else I18n.t("final.btn.repetir")
			if reloj >= FIN_NOTICIA:
				_decir("Presentadora", I18n.t("final.noticia.cierre"), Vector2(100, 585))
				return
		"victoria":
			var entrada := smoothstep(0.55, 1.45, reloj)
			titulo.text = I18n.t("final.ganaste")
			titulo.position = Vector2(372, lerpf(459, 418, entrada))
			titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			titulo.add_theme_font_size_override("font_size", 65)
			titulo.modulate = Color("#ffda88")
			titulo.modulate.a = entrada
			accion.text = I18n.t("final.btn.repetir")
			accion.visible = reloj >= 2.5
	var lineas := _lineas()
	for i in range(lineas.size() - 1, -1, -1):
		var linea: Array = lineas[i]
		if reloj >= float(linea[0]):
			var origen := Vector2(897, 202)
			if fase == "noticia":
				origen = Vector2(100, 585)
			elif linea[1] in ["Iris", "Nora"]:
				origen = Vector2(492, 245)
			_decir(linea[1], I18n.t(linea[2]), origen)
			break

func _decir(nombre: String, texto: String, origen := Vector2(897, 202)) -> void:
	voz.position = origen
	var ancho := 790.0 if fase == "noticia" else DialogoEscena.ANCHO
	voz.frase.size.x = ancho
	voz.decir(nombre, texto)

func _draw() -> void:
	if fase == "viaje":
		return
	if fase == "victoria":
		draw_texture_rect(SALON, Rect2(Vector2.ZERO, TAMANO), false)
		draw_rect(Rect2(Vector2.ZERO, TAMANO), Color(0.025, 0.06, 0.09, smoothstep(0, 0.65, reloj) * 0.90))
		var entrada_medalla := smoothstep(0.15, 1.1, reloj)
		var giro := sin(reloj * 3.0) * (1.0 - entrada_medalla) * 0.24
		draw_set_transform(Vector2(640, lerpf(260, 382, entrada_medalla)), giro)
		_dibujar_sprite(MEDALLA, Vector2.ZERO, lerpf(38, 210, entrada_medalla))
		draw_set_transform(Vector2.ZERO)
		return
	if fase == "noticia":
		draw_texture_rect(NOTICIERO, Rect2(Vector2.ZERO, TAMANO), false)
		draw_set_transform(VENTANA_NOTICIERO.position, 0, VENTANA_NOTICIERO.size / TAMANO)
		_dibujar_recepcion(false)
		draw_set_transform(Vector2.ZERO)
		return
	_dibujar_recepcion(fase == "ceremonia")
	var entrada := 1.0 - smoothstep(0.0, 0.42, reloj)
	if entrada > 0:
		draw_rect(Rect2(Vector2.ZERO, TAMANO), Color(0.025, 0.04, 0.06, entrada))

func _dibujar_recepcion(ceremonia: bool) -> void:
	draw_texture_rect(SALON if ceremonia else HANGAR, Rect2(Vector2.ZERO, TAMANO), false)
	var piso := 605.0 if ceremonia else 568.0
	var destino_directora := Vector2(865 if ceremonia else 852, piso)
	_dibujar_sprite(DIRECTORA, destino_directora, 212)
	for indice in range(3):
		var destino := Vector2(420 + indice * 144, piso)
		var progreso := smoothstep(indice * 0.15, 2.55 + indice * 0.15, reloj)
		var inicio := Vector2(75 + indice * 118, piso)
		var pies := inicio.lerp(destino, progreso)
		var en_marcha := progreso > 0.0 and progreso < 1.0
		var textura: Texture2D = MARCHA[indice] if en_marcha else TRIPULACION[indice]
		var paso := int(floor(pies.x / 8.0)) % 8 if en_marcha else 0
		_dibujar_sprite(textura, pies, 186, paso)
		if ceremonia:
			_entregar_medalla(indice, destino_directora, pies)

func _entregar_medalla(indice: int, directora: Vector2, astronauta: Vector2) -> void:
	var inicio := RECONOCIMIENTO - indice * 0.6
	if reloj < inicio:
		return
	var fraccion := smoothstep(inicio, inicio + 0.45, reloj)
	var pecho := astronauta + Vector2(7, -108)
	var mano := directora + Vector2(-50, -154)
	var centro := mano.lerp(pecho, fraccion)
	centro.y -= sin(fraccion * PI) * 23.0
	_dibujar_sprite(MEDALLA, centro + Vector2(0, 15), 30)

func _dibujar_sprite(textura: Texture2D, pies: Vector2, altura: float, pose := 0) -> void:
	var recorte: Rect2 = recortes[textura][pose]
	if recorte.size.y <= 0:
		return
	var dimensiones := recorte.size * (altura / recorte.size.y)
	draw_texture_rect_region(textura, Rect2(pies - Vector2(dimensiones.x * 0.5, dimensiones.y), dimensiones), recorte)

func _etiqueta(origen: Vector2, fuente: int) -> Label:
	var etiqueta := Label.new()
	etiqueta.position = origen
	etiqueta.size = Vector2(535, 140)
	etiqueta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	etiqueta.add_theme_font_size_override("font_size", fuente)
	etiqueta.add_theme_color_override("font_color", Color("#fff1db"))
	etiqueta.add_theme_color_override("font_outline_color", Color("#0b1320"))
	etiqueta.add_theme_constant_override("outline_size", 8)
	add_child(etiqueta)
	return etiqueta
