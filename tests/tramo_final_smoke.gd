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

func _probar() -> void:
	_probar_planes_y_proteccion()
	var banco := Banco.instantiate()
	root.add_child(banco)
	await _captura("dias-45-prueba")
	banco.iniciar(1)
	var nivel: Tramo = banco._pantalla
	nivel.set_process(false)
	assert(not Reglas.impedimento("ambas", nivel.recursos.estado()).is_empty())
	assert(not Reglas.completar_plan(nivel.recursos, "ambas"))
	banco.iniciar(0)
	nivel = banco._pantalla
	nivel.set_process(false)
	_camino(nivel, [Tramo.RADIO])
	nivel._interactuar()
	assert(nivel.vista.abierta())
	await _captura("dia4-control")
	nivel._elegir("ambas")
	_camino(nivel, [Vector2(402, 318), Vector2(402, 360), Tramo.ESCLUSA])
	nivel._interactuar()
	_camino(nivel, [PuestoUmbra.SONDEOS[0]])
	nivel._interactuar()
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
	nivel._interactuar()
	await create_timer(1.25).timeout
	assert(nivel.etapa == "recoger_blindaje")
	_camino(nivel, [Vector2(25, 42), Vector2(191, 42), Vector2(191, 245), Tramo.TALLER])
	nivel._interactuar()
	assert(nivel.mapa.carga == "protecciones")
	_camino(nivel, [Vector2(402, 245), Vector2(402, 360), Tramo.ESCLUSA])
	nivel._interactuar()
	_camino(nivel, [Tramo.AIRE_PROTEGIDO])
	nivel._interactuar()
	assert(nivel.mapa.paneles == 0 and nivel.etapa == "blindaje")
	_camino(nivel, [Tramo.PUERTA_PROTEGIDA])
	nivel._interactuar()
	await create_timer(1.1).timeout
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
	assert(nivel.vista.abierta())
	nivel._dormir()
	await process_frame
	assert(banco._recursos.estado().sol == 5)
	assert(banco._recursos.estado().reservas.agua == 5)
	# Tres estados de entrada y reanudación sin volver a cobrar la tormenta.
	var resultados := ["mision_cumplida", "evacuacion", "derrota"]
	for i in range(resultados.size()):
		banco.iniciar(2 + i)
		nivel = banco._pantalla
		_camino(nivel, [Tramo.RADIO])
		nivel._interactuar()
		_camino(nivel, [Vector2(402, 318), Vector2(402, 360), Tramo.ESCLUSA])
		nivel._interactuar()
		_camino(nivel, [Tramo.PUERTA_PROTEGIDA])
		nivel._interactuar()
		await create_timer(3.22).timeout
		var registro: Dictionary = nivel.historial.impacto_solar
		assert(registro.final == resultados[i])
		assert(Reglas.impacto(nivel.recursos, nivel.historial) == registro)
		assert(nivel.recursos.estado().reservas == registro.despues)
		if i == 2:
			await create_timer(0.70).timeout
			assert(banco._pantalla is ColorRect)
			await _captura("dia5-game-over")
		else:
			_camino(nivel, [Tramo.RADIO_PROTEGIDA])
			nivel._interactuar()
			assert(nivel.vista.abierta())
			await _captura("dia5-" + resultados[i])
			nivel._emitir_final(registro.final)
			await process_frame
			assert(banco._pantalla.mision_cumplida == (i == 0))
	print("TRAMO_FINAL_OK")
	quit()


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
