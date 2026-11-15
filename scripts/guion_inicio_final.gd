extends Control
## Presentación del guion y entrada a las actividades aprobadas.
const Campana := preload("res://scripts/campana_narrativa.gd")
const Viaje := preload("res://scripts/viaje_espacial.gd")
const DialogoEscena := preload("res://scripts/dialogo_escena.gd")
const VISTAS_FINALES := {
	"--final-recursos": "res://scenes/pruebas/banco_recursos.tscn",
	"--final-incompleta": "res://scenes/final_incompleta.tscn",
	"--final-cumplida": "res://scenes/final_cumplida.tscn",
}
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
	"cierre": "Esta sala tiene dos puertas: cerramos una antes de abrir la otra para conservar el aire del refugio.",
	"taller": "Aquí se revisan los trajes y se guardan herramientas y repuestos.",
}
const Recursos := preload("res://scripts/mecanicas/recursos_mision.gd")
const Tutorial := preload("res://scenes/dias/dia_1/tutorial_sol_uno.gd")
var recursos := Recursos.new()
const SOLES_JUGABLES := {
	2: preload("res://scenes/dias/dia_2/dia_2.tscn"),
	3: preload("res://scenes/dias/dia_3/dia_3.tscn"),
	4: preload("res://scenes/dias/tramo_final/nivel.tscn"),
	5: preload("res://scenes/dias/tramo_final/nivel.tscn"),
}
var nivel_activo: Control
var historial_soles := {}
var menu_soles: ColorRect
var prueba_soles := false
var integrar_soles := true
const PanelControl := preload("res://scripts/panel_control.gd")
const MapaNucleo := preload("res://scenes/dias/tramo_final/mapa_tramo.gd")
var visita_nucleo: MapaNucleo
var marco_nucleo: Control
var panel_control: PanelControl
var extraccion_hasta := 0.0
var estaciones: VBoxContainer
var estacion := ""
var turnos_cosecha: Dictionary = {}
var campana = Campana.new()
var fase := "portada"
var reloj := 0.0
var posicion := Vector2(220, PuestoUmbra.SUELO)
var puesto: PuestoUmbra
var viaje: Control
var capa: Control
var titulo: Label
var voz: Control
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
	for argumento in OS.get_cmdline_user_args():
		if VISTAS_FINALES.has(argumento):
			get_tree().change_scene_to_file.call_deferred(VISTAS_FINALES[argumento])
			return
	restaurado = campana.cargar()
	historial_soles = restaurado.get("historial", {})
	if not restaurado.is_empty():
		var guardado: Variant = restaurado.recursos
		if not guardado is Dictionary or guardado.get("sol") != campana.sol or not recursos.restaurar_estado(guardado):
			var inicial := recursos.guardar_estado()
			inicial.sol = campana.sol
			inicial.terminado = campana.listo_para_regresar()
			recursos.restaurar_estado(inicial)
	if OS.has_feature("web") and restaurado.is_empty():
		_cambiar("ida")
	else:
		_mostrar()

func _process(delta: float) -> void:
	if is_instance_valid(menu_soles):
		return
	if is_instance_valid(nivel_activo):
		if campana.sol == 2 and nivel_activo.juego_activo():
			recursos.avanzar(delta)
		elif campana.sol == 3 and not recursos.estado().derrota.is_empty():
			_cerrar_sol.call_deferred(false)
		return
	if is_instance_valid(visita_nucleo):
		visita_nucleo.avanzar(_direccion(), minf(delta, 0.05))
		visita_nucleo.queue_redraw()
		boton.visible = _cerca_salida_nucleo()
		return
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
		"base":
			if is_instance_valid(panel_control):
				return
			if not estacion.is_empty():
				if _sol_uno() and estacion == "cultivos":
					if not _avanzar_recursos(delta):
						return
					_actualizar_cosecha(recursos.estado())
					_refrescar_recursos()
				return
			if not _avanzar_recursos(delta):
				return
			_caminar(delta)
			_refrescar_recursos()
		"camino_base", "camino_nave":
			_caminar(delta)
		"expedicion_sol_1":
			if not _avanzar_recursos(delta):
				return
			if reloj < extraccion_hasta:
				puesto.avance_muestra = 1.0 - (extraccion_hasta - reloj) / 1.5
				puesto.queue_redraw()
				return
			puesto.taladro_sol_uno_x = -1.0
			_caminar(delta)
		"esclusa":
			puesto.avance_esclusa = reloj
			puesto.punto.y = 440 - 43 * smoothstep(0.68, 1.36, reloj) - 49 * smoothstep(2.6, 3.45, reloj)
			puesto.caminando = (reloj > 0.68 and reloj < 1.36) or (reloj > 2.6 and reloj < 3.45)
			puesto.paso = fposmod(reloj * 2.5, 1.0)
			puesto.actualizar_camara(delta)
			puesto.queue_redraw()
			voz.decir("Pluto", "Ya hay aire. Se abre la puerta interior." if reloj > 2.22 else "Cerramos la puerta de fuera para que no escape el aire.")
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

