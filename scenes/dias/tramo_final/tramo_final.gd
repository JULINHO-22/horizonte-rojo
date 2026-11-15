extends Control
## El integrador configura el tramo antes de añadirlo al árbol.
signal preparacion_completada(historial: Dictionary)
signal impacto_registrado(historial: Dictionary)
signal terminado(resultado: String, historial: Dictionary)

const Recursos := preload("res://scripts/mecanicas/recursos_mision.gd")
const Reglas := preload("res://scenes/dias/tramo_final/reglas.gd")
const Mapa := preload("res://scenes/dias/tramo_final/mapa_tramo.gd")
const Vista := preload("res://scenes/dias/tramo_final/vista.gd")
const ArchivoNASA := preload("res://scenes/dias/tramo_final/archivo_nasa.gd")
const RADIO := Vector2(402, 251)
const ESCLUSA := Vector2(400, 382)
const TALLER := Vector2(660, 245)
const RADIO_PROTEGIDA := Vector2(135, PuestoUmbra.SUELO)
const ACCESO_NUCLEO := PuestoUmbra.ACCESO_NUCLEO
const UMBRAL_NUCLEO := Mapa.UMBRAL
const PUERTA_PROTEGIDA := Vector2(414, PuestoUmbra.SUELO)
const AIRE_PROTEGIDO := Vector2(535, PuestoUmbra.SUELO)
const RETORNO_HIELO := Vector2(278, PuestoUmbra.SUELO)
const AIRE := PuestoUmbra.ESTACION_OXIGENO
const DORMITORIO := Vector2(685, 89)
const HUERTO := Vector2(407, 96)
const SOPORTES := {"montaje_0": Vector2(256, PuestoUmbra.SUELO),
	"montaje_1": Vector2(340, PuestoUmbra.SUELO), "montaje_2": Vector2(424, PuestoUmbra.SUELO)}

var recursos: Recursos
var historial: Dictionary
var mapa: Mapa
var vista: Vista
var etapa := ""
var plan := ""
var _lecturas: Array[String] = []
var _guias: Dictionary = {}
var _objetivo := ""
var _confirmacion := ""
var _ocupado := false
var _fin := false

func configurar(partida: Recursos, antecedentes: Dictionary) -> void:
	recursos = partida
	historial = antecedentes.duplicate(true)

func _ready() -> void:
	if recursos == null or recursos.estado().sol not in [4, 5]:
		push_error(I18n.t("tramo.err.config"))
		set_process(false)
		return
	var marco := Control.new()
	marco.size = Vector2(1280, 720)
	marco.clip_contents = true
	marco.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(marco)
	mapa = Mapa.new()
	mapa.pluto_acompana = true
	marco.add_child(mapa)
	mapa.entrar("base", RADIO + Vector2(0, 20))
	mapa.lecturas = _lecturas
	vista = Vista.new()
	marco.add_sibling(vista)
	if recursos.estado().sol == 4:
		plan = historial.get("plan_dia4", "")
		if recursos.estado().decisiones.has(Reglas.ID_PLAN) and Reglas.PLANES.has(plan):
			_preparar_noche()
		else:
			_preparar_aviso()
			var aviso := I18n.t("tramo.s4.iris_nota") if historial.get("sistemas_danados", false) else I18n.t("tramo.s4.aviso")
			vista.decir("Pluto", aviso)
	elif historial.has("impacto_solar") and recursos.estado().decisiones.has(Reglas.ID_TORMENTA):
		mapa.compuerta = 1.0
		mapa.entrar("refugio", PUERTA_PROTEGIDA)
		_restaurar_impacto(historial.impacto_solar)
	else:
		mapa.paneles = 3 if historial.get("refugio_reforzado", false) else 0
		_paso("aviso5", I18n.t("tramo.s5.aviso"), {"control": RADIO})
		vista.decir("Iris", I18n.t("tramo.s5.iris"))

func _process(delta: float) -> void:
	if _fin:
		return
	var direccion := Vector2(
		float(Input.is_physical_key_pressed(KEY_D) or Input.is_action_pressed("ui_right")) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_action_pressed("ui_left")),
		float(Input.is_physical_key_pressed(KEY_S) or Input.is_action_pressed("ui_down")) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_action_pressed("ui_up"))
	)
	if not _ocupado and not vista.abierta() and mapa.arrastre.is_empty():
		mapa.avanzar(direccion.normalized(), minf(0.05, delta))
		mapa.actualizar_camara(delta)
	if not _confirmacion.is_empty() and _cercana() != _confirmacion:
		_confirmacion = ""
	mapa.permite_tocar = not _ocupado and not vista.abierta()
	mapa.foco = _apuntado(mapa.cursor) if mapa.permite_tocar else ""
	for id: String in _guias:
		mapa.nombres[id] = _texto_accion(id)
	mapa.tiempo += delta
	mapa.queue_redraw()

