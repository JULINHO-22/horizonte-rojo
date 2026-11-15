extends Control
## Presentación del guion aprobado. Las actividades se conectarán después.
const Campana := preload("res://scripts/campana_narrativa.gd")
const Viaje := preload("res://scripts/viaje_espacial.gd")
const AREA := Rect2(0, 0, 1280, 720)
const TINTA := Color("#101c28")
const PAPEL := Color("#fff1db")
const CIAN := Color("#83eadc")
const DURACION_IDA := 5.4
const DURACION_ATERRIZAJE := 2.6
const DURACION_REGRESO := 9.0
const FICHAS := {
	"energia": "La energía mantiene funcionando los equipos. Aquí se reparte la reserva del refugio.",
	"agua": "Aquí se limpia y comprueba el agua antes de usarla. El hielo recién recogido todavía no se puede beber.",
	"cultivos": "Estas plantas necesitan agua, luz y tiempo para crecer.",
	"radio": "Control conecta las salas y recibe los mensajes de Tierra. La respuesta tarda en llegar.",
	"cierre": "Esta sala tiene dos puertas: cerramos una antes de abrir la otra para conservar el aire del refugio.",
	"taller": "Aquí se revisan los trajes y se guardan herramientas y repuestos.",
}
var campana = Campana.new()
var fase := "portada"
var reloj := 0.0
var posicion := Vector2(220, PuestoUmbra.SUELO)
var puesto: PuestoUmbra
var viaje: Control
var capa: Control
var titulo: Label
var voz: Label
var pista: Label
var boton: Button
var velo: ColorRect
var nave_salida: TextureRect
var plano := false
var aviso_tiempo := 0.0
var segundos_guardado := 0.0
var restaurado := {}

func _ready() -> void:
	get_window().min_size = Vector2i(800, 450)
	restaurado = campana.cargar()
	if OS.has_feature("web") and restaurado.is_empty():
		_cambiar("ida")
	else:
		_mostrar()

func _process(delta: float) -> void:
	reloj += delta
	aviso_tiempo = maxf(0, aviso_tiempo - delta)
	match fase:
		"ida", "regreso":
			var duracion := DURACION_IDA if fase == "ida" else DURACION_REGRESO
			viaje.progreso = reloj / duracion
			titulo.text = viaje.etapa()
			if reloj >= duracion:
				_cambiar("aterrizaje" if fase == "ida" else "llegada_tierra")
		"aterrizaje":
			puesto.tiempo = minf(reloj / DURACION_ATERRIZAJE, 1.0) * PuestoUmbra.FIN_LLEGADA
			velo.color.a = 1.0 - smoothstep(0, 0.28, reloj)
			puesto.queue_redraw()
			if reloj >= DURACION_ATERRIZAJE:
				_iniciar_caminata()
		"base", "camino_base", "camino_nave":
			_caminar(delta)
		"esclusa":
			puesto.avance_esclusa = reloj
			puesto.punto.y = 440 - 43 * smoothstep(0.68, 1.36, reloj) - 49 * smoothstep(2.6, 3.45, reloj)
			puesto.caminando = (reloj > 0.68 and reloj < 1.36) or (reloj > 2.6 and reloj < 3.45)
			puesto.paso = fposmod(reloj * 2.5, 1.0)
			puesto.actualizar_camara(delta)
			puesto.queue_redraw()
			voz.text = "Pluto · Ya hay aire. Se abre la puerta interior." if reloj > 2.22 else "Pluto · Primero cerramos la puerta exterior para conservar el aire."
			if reloj >= 3.5:
				posicion = puesto.punto
				_cambiar("base")
				_guardar()
		"noche":
			velo.color.a = smoothstep(0, 3.0, reloj)
			voz.modulate.a = 1.0 - smoothstep(1.6, 2.9, reloj)
			if reloj >= 3.0:
				campana.terminar_noche()
				posicion = PuestoUmbra.TERMINALES.dormitorio
				_guardar("base")
				_cambiar("amanecer")
		"amanecer":
			velo.color.a = 1.0 - smoothstep(0, 1.5, reloj)
			if reloj >= 1.5:
				_cambiar("base")
		"despegue":
			nave_salida.position.y = lerpf(275.0, -220.0, smoothstep(1, 5.5, reloj))
			if reloj >= 6:
				_cambiar("regreso")
		"llegada_tierra":
			velo.color.a = clampf(reloj, 0, 1)
			if reloj >= 1.0:
				_cambiar("epilogo")
				_guardar()
		"epilogo":
			if reloj >= 10:
				boton.visible = true

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.physical_keycode == KEY_E or event.physical_keycode == KEY_ENTER:
		_accion()
	elif event.physical_keycode == KEY_M and fase == "base":
		plano = not plano
		puesto.plano = plano
	elif event.physical_keycode == KEY_ESCAPE and fase in ["ida", "aterrizaje"]:
		_iniciar_caminata()

