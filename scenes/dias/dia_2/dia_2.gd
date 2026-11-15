extends Control

signal finalizado(resultado: Dictionary)

const Recursos := preload("res://scripts/mecanicas/recursos_mision.gd")
const Indicadores := preload("res://scripts/mecanicas/indicadores_refugio.gd")
const HUD := preload("res://scenes/dias/dia_2/dia_2_hud.gd")
const AudioDia2 := preload("res://scenes/dias/dia_2/dia_2_audio.gd")

const REPARAR := "dia_2_reparar"
const RESGUARDARSE := "dia_2_resguardarse"
const DANOS_DIA_3 := "dia_3_danos_del_dia_2"
const COSTO_REPARAR := {"energia": -4, "alimento": -1}

const CONTROL: Vector2 = PuestoUmbra.TERMINALES.radio
const SALIDA := Vector2(402, 382)
const PANELES := PuestoUmbra.REVISION_SOLAR
const PLUTO := Vector2(340, 260)
const AIRE := Vector2(25, 27)
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
	Paso.DECISION: [CONTROL, "Supercomputadora Â· Control", "La tormenta de polvo detiene la generaciÃ³n solar. Sal para proteger los paneles y el laboratorio o resguÃ¡rdate.", "Ir a reparar Â· 4 energÃ­a + 1 alimento"],
	Paso.SALIR: [SALIDA, "Esclusa principal", "La esclusa conecta con el exterior azotado por las rÃ¡fagas. La reparaciÃ³n se confirma junto a los paneles.", "Salir a la superficie"],
	Paso.REPARAR: [PANELES, "Paneles solares exteriores", "Las rÃ¡fagas empujan a Nora. AcÃ©rcate a la marca y asegura los paneles y la toma del laboratorio.", "Reparar Â· 4 energÃ­a + 1 alimento"],
	Paso.ENTRAR: [PuestoUmbra.ESCLUSA, "Esclusa principal", "Paneles y laboratorio asegurados. Regresa al refugio para proteger el soporte vital.", "Entrar al refugio"],
	Paso.AIRE: [AIRE, "Centro de agua Â· Soporte vital", "Activa el ciclo de electrÃ³lisis para asegurar el oxÃ­geno de la base hasta la noche.", "Asegurar aire Â· 6 energÃ­a + 1 agua"],
	Paso.PLANTAS: [PLANTAS, "MÃ³dulo de cultivo Â· Plantas", "La lechuga tarda 15 s y aporta 2 de alimento al cosecharla.", "Sembrar Â· 1 energÃ­a + 1 agua"],
	Paso.DESCANSO: [CAMA, "Dormitorio Â· Litera", "Comprueba que las reservas y el aire estÃ©n asegurados y descansa para completar el Sol 2.", "Terminar el DÃ­a 2"],
}

var recursos: Recursos
var puesto: PuestoUmbra
var interfaz: HUD
var audio: AudioDia2
var lecturas: Indicadores
var comida_ui: Indicadores
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
	puesto.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(puesto)

	audio = AudioDia2.new()
	add_child(audio)

	# Indicadores del refugio integrados con el nuevo arte de main
	lecturas = Indicadores.new()
	add_child(lecturas)

	comida_ui = Indicadores.new()
	comida_ui.solo_alimento = true
	comida_ui.position = Vector2(875, 20)
	add_child(comida_ui)

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
	en_pausa = true
	abierto = estado.sol == 2 and estado.en_curso and estado.polvo == "tormenta"
	_mundo(true, Vector2(CONTROL.x, 282))
	if REPARAR in estado.decisiones or RESGUARDARSE in estado.decisiones:
		_ir_al_cierre(estado, [CRUCE_SUR], [CRUCE_SUR])
	else:
		_ir(Paso.DECISION)

	interfaz.presentar("DÃ­a 2 Â· Tormenta de polvo",
		"El frente de polvo registrado por Pancam detuvo la generaciÃ³n solar en Umbra.\n\n" +
		"En Control puedes decidir la estrategia:\n" +
		"â€¢ Salir a reparar: asegura paneles y laboratorio (4 energÃ­a + 1 alimento).\n" +
		"â€¢ Resguardarse: sin coste inmediato; maÃ±ana habrÃ¡ daÃ±os (-1 agua, -1 oxÃ­geno).\n\n" +
		"Asegura el aire en el Centro de agua (6 energÃ­a + 1 agua) antes de dormir.",
		"Empezar el DÃ­a 2")
	if not abierto:
		interfaz.presentar("DÃ­a 2", "La escena necesita una partida con el Sol 2 activo y clima de tormenta.", "")
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
	return abierto and not concluido and not en_pausa and not puesto.plano