func _unhandled_key_input(evento: InputEvent) -> void:
	if not evento is InputEventKey or not evento.pressed or evento.echo or _fin:
		return
	if evento.physical_keycode == KEY_ESCAPE and vista.abierta():
		vista.cerrar()
	elif evento.physical_keycode in [KEY_E, KEY_SPACE] and mapa.arrastre.is_empty():
		_interactuar()
	elif evento.physical_keycode == KEY_M and mapa.interior and not vista.abierta() and not _ocupado and mapa.arrastre.is_empty():
		mapa.plano = not mapa.plano
		vista.mostrar_plano(mapa.plano)
	else:
		return
	get_viewport().set_input_as_handled()

func _input(evento: InputEvent) -> void:
	if not evento is InputEventMouse or mapa == null or _fin or _ocupado or vista.abierta() or mapa.plano:
		return
	mapa.cursor = evento.position
	if not evento is InputEventMouseButton or evento.button_index != MOUSE_BUTTON_LEFT:
		return
	if evento.pressed:
		_puntero_inicio(evento.position)
	else:
		_puntero_fin(evento.position)

func _apuntado(posicion: Vector2) -> String:
	var alcance := mapa.alcance_interaccion()
	var mejor := 43.0
	var id_cerca := ""
	for id: String in _guias:
		if mapa.punto.distance_to(_guias[id]) >= alcance:
			continue
		var distancia: float = mapa.ancla_interaccion(id, _guias[id]).distance_to(posicion)
		if distancia < mejor:
			mejor = distancia
			id_cerca = id
	return id_cerca

func _puntero_inicio(posicion: Vector2) -> void:
	var id := _apuntado(posicion)
	if etapa in ["purificar", "blindaje"] and not mapa.carga.is_empty():
		if mapa.ancla_carga().distance_to(posicion) < 55.0:
			mapa.arrastre = "objeto"
		elif not id.is_empty():
			vista.decir("Pluto", I18n.t("tramo.pista.arrastra"))
	elif not id.is_empty():
		_interactuar(id)

func _puntero_fin(posicion: Vector2) -> void:
	var gesto := mapa.arrastre
	mapa.arrastre = ""
	if gesto == "objeto":
		var id := _apuntado(posicion)
		if not id.is_empty():
			_interactuar(id)

func _paso(id: String, objetivo: String, guias: Dictionary) -> void:
	etapa = id
	_objetivo = objetivo
	_guias = guias
	if mapa.interior and recursos.estado().sol == 4:
		_guias["control"] = RADIO
	mapa.blancos = _guias
	mapa.nombres.clear()
	mapa.arrastre = ""
	_confirmacion = ""
	for marca: String in _guias:
		mapa.nombres[marca] = _texto_accion(marca)

func _cercana() -> String:
	var alcance := mapa.alcance_interaccion()
	var seleccion := ""
	for id: String in _guias:
		var distancia := mapa.punto.distance_to(_guias[id])
		if distancia < alcance:
			alcance = distancia
			seleccion = id
	return seleccion

func _texto_accion(id: String) -> String:
	if not id.is_empty() and id == _confirmacion:
		return I18n.t("tramo.nodos.descanso_plan") if id == "carga" else I18n.t("tramo.nodos.descanso_fin")
	if id == "control" and etapa == "aviso5":
		return I18n.t("tramo.nodos.aviso_s5")
	if id == "emisora" and etapa == "salida5":
		return I18n.t("tramo.nodos.enviar_ok") if historial.impacto_solar.final == "mision_cumplida" else I18n.t("tramo.nodos.evacuar")
	if etapa == "sondeos":
		if _lecturas.has(id):
			return I18n.t("tramo.nodos.extraer") if id == "veta" and _lecturas.size() == 2 else I18n.t("tramo.nodos.revisar")
		return I18n.t("tramo.nodos.medir") if not id.is_empty() else ""
	if id.begins_with("montaje_"):
		return I18n.t("tramo.nodos.montaje")
	var claves := {
		"control": "tramo.nodos.radio", "afuera": "tramo.nodos.afuera", "retorno": "tramo.nodos.retorno",
		"filtro": "tramo.nodos.filtro", "taller": "tramo.nodos.taller",
		"refugio": "tramo.nodos.refugio", "montaje": "tramo.nodos.blindaje",
		"ventilacion": "tramo.nodos.ventilacion", "aire": "tramo.nodos.oxigeno",
		"descanso": "tramo.nodos.cama", "carga": "tramo.nodos.espera", "plantas": "tramo.nodos.plantas",
		"sello": "tramo.nodos.sello", "emisora": "tramo.nodos.emisora",
		"volver_capsula": "tramo.nodos.volver_capsula",
	}
	var clave: String = claves.get(id, "")
	return "" if clave.is_empty() else I18n.t(clave)

