extends Control

const ExpedicionHielo := preload("res://scripts/expedicion_hielo.gd")

const EXTERIOR := preload("res://assets/exterior.jpg")
const IRIS_ORDEN := preload("res://assets/iris_orden.png")
const TEO_ALARMA := preload("res://assets/teo_alarma.png")
const FONDO := Color("#241b2c")
const PANEL := Color("#32283c")
const LINEA := Color("#6b566c")
const MARFIL := Color("#fff1db")
const MUTED := Color("#b3bfc8")
const CIAN := Color("#7df0e0")
const AMBAR := Color("#ffb46f")
const MODULOS := {
	"energia": ["01  /  ENERGÍA", "Usa 3 puntos de batería para conectar la reserva. La reserva aporta 5."],
	"cultivos": ["02  /  SALA DE PLANTAS", "Consume 4 puntos de batería. Protege las bandejas durante la noche."],
	"medicina": ["03  /  ENFERMERÍA", "Usa 3 puntos de batería para cuidar a Teo. Aún necesita descansar."],
	"radio": ["04  /  COMUNICACIONES", "Consume 2 puntos de batería. Envía la lectura del polvo y el informe. Respuesta pendiente."],
}
const ATERRIZAJE := [
	"Ahí está el refugio. Vamos a bajar junto al camino.",
	"Nos queda media botella de repuesto. En el barranco hay hielo bajo la tierra. Traigamos un poco para probarlo.",
	"Lo probaremos durante cinco días. Primero, reúne al equipo en el refugio.",
]
var estado := SolUno.new()
var fase := "inicio"
var modulo := ""
var pantalla: Control
var puesto: PuestoUmbra
var subtitulo: Label
var hablante: Label
var aviso: Label
var pista_exploracion: Label
var guia_exploracion := ""
var terminal_pendiente := ""
var guia_cuidados: Label
var ferula_recogida := false
var tecla_cuidados := false
const TIEMPO_CUIDADOS := 1.6
var posicion := Vector2(339, 352)
var reloj := 0.0
var expedicion := ExpedicionHielo.new()
var muestra_procesada := false
var boton_sondeo: Button
var reserva_para_aire := false
var regreso_distante := false
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
	["Depósito", "Cerrado", "A derretir", "Al desagüe"],
	["Para derretir", "Cerrado", "Al desagüe", "Al filtro"],
	["Filtro", "Cerrado", "A revisión", "A retorno"],
]
const RUTA_AGUA: Array[int] = [1, 2, 1]
const NOCHES := [
	"El aire y el calor vuelven a funcionar. Mañana probaremos el hielo.",
	"La muestra ya es agua. Mañana le contaremos a Tierra cómo salió la prueba.",
	"El informe viaja a Tierra. Pluto revisará la radio mientras dormimos.",
	"Pluto volvió y el refugio está protegido. Mañana enviaremos los resultados.",
	"El informe final salió. Por primera vez en cinco días, podemos bajar la guardia.",
]
const AREA := Rect2(0, 0, 1280, 720)
const NOMBRES := {"energia": "Energía", "cultivos": "Sala de plantas", "medicina": "Enfermería", "radio": "Control", "cierre": "Puerta del refugio", "dormitorio": "Dormitorio"}
const DETALLES := {
	"aire": ["Reciclador de aire", "Este equipo retira del aire lo que soltamos al respirar. Afuera usamos el aire del traje. Con la puerta sellada, el refugio mantiene aire respirable."],
	"mapa": ["Mapa de la expedición", "El barranco queda lejos del refugio. En el visor comparamos la escarcha con el hielo bajo tierra antes de elegir dónde perforar."],
	"plantas": ["Jardineras", "Las hojas necesitan luz y agua. Si ahorramos batería apagando las luces, mañana tendremos menos comida."],
	"teo": ["Cuidados de Teo", "Teo necesita dos sesiones de cuidado. Cuando pueda volver a trabajar, habrá tiempo para una tarea más a partir del día siguiente."],
	"literas": ["Las literas", "Nora dibujó el barranco en la pared. Iris dejó marcada la hora del próximo mensaje. La manta de Teo está lista para cuando pueda volver."],
	"muestras_frias": ["Cajones de muestras", "Cada cajón conserva el hielo de un sitio distinto. Si se mezclan, perdemos la pista de dónde estaba el agua."],
	"capas_hielo": ["Capas del hielo", "Mira las franjas claras y oscuras. Al sacar un trozo entero, podemos ver qué partes tienen más tierra."],
	"rover_taller": ["Camioneta de repuesto", "Es un vehículo de reserva. Iris lo dejó limpio, con las ruedas en alto, para revisar los ejes dentro del taller."],
	"repuestos": ["Estante de repuestos", "Las juntas mantienen el polvo fuera. Los guantes gruesos protegen las manos cuando toca cambiar piezas afuera."],
}
const PRUEBAS_ANEXOS := {
	"filtro_lab": ["Banco de filtrado", "El hielo se derritió y dejó granitos de tierra en el agua. ¿Qué hacemos antes de guardarla?",
		"Pasar el agua por el filtro", "Guardar el agua tal como salió",
		"El filtro atrapó la tierra. Antes de usar el agua, medimos las sales y buscamos otras impurezas.",
		"Si la guardamos ahora, la tierra también llega al tanque. Prueba con el filtro."],
	"sello_traje": ["Probador de trajes", "Este traje pierde aire despacio. ¿Qué revisamos antes de llevarlo afuera?",
		"Revisar el sello del casco", "Llenar el tanque otra vez",
		"El cierre del casco tenía una fuga. Cambiamos el sello y volvimos a probar el traje en el banco.",
		"Llenarlo nos da más aire por un rato. La fuga sigue ahí. Busca por dónde sale."],
}
const PLANES := {
	"cultivos": [["Abrir retorno de agua", "Ajustar la luz", "Revisar bandejas"], [1, 2, 0]],
}
var pruebas_anexos: Dictionary = {}
var pista_anexo := ""
var zoom_anterior := 1.0
var centro_anterior := Vector2(402, 263.5)
var orientacion_izquierda := false
var retrato: TextureRect


func _ready() -> void:
	get_window().min_size = Vector2i(800, 450)
	_preparar_viento()
	if OS.has_feature("web"):
		_comenzar()
	else:
		_render()


