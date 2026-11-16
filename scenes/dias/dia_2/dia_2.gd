extends Control

signal finalizado(resultado: Dictionary)
signal avance_guardado

const Recursos := preload("res://scripts/mecanicas/recursos_mision.gd")
const Invernadero := preload("res://scripts/invernadero_umbra.gd")
const Laboratorio := preload("res://scripts/laboratorio_umbra.gd")
const HUD := preload("res://scenes/dias/dia_2/dia_2_hud.gd")
const PanelControl := preload("res://scripts/panel_control.gd")
const SabiasQue := preload("res://scripts/sabias_que.gd")
const ControlesTactiles := preload("res://scripts/controles_tactiles.gd")
var panel_control: PanelControl
var sabias_que: SabiasQue
var pad_tactil: ControlesTactiles
var _ciencia_pendiente := ""
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
	Paso.DECISION: [CONTROL, "sol2.guia.consola"],
	Paso.SALIR: [SALIDA, "sol2.guia.esclusa_salir"],
	Paso.REPARAR: [PANELES, "sol2.guia.paneles"],
	Paso.ENTRAR: [PuestoUmbra.ESCLUSA, "sol2.guia.esclusa_volver"],
	Paso.AIRE: [AIRE, "sol2.guia.aire"],
	Paso.PLANTAS: [PLANTAS, "sol2.guia.plantas"],
	Paso.DESCANSO: [CAMA, "sol2.guia.cama"],
}

func _obj(p: Paso, campo: String) -> String:
	return I18n.t(OBJETIVOS[p][1] + "." + campo)

var taller: Taller
var huerto: Invernadero
var laboratorio: Laboratorio
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
	paneles.text = I18n.t("puesto.paneles")
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
	sabias_que = SabiasQue.new()
	add_child(sabias_que)
	pad_tactil = ControlesTactiles.new()
	add_child(pad_tactil)
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
		nota = I18n.t("sol2.intro.emergencia")
	interfaz.presentar(I18n.t("sol2.intro.titulo"), nota +
		I18n.t("sol2.intro.p1") +
		I18n.t("sol2.intro.p2") +
		I18n.t("sol2.intro.p3") +
		I18n.t("sol2.intro.controles"),
		I18n.t("sol2.intro.btn"))
	if not abierto:
		interfaz.presentar(I18n.t("sol2.req.titulo"), I18n.t("sol2.req.msg"), "")
	elif not local:
		en_pausa = false
		interfaz.modal.hide()
		if paso == Paso.DECISION:
			aviso = I18n.t("sol2.pluto.consola_cerca")
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
	return abierto and not concluido and not en_pausa and not is_instance_valid(panel_control) and not is_instance_valid(laboratorio) and not puesto.plano and (not taller.visible or taller.jugando)

func _process(delta: float) -> void:
	if abierto and not concluido:
		if juego_activo():
			if local:
				recursos.avanzar(delta)
			var direccion := Vector2(
				float((Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_D)) or Input.is_action_pressed("ui_right")) - float((Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_A)) or Input.is_action_pressed("ui_left")),
				float((Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_S)) or Input.is_action_pressed("ui_down")) - float((Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_W)) or Input.is_action_pressed("ui_up")))
			if not taller.visible and not is_instance_valid(huerto):
				puesto.avanzar((direccion + ControlesTactiles.direccion()).limit_length(1.0), minf(delta, 0.05))
			taller.avanzar(delta)
			puesto.tiempo += delta
			while not ruta.is_empty() and puesto.punto.distance_to(ruta.front()) < 9.0:
				ruta.pop_front()
		puesto.actualizar_camara(delta)
		puesto.queue_redraw()
	audio.actualizar_viento(juego_activo(), puesto.interior, puesto.intensidad_viento() if not puesto.interior else 0.25)
	_actualizar()