func _input(evento: InputEvent) -> void:
	if not evento is InputEventKey or not evento.pressed or evento.echo:
		return
	if evento.ctrl_pressed and evento.shift_pressed and evento.physical_keycode == KEY_M:
		get_viewport().set_input_as_handled()
		if is_instance_valid(menu_soles):
			_cerrar_menu_soles()
		else:
			_abrir_menu_soles()

func _unhandled_key_input(event: InputEvent) -> void:
	if is_instance_valid(nivel_activo) or is_instance_valid(menu_soles):
		return
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if is_instance_valid(visita_nucleo):
		if event.physical_keycode == KEY_ESCAPE or (event.physical_keycode == KEY_E and _cerca_salida_nucleo()):
			_cerrar_nucleo()
		get_viewport().set_input_as_handled()
		return
	if is_instance_valid(panel_control):
		if event.physical_keycode == KEY_ESCAPE:
			_cerrar_control()
		get_viewport().set_input_as_handled()
		return
	if event.physical_keycode == KEY_E or event.physical_keycode == KEY_ENTER:
		_accion()
	elif event.physical_keycode == KEY_M and fase == "base":
		plano = not plano
		puesto.plano = plano
	elif event.physical_keycode == KEY_ESCAPE and fase in ["ida", "aterrizaje"]:
		_iniciar_caminata()
	elif event.physical_keycode == KEY_ESCAPE and not estacion.is_empty():
		_cerrar_estacion()

func _direccion() -> Vector2:
	return Vector2(
		int(Input.is_physical_key_pressed(KEY_D) or Input.is_action_pressed("ui_right")) - int(Input.is_physical_key_pressed(KEY_A) or Input.is_action_pressed("ui_left")),
		int(Input.is_physical_key_pressed(KEY_S) or Input.is_action_pressed("ui_down")) - int(Input.is_physical_key_pressed(KEY_W) or Input.is_action_pressed("ui_up"))).normalized()

func _caminar(delta: float) -> void:
	puesto.avanzar(_direccion(), minf(delta, 0.05))
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

func _sol_uno() -> bool:
	return campana.sol == 1

func _avanzar_recursos(delta: float) -> bool:
	recursos.avanzar(delta)
	if recursos.estado().derrota.is_empty():
		return true
	_cambiar("derrota")
	_guardar()
	return false

func _deposito_cercano() -> Dictionary:
	for sitio: Dictionary in Tutorial.DEPOSITOS:
		if absf(posicion.x - sitio.x) <= 32:
			return sitio
	return {}

func _guia_expedicion() -> void:
	var sitio := _deposito_cercano()
	var recogido := not Tutorial.deposito(recursos.estado()).is_empty()
	if aviso_tiempo <= 0:
		voz.decir("Percy", "¡Ya tenemos hielo! Vuelve a la esclusa, a la izquierda." if recogido else
			"Queda poca agua. Detecté hielo bajo el suelo. El mapa SWIM de NASA da pistas. Sigue a Iris: lleva el taladro.")
	pista.text = "← Refugio" if recogido else "Depósitos a la derecha →"
	if absf(posicion.x - PuestoUmbra.ESCLUSA.x) < 28:
		boton.text = "E · Entrar al refugio"
	elif not recogido and not sitio.is_empty():
		var agua := mini(Recursos.LIMITES.agua - int(recursos.estado().reservas.agua), sitio.hielo * 3)
		if aviso_tiempo <= 0:
			voz.decir("Percy", "Aquí ahorras batería. Más a la derecha hay más hielo." if sitio.hielo == 1 else
				"Aquí hay más hielo. El taladro y el filtro usarán más batería.")
		boton.text = "E · %s · +%d agua tras filtrar" % [Tutorial.etiqueta_deposito(sitio), agua]
		pista.text = "Batería total con filtro: cercano 3 · profundo 7"
	else:
		return
	boton.show()
	boton.size = boton.get_minimum_size().max(Vector2(256, 45))
	_ubicar_accion()