func _interactuar(id := "") -> void:
	if _ocupado or _fin or vista.abierta() or mapa.plano:
		return
	var accion := _cercana() if id.is_empty() else id
	if accion.is_empty():
		return
	if accion == "control":
		if etapa == "aviso4":
			_elegir_plan()
		elif etapa == "aviso5":
			var panel := vista.abrir_control(5, I18n.t("tramo.s5.aviso_pista"))
			Vista.boton(panel, I18n.t("tramo.s5.transmitir"), Rect2(34, 234, 242, 42), _avisar_tierra)
		else:
			vista.abrir_control(recursos.estado().sol, _objetivo)
		return
	match etapa:
		"aviso4":
			_estacion_final_dia(accion)
		"salida_hielo":
			mapa.entrar("hielo", Vector2(300, PuestoUmbra.SUELO))
			_paso("sondeos", I18n.t("tramo.pista.comparar"), {
				"escarcha": Vector2(555, PuestoUmbra.SUELO), "veta": PuestoUmbra.MUESTRA})
			vista.decir("Percy", I18n.t("tramo.percy.sondeos"))
		"sondeos":
			_sondear(accion)
		"vuelta_hielo":
			mapa.entrar("base", ESCLUSA)
			_paso("purificar", I18n.t("tramo.pista.filtro"), {"filtro": PuestoUmbra.EQUIPO_AGUA[0]})
		"purificar":
			_purificar()
		"recoger_blindaje":
			mapa.carga = "protecciones"
			_paso("llevar_blindaje", I18n.t("tramo.pista.esclusa_nuc"), {"refugio": ACCESO_NUCLEO})
			vista.decir("Teo", I18n.t("tramo.teo.muro"))
		"llevar_blindaje":
			mapa.entrar("refugio", UMBRAL_NUCLEO)
			_mostrar_soportes()
		"blindaje":
			if SOPORTES.has(accion):
				_instalar_proteccion(accion)
			else:
				vista.decir("Teo", I18n.t("tramo.teo.aire"))
		"probar_aire":
			_probar_aire()
		"noche":
			_estacion_final_dia(accion)
		"ir_refugio":
			_entrar_al_nucleo()
		"informar":
			_informe_final()
		"salida5":
			_preparar_salida()
		"volver_capsula":
			_salir_del_nucleo()
		"sellar":
			_tormenta()

func _preparar_aviso() -> void:
	_paso("aviso4", I18n.t("tramo.s4.aviso_radiacion"), {"control": RADIO, "aire": AIRE,
		"carga": PuestoUmbra.TERMINALES.energia, "plantas": HUERTO})

func _elegir_plan() -> void:
	var panel := vista.abrir_control(4, I18n.t("tramo.s4.elegir_titulo"), true)
	var fila := 218
	var descripciones := {
		"hielo": I18n.t("tramo.s4.desc.hielo"),
		"refuerzo": I18n.t("tramo.s4.desc.refuerzo"),
		"ambas": I18n.t("tramo.s4.desc.ambas"),
	}
	for id: String in Reglas.PLANES:
		var motivo := Reglas.impedimento(id, recursos.estado())
		var boton := Vista.boton(panel, Reglas.titulo_plan(id), Rect2(34, fila, 275, 34), _elegir.bind(id))
		boton.disabled = not motivo.is_empty()
		Vista.rotulo(panel, descripciones[id] + (" " + motivo if not motivo.is_empty() else ""),
			Rect2(327, fila, 580, 36), 15, Vista.PAPEL)
		fila += 41
	Vista.rotulo(panel, I18n.t("tramo.s4.reserva_aire"), Rect2(34, 359, 615, 24), 15, Vista.AMBAR)
	Vista.boton(panel, I18n.t("tramo.s4.swim_btn"), Rect2(710, 354, 200, 32), _abrir_fuente.bind(ArchivoNASA.SWIM))

