extends SceneTree
const Banco := preload("res://scenes/dias/tramo_final/prueba.tscn")
const Reglas := preload("res://scenes/dias/tramo_final/reglas.gd")
const Tramo := preload("res://scenes/dias/tramo_final/tramo_final.gd")

func _initialize() -> void:
	call_deferred("_probar")

func _captura(nombre: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://build/qa/")
	root.get_texture().get_image().save_png("res://build/qa/" + nombre + ".png")

func _camino(nivel: Tramo, ruta: Array) -> void:
	for destino: Vector2 in ruta:
		var distancia := nivel.mapa.punto.distance_to(destino)
		var pasos := ceili(distancia)
		var inicio := nivel.mapa.punto
		for i in range(pasos + 1):
			var sitio := inicio.move_toward(destino, i)
			assert(nivel.mapa.transitable(sitio), "Ruta bloqueada · %s · %s" % [nivel.etapa, sitio])
		nivel.mapa.punto = destino
	nivel.mapa.actualizar_camara(2.0)

func _pulsar(punto: Vector2, presionado: bool) -> void:
	var evento := InputEventMouseButton.new()
	evento.position = punto
	evento.button_index = MOUSE_BUTTON_LEFT
	evento.pressed = presionado
	root.push_input(evento, true)

func _clic(nivel: Tramo, id: String, mundo: Vector2) -> void:
	var sitio := nivel.mapa.ancla_interaccion(id, mundo)
	_pulsar(sitio, true)
	_pulsar(sitio, false)

func _arrastrar(nivel: Tramo, id: String, mundo: Vector2) -> void:
	var destino := nivel.mapa.ancla_interaccion(id, mundo)
	_pulsar(nivel.mapa.ancla_carga(), true)
	assert(nivel.mapa.arrastre == "objeto")
	_pulsar(destino, false)

func _probar() -> void:
	_probar_planes_y_proteccion()
	var banco := Banco.instantiate()
	root.add_child(banco)
	await _captura("dias-45-prueba")
	banco._elegir_dia(5)
	await _captura("dias-45-selector-dia5")
	banco.iniciar(1)
	var atajo := InputEventKey.new()
	atajo.physical_keycode = KEY_M
	atajo.ctrl_pressed = true
	atajo.shift_pressed = true
	atajo.pressed = true
	var partida: Control = banco._pantalla
	root.push_input(atajo)
	assert(is_instance_valid(banco._selector) and partida.process_mode == Node.PROCESS_MODE_DISABLED)
	root.push_input(atajo)
	assert(banco._selector == null and banco._pantalla == partida and partida.process_mode == Node.PROCESS_MODE_INHERIT)
	var nivel: Tramo = banco._pantalla
	nivel.set_process(false)
	assert(not Reglas.impedimento("ambas", nivel.recursos.estado()).is_empty())
	assert(not Reglas.completar_plan(nivel.recursos, "ambas"))
	banco.iniciar(0)
	nivel = banco._pantalla
	nivel.set_process(false)
	_camino(nivel, [Tramo.RADIO])
	nivel.mapa.plano = true
	nivel.vista.mostrar_plano(true)
	nivel.mapa.actualizar_camara(2.0)
	await _captura("dias-45-plano")
	nivel.mapa.plano = false
	nivel.vista.mostrar_plano(false)
	nivel.mapa.actualizar_camara(2.0)
	var tecla := InputEventKey.new()
	tecla.physical_keycode = KEY_E
	tecla.pressed = true
	root.push_input(tecla)
	assert(nivel.vista.abierta())
	tecla.physical_keycode = KEY_ESCAPE
	root.push_input(tecla)
	assert(not nivel.vista.abierta())
	_clic(nivel, "control", Tramo.RADIO)
	assert(nivel.vista.abierta())
	await _captura("dia4-control")
	nivel._elegir("ambas")
	_camino(nivel, [Vector2(402, 318), Vector2(402, 360), Tramo.ESCLUSA])
	nivel._interactuar()
	var inicio_barranco := nivel.mapa.punto
	nivel.mapa.tiempo = 20.0
	assert(nivel.mapa.empuje_viento() == 0.0)
	nivel.mapa.avanzar(Vector2.ZERO, 0.05)
	assert(nivel.mapa.punto == inicio_barranco, "Con cielo sereno no hay deriva")
	nivel.mapa.avanzar(Vector2.RIGHT, 0.05)
	assert(nivel.mapa.punto.x > inicio_barranco.x, "La ráfaga invisible no debe frenar el avance")
	nivel.mapa.cielo_sereno = false
	assert(nivel.mapa.empuje_viento() > 0.0, "Las ráfagas siguen activas durante la tormenta")
	nivel.mapa.cielo_sereno = true
	nivel.mapa.velocidad = Vector2.ZERO
	_camino(nivel, [PuestoUmbra.SONDEOS[0]])
	tecla.physical_keycode = KEY_E
	root.push_input(tecla)
	assert(nivel.etapa == "sondeos" and nivel._lecturas.size() == 1)
	_camino(nivel, [PuestoUmbra.MUESTRA])
	nivel._interactuar()
	assert(nivel._lecturas.size() == 2)
	await _captura("dia4-barranco")
	nivel.set_process(true)
	nivel._interactuar()
	await create_timer(2.35).timeout
	assert(nivel.mapa.carga == "hielo")
	_camino(nivel, [Tramo.RETORNO_HIELO])
	nivel._interactuar()
	_camino(nivel, [Vector2(402, 360), Vector2(402, 245), Vector2(191, 245),
		Vector2(191, 42), Vector2(25, 42), PuestoUmbra.EQUIPO_AGUA[0]])
	_pulsar(nivel.mapa.ancla_carga(), true)
	_pulsar(Vector2(34, 645), false)
	assert(nivel.etapa == "purificar" and nivel.mapa.carga == "hielo")
	_arrastrar(nivel, "filtro", PuestoUmbra.EQUIPO_AGUA[0])
	await create_timer(1.25).timeout
	assert(nivel.etapa == "recoger_blindaje")
	_camino(nivel, [Vector2(25, 42), Vector2(191, 42), Vector2(191, 245), Tramo.TALLER])
	nivel._interactuar()
	assert(nivel.mapa.carga == "protecciones")
	_camino(nivel, [Vector2(402, 245), Vector2(402, 360), Tramo.ACCESO_NUCLEO])
	nivel._interactuar()
	_camino(nivel, [Tramo.AIRE_PROTEGIDO])
	nivel._interactuar()
	assert(nivel.mapa.paneles == 0 and nivel.etapa == "blindaje")
	_arrastrar(nivel, "ventilacion", Tramo.AIRE_PROTEGIDO)
	assert(nivel.mapa.paneles == 0)
	for id: String in Tramo.SOPORTES:
		var soporte: Vector2 = Tramo.SOPORTES[id]
		_camino(nivel, [soporte])
		_arrastrar(nivel, id, soporte)
	assert(nivel.mapa.paneles == 3 and nivel.etapa == "probar_aire")
	await _captura("dia4-blindaje")
	_camino(nivel, [Tramo.AIRE_PROTEGIDO])
	nivel._interactuar()
	var estado := nivel.recursos.estado()
	assert(estado.reservas == {"energia": 5, "agua": 6, "oxigeno": 7, "alimento": 7})
	assert(nivel.historial.refugio_reforzado and nivel.historial.plan_dia4 == "ambas")
	assert(not Reglas.completar_plan(nivel.recursos, "hielo"))
	_camino(nivel, [Vector2(402, 360), Vector2(402, 245), PuestoUmbra.TERMINALES.energia])
	nivel._avanzar_carga(10)
	_camino(nivel, [Vector2(191, 245), Vector2(191, 42), Vector2(103, 42), Tramo.AIRE])
	nivel._interactuar()
	assert(nivel.recursos.estado().aire_asegurado)
	_camino(nivel, [Vector2(103, 42), Vector2(191, 42), Vector2(191, 245), Vector2(538, 245),
		Vector2(538, 133), Vector2(681, 133), Vector2(681, 89), Tramo.DORMITORIO])
	nivel._interactuar()
	assert(not nivel.vista.abierta())
	assert(nivel._confirmacion == "descanso")
	nivel._interactuar()
	await process_frame
	assert(banco._recursos.estado().sol == 5)
	assert(banco._recursos.estado().reservas.agua == 5)
	# Tres estados de entrada y reanudación sin volver a cobrar la tormenta.
	var resultados := ["mision_cumplida", "evacuacion", "derrota"]
	for i in range(resultados.size()):
		banco.iniciar(2 + i)
		nivel = banco._pantalla
		_camino(nivel, [Tramo.RADIO])
		_clic(nivel, "control", Tramo.RADIO)
		assert(nivel.vista.abierta())
		for control in nivel.vista._ventana.get_children():
			if control is Button and control.text == "Transmitir aviso":
				control.pressed.emit()
				break
		assert(not nivel.vista.abierta() and nivel.etapa == "ir_refugio")
		_camino(nivel, [Vector2(402, 318), Vector2(402, 360), Tramo.ACCESO_NUCLEO])
		assert(nivel.mapa.zona == "base")
		nivel._interactuar()
		assert(nivel.etapa == "cruzar_umbral")
		nivel._interactuar()
		assert(nivel.etapa == "cruzar_umbral")
		await create_timer(1.24).timeout
		assert(nivel.mapa.zona == "refugio" and nivel.etapa == "sellar")
		assert(nivel.mapa.compuerta == 0.0 and nivel.mapa.entrada_nucleo == 1.0)
		_camino(nivel, [Tramo.PUERTA_PROTEGIDA])
		var historia_impacto := {}
		nivel.impacto_registrado.connect(func(historia: Dictionary): historia_impacto.merge(historia))
		if i == 0:
			await _captura("dia5-cierre")
		_clic(nivel, "sello", Tramo.PUERTA_PROTEGIDA)
		assert(nivel.etapa == "impacto")
		await create_timer(1.95).timeout
		assert(nivel.mapa.fase_radiacion == "Pico de radiación")
		if i == 0:
			await _captura("dia5-radlab")
		await create_timer(1.8).timeout
		var registro: Dictionary = historia_impacto.impacto_solar
		assert(registro.final == resultados[i])
		assert(Reglas.impacto(banco._recursos, historia_impacto) == registro)
		assert(banco._recursos.estado().reservas == registro.despues)
		if i == 2:
			await create_timer(0.70).timeout
			assert(banco._pantalla.get_script() == preload("res://scripts/derrota_umbra.gd"))
			assert(banco._pantalla.sol == 5)
			await create_timer(0.6).timeout
			await _captura("dia5-game-over")
		else:
			_camino(nivel, [Tramo.RADIO_PROTEGIDA])
			nivel._interactuar()
			assert(not nivel.vista.abierta() and nivel.etapa == "salida5")
			await _captura("dia5-" + resultados[i])
			nivel._interactuar()
			assert(nivel.etapa == "volver_capsula")
			_camino(nivel, [Tramo.UMBRAL_NUCLEO])
			nivel._interactuar()
			await create_timer(1.24).timeout
			assert(banco._pantalla.mision_cumplida == (i == 0))
			assert(banco._pantalla.titulo.text.is_empty(), "El viaje de regreso no lleva un rótulo de tiempo")
			await _probar_cinematica(banco._pantalla, i == 0)
	print("TRAMO_FINAL_OK")
	quit()


func _probar_cinematica(cierre: Control, cumplida: bool) -> void:
	cierre.set_process(false)
	var espacio := InputEventKey.new()
	espacio.physical_keycode = KEY_SPACE
	espacio.pressed = true
	root.push_input(espacio)
	assert(cierre.fase == "hangar")
	root.push_input(espacio)
	var primer_texto: String = cierre.voz.frase.text
	assert(cierre.voz.visible and not primer_texto.is_empty())
	espacio.echo = true
	root.push_input(espacio)
	assert(cierre.voz.frase.text == primer_texto)
	espacio.echo = false
	root.push_input(espacio)
	assert(cierre.fase == "hangar" and cierre.voz.frase.text != primer_texto)
	root.push_input(espacio)
	assert(cierre.fase == ("ceremonia" if cumplida else "noticia"))
	assert(cierre.accion.visible and cierre.accion.text.begins_with("Omitir"))
	root.push_input(espacio)
	assert(cierre.voz.visible)
	if not cumplida:
		root.push_input(espacio)
		assert(cierre.voz.frase.text.contains("incompleta"))
		await _captura("final-noticiero")
	cierre.accion.pressed.emit()
	assert(cierre.fase == ("victoria" if cumplida else "noticia"))
	if not cumplida:
		assert(cierre.accion.text == "Repetir final" and cierre.voz.frase.text.contains("a salvo"))

func _probar_planes_y_proteccion() -> void:
	for id in ["hielo", "refuerzo"]:
		var recursos := _partida(4)
		assert(Reglas.completar_plan(recursos, id))
		var esperadas := {"energia": 6 if id == "hielo" else 8, "agua": 6 if id == "hielo" else 4,
			"oxigeno": 8, "alimento": 7 if id == "hielo" else 8}
		assert(recursos.estado().reservas == esperadas)
		assert(not Reglas.completar_plan(recursos, "ambas"))
	for refuerzo in [false, true]:
		for danio in [false, true]:
			var recursos := _partida(5)
			var historia := {"refugio_reforzado": refuerzo, "sistemas_danados": danio}
			var registro := Reglas.impacto(recursos, historia)
			assert(registro.despues.energia == 11 - (4 if refuerzo else 7) - int(danio))
			assert(registro.despues.oxigeno == 8 - (1 if refuerzo else 3) - int(danio))
			assert(registro.despues.agua == (4 if refuerzo else 3))
			var recuperada := Reglas.Recursos.new()
			assert(recuperada.restaurar_estado(recursos.guardar_estado()))
			historia.impacto_solar = registro
			assert(Reglas.impacto(recuperada, historia) == registro)
			assert(recuperada.estado().reservas == registro.despues)

func _partida(sol: int) -> Reglas.Recursos:
	var recursos := Reglas.Recursos.new()
	var guardado := recursos.guardar_estado()
	guardado.sol = sol
	guardado.reservas = {"energia": 11, "agua": 4, "oxigeno": 8, "alimento": 8}
	assert(recursos.restaurar_estado(guardado))
	assert(recursos.iniciar_sol("medio"))
	return recursos