func _accion_expedicion() -> void:
	if reloj < extraccion_hasta:
		return
	var datos := recursos.estado()
	if absf(posicion.x - PuestoUmbra.ESCLUSA.x) < 28:
		posicion = PuestoUmbra.ENTRADA
		_cambiar("esclusa")
		return
	if not Tutorial.deposito(datos).is_empty():
		return
	var sitio := _deposito_cercano()
	if sitio.is_empty():
		return
	if not recursos.recoger_hielo(sitio.hielo, sitio.energia, sitio.id):
		voz.decir("Iris", "Falta batería. Los paneles la recargan poco a poco. También puedes ir al depósito cercano.")
		aviso_tiempo = 6
		return
	puesto.taladro_sol_uno_x = sitio.x
	puesto.depositos_sol_uno = []
	puesto.hielo_sol_uno = true
	puesto.avance_muestra = 0
	extraccion_hasta = reloj + 1.5
	boton.hide()
	voz.decir("Iris", "Con el taladro sacamos %d de hielo. Ahora toca llevarlo al filtro." % sitio.hielo)
	aviso_tiempo = 5
	_guardar()

func _actualizar_guia() -> void:
	boton.visible = false
	if fase == "expedicion_sol_1":
		_guia_expedicion()
	elif fase == "camino_base":
		pista.text = "A / D o flechas   ·   Refugio a la derecha"
		var rover := puesto.proyectar_suelo(Vector2(minf(puesto.punto.x + 85, PuestoUmbra.ESCLUSA.x - 44), PuestoUmbra.SUELO))
		voz.position = Vector2(clampf(rover.x + 20, 40, 860), clampf(rover.y - 250, 74, 350))
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
		var cerca := _estacion_cercana()
		if _sol_uno():
			_guia_sol_uno(cerca)
			return
		if cerca == "dormitorio" and not campana.listo_para_regresar():
			boton.text = "E · Descansar"
			boton.visible = true
		elif cerca == "radio" and not plano:
			boton.text = "E · Abrir Control"
			boton.visible = true
		elif cerca == "nucleo":
			boton.text = "E · Bajar al núcleo protegido"
			boton.visible = true
		elif cerca == "cierre" and campana.listo_para_regresar():
			boton.text = "E · Salir hacia la nave"
			boton.visible = true
		elif cerca in ["agua", "oxigeno"] and not campana.listo_para_regresar():
			boton.text = "E · Purificar agua" if cerca == "agua" else "E · Preparar oxígeno"
			boton.visible = true
		elif not cerca.is_empty() and FICHAS.has(cerca):
			boton.text = "E · " + PuestoUmbra.NOMBRES.get(cerca, "Entrada").capitalize()
			boton.visible = true
		if boton.visible:
			_ubicar_accion()
		if aviso_tiempo <= 0:
			voz.decir("Pluto", "Asegura el aire en el laboratorio de Agua y Oxígeno antes de dormir." if not campana.listo_para_regresar() else "Revisa la ruta en Control antes de salir.")
			voz.visible = reloj < 6.0
		else:
			voz.visible = true

func _guia_sol_uno(cerca: String) -> void:
	var objetivo := Tutorial.objetivo(recursos.estado())
	if aviso_tiempo <= 0:
		voz.decir("Pluto", Tutorial.GUIA[objetivo])
	if cerca not in ["radio", "oxigeno", "cultivos", "cierre", "agua", "dormitorio", "nucleo"]:
		return
	boton.text = {"radio": "Revisar reservas", "oxigeno": "Preparar oxígeno", "cultivos": "Revisar bandejas",
		"cierre": "Salir con Iris", "agua": "Purificar hielo", "dormitorio": "Descansar", "nucleo": "Bajar al núcleo protegido"}[cerca]
	boton.text = "E · " + boton.text
	boton.show()
	_ubicar_accion()

func _accion_sol_uno(cerca: String) -> void:
	match cerca:
		"radio":
			recursos.aplicar_decision(Tutorial.CONTROL, {})
			voz.decir("Pluto", "Los rayos son la energía de los equipos, las burbujas son el aire y la gota es el agua. Guarda 6 de energía y 1 de agua para asegurar el aire.")
			aviso_tiempo = 8
			_guardar()
			_abrir_control()
		"nucleo":
			_abrir_nucleo()
		"oxigeno", "agua", "cultivos":
			_abrir_estacion(cerca)
		"cierre":
			posicion = PuestoUmbra.ESCLUSA
			_cambiar("expedicion_sol_1")
			_guardar()
		"dormitorio":
			_intentar_descanso()