func _elegir(id: String) -> void:
	if not Reglas.impedimento(id, recursos.estado()).is_empty():
		return
	plan = id
	vista.cerrar()
	if id == "refuerzo":
		_ir_taller()
	else:
		_paso("salida_hielo", I18n.t("tramo.pista.barranco"), {"afuera": ESCLUSA})
		vista.decir("Pluto", I18n.t("tramo.pluto.swim"))

func _ir_taller() -> void:
	_paso("recoger_blindaje", I18n.t("tramo.pista.taller_recoger"), {"taller": TALLER})

func _sondear(id: String) -> void:
	if not _lecturas.has(id):
		_lecturas.append(id)
		var lectura := I18n.t("tramo.sondeo.a") if id == "escarcha" else I18n.t("tramo.sondeo.b")
		vista.decir("Percy", lectura)
		if _lecturas.size() == 2:
			_paso("sondeos", I18n.t("tramo.pista.extraer"), {"veta": PuestoUmbra.MUESTRA})
	elif id == "veta" and _lecturas.size() == 2:
		_ocupado = true
		mapa.perforando = true
		var taladro := create_tween()
		taladro.tween_property(mapa, "avance_muestra", 1.0, 2.1)
		await taladro.finished
		mapa.perforando = false
		mapa.carga = "hielo"
		_ocupado = false
		_paso("vuelta_hielo", I18n.t("tramo.pista.volver_hielo"), {"retorno": RETORNO_HIELO})
		vista.decir("Percy", I18n.t("tramo.percy.guardada"))
	else:
		vista.decir("Percy", I18n.t("tramo.percy.falta_otro"))

func _purificar() -> void:
	_ocupado = true
	mapa.agua_en_curso = true
	mapa.etapa_agua = 2
	await create_tween().tween_property(mapa, "avance_agua", 1.0, 1.1).finished
	mapa.agua_en_curso = false
	mapa.carga = ""
	_ocupado = false
	if plan == "ambas":
		vista.decir("Pluto", I18n.t("tramo.pluto.muestra_limpia"))
		_ir_taller()
	else:
		_completar_preparacion()

func _mostrar_soportes() -> void:
	var puntos := {"ventilacion": AIRE_PROTEGIDO}
	for soporte: String in SOPORTES:
		if not mapa.placas.has(soporte):
			puntos[soporte] = SOPORTES[soporte]
	_paso("blindaje", I18n.t("tramo.pista.arrastrar_3"), puntos)

func _instalar_proteccion(id: String) -> void:
	if mapa.placas.has(id):
		return
	mapa.placas.append(id)
	mapa.paneles = mapa.placas.size()
	if mapa.paneles < SOPORTES.size():
		_mostrar_soportes()
		vista.decir("Teo", I18n.tf("tramo.teo.panel", [SOPORTES.size() - mapa.paneles]))
		return
	mapa.carga = ""
	_paso("probar_aire", I18n.t("tramo.pista.vent"), {"ventilacion": AIRE_PROTEGIDO})
	vista.decir("Teo", I18n.t("tramo.teo.probemos"))

func _probar_aire() -> void:
	mapa.entrar("base", ACCESO_NUCLEO)
	_completar_preparacion()

func _completar_preparacion() -> void:
	var antes: Dictionary = recursos.estado().reservas
	if not Reglas.completar_plan(recursos, plan):
		vista.decir("Pluto", I18n.t("tramo.pluto.plan_invalido"))
		mapa.paneles = 0
		mapa.placas.clear()
		_lecturas.clear()
		_preparar_aviso()
		return
	var agua: int = recursos.estado().reservas.agua - antes.agua
	historial.plan_dia4 = plan
	historial.refugio_reforzado = Reglas.PLANES[plan].refuerzo
	preparacion_completada.emit(historial.duplicate(true))
	var resumen := I18n.tf("tramo.agua_anadida", [agua]) if plan != "refuerzo" else ""
	resumen += I18n.t("tramo.nucleo_protegido") if historial.refugio_reforzado else I18n.t("tramo.nucleo_original")
	vista.decir("Pluto", resumen)
	_preparar_noche()

