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
const PUERTA_PROTEGIDA := Vector2(335, PuestoUmbra.SUELO)
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
var _ocupado := false
var _fin := false

func configurar(partida: Recursos, antecedentes: Dictionary) -> void:
	recursos = partida
	historial = antecedentes.duplicate(true)

func _ready() -> void:
	if recursos == null or recursos.estado().sol not in [4, 5]:
		push_error("Configura TramoFinal con una partida del día 4 o 5.")
		set_process(false)
		return
	var marco := Control.new()
	marco.size = Vector2(1280, 720)
	marco.clip_contents = true
	marco.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(marco)
	mapa = Mapa.new()
	marco.add_child(mapa)
	mapa.entrar("base", RADIO + Vector2(0, 26))
	mapa.lecturas = _lecturas
	vista = Vista.new()
	marco.add_sibling(vista)
	recursos.cambiado.connect(_actualizar)
	if recursos.estado().sol == 4:
		plan = historial.get("plan_dia4", "")
		if recursos.estado().decisiones.has(Reglas.ID_PLAN) and Reglas.PLANES.has(plan):
			_preparar_noche()
		else:
			_preparar_aviso()
			var aviso := "Iris dejó una nota: los equipos dañados tendrán menos margen mañana." if historial.get("sistemas_danados", false) else "La base está funcionando. Control recibió un aviso para mañana."
			vista.decir("Pluto", aviso)
	elif historial.has("impacto_solar") and recursos.estado().decisiones.has(Reglas.ID_TORMENTA):
		mapa.compuerta = 1.0
		mapa.entrar("refugio", PUERTA_PROTEGIDA)
		_restaurar_impacto(historial.impacto_solar)
	else:
		mapa.paneles = 3 if historial.get("refugio_reforzado", false) else 0
		_paso("aviso5", "Ve a Control y avisa a Tierra antes de cerrar el refugio.", {"control": RADIO})
		vista.decir("Iris", "La actividad del Sol está subiendo. Hoy esperaremos bajo protección.")

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
	mapa.permite_tocar = not _ocupado and not vista.abierta()
	mapa.foco = _apuntado(mapa.cursor) if mapa.permite_tocar else ""
	for id: String in _guias:
		mapa.nombres[id] = _texto_accion(id)
	mapa.tiempo += delta
	mapa.queue_redraw()

func _unhandled_key_input(evento: InputEvent) -> void:
	if not evento is InputEventKey or not evento.pressed or evento.echo or _fin:
		return
	if evento.physical_keycode == KEY_SPACE:
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
	var alcance := 18.0 if mapa.interior else 27.0
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
			vista.decir("Pluto", "Toma lo que llevas en la mano y arrástralo hasta el equipo.")
	elif id == "sello":
		mapa.arrastre = "sello"
	elif not id.is_empty():
		_interactuar(id)

func _puntero_fin(posicion: Vector2) -> void:
	var gesto := mapa.arrastre
	mapa.arrastre = ""
	if gesto == "objeto":
		var id := _apuntado(posicion)
		if not id.is_empty():
			_interactuar(id)
	elif gesto == "sello":
		var inicio := mapa.ancla_interaccion("sello", PUERTA_PROTEGIDA)
		if posicion.distance_to(inicio + Vector2(100, 0)) <= 38:
			_interactuar("sello")

func _paso(id: String, objetivo: String, guias: Dictionary) -> void:
	etapa = id
	_objetivo = objetivo
	_guias = guias
	mapa.blancos = guias
	mapa.nombres.clear()
	mapa.arrastre = ""
	_actualizar()

func _actualizar() -> void:
	var estado := recursos.estado()
	var titulo := "Día 4  /  Antes de la tormenta" if estado.sol == 4 else "Día 5  /  Bajo protección"
	vista.actualizar(titulo, _objetivo, estado.reservas)

func _cercana() -> String:
	var alcance := 18.0 if mapa.interior else 27.0
	var seleccion := ""
	for id: String in _guias:
		var distancia := mapa.punto.distance_to(_guias[id])
		if distancia < alcance:
			alcance = distancia
			seleccion = id
	return seleccion