func _caminar(delta: float) -> void:
	var direccion := Vector2(
		int(Input.is_physical_key_pressed(KEY_D) or Input.is_action_pressed("ui_right")) - int(Input.is_physical_key_pressed(KEY_A) or Input.is_action_pressed("ui_left")),
		int(Input.is_physical_key_pressed(KEY_S) or Input.is_action_pressed("ui_down")) - int(Input.is_physical_key_pressed(KEY_W) or Input.is_action_pressed("ui_up")))
	puesto.avanzar(direccion.normalized(), minf(delta, 0.05))
	puesto.actualizar_camara(delta)
	puesto.tiempo += delta
	posicion = puesto.punto
	puesto.queue_redraw()
	segundos_guardado += delta
	if segundos_guardado > 3.0:
		_guardar()
		segundos_guardado = 0
	_actualizar_guia()
	if fase == "camino_base" and absf(posicion.x - PuestoUmbra.ESCLUSA.x) < 14:
		_cambiar("esclusa")

func _actualizar_guia() -> void:
	boton.visible = false
	if fase == "camino_base":
		pista.text = "A / D o flechas   →   Refugio"
		voz.visible = reloj < 6.0
	elif fase == "camino_nave":
		pista.text = "A / D o flechas · Vuelve por el camino hasta la nave"
		if absf(posicion.x - 220) < 30:
			boton.visible = true
			boton.text = "E · Subir a la nave"
			_ubicar_accion()
		return
	elif fase == "base":
		pista.text = "WASD o flechas  /  M: plano" if reloj < 6.0 else ""
		var cerca := puesto.terminal_cercana()
		if cerca == "dormitorio" and not campana.listo_para_regresar():
			boton.text = "E · Descansar"
			boton.visible = true
		elif cerca == "radio" and campana.listo_para_regresar():
			boton.text = "E · Revisar la ruta de regreso"
			boton.visible = true
		elif cerca == "cierre" and campana.listo_para_regresar():
			boton.text = "E · Salir hacia la nave"
			boton.visible = true
		elif not cerca.is_empty() and FICHAS.has(cerca):
			boton.text = "E · " + PuestoUmbra.NOMBRES.get(cerca, "Entrada").capitalize()
			boton.visible = true
		if boton.visible:
			_ubicar_accion()
		if aviso_tiempo <= 0:
			voz.text = "Pluto · El dormitorio está por el pasillo derecho, arriba." if not campana.listo_para_regresar() else "Pluto · Revisa la ruta en Control antes de salir."
			voz.visible = reloj < 6.0
		else:
			voz.visible = true

func _accion() -> void:
	match fase:
		"portada":
			if not restaurado.is_empty():
				posicion = restaurado.posicion
				_cambiar(restaurado.fase)
			else:
				_cambiar("ida")
		"ida", "aterrizaje":
			_iniciar_caminata()
		"base":
			var cerca := puesto.terminal_cercana()
			if cerca == "dormitorio" and not campana.listo_para_regresar():
				_guardar()
				_cambiar("noche")
			elif cerca == "radio" and campana.listo_para_regresar():
				voz.text = "Iris · La ruta está preparada. Salgamos juntos: la nave nos espera a la izquierda del refugio."
				puesto.objetivo_mision = "cierre"
				aviso_tiempo = 9
			elif cerca == "cierre" and campana.listo_para_regresar():
				posicion = PuestoUmbra.ESCLUSA
				_cambiar("camino_nave")
				_guardar()
			elif FICHAS.has(cerca):
				voz.text = "Pluto · " + FICHAS[cerca]
				aviso_tiempo = 9
		"camino_nave":
			if absf(posicion.x - 220) < 30:
				_cambiar("pilotaje")
		"pilotaje":
			_cambiar("despegue")
		"epilogo":
			if reloj >= 10:
				_reiniciar()

func _iniciar_caminata() -> void:
	posicion = Vector2(240, PuestoUmbra.SUELO)
	_cambiar("camino_base")
	_guardar()