func _preparar_noche() -> void:
	var meta := I18n.t("tramo.pista.paso_ox")
	if recursos.estado().aire_asegurado:
		meta = I18n.t("tramo.pista.ir_dormitorio")
	_paso("noche", meta, {"aire": AIRE, "descanso": DORMITORIO,
		"carga": PuestoUmbra.TERMINALES.energia, "plantas": HUERTO})


func _estacion_final_dia(id: String) -> void:
	match id:
		"aire":
			if recursos.estado().aire_asegurado:
				vista.decir("Iris", I18n.t("tramo.iris.aire_noche"))
			elif recursos.activar_oxigeno():
				vista.decir("Iris", I18n.t("tramo.iris.aire_bateria"))
				if etapa == "noche":
					_preparar_noche()
			else:
				vista.decir("Iris", I18n.t("tramo.iris.falta_aire"))
		"carga":
			_esperar_carga()
		"plantas":
			_atender_huerto()
		"descanso":
			_consultar_descanso()

func _esperar_carga() -> void:
	var estado := recursos.estado()
	var periodo: float = Recursos.RECARGA_SOLAR[estado.polvo]
	if not is_finite(periodo):
		vista.decir("Pluto", I18n.t("tramo.pluto.sin_luz"))
		return
	var cambio := I18n.t("tramo.pluto.carga_1")
	if estado.reservas.energia == Recursos.LIMITES.energia:
		cambio = I18n.t("tramo.pluto.bat_llena")
	if _confirmacion == "carga":
		_confirmacion = ""
		_avanzar_carga(periodo)
	else:
		_confirmacion = "carga"
		vista.decir("Pluto", I18n.tf("tramo.pluto.esperar", [cambio]))

func _avanzar_carga(periodo: float) -> void:
	vista.cerrar()
	recursos.avanzar(periodo)
	if not recursos.estado().derrota.is_empty():
		_emitir_final("derrota")
	else:
		vista.decir("Pluto", I18n.t("tramo.pluto.comparar_espera"))

func _atender_huerto() -> void:
	var estado := recursos.estado()
	for cultivo: String in estado.bandejas:
		if recursos.comer(cultivo):
			vista.decir("Iris", I18n.t("tramo.iris.cosecha"))
			return
	if estado.bandejas.has("lechuga"):
		vista.decir("Iris", I18n.t("tramo.iris.creciendo"))
		return
	if recursos.sembrar("lechuga"):
		vista.decir("Iris", I18n.t("tramo.iris.recien"))
	else:
		vista.decir("Iris", I18n.t("tramo.iris.falta_sembrar"))

func _consultar_descanso() -> void:
	var estado := recursos.estado()
	var riesgo := I18n.t("tramo.pista.pasan_manana")
	if not estado.aire_asegurado:
		riesgo = I18n.t("tramo.riesgo.aire")
	elif estado.reservas.alimento == 0:
		riesgo = I18n.t("tramo.riesgo.comida")
	elif historial.refugio_reforzado:
		var margen := 7 if historial.get("sistemas_danados", false) else 6
		if estado.reservas.energia < margen:
			riesgo = I18n.tf("tramo.riesgo.margen", [margen])
	if _confirmacion == "descanso":
		_confirmacion = ""
		_dormir()
	else:
		_confirmacion = "descanso"
		vista.decir("Iris", I18n.tf("tramo.iris.tocar_cama", [riesgo]))

func _dormir() -> void:
	vista.cerrar()
	# La campaña cierra el día y abre el siguiente. La vista previa hace lo mismo.
	_emitir_final("dia4_listo")

func _avisar_tierra() -> void:
	vista.cerrar()
	mapa.radio_enviada = true
	_paso("ir_refugio", I18n.t("tramo.pista.bajar_nucleo"), {"refugio": ACCESO_NUCLEO})
	vista.decir("Pluto", I18n.t("tramo.pluto.s5_control"))

func _entrar_al_nucleo() -> void:
	_ocupado = true
	_paso("cruzar_umbral", I18n.t("tramo.pista.cruzar"), {})
	var velo := ColorRect.new()
	velo.size = Vector2(1280, 720)
	velo.color = Color("#16131a")
	velo.modulate.a = 0.0
	velo.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(velo)
	await create_tween().tween_property(velo, "modulate:a", 1.0, 0.24).finished
	mapa.compuerta = 0.0
	mapa.entrada_nucleo = 0.0
	mapa.entrar("refugio", UMBRAL_NUCLEO)
	mapa.direccion_izquierda = false
	vista.decir("Teo", I18n.t("tramo.teo.pasa_nora"), Vector2(866, 331))
	var cruzar := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
	cruzar.tween_property(velo, "modulate:a", 0.0, 0.30)
	cruzar.tween_property(mapa, "entrada_nucleo", 1.0, 0.85)
	await cruzar.finished
	velo.queue_free()
	_ocupado = false
	_paso("sellar", I18n.t("tramo.pista.sellar"), {"sello": PUERTA_PROTEGIDA})