func _texto_accion(id: String) -> String:
	if etapa == "sondeos":
		if _lecturas.has(id):
			return "Extraer la muestra" if id == "veta" and _lecturas.size() == 2 else "Revisar la lectura"
		return "Medir bajo el suelo" if not id.is_empty() else ""
	if id.begins_with("montaje_"):
		return "Soporte del blindaje"
	return {
		"control": "Abrir Control", "afuera": "Salir al barranco", "retorno": "Volver a la base",
		"filtro": "Limpiar la muestra", "taller": "Recoger protecciones",
		"refugio": "Entrar al núcleo protegido", "montaje": "Colocar blindaje",
		"ventilacion": "Comprobar el paso del aire", "aire": "Revisar oxígeno",
		"descanso": "Cerrar el día", "carga": "Esperar carga solar", "plantas": "Revisar los cultivos",
		"sello": "Cerrar la compuerta interior", "emisora": "Revisar la señal de Tierra",
	}.get(id, "")

func _interactuar(id := "") -> void:
	if _ocupado or _fin or vista.abierta() or mapa.plano:
		return
	var accion := _cercana() if id.is_empty() else id
	if accion.is_empty():
		return
	match etapa:
		"aviso4":
			if accion == "control":
				_elegir_plan()
			else:
				_estacion_final_dia(accion)
		"salida_hielo":
			mapa.entrar("hielo", Vector2(300, PuestoUmbra.SUELO))
			_paso("sondeos", "Compara los dos puntos marcados antes de taladrar.", {
				"escarcha": Vector2(555, PuestoUmbra.SUELO), "veta": PuestoUmbra.MUESTRA})
			vista.decir("Percy", "Los mapas desde el espacio orientan la búsqueda. Ahora compara aquí qué hay debajo del polvo.")
		"sondeos":
			_sondear(accion)
		"vuelta_hielo":
			mapa.entrar("base", ESCLUSA)
			_paso("purificar", "Cruza Energía hasta el filtro azul. Arrastra tu caja al filtro cuando estés cerca.", {"filtro": PuestoUmbra.EQUIPO_AGUA[0]})
		"purificar":
			_purificar()
		"recoger_blindaje":
			mapa.carga = "protecciones"
			_paso("llevar_blindaje", "Lleva las protecciones a la esclusa; allí está el acceso al núcleo protegido.", {"refugio": ESCLUSA})
			vista.decir("Teo", "Cubriremos el muro junto a la compuerta. La rejilla tiene que quedar libre para que entre aire.")
		"llevar_blindaje":
			mapa.entrar("refugio", Vector2(75, PuestoUmbra.SUELO))
			_mostrar_soportes()
		"blindaje":
			if SOPORTES.has(accion):
				_instalar_proteccion(accion)
			else:
				vista.decir("Teo", "Aquí pasa el aire. Busca la marca junto a la compuerta para fijar los paneles.")
		"probar_aire":
			_probar_aire()
		"noche":
			_estacion_final_dia(accion)
		"aviso5":
			_avisar_tierra()
		"ir_refugio":
			mapa.entrar("refugio", Vector2(75, PuestoUmbra.SUELO))
			_paso("sellar", "Reúne a la tripulación y desliza el cierre de la compuerta.", {"sello": PUERTA_PROTEGIDA})
			vista.decir("Teo", "Estamos todos aquí. Cierra para mantener el aire en esta parte de la base.")
		"informar":
			_informe_final()
		"sellar":
			_tormenta()

func _preparar_aviso() -> void:
	_paso("aviso4", "Consulta el aviso de radiación en Control.", {"control": RADIO, "aire": AIRE,
		"carga": PuestoUmbra.TERMINALES.energia, "plantas": HUERTO})

func _elegir_plan() -> void:
	var panel := vista.abrir("Mañana nos quedamos dentro",
		"Una tormenta solar está en camino. Elige cómo usar las reservas de hoy.")
	Vista.boton(panel, "Mapa de hielo · NASA", Rect2(650, 27, 220, 40), _abrir_fuente.bind(ArchivoNASA.SWIM))
	var fila := 148
	var descripciones := {
		"hielo": "5 de energía y 1 de comida. Hasta 3 de agua.",
		"refuerzo": "3 de energía. La base pierde menos durante la tormenta.",
		"ambas": "7 de energía y 1 de comida. Agua y protección.",
	}
	for id: String in Reglas.PLANES:
		var ficha: Dictionary = Reglas.PLANES[id]
		var motivo := Reglas.impedimento(id, recursos.estado())
		var boton := Vista.boton(panel, ficha.titulo, Rect2(32, fila, 276, 55), _elegir.bind(id))
		boton.disabled = not motivo.is_empty()
		Vista.rotulo(panel, descripciones[id] + (" " + motivo if not motivo.is_empty() else ""),
			Rect2(336, fila + 4, 525, 62), 18, Vista.PAPEL)
		fila += 76
	Vista.rotulo(panel, "El aire de esta noche también necesita 6 de energía y 1 de agua.",
		Rect2(32, 391, 599, 60), 17, Vista.AMBAR)
	Vista.boton(panel, "Volver a Control", Rect2(650, 392, 220, 50), vista.cerrar)

