extends Control

signal finalizado(resultado: Dictionary)
signal avance_plantas_guardado

const Recursos := preload("res://scripts/mecanicas/recursos_mision.gd")
const Invernadero := preload("res://scripts/invernadero_umbra.gd")
const HUD := preload("res://scenes/dias/dia_2/dia_2_hud.gd")
const PanelControl := preload("res://scripts/panel_control.gd")
var panel_control: PanelControl
const Taller := preload("res://scenes/dias/dia_2/taller_dia_2.gd")
const AudioDia2 := preload("res://scenes/dias/dia_2/dia_2_audio.gd")

const REPARAR := "dia_2_reparar"
const RESGUARDARSE := "dia_2_resguardarse"
const DANOS_DIA_3 := "dia_3_danos_del_dia_2"
const COSTO_REPARAR := {"energia": -4, "alimento": -1}

const CONTROL: Vector2 = PuestoUmbra.TERMINALES.radio
const SALIDA := Vector2(402, 382)
const PANELES := PuestoUmbra.REVISION_SOLAR
const AIRE := PuestoUmbra.ESTACION_OXIGENO
const AGUA := Vector2(25, 27)
const PLANTAS := Vector2(405, 99)
const CAMA := Vector2(681, 89)

const CRUCE_SUR := Vector2(402, 245)
const CRUCE_OESTE := Vector2(192, 245)
const GIRO_AGUA := Vector2(192, 42)
const ENTRADA_AGUA := Vector2(164, 44)
const CRUCE_ESTE := Vector2(538, 245)
const GIRO_ESTE := Vector2(538, 131)
const GIRO_PLANTAS := Vector2(405, 131)
const GIRO_CAMA := Vector2(681, 131)

enum Paso { DECISION, SALIR, REPARAR, ENTRAR, AIRE, PLANTAS, DESCANSO }

const OBJETIVOS := {
	Paso.DECISION: [CONTROL, "1 · Elige tu plan", "El polvo tapa la luz. Hoy los paneles no cargan.\nConsulta las opciones en la computadora.", "Elegir plan en Control"],
	Paso.SALIR: [SALIDA, "3 · Sal por la esclusa", "Tu aire está listo. Ve a proteger los equipos.\nTodavía puedes volver y cambiar de plan.", "Salir al exterior"],
	Paso.REPARAR: [PANELES, "3 · Sujeta los equipos", "Alinea y fija 3 cierres entre las ráfagas.\nSigue la marca hasta los paneles.", "Abrir caja de herramientas"],
	Paso.ENTRAR: [PuestoUmbra.ESCLUSA, "4 · Vuelve a casa", "¡Los equipos están protegidos!\nLos paneles cargarán cuando pase la tormenta.", "Entrar al refugio"],
	Paso.AIRE: [AIRE, "2 · Prepara el aire", "Ve a los tanques verdes del laboratorio.\nAgua + energía nos ayudan a tener aire.", "Conectar aire · 6 energía + 1 agua"],
	Paso.PLANTAS: [PLANTAS, "Una pausa para comer", "Recoge una cosecha lista o visita la bandeja de lechuga.\nCuando termines, vuelve al dormitorio.", "Atender las bandejas"],
	Paso.DESCANSO: [CAMA, "4 · A descansar", "Aire listo, comida lista. ¡Buen trabajo!\nAcércate a la cama para terminar el día.", "Terminar el Sol 2"],
}

var taller: Taller
var huerto: Invernadero
var salida_pendiente := false
var recursos: Recursos
var puesto: PuestoUmbra
var interfaz: HUD
var audio: AudioDia2
var paneles: Label
var oscuridad: ColorRect
var ruta: Array[Vector2] = []
var paso := Paso.DECISION
var local := false
var abierto := false
var en_pausa := false
var concluido := false
var reservas_entrada: Dictionary
var aviso := ""

func configurar(partida: Recursos) -> void:
	assert(not is_inside_tree())
	recursos = partida