func _process(delta: float) -> void:
	if not is_instance_valid(puesto):
		return
	if operacion == "medicina":
		_actualizar_cuidados(delta)
		if operacion.is_empty():
			return
	if fase == "aterrizaje":
		reloj += delta
		subtitulo.text = ATERRIZAJE[0 if reloj < 4.0 else 1 if reloj < 9.5 else 2]
		if reloj >= 14.0:
			_fin_aterrizaje()
			return
	elif fase == "tregua":
		reloj += delta
		if reloj >= 3.0:
			fase = "extraccion"
			_render()
			return
	elif fase == "esclusa_entrada":
		reloj += delta
		if reloj >= 0.7:
			subtitulo.text = "Puerta exterior cerrada. Igualando la presión con el refugio."
		if reloj >= 1.7:
			posicion = PuestoUmbra.ENTRADA
			fase = "base"
			_render()
			return
	elif fase == "noche":
		reloj += delta
		if reloj >= 3.5:
			fase = "relevo"
			_render()
			return
	elif fase == "taladro":
		reloj += delta
		puesto.avance_muestra = clampf(reloj / 3.8, 0.0, 1.0)
		if reloj >= 1.8:
			subtitulo.text = "Ahí está el hielo. Guárdalo en la caja abierta antes de volver."
		if reloj >= 3.8:
			expedicion.muestra_lista = true
			fase = "sondeo"
			_render()
			return
	elif fase == "hallazgo":
		reloj += delta
		puesto.frente_polvo = smoothstep(0.4, 5.4, reloj)
		if reloj >= 2.7:
			hablante.text = "Iris · Radio de la tripulación"
			retrato.texture = IRIS_ORDEN
			subtitulo.text = "¡Miren el cielo! El polvo ya tapó el sol. Regresamos juntos. Teo, trae la caja."
		if reloj >= 6.7:
			fase = "exterior"
			_render()
			return
	elif fase == "caida":
		reloj += delta
		puesto.tiempo_caida = reloj
		subtitulo.text = "¡Teo! ¡Agárrate!" if reloj < 1.65 else "¡Nora, ven! La camioneta cayó en una zanja. ¡La rueda rota le aprisionó la bota!"
		if reloj >= 4.6:
			posicion.x += 19.0
			fase = "averia"
			reloj = 0.0
			_render()
			return
	elif fase == "averia":
		reloj += delta
		puesto.tiempo_caida = reloj
		if reloj >= 1.3:
			subtitulo.text = "Falló la conexión de los paneles. La base ya está usando su batería."
		if reloj >= 4.8:
			fase = "sujetar"
			reloj = 0.0
			_render()
			return
	elif fase == "apagado":
		reloj += delta
		if reloj >= 3.5:
			fase = "abrigo"
			_render()
			return
	elif fase == "extraccion":
		if puesto.tiempo >= 19.8:
			fase = "evacuacion"
			_render()
			return
	elif fase not in ["decision", "sujetar", "taladro"] and (modulo.is_empty() or operacion == "medicina"):
		var inmovil := tecla_cuidados and ferula_recogida and posicion.distance_to(PuestoUmbra.CAMA_TEO) <= 13.0
		if inmovil:
			puesto.velocidad = Vector2.ZERO
		var direccion := Vector2(
			int(Input.is_physical_key_pressed(KEY_D) or Input.is_action_pressed("ui_right")) -
				int(Input.is_physical_key_pressed(KEY_A) or Input.is_action_pressed("ui_left")),
			int(Input.is_physical_key_pressed(KEY_S) or Input.is_action_pressed("ui_down")) -
				int(Input.is_physical_key_pressed(KEY_W) or Input.is_action_pressed("ui_up")))
		puesto.anclado = not puesto.interior and not puesto.chequeo and Input.is_physical_key_pressed(KEY_SHIFT)
		puesto.avanzar(Vector2.ZERO if inmovil else direccion.normalized(), delta)
		if fase == "salida" and puesto.punto.x > 747:
			fase = "sondeo"
			posicion = puesto.punto - Vector2(PuestoUmbra.DISTANCIA_PANORAMA, 0)
			_render()
			return
		if fase == "evacuacion" and regreso_distante and puesto.punto.x < 56:
			regreso_distante = false
			puesto.campo = false
			puesto.punto.x += PuestoUmbra.DISTANCIA_PANORAMA
		if fase == "exterior" and puesto.punto.x <= PuestoUmbra.INICIO_CAIDA:
			posicion = puesto.punto
			fase = "caida"
			reloj = 0.0
			_render()
			return
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
	if not evento is InputEventKey or evento.echo:
		return
	if evento.physical_keycode == KEY_E and operacion == "medicina":
		tecla_cuidados = evento.pressed
		if evento.pressed and not ferula_recogida and posicion.distance_to(PuestoUmbra.BOTIQUIN) <= 13.0:
			ferula_recogida = true
			puesto.lleva_ferula = true
		return
	if not evento.pressed:
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
	if evento.physical_keycode == KEY_SPACE:
		if fase in ["chequeo", "salida", "exterior"]:
			puesto.saltar()
		return
	if evento.physical_keycode != KEY_E:
		return
	match fase:
		"sujetar":
			_revisar_rueda()
		"abrigo":
			if posicion.distance_to(PuestoUmbra.ABRIGO_TEO) <= 24:
				fase = "tregua"
				reloj = 0.0
				_render()
		"nido":
			var destino: Vector2 = PuestoUmbra.RELES[rele_nido] if rele_nido < PuestoUmbra.RELES.size() else PuestoUmbra.ESCLUSA
			if posicion.distance_to(destino) <= 31.0:
				if rele_nido < PuestoUmbra.RELES.size():
					rele_nido += 1
					puesto.rele_actual = rele_nido
				else:
					_volver_nido(true)
		"chequeo":
			if posicion.distance_to(PuestoUmbra.ESCLUSA) <= 42:
				_salir_expedicion()
		"sondeo":
			_interactuar_sondeo()
		"evacuacion":
			if not regreso_distante and posicion.distance_to(PuestoUmbra.ESCLUSA) <= 42:
				fase = "esclusa_entrada"
				reloj = 0.0
				_render()
		"base":
			var cerca := puesto.terminal_cercana()
			if cerca.is_empty():
				cerca = puesto.inspeccion_cercana()
			if not cerca.is_empty() and modulo.is_empty():
				if _requiere_tarea_principal(cerca):
					terminal_pendiente = cerca
					_actualizar_aviso()
					return
				modulo = cerca
				operacion = ""
				aviso_operacion = ""
				pista_anexo = ""
				if cerca == "radio" and estado.disponible(cerca):
					_abrir_operacion()
					return
				_render()


