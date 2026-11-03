extends Control

const EXTERIOR := preload("res://assets/exterior.jpg")
const IRIS_ORDEN := preload("res://assets/iris_orden.png")
const TEO_ALARMA := preload("res://assets/teo_alarma.png")
const FONDO := Color("#101318")
const PANEL := Color("#1a2129")
const LINEA := Color("#394652")
const MARFIL := Color("#fff1db")
const MUTED := Color("#b3bfc8")
const CIAN := Color("#7df0e0")
const AMBAR := Color("#ffb46f")
const MODULOS := {
	"energia": ["01  /  ENERGÍA", "Consume 3 UE. Recupera 5 UE del banco auxiliar."],
	"cultivos": ["02  /  INVERNADERO", "Consume 4 UE. Protege las bandejas durante la noche."],
	"medicina": ["03  /  ENFERMERÍA", "Consume 3 UE. Estabiliza a Teo, que sigue en reposo."],
	"radio": ["04  /  COMUNICACIONES", "Consume 2 UE. Envía la lectura del polvo y el informe. Respuesta pendiente."],
}
const GUION := [
	["IRIS  /  CONTROL DE MISIÓN", "Teo, muestra confirmada. Si el filtro funciona, podremos pasar cinco soles con agua de Marte."],
	["TEO  /  OPERACIONES", "Nora, mira los paneles. La lectura está cayendo. No vamos a terminar el chequeo aquí."],
	["IRIS  /  CANAL DE EMERGENCIA", "¡CIERREN LAS COMPUERTAS! ¡LA TORMENTA ESTÁ ENCIMA!"],
	["TEO  /  CANAL DE EMERGENCIA", "¡Nora! Me caí junto al rover averiado. No puedo sacar la pierna."],
]

var estado := SolUno.new()
var fase := "inicio"
var modulo := ""
var pantalla: Control
var puesto: PuestoUmbra
var subtitulo: Label
var hablante: Label
var aviso: Label
var posicion := Vector2(339, 352)
var reloj := 0.0
var ambiente: AudioStreamPlayer
var operacion := ""
var aviso_operacion := ""
var paso_operacion := 0
var ajuste_radio := 0.0
var detalle_radio: Label
var mensaje := ""
var ver_plano := false
var rele_nido := 0
var regreso_nora := Vector2.ZERO
var intensidad_ui: ProgressBar
var fase_renderizada := ""
var valvulas: Array[int] = [0, 0, 0]
const CONDUCTOS := [
	["Depósito", "Cerrado", "Al fundidor", "A drenaje"],
	["Fundidor", "Cerrado", "A drenaje", "Al filtro"],
	["Filtro", "Cerrado", "Al tanque", "A retorno"],
]
const RUTA_AGUA: Array[int] = [1, 2, 1]
const AREA := Rect2(32, 84, 1216, 578)
const NOMBRES := {"energia": "Energía", "cultivos": "Invernadero", "medicina": "Enfermería", "radio": "Control", "cierre": "Esclusa"}
const PLANES := {
	"energia": [["Aislar luces auxiliares", "Acoplar batería", "Verificar soporte vital"], [2, 0, 1]],
	"cultivos": [["Abrir retorno de agua", "Ajustar la luz", "Revisar bandejas"], [1, 2, 0]],
	"medicina": [["Leer el monitor", "Inmovilizar la pierna", "Registrar reposo"], [1, 0, 2]],
}
var zoom_anterior := 1.0
var centro_anterior := Vector2(402, 263.5)
var orientacion_izquierda := false
var retrato: TextureRect


func _ready() -> void:
	get_window().min_size = Vector2i(800, 450)
	_preparar_viento()
	_render()