func _process(delta: float) -> void:
	if abierto and not concluido:
		if juego_activo():
			if local:
				recursos.avanzar(delta)
			var direccion := Vector2(
				float(Input.is_physical_key_pressed(KEY_D) or Input.is_action_pressed("ui_right")) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_action_pressed("ui_left")),
				float(Input.is_physical_key_pressed(KEY_S) or Input.is_action_pressed("ui_down")) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_action_pressed("ui_up")))
			puesto.avanzar(direccion.normalized(), minf(delta, 0.05))
			puesto.tiempo += delta
			while not ruta.is_empty() and puesto.punto.distance_to(ruta.front()) < 9.0:
				ruta.pop_front()
		puesto.actualizar_camara(delta)
		puesto.queue_redraw()
	audio.actualizar_viento(juego_activo(), puesto.interior, puesto.intensidad_viento() if not puesto.interior else 0.25)
	_actualizar()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.physical_keycode:
		KEY_E, KEY_ENTER:
			if interfaz.modal.visible:
				_confirmar()
			else:
				_actuar()
		KEY_Q: _alternativa()
		KEY_M: _mapa()
		KEY_ESCAPE: _pausar()

func _mapa() -> void:
	if abierto and not concluido and not en_pausa and puesto.interior:
		audio.sonar_clic()
		puesto.plano = not puesto.plano

func _pausar() -> void:
	if not abierto or concluido:
		return
	audio.sonar_clic()
	if en_pausa:
		_confirmar()
	else:
		en_pausa = true
		interfaz.presentar("En pausa", "WASD o flechas para caminar.\nE para interactuar, Q para la alternativa y M para el plano de Umbra.", "Continuar")

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
	if not juego_activo():
		return
	var estado := recursos.estado()
	if _cerca_del_aire(estado):
		_asegurar_aire(estado)
		_actualizar()
		return
	var ficha: Array = OBJETIVOS[paso]
	if not _cerca(ficha[0]):
		return
	match paso:
		Paso.DECISION:
			audio.sonar_clic()
			_ir(Paso.SALIR, [Vector2(402, 352)])
		Paso.SALIR:
			audio.sonar_esclusa()
			_mundo(false, PuestoUmbra.ESCLUSA - Vector2(10, 0))
			_ir(Paso.REPARAR)
		Paso.REPARAR:
			if not recursos.aplicar_decision(REPARAR, COSTO_REPARAR):
				audio.sonar_error()
				aviso = "Faltan reservas para reparar. Vuelve por la esclusa y resguÃ¡rdate."
				return
			audio.sonar_reparar()
			_ir(Paso.ENTRAR)
			aviso = "Â¡Paneles y toma del laboratorio asegurados! Vuelve a la esclusa."
		Paso.ENTRAR:
			audio.sonar_esclusa()
			_mundo(true, SALIDA)
			_ir_al_cierre(estado, [CRUCE_SUR], [CRUCE_SUR])
		Paso.PLANTAS:
			if recursos.sembrar("lechuga"):
				audio.sonar_clic()
				aviso = "Lechuga sembrada en bandeja. Espera 15 s y pulsa Q para comerla."
			else:
				audio.sonar_error()
				aviso = "Necesitas una bandeja libre, 1 de energÃ­a y 1 de agua."
		Paso.DESCANSO:
			var derrota := ""
			if not estado.aire_asegurado:
				derrota = "aire_sin_activar"
			elif estado.reservas.alimento == 0:
				derrota = "hambre_al_dormir"
			_terminar(estado, derrota)
	_actualizar()

func _asegurar_aire(estado: Dictionary) -> void:
	if not recursos.activar_oxigeno():
		audio.sonar_error()
		aviso = "Falta agua para activar el oxÃ­geno." if estado.reservas.agua == 0 else "Falta energÃ­a. Durante la tormenta los paneles no cargan."
		return
	audio.sonar_oxigeno()
	var salida_del_centro: Array[Vector2] = [ENTRADA_AGUA, GIRO_AGUA, CRUCE_OESTE]
	match paso:
		Paso.DECISION:
			_ir(Paso.DECISION, salida_del_centro + [CRUCE_SUR])
		Paso.SALIR:
			_ir(Paso.SALIR, salida_del_centro + [CRUCE_SUR, Vector2(402, 352)])
		_:
			_ir_al_cierre(recursos.estado(), [], salida_del_centro)
	aviso = "Soporte vital asegurado: oxÃ­geno lleno hasta la noche."