func _intentar_descanso() -> void:
	if recursos.dormir():
		_cambiar("noche")
	else:
		_cambiar("derrota")
		_guardar()

func _accion() -> void:
	if is_instance_valid(visita_nucleo):
		if _cerca_salida_nucleo():
			_cerrar_nucleo()
		return
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
			if is_instance_valid(panel_control):
				return
			if not estacion.is_empty():
				_cerrar_estacion()
				return
			var cerca := _estacion_cercana()
			if _sol_uno():
				_accion_sol_uno(cerca)
			elif cerca == "dormitorio" and not campana.listo_para_regresar():
				_intentar_descanso()
			elif cerca in ["agua", "oxigeno", "cultivos"] and not campana.listo_para_regresar():
				_abrir_estacion(cerca)
			elif cerca == "radio" and not plano:
				_abrir_control()
			elif cerca == "nucleo":
				_abrir_nucleo()
			elif cerca == "cierre" and campana.listo_para_regresar():
				posicion = PuestoUmbra.ESCLUSA
				_cambiar("camino_nave")
				_guardar()
			elif cerca == "energia":
				voz.decir("Pluto", "Con más polvo en el aire, llega menos luz a los paneles. Fuente: NASA, Pancam.")
				aviso_tiempo = 9
			elif FICHAS.has(cerca):
				voz.decir("Pluto", FICHAS[cerca])
				aviso_tiempo = 9
		"camino_nave":
			if absf(posicion.x - 220) < 30:
				_cambiar("pilotaje")
		"expedicion_sol_1":
			_accion_expedicion()
		"pilotaje":
			_cambiar("despegue")
		"derrota":
			_reiniciar()
		"epilogo":
			if reloj >= 10:
				_reiniciar()

func _montar_sol() -> void:
	nivel_activo = SOLES_JUGABLES[campana.sol].instantiate()
	match campana.sol:
		2:
			nivel_activo.configurar(recursos)
			nivel_activo.finalizado.connect(_cerrar_sol_2, CONNECT_DEFERRED)
		3:
			nivel_activo.configurar(recursos, historial_soles.get("sistemas_danados", false))
			nivel_activo.descanso_solicitado.connect(_cerrar_sol_3, CONNECT_DEFERRED)
		4, 5:
			nivel_activo.configurar(recursos, historial_soles)
			nivel_activo.terminado.connect(_cerrar_tramo, CONNECT_DEFERRED)
			nivel_activo.preparacion_completada.connect(_registrar_historial)
			nivel_activo.impacto_registrado.connect(_registrar_historial)
	capa.add_child(nivel_activo)

func _registrar_historial(datos: Dictionary) -> void:
	historial_soles = datos.duplicate(true)
	_guardar("base")

func _cerrar_sol_2(datos: Dictionary) -> void:
	historial_soles.sistemas_danados = datos.sistemas_danados
	historial_soles.paneles_protegidos = datos.paneles_protegidos
	_cerrar_sol(datos.completado)

func _cerrar_sol_3(datos: Dictionary) -> void:
	historial_soles.decision_sol_3 = datos.decision
	_cerrar_sol(true)

func _cerrar_tramo(resultado: String, datos: Dictionary) -> void:
	historial_soles = datos
	if resultado in ["mision_cumplida", "evacuacion"]:
		var final := "final_cumplida" if resultado == "mision_cumplida" else "final_incompleta"
		_guardar(final)
		_cambiar(final)
	else:
		_cerrar_sol(resultado == "dia4_listo")

func _cerrar_sol(completado: bool) -> void:
	if completado and recursos.dormir():
		_cambiar("noche")
	else:
		_cambiar("derrota")
		_guardar()

