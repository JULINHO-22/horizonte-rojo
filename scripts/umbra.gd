extends Control

const ExpedicionHielo := preload("res://scripts/expedicion_hielo.gd")
const GuardadoMision := preload("res://scripts/guardado_mision.gd")

const EXTERIOR := preload("res://assets/exterior.jpg")
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
	"agua": ["CENTRO DE AGUA", "La muestra del barranco está en el Centro de agua."],
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
var aviso: Label
var pista_exploracion: Label
var guia_exploracion := ""
var terminal_pendiente := ""
var posicion := Vector2(339, 352)
var reloj := 0.0
var expedicion := ExpedicionHielo.new()
var panel_comprobado := false
var avance_panel := 0.0
var rotulo_ruta: Label
var muestra_procesada := false
var lectura_radio: Label
var accion_radio: Label
var etapa_agua := 0
var avance_agua := 0.0
var tecla_agua := false
var muestra_retenida := false
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
const DURACION_ETAPA_AGUA := 1.55
const PASOS_AGUA := ["Derretir el hielo", "Tratar el agua", "Comprobar que es segura"]
const NOCHES := [
	"El aire y el calor vuelven a funcionar. Mañana probaremos el hielo.",
	"La muestra ya es agua. Mañana le contaremos a Tierra cómo salió la prueba.",
	"El informe viaja a Tierra. Pluto revisará la radio mientras dormimos.",
	"Pluto volvió y el refugio está protegido. Mañana enviaremos los resultados.",
	"El informe final salió. Por primera vez en cinco días, podemos bajar la guardia.",
]
const AREA := Rect2(0, 0, 1280, 720)
const NOMBRES := {"energia": "Energía", "cultivos": "Sala de plantas", "agua": "Centro de agua", "radio": "Control", "cierre": "Puerta del refugio", "dormitorio": "Dormitorio"}
const DETALLES := {
	"aire": ["Reciclador de aire", "Este equipo retira del aire lo que soltamos al respirar. Afuera usamos el aire del traje. Con la puerta sellada, el refugio mantiene aire respirable."],
	"mapa": ["Mapa de la expedición", "El barranco queda lejos del refugio. En el visor comparamos la escarcha con el hielo bajo tierra antes de elegir dónde perforar."],
	"plantas": ["Jardineras", "Las hojas necesitan luz y agua. Si ahorramos batería apagando las luces, mañana tendremos menos comida."],
	"literas": ["Las literas", "Nora dibujó el barranco en la pared. Iris dejó marcada la hora del próximo mensaje. La manta de Teo está lista para cuando pueda volver."],
	"rover_taller": ["Camioneta de repuesto", "Es un vehículo de reserva. Iris lo dejó limpio, con las ruedas en alto, para revisar los ejes dentro del taller."],
	"repuestos": ["Estante de repuestos", "Las juntas mantienen el polvo fuera. Los guantes gruesos protegen las manos cuando toca cambiar piezas afuera."],
}
const PRUEBAS_ANEXOS := {
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
func _ready() -> void:
	get_window().min_size = Vector2i(800, 450)
	_preparar_viento()
	if _recuperar_punto():
		_render()
	elif OS.has_feature("web"):
		_comenzar()
	else:
		_render()


func _process(delta: float) -> void:
	if not is_instance_valid(puesto):
		return
	if operacion == "agua":
		_actualizar_agua(delta)
		if operacion.is_empty():
			return
	if fase == "aterrizaje":
		reloj += delta
		subtitulo.text = "Iris · " + ATERRIZAJE[0 if reloj < 4.0 else 1 if reloj < 9.5 else 2]
		if reloj >= 14.0:
			_fin_aterrizaje()
			return
	elif fase == "esclusa_entrada":
		reloj += delta
		puesto.avance_esclusa = reloj
		puesto.punto.y = 440.0 - 43.0 * smoothstep(0.68, 1.36, reloj) - 49.0 * smoothstep(2.6, 3.45, reloj)
		puesto.caminando = (reloj > 0.68 and reloj < 1.36) or (reloj > 2.6 and reloj < 3.45)
		puesto.paso = fposmod(reloj * 2.5, 1.0)
		puesto.actualizar_camara(delta)
		if reloj >= 2.22:
			lectura_radio.text = "Pluto · Ya hay aire seguro. Se abre la puerta interior."
		elif reloj >= 1.62:
			lectura_radio.text = "Pluto · Cerramos la puerta de fuera. Estamos llenando de aire la sala."
		if reloj >= 3.5:
			posicion = puesto.punto
			fase = "base"
			_guardar_punto()
			_render()
			return
	elif fase == "noche":
		reloj += delta
		if reloj >= 3.5:
			fase = "relevo"
			_guardar_punto()
			_render()
			return
	elif fase == "taladro":
		reloj += delta
		puesto.avance_muestra = clampf(reloj / 3.8, 0.0, 1.0)
		if reloj >= 1.8:
			lectura_radio.text = "Iris · Salió un trozo de hielo con tierra. Déjame bajarlo al suelo."
		if reloj >= 3.8:
			expedicion.muestra_lista = true
			fase = "sondeo"
			_render()
			return
	elif fase == "hallazgo":
		reloj += delta
		puesto.frente_polvo = smoothstep(0.4, 5.4, reloj)
		if reloj >= 2.7:
			lectura_radio.text = "Iris · ¡El polvo está tapando el sol! Teo, trae la caja. Volvemos juntos."
		if reloj >= 6.7:
			fase = "exterior"
			_guardar_punto()
			_render()
			return
	elif fase == "averia":
		reloj += delta
		puesto.tiempo_averia = reloj
		if reloj >= 1.3:
			lectura_radio.text = "Pluto · El polvo tapó los paneles. La reserva sostiene el aire y el calor. Apagué las luces de cultivo."
		if reloj >= 4.8:
			estado.iniciar_regreso(expedicion.gasto)
			fase = "evacuacion"
			regreso_distante = true
			_guardar_punto()
			_render()
			return
	elif modulo.is_empty() or operacion == "agua":
		var inmovil := tecla_agua and _cerca_equipo_agua()
		if inmovil:
			puesto.velocidad = Vector2.ZERO
		var direccion := Vector2(
			int(Input.is_physical_key_pressed(KEY_D) or Input.is_action_pressed("ui_right")) -
				int(Input.is_physical_key_pressed(KEY_A) or Input.is_action_pressed("ui_left")),
			int(Input.is_physical_key_pressed(KEY_S) or Input.is_action_pressed("ui_down")) -
				int(Input.is_physical_key_pressed(KEY_W) or Input.is_action_pressed("ui_up")))
		puesto.anclado = not puesto.interior and not puesto.chequeo and Input.is_physical_key_pressed(KEY_SHIFT)
		puesto.avanzar(Vector2.ZERO if inmovil else direccion.normalized(), delta)
		if fase == "chequeo":
			_actualizar_panel_solar(delta, direccion.x)
			if panel_comprobado and absf(puesto.punto.x - PuestoUmbra.ESCLUSA.x) <= 24.0:
				posicion = puesto.punto
				_salir_expedicion()
				return
			_actualizar_rotulo_ruta()
		if fase == "salida" and puesto.punto.x > 747:
			fase = "sondeo"
			posicion = puesto.punto - Vector2(PuestoUmbra.DISTANCIA_PANORAMA, 0)
			_render()
			return
		if fase == "evacuacion" and regreso_distante and puesto.punto.x < 56:
			regreso_distante = false
			puesto.campo = false
			puesto.punto.x += PuestoUmbra.DISTANCIA_PANORAMA
		if fase == "evacuacion" and not regreso_distante and absf(puesto.punto.x - PuestoUmbra.ESCLUSA.x) <= 12.0:
			fase = "esclusa_entrada"
			reloj = 0.0
			_render()
			return
		if fase == "exterior" and puesto.punto.x <= PuestoUmbra.PUNTO_AVISO:
			posicion = puesto.punto
			fase = "averia"
			reloj = 0.0
			_render()
			return
		posicion = puesto.punto
		puesto.actualizar_camara(delta)
		if fase == "sondeo" and expedicion.muestra_en_mano and _cerca_caja():
			expedicion.guardar_muestra()
			fase = "hallazgo"
			reloj = 0.0
			_render()
			return
		_actualizar_aviso()
		if fase == "evacuacion":
			_actualizar_regreso()
	puesto.tiempo += delta
	if ambiente.playing:
		ambiente.volume_db = lerpf(-23.0, -4.0, puesto.intensidad_viento())
	if is_instance_valid(intensidad_ui):
		intensidad_ui.value = puesto.intensidad_viento()
	puesto.queue_redraw()


func _unhandled_key_input(evento: InputEvent) -> void:
	if not evento is InputEventKey or evento.echo:
		return
	if evento.physical_keycode == KEY_E and operacion == "agua":
		tecla_agua = evento.pressed and _cerca_equipo_agua()
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
		"nido":
			var destino: Vector2 = PuestoUmbra.RELES[rele_nido] if rele_nido < PuestoUmbra.RELES.size() else PuestoUmbra.ESCLUSA
			if posicion.distance_to(destino) <= 31.0:
				if rele_nido < PuestoUmbra.RELES.size():
					rele_nido += 1
					puesto.rele_actual = rele_nido
				else:
					_volver_nido(true)
		"sondeo":
			_interactuar_sondeo()
		"base":
			var cerca := puesto.terminal_cercana()
			if cerca.is_empty():
				cerca = puesto.inspeccion_cercana()
			if not cerca.is_empty() and modulo.is_empty():
				if cerca == "agua" and (estado.sol != 2 or muestra_procesada):
					mensaje = "Aquí tratamos y comprobamos el agua antes de enviarla al tanque."
					_render()
					return
				if _requiere_tarea_principal(cerca):
					terminal_pendiente = cerca
					_actualizar_aviso()
					return
				modulo = cerca
				operacion = ""
				aviso_operacion = ""
				pista_anexo = ""
				if cerca in ["radio", "agua"] and estado.disponible(cerca):
					_abrir_operacion()
					return
				_render()


func _requiere_tarea_principal(id: String) -> bool:
	if id == "agua" and estado.sol != 2:
		return false
	return SolUno.ACCIONES.has(id) and not estado.mision_cumplida() and id != SolUno.MISIONES[estado.sol - 1]


func _actualizar_aviso() -> void:
	if fase == "sondeo":
		_actualizar_sondeo()
		return
	if not is_instance_valid(aviso):
		return
	if fase == "base" and operacion.is_empty():
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
	elif fase == "salida":
		aviso.text = "Derecha · Sal del puesto para llegar al campo de hielo"
	elif fase == "exterior":
		aviso.text = "Izquierda · Corre hacia el refugio"
	elif fase == "nido":
		var destino: Vector2 = PuestoUmbra.RELES[rele_nido] if rele_nido < PuestoUmbra.RELES.size() else PuestoUmbra.ESCLUSA
		var objetivo := "PUESTO %d DE %d" % [rele_nido + 1, PuestoUmbra.RELES.size()] if rele_nido < PuestoUmbra.RELES.size() else "VOLVER A LA PUERTA"
		aviso.text = ("E  /  " if posicion.distance_to(destino) <= 31 else "WASD  /  ") + objetivo + "   ·   Esc: retirar a Pluto"
	if fase in ["exterior", "nido"]:
		if puesto.intensidad_viento() >= 0.55 and not puesto.bajo_abrigo():
			aviso.text += "   ·   ¡VIENTO FUERTE! · Mantén Shift para sujetarte"
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
	var en_superficie := fase in ["hallazgo", "exterior", "averia", "evacuacion", "nido"]
	if en_superficie and not ambiente.playing:
		ambiente.play()
	elif not en_superficie:
		ambiente.stop()
	_panel(AREA, FONDO, FONDO)
	match fase:
		"inicio":
			_inicio()
		"chequeo":
			_recorrido_pluto()
		"aterrizaje", "salida", "exterior", "nido":
			_superficie()
		"averia":
			_corte_energia()
		"sondeo", "taladro", "hallazgo":
			_camino_del_hielo()
		"esclusa_entrada":
			posicion = Vector2(402, 440)
			_crear_puesto(true, AREA)
			puesto.esclusa_activa = true
			puesto.actualizar_camara(1.5)
			_radio_de_campo("Pluto · Pasen de la tormenta a la sala de entrada.", 638.0)
		"evacuacion":
			_crear_puesto(false, AREA)
			_radio_de_campo("Iris · Seguimos juntos. Teo lleva la muestra. Volvamos al refugio.")
			_actualizar_regreso()
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
	panel_comprobado = false
	avance_panel = 0.0
	fase = "chequeo"
	posicion = Vector2(220, PuestoUmbra.SUELO)
	_guardar_punto()
	_render()


func _salir_expedicion() -> void:
	expedicion = ExpedicionHielo.new()
	muestra_procesada = false
	fase = "salida"
	_guardar_punto()
	_render()


func _recorrido_pluto() -> void:
	_crear_puesto(false, AREA)
	puesto.guia_pluto = true
	puesto.panel_comprobado = panel_comprobado
	puesto.pluto_superficie_x = minf(posicion.x + 35.0, PuestoUmbra.ESCLUSA.x - 14.0)
	rotulo_ruta = _texto("", Rect2(0, 0, 416, 40), 18, MARFIL)
	rotulo_ruta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rotulo_ruta.add_theme_color_override("font_outline_color", Color("#131820"))
	rotulo_ruta.add_theme_constant_override("outline_size", 6)
	_actualizar_rotulo_ruta()


func _actualizar_panel_solar(delta: float, movimiento: float) -> void:
	if panel_comprobado:
		return
	var sobre_marca := absf(puesto.punto.x - PuestoUmbra.REVISION_SOLAR.x) <= 30.0
	var leyendo := sobre_marca and is_zero_approx(movimiento)
	avance_panel = move_toward(avance_panel, 1.0 if leyendo else 0.0, delta / 0.75)
	puesto.avance_panel = avance_panel
	if avance_panel >= 1.0:
		panel_comprobado = true
		puesto.panel_comprobado = true
		posicion = puesto.punto
		_guardar_punto()


func _actualizar_rotulo_ruta() -> void:
	var destino := PuestoUmbra.ESCLUSA if panel_comprobado else PuestoUmbra.REVISION_SOLAR
	var cerca_panel := panel_comprobado and absf(puesto.punto.x - PuestoUmbra.REVISION_SOLAR.x) < 76.0
	if cerca_panel:
		rotulo_ruta.text = "Pluto · Los paneles están dando energía"
	elif panel_comprobado:
		rotulo_ruta.text = "Reúnete con Iris"
	elif absf(puesto.punto.x - destino.x) <= 48.0:
		rotulo_ruta.text = "Para en la luz. Pluto está revisando los paneles."
	else:
		rotulo_ruta.text = "A / D o flechas · Sigue a Pluto"
	var ancla := PuestoUmbra.REVISION_SOLAR if cerca_panel else destino
	if not cerca_panel and absf(puesto.punto.x - destino.x) > 140.0:
		ancla.x = puesto.pluto_superficie_x
	var punto_rotulo := puesto.proyectar_suelo(ancla - Vector2(0, 96))
	rotulo_ruta.position = Vector2(clampf(punto_rotulo.x - 208.0, 26.0, 838.0), punto_rotulo.y)


func _corte_energia() -> void:
	_crear_puesto(false, AREA)
	puesto.corte = true
	puesto.tiempo_averia = 0.0
	_radio_de_campo("Pluto · La tormenta llegó a la base. ¡Mira el cable!")


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
	puesto.carrera = fase == "exterior"
	puesto.chequeo = fase in ["chequeo", "salida", "sondeo", "taladro"]
	puesto.campo = fase in ["sondeo", "taladro", "hallazgo", "exterior"] or (fase == "evacuacion" and regreso_distante)
	puesto.sondeo = fase == "sondeo"
	puesto.perforando = fase == "taladro"
	if fase == "exterior":
		puesto.frente_polvo = 1.0
	elif fase in ["evacuacion", "esclusa_entrada"]:
		puesto.frente_polvo = 0.65
	puesto.sondeos_hechos = expedicion.examinados
	puesto.caja_abierta = expedicion.muestra_lista and not expedicion.muestra_guardada
	puesto.hielo_en_mano = expedicion.muestra_en_mano
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
	puesto.punto = Vector2(585, PuestoUmbra.SUELO) if fase == "averia" else posicion
	puesto.tiempo = 0.0 if fase in ["aterrizaje", "chequeo", "hallazgo"] else 17.0
	puesto.cultivo_activo = estado.cultivo != "En pausa"
	puesto.radio_enviada = estado.ciencia_enviada
	puesto.escala_camara = zoom_anterior
	puesto.centro_camara = centro_anterior
	puesto.direccion_izquierda = orientacion_izquierda
	# Al entrar por la esclusa o despertar, encuadra la posición inicial.
	if es_interior and (zoom_anterior <= 1.0 or puesto.centro_camara.distance_to(posicion) > 100.0):
		puesto.actualizar_camara(1.5)
	marco.add_child(puesto)
	if es_interior and fase == "base" and not puesto.transitable(posicion):
		posicion = PuestoUmbra.ENTRADA
		puesto.punto = posicion
		puesto.actualizar_camara(1.5)


func _superficie() -> void:
	_crear_puesto(false, AREA)
	_panel(Rect2(1040, 20, 218, 40), FONDO)
	if expedicion.muestra_guardada:
		_panel(Rect2(930, 67, 328, 36), FONDO)
		_texto("Muestra de hielo · Teo lleva la caja", Rect2(944, 75, 309, 25), 16, CIAN)
	_texto("Marte   ·   Día %d de 5" % estado.sol, Rect2(1061, 29, 180, 24), 16, MARFIL)
	if fase in ["exterior", "nido"]:
		_panel(Rect2(22, 20, 236, 52), FONDO)
		_texto("Fuerza del viento", Rect2(35, 26, 208, 21), 14, AMBAR)
		intensidad_ui = ProgressBar.new()
		intensidad_ui.max_value = 1.0
		intensidad_ui.step = 0.0
		intensidad_ui.show_percentage = false
		intensidad_ui.add_theme_stylebox_override("background", _estilo(PANEL, LINEA))
		intensidad_ui.add_theme_stylebox_override("fill", _estilo(AMBAR, AMBAR))
		_colocar(intensidad_ui, Rect2(35, 50, 209, 9))
	_radio_de_campo("")
	aviso = accion_radio
	match fase:
		"aterrizaje":
			subtitulo = lectura_radio
			subtitulo.text = "Iris · " + ATERRIZAJE[0]
			_boton("Saltar aterrizaje", Rect2(1037, 641, 202, 36), _fin_aterrizaje, AMBAR)
		"salida":
			lectura_radio.text = "Iris · Teo trae la caja fría. Busquemos hielo para reponer el agua de las botellas."
		"exterior":
			lectura_radio.text = "Pluto · Teo viene detrás con la muestra. Volvamos por el camino."
		"nido":
			lectura_radio.text = "Pluto · Enciende las tres cajas en orden. La tripulación espera bajo techo."
	_actualizar_aviso()


func _radio_de_campo(frase: String, altura := 572.0) -> void:
	_panel(Rect2(248, altura, 784, 55), Color("#171c25ed"), Color("#394752"))
	lectura_radio = _texto(frase, Rect2(270, altura + 5, 740, 43), 19)
	lectura_radio.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lectura_radio.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	accion_radio = _texto("", Rect2(210, 645, 860, 36), 17, CIAN)
	accion_radio.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	accion_radio.add_theme_color_override("font_outline_color", Color("#131820"))
	accion_radio.add_theme_constant_override("outline_size", 4)


func _camino_del_hielo() -> void:
	_crear_puesto(false, AREA)
	match fase:
		"sondeo":
			_radio_de_campo("Iris · Compara dos sitios. El hielo puede estar bajo la tierra.")
			_actualizar_sondeo()
		"taladro":
			_radio_de_campo("Iris · Voy a perforar donde vimos la veta.")
		"hallazgo":
			_radio_de_campo("Teo · Cierro la caja. En la base veremos si podemos usar esa agua.")


func _sondeo_cercano() -> int:
	for i in range(PuestoUmbra.SONDEOS.size()):
		if posicion.distance_to(PuestoUmbra.SONDEOS[i]) <= ExpedicionHielo.ALCANCE:
			return i
	return -1


func _cerca_caja() -> bool:
	return posicion.distance_to(PuestoUmbra.CAJA_HIELO) <= 9.0


func _actualizar_sondeo() -> void:
	if expedicion.muestra_en_mano:
		accion_radio.text = "Camina hasta la caja abierta para guardar la muestra."
		return
	var sitio := _sondeo_cercano()
	match expedicion.accion(sitio):
		ExpedicionHielo.Accion.EXAMINAR:
			accion_radio.text = "Pulsa E junto a la marca para mirar bajo el suelo."
		ExpedicionHielo.Accion.PERFORAR:
			accion_radio.text = "Pulsa E para perforar aquí."
		ExpedicionHielo.Accion.RECOGER:
			accion_radio.text = "Pulsa E junto al hielo para recogerlo."
		_:
			if expedicion.muestra_lista:
				accion_radio.text = "Acércate al hielo que dejó Iris junto al taladro."
			else:
				accion_radio.text = "Usa A o D, o las flechas, para acercarte a las marcas."


func _interactuar_sondeo() -> void:
	if fase != "sondeo":
		return
	var resultado := expedicion.interactuar(_sondeo_cercano())
	puesto.corte_suelo = expedicion.lectura
	match resultado:
		ExpedicionHielo.Resultado.EXAMINADO:
			lectura_radio.text = "Iris · " + ExpedicionHielo.LECTURAS[expedicion.lectura]
		ExpedicionHielo.Resultado.SECO:
			puesto.polvo_taladro_hasta = puesto.tiempo + 0.7
			lectura_radio.text = "Iris · Salió tierra. El taladro usó un punto de la carga."
		ExpedicionHielo.Resultado.SECO_REPETIDO:
			lectura_radio.text = "Iris · Guardemos la carga. Prueba donde viste la veta de hielo."
		ExpedicionHielo.Resultado.PERFORANDO:
			fase = "taladro"
			reloj = 0.0
			_render()
			return
		ExpedicionHielo.Resultado.EN_MANO:
			puesto.hielo_en_mano = true
			lectura_radio.text = "Iris · Llévalo a la caja fría para que no se mezcle con el polvo."
	_actualizar_sondeo()


func _actualizar_regreso() -> void:
	if not regreso_distante and posicion.distance_to(PuestoUmbra.ESCLUSA) <= 42.0:
		accion_radio.text = "Acércate a la puerta. La abriremos al llegar."
	elif puesto.intensidad_viento() >= 0.55 and not puesto.bajo_abrigo():
		accion_radio.text = "Viento fuerte. Mantén Shift para sujetarte."
	else:
		accion_radio.text = "Sigue el camino de vuelta al refugio."


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
	if operacion == "agua":
		_radio_de_campo("")
		_actualizar_agua(0.0)
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
	else:
		objetivo = "Por último · Descansa en el dormitorio"
		pista = "Desde Control, toma el corredor este y gira hacia arriba. Revisa las reservas antes de cerrar el día."
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
		_modal("Pluto · Puerta del refugio", "Cerramos la puerta exterior y ajustamos la presión antes de abrir la puerta interior. Para ir al dormitorio, cruza Control por el corredor este y gira hacia arriba.")
	elif PRUEBAS_ANEXOS.has(modulo):
		_mostrar_prueba_anexo()
	elif DETALLES.has(modulo):
		var ficha: Array = DETALLES[modulo]
		_modal(str(ficha[0]), str(ficha[1]))
	else:
		_operar_terminal()
	_boton("Volver al mapa  ·  Esc", Rect2(308, 480, 660, 36), _salir_terminal, MUTED)
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
		_guardar_punto()
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
				accion = "Recoger comida"
				descripcion = "Usa 4 puntos de carga para cuidar las plantas y recoger 4 raciones."
			"radio":
				accion = "Transmitir informe"
				descripcion = "2 puntos de batería. Alinea la antena para enviar el registro. La confirmación tarda."
	if id == "agua" and not estado.disponible(id):
		descripcion = "Quedan pocos turnos o poca carga. Ve a Energía si necesitas recargar para tratar el agua."
	if estado.acciones.has(id):
		accion = "Tarea completada"
	elif not estado.disponible(id):
		accion = "Reserva batería o turnos para la misión y la noche"
	_modal("Pluto   /   " + titulo, descripcion)
	_boton(accion, Rect2(308, 387, 660, 48), _abrir_operacion, CIAN, not estado.disponible(id))


func _abrir_operacion() -> void:
	if not estado.disponible(modulo):
		return
	if _requiere_tarea_principal(modulo):
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
	reserva_para_aire = false
	etapa_agua = 0
	avance_agua = 0.0
	tecla_agua = false
	muestra_retenida = false
	ajuste_radio = 0.0
	aviso_operacion = ""
	_render()


func _notification(cambio: int) -> void:
	if cambio == NOTIFICATION_APPLICATION_FOCUS_OUT:
		tecla_agua = false


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


func _cerca_equipo_agua() -> bool:
	return posicion.distance_to(PuestoUmbra.EQUIPO_AGUA[etapa_agua]) <= PuestoUmbra.ALCANCE_AGUA


func _actualizar_agua(delta: float) -> void:
	var cerca := _cerca_equipo_agua()
	if cerca and tecla_agua:
		avance_agua = minf(1.0, avance_agua + delta / DURACION_ETAPA_AGUA)
		if avance_agua >= 1.0:
			if etapa_agua == PASOS_AGUA.size() - 1:
				if muestra_retenida:
					_completar_operacion()
					return
				muestra_retenida = true
				etapa_agua = 1
			else:
				etapa_agua += 1
			avance_agua = 0.0
			tecla_agua = false
			cerca = _cerca_equipo_agua()
	puesto.agua_en_curso = true
	puesto.etapa_agua = etapa_agua
	puesto.avance_agua = avance_agua
	var explicacion := [
		"La caja trajo hielo con tierra. Derrítelo en el equipo marcado.",
		"El agua sigue turbia. Pásala por el equipo que quita las impurezas.",
		"Se ve clara. Comprueba que sea segura antes de enviarla al tanque.",
	]
	var lectura: String = explicacion[etapa_agua]
	if muestra_retenida and etapa_agua == 1:
		lectura = "La prueba detectó impurezas. El tanque sigue cerrado. Vuelve a tratar la muestra."
	lectura_radio.text = "Pluto · " + lectura
	var instruccion: String = "Mantén E para " + PASOS_AGUA[etapa_agua].to_lower() if cerca else "Camina hasta el equipo marcado."
	accion_radio.text = instruccion + "   ·   Carga al terminar: %d puntos   ·   Esc para salir" % SolUno.ACCIONES.agua.costo


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
			mensaje = "Plantas protegidas. Revisa las raciones antes de cerrar."
		"agua":
			muestra_procesada = true
			mensaje = "La muestra pasó la revisión. El tanque tiene 4 unidades más de agua segura."
		"radio": mensaje = "Informe transmitido. La respuesta de Tierra llegará con retraso."
	_guardar_punto()
	_salir_terminal()


func _salir_terminal() -> void:
	tecla_agua = false
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
		if informe.soporte >= 80 and informe.muestras >= 3 and informe.informe_hoy:
			titulo = "Misión completada"
	_imagen(PuestoUmbra.TORMENTA if estado.sol < 5 else EXTERIOR, AREA)
	var reporte := "Batería %d/24 · Comida %d · Agua %d · Estado del refugio %d%%
Datos de misión: %d." % [
		informe.energia, informe.raciones, informe.agua, informe.soporte, informe.muestras]
	_modal(titulo, reporte)
	var nota := "Mañana comienza un nuevo turno."
	if estado.cultivo == "En pausa":
		nota += " Las plantas siguen a oscuras. Mañana comeremos de la reserva."
	elif estado.sol == 1:
		nota += " Las plantas tienen luz y podrán aportar comida mañana."
	if final:
		if informe.soporte <= 0:
			nota = "Pluto: El refugio agotó su margen de aire y calor."
		elif titulo == "Misión completada":
			nota = "Pluto: El informe salió. La tripulación y el refugio tienen margen para seguir operando."
		else:
			nota = "Pluto: El informe salió. Queda trabajo en las reservas o el soporte vital antes de prolongar la misión."
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
	_guardar_punto()
	_render()