func _requiere_tarea_principal(id: String) -> bool:
	return SolUno.ACCIONES.has(id) and not estado.mision_cumplida() and id != SolUno.MISIONES[estado.sol - 1]


func _actualizar_aviso() -> void:
	if fase == "sondeo":
		_actualizar_boton_sondeo()
		return
	if not is_instance_valid(aviso):
		return
	if fase == "base":
		var cerca := puesto.terminal_cercana()
		var detalle := puesto.inspeccion_cercana()
		aviso.text = "WASD / flechas · M: plano general"
		if cerca != terminal_pendiente:
			terminal_pendiente = ""
		if is_instance_valid(pista_exploracion):
			if terminal_pendiente.is_empty():
				pista_exploracion.text = guia_exploracion
			else:
				var tarea: String = SolUno.MISIONES[estado.sol - 1]
				pista_exploracion.text = "Primero ve a %s. Puedes volver a %s después." % [NOMBRES[tarea], NOMBRES[cerca]]
		if _requiere_tarea_principal(cerca):
			aviso.text = NOMBRES[cerca] + " · Tarea disponible después del objetivo principal"
		elif not cerca.is_empty():
			aviso.text = "E · " + NOMBRES[cerca] + "   ·   M: plano general"
		elif not detalle.is_empty():
			var ficha: Array = PRUEBAS_ANEXOS[detalle] if PRUEBAS_ANEXOS.has(detalle) else DETALLES[detalle]
			aviso.text = "E · " + str(ficha[0]) + "   ·   M: plano general"
	elif fase == "chequeo":
		aviso.text = "E · Salir con Iris" if posicion.distance_to(PuestoUmbra.ESCLUSA) <= 42 else "A / D o flechas izquierda y derecha · Ve al refugio"
	elif fase == "salida":
		aviso.text = "Derecha · Sal del puesto para llegar al campo de hielo"
	elif fase == "abrigo":
		aviso.text = "E · Esperar tras la roca" if posicion.distance_to(PuestoUmbra.ABRIGO_TEO) <= 24 else "Sigue la marca de abrigo"
	elif fase == "exterior":
		aviso.text = "Izquierda · Corre hacia el refugio"
	elif fase == "evacuacion":
		aviso.text = "Izquierda · Lleva a Teo de vuelta al puesto" if regreso_distante else "E · Abrir la puerta del refugio"
	elif fase == "nido":
		var destino: Vector2 = PuestoUmbra.RELES[rele_nido] if rele_nido < PuestoUmbra.RELES.size() else PuestoUmbra.ESCLUSA
		var objetivo := "PUESTO %d DE %d" % [rele_nido + 1, PuestoUmbra.RELES.size()] if rele_nido < PuestoUmbra.RELES.size() else "VOLVER A LA PUERTA"
		aviso.text = ("E  /  " if posicion.distance_to(destino) <= 31 else "WASD  /  ") + objetivo + "   ·   Esc: retirar a Pluto"
	if fase in ["exterior", "evacuacion", "nido"]:
		if puesto.intensidad_viento() >= 0.55 and not puesto.bajo_abrigo():
			aviso.text += "   ·   ¡VIENTO FUERTE! · Mantén Shift para sujetarte"
		elif puesto.bajo_abrigo():
			aviso.text += "   ·   A CUBIERTO"


func _render() -> void:
	var cambio_de_fase := fase != fase_renderizada
	var tiempo_evacuacion := puesto.tiempo if fase == "esclusa_entrada" and is_instance_valid(puesto) else 0.0
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
	var en_superficie := fase in ["hallazgo", "exterior", "caida", "sujetar", "decision", "averia", "apagado", "abrigo", "tregua", "extraccion", "evacuacion", "nido"]
	if en_superficie and not ambiente.playing:
		ambiente.play()
	elif not en_superficie:
		ambiente.stop()
	_panel(AREA, FONDO, FONDO)
	match fase:
		"inicio":
			_inicio()
		"aterrizaje", "chequeo", "salida", "sondeo", "hallazgo", "exterior", "caida", "abrigo", "tregua", "extraccion", "evacuacion", "nido":
			_superficie()
		"averia":
			_corte_energia()
		"sujetar", "apagado":
			_superficie()
		"taladro":
			_superficie()
		"esclusa_entrada":
			_crear_puesto(false, AREA)
			puesto.tiempo = tiempo_evacuacion
			_panel(AREA, Color(0.11, 0.09, 0.17, 0.64), Color.TRANSPARENT)
			_panel(Rect2(340, 300, 600, 113), FONDO)
			_texto("Pluto · Esclusa del refugio", Rect2(366, 320, 548, 33), 23, CIAN)
			subtitulo = _texto("Cerrando la puerta exterior. La puerta de adentro sigue cerrada.",
				Rect2(366, 359, 545, 45), 17)
		"decision":
			_apertura()
		"base":
			_base()
		"noche":
			_crear_puesto(true, AREA)
			_panel(AREA, Color(0.09, 0.06, 0.18, 0.69), Color.TRANSPARENT)
			_panel(Rect2(345, 298, 590, 125), FONDO)
			_texto("Fin del día %d" % estado.sol, Rect2(372, 320, 535, 45), 30, CIAN)
			_texto(NOCHES[estado.sol - 1], Rect2(373, 371, 529, 44), 17)
		"relevo":
			_relevo()
	if cambio_de_fase and fase == "aterrizaje":
		puesto.modulate.a = 0.18
		puesto.create_tween().tween_property(puesto, "modulate:a", 1.0, 0.36)


func _inicio() -> void:
	_imagen(PuestoUmbra.SENDERO, AREA)
	_panel(Rect2(307, 242, 666, 278), FONDO)
	_texto("PUESTO UMBRA   /   SIMULACIÓN DE UNA MISIÓN A MARTE", Rect2(344, 269, 595, 28), 17, AMBAR)
	_texto("Horizonte Rojo", Rect2(344, 308, 598, 64), 46)
	_texto("Prueba el equipo con Teo. La misión es mantener con vida a la tripulación y enviar evidencia de que el agua local puede sostener el puesto.",
		Rect2(344, 380, 592, 70), 19, MUTED)
	_boton("Iniciar misión", Rect2(344, 460, 592, 40), _comenzar, CIAN)