func _abrir_menu_soles() -> void:
	capa.process_mode = Node.PROCESS_MODE_DISABLED
	menu_soles = ColorRect.new()
	menu_soles.color = Color("#1d2a36")
	menu_soles.size = AREA.size
	add_child(menu_soles)
	var anterior := capa
	capa = menu_soles
	_etiqueta("Soles de Horizonte Rojo", Rect2(124, 88, 1032, 64), 43)
	_etiqueta("Un sol es un día en Marte. Dura un poquito más que un día en la Tierra.", Rect2(128, 166, 990, 64), 23)
	var nombres := ["Llegada y búsqueda de hielo", "Tormenta de polvo", "Aire o invernadero", "Preparar el refugio", "Tormenta solar"]
	for i in range(nombres.size()):
		_boton("Sol %d · %s" % [i + 1, nombres[i]], Rect2(130, 245 + i * 61, 505, 45), _probar_sol.bind(i + 1))
	_boton("Continuar", Rect2(800, 590, 292, 47), _cerrar_menu_soles)
	if prueba_soles:
		_boton("Volver a la partida guardada", Rect2(800, 528, 292, 47), _volver_a_campana)
	capa = anterior

func _cerrar_menu_soles() -> void:
	remove_child(menu_soles)
	menu_soles.queue_free()
	menu_soles = null
	capa.process_mode = Node.PROCESS_MODE_INHERIT

func _volver_a_campana() -> void:
	get_tree().reload_current_scene.call_deferred()

func _probar_sol(sol: int) -> void:
	_cerrar_menu_soles()
	prueba_soles = true
	campana = Campana.new()
	campana.sol = sol
	campana.noches = sol - 1
	recursos = Recursos.new()
	var estado := recursos.guardar_estado()
	estado.sol = sol
	if sol > 1:
		estado.reservas = {"energia": 12, "agua": 4, "oxigeno": 8, "alimento": 10}
	recursos.restaurar_estado(estado)
	historial_soles = {"refugio_reforzado": sol == 5}
	posicion = PuestoUmbra.TERMINALES.radio
	_cambiar("base")

func _ver_final(clave: String) -> void:
	get_tree().change_scene_to_file.call_deferred(VISTAS_FINALES[clave])

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
	if not prueba_soles:
		campana.borrar()
	historial_soles.clear()
	campana = Campana.new()
	recursos = Recursos.new()
	restaurado = {}
	posicion = Vector2(220, PuestoUmbra.SUELO)
	_cambiar("ida")

func _guardar(fase_guardada := "") -> void:
	if prueba_soles:
		return
	var error: Error = campana.guardar(fase if fase_guardada.is_empty() else fase_guardada, posicion, recursos.guardar_estado(), historial_soles)
	if error != OK:
		push_warning("No se pudo guardar la narrativa: %s" % error_string(error))

func _cambiar(destino: String) -> void:
	fase = destino
	estacion = ""
	turnos_cosecha.clear()
	extraccion_hasta = 0
	aviso_tiempo = 0
	if fase == "base":
		var tormenta: bool = integrar_soles and campana.sol == 2
		var estado := recursos.guardar_estado()
		if tormenta and estado.en_curso and estado.polvo != "tormenta":
			# Compatibilidad con partidas guardadas antes de conectar el segundo sol.
			estado.polvo = "tormenta"
			estado.relojes[0] = 0.0
			recursos.restaurar_estado(estado)
		recursos.iniciar_sol("tormenta" if tormenta else "")
	reloj = 0
	_mostrar()