func _ubicar_accion() -> void:
	# La acción sigue al personaje sin taparle el traje.
	var suelo := puesto.proyectar_suelo(puesto.punto)
	boton.position = Vector2(clampf(suelo.x - boton.size.x / 2.0, 24, 1256 - boton.size.x),
		clampf(suelo.y + 18, 240, 650))

func _reiniciar() -> void:
	campana.borrar()
	campana = Campana.new()
	restaurado = {}
	posicion = Vector2(220, PuestoUmbra.SUELO)
	_cambiar("ida")

func _guardar(fase_guardada := "") -> void:
	var error: Error = campana.guardar(fase if fase_guardada.is_empty() else fase_guardada, posicion)
	if error != OK:
		push_warning("No se pudo guardar la narrativa: %s" % error_string(error))

func _cambiar(destino: String) -> void:
	fase = destino
	reloj = 0
	_mostrar()

func _mostrar() -> void:
	if is_instance_valid(capa):
		remove_child(capa)
		capa.queue_free()
	puesto = null
	viaje = null
	capa = Control.new()
	add_child(capa)
	match fase:
		"ida", "regreso", "llegada_tierra", "pilotaje":
			viaje = Viaje.new()
			viaje.regreso = fase != "ida"
			viaje.progreso = 1.0 if fase == "llegada_tierra" else 0.0
			capa.add_child(viaje)
		"base", "noche", "amanecer", "esclusa":
			_crear_mapa(true)
			if fase == "esclusa":
				puesto.esclusa_activa = true
				puesto.punto = Vector2(402, 440)
				puesto.actualizar_camara(2)
		"aterrizaje", "camino_base", "camino_nave":
			_crear_mapa(false)
			puesto.aterrizaje = fase == "aterrizaje"
			puesto.bienvenida_percy = fase != "aterrizaje"
		"despegue":
			_imagen(PuestoUmbra.SENDERO, AREA)
			nave_salida = _imagen(PuestoUmbra.NAVE, Rect2(280, 275, 170, 260), true)
		"epilogo":
			_imagen(PuestoUmbra.CENTRO_AGUA, AREA)
			_sombra(Rect2(0, 0, 1280, 720), Color(0.03, 0.07, 0.12, 0.78))
			_imagen(PuestoUmbra.NORA, Rect2(190, 235, 175, 270), true)
			_imagen(PuestoUmbra.IRIS, Rect2(390, 235, 175, 270), true)
			_imagen(PuestoUmbra.TEO_NORMAL, Rect2(590, 235, 175, 270), true)
			_etiqueta("Gracias, tripulación", Rect2(105, 120, 1060, 75), 44)
			_etiqueta("De vuelta en la Tierra", Rect2(810, 283, 340, 65), 26)
			_etiqueta("Las muestras se estudiarían en un laboratorio protegido. Esta es una misión imaginada para aprender.", Rect2(810, 355, 340, 130), 21)
		_:
			_imagen(PuestoUmbra.SENDERO, AREA)
			_sombra(AREA, Color(0.03, 0.07, 0.12, 0.30))
			_etiqueta("Horizonte Rojo", Rect2(85, 145, 1100, 100), 64)
			_etiqueta("Cinco días en Marte", Rect2(90, 255, 900, 60), 32)
			_etiqueta("Acompaña a Nora, Iris y Teo hasta el refugio.", Rect2(90, 322, 480, 72), 24)
	titulo = _etiqueta("", Rect2(34, 26, 590, 36), 23)
	voz = _etiqueta("", Rect2(34, 82, 410, 105), 20)
	pista = _etiqueta("", Rect2(34, 653, 445, 35), 17)
	boton = _boton("", Rect2(986, 28, 256, 45), _accion)
	boton.visible = false
	match fase:
		"portada":
			boton.position = Vector2(90, 402)
			boton.text = "Continuar viaje" if not restaurado.is_empty() else "Comenzar viaje"
			boton.visible = true
			if not restaurado.is_empty():
				_boton("Empezar de nuevo", Rect2(90, 460, 256, 45), _reiniciar)
		"ida":
			titulo.text = "Salida de la Tierra"
			boton.text = "Saltar viaje · Esc"
			boton.visible = true
		"regreso", "llegada_tierra":
			titulo.text = "Marte → Tierra"
			voz.text = "Iris · Nos llevamos las preguntas y lo que aprendimos. Percy seguirá explorando Marte."
			pista.text = "Meses después · Trayectoria ilustrativa, sin escala"
		"aterrizaje":
			titulo.text = "Aterrizaje en Marte"
			boton.text = "Saltar viaje · Esc"
			boton.visible = true
		"pilotaje":
			titulo.text = "A bordo · Puesto de pilotaje"
			voz.text = "Iris · Tripulación a bordo, puerta cerrada. Nora, cuando estés lista, inicia el vuelo de regreso."
			pista.text = "Percy se queda en Marte · Ruta resumida, sin escala"
			boton.text = "E · Iniciar vuelo"
			boton.visible = true
		"camino_base":
			voz.text = "Percy · Soy Perseverance. Síganme al refugio."
			_actualizar_guia()
		"camino_nave":
			voz.text = "Percy · ¡Buen regreso! Yo seguiré aquí, buscando nuevas pistas."
		"base":
			titulo.text = "Día %d de 5 · Refugio Umbra" % campana.sol
			_actualizar_guia()
		"noche":
			titulo.text = "Fin del día %d" % campana.sol
			voz.text = "Pluto · Es hora de descansar. La base queda cerrada mientras dormimos."
		"amanecer":
			voz.text = "Pluto · Buenos días. Es hora de preparar el regreso." if campana.listo_para_regresar() else "Pluto · Buenos días. Comienza el día %d." % campana.sol
		"despegue":
			voz.text = "Nora · ¡Hasta la próxima, Percy! Tripulación lista para volver."
		"epilogo":
			titulo.text = "Tierra · Cierre de la historia"
			voz.text = "Equipo científico · ¡Gracias, astronautas! Sus preguntas y sus aportes nos ayudan a comprender Marte. ¡Sigan explorando!"
			boton.text = "Volver al comienzo"
	if fase in ["noche", "amanecer", "llegada_tierra", "aterrizaje"]:
		velo = _sombra(AREA, Color(0, 0, 0, 1 if fase in ["amanecer", "aterrizaje"] else 0))