func _comenzar() -> void:
	fase = "aterrizaje"
	reloj = 0.0
	posicion = Vector2(220, PuestoUmbra.SUELO)
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


func _fin_aterrizaje() -> void:
	fase = "chequeo"
	posicion = Vector2(220, PuestoUmbra.SUELO)
	_render()


func _salir_expedicion() -> void:
	expedicion = ExpedicionHielo.new()
	muestra_procesada = false
	fase = "salida"
	_render()


func _corte_energia() -> void:
	_crear_puesto(false, AREA)
	puesto.corte = true
	puesto.tiempo_caida = 0.0
	_panel(Rect2(260, 514, 760, 129), FONDO)
	_imagen(PuestoUmbra.DRON, Rect2(276, 528, 90, 94), TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	_texto("Pluto · Desde el refugio", Rect2(379, 526, 620, 25), 16, CIAN)
	subtitulo = _texto("La tormenta alcanzó el refugio. ¡Mira el cable de los paneles!",
		Rect2(379, 554, 620, 71), 20)


func _crear_puesto(es_interior: bool, area: Rect2) -> void:
	var marco := Control.new()
	marco.clip_contents = true
	marco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_colocar(marco, area)
	puesto = PuestoUmbra.new()
	puesto.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	puesto.interior = es_interior
	puesto.aterrizaje = fase == "aterrizaje"
	puesto.hallazgo = fase == "hallazgo"
	puesto.caida = fase == "caida"
	puesto.carrera = fase == "exterior"
	puesto.chequeo = fase in ["chequeo", "salida", "sondeo", "taladro"]
	puesto.campo = fase in ["sondeo", "taladro", "hallazgo", "exterior", "caida", "sujetar", "apagado", "decision", "abrigo", "tregua", "extraccion"] or (fase == "evacuacion" and regreso_distante)
	puesto.sondeo = fase == "sondeo"
	puesto.perforando = fase == "taladro"
	if fase in ["exterior", "caida", "sujetar", "decision"]:
		puesto.frente_polvo = 1.0
	elif fase in ["apagado", "abrigo", "tregua", "extraccion", "evacuacion", "esclusa_entrada"]:
		puesto.frente_polvo = 0.65
	puesto.sondeos_hechos = expedicion.examinados
	puesto.caja_abierta = expedicion.muestra_lista and not expedicion.muestra_guardada
	puesto.carga_hielo = expedicion.muestra_guardada
	puesto.reserva_en_prueba = operacion == "energia"
	puesto.desvio_energia = reserva_para_aire
	puesto.mando_nido = fase == "nido"
	puesto.rele_actual = rele_nido
	puesto.plano = ver_plano
	puesto.pruebas_anexos = pruebas_anexos
	puesto.objetivo_mision = "dormitorio" if estado.mision_cumplida() else SolUno.MISIONES[estado.sol - 1]
	puesto.escala_visual = area.size.y / (527.0 if es_interior else 385.0)
	puesto.ancho_visible = area.size.x / puesto.escala_visual
	puesto.scale = Vector2.ONE * puesto.escala_visual
	puesto.evacuacion = fase in ["evacuacion", "esclusa_entrada"]
	puesto.camilla = estado.ruta == SolUno.ESPERA
	puesto.refugio_teo = fase in ["abrigo", "tregua"]
	puesto.extraccion = fase == "extraccion"
	puesto.usa_gato = estado.ruta == SolUno.RESCATE
	puesto.decision = fase == "decision"
	puesto.sujetando_teo = fase in ["sujetar", "apagado"]
	puesto.punto = Vector2(585, PuestoUmbra.SUELO) if fase == "averia" else posicion
	puesto.tiempo = 0.0 if fase in ["aterrizaje", "chequeo", "hallazgo"] else 19.3 if fase == "caida" else 17.0
	puesto.cultivo_activo = estado.cultivo != "En pausa"
	puesto.radio_enviada = estado.ciencia_enviada
	puesto.atendido = estado.recuperacion > 0
	puesto.teo_en_cama = estado.ruta == SolUno.ESPERA and estado.recuperacion == 0
	puesto.teo_recuperado = estado.recuperacion >= 2
	puesto.escala_camara = zoom_anterior
	puesto.centro_camara = centro_anterior
	puesto.direccion_izquierda = orientacion_izquierda
	# Al entrar por la esclusa o despertar, encuadra la posición inicial.
	if es_interior and (zoom_anterior <= 1.0 or puesto.centro_camara.distance_to(posicion) > 100.0):
		puesto.actualizar_camara(1.5)
	marco.add_child(puesto)


func _superficie() -> void:
	_crear_puesto(false, AREA)
	_panel(Rect2(1040, 20, 218, 40), FONDO)
	if expedicion.muestra_guardada:
		_panel(Rect2(930, 67, 328, 36), FONDO)
		var carga := "Nora lleva la caja" if fase == "evacuacion" else "Teo lleva la caja"
		_texto("Muestra de hielo · " + carga, Rect2(944, 75, 309, 25), 16, CIAN)
	_texto("Marte   ·   Día %d de 5" % estado.sol, Rect2(1061, 29, 180, 24), 16, MARFIL)
	if fase in ["exterior", "evacuacion", "nido"]:
		_panel(Rect2(22, 20, 236, 52), FONDO)
		_texto("Fuerza del viento", Rect2(35, 26, 208, 21), 14, AMBAR)
		intensidad_ui = ProgressBar.new()
		intensidad_ui.max_value = 1.0
		intensidad_ui.step = 0.0
		intensidad_ui.show_percentage = false
		intensidad_ui.add_theme_stylebox_override("background", _estilo(PANEL, LINEA))
		intensidad_ui.add_theme_stylebox_override("fill", _estilo(AMBAR, AMBAR))
		_colocar(intensidad_ui, Rect2(35, 50, 209, 9))
	if fase == "sondeo":
		_interfaz_sondeo()
		return
	_panel(Rect2(260, 514, 760, 129), FONDO)
	retrato = _imagen(PuestoUmbra.DRON, Rect2(276, 528, 90, 94), TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	hablante = _texto("Pluto   /   ASISTENTE DE MISIÓN", Rect2(379, 526, 620, 24), 15, CIAN)
	subtitulo = _texto("", Rect2(379, 553, 620, 57), 19)
	if fase == "aterrizaje":
		hablante.text = "Iris · Jefa de la expedición"
		retrato.texture = IRIS_ORDEN
		_boton("Saltar aterrizaje", Rect2(1031, 607, 202, 36), _fin_aterrizaje, AMBAR)
		return
	if fase == "taladro":
		hablante.text = "Iris · Equipo del barranco"
		retrato.texture = IRIS_ORDEN
		subtitulo.text = "El taladro atraviesa la tierra y llega al hielo."
		return
	if fase in ["hallazgo", "caida"]:
		hablante.text = "Iris · Radio de la tripulación" if fase == "caida" else "Teo · Radio de la tripulación"
		retrato.texture = IRIS_ORDEN if fase == "caida" else PuestoUmbra.TEO_NORMAL
		if fase == "hallazgo":
			subtitulo.text = "Caja cerrada. Cuando volvamos podemos derretir esto y ver cuánta agua nos da."
		return
	if fase == "sujetar":
		hablante.text = "Iris · Junto a Teo"
		retrato.texture = IRIS_ORDEN
		subtitulo.text = "La rueda quedó torcida. Ven a ver dónde podemos levantar la camioneta."
		_boton("Revisar la rueda  ·  E", Rect2(379, 603, 616, 34), _revisar_rueda, CIAN)
		return
	if fase == "apagado":
		subtitulo.text = "Guardamos la batería para la base. Iris se queda con Teo. Busca abrigo mientras baja el viento."
		return
	if fase == "extraccion":
		subtitulo.text = "El gato levanta la camioneta. Iris libera la bota. Al volver, apagaremos las luces de cultivo para ahorrar batería." if estado.ruta == SolUno.RESCATE else "El viento bajó un poco. Vamos por Teo con la camilla."
		return
	if fase == "tregua":
		subtitulo.text = "Teo sigue atrapado. Iris prepara la camilla. Esperamos a que el viento dé una tregua."
		return
	match fase:
		"chequeo":
			subtitulo.text = "Soy Pluto. Sigue el camino hacia la derecha. Iris te espera junto a la puerta del refugio."
		"salida":
			retrato.texture = IRIS_ORDEN
			hablante.text = "Iris · En camino al barranco"
			subtitulo.text = "Queda media botella de reserva. Sígueme al barranco. Teo lleva una caja para traer hielo."
		"exterior":
			subtitulo.text = "¡Da la vuelta! Teo viene detrás con la muestra. El viento puede empujarte hacia atrás. Si sopla muy fuerte, mantén Shift para sujetarte."
		"evacuacion":
			subtitulo.text = "Lleva la camilla al refugio. Teo no puede apoyar el pie." if estado.ruta == SolUno.ESPERA else "Teo puede caminar despacio con ayuda de Iris. Guíalos de vuelta al refugio."
		"abrigo":
			subtitulo.text = "Busquemos abrigo tras la roca marcada. Teo sigue junto a la camioneta; no lo moveremos hasta que sea más seguro."
		"nido":
			subtitulo.text = "Tienes mi mando. Enciende las tres cajas de energía por orden y tráeme de vuelta. La tripulación espera bajo techo."
	aviso = _texto("", Rect2(379, 609, 620, 26), 15, CIAN)
	_actualizar_aviso()


func _interfaz_sondeo() -> void:
	_panel(Rect2(271, 594, 738, 104), FONDO)
	var titulo := "Iris · Caja de muestras" if expedicion.muestra_lista else "Iris · ¿Dónde hay hielo?"
	_texto(titulo, Rect2(292, 601, 696, 21), 15, CIAN)
	var guia := "El hielo ya está fuera. Sigue la flecha hasta la caja." if expedicion.muestra_lista else "Compara dos lugares. Busca hielo debajo de la tierra."
	subtitulo = _texto(guia, Rect2(292, 623, 696, 30), 16)
	boton_sondeo = _boton("", Rect2(292, 654, 696, 34), _interactuar_sondeo, CIAN)
	boton_sondeo.focus_mode = Control.FOCUS_NONE
	_actualizar_boton_sondeo()


func _sondeo_cercano() -> int:
	for i in range(PuestoUmbra.SONDEOS.size()):
		if posicion.distance_to(PuestoUmbra.SONDEOS[i]) <= ExpedicionHielo.ALCANCE:
			return i
	return -1


func _cerca_caja() -> bool:
	return posicion.distance_to(PuestoUmbra.CAJA_HIELO) <= ExpedicionHielo.ALCANCE


func _actualizar_boton_sondeo() -> void:
	var sitio := _sondeo_cercano()
	var accion := expedicion.accion(sitio, _cerca_caja())
	boton_sondeo.disabled = accion == ExpedicionHielo.Accion.CAMINAR
	match accion:
		ExpedicionHielo.Accion.EXAMINAR:
			boton_sondeo.text = "Examinar este suelo  ·  E"
		ExpedicionHielo.Accion.PERFORAR:
			boton_sondeo.text = "Perforar aquí  ·  E"
		ExpedicionHielo.Accion.RECOGER:
			boton_sondeo.text = "Guardar hielo en la caja  ·  E"
		_:
			if expedicion.muestra_lista:
				boton_sondeo.text = "Camina a la derecha →  Caja de muestras"
			elif expedicion.examinados.is_empty():
				boton_sondeo.text = "Camina a la derecha →  Busca los aros blancos"
			elif expedicion.examinados.size() == 1:
				boton_sondeo.text = "Camina hasta otro aro blanco para comparar"
			else:
				boton_sondeo.text = "Acércate a una marca para examinar o perforar"


func _interactuar_sondeo() -> void:
	if fase != "sondeo":
		return
	var resultado := expedicion.interactuar(_sondeo_cercano(), _cerca_caja())
	puesto.corte_suelo = expedicion.lectura
	match resultado:
		ExpedicionHielo.Resultado.EXAMINADO:
			subtitulo.text = ExpedicionHielo.LECTURAS[expedicion.lectura]
		ExpedicionHielo.Resultado.SECO:
			puesto.polvo_taladro_hasta = puesto.tiempo + 0.7
			subtitulo.text = "Solo salió tierra. Gastamos 1 punto de batería. Busca hielo debajo del suelo."
		ExpedicionHielo.Resultado.SECO_REPETIDO:
			subtitulo.text = "Iris guarda la batería. Prueba en el lugar con la franja de hielo."
		ExpedicionHielo.Resultado.PERFORANDO:
			fase = "taladro"
			reloj = 0.0
			_render()
			return
		ExpedicionHielo.Resultado.GUARDADO:
			fase = "hallazgo"
			reloj = 0.0
			_render()
			return
	_actualizar_boton_sondeo()


func _revisar_rueda() -> void:
	if fase != "sujetar":
		return
	fase = "decision"
	_render()


func _apertura() -> void:
	_crear_puesto(false, AREA)
	_panel(Rect2(168, 462, 944, 228), FONDO)
	_imagen(IRIS_ORDEN, Rect2(188, 471, 53, 53), TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	_texto("Iris · Teo sigue atrapado", Rect2(263, 473, 820, 27), 20, CIAN)
	_texto("La camioneta tiene una rueda rota. Podemos alzarla ya con el gato eléctrico o esperar una tregua y usar el gato manual.",
		Rect2(263, 504, 817, 48), 18)
	_boton("Ayudar a Teo ahora", Rect2(195, 558, 429, 43), _elegir.bind(SolUno.RESCATE), CIAN)
	_boton("Esperar a que baje el viento", Rect2(655, 558, 429, 43), _elegir.bind(SolUno.ESPERA), AMBAR)
	_texto("Usas 6 puntos de batería. Teo sale antes y las plantas se quedan sin luz.",
		Rect2(196, 611, 424, 65), 17, MUTED)
	_texto("Gastas 4 puntos en el equipo y la espera. Las plantas conservan luz. Teo necesita más cuidados.",
		Rect2(656, 611, 424, 65), 17, MUTED)


func _elegir(ruta: String) -> void:
	if fase != "decision":
		return
	estado.abrir(ruta)
	estado.energia -= expedicion.gasto
	regreso_distante = true
	reloj = 0.0
	fase = "apagado" if ruta == SolUno.ESPERA else "extraccion"
	_render()


func _base() -> void:
	_crear_puesto(true, AREA)
	_panel(Rect2(24, 20, 1232, 40), FONDO)
	_texto("Día %d   ·   Batería %d/24   ·   Comida %d   ·   Agua %d   ·   Tareas restantes %d   ·   Estado del refugio %d%%   ·   Hallazgos %d" % [
		estado.sol, estado.energia, estado.raciones, estado.agua,
		estado.operativos - estado.acciones.size(), estado.soporte, estado.muestras],
		Rect2(43, 28, 1190, 25), 17, MARFIL)
	if expedicion.muestra_guardada and not muestra_procesada:
		_panel(Rect2(913, 67, 343, 36), FONDO)
		_texto("Muestra de hielo · En el refugio", Rect2(929, 74, 312, 26), 16, CIAN)
	if operacion == "medicina":
		_mostrar_cuidados()
		return
	if not modulo.is_empty():
		_terminal()
		return
	_panel(Rect2(213, 608, 854, 98), FONDO)
	_imagen(PuestoUmbra.DRON, Rect2(224, 619, 63, 67), TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	var objetivo: String = SolUno.OBJETIVOS[estado.sol - 1]
	var pista: String = estado.EVENTOS[estado.sol - 1]
	if not estado.mision_cumplida():
		objetivo = "Primero · " + objetivo
		if estado.sol == 1 and expedicion.gasto > 0:
			pista = "El taladro gastó 1 punto en suelo seco. Ve a Energía y devuelve el aire y el calor."
	elif estado.disponible("medicina") and estado.recuperacion < 2:
		objetivo = "Ahora · Elige si dedicas un turno a Teo"
		pista = "Puedes cuidarlo en Enfermería u operar otro equipo. Si lo dejas para mañana, sus cuidados seguirán usando batería."
	else:
		objetivo = "Por último · Descansa en el dormitorio"
		pista = "Cruza Control hacia Enfermería y gira arriba en el corredor. Revisa las reservas antes de cerrar el día."
	if not mensaje.is_empty():
		pista = mensaje
	_texto("Pluto   /   " + objetivo, Rect2(306, 614, 740, 25), 20, CIAN)
	pista_exploracion = _texto(pista, Rect2(306, 642, 740, 38), 16)
	guia_exploracion = pista
	aviso = _texto("", Rect2(306, 682, 740, 20), 14, MUTED)
	_actualizar_aviso()


func _modal(titulo: String, descripcion: String) -> void:
	var sombra := 0.16 if fase == "base" else 0.48
	_panel(AREA, Color(0.03, 0.04, 0.06, sombra), Color.TRANSPARENT)
	_panel(Rect2(282, 193, 716, 345), FONDO, LINEA)
	_imagen(PuestoUmbra.DRON, Rect2(309, 209, 71, 72), TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	_texto(titulo, Rect2(396, 227, 570, 44), 23, CIAN)
	_texto(descripcion, Rect2(308, 292, 661, 72), 20)


func _terminal() -> void:
	if operacion == "radio":
		_radio_en_escena()
		return
	var primer_control := pantalla.get_child_count()
	if modulo == "dormitorio":
		var listo := estado.mision_cumplida()
		var texto := "Por hoy terminamos. Durante la noche usamos 4 puntos de batería, 3 porciones de comida y 2 de agua. Puedes gastar tus turnos restantes antes de descansar."
		if not listo:
			texto = "Primero completa la misión del día. " + SolUno.OBJETIVOS[estado.sol - 1] + ". El marcador indica el módulo."
		_modal("Pluto · Dormitorio", texto)
		_boton("Descansar y terminar el día", Rect2(308, 389, 660, 48), _cerrar, AMBAR, not listo)
	elif modulo == "cierre":
		_modal("Pluto · Puerta del refugio", "Cerramos la puerta exterior y ajustamos la presión antes de abrir la puerta interior. Para ir al dormitorio, cruza Control hacia Enfermería y gira arriba antes de su puerta.")
	elif PRUEBAS_ANEXOS.has(modulo):
		_mostrar_prueba_anexo()
	elif DETALLES.has(modulo):
		var ficha: Array = DETALLES[modulo]
		_modal(str(ficha[0]), str(ficha[1]))
	else:
		_operar_terminal()
	var salida := Rect2(756, 632, 284, 47) if modulo == "medicina" else Rect2(308, 480, 660, 36)
	_boton("Volver al mapa  ·  Esc", salida, _salir_terminal, MUTED)
	if modulo != "medicina":
		for indice in range(primer_control, pantalla.get_child_count()):
			var elemento := pantalla.get_child(indice) as Control
			if elemento.size == AREA.size:
				continue
			elemento.position.y = 438 + (elemento.position.y - 193) * 0.73
			if elemento is Panel:
				elemento.size.y = 252


func _mostrar_prueba_anexo() -> void:
	var prueba: Array = PRUEBAS_ANEXOS[modulo]
	var completa := pruebas_anexos.has(modulo)
	_modal("Pluto · " + str(prueba[0]), str(prueba[4] if completa else prueba[1]))
	if completa:
		_texto("✓  Comprobación terminada", Rect2(308, 392, 660, 40), 20, CIAN)
		return
	_boton(str(prueba[2]), Rect2(308, 378, 320, 44), _resolver_prueba_anexo.bind(true), CIAN)
	_boton(str(prueba[3]), Rect2(648, 378, 320, 44), _resolver_prueba_anexo.bind(false), AMBAR)
	_texto(pista_anexo, Rect2(308, 430, 660, 38), 16, MARFIL)


func _resolver_prueba_anexo(correcta: bool) -> void:
	if correcta:
		pruebas_anexos[modulo] = true
	else:
		pista_anexo = PRUEBAS_ANEXOS[modulo][5]
	_render()


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
				accion = "Recargar la batería"
				descripcion = "3 puntos de batería. Recupera 6 puntos de batería y prepara los paneles para el día siguiente."
				if estado.sol == 4:
					accion = "Tomar el mando de Pluto"
					descripcion = "3 puntos de batería. Pilota a Pluto, enciende las tres cajas de energía de afuera y regresa al refugio. Recuperas 6 puntos de batería."
			"cultivos":
				accion = "Preparar agua con hielo" if estado.sol <= 3 else "Recoger comida"
				descripcion = "4 puntos de batería. El hielo del depósito aporta 4 de agua y 1 dato." if estado.sol <= 3 else "4 puntos de batería. Ajusta el cultivo y recoge 4 raciones."
			"radio":
				accion = "Transmitir informe"
				descripcion = "2 puntos de batería. Alinea la antena para enviar el registro. La confirmación tarda."
	if id == "medicina":
		descripcion = "3 puntos de batería. Teo necesita dos sesiones para volver al equipo. Estado actual: " + estado.paciente
	if estado.acciones.has(id):
		accion = "Tarea completada"
	elif not estado.disponible(id):
		accion = "Reserva batería o turnos para la misión y la noche"
	if id == "medicina":
		_panel(Rect2(213, 525, 854, 179), FONDO)
		_texto("Enfermería · Teo en observación", Rect2(238, 539, 800, 26), 20, CIAN)
		_texto(descripcion, Rect2(238, 573, 802, 54), 18)
		_boton(accion, Rect2(238, 632, 500, 47), _abrir_operacion, CIAN, not estado.disponible(id))
		return
	_modal("Pluto   /   " + titulo, descripcion)
	_boton(accion, Rect2(308, 387, 660, 48), _abrir_operacion, CIAN, not estado.disponible(id))


func _abrir_operacion() -> void:
	if not estado.disponible(modulo):
		return
	if _requiere_tarea_principal(modulo):
		return
	operacion = modulo
	if operacion == "medicina":
		ferula_recogida = false
		tecla_cuidados = false
	if modulo == "energia" and estado.sol == 4:
		regreso_nora = posicion
		posicion = PuestoUmbra.ESCLUSA
		rele_nido = 0
		fase = "nido"
		modulo = ""
		_render()
		return
	paso_operacion = 0
	reserva_para_aire = false
	valvulas = [0, 0, 0]
	ajuste_radio = 0.0
	aviso_operacion = ""
	_render()


func _mostrar_cuidados() -> void:
	puesto.juego_cuidados = true
	puesto.lleva_ferula = ferula_recogida
	_panel(Rect2(213, 600, 854, 104), FONDO)
	_texto("Nora · Cuidar a Teo", Rect2(238, 612, 800, 24), 20, CIAN)
	guia_cuidados = _texto("", Rect2(238, 642, 800, 54), 18)
	guia_cuidados.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_actualizar_cuidados(0.0)


func _actualizar_cuidados(delta: float) -> void:
	var cerca := posicion.distance_to(PuestoUmbra.CAMA_TEO) <= 13.0
	if ferula_recogida and cerca and tecla_cuidados:
		puesto.progreso_cuidados = minf(1.0, puesto.progreso_cuidados + delta / TIEMPO_CUIDADOS)
		if puesto.progreso_cuidados >= 1.0:
			_completar_operacion()
			return
		var avance := roundi(puesto.progreso_cuidados * 100)
		guia_cuidados.text = "Nora está cerrando la correa. Mantén E · %d%%" % avance
	elif ferula_recogida and cerca:
		guia_cuidados.text = "Mantén E junto a Teo para ajustar la correa. Esc cierra la actividad."
	elif ferula_recogida:
		guia_cuidados.text = "Lleva la férula a Teo. Es el soporte que mantiene quieta la pierna."
	else:
		guia_cuidados.text = "Ve al botiquín y pulsa E para recoger el soporte de la pierna."


func _notification(cambio: int) -> void:
	if cambio == NOTIFICATION_APPLICATION_FOCUS_OUT:
		tecla_cuidados = false


func _volver_nido(completado: bool) -> void:
	fase = "base"
	posicion = regreso_nora
	if completado:
		_completar_operacion()
	else:
		operacion = ""
		mensaje = "Pluto regresó. Puedes reintentar la salida desde Energía."
		_render()


func _procedimiento(titulo: String) -> void:
	if operacion == "energia":
		_tablero_energia()
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
	_modal("Pluto   /   " + titulo, pista)
	for columna in range(3):
		var accion: int = ficha[1][columna]
		_boton(pasos[accion], Rect2(306 + columna * 223, 389, 218, 48),
			_ejecutar_paso.bind(accion), CIAN, accion < paso_operacion)


func _radio_en_escena() -> void:
	var objetivo := 29 + estado.sol * 9
	_panel(Rect2(185, 557, 910, 142), FONDO)
	_texto("Control · Enviar a Tierra", Rect2(207, 568, 330, 25), 18, CIAN)
	_boton("Cerrar · Esc", Rect2(934, 568, 141, 30), _salir_terminal, MUTED)
	var pista := "Busca una señal entre los canales %d y %d." % [objetivo - 10, objetivo + 10]
	if not aviso_operacion.is_empty():
		pista = "Señal débil. Mueve el control hasta que aparezca «Listo para enviar»."
	_texto(pista, Rect2(207, 602, 868, 25), 17)
	var dial := HSlider.new()
	dial.max_value = 100
	dial.step = 1
	dial.value = ajuste_radio
	_colocar(dial, Rect2(207, 646, 446, 27))
	detalle_radio = _texto("", Rect2(677, 633, 165, 48), 15, AMBAR)
	_ajustar_radio(ajuste_radio)
	dial.value_changed.connect(_ajustar_radio)
	_boton("Transmitir", Rect2(870, 639, 205, 39), _transmitir.bind(objetivo), CIAN)


func _tablero_energia() -> void:
	var pista := "La reserva puede devolver el aire y el calor. Elige qué alimentar antes de conectar."
	if reserva_para_aire:
		pista = "La línea marcada lleva la reserva al aire y la calefacción. Conéctala para arrancar ambos equipos."
	if not aviso_operacion.is_empty():
		pista = aviso_operacion
	_modal("Pluto · Reparto de batería", pista)
	_boton("Enviar a aire y calor", Rect2(308, 378, 320, 43), _elegir_destino_energia.bind(true), CIAN)
	_boton("Enviar a las luces", Rect2(648, 378, 320, 43), _elegir_destino_energia.bind(false), AMBAR)
	_boton("Conectar la reserva", Rect2(308, 430, 660, 37), _conectar_reserva, CIAN, not reserva_para_aire)


func _elegir_destino_energia(para_aire: bool) -> void:
	reserva_para_aire = para_aire
	aviso_operacion = "" if para_aire else "Las luces podrían encenderse, pero el aire y el calor seguirían apagados. Cambia el destino antes de conectar."
	_render()


func _conectar_reserva() -> void:
	if operacion == "energia" and reserva_para_aire:
		_completar_operacion()


func _circuito_agua() -> void:
	var aviso_agua := "Conecta las tuberías para derretir el hielo y filtrar el agua. Al final, envíala a revisión antes de que llegue al tanque."
	if not aviso_operacion.is_empty():
		aviso_agua = aviso_operacion
	_modal("Pluto   /   CIRCUITO DE AGUA", aviso_agua)
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
	detalle_radio.text = "Canal %d\n%s" % [valor, "Listo para enviar" if diferencia <= 2 else "Señal %d%%" % maxi(0, 100 - int(diferencia * 6))]
	detalle_radio.modulate = CIAN if diferencia <= 2 else Color.WHITE


func _transmitir(objetivo: int) -> void:
	if absf(ajuste_radio - objetivo) <= 2:
		_completar_operacion()
	else:
		aviso_operacion = "Señal débil · Mueve la barra y vuelve a probar"
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
		"energia": mensaje = "El refugio vuelve a tener energía para mantener el aire y el calor."
		"cultivos":
			if estado.sol in [2, 3]:
				muestra_procesada = true
			mensaje = "El agua pasó el filtro y la revisión de calidad. El depósito tiene 4 unidades más." if estado.sol in [2, 3] else "Sala de plantas estabilizado. Revisa las raciones antes de cerrar."
		"medicina": mensaje = "Teo volverá al turno en el día siguiente." if estado.recuperacion >= 2 else "Teo descansa. Falta otra sesión para que vuelva al turno."
		"radio": mensaje = "Informe transmitido. La respuesta de Tierra llegará con retraso."
	_salir_terminal()


func _salir_terminal() -> void:
	tecla_cuidados = false
	modulo = ""
	operacion = ""
	_render()


func _cerrar() -> void:
	if puesto.terminal_cercana() != "dormitorio" or not estado.mision_cumplida():
		return
	fase = "noche"
	reloj = 0.0
	modulo = ""
	_render()


func _relevo() -> void:
	var informe := estado.relevo()
	var final: bool = estado.sol == 5 or informe.soporte <= 0
	var titulo := "Resumen del día %d" % estado.sol
	if final:
		titulo = "Misión interrumpida" if informe.soporte <= 0 else "La base resistió"
		if informe.soporte >= 80 and estado.recuperacion >= 2 and informe.muestras >= 3 and informe.informe_hoy:
			titulo = "Misión completada"
	_imagen(PuestoUmbra.TORMENTA if estado.sol < 5 else EXTERIOR, AREA)
	var reporte := "Batería %d/24 · Comida %d · Agua %d · Estado del refugio %d%%
Datos de misión: %d. Teo: %s." % [
		informe.energia, informe.raciones, informe.agua, informe.soporte, informe.muestras, informe.paciente]
	_modal(titulo, reporte)
	var nota := "Mañana: %d puntos de batería para los cuidados de Teo." % informe.energia_comprometida
	if estado.cultivo == "En pausa":
		nota += " Las plantas siguen a oscuras. Mañana comeremos de la reserva."
	elif estado.sol == 1:
		nota += " Las plantas tienen luz y podrán aportar comida mañana."
	if final:
		if informe.soporte <= 0:
			nota = "Pluto: El refugio agotó su margen de aire y calor."
		elif titulo == "Misión completada":
			nota = "Pluto: El informe salió. Teo volvió al turno y el refugio tiene margen para seguir operando."
		else:
			nota = "Pluto: El informe salió. Queda trabajo en cuidados o aire y calor antes de prolongar la misión."
	_texto(nota, Rect2(308, 378, 661, 59), 18, MUTED)
	if not final:
		_boton("Comenzar día %d" % (estado.sol + 1), Rect2(308, 458, 420, 48), _siguiente_sol, CIAN)
		_boton("Reiniciar", Rect2(746, 458, 222, 48), _reiniciar, MUTED)
	else:
		_boton("Volver al comienzo", Rect2(308, 458, 660, 48), _reiniciar, CIAN)


func _siguiente_sol() -> void:
	estado.siguiente_sol()
	mensaje = ""
	terminal_pendiente = ""
	posicion = PuestoUmbra.TERMINALES.dormitorio
	modulo = ""
	operacion = ""
	fase = "base"
	_render()


func _reiniciar() -> void:
	estado = SolUno.new()
	terminal_pendiente = ""
	expedicion = ExpedicionHielo.new()
	muestra_procesada = false
	pruebas_anexos.clear()
	pista_anexo = ""
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
	if color == FONDO and borde != FONDO:
		estilo.set_corner_radius_all(12)
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