func _elegir(id: String) -> void:
	if not Reglas.impedimento(id, recursos.estado()).is_empty():
		return
	plan = id
	vista.cerrar()
	if id == "refuerzo":
		_ir_taller()
	else:
		_paso("salida_hielo", "Cruza la esclusa y reúnete con Percy en el barranco.", {"afuera": ESCLUSA})
		vista.decir("Pluto", "El hielo que traigas pasará por el laboratorio. Sigue las marcas de Percy.")

func _ir_taller() -> void:
	_paso("recoger_blindaje", "Entra al Taller por la derecha de Control y recoge las protecciones.", {"taller": TALLER})

func _sondear(id: String) -> void:
	if not _lecturas.has(id):
		_lecturas.append(id)
		var lectura := "Se ve blanco arriba, pero debajo solo hay tierra seca." if id == "escarcha" else "Aquí aparece una franja gruesa de hielo bajo la tierra."
		vista.decir("Percy", lectura)
		if _lecturas.size() == 2:
			_paso("sondeos", "Vuelve al punto con hielo debajo y extrae la muestra.", {"veta": PuestoUmbra.MUESTRA})
	elif id == "veta" and _lecturas.size() == 2:
		_ocupado = true
		mapa.perforando = true
		var taladro := create_tween()
		taladro.tween_property(mapa, "avance_muestra", 1.0, 2.1)
		await taladro.finished
		mapa.perforando = false
		mapa.carga = "hielo"
		_ocupado = false
		_paso("vuelta_hielo", "Regresa por la izquierda con la caja de hielo.", {"retorno": RETORNO_HIELO})
		vista.decir("Percy", "Muestra guardada. Llévala a derretir y limpiar antes de usar el agua.")
	else:
		vista.decir("Percy", "Aún falta comparar el otro punto.")

func _purificar() -> void:
	_ocupado = true
	mapa.agua_en_curso = true
	mapa.etapa_agua = 2
	await create_tween().tween_property(mapa, "avance_agua", 1.0, 1.1).finished
	mapa.agua_en_curso = false
	mapa.carga = ""
	_ocupado = false
	if plan == "ambas":
		vista.decir("Pluto", "Muestra limpia. Terminemos el refuerzo y haremos el recuento de las dos tareas.")
		_ir_taller()
	else:
		_completar_preparacion()

func _mostrar_soportes() -> void:
	var puntos := {"ventilacion": AIRE_PROTEGIDO}
	for soporte: String in SOPORTES:
		if not mapa.placas.has(soporte):
			puntos[soporte] = SOPORTES[soporte]
	_paso("blindaje", "Arrastra el blindaje a tres soportes. Deja libre la rejilla.", puntos)

func _instalar_proteccion(id: String) -> void:
	if mapa.placas.has(id):
		return
	mapa.placas.append(id)
	mapa.paneles = mapa.placas.size()
	if mapa.paneles < SOPORTES.size():
		_mostrar_soportes()
		vista.decir("Teo", "Panel fijado. Quedan %d soportes libres." % (SOPORTES.size() - mapa.paneles))
		return
	mapa.carga = ""
	_paso("probar_aire", "Comprueba que la rejilla de ventilación quedó libre.", {"ventilacion": AIRE_PROTEGIDO})
	vista.decir("Teo", "Protecciones fijadas. Probemos que sigue llegando aire antes de cerrar.")

func _probar_aire() -> void:
	mapa.entrar("base", ESCLUSA)
	_completar_preparacion()