func _alternativa() -> void:
	if not juego_activo():
		return
	var estado := recursos.estado()
	if _cerca_del_aire(estado) and estado.reservas.agua == 0 and estado.hielo > 0:
		if recursos.purificar_hielo():
			audio.sonar_oxigeno()
			aviso = "Hielo purificado. Ya dispones de agua para activar el oxÃ­geno."
		else:
			audio.sonar_error()
			aviso = "Hacen falta 2 de energÃ­a para purificar el hielo."
	elif paso == Paso.REPARAR and _cerca(PuestoUmbra.ESCLUSA):
		audio.sonar_esclusa()
		_mundo(true, SALIDA)
		_ir(Paso.SALIR)
	elif (paso == Paso.DECISION and _cerca(CONTROL)) or (paso == Paso.SALIR and _cerca(SALIDA)):
		if recursos.aplicar_decision(RESGUARDARSE, {}):
			audio.sonar_alerta()
			var hacia_aire := [CRUCE_SUR]
			_ir_al_cierre(recursos.estado(), hacia_aire, hacia_aire)
			aviso = "La tripulaciÃ³n se resguarda. MaÃ±ana se sentirÃ¡ el daÃ±o en los equipos."
	elif paso == Paso.AIRE and _cerca(AIRE):
		audio.sonar_clic()
		_ir(Paso.DESCANSO, [ENTRADA_AGUA, GIRO_AGUA, CRUCE_OESTE, CRUCE_ESTE, GIRO_ESTE, GIRO_CAMA])
	elif paso == Paso.DESCANSO and _cerca(CAMA):
		audio.sonar_clic()
		if estado.aire_asegurado:
			_ir(Paso.PLANTAS, [GIRO_CAMA, GIRO_PLANTAS])
		else:
			_ir(Paso.AIRE, [GIRO_CAMA, GIRO_ESTE, CRUCE_ESTE, CRUCE_OESTE, GIRO_AGUA, ENTRADA_AGUA])
	elif paso == Paso.PLANTAS and _cerca(PLANTAS):
		var cosecha := _cosecha(estado)
		if not cosecha.is_empty() and recursos.comer(cosecha):
			audio.sonar_clic()
			aviso = "Cosecha consumida. Recuperaste alimento."
		else:
			audio.sonar_clic()
			_ir(Paso.DESCANSO, [GIRO_PLANTAS, GIRO_CAMA])
	_actualizar()

func _cosecha(estado: Dictionary) -> String:
	if estado.reservas.alimento == Recursos.LIMITES.alimento:
		return ""
	for cultivo: String in estado.bandejas:
		if estado.bandejas[cultivo] == 0:
			return cultivo
	return ""

func _terminar(estado: Dictionary, derrota: String) -> void:
	concluido = true
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
	var resumen := "Paneles y laboratorio protegidos contra la tormenta." if reparado else "A resguardo Â· MaÃ±ana: sistemas daÃ±ados (-1 agua y -1 oxÃ­geno)."
	resumen += "\nReservas: EnergÃ­a %d Â· Agua %d Â· OxÃ­geno %d Â· Alimento %d" % [
		estado.reservas.energia, estado.reservas.agua, estado.reservas.oxigeno, estado.reservas.alimento,
	]
	var motivo := {
		"oxigeno_agotado": "El oxÃ­geno de reserva se agotÃ³ antes de asegurar el soporte vital.",
		"aire_sin_activar": "La tripulaciÃ³n intentÃ³ dormir sin activar el ciclo de oxÃ­geno.",
		"hambre_al_dormir": "La tripulaciÃ³n intentÃ³ dormir con las reservas de alimento en cero.",
	}
	interfaz.presentar("DÃ­a 2 completado" if derrota.is_empty() else "DÃ­a 2 terminado",
		motivo.get(derrota, resumen), "Volver a jugar" if local else "")
	finalizado.emit(resultado)