func _ready() -> void:
	clip_contents = true
	var fondo := ColorRect.new()
	fondo.color = Color("#10151c")
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fondo)

	puesto = PuestoUmbra.new()
	puesto.laboratorio_activo = true
	puesto.pluto_acompana = true
	puesto.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(puesto)

	audio = AudioDia2.new()
	add_child(audio)

	paneles = Label.new()
	paneles.text = "PANELES SOLARES"
	paneles.add_theme_font_size_override("font_size", 16)
	paneles.add_theme_color_override("font_color", HUD.CIAN)
	paneles.add_theme_color_override("font_outline_color", HUD.TINTA)
	paneles.add_theme_constant_override("outline_size", 8)
	paneles.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(paneles)

	oscuridad = ColorRect.new()
	oscuridad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	oscuridad.color = Color(0.025, 0.06, 0.12, 0.62)
	oscuridad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(oscuridad)

	interfaz = HUD.new()
	add_child(interfaz)
	interfaz.accion.pressed.connect(_actuar)
	interfaz.alternativa.pressed.connect(_alternativa)
	interfaz.mapa.pressed.connect(_mapa)
	interfaz.pausa.pressed.connect(_pausar)
	interfaz.confirmar.pressed.connect(_confirmar)

	taller = Taller.new()
	add_child(taller)
	taller.completado.connect(_completar_taller)
	taller.cancelado.connect(_cerrar_taller)
	taller.sonido.connect(func(correcto: bool):
		if correcto: audio.sonar_clic()
		else: audio.sonar_error())

	local = recursos == null
	if local:
		_iniciar_local()
	else:
		_preparar()

func _iniciar_local() -> void:
	recursos = Recursos.new()
	var punto_de_prueba := recursos.guardar_estado()
	punto_de_prueba.sol = 2
	punto_de_prueba.reservas.energia = Recursos.LIMITES.energia
	var preparado := recursos.restaurar_estado(punto_de_prueba) and recursos.iniciar_sol("tormenta")
	assert(preparado)
	_preparar()

func _preparar() -> void:
	var estado := recursos.estado()
	reservas_entrada = estado.reservas
	concluido = false
	salida_pendiente = false
	taller.hide()
	en_pausa = true
	abierto = estado.sol == 2 and estado.en_curso and estado.polvo == "tormenta"
	_mundo(true, Vector2(CONTROL.x, 282) if local else CONTROL + Vector2(0, 12))
	if REPARAR in estado.decisiones or RESGUARDARSE in estado.decisiones:
		_ir_al_cierre(estado, [CRUCE_SUR], [CRUCE_SUR])
	else:
		_ir(Paso.DECISION)

	var nota := ""
	if "sol_2_reserva_emergencia" in estado.decisiones:
		nota = "Pluto abrió la reserva de emergencia. Alcanza para preparar aire; puedes quedarte bajo techo.\n\n"
	interfaz.presentar("¡Se acerca una tormenta!", nota +
		"1   Elige tu plan en la computadora.\n\n" +
		"2   Prepara el aire para respirar sin apuros.\n\n" +
		"3   Protege los equipos o quédate dentro.\n\n" +
		"Camina con WASD o flechas. Sigue la marca azul.",
		"¡Vamos, equipo!")
	if not abierto:
		interfaz.presentar("Sol 2", "La escena necesita una partida con el Sol 2 activo y clima de tormenta.", "")
	elif not local:
		en_pausa = false
		interfaz.modal.hide()
		if paso == Paso.DECISION:
			aviso = "Estás junto a la computadora. Pulsa E o elige «Elegir plan en Control»."
	_actualizar()

func _mundo(dentro: bool, posicion: Vector2) -> void:
	puesto.interior = dentro
	puesto.cielo_sereno = false
	puesto.frente_polvo = 0.65 if not dentro else 0.0
	puesto.plano = false
	puesto.punto = posicion
	puesto.velocidad = Vector2.ZERO
	puesto.caminando = false
	puesto.tiempo = 18.0
	puesto.esclusa_activa = false
	puesto.avance_esclusa = 4.0 if dentro else 0.0
	puesto.escala_visual = 720.0 / (527.0 if dentro else 385.0)
	puesto.ancho_visible = 1280.0 / puesto.escala_visual
	puesto.scale = Vector2.ONE * puesto.escala_visual
	puesto.actualizar_camara(2.0)
	puesto.queue_redraw()

func _ir(destino: Paso, guia: Array = []) -> void:
	paso = destino
	ruta.assign(guia)
	aviso = ""
	puesto.objetivo_mision = {
		Paso.DECISION: "radio", Paso.AIRE: "agua",
		Paso.PLANTAS: "cultivos", Paso.DESCANSO: "dormitorio",
	}.get(paso, "")