func _tormenta() -> void:
	_paso("impacto", I18n.t("tramo.pista.impacto"), {})
	vista.decir("Iris", I18n.t("tramo.iris.impacto"), Vector2(473, 142))
	_ocupado = true
	var pulso := create_tween().set_trans(Tween.TRANS_SINE)
	pulso.tween_property(mapa, "compuerta", 1.0, 0.36)
	for i in ArchivoNASA.LECTURAS.size():
		pulso.tween_callback(_mostrar_lectura.bind(i))
		pulso.tween_property(mapa, "impacto", ArchivoNASA.nivel(i) * 0.88, 0.70)
	await pulso.finished
	_ocupado = false
	var registro := Reglas.impacto(recursos, historial)
	if registro.is_empty():
		push_error(I18n.t("tramo.err.impacto"))
		return
	historial.impacto_solar = registro
	impacto_registrado.emit(historial.duplicate(true))
	_restaurar_impacto(registro)

func _mostrar_lectura(indice: int) -> void:
	mapa.fase_radiacion = ArchivoNASA.fase_texto(indice)
	mapa.nivel_radiacion = ArchivoNASA.nivel(indice)

func _restaurar_impacto(registro: Dictionary) -> void:
	mapa.paneles = 3 if historial.get("refugio_reforzado", false) else 0
	mapa.impacto = 0.15 if registro.final == "mision_cumplida" else 0.45
	if registro.final == "derrota":
		_ocupado = true
		await create_tween().tween_property(mapa, "impacto", 1.0, 0.55).finished
		_emitir_final("derrota")
		return
	_paso("informar", I18n.t("tramo.pista.informar"), {"emisora": RADIO_PROTEGIDA})
	var consecuencia: String = I18n.t("tramo.iris.res_ok") if mapa.paneles == 3 else I18n.t("tramo.iris.res_afectado")
	if historial.get("sistemas_danados", false):
		consecuencia += I18n.t("tramo.iris.res_dano2")
	vista.decir("Iris", consecuencia)

func _informe_final() -> void:
	mapa.fase_radiacion = ""
	var registro: Dictionary = historial.impacto_solar
	var logrado: bool = registro.final == "mision_cumplida"
	var orden := I18n.t("tramo.tierra.cumplida") if logrado else I18n.t("tramo.tierra.evacuacion")
	var explicacion := I18n.t("tramo.causa.blindaje") if historial.get("refugio_reforzado", false) else I18n.t("tramo.causa.sin_refuerzo")
	if historial.get("sistemas_danados", false):
		explicacion += I18n.t("tramo.causa.dano2")
	vista.decir("Tierra", orden)
	vista.mostrar_lecturas(registro, explicacion, ArchivoNASA.DONKI, ArchivoNASA.GUIA_RAD)
	_paso("salida5", I18n.t("tramo.pista.salida5"), {"emisora": RADIO_PROTEGIDA})

func _preparar_salida() -> void:
	vista.cerrar_lecturas()
	_paso("volver_capsula", I18n.t("tramo.pista.volver_cap"), {"volver_capsula": UMBRAL_NUCLEO})
	vista.decir("Teo", I18n.t("tramo.teo.salir"), Vector2(865, 326))

func _salir_del_nucleo() -> void:
	_ocupado = true
	_paso("salir_umbral", I18n.t("tramo.pista.salir_umbral"), {})
	mapa.punto = UMBRAL_NUCLEO
	var salida := create_tween().set_trans(Tween.TRANS_SINE)
	salida.tween_property(mapa, "compuerta", 0.0, 0.45)
	salida.tween_property(mapa, "entrada_nucleo", 0.0, 0.65)
	await salida.finished
	_emitir_final(historial.impacto_solar.final)

func _abrir_fuente(url: String) -> void:
	OS.shell_open(url)

func _emitir_final(resultado: String) -> void:
	_fin = true
	terminado.emit(resultado, historial.duplicate(true))