func _crear_mapa(interior: bool) -> void:
	var marco := Control.new()
	marco.size = AREA.size
	marco.clip_contents = true
	marco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.add_child(marco)
	puesto = PuestoUmbra.new()
	puesto.interior = interior
	puesto.chequeo = not interior
	puesto.cielo_sereno = true
	puesto.punto = posicion
	puesto.plano = plano
	puesto.objetivo_mision = "radio" if campana.listo_para_regresar() else "dormitorio"
	puesto.escala_visual = 720.0 / (527.0 if interior else 385.0)
	puesto.ancho_visible = 1280.0 / puesto.escala_visual
	puesto.scale = Vector2.ONE * puesto.escala_visual
	puesto.tiempo = 17
	marco.add_child(puesto)
	if interior and not puesto.transitable(posicion):
		posicion = PuestoUmbra.ENTRADA
		puesto.punto = posicion
	if interior:
		puesto.actualizar_camara(2)

func _etiqueta(texto: String, rect: Rect2, tamano: int) -> Label:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.position = rect.position
	etiqueta.size = rect.size
	etiqueta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	etiqueta.add_theme_font_size_override("font_size", tamano)
	etiqueta.add_theme_color_override("font_color", PAPEL)
	etiqueta.add_theme_color_override("font_outline_color", Color("#0b1320"))
	etiqueta.add_theme_constant_override("outline_size", 7)
	etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.add_child(etiqueta)
	etiqueta.size = rect.size
	return etiqueta

func _sombra(rect: Rect2, color: Color) -> ColorRect:
	var sombra := ColorRect.new()
	sombra.color = color
	sombra.position = rect.position
	sombra.size = rect.size
	sombra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.add_child(sombra)
	return sombra

func _imagen(textura: Texture2D, rect: Rect2, proporcional := false) -> TextureRect:
	var imagen := TextureRect.new()
	if proporcional:
		var recorte := AtlasTexture.new()
		recorte.atlas = textura
		recorte.region = textura.get_image().get_used_rect()
		imagen.texture = recorte
	else:
		imagen.texture = textura
	imagen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagen.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED if proporcional else TextureRect.STRETCH_SCALE
	imagen.position = rect.position
	imagen.size = rect.size
	imagen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.add_child(imagen)
	return imagen

func _boton(texto: String, rect: Rect2, accion: Callable) -> Button:
	var control := Button.new()
	control.position = rect.position
	control.size = rect.size
	control.text = texto
	control.add_theme_font_size_override("font_size", 19)
	var normal := StyleBoxFlat.new()
	normal.bg_color = TINTA
	normal.border_color = CIAN
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(7)
	control.add_theme_stylebox_override("normal", normal)
	control.pressed.connect(accion)
	capa.add_child(control)
	return control