func _completar_preparacion() -> void:
	var antes: Dictionary = recursos.estado().reservas
	if not Reglas.completar_plan(recursos, plan):
		vista.decir("Pluto", "Las reservas cambiaron y ya no cubren el plan. Vuelve a Control.")
		mapa.paneles = 0
		mapa.placas.clear()
		_lecturas.clear()
		_preparar_aviso()
		return
	var agua: int = recursos.estado().reservas.agua - antes.agua
	historial.plan_dia4 = plan
	historial.refugio_reforzado = Reglas.PLANES[plan].refuerzo
	preparacion_completada.emit(historial.duplicate(true))
	var resumen := "Agua añadida: %d. " % agua if plan != "refuerzo" else ""
	resumen += "El núcleo está protegido." if historial.refugio_reforzado else "El núcleo conserva su protección original."
	vista.decir("Pluto", resumen)
	_preparar_noche()

func _preparar_noche() -> void:
	var meta := "Pasa por Energía para llegar al laboratorio. Prepara el aire antes de descansar."
	if recursos.estado().aire_asegurado:
		meta = "Aire asegurado. Comprueba la comida y ve al dormitorio."
	_paso("noche", meta, {"aire": AIRE, "descanso": DORMITORIO,
		"carga": PuestoUmbra.TERMINALES.energia, "plantas": HUERTO})


func _estacion_final_dia(id: String) -> void:
	match id:
		"aire":
			if recursos.estado().aire_asegurado:
				vista.decir("Iris", "El aire está asegurado para esta noche.")
			elif recursos.activar_oxigeno():
				vista.decir("Iris", "El agua y la batería nos dieron aire para la noche.")
				if etapa == "noche":
					_preparar_noche()
			else:
				vista.decir("Iris", "Necesitamos 6 de energía y 1 de agua. Puedes esperar carga junto a las baterías.")
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
		vista.decir("Pluto", "Los paneles no reciben luz ahora.")
		return
	var cambio := "Los paneles recuperarán un punto de energía."
	if estado.reservas.energia == Recursos.LIMITES.energia:
		cambio = "La batería está llena. La espera puede servir para que crezcan los cultivos."
	var panel := vista.abrir("Esperar junto a las baterías",
		cambio + " Durante la espera seguimos usando aire y comida.", 285)
	Vista.boton(panel, "Esperar una carga", Rect2(32, 199, 240, 48), _avanzar_carga.bind(periodo))
	Vista.boton(panel, "Volver", Rect2(649, 199, 220, 48), vista.cerrar)

func _avanzar_carga(periodo: float) -> void:
	vista.cerrar()
	recursos.avanzar(periodo)
	if not recursos.estado().derrota.is_empty():
		_emitir_final("derrota")
	else:
		vista.decir("Pluto", "Compara lo que ganamos con lo que se usó durante la espera.")

func _atender_huerto() -> void:
	var estado := recursos.estado()
	for cultivo: String in estado.bandejas:
		if recursos.comer(cultivo):
			vista.decir("Iris", "Comimos de la cosecha. Ahora tenemos más reservas para descansar.")
			return
	if estado.bandejas.has("lechuga"):
		vista.decir("Iris", "Aún está creciendo. Puedes dejar pasar una carga solar para darle tiempo.")
		return
	if recursos.sembrar("lechuga"):
		vista.decir("Iris", "Acabamos de sembrar. La planta necesita agua, energía y tiempo. Espera una carga solar y vuelve.")
	else:
		vista.decir("Iris", "Sembrar necesita 1 de agua y 1 de energía.")

func _consultar_descanso() -> void:
	var estado := recursos.estado()
	var riesgo := "Las reservas que queden pasarán a la mañana."
	if not estado.aire_asegurado:
		riesgo = "Aún falta preparar el aire. Si cierras el día así, la misión termina."
	elif estado.reservas.alimento == 0:
		riesgo = "No queda comida. Si cierras el día así, la misión termina."
	elif historial.refugio_reforzado:
		var margen := 7 if historial.get("sistemas_danados", false) else 6
		if estado.reservas.energia < margen:
			riesgo = "El aire está preparado. Con %d de energía, mañana tendríamos margen para seguir trabajando." % margen
	var panel := vista.abrir("Fin del día 4", riesgo, 285)
	Vista.boton(panel, "Cerrar el día", Rect2(32, 199, 240, 48), _dormir)
	Vista.boton(panel, "Seguir preparando", Rect2(649, 199, 220, 48), vista.cerrar)

func _dormir() -> void:
	vista.cerrar()
	# La campaña cierra el día y abre el siguiente. La vista previa hace lo mismo.
	_emitir_final("dia4_listo")