func _process(delta: float) -> void:
	if not is_instance_valid(puesto):
		return
	if fase == "cinematica":
		reloj += delta
		var parte := 0
		if reloj >= 12.0:
			parte = 3
		elif reloj >= 8.0:
			parte = 2
		elif reloj >= 4.0:
			parte = 1
		hablante.text = GUION[parte][0]
		subtitulo.text = GUION[parte][1]
		retrato.texture = IRIS_ORDEN if parte in [0, 2] else TEO_ALARMA if parte == 3 else PuestoUmbra.TEO_NORMAL
		if reloj >= 17.0:
			_fin_cinematica()
			return
	elif fase == "extraccion":
		if puesto.tiempo >= 19.8:
			fase = "evacuacion"
			_render()
			return
	elif fase != "decision" and modulo.is_empty():
		var direccion := Vector2(
			int(Input.is_physical_key_pressed(KEY_D) or Input.is_action_pressed("ui_right")) -
				int(Input.is_physical_key_pressed(KEY_A) or Input.is_action_pressed("ui_left")),
			int(Input.is_physical_key_pressed(KEY_S) or Input.is_action_pressed("ui_down")) -
				int(Input.is_physical_key_pressed(KEY_W) or Input.is_action_pressed("ui_up")))
		puesto.anclado = not puesto.interior and not puesto.chequeo and Input.is_physical_key_pressed(KEY_SHIFT)
		puesto.avanzar(direccion.normalized(), delta)
		posicion = puesto.punto
		puesto.actualizar_camara(delta)
		_actualizar_aviso()
	puesto.tiempo += delta
	if ambiente.playing:
		ambiente.volume_db = lerpf(-23.0, -4.0, puesto.intensidad_viento())
	if is_instance_valid(intensidad_ui):
		intensidad_ui.value = puesto.intensidad_viento()
	puesto.queue_redraw()


func _unhandled_key_input(evento: InputEvent) -> void:
	if not evento is InputEventKey or not evento.pressed or evento.echo:
		return
	if fase == "base" and evento.physical_keycode == KEY_ESCAPE and not modulo.is_empty():
		_salir_terminal()
		return
	if fase == "base" and evento.physical_keycode == KEY_M and modulo.is_empty():
		ver_plano = not ver_plano
		puesto.plano = ver_plano
		return
	if fase == "nido" and evento.physical_keycode == KEY_ESCAPE:
		_volver_nido(false)
		return
	if evento.physical_keycode != KEY_E:
		return
	match fase:
		"nido":
			var destino: Vector2 = PuestoUmbra.RELES[rele_nido] if rele_nido < PuestoUmbra.RELES.size() else PuestoUmbra.ESCLUSA
			if posicion.distance_to(destino) <= 31.0:
				if rele_nido < PuestoUmbra.RELES.size():
					rele_nido += 1
					puesto.rele_actual = rele_nido
				else:
					_volver_nido(true)
		"chequeo":
			if posicion.distance_to(PuestoUmbra.ROVER) <= 42:
				fase = "cinematica"
				reloj = 0.0
				_render()
		"exterior":
			if posicion.distance_to(PuestoUmbra.ROVER) <= 42:
				fase = "decision"
				_render()
		"evacuacion":
			if posicion.distance_to(PuestoUmbra.ESCLUSA) <= 42:
				posicion = PuestoUmbra.ENTRADA
				fase = "base"
				_render()
		"base":
			var cerca := puesto.terminal_cercana()
			if not cerca.is_empty() and modulo.is_empty():
				modulo = cerca
				operacion = ""
				aviso_operacion = ""
				_render()


func _actualizar_aviso() -> void:
	if not is_instance_valid(aviso):
		return
	if fase == "base":
		var cerca := puesto.terminal_cercana()
		aviso.text = "WASD / flechas · M: plano general" if cerca.is_empty() else "E   /   " + NOMBRES[cerca] + "   ·   M: plano general"
	elif fase in ["chequeo", "exterior"]:
		aviso.text = "E   /   HABLAR CON TEO" if posicion.distance_to(PuestoUmbra.ROVER) <= 42 else "WASD / flechas   ·   Camina hacia el rover"
	elif fase == "evacuacion":
		aviso.text = "E   /   ABRIR ESCLUSA" if posicion.distance_to(PuestoUmbra.ESCLUSA) <= 42 else "WASD / flechas   ·   Lleva a Teo al refugio"
	elif fase == "nido":
		var destino: Vector2 = PuestoUmbra.RELES[rele_nido] if rele_nido < PuestoUmbra.RELES.size() else PuestoUmbra.ESCLUSA
		var objetivo := "RELÉ %d / %d" % [rele_nido + 1, PuestoUmbra.RELES.size()] if rele_nido < PuestoUmbra.RELES.size() else "VOLVER A LA ESCLUSA"
		aviso.text = ("E  /  " if posicion.distance_to(destino) <= 31 else "WASD  /  ") + objetivo + "   ·   Esc: retirar a NIDO"
	if fase in ["exterior", "evacuacion", "nido"]:
		if puesto.intensidad_viento() >= 0.55 and not puesto.bajo_abrigo():
			aviso.text += "   ·   RÁFAGA  /  Shift: anclar"
		elif puesto.bajo_abrigo():
			aviso.text += "   ·   A CUBIERTO"