func _reiniciar() -> void:
	GuardadoMision.borrar()
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


func _guardar_punto() -> void:
	var punto := {
		"fase": fase,
		"posicion": posicion,
		"panel_comprobado": panel_comprobado,
		"carga_hielo": expedicion.muestra_guardada,
		"gasto_taladro": expedicion.gasto,
		"muestra_procesada": muestra_procesada,
		"regreso_distante": regreso_distante,
		"pruebas_anexos": pruebas_anexos,
		"mensaje": mensaje,
	}
	if not GuardadoMision.guardar(punto, estado):
		push_warning("No se pudo guardar el punto de misión.")


func _recuperar_punto() -> bool:
	var punto := GuardadoMision.cargar(estado)
	if punto.is_empty():
		return false
	fase = punto.fase
	posicion = punto.posicion
	panel_comprobado = punto.get("panel_comprobado", false) == true
	expedicion.muestra_guardada = punto.get("carga_hielo", false) == true
	expedicion.gasto = 1 if punto.get("gasto_taladro", 0) == 1 else 0
	muestra_procesada = punto.get("muestra_procesada", false) == true
	regreso_distante = punto.get("regreso_distante", false) == true
	var pruebas: Variant = punto.get("pruebas_anexos")
	if pruebas is Dictionary and pruebas.get("sello_traje", false) == true:
		pruebas_anexos["sello_traje"] = true
	mensaje = str(punto.get("mensaje", ""))
	reloj = 0.0
	return true


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