func _actualizar() -> void:
	var estado := recursos.estado()
	if abierto and not concluido and not estado.derrota.is_empty():
		_terminar(estado, estado.derrota)
		if is_queued_for_deletion():
			return

	# Actualizar lecturas en pantalla de la supercomputadora y HUD
	lecturas.actualizar(estado)
	comida_ui.actualizar(estado)
	lecturas.visible = puesto.interior and not puesto.plano and PuestoUmbra.ROOMS.radio.has_point(puesto.punto)
	var esquina := puesto.proyectar_suelo(Vector2(370, 198))
	var borde := puesto.proyectar_suelo(Vector2(436, 198))
	lecturas.position = esquina
	lecturas.scale = Vector2.ONE * ((borde.x - esquina.x) / 386.0)

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
			opcion = "Resguardarse Â· maÃ±ana -1 agua y -1 oxÃ­geno"
		Paso.REPARAR:
			opcion = "Volver adentro"
			puede_elegir = _cerca(PuestoUmbra.ESCLUSA)
		Paso.AIRE:
			opcion = "Ir al dormitorio"
		Paso.PLANTAS:
			var lista := _cosecha(estado)
			opcion = "Volver al dormitorio" if lista.is_empty() else "Comer cosecha Â· +%d alimento" % Recursos.CULTIVOS[lista].alimento
		Paso.DESCANSO:
			if not estado.aire_asegurado:
				accion = "Dormir sin asegurar el aire"
				opcion = "Volver a activar el oxÃ­geno"
			elif estado.reservas.alimento == 0:
				accion = "Dormir sin alimento"
				opcion = "Volver a Plantas"

	if paso in [Paso.DECISION, Paso.SALIR, Paso.REPARAR] and aviso.is_empty() and not estado.aire_asegurado:
		if estado.reservas.energia < 10:
			detalle = "Reparar consume 4 de energÃ­a y deja menos de las 6 requeridas para el aire. Conviene resguardarse o asegurar el aire primero."

	if _cerca_del_aire(estado):
		lugar = OBJETIVOS[Paso.AIRE][1]
		accion = OBJETIVOS[Paso.AIRE][3]
		detalle = OBJETIVOS[Paso.AIRE][2] if aviso.is_empty() else aviso
		cerca = true
		destino = AIRE
		if estado.reservas.agua == 0 and estado.hielo > 0:
			opcion = "Purificar hielo guardado Â· 2 energÃ­a"
			puede_elegir = true

	if puesto.plano:
		detalle = "M Â· Cerrar el plano y volver al recorrido."

	oscuridad.visible = puesto.interior and estado.sin_luz and not puesto.plano

	# Indicador de baliza exterior para paneles solares
	var en_exterior_paneles := not puesto.interior and (paso == Paso.REPARAR or paso == Paso.ENTRAR)
	paneles.visible = en_exterior_paneles
	if en_exterior_paneles:
		var reparado: bool = REPARAR in estado.decisiones
		paneles.text = "âœ“ PANELES Y LAB ASEGURADOS" if reparado else "âš ï¸ PANELES SOLARES Â· EXPUESTOS"
		paneles.add_theme_color_override("font_color", HUD.VERDE if reparado else HUD.CIAN)
		paneles.position = puesto.proyectar_suelo(PANELES - Vector2(0, 45)) - Vector2(100, 20)

	# Mensaje contextual de Pluto
	var pluto_texto := ""
	if paso == Paso.DECISION and not cerca:
		if estado.reservas.energia < 10 and not estado.aire_asegurado:
			pluto_texto = "Â¡Ojo con la baterÃ­a! Salir a reparar cuesta 4, y el aire necesita 6. PodrÃ­amos asegurar el aire primero o resguardarnos."
		else:
			pluto_texto = "Nora, la tormenta de polvo bloqueÃ³ los paneles. Decide en la supercomputadora si reparamos o nos resguardamos."
	elif paso == Paso.SALIR:
		pluto_texto = "Las rÃ¡fagas son fuertes afuera. Ve con cuidado hacia los paneles."
	elif paso == Paso.REPARAR:
		pluto_texto = "AcÃ©rcate a los paneles para fijar los cobertores mecÃ¡nicos."
	elif paso == Paso.ENTRAR:
		pluto_texto = "Â¡Excelente! Paneles a salvo. Vuelve por la esclusa a asegurar el aire."
	elif paso == Paso.AIRE and not estado.aire_asegurado:
		pluto_texto = "En el Centro de agua podemos usar electrÃ³lisis para llenar el tanque de oxÃ­geno."
	elif estado.aire_asegurado:
		pluto_texto = "OxÃ­geno asegurado para la noche. Descansa en el dormitorio cuando estÃ©s lista."

	var pluto_a_la_vista := puesto.interior and not puesto.plano and juego_activo() and puesto.punto.distance_to(PLUTO) < 110.0
	interfaz.aviso_de_pluto(pluto_a_la_vista, puesto.proyectar_suelo(PLUTO), pluto_texto)

	interfaz.actualizar(estado, lugar, detalle, accion, opcion, cerca and juego_activo(),
		puede_elegir and juego_activo(), puesto.interior, puesto.plano,
		puesto.proyectar_suelo(destino) - Vector2(0, 18), puesto.proyectar_suelo(puesto.punto))