func _ir_al_cierre(estado: Dictionary, hacia_aire: Array, hacia_este: Array) -> void:
	if estado.aire_asegurado:
		_ir(Paso.DESCANSO, hacia_este + [CRUCE_ESTE, GIRO_ESTE, GIRO_CAMA])
	else:
		_ir(Paso.AIRE, hacia_aire + [CRUCE_OESTE, GIRO_AGUA, ENTRADA_AGUA])

func juego_activo() -> bool:
	return abierto and not concluido and not en_pausa and not is_instance_valid(panel_control) and not puesto.plano and (not taller.visible or taller.jugando)

func _process(delta: float) -> void:
	if abierto and not concluido:
		if juego_activo():
			if local:
				recursos.avanzar(delta)
			var direccion := Vector2(
				float((Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_D)) or Input.is_action_pressed("ui_right")) - float((Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_A)) or Input.is_action_pressed("ui_left")),
				float((Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_S)) or Input.is_action_pressed("ui_down")) - float((Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_W)) or Input.is_action_pressed("ui_up")))
			if not taller.visible and not is_instance_valid(huerto):
				puesto.avanzar(direccion.normalized(), minf(delta, 0.05))
			taller.avanzar(delta)
			puesto.tiempo += delta
			while not ruta.is_empty() and puesto.punto.distance_to(ruta.front()) < 9.0:
				ruta.pop_front()
		puesto.actualizar_camara(delta)
		puesto.queue_redraw()
	audio.actualizar_viento(juego_activo(), puesto.interior, puesto.intensidad_viento() if not puesto.interior else 0.25)
	_actualizar()

func _unhandled_key_input(event: InputEvent) -> void:
	if is_instance_valid(huerto) or not event is InputEventKey or not event.pressed or event.echo:
		return
	var codigo: Key = event.keycode if event.keycode != KEY_NONE else event.physical_keycode
	if is_instance_valid(panel_control):
		if codigo == KEY_ESCAPE:
			_cerrar_control()
		elif codigo == KEY_E:
			var elegido := get_viewport().gui_get_focus_owner() as Button
			if elegido != null and elegido.get_parent() == panel_control and not elegido.disabled:
				elegido.pressed.emit()
		get_viewport().set_input_as_handled()
		return
	if taller.visible:
		taller.tecla(codigo)
		get_viewport().set_input_as_handled()
		return
	match codigo:
		KEY_E, KEY_ENTER:
			if interfaz.modal.visible:
				_confirmar()
			else:
				_actuar()
		KEY_F: _alternativa()
		KEY_M: _mapa()
		KEY_ESCAPE: _pausar()

func _mapa() -> void:
	if abierto and not concluido and not en_pausa and puesto.interior and not taller.visible:
		audio.sonar_clic()
		puesto.plano = not puesto.plano

func _pausar() -> void:
	if not abierto or concluido or taller.visible:
		return
	audio.sonar_clic()
	if en_pausa:
		_confirmar()
	else:
		en_pausa = true
		interfaz.presentar("En pausa", "WASD o flechas para caminar.\nE para interactuar, F para la alternativa y M para el plano de Umbra.", "Continuar")

func _confirmar() -> void:
	if not interfaz.modal.visible or not interfaz.confirmar.visible:
		return
	audio.sonar_clic()
	if concluido:
		if local:
			_iniciar_local()
	else:
		en_pausa = false
		interfaz.modal.hide()
		_actualizar()

func _cerca(destino: Vector2) -> bool:
	return puesto.punto.distance_to(destino) <= (18.0 if puesto.interior else 26.0)

func _cerca_del_aire(estado: Dictionary) -> bool:
	return puesto.interior and _cerca(AIRE) and not estado.aire_asegurado