func _unhandled_key_input(event: InputEvent) -> void:
	if is_instance_valid(huerto) or is_instance_valid(laboratorio) or not event is InputEventKey or not event.pressed or event.echo:
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
		interfaz.presentar(I18n.t("ui.en_pausa"), I18n.t("sol2.pausa.desc"), I18n.t("ui.continuar"))

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
	if _puede_usar_filtro(estado):
		_abrir_filtro()
		return
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
		panel_control.mostrar_tarea(I18n.t("sol2.plan.msg"))
		var reparar := panel_control.accion(I18n.t("sol2.plan.reparar"), Rect2(34, 276, 418, 44), _plan_reparar)
		panel_control.accion(I18n.t("sol2.plan.quedarme_largo"), Rect2(468, 276, 438, 44), _plan_resguardo)
		reparar.grab_focus()
	else:
		panel_control.mostrar_tarea(_obj(paso, "msg"))

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
		aviso = I18n.t("sol2.plan.aire_antes")

func _plan_resguardo() -> void:
	_cerrar_control()
	_alternativa()

func _asegurar_aire(estado: Dictionary) -> void:
	if not recursos.activar_oxigeno():
		audio.sonar_error()
		aviso = I18n.t("sol2.ox.falta_agua" if estado.reservas.agua == 0 else "sol2.ox.falta_energia")
		return
	audio.sonar_oxigeno()
	interfaz.celebrar(I18n.t("sol2.ox.logro"))
	var salida_del_centro: Array[Vector2] = [ENTRADA_AGUA, GIRO_AGUA, CRUCE_OESTE]
	if salida_pendiente:
		_ir(Paso.SALIR, salida_del_centro + [CRUCE_SUR, Vector2(402, 352)])
		aviso = I18n.t("sol2.ox.pluto")
		return
	match paso:
		Paso.DECISION:
			_ir(Paso.DECISION, salida_del_centro + [CRUCE_SUR])
		Paso.SALIR:
			_ir(Paso.SALIR, salida_del_centro + [CRUCE_SUR, Vector2(402, 352)])
		_:
			_ir_al_cierre(recursos.estado(), [], salida_del_centro)
	aviso = I18n.t("sol2.ox.msg")

func _alternativa() -> void:
	if not juego_activo() or taller.visible:
		return
	var estado := recursos.estado()
	if _puede_usar_filtro(estado):
		_abrir_filtro()
	elif _cerca_del_aire(estado) and estado.reservas.agua == 0 and estado.hielo > 0:
		ruta.assign([AGUA])
		aviso = I18n.t("sol2.hielo.guia")
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
			aviso = I18n.t("sol2.resguardo.msg")
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

func _puede_usar_filtro(estado: Dictionary) -> bool:
	return puesto.interior and _cerca(AGUA) and estado.reservas.agua == 0 and estado.hielo > 0

func _abrir_filtro() -> void:
	laboratorio = Laboratorio.new()
	laboratorio.recursos = recursos
	laboratorio.cerrar_solicitado.connect(_cerrar_filtro)
	laboratorio.trabajo_completado.connect(_registrar_filtro)
	interfaz.hide()
	add_child(laboratorio)

func _registrar_filtro(_ganancia: int) -> void:
	audio.sonar_oxigeno()
	aviso = I18n.t("sol2.filtro.listo_agua")
	_ciencia_pendiente = "agua"
	avance_guardado.emit()

func _cerrar_filtro() -> void:
	remove_child(laboratorio)
	laboratorio.queue_free()
	laboratorio = null
	interfaz.show()

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
	_ciencia_pendiente = "cultivos"
	if cosechado and paso == Paso.PLANTAS:
		aviso = I18n.t("sol2.plantas.recuperaste")
	avance_guardado.emit()

func _cerrar_huerto() -> void:
	remove_child(huerto)
	huerto.queue_free()
	huerto = null
	interfaz.show()

func _terminar(estado: Dictionary, derrota: String) -> void:
	concluido = true
	if is_instance_valid(huerto):
		_cerrar_huerto()
	if is_instance_valid(laboratorio):
		_cerrar_filtro()
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
	var resumen := I18n.t("sol2.fin.reparado" if reparado else "sol2.fin.dentro")
	resumen += I18n.tf("sol2.fin.reservas", [
		estado.reservas.energia, estado.reservas.agua, estado.reservas.oxigeno, estado.reservas.alimento,
	])
	var motivo := {
		"oxigeno_agotado": I18n.t("sol2.derrota.ox"),
		"aire_sin_activar": I18n.t("sol2.derrota.aire"),
		"hambre_al_dormir": I18n.t("sol2.derrota.comida"),
	}
	interfaz.presentar(I18n.t("sol2.fin.ok" if derrota.is_empty() else "sol2.fin.fail"),
		motivo.get(derrota, resumen), I18n.t("ui.volver_jugar") if local else "")
	finalizado.emit(resultado)