func _avisar_tierra() -> void:
	mapa.radio_enviada = true
	_paso("ir_refugio", "Cruza la esclusa para reunirte con la tripulación bajo protección.", {"refugio": ESCLUSA})
	vista.decir("Pluto", "Informe enviado. La respuesta tarda en llegar. Cierren el refugio mientras esperamos.")

func _tormenta() -> void:
	_paso("impacto", "Compuerta cerrada. Mantente en el núcleo protegido.", {})
	vista.decir("Iris", "Los sensores detectan partículas del Sol. Quédense aquí hasta que baje la alerta.")
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
		push_error("No se pudo registrar el impacto solar.")
		return
	historial.impacto_solar = registro
	impacto_registrado.emit(historial.duplicate(true))
	_restaurar_impacto(registro)

func _mostrar_lectura(indice: int) -> void:
	var lectura: Dictionary = ArchivoNASA.LECTURAS[indice]
	mapa.fase_radiacion = lectura.fase
	mapa.nivel_radiacion = ArchivoNASA.nivel(indice)

func _restaurar_impacto(registro: Dictionary) -> void:
	mapa.paneles = 3 if historial.get("refugio_reforzado", false) else 0
	mapa.impacto = 0.15 if registro.final == "mision_cumplida" else 0.45
	if registro.final == "derrota":
		_ocupado = true
		await create_tween().tween_property(mapa, "impacto", 1.0, 0.55).finished
		_emitir_final("derrota")
		return
	_paso("informar", "La alerta bajó. Revisa qué cambió en la emisora del refugio.", {"emisora": RADIO_PROTEGIDA})
	var consecuencia: String = "Las protecciones ayudaron a conservar aire y energía." if mapa.paneles == 3 else "La tormenta afectó más equipos. Comprueba las reservas."
	if historial.get("sistemas_danados", false):
		consecuencia += " El daño del día 2 empeoró las pérdidas."
	vista.decir("Iris", consecuencia)

func _informe_final() -> void:
	var registro: Dictionary = historial.impacto_solar
	var logrado: bool = registro.final == "mision_cumplida"
	var orden := "Tierra recibió el informe. Los equipos aguantaron y pueden enviar los resultados." if logrado else "Tierra confirmó que hay reservas para la salida. La investigación queda interrumpida."
	var panel := vista.abrir("Llegó la respuesta de Tierra", orden, 470)
	var nombres := {"energia": "Energía", "agua": "Agua", "oxigeno": "Oxígeno", "alimento": "Comida"}
	var x := 32
	for campo: String in nombres:
		Vista.rotulo(panel, nombres[campo], Rect2(x, 166, 190, 32), 20, Vista.MENTA)
		var lectura := "%d  →  %d" % [registro.antes[campo], registro.despues[campo]]
		Vista.rotulo(panel, lectura, Rect2(x, 208, 190, 54), 30, Vista.PAPEL)
		x += 209
	var explicacion := "El blindaje ayudó a conservar aire y energía." if historial.get("refugio_reforzado", false) else "El núcleo sin refuerzo sufrió más pérdidas."
	if historial.get("sistemas_danados", false):
		explicacion += " El daño previo costó 1 de energía y 1 de oxígeno más."
	Vista.rotulo(panel, explicacion, Rect2(32, 275, 830, 49), 18, Vista.AMBAR)
	var llamada := "Enviar resultados y regresar" if logrado else "Confirmar evacuación"
	Vista.rotulo(panel, "Alerta DONKI y lecturas de Curiosity de 2017. El ejercicio resume la espera.",
		Rect2(32, 332, 836, 31), 16, Vista.MENTA)
	Vista.boton(panel, llamada, Rect2(32, 390, 335, 51), _emitir_final.bind(registro.final))
	var alerta := Vista.boton(panel, "Alerta DONKI", Rect2(474, 390, 181, 51), _abrir_fuente.bind(ArchivoNASA.DONKI))
	alerta.tooltip_text = ArchivoNASA.DONKI_ID
	Vista.boton(panel, "Lecturas de Curiosity", Rect2(668, 390, 203, 51), _abrir_fuente.bind(ArchivoNASA.GUIA_RAD))

func _abrir_fuente(url: String) -> void:
	OS.shell_open(url)

func _emitir_final(resultado: String) -> void:
	_fin = true
	terminado.emit(resultado, historial.duplicate(true))