func _actuar() -> void:
	if not juego_activo() or taller.visible or is_instance_valid(huerto):
		return
	var estado := recursos.estado()
	if _cerca_del_aire(estado):
		_abrir_taller("aire")
		_actualizar()
		return
	if puesto.interior and paso != Paso.DECISION and _cerca(CONTROL):
		_abrir_control(false)
		return
	if puesto.interior and _cerca(PLANTAS):
		_abrir_huerto()
		return
	var ficha: Array = OBJETIVOS[paso]
	if not _cerca(ficha[0]):
		return
	match paso:
		Paso.DECISION:
			_abrir_control(true)
		Paso.SALIR:
			audio.sonar_esclusa()
			_mundo(false, PuestoUmbra.ESCLUSA - Vector2(10, 0))
			_ir(Paso.REPARAR)
		Paso.REPARAR:
			_abrir_taller("reparar")
		Paso.ENTRAR:
			audio.sonar_esclusa()
			_mundo(true, SALIDA)
			_ir_al_cierre(estado, [CRUCE_SUR], [CRUCE_SUR])
		Paso.DESCANSO:
			var derrota := ""
			if not estado.aire_asegurado:
				derrota = "aire_sin_activar"
			elif estado.reservas.alimento == 0:
				derrota = "hambre_al_dormir"
			_terminar(estado, derrota)
	_actualizar()

func _abrir_control(elegir: bool) -> void:
	if is_instance_valid(panel_control):
		return
	panel_control = PanelControl.new()
	panel_control.configurar(2, false, 78.0 if elegir else 0.0)
	panel_control.cerrar_solicitado.connect(_cerrar_control)
	add_child(panel_control)
	if elegir:
		panel_control.mostrar_tarea("La tormenta detuvo la recarga solar. Repara para proteger los equipos o permanece en el refugio.")
		var reparar := panel_control.accion("Reparar · 4 energía y 1 comida", Rect2(34, 237, 418, 44), _plan_reparar)
		panel_control.accion("Quedarme · mañana pierdo agua y aire", Rect2(468, 237, 438, 44), _plan_resguardo)
		reparar.grab_focus()
	else:
		panel_control.mostrar_tarea(OBJETIVOS[paso][2])

func _cerrar_control() -> void:
	remove_child(panel_control)
	panel_control.queue_free()
	panel_control = null

func _plan_reparar() -> void:
	_cerrar_control()
	audio.sonar_clic()
	salida_pendiente = true
	if recursos.estado().aire_asegurado:
		_ir(Paso.SALIR, [Vector2(402, 352)])
	else:
		_ir(Paso.AIRE, [CRUCE_SUR, CRUCE_OESTE, GIRO_AGUA, ENTRADA_AGUA])
		aviso = "Primero prepara el aire. Luego salimos a reparar."

func _plan_resguardo() -> void:
	_cerrar_control()
	_alternativa()

func _asegurar_aire(estado: Dictionary) -> void:
	if not recursos.activar_oxigeno():
		audio.sonar_error()
		aviso = "Falta agua para activar el oxígeno." if estado.reservas.agua == 0 else "Falta energía. Durante la tormenta los paneles no cargan."
		return
	audio.sonar_oxigeno()
	interfaz.celebrar("¡Lo lograste! Aire listo para el equipo")
	var salida_del_centro: Array[Vector2] = [ENTRADA_AGUA, GIRO_AGUA, CRUCE_OESTE]
	if salida_pendiente:
		_ir(Paso.SALIR, salida_del_centro + [CRUCE_SUR, Vector2(402, 352)])
		aviso = "¡Aire listo! Ahora puedes salir sin apuros."
		return
	match paso:
		Paso.DECISION:
			_ir(Paso.DECISION, salida_del_centro + [CRUCE_SUR])
		Paso.SALIR:
			_ir(Paso.SALIR, salida_del_centro + [CRUCE_SUR, Vector2(402, 352)])
		_:
			_ir_al_cierre(recursos.estado(), [], salida_del_centro)
	aviso = "Soporte vital asegurado: oxígeno lleno hasta la noche."