func _actualizar() -> void:
	var estado := recursos.estado()
	if abierto and not concluido and not estado.derrota.is_empty():
		_terminar(estado, estado.derrota)
		if is_queued_for_deletion():
			return
	if is_instance_valid(huerto) or is_instance_valid(laboratorio):
		return

	var ficha: Array = OBJETIVOS[paso]
	var destino: Vector2 = ficha[0] if ruta.is_empty() else ruta.front()
	var cerca := _cerca(ficha[0])
	var puede_elegir := cerca
	var lugar := _obj(paso, "tit")
	var accion := _obj(paso, "act")
	var detalle := _obj(paso, "msg") if aviso.is_empty() else aviso
	var opcion := ""

	match paso:
		Paso.DECISION, Paso.SALIR:
			opcion = I18n.t("sol2.alt.quedarme")
		Paso.REPARAR:
			opcion = I18n.t("sol2.btn.volver_adentro")
			puede_elegir = _cerca(PuestoUmbra.ESCLUSA)
		Paso.AIRE:
			opcion = I18n.t("sol2.alt.aire_despues" if salida_pendiente else "sol2.alt.dormitorio")
		Paso.PLANTAS:
			opcion = I18n.t("sol2.btn.volver_dormitorio")
		Paso.DESCANSO:
			if not estado.aire_asegurado:
				accion = I18n.t("sol2.cama.sin_aire_act")
				detalle = I18n.t("sol2.cama.sin_aire_msg")
				opcion = I18n.t("sol2.cama.sin_aire_alt")
			elif estado.reservas.alimento == 0:
				accion = I18n.t("sol2.cama.hambre_act")
				detalle = I18n.t("sol2.cama.hambre_msg")
				opcion = I18n.t("sol2.cama.hambre_alt")

	if paso == Paso.SALIR and not estado.aire_asegurado and aviso.is_empty():
		detalle = I18n.t("sol2.salir_alerta")

	if paso in [Paso.DECISION, Paso.SALIR, Paso.REPARAR] and aviso.is_empty() and not estado.aire_asegurado:
		if estado.reservas.energia < 10:
			detalle = I18n.t("sol2.alerta_bateria_baja")

	if _cerca_del_aire(estado):
		lugar = _obj(Paso.AIRE, "tit")
		accion = _obj(Paso.AIRE, "act")
		detalle = _obj(Paso.AIRE, "msg") if aviso.is_empty() else aviso
		cerca = true
		destino = AIRE
		if estado.reservas.agua == 0 and estado.hielo > 0:
			opcion = I18n.t("sol2.alt.ir_filtro")
			puede_elegir = true
	elif puesto.interior and paso != Paso.DECISION and _cerca(CONTROL):
		accion = I18n.t("sol2.alt.consultar_tareas")
		cerca = true

	if _puede_usar_filtro(estado):
		lugar = I18n.t("sol2.filtro.tit")
		detalle = I18n.t("sol2.filtro.msg")
		accion = I18n.t("sol2.filtro.act")
		opcion = ""
		cerca = true
		puede_elegir = false
		destino = AGUA

	if puesto.interior and _cerca(PLANTAS):
		cerca = true
		accion = I18n.t("sol2.guia.plantas.act")

	if puesto.plano:
		detalle = I18n.t("sol2.pista.cerrar_plano")

	oscuridad.visible = puesto.interior and estado.sin_luz and not puesto.plano

	# Indicador de baliza exterior para paneles solares
	var en_exterior_paneles := not puesto.interior and (paso == Paso.REPARAR or paso == Paso.ENTRAR)
	paneles.visible = en_exterior_paneles
	if en_exterior_paneles:
		var reparado: bool = REPARAR in estado.decisiones
		paneles.text = I18n.t("sol2.paneles.ok" if reparado else "sol2.paneles.sin")
		paneles.add_theme_color_override("font_color", HUD.VERDE if reparado else HUD.CIAN)
		paneles.position = puesto.proyectar_suelo(PANELES - Vector2(0, 45)) - Vector2(100, 20)

	# Mensaje contextual de Pluto
	var pluto_texto := ""
	if paso == Paso.DECISION and not cerca:
		if estado.reservas.energia < 10 and not estado.aire_asegurado:
			pluto_texto = I18n.t("sol2.pluto.bateria_ojo")
		else:
			pluto_texto = I18n.t("sol2.pluto.polvo")
	elif paso == Paso.SALIR:
		pluto_texto = I18n.t("sol2.pluto.rafagas")
	elif paso == Paso.REPARAR:
		pluto_texto = I18n.t("sol2.pluto.fijar")
	elif paso == Paso.ENTRAR:
		pluto_texto = I18n.t("sol2.pluto.paneles_salvo")
	elif paso == Paso.AIRE and not estado.aire_asegurado:
		pluto_texto = I18n.t("sol2.pluto.tanques")
	elif paso == Paso.PLANTAS:
		pluto_texto = I18n.t("sol2.pluto.plantas")
	elif estado.aire_asegurado:
		pluto_texto = I18n.t("sol2.pluto.descansa")

	var pluto_a_la_vista := not taller.visible and not cerca and puesto.interior and not puesto.plano and juego_activo()
	interfaz.aviso_de_pluto(pluto_a_la_vista, puesto.proyectar_suelo(puesto.posicion_pluto()), pluto_texto)

	taller.mostrar_aire(estado)
	interfaz.visible = not taller.visible
	interfaz.ruta_del_dia(estado, salida_pendiente, paso == Paso.DESCANSO)
	interfaz.actualizar(lugar, detalle, accion, opcion, cerca and juego_activo(),
		puede_elegir and juego_activo(), puesto.interior, puesto.plano,
		puesto.proyectar_suelo(destino) - Vector2(0, 18), puesto.proyectar_suelo(puesto.punto))
	if is_instance_valid(pad_tactil):
		pad_tactil.establecer_habilitado(juego_activo() and not taller.visible and not is_instance_valid(huerto) and not puesto.plano)
	if is_instance_valid(sabias_que):
		if not juego_activo() or taller.visible or is_instance_valid(huerto) or puesto.plano:
			sabias_que.ocultar()
		else:
			var evitar: Array[Rect2] = [Rect2(24, 14, 1240, 126)]
			if interfaz.guia.visible:
				evitar.append(interfaz.guia.get_global_rect())
			if interfaz.aviso_pluto.visible:
				evitar.append(interfaz.aviso_pluto.get_global_rect())
			sabias_que.evitar(evitar)
			if not _ciencia_pendiente.is_empty():
				var tema := _ciencia_pendiente
				_ciencia_pendiente = ""
				sabias_que.mostrar(tema)
			elif not SabiasQue.ya_visto("polvo"):
				sabias_que.mostrar("polvo")