func _mostrar() -> void:
	nivel_activo = null
	panel_control = null
	visita_nucleo = null
	marco_nucleo = null
	if is_instance_valid(capa):
		remove_child(capa)
		capa.queue_free()
	puesto = null
	viaje = null
	capa = Control.new()
	add_child(capa)
	if fase in ["final_cumplida", "final_incompleta"]:
		_ver_final("--" + fase.replace("_", "-"))
		return
	if integrar_soles and fase == "base" and SOLES_JUGABLES.has(campana.sol) and not campana.listo_para_regresar():
		_montar_sol()
		return
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
		"expedicion_sol_1":
			_crear_mapa(false)
			puesto.bienvenida_percy = true
			puesto.expedicion_sol_uno = true
			puesto.hielo_sol_uno = not Tutorial.deposito(recursos.estado()).is_empty()
			puesto.depositos_sol_uno = [] if puesto.hielo_sol_uno else Tutorial.DEPOSITOS
		"despegue":
			_imagen(PuestoUmbra.SENDERO, AREA)
			nave_salida = _imagen(PuestoUmbra.NAVE, Rect2(280, 275, 170, 260), true)
		"derrota":
			_sombra(AREA, Color.BLACK)
			_etiqueta("Game Over", Rect2(485, 290, 400, 100), 56)
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
	voz = DialogoEscena.new()
	voz.position = Vector2(45, 82)
	capa.add_child(voz)
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
			for i in range(2):
				var opcion := ["Misión incompleta", "Misión cumplida"][i] as String
				var clave := ["--final-incompleta", "--final-cumplida"][i] as String
				_boton("Ver final · " + opcion, Rect2(90 + i * 273, 529, 257, 44), _ver_final.bind(clave))
		"ida":
			titulo.text = "Salida de la Tierra"
			boton.text = "Saltar viaje · Esc"
			boton.visible = true
		"regreso", "llegada_tierra":
			titulo.text = "Marte → Tierra"
			voz.decir("Iris", "Nos llevamos las preguntas y lo que aprendimos. Percy seguirá explorando Marte.")
			pista.text = ""
		"aterrizaje":
			titulo.text = "Aterrizaje en Marte"
			boton.text = "Saltar viaje · Esc"
			boton.visible = true
		"pilotaje":
			titulo.text = "A bordo · Puesto de pilotaje"
			voz.decir("Iris", "Tripulación a bordo, puerta cerrada. Nora, cuando estés lista, inicia el vuelo de regreso.")
			pista.text = "Percy se queda en Marte · Ruta resumida, sin escala"
			boton.text = "E · Iniciar vuelo"
			boton.visible = true
		"camino_base":
			voz.decir("Percy", "Soy Perseverance. Síganme al refugio.")
			_actualizar_guia()
		"camino_nave":
			voz.decir("Percy", "¡Buen regreso! Yo seguiré aquí, buscando nuevas pistas.")
		"expedicion_sol_1":
			titulo.text = "Día 1 de 5 · Hielo bajo el suelo"
			_actualizar_guia()
		"derrota":
			boton.position = Vector2(512, 410)
			boton.text = "Volver a intentar"
			boton.show()
		"base":
			_refrescar_recursos()
			titulo.text = "Sol %d de 5 · Refugio Umbra" % campana.sol
			_actualizar_guia()
		"noche":
			titulo.text = "Fin del sol %d" % campana.sol
			voz.decir("Pluto", "Es hora de descansar. La base queda cerrada mientras dormimos.")
		"amanecer":
			voz.decir("Pluto", "Buenos días. Es hora de preparar el regreso." if campana.listo_para_regresar() else "Buenos días. Comienza el día %d." % campana.sol)
		"despegue":
			voz.decir("Nora", "¡Hasta la próxima, Percy! Tripulación lista para volver.")
		"epilogo":
			titulo.text = "Tierra · Cierre de la historia"
			voz.decir("Equipo científico", "¡Gracias, astronautas! Sus preguntas y sus aportes nos ayudan a comprender Marte. ¡Sigan explorando!")
			boton.text = "Volver al comienzo"
	if fase in ["noche", "amanecer", "llegada_tierra", "aterrizaje"]:
		velo = _sombra(AREA, Color(0, 0, 0, 1 if fase in ["amanecer", "aterrizaje"] else 0))

func _refrescar_recursos() -> void:
	var datos := recursos.estado()
	if _sol_uno():
		var objetivo := Tutorial.objetivo(datos)
		puesto.objetivo_mision = "cultivos" if objetivo in ["sembrar", "cosechar"] else objetivo
	elif not campana.listo_para_regresar():
		puesto.objetivo_mision = "dormitorio" if datos.aire_asegurado else "agua"
	if datos.sin_luz:
		puesto.modulate = Color("#59697d")
	else:
		puesto.modulate = Color.WHITE

func _abrir_control() -> void:
	boton.hide()
	panel_control = PanelControl.new()
	var estado := recursos.estado()
	var regreso := campana.listo_para_regresar()
	panel_control.configurar(estado, regreso, 0.0 if regreso else 58.0)
	panel_control.cerrar_solicitado.connect(_cerrar_control)
	panel_control.ruta_confirmada.connect(_confirmar_ruta)
	capa.add_child(panel_control)
	if not regreso:
		var tarea := "El aire está asegurado. Ve al dormitorio para descansar." if estado.aire_asegurado else "Prepara el aire en el laboratorio de Agua y Oxígeno antes de descansar."
		panel_control.mostrar_tarea(tarea)

func _cerrar_control() -> void:
	capa.remove_child(panel_control)
	panel_control.queue_free()
	panel_control = null
	_actualizar_guia()

func _confirmar_ruta() -> void:
	_cerrar_control()
	voz.decir("Iris", "La ruta está preparada. Salgamos juntos: la nave nos espera a la izquierda del refugio.")
	puesto.objetivo_mision = "cierre"
	aviso_tiempo = 9

