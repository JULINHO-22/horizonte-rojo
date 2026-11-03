extends Control

const EXTERIOR := preload("res://assets/exterior.jpg")
const ROBOT := preload("res://assets/robot.jpg")
const NORA_ALARMA := preload("res://assets/nora_alarma.png")
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
	["IRIS  /  CONTROL DE MISIÓN", "Puesto Umbra a Tierra. Hoy intentaremos sostener la base con recursos de Marte durante cinco soles."],
	["TEO  /  OPERACIONES", "El viento levantó polvo. La lectura de los paneles acaba de caer."],
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
var boton_tarea: Button
var boton_cierre: Button
var posicion := Vector2(339, 352)
var reloj := 0.0
var ambiente: AudioStreamPlayer
var operacion := ""
var aviso_operacion := ""
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
		if reloj >= 9.0:
			parte = 3
		elif reloj >= 6.0:
			parte = 2
		elif reloj >= 3.0:
			parte = 1
		hablante.text = GUION[parte][0]
		subtitulo.text = GUION[parte][1]
		retrato.texture = IRIS_ORDEN if parte in [0, 2] else TEO_ALARMA
		if reloj >= 13.0:
			_fin_cinematica()
			return
	elif fase == "extraccion":
		if puesto.tiempo >= 16.0:
			fase = "evacuacion"
			_render()
			return
	elif fase != "decision":
		var direccion := Vector2(
			int(Input.is_physical_key_pressed(KEY_D) or Input.is_action_pressed("ui_right")) -
				int(Input.is_physical_key_pressed(KEY_A) or Input.is_action_pressed("ui_left")),
			int(Input.is_physical_key_pressed(KEY_S) or Input.is_action_pressed("ui_down")) -
				int(Input.is_physical_key_pressed(KEY_W) or Input.is_action_pressed("ui_up")))
		puesto.avanzar(direccion.normalized(), delta)
		posicion = puesto.punto
		puesto.actualizar_camara(delta)
		_actualizar_aviso()
	puesto.tiempo += delta
	puesto.queue_redraw()


func _unhandled_key_input(evento: InputEvent) -> void:
	if not evento is InputEventKey or not evento.pressed or evento.echo or evento.physical_keycode != KEY_E:
		return
	match fase:
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
			if not cerca.is_empty():
				modulo = cerca
				operacion = ""
				aviso_operacion = ""
				_render()


func _actualizar_aviso() -> void:
	if fase == "base":
		var cerca := puesto.terminal_cercana()
		aviso.text = "WASD / flechas   ·   Acércate a un terminal" if cerca.is_empty() else "E   /   " + (
			"ABRIR REGISTRO DE ESCLUSA" if cerca == "cierre" else str(MODULOS[cerca][0]))
		if is_instance_valid(boton_tarea):
			boton_tarea.disabled = cerca != modulo or not estado.disponible(modulo)
		if is_instance_valid(boton_cierre):
			boton_cierre.disabled = cerca != "cierre"
	elif fase == "exterior":
		aviso.text = "E   /   HABLAR CON TEO" if posicion.distance_to(PuestoUmbra.ROVER) <= 42 else "WASD / flechas   ·   Acércate al rover"
	elif fase == "evacuacion":
		aviso.text = "E   /   ABRIR ESCLUSA" if posicion.distance_to(PuestoUmbra.ESCLUSA) <= 42 else "WASD / flechas   ·   Lleva a Teo al refugio"


func _render() -> void:
	if is_instance_valid(puesto):
		zoom_anterior = puesto.escala_camara
		centro_anterior = puesto.centro_camara
		orientacion_izquierda = puesto.direccion_izquierda
	puesto = null
	boton_tarea = null
	boton_cierre = null
	if is_instance_valid(pantalla):
		remove_child(pantalla)
		pantalla.queue_free()
	pantalla = Control.new()
	add_child(pantalla)
	var en_superficie := fase in ["cinematica", "exterior", "decision", "extraccion", "evacuacion"]
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
		"cinematica", "exterior", "extraccion", "evacuacion":
			_superficie()
		"decision":
			_apertura()
		"base":
			_base()
		"relevo":
			_relevo()
	_texto("UMBRA  /  PROTOTIPO 01", Rect2(32, 682, 440, 22), 14, MUTED)
	_texto("SOL %02d DE 05   •   PUESTO UMBRA" % estado.sol, Rect2(914, 682, 334, 22), 14, MUTED)