func _render() -> void:
	var cambio_de_fase := fase != fase_renderizada
	fase_renderizada = fase
	if is_instance_valid(puesto):
		zoom_anterior = puesto.escala_camara
		centro_anterior = puesto.centro_camara
		orientacion_izquierda = puesto.direccion_izquierda
	puesto = null
	if is_instance_valid(pantalla):
		remove_child(pantalla)
		pantalla.queue_free()
	pantalla = Control.new()
	add_child(pantalla)
	var en_superficie := fase in ["cinematica", "exterior", "decision", "extraccion", "evacuacion", "nido"]
	if en_superficie and not ambiente.playing:
		ambiente.play()
	elif not en_superficie:
		ambiente.stop()
	_panel(Rect2(0, 0, 1280, 720), FONDO, FONDO)
	_texto("UMBRA", Rect2(32, 17, 230, 46), 36)
	_texto("CINCO SOLES PARA SOBREVIVIR", Rect2(184, 33, 390, 24), 15, MUTED)
	_texto("MARTE   /   PUESTO UMBRA", Rect2(988, 32, 266, 26), 16, CIAN)
	_panel(Rect2(32, 74, 1216, 1), LINEA, LINEA)
	match fase:
		"inicio":
			_inicio()
		"chequeo", "cinematica", "exterior", "extraccion", "evacuacion", "nido":
			_superficie()
		"decision":
			_apertura()
		"base":
			_base()
		"relevo":
			_relevo()
	_texto("NIDO  /  CANAL DE MISIÓN", Rect2(32, 682, 440, 22), 14, MUTED)
	_texto("SOL %02d DE 05   •   PUESTO UMBRA" % estado.sol, Rect2(914, 682, 334, 22), 14, MUTED)
	if cambio_de_fase and is_instance_valid(puesto):
		puesto.modulate.a = 0.18
		puesto.create_tween().tween_property(puesto, "modulate:a", 1.0, 0.36)


func _inicio() -> void:
	_imagen(EXTERIOR, AREA)
	_panel(Rect2(307, 242, 666, 278), FONDO)
	_texto("PUESTO UMBRA   /   ENTRENAMIENTO MARCIANO", Rect2(344, 269, 595, 28), 17, AMBAR)
	_texto("Cinco soles para sobrevivir", Rect2(344, 308, 598, 64), 40)
	_texto("Prueba el equipo con Teo. La misión es mantener con vida a la tripulación y enviar evidencia de que el agua local puede sostener el puesto.",
		Rect2(344, 380, 592, 70), 19, MUTED)
	_boton("Iniciar misión", Rect2(344, 460, 592, 40), _comenzar, CIAN)


func _comenzar() -> void:
	fase = "chequeo"
	posicion = Vector2(196, 347)
	_render()