func _abrir_nucleo() -> void:
	marco_nucleo = Control.new()
	marco_nucleo.size = AREA.size
	marco_nucleo.clip_contents = true
	marco_nucleo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.add_child(marco_nucleo)
	visita_nucleo = MapaNucleo.new()
	marco_nucleo.add_child(visita_nucleo)
	visita_nucleo.entrar("refugio", MapaNucleo.UMBRAL)
	var guia := DialogoEscena.new()
	guia.position = Vector2(49, 120)
	marco_nucleo.add_child(guia)
	guia.decir("Pluto", "Este túnel conecta con la esclusa. Si hay radiación afuera, nos reunimos en esta sala protegida.")
	capa.move_child(boton, -1)
	var puerta := visita_nucleo.proyectar_suelo(MapaNucleo.UMBRAL)
	boton.position = puerta + Vector2(-128, 28)
	boton.text = "E · Volver a la esclusa"
	boton.show()

func _cerca_salida_nucleo() -> bool:
	return visita_nucleo.punto.distance_to(MapaNucleo.UMBRAL) < visita_nucleo.alcance_interaccion()

func _cerrar_nucleo() -> void:
	capa.remove_child(marco_nucleo)
	marco_nucleo.queue_free()
	marco_nucleo = null
	visita_nucleo = null
	_actualizar_guia()

func _estacion_cercana() -> String:
	if not plano and puesto.punto.distance_to(PuestoUmbra.ACCESO_NUCLEO) < 13.0:
		return "nucleo"
	if puesto.punto.distance_to(PuestoUmbra.ESTACION_OXIGENO) <= 13.0:
		return "oxigeno"
	return puesto.terminal_cercana()

func _abrir_estacion(id: String) -> void:
	estacion = id
	boton.hide()
	estaciones = VBoxContainer.new()
	estaciones.position = Vector2(818, 78 if _sol_uno() else 180)
	estaciones.custom_minimum_size.x = 384
	if _sol_uno() and id == "cultivos":
		estaciones.theme = _tema_plantas()
	capa.add_child(estaciones)
	if _sol_uno():
		_opciones_sol_uno(id)
	elif id == "agua":
		voz.decir("Pluto", "Aquí limpiamos el hielo. Los depósitos de oxígeno están al lado, en esta misma sala.")
		_opcion("Recoger hielo de la reserva de prueba", _hielo_prueba)
		_opcion("Purificar hielo · 2 energía", recursos.purificar_hielo)
	elif id == "oxigeno":
		voz.decir("Pluto", "Este equipo usa agua y batería para asegurar el aire de hoy.")
		_opcion("Asegurar aire · 6 energía y 1 agua", recursos.activar_oxigeno)
	else:
		for cultivo: String in Recursos.CULTIVOS:
			var ficha: Dictionary = Recursos.CULTIVOS[cultivo]
			_opcion("Sembrar %s · %d energía, 1 agua, %d s, +%d comida" % [
				cultivo.capitalize(), ficha.energia, int(ficha.segundos), ficha.alimento], recursos.sembrar.bind(cultivo))
			_opcion("Comer %s" % cultivo, recursos.comer.bind(cultivo))
	var cerrar := Button.new()
	cerrar.text = "Cerrar · Esc"
	cerrar.pressed.connect(_cerrar_estacion)
	estaciones.add_child(cerrar)
	if _sol_uno():
		estaciones.get_child(0).grab_focus()

func _tema_plantas() -> Theme:
	var tema := Theme.new()
	tema.set_constant("separation", "VBoxContainer", 5)
	tema.set_font_size("font_size", "Button", 17)
	tema.set_color("font_disabled_color", "Button", Color("#c2d4df"))
	var colores := {
		"normal": TINTA, "hover": Color("#274858"), "pressed": Color("#315866"),
		"disabled": Color("#233340"),
	}
	for estado: String in colores:
		var estilo := StyleBoxFlat.new()
		estilo.bg_color = colores[estado]
		estilo.border_color = Color("#476473")
		estilo.set_border_width_all(1)
		estilo.set_corner_radius_all(6)
		estilo.content_margin_top = 6
		estilo.content_margin_bottom = 6
		estilo.content_margin_left = 10
		estilo.content_margin_right = 10
		tema.set_stylebox(estado, "Button", estilo)
	return tema