func _inicio() -> void:
	_imagen(EXTERIOR, Rect2(32, 92, 1216, 570))
	_panel(Rect2(55, 358, 524, 282), FONDO)
	_texto("PUESTO UMBRA   /   MARTE", Rect2(79, 382, 450, 24), 16, AMBAR)
	_texto("Cinco soles\npara sobrevivir", Rect2(79, 415, 470, 110), 42)
	_texto("Nora, Iris y Teo · Expedición de recursos locales", Rect2(79, 542, 473, 29), 18, MUTED)
	_boton("Iniciar misión", Rect2(79, 582, 476, 42), _comenzar, CIAN)


func _comenzar() -> void:
	fase = "cinematica"
	reloj = 0.0
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
	puesto.evacuacion = fase == "evacuacion"
	puesto.extraccion = fase == "extraccion"
	puesto.usa_cabrestante = estado.ruta == SolUno.RESCATE
	puesto.decision = fase == "decision"
	puesto.punto = posicion
	puesto.tiempo = 0.0 if puesto.cinematica else 13.0
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
	_crear_puesto(false, Rect2(32, 92, 804, 421))
	_panel(Rect2(32, 526, 804, 136), PANEL)
	hablante = _texto(GUION[0][0], Rect2(49, 539, 764, 25), 15, CIAN)
	subtitulo = _texto(GUION[0][1], Rect2(49, 572, 764, 66), 21)
	_panel(Rect2(856, 92, 392, 570), PANEL)
	_texto("SUPERFICIE   /   SOL 01", Rect2(876, 112, 350, 24), 16, AMBAR)
	retrato = _imagen(IRIS_ORDEN if fase in ["cinematica", "extraccion"] else NORA_ALARMA,
		Rect2(875, 151, 172, 145), TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	_texto("TRIPULACIÓN", Rect2(1050, 174, 174, 28), 19)
	_texto("Nora · Piloto\nIris · Comandante\nTeo · Técnico", Rect2(1050, 209, 174, 83), 15, MUTED)
	_texto("Iris dirige la base. Teo se ocupa de los equipos de superficie. La tripulación necesita demostrar que puede mantener el refugio con recursos locales.",
		Rect2(876, 291, 350, 150), 19)
	if fase == "cinematica":
		_boton("Saltar cinemática", Rect2(876, 595, 351, 43), _fin_cinematica, AMBAR)
		return
	if fase == "extraccion":
		hablante.text = "IRIS   /   OPERACIONES DE RESCATE"
		subtitulo.text = "¡Sujétate, Teo! Activamos el cabrestante." if estado.ruta == SolUno.RESCATE else (
			"La racha cedió. Salimos por Teo con la camilla. ¡Ya lo tenemos!")
		_texto("EXTRACCIÓN EN CURSO", Rect2(876, 537, 350, 54), 20, AMBAR)
		return
	hablante.text = "NORA   /   CANAL LOCAL"
	subtitulo.text = "Tengo que llegar al rover. Teo sigue fuera." if fase == "exterior" else (
		"El cabrestante lo liberó. El invernadero se quedó sin luz. Llevémoslo a la esclusa." if estado.ruta == SolUno.RESCATE else
		"Tras la tregua volvimos por él. Conservamos el invernadero, pero Teo necesita atención.")
	aviso = _texto("", Rect2(876, 528, 351, 95), 21, CIAN)
	_actualizar_aviso()


func _apertura() -> void:
	_crear_puesto(false, Rect2(32, 92, 804, 421))
	_panel(Rect2(47, 109, 233, 34), FONDO)
	_texto("EXTERIOR   /   ESCLUSA 01", Rect2(60, 116, 205, 20), 14, AMBAR)
	_panel(Rect2(32, 511, 804, 49), Color("#15191f"))
	_texto("«¡CIERREN LAS COMPUERTAS! ¡LA TORMENTA ESTÁ ENCIMA!»",
		Rect2(48, 524, 780, 25), 20)
	_panel(Rect2(32, 578, 804, 84), PANEL)
	_imagen(TEO_ALARMA, Rect2(45, 587, 66, 66), TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	_texto("CANAL DE TRIPULACIÓN", Rect2(124, 592, 300, 20), 14, CIAN)
	_texto("«Me caí junto al rover. No puedo sacar la pierna.»",
		Rect2(124, 617, 690, 32), 20)
	_panel(Rect2(856, 92, 392, 570), PANEL)
	_texto("01   /   ALERTA DE ESCLUSA", Rect2(876, 111, 351, 24), 16, AMBAR)
	_texto("Alguien sigue afuera", Rect2(876, 146, 351, 50), 30)
	_texto("Tres astronautas corren al refugio. Uno tropieza y queda atrapado junto al rover averiado.",
		Rect2(876, 198, 351, 94), 20)
	_imagen(_recorte(ROBOT, Rect2(65, 70, 565, 523)), Rect2(875, 296, 66, 66))
	_texto("ROBOT DE A BORDO", Rect2(954, 294, 270, 20), 13, CIAN)
	_texto("El cabrestante usa el circuito del invernadero.", Rect2(954, 317, 272, 58), 18)
	_boton("Rescatar ahora", Rect2(876, 391, 351, 43), _elegir.bind(SolUno.RESCATE), CIAN)
	_texto("6 UE · Invernadero en pausa. Atención temprana.", Rect2(877, 442, 350, 52), 16, MUTED)
	_boton("Cerrar y esperar una tregua", Rect2(876, 506, 351, 43), _elegir.bind(SolUno.ESPERA), AMBAR)
	_texto("4 UE para la extracción posterior. Cultivos activos. La lesión puede agravarse.",
		Rect2(877, 556, 350, 75), 16, MUTED)


func _elegir(ruta: String) -> void:
	estado.abrir(ruta)
	fase = "extraccion"
	_render()


func _base() -> void:
	_crear_puesto(true, Rect2(32, 92, 804, 527))
	_panel(Rect2(32, 625, 804, 37), PANEL)
	aviso = _texto("", Rect2(47, 633, 770, 24), 16, CIAN)
	_panel(Rect2(856, 92, 392, 570), PANEL)
	_texto("SOL %02d   /   ESTABILIZAR LA BASE" % estado.sol, Rect2(875, 108, 351, 24), 16, AMBAR)
	_texto("Reserva de batería", Rect2(875, 143, 285, 28), 22)
	_texto("%02d UE" % estado.energia, Rect2(1145, 143, 85, 28), 22, CIAN)
	_panel(Rect2(876, 180, 350, 8), LINEA, LINEA)
	_panel(Rect2(876, 180, 350 * minf(estado.energia / 24.0, 1.0), 8), CIAN, CIAN)
	_texto("%d raciones  ·  %d agua  ·  %d turnos" % [
		estado.raciones, estado.agua, estado.operativos - estado.acciones.size()],
		Rect2(875, 199, 352, 42), 17, MARFIL)
	_texto("Cultivos · %s\nTripulante · %s" % [estado.cultivo, estado.paciente],
		Rect2(875, 243, 352, 74), 17, MUTED)
	_panel(Rect2(875, 322, 352, 195), FONDO)
	if modulo.is_empty():
		_texto("IRIS   /   REFUGIO", Rect2(888, 335, 327, 24), 14, CIAN)
		var parte: String = estado.EVENTOS[estado.sol - 1]
		if estado.respuesta:
			parte += " Tierra confirma recepción del informe."
		_texto(parte + " Acércate a un terminal y pulsa E.",
			Rect2(888, 366, 327, 134), 18)
	elif modulo == "cierre":
		_texto("05  /  ESCLUSA", Rect2(888, 335, 327, 24), 14, CIAN)
		var cierre := "Sella la base para pasar la noche. El registro guarda las consecuencias."
		if estado.sol == 4 and not estado.paneles_revisados:
			cierre = "La alerta solar exige activar el blindaje auxiliar: cuesta 2 UE adicionales al cerrar."
		_texto(cierre,
			Rect2(888, 366, 327, 89), 17)
		boton_cierre = _boton("Cerrar el sol", Rect2(888, 451, 326, 48), _cerrar, AMBAR)
	else:
		_terminal()
	_texto("Noche · 4 UE, 3 raciones y 2 agua.\nSoporte vital %d%%  ·  Datos de misión %d" % [estado.soporte, estado.muestras],
		Rect2(875, 527, 352, 63), 16, MUTED)
	_texto("Para terminar, vuelve a la esclusa.", Rect2(875, 615, 352, 32), 16, AMBAR)
	_actualizar_aviso()


func _terminal() -> void:
	_texto(MODULOS[modulo][0], Rect2(888, 335, 327, 24), 14, CIAN)
	if not operacion.is_empty():
		_procedimiento()
		return
	var descripcion: String = MODULOS[modulo][1]
	var accion: String = SolUno.ACCIONES[modulo]["titulo"]
	if estado.sol > 1:
		match modulo:
			"energia":
				accion = "Recuperar carga auxiliar"
				descripcion = "3 UE. Recupera 6 UE y prepara los paneles para el siguiente sol."
				if estado.sol == 4:
					descripcion = "3 UE. Usa el robot, recupera 6 UE y conecta el refugio al circuito protegido."
			"cultivos":
				accion = "Procesar hielo" if estado.sol <= 3 else "Cosechar bandejas"
				descripcion = "4 UE. Funde hielo de la reserva: +4 agua y +1 dato." if estado.sol <= 3 else "4 UE. Protege las plantas y recoge 4 raciones."
			"medicina":
				descripcion = "3 UE. Tras dos sesiones, Teo se reincorpora en el siguiente sol."
			"radio":
				accion = "Transmitir informe"
				descripcion = "2 UE. Registra 1 dato. La respuesta de Tierra llega al siguiente sol."
	if modulo == "medicina":
		if estado.recuperacion >= 2:
			descripcion = "«Puedo volver a la consola. Gracias por darme tiempo.»"
		elif estado.recuperacion == 1:
			descripcion = "«Me siento más estable. Aún necesito reposo.»"
		var cara: Texture2D = TEO_ALARMA
		if estado.recuperacion >= 2:
			cara = _recorte(PuestoUmbra.TEO_RECUPERADO, Rect2(219, 0, 495, 444))
		_imagen(cara, Rect2(1134, 353, 80, 88), TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	_texto(descripcion, Rect2(888, 366, 236 if modulo == "medicina" else 327, 74), 17)
	if estado.acciones.has(modulo):
		accion = "Tarea completada"
	elif estado.acciones.size() == estado.operativos:
		accion = "Turnos agotados"
	elif not estado.disponible(modulo):
		accion = "Batería reservada para la noche"
	boton_tarea = _boton(accion, Rect2(888, 451, 326, 48), _abrir_operacion, CIAN,
		not estado.disponible(modulo))


func _abrir_operacion() -> void:
	if puesto.terminal_cercana() != modulo or not estado.disponible(modulo):
		return
	operacion = modulo
	_render()


func _procedimiento() -> void:
	var pasos := {
		"energia": ["El inversor muestra una caída de carga. ¿Qué circuito proteges?", "Soporte vital", "Todas las luces"],
		"cultivos": ["Debes recuperar producción con poca energía.", "Ajustar al consumo mínimo", "Encender todo el módulo"],
		"medicina": ["Teo necesita reposo y seguimiento.", "Registrar y vigilar signos", "Enviarlo a trabajar"],
		"radio": ["Tierra recibirá el mensaje con retraso.", "Enviar el registro de datos", "Esperar indicaciones en vivo"],
	}
	var ficha: Array = pasos[operacion]
	if operacion == "cultivos" and estado.sol in [2, 3]:
		ficha = ["El hielo contiene polvo del terreno.", "Fundir y filtrar", "Enviar hielo directo al tanque"]
	elif operacion == "energia" and estado.sol == 4:
		ficha = ["Hay una alerta solar. ¿Cómo accedes al banco exterior?", "Enviar el robot", "Enviar a un tripulante"]
	var pregunta: String = ficha[0] if aviso_operacion.is_empty() else aviso_operacion
	_texto(pregunta, Rect2(888, 363, 327, 58), 16, MARFIL)
	var invertir := (estado.sol + operacion.length()) % 2 == 0
	for fila in range(2):
		var acierto := fila == int(invertir)
		_boton(ficha[1 if acierto else 2], Rect2(888, 426 + 40 * fila, 326, 34),
			_resolver_operacion.bind(acierto), CIAN)


func _resolver_operacion(acierto: bool) -> void:
	if puesto.terminal_cercana() != operacion or not estado.disponible(operacion):
		return
	if acierto:
		estado.aplicar(operacion)
		operacion = ""
		aviso_operacion = ""
	else:
		aviso_operacion = "El robot detectó un riesgo. Revisa el procedimiento antes de activarlo."
	_render()


func _cerrar() -> void:
	if puesto.terminal_cercana() != "cierre":
		return
	fase = "relevo"
	_render()


func _relevo() -> void:
	var informe := estado.relevo()
	if estado.sol > 1:
		_relevo_campana(informe)
		return
	_imagen(EXTERIOR, Rect2(32, 92, 728, 570))
	_panel(Rect2(32, 470, 728, 192), PANEL)
	_texto("BITÁCORA   /   FIN DEL SOL 01", Rect2(54, 491, 680, 25), 16, CIAN)
	_texto("La base aguanta", Rect2(54, 527, 680, 54), 43)
	_texto("El polvo redujo la luz de los paneles. La batería hizo posible el rescate y mantuvo el refugio durante la noche.",
		Rect2(54, 591, 680, 62), 19, MUTED)
	_panel(Rect2(780, 92, 468, 570), PANEL)
	_texto("RELEVO   /   AMANECER DEL SOL 02", Rect2(802, 112, 423, 30), 17, AMBAR)
	var ruta := "Rescate inmediato" if estado.ruta == SolUno.RESCATE else "Extracción tras la tregua"
	_texto(ruta, Rect2(802, 155, 424, 43), 27)
	var datos := "%d UE en batería  ·  %d raciones\n%d de 3 tripulantes operativos\n\nCultivos · %s\nTripulante · %s\nCuidados previstos · %d UE al próximo sol" % [
		informe.energia, informe.raciones, informe.operativos, informe.cultivo,
		informe.paciente, informe.energia_comprometida]
	_texto(datos, Rect2(802, 212, 424, 190), 20)
	var radio := "Informe en tránsito. Respuesta de Tierra pendiente." if informe.ciencia_enviada else "Lectura del polvo sin enviar."
	_texto(radio, Rect2(802, 422, 424, 58), 19, CIAN)
	var leccion := "El rescate temprano reduce los cuidados. Si los cultivos quedan en pausa, mañana dependes de las raciones."
	if estado.ruta == SolUno.ESPERA:
		leccion = "La espera conservó los cultivos. Si la lesión sigue sin atenderse, mañana compromete más batería."
	_texto(leccion, Rect2(802, 490, 424, 94), 17, MUTED)
	_boton("Comenzar Sol 2", Rect2(802, 584, 424, 34), _siguiente_sol, CIAN)
	_boton("Volver al comienzo", Rect2(802, 623, 424, 29), _reiniciar, AMBAR)


func _relevo_campana(informe: Dictionary) -> void:
	_imagen(PuestoUmbra.TORMENTA, Rect2(32, 92, 728, 570))
	_panel(Rect2(32, 484, 728, 178), PANEL)
	var final: bool = estado.sol == 5 or informe.soporte <= 0
	var titulo := "Fin del Sol %02d" % estado.sol
	var mensaje: String = estado.EVENTOS[mini(estado.sol, 4)]
	if final:
		titulo = "Misión completada" if informe.soporte > 0 and informe.muestras >= 3 and informe.informe_hoy else "Misión interrumpida" if informe.soporte <= 0 else "Supervivencia con misión parcial"
		mensaje = "Tierra registró %d datos. Teo: %s." % [informe.muestras, informe.paciente]
	_texto(titulo, Rect2(54, 503, 680, 47), 34, CIAN)
	_texto(mensaje, Rect2(54, 566, 680, 75), 21)
	_panel(Rect2(780, 92, 468, 570), PANEL)
	_texto("BITÁCORA   /   SOL %02d" % estado.sol, Rect2(802, 115, 424, 43), 21, AMBAR)
	_texto("%d UE en batería\n%d raciones · %d agua\nSoporte vital: %d%%\nDatos acumulados: %d\n\nTeo: %s" % [
		informe.energia, informe.raciones, informe.agua, informe.soporte,
		informe.muestras, informe.paciente], Rect2(802, 180, 424, 320), 23)
	if final:
		_boton("Volver al comienzo", Rect2(802, 590, 424, 48), _reiniciar, AMBAR)
	else:
		_boton("Comenzar Sol %d" % (estado.sol + 1), Rect2(802, 590, 424, 48), _siguiente_sol, CIAN)


func _siguiente_sol() -> void:
	estado.siguiente_sol()
	posicion = PuestoUmbra.ENTRADA
	modulo = ""
	operacion = ""
	fase = "base"
	_render()


func _reiniciar() -> void:
	estado = SolUno.new()
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


func _recorte(textura: Texture2D, region: Rect2) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = textura
	atlas.region = region
	return atlas


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