func _preparar_viento() -> void:
	var audio := AudioStreamWAV.new()
	audio.format = AudioStreamWAV.FORMAT_16_BITS
	audio.mix_rate = 12000
	audio.loop_mode = AudioStreamWAV.LOOP_FORWARD
	audio.loop_end = 48000
	var muestras := PackedByteArray()
	muestras.resize(audio.loop_end * 2)
	var ruido := RandomNumberGenerator.new()
	ruido.seed = 741
	var suave := 0.0
	for indice in range(audio.loop_end):
		suave = lerpf(suave, ruido.randf_range(-1.0, 1.0), 0.12)
		var rafaga := sin(TAU * float(indice) / audio.loop_end) * 0.24 + 0.76
		muestras.encode_s16(indice * 2, int(suave * rafaga * 9400))
	audio.data = muestras
	ambiente = AudioStreamPlayer.new()
	ambiente.stream = audio
	ambiente.volume_db = -16.0
	add_child(ambiente)


func _fin_cinematica() -> void:
	fase = "exterior"
	posicion = Vector2(339, 352)
	_render()


func _crear_puesto(es_interior: bool, area: Rect2) -> void:
	var marco := Control.new()
	marco.clip_contents = true
	marco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_colocar(marco, area)
	puesto = PuestoUmbra.new()
	puesto.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	puesto.interior = es_interior
	puesto.cinematica = fase == "cinematica"
	puesto.chequeo = fase == "chequeo"
	puesto.mando_nido = fase == "nido"
	puesto.rele_actual = rele_nido
	puesto.plano = ver_plano
	puesto.objetivo_mision = "cierre" if estado.mision_cumplida() else SolUno.MISIONES[estado.sol - 1]
	puesto.escala_visual = area.size.y / (527.0 if es_interior else 421.0)
	puesto.ancho_visible = area.size.x / puesto.escala_visual
	puesto.scale = Vector2.ONE * puesto.escala_visual
	puesto.evacuacion = fase == "evacuacion"
	puesto.extraccion = fase == "extraccion"
	puesto.usa_cabrestante = estado.ruta == SolUno.RESCATE
	puesto.decision = fase == "decision"
	puesto.punto = posicion
	puesto.tiempo = 0.0 if puesto.cinematica else 17.0
	puesto.cultivo_activo = estado.cultivo != "En pausa"
	puesto.radio_enviada = estado.ciencia_enviada
	puesto.atendido = estado.recuperacion > 0
	puesto.lesion_grave = estado.paciente.begins_with("Lesión")
	puesto.teo_recuperado = estado.recuperacion >= 2
	puesto.escala_camara = zoom_anterior
	puesto.centro_camara = centro_anterior
	puesto.direccion_izquierda = orientacion_izquierda
	marco.add_child(puesto)