func _abrir_taller(tipo: String) -> void:
	var estado := recursos.estado()
	var costo := 6 if tipo == "aire" else 4
	if estado.reservas.energia < costo or (tipo == "aire" and estado.reservas.agua < 1) or (tipo == "reparar" and estado.reservas.alimento < 1):
		audio.sonar_error()
		aviso = I18n.t("sol2.falta.aire6_1" if tipo == "aire" else "sol2.falta.rep4_1")
		return
	taller.abrir(tipo)
	_actualizar()

func _cerrar_taller() -> void:
	taller.hide()
	aviso = I18n.t("sol2.taller.sin_gasto")
	_actualizar()

func _completar_taller(tipo: String) -> void:
	# Se comprueba otra vez: el alimento puede bajar mientras se trabaja.
	taller.hide()
	if tipo == "aire":
		_asegurar_aire(recursos.estado())
		if recursos.estado().aire_asegurado:
			_ciencia_pendiente = "oxigeno"
	elif recursos.aplicar_decision(REPARAR, COSTO_REPARAR):
		salida_pendiente = false
		interfaz.celebrar(I18n.t("sol2.taller.logro_cierres"))
		audio.sonar_reparar()
		_ir(Paso.ENTRAR)
		aviso = I18n.t("sol2.taller.pluto_cierres")
	else:
		audio.sonar_error()
		aviso = I18n.t("sol2.taller.falta_res")
	_actualizar()