func _alternativa() -> void:
	if not juego_activo() or taller.visible:
		return
	var estado := recursos.estado()
	if puesto.interior and _cerca(AGUA) and estado.reservas.agua == 0 and estado.hielo > 0:
		if recursos.purificar_hielo():
			audio.sonar_oxigeno()
			aviso = "Hielo purificado. Ya dispones de agua para activar el oxígeno."
		else:
			audio.sonar_error()
			aviso = "Hacen falta 2 de energía para purificar el hielo."
	elif _cerca_del_aire(estado) and estado.reservas.agua == 0 and estado.hielo > 0:
		ruta.assign([AGUA])
		aviso = "Sigue la marca hasta el filtro azul. Pulsa F para purificar el hielo."
	elif paso == Paso.REPARAR and _cerca(PuestoUmbra.ESCLUSA):
		audio.sonar_esclusa()
		_mundo(true, SALIDA)
		_ir(Paso.SALIR)
	elif (paso == Paso.DECISION and _cerca(CONTROL)) or (paso == Paso.SALIR and _cerca(SALIDA)):
		if recursos.aplicar_decision(RESGUARDARSE, {}):
			salida_pendiente = false
			audio.sonar_alerta()
			var hacia_aire := [CRUCE_SUR]
			_ir_al_cierre(recursos.estado(), hacia_aire, hacia_aire)
			aviso = "Nos quedamos dentro. Hoy no gastas en reparar.\nMañana perderemos 1 de agua y 1 de oxígeno."
	elif paso == Paso.AIRE and _cerca(AIRE):
		audio.sonar_clic()
		if salida_pendiente:
			_ir(Paso.SALIR, [ENTRADA_AGUA, GIRO_AGUA, CRUCE_OESTE, CRUCE_SUR, Vector2(402, 352)])
			return
		_ir(Paso.DESCANSO, [ENTRADA_AGUA, GIRO_AGUA, CRUCE_OESTE, CRUCE_ESTE, GIRO_ESTE, GIRO_CAMA])
	elif paso == Paso.DESCANSO and _cerca(CAMA):
		audio.sonar_clic()
		if estado.aire_asegurado:
			_ir(Paso.PLANTAS, [GIRO_CAMA, GIRO_PLANTAS])
		else:
			_ir(Paso.AIRE, [GIRO_CAMA, GIRO_ESTE, CRUCE_ESTE, CRUCE_OESTE, GIRO_AGUA, ENTRADA_AGUA])
	elif paso == Paso.PLANTAS and _cerca(PLANTAS):
		audio.sonar_clic()
		_ir(Paso.DESCANSO, [GIRO_PLANTAS, GIRO_CAMA])
	_actualizar()

func _abrir_huerto() -> void:
	huerto = Invernadero.new()
	huerto.recursos = recursos
	huerto.semillas_disponibles = ["lechuga"]
	huerto.cerrar_solicitado.connect(_cerrar_huerto)
	huerto.cultivo_atendido.connect(_registrar_cultivo)
	interfaz.hide()
	add_child(huerto)

func _registrar_cultivo(cosechado: bool) -> void:
	audio.sonar_clic()
	if cosechado and paso == Paso.PLANTAS:
		aviso = "Recuperaste comida. Ahora puedes volver al dormitorio."
	avance_plantas_guardado.emit()

func _cerrar_huerto() -> void:
	remove_child(huerto)
	huerto.queue_free()
	huerto = null
	interfaz.show()

func _terminar(estado: Dictionary, derrota: String) -> void:
	concluido = true
	if is_instance_valid(huerto):
		_cerrar_huerto()
	taller.hide()
	if derrota.is_empty():
		audio.sonar_alerta()
	else:
		audio.sonar_error()
	var reparado: bool = REPARAR in estado.decisiones
	var danado: bool = RESGUARDARSE in estado.decisiones
	var cambios := {}
	for id: String in estado.reservas:
		cambios[id] = estado.reservas[id] - reservas_entrada[id]
	var resultado := {
		"id": "dia_2", "completado": derrota.is_empty(), "derrota": derrota,
		"decision": "reparar" if reparado else ("resguardarse" if danado else ""),
		"paneles_protegidos": reparado, "sistemas_danados": danado,
		"perdidas_dia_3": {"id": DANOS_DIA_3, "recursos": {"agua": 1, "oxigeno": 1}} if danado else {},
		"cambios_reservas": cambios, "estado_recursos": estado,
	}
	var resumen := "✓  Aire listo para toda la noche.\n✓  Tres cierres protegen los equipos.\n✓  Equipo de vuelta en el refugio." if reparado else "✓  Aire listo para toda la noche.\n✓  El equipo se quedó dentro.\nMañana: equipos dañados, −1 agua y −1 oxígeno."
	resumen += "\n\nReservas: Energía %d · Agua %d · Oxígeno %d · Alimento %d" % [
		estado.reservas.energia, estado.reservas.agua, estado.reservas.oxigeno, estado.reservas.alimento,
	]
	var motivo := {
		"oxigeno_agotado": "Se acabó el aire. En el próximo intento, ve primero a los tanques verdes.\n\nConsejo: puedes pausar con Esc mientras piensas.",
		"aire_sin_activar": "Faltó preparar el aire antes de dormir.\n\nPrueba de nuevo: conecta las tuberías en el laboratorio.",
		"hambre_al_dormir": "El equipo necesita comer antes de dormir.\n\nEn Plantas, siembra una lechuga y come cuando esté lista.",
	}
	interfaz.presentar("Sol 2 completado" if derrota.is_empty() else "Sol 2 terminado",
		motivo.get(derrota, resumen), "Volver a jugar" if local else "")
	finalizado.emit(resultado)