func _opciones_sol_uno(id: String) -> void:
	var datos := recursos.estado()
	if id == "oxigeno":
		voz.decir("Pluto", "Si se acaba el oxígeno, no podemos respirar. Asegura el aire al inicio de cada día. Reserva 6 de energía y 1 de agua.")
		_opcion("Asegurar aire · 6 energía y 1 agua", recursos.activar_oxigeno)
	elif id == "agua":
		voz.decir("Pluto", "El hielo trae polvo. Derrítelo, fíltralo y revisa el agua antes de llenar el tanque.")
		_opcion("Purificar 1 hielo · 2 energía", recursos.purificar_hielo)
	else:
		voz.decir("Pluto", "Elige qué sembrar. El reloj te muestra cuánto falta. Cuando esté listo, recoge y come aquí mismo.")
		for cultivo: String in Recursos.CULTIVOS:
			turnos_cosecha[cultivo] = _opcion("", _usar_bandeja.bind(cultivo))
		var anterior := Tutorial.cosecha(datos)
		if Recursos.CULTIVOS.has(anterior) and Tutorial.COMIDA not in datos.decisiones:
			_opcion("Comer la cosecha guardada", _comer_guardado.bind(anterior))
		_actualizar_cosecha(datos)

func _actualizar_cosecha(datos: Dictionary) -> void:
	for cultivo: String in turnos_cosecha:
		var control: Button = turnos_cosecha[cultivo]
		var ficha: Dictionary = Recursos.CULTIVOS[cultivo]
		if not datos.bandejas.has(cultivo):
			control.text = "Sembrar %s · %d energía, 1 agua · %d s" % [cultivo.capitalize(), ficha.energia, int(ficha.segundos)]
			control.disabled = false
			continue
		var espera := ceili(datos.bandejas[cultivo])
		var reloj_cultivo := "%02d:%02d" % [int(espera / 60.0), espera % 60]
		var lleno: bool = datos.reservas.alimento == Recursos.LIMITES.alimento
		var estado := "lista · comida llena" if lleno else "recoger y comer · +%d comida" % ficha.alimento
		control.text = "%s · %s" % [cultivo.capitalize(), "faltan " + reloj_cultivo if espera > 0 else estado]
		control.disabled = espera > 0 or lleno

func _usar_bandeja(cultivo: String) -> bool:
	if not recursos.estado().bandejas.has(cultivo):
		return recursos.sembrar(cultivo)
	if not recursos.comer(cultivo):
		return false
	recursos.aplicar_decision(Tutorial.COMIDA, {})
	return true

func _comer_guardado(cultivo: String) -> bool:
	if recursos.estado().reservas.alimento == Recursos.LIMITES.alimento:
		return false
	return recursos.aplicar_decision(Tutorial.COMIDA, {"alimento": Recursos.CULTIVOS[cultivo].alimento})

func _opcion(texto: String, accion: Callable) -> Button:
	var control := Button.new()
	control.text = texto
	control.pressed.connect(_usar_estacion.bind(accion))
	estaciones.add_child(control)
	return control

func _usar_estacion(accion: Callable) -> void:
	var aplicada: bool = accion.call()
	if _sol_uno() and aplicada:
		var datos := recursos.estado()
		_actualizar_cosecha(datos)
		voz.decir("Pluto", Tutorial.GUIA[Tutorial.objetivo(datos)])
	else:
		voz.decir("Pluto", "Listo. Revisa las reservas." if aplicada else "Revisa las reservas y si la tarea ya está lista.")
		if _sol_uno() and estacion == "agua":
			voz.decir("Pluto", "Para purificar necesitas hielo, 2 de energía y espacio en el tanque de agua.")
	aviso_tiempo = 6
	_refrescar_recursos()
	if aplicada:
		_guardar()

func _hielo_prueba() -> bool:
	return recursos.aplicar_decision("reserva_hielo_prueba", {}) and recursos.recoger_hielo()

func _cerrar_estacion() -> void:
	estacion = ""
	turnos_cosecha.clear()
	estaciones.hide()
	estaciones.queue_free()

func _crear_mapa(interior: bool) -> void:
	var marco := Control.new()
	marco.size = AREA.size
	marco.clip_contents = true
	marco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.add_child(marco)
	puesto = PuestoUmbra.new()
	puesto.interior = interior
	puesto.guia_sol_uno = _sol_uno() and fase == "base"
	puesto.laboratorio_activo = fase == "base"
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