func _superficie() -> void:
	_crear_puesto(false, AREA)
	if fase in ["exterior", "evacuacion", "nido"]:
		_panel(Rect2(48, 100, 236, 52), FONDO)
		_texto("NIDO  /  CARGA DE VIENTO", Rect2(60, 106, 218, 21), 13, AMBAR)
		intensidad_ui = ProgressBar.new()
		intensidad_ui.max_value = 1.0
		intensidad_ui.step = 0.0
		intensidad_ui.show_percentage = false
		intensidad_ui.add_theme_stylebox_override("background", _estilo(PANEL, LINEA))
		intensidad_ui.add_theme_stylebox_override("fill", _estilo(AMBAR, AMBAR))
		_colocar(intensidad_ui, Rect2(61, 130, 209, 9))
	_panel(Rect2(260, 514, 760, 129), FONDO)
	retrato = _imagen(PuestoUmbra.DRON, Rect2(276, 528, 90, 94), TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	hablante = _texto("NIDO   /   ASISTENTE DE MISIÓN", Rect2(379, 526, 620, 24), 15, CIAN)
	subtitulo = _texto("", Rect2(379, 553, 620, 57), 19)
	if fase == "cinematica":
		_boton("Saltar cinemática", Rect2(1031, 607, 202, 36), _fin_cinematica, AMBAR)
		return
	if fase == "extraccion":
		subtitulo.text = "El cabrestante está tirando. Vigila a Teo." if estado.ruta == SolUno.RESCATE else "Bajó el polvo. Acércale la camilla a Teo."
		return
	match fase:
		"chequeo":
			subtitulo.text = "Soy NIDO. Teo tiene la muestra de hielo del entrenamiento. Acércate al rover para hacer el chequeo."
		"exterior":
			subtitulo.text = "Teo cayó junto al rover. Avanza entre ráfagas. Mantén Shift para anclarte o busca los círculos de abrigo."
		"evacuacion":
			subtitulo.text = "Lleva la camilla a la esclusa. Cuando arrecie el viento, ancla con Shift y espera la tregua."
		"nido":
			subtitulo.text = "Tienes mi mando. Activa los tres relés por orden y tráeme de vuelta. La tripulación espera bajo techo."
	aviso = _texto("", Rect2(379, 609, 620, 26), 15, CIAN)
	_actualizar_aviso()


func _apertura() -> void:
	_crear_puesto(false, AREA)
	_modal("NIDO   /   RESCATE EN SUPERFICIE", "El cabrestante comparte circuito con el invernadero. La tregua reduce el gasto, pero Teo pasará más tiempo afuera.")
	_boton("Rescatar ahora · 6 UE", Rect2(306, 383, 324, 45), _elegir.bind(SolUno.RESCATE), CIAN)
	_boton("Esperar una tregua · 4 UE", Rect2(650, 383, 324, 45), _elegir.bind(SolUno.ESPERA), AMBAR)
	_texto("Invernadero en pausa. Teo llega estable.", Rect2(309, 443, 316, 58), 17, MUTED)
	_texto("Cultivos activos. Teo llega con una lesión más grave.", Rect2(653, 443, 316, 58), 17, MUTED)


func _elegir(ruta: String) -> void:
	estado.abrir(ruta)
	fase = "extraccion"
	_render()


func _base() -> void:
	_crear_puesto(true, AREA)
	_panel(Rect2(44, 96, 1192, 38), FONDO)
	_texto("SOL %02d   ·   %d UE   ·   %d RACIONES   ·   %d AGUA   ·   %d TURNOS   ·   SOPORTE %d%%   ·   DATOS %d" % [
		estado.sol, estado.energia, estado.raciones, estado.agua,
		estado.operativos - estado.acciones.size(), estado.soporte, estado.muestras],
		Rect2(61, 104, 1150, 25), 17, CIAN)
	if not modulo.is_empty():
		_terminal()
		return
	_panel(Rect2(213, 541, 854, 108), FONDO)
	_imagen(PuestoUmbra.DRON, Rect2(224, 550, 72, 80), TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	var objetivo: String = "Vuelve a la esclusa para cerrar el sol" if estado.mision_cumplida() else SolUno.OBJETIVOS[estado.sol - 1]
	_texto("NIDO   /   " + objetivo, Rect2(306, 550, 740, 27), 20, CIAN)
	var pista: String = mensaje if not mensaje.is_empty() else estado.EVENTOS[estado.sol - 1]
	if estado.mision_cumplida() and estado.acciones.size() < estado.operativos:
		if estado.recuperacion < 2 and estado.disponible("medicina"):
			pista = "Te queda un turno. Puedes visitar Enfermería antes de volver a la esclusa."
		elif estado.disponible("cultivos"):
			pista = "Te queda un turno. Si faltan reservas, revisa el Invernadero antes de cerrar."
	if mensaje.is_empty() and estado.respuesta:
		pista += " Tierra confirmó el informe anterior."
	_texto(pista, Rect2(306, 580, 740, 44), 16)
	aviso = _texto("", Rect2(306, 622, 740, 23), 14, MUTED)
	_actualizar_aviso()


func _modal(titulo: String, descripcion: String) -> void:
	_panel(AREA, Color(0.03, 0.04, 0.06, 0.48), Color.TRANSPARENT)
	_panel(Rect2(282, 193, 716, 345), FONDO, LINEA)
	_imagen(PuestoUmbra.DRON, Rect2(309, 209, 71, 72), TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	_texto(titulo, Rect2(396, 227, 570, 44), 23, CIAN)
	_texto(descripcion, Rect2(308, 292, 661, 72), 20)


func _terminal() -> void:
	if modulo == "cierre":
		var listo := estado.mision_cumplida()
		var texto := "Al cerrar se consumen 4 UE, 3 raciones y 2 de agua. Puedes usar los turnos restantes antes de dormir."
		if not listo:
			texto = "Primero completa la misión del sol. " + SolUno.OBJETIVOS[estado.sol - 1] + ". El marcador indica el módulo."
		_modal("NIDO   /   REGISTRO DE ESCLUSA", texto)
		_boton("Cerrar el sol", Rect2(308, 389, 660, 48), _cerrar, AMBAR, not listo)
	else:
		_operar_terminal()
	_boton("Volver al mapa  ·  Esc", Rect2(308, 480, 660, 36), _salir_terminal, MUTED)


func _operar_terminal() -> void:
	var id := modulo
	var titulo: String = MODULOS[id][0]
	if not operacion.is_empty():
		_procedimiento(titulo)
		return
	var descripcion: String = MODULOS[id][1]
	var accion: String = SolUno.ACCIONES[id]["titulo"]
	if estado.sol > 1:
		match id:
			"energia":
				accion = "Recuperar carga auxiliar"
				descripcion = "3 UE. Recupera 6 UE y prepara los paneles para el próximo sol."
				if estado.sol == 4:
					accion = "Tomar el mando de NIDO"
					descripcion = "3 UE. Pilota a NIDO, activa los tres relés exteriores y regresa al refugio. Recuperas 6 UE."
			"cultivos":
				accion = "Procesar hielo" if estado.sol <= 3 else "Cosechar bandejas"
				descripcion = "4 UE. El hielo del depósito aporta 4 de agua y 1 dato." if estado.sol <= 3 else "4 UE. Ajusta el cultivo y recoge 4 raciones."
			"radio":
				accion = "Transmitir informe"
				descripcion = "2 UE. Alinea la antena para enviar el registro. La confirmación tarda."
	if id == "medicina":
		descripcion = "3 UE. Teo necesita dos sesiones para volver al equipo. Estado actual: " + estado.paciente
	if estado.acciones.has(id):
		accion = "Tarea completada"
	elif not estado.disponible(id):
		accion = "Reserva batería o turnos para la misión y la noche"
	_modal("NIDO   /   " + titulo, descripcion)
	_boton(accion, Rect2(308, 387, 660, 48), _abrir_operacion, CIAN, not estado.disponible(id))


func _abrir_operacion() -> void:
	if not estado.disponible(modulo):
		return
	operacion = modulo
	if modulo == "energia" and estado.sol == 4:
		regreso_nora = posicion
		posicion = PuestoUmbra.ESCLUSA
		rele_nido = 0
		fase = "nido"
		modulo = ""
		_render()
		return
	paso_operacion = 0
	valvulas = [0, 0, 0]
	ajuste_radio = 0.0
	aviso_operacion = ""
	_render()


func _volver_nido(completado: bool) -> void:
	fase = "base"
	posicion = regreso_nora
	if completado:
		_completar_operacion()
	else:
		operacion = ""
		mensaje = "NIDO regresó. Puedes reintentar la salida desde Energía."
		_render()


func _procedimiento(titulo: String) -> void:
	if operacion == "radio":
		var objetivo := 29 + estado.sol * 9
		_modal("NIDO   /   " + titulo, "Busca la señal entre %d y %d kHz. Mueve el dial hasta que el indicador marque enlace estable." % [objetivo - 10, objetivo + 10])
		var dial := HSlider.new()
		dial.max_value = 100
		dial.step = 1
		dial.value = ajuste_radio
		_colocar(dial, Rect2(308, 375, 516, 32))
		detalle_radio = _texto("", Rect2(828, 367, 145, 50), 16, AMBAR)
		_ajustar_radio(ajuste_radio)
		dial.value_changed.connect(_ajustar_radio)
		var etiqueta := "Transmitir" if aviso_operacion.is_empty() else aviso_operacion
		_boton(etiqueta, Rect2(308, 420, 660, 42), _transmitir.bind(objetivo), CIAN)
		return
	if operacion == "cultivos" and estado.sol in [2, 3]:
		_circuito_agua()
		return
	var ficha: Array = PLANES[operacion]
	var pasos: Array = ficha[0]
	var siguiente: String = pasos[paso_operacion]
	var pista := "Paso %d de 3 · %s" % [paso_operacion + 1, siguiente]
	if not aviso_operacion.is_empty():
		pista = "Circuito protegido. Primero debes: " + siguiente.to_lower() + "."
	_modal("NIDO   /   " + titulo, pista)
	for columna in range(3):
		var accion: int = ficha[1][columna]
		_boton(pasos[accion], Rect2(306 + columna * 223, 389, 218, 48),
			_ejecutar_paso.bind(accion), CIAN, accion < paso_operacion)


func _circuito_agua() -> void:
	var aviso_agua := "Gira las válvulas para llevar el hielo al fundidor, pasar el agua por el filtro y llenar el tanque."
	if not aviso_operacion.is_empty():
		aviso_agua = aviso_operacion
	_modal("NIDO   /   CIRCUITO DE AGUA", aviso_agua)
	for i in range(CONDUCTOS.size()):
		var valvula: Array = CONDUCTOS[i]
		var x := 308 + i * 222
		_texto(valvula[0], Rect2(x, 365, 207, 23), 16, AMBAR)
		_boton(valvula[1 + valvulas[i]], Rect2(x, 391, 206, 36), _girar_valvula.bind(i), CIAN)
	_boton("Probar caudal", Rect2(308, 435, 660, 32), _probar_caudal, CIAN)


func _girar_valvula(indice: int) -> void:
	valvulas[indice] = (valvulas[indice] + 1) % 3
	aviso_operacion = ""
	_render()


func _probar_caudal() -> void:
	for i in range(RUTA_AGUA.size()):
		if valvulas[i] != RUTA_AGUA[i]:
			aviso_operacion = "La prueba se detuvo en %s. Corrige esa salida y comprueba el caudal otra vez." % CONDUCTOS[i][0].to_lower()
			_render()
			return
	_completar_operacion()


func _ajustar_radio(valor: float) -> void:
	ajuste_radio = valor
	var diferencia := absf(valor - (29 + estado.sol * 9))
	detalle_radio.text = "%d kHz\n%s" % [valor, "Enlace estable" if diferencia <= 2 else "Señal %d%%" % maxi(0, 100 - int(diferencia * 6))]
	detalle_radio.modulate = CIAN if diferencia <= 2 else Color.WHITE


func _transmitir(objetivo: int) -> void:
	if absf(ajuste_radio - objetivo) <= 2:
		_completar_operacion()
	else:
		aviso_operacion = "Señal débil · Ajustar y reintentar"
		_render()


func _ejecutar_paso(accion: int) -> void:
	if accion != paso_operacion:
		aviso_operacion = "secuencia"
	else:
		paso_operacion += 1
		aviso_operacion = ""
		if paso_operacion == 3:
			_completar_operacion()
			return
	_render()


func _completar_operacion() -> void:
	if not estado.disponible(operacion):
		return
	estado.aplicar(operacion)
	match operacion:
		"energia": mensaje = "Circuito estable. La carga auxiliar ya está en la batería."
		"cultivos": mensaje = "Muestra filtrada. El depósito tiene 4 unidades más de agua." if estado.sol in [2, 3] else "Invernadero estabilizado. Revisa las raciones antes de cerrar."
		"medicina": mensaje = "Teo volverá al turno en el próximo sol." if estado.recuperacion >= 2 else "Teo descansa. Falta otra sesión para que vuelva al turno."
		"radio": mensaje = "Informe transmitido. La respuesta de Tierra llegará con retraso."
	_salir_terminal()


func _salir_terminal() -> void:
	modulo = ""
	operacion = ""
	_render()


func _cerrar() -> void:
	if puesto.terminal_cercana() != "cierre" or not estado.mision_cumplida():
		return
	fase = "relevo"
	_render()


func _relevo() -> void:
	var informe := estado.relevo()
	var final: bool = estado.sol == 5 or informe.soporte <= 0
	var titulo := "Bitácora · Sol %02d" % estado.sol
	if final:
		titulo = "Misión interrumpida" if informe.soporte <= 0 else "La base resistió"
		if informe.soporte >= 80 and estado.recuperacion >= 2 and informe.muestras >= 3 and informe.informe_hoy:
			titulo = "Misión completada"
	_imagen(PuestoUmbra.TORMENTA if estado.sol < 5 else EXTERIOR, AREA)
	var reporte := "%d UE · %d raciones · %d de agua · soporte %d%%
Datos de misión: %d. Teo: %s." % [
		informe.energia, informe.raciones, informe.agua, informe.soporte, informe.muestras, informe.paciente]
	_modal(titulo, reporte)
	var nota := "NIDO: El próximo sol descontará %d UE de cuidados." % informe.energia_comprometida
	if final:
		if informe.soporte <= 0:
			nota = "NIDO: El refugio agotó su margen de soporte vital."
		elif titulo == "Misión completada":
			nota = "NIDO: El informe salió. Teo volvió al turno y el refugio tiene margen para seguir operando."
		else:
			nota = "NIDO: El informe salió. Queda trabajo en cuidados o soporte vital antes de prolongar la misión."
	_texto(nota, Rect2(308, 378, 661, 59), 18, MUTED)
	if not final:
		_boton("Comenzar Sol %d" % (estado.sol + 1), Rect2(308, 458, 420, 48), _siguiente_sol, CIAN)
		_boton("Reiniciar", Rect2(746, 458, 222, 48), _reiniciar, MUTED)
	else:
		_boton("Volver al comienzo", Rect2(308, 458, 660, 48), _reiniciar, CIAN)


func _siguiente_sol() -> void:
	estado.siguiente_sol()
	mensaje = ""
	posicion = PuestoUmbra.ENTRADA
	modulo = ""
	operacion = ""
	fase = "base"
	_render()


func _reiniciar() -> void:
	estado = SolUno.new()
	mensaje = ""
	modulo = ""
	operacion = ""
	fase = "inicio"
	_render()


func _estilo(color: Color, borde: Color) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = color
	estilo.border_color = borde
	estilo.set_border_width_all(1)
	return estilo


func _colocar(control: Control, area: Rect2) -> void:
	pantalla.add_child(control)
	control.position = area.position
	control.size = area.size


func _panel(area: Rect2, color: Color, borde := LINEA) -> void:
	var panel := Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _estilo(color, borde))
	_colocar(panel, area)


func _texto(contenido: String, area: Rect2, puntos: int, color := MARFIL) -> Label:
	var etiqueta := Label.new()
	etiqueta.text = contenido
	etiqueta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	etiqueta.add_theme_font_size_override("font_size", puntos)
	etiqueta.add_theme_color_override("font_color", color)
	_colocar(etiqueta, area)
	return etiqueta


func _imagen(textura: Texture2D, area: Rect2, ajuste := TextureRect.STRETCH_KEEP_ASPECT_COVERED) -> TextureRect:
	var imagen := TextureRect.new()
	imagen.texture = textura
	imagen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagen.stretch_mode = ajuste
	imagen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_colocar(imagen, area)
	return imagen


func _boton(titulo: String, area: Rect2, evento: Callable, acento: Color,
		desactivado := false) -> Button:
	var boton := Button.new()
	boton.text = titulo
	boton.disabled = desactivado
	boton.add_theme_font_size_override("font_size", 17)
	boton.add_theme_color_override("font_color", acento)
	boton.add_theme_color_override("font_hover_color", FONDO)
	boton.add_theme_color_override("font_pressed_color", FONDO)
	boton.add_theme_color_override("font_disabled_color", MUTED)
	boton.add_theme_stylebox_override("normal", _estilo(FONDO, acento))
	boton.add_theme_stylebox_override("hover", _estilo(acento, acento))
	boton.add_theme_stylebox_override("pressed", _estilo(acento.darkened(0.2), acento))
	boton.add_theme_stylebox_override("disabled", _estilo(PANEL, LINEA))
	boton.add_theme_stylebox_override("focus", _estilo(Color.TRANSPARENT, MARFIL))
	_colocar(boton, area)
	boton.pressed.connect(evento)
	return boton