func _actualizar() -> void:
	var estado := recursos.estado()
	if abierto and not concluido and not estado.derrota.is_empty():
		_terminar(estado, estado.derrota)
		if is_queued_for_deletion():
			return
	if is_instance_valid(huerto):
		return

	var ficha: Array = OBJETIVOS[paso]
	var destino: Vector2 = ficha[0] if ruta.is_empty() else ruta.front()
	var cerca := _cerca(ficha[0])
	var puede_elegir := cerca
	var lugar: String = ficha[1]
	var accion: String = ficha[3]
	var detalle: String = ficha[2] if aviso.is_empty() else aviso
	var opcion := ""

	match paso:
		Paso.DECISION, Paso.SALIR:
			opcion = "Quedarme · mañana −1 agua y −1 aire"
		Paso.REPARAR:
			opcion = "Volver adentro"
			puede_elegir = _cerca(PuestoUmbra.ESCLUSA)
		Paso.AIRE:
			opcion = "Preparar aire después · salir" if salida_pendiente else "Ir al dormitorio"
		Paso.PLANTAS:
			opcion = "Volver al dormitorio"
		Paso.DESCANSO:
			if not estado.aire_asegurado:
				accion = "Dormir sin aire · termina la misión"
				detalle = "Falta preparar el aire. No es seguro dormir.\nPulsa F para volver a los tanques verdes."
				opcion = "Volver a activar el oxígeno"
			elif estado.reservas.alimento == 0:
				accion = "Dormir sin comida · termina la misión"
				detalle = "Tienes hambre. Pulsa F para ir a Plantas.\nCome una cosecha antes de dormir."
				opcion = "Volver a Plantas"

	if paso == Paso.SALIR and not estado.aire_asegurado and aviso.is_empty():
		detalle = "Aún falta preparar el aire. No tardes afuera.\nPuedes volver al laboratorio antes de salir."

	if paso in [Paso.DECISION, Paso.SALIR, Paso.REPARAR] and aviso.is_empty() and not estado.aire_asegurado:
		if estado.reservas.energia < 10:
			detalle = "La batería no alcanza para reparar y preparar aire.\nQuedarte dentro guarda energía para respirar."

	if _cerca_del_aire(estado):
		lugar = OBJETIVOS[Paso.AIRE][1]
		accion = OBJETIVOS[Paso.AIRE][3]
		detalle = OBJETIVOS[Paso.AIRE][2] if aviso.is_empty() else aviso
		cerca = true
		destino = AIRE
		if estado.reservas.agua == 0 and estado.hielo > 0:
			opcion = "Ir al filtro azul · purificar hielo"
			puede_elegir = true
	elif puesto.interior and paso != Paso.DECISION and _cerca(CONTROL):
		accion = "Consultar tareas"
		cerca = true

	if puesto.interior and _cerca(AGUA) and estado.reservas.agua == 0 and estado.hielo > 0:
		lugar = "Filtro azul · Prepara agua"
		detalle = "Convierte tu hielo en agua para el aire.\nCuesta 2 de energía. Recibes hasta 3 de agua."
		opcion = "Purificar hielo · 2 energía"
		cerca = false
		puede_elegir = true
		destino = AGUA

	if puesto.interior and _cerca(PLANTAS):
		cerca = true
		accion = "Atender las bandejas"

	if puesto.plano:
		detalle = "M · Cerrar el plano y volver al recorrido."

	oscuridad.visible = puesto.interior and estado.sin_luz and not puesto.plano

	# Indicador de baliza exterior para paneles solares
	var en_exterior_paneles := not puesto.interior and (paso == Paso.REPARAR or paso == Paso.ENTRAR)
	paneles.visible = en_exterior_paneles
	if en_exterior_paneles:
		var reparado: bool = REPARAR in estado.decisiones
		paneles.text = "✓ PANELES Y LAB ASEGURADOS" if reparado else "PANELES · SIN PROTEGER"
		paneles.add_theme_color_override("font_color", HUD.VERDE if reparado else HUD.CIAN)
		paneles.position = puesto.proyectar_suelo(PANELES - Vector2(0, 45)) - Vector2(100, 20)

	# Mensaje contextual de Pluto
	var pluto_texto := ""
	if paso == Paso.DECISION and not cerca:
		if estado.reservas.energia < 10 and not estado.aire_asegurado:
			pluto_texto = "¡Ojo con la batería! Salir a reparar cuesta 4, y el aire necesita 6. Podríamos asegurar el aire primero o resguardarnos."
		else:
			pluto_texto = "El polvo tapa la luz del Sol. Hoy cuidaremos la batería. ¿Vamos a la computadora?"
	elif paso == Paso.SALIR:
		pluto_texto = "Las ráfagas son fuertes afuera. Ve con cuidado hacia los paneles."
	elif paso == Paso.REPARAR:
		pluto_texto = "Acércate a los paneles para fijar los cobertores mecánicos."
	elif paso == Paso.ENTRAR:
		pluto_texto = "¡Excelente! Paneles a salvo. Vuelve por la esclusa a asegurar el aire."
	elif paso == Paso.AIRE and not estado.aire_asegurado:
		pluto_texto = "Usa agua y batería para preparar el aire. Busca los tanques verdes."
	elif paso == Paso.PLANTAS:
		pluto_texto = "Ve a Plantas. Allí puedes regar una lechuga o comer de una bandeja madura."
	elif estado.aire_asegurado:
		pluto_texto = "Oxígeno asegurado para la noche. Descansa en el dormitorio cuando estés lista."

	var pluto_a_la_vista := not taller.visible and not cerca and puesto.interior and not puesto.plano and juego_activo()
	interfaz.aviso_de_pluto(pluto_a_la_vista, puesto.proyectar_suelo(puesto.posicion_pluto()), pluto_texto)

	taller.mostrar_aire(estado)
	interfaz.visible = not taller.visible
	interfaz.ruta_del_dia(estado, salida_pendiente, paso == Paso.DESCANSO)
	interfaz.actualizar(lugar, detalle, accion, opcion, cerca and juego_activo(),
		puede_elegir and juego_activo(), puesto.interior, puesto.plano,
		puesto.proyectar_suelo(destino) - Vector2(0, 18), puesto.proyectar_suelo(puesto.punto))

func _abrir_taller(tipo: String) -> void:
	var estado := recursos.estado()
	var costo := 6 if tipo == "aire" else 4
	if estado.reservas.energia < costo or (tipo == "aire" and estado.reservas.agua < 1) or (tipo == "reparar" and estado.reservas.alimento < 1):
		audio.sonar_error()
		aviso = "Necesitas 6 de energía y 1 de agua para el aire." if tipo == "aire" else "Necesitas 4 de energía y 1 de comida. Puedes volver a resguardarte."
		return
	taller.abrir(tipo)
	_actualizar()

func _cerrar_taller() -> void:
	taller.hide()
	aviso = "No gastaste recursos. Puedes intentarlo otra vez."
	_actualizar()

func _completar_taller(tipo: String) -> void:
	# Se comprueba otra vez: el alimento puede bajar mientras se trabaja.
	taller.hide()
	if tipo == "aire":
		_asegurar_aire(recursos.estado())
	elif recursos.aplicar_decision(REPARAR, COSTO_REPARAR):
		salida_pendiente = false
		interfaz.celebrar("¡3 cierres listos! Equipos protegidos")
		audio.sonar_reparar()
		_ir(Paso.ENTRAR)
		aviso = "¡Tres cierres listos! Paneles y laboratorio protegidos."
	else:
		audio.sonar_error()
		aviso = "Faltan reservas. No se cobró nada. Vuelve a resguardarte."
	_actualizar()
