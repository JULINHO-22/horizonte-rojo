extends SceneTree

const Recursos := preload("res://scripts/mecanicas/recursos_mision.gd")
const Dia3 := preload("res://scenes/dias/dia_3/dia_3.tscn")


func _initialize() -> void:
	call_deferred("_probar")


func _estado_dia_3():
	var recursos := Recursos.new()
	var datos: Dictionary = recursos.guardar_estado()
	datos.sol = 3
	datos.polvo = "medio"
	datos.reservas = {"energia": 9, "agua": 4, "oxigeno": 6, "alimento": 6}
	datos.bandejas = {"rabano": 0.0}
	datos.decisiones = []
	datos.relojes = [0.0, 0.0, 0.0]
	assert(recursos.restaurar_estado(datos))
	assert(recursos.iniciar_sol("medio"))
	return recursos


func _probar() -> void:
	var protegidos = _estado_dia_3()
	var escena_protegida = Dia3.instantiate()
	escena_protegida.configurar(protegidos, false)
	root.add_child(escena_protegida)
	await process_frame
	assert(escena_protegida.fase == "ir_plantas")
	escena_protegida._comenzar_recorrido()
	escena_protegida.puesto.punto = PuestoUmbra.TERMINALES.cultivos
	escena_protegida._accion()
	assert(escena_protegida.modal != null and escena_protegida.invernadero_revisado)
	escena_protegida._sembrar("lechuga")
	escena_protegida._cerrar_panel_plantas()
	assert(escena_protegida.fase == "ir_oxigeno")
	escena_protegida.puesto.punto = PuestoUmbra.ESTACION_OXIGENO
	escena_protegida._accion()
	assert(escena_protegida.fase == "decision")
	escena_protegida._elegir_oxigeno()
	var estado_protegido: Dictionary = protegidos.estado()
	assert(escena_protegida.decision == "oxigeno")
	assert(estado_protegido.aire_asegurado)
	assert(estado_protegido.bandejas.is_empty())
	assert(estado_protegido.reservas == {"energia": 2, "agua": 2, "oxigeno": 8, "alimento": 4})
	var relevos: Array[Dictionary] = []
	escena_protegida.descanso_solicitado.connect(func(resultado: Dictionary): relevos.append(resultado))
	escena_protegida.puesto.punto = PuestoUmbra.TERMINALES.dormitorio
	escena_protegida._accion()
	assert(relevos.size() == 1 and relevos[0].decision == "oxigeno")
	assert(protegidos.estado().sol == 3, "La campaña conserva la responsabilidad de dormir.")
	escena_protegida.queue_free()
	await process_frame

	var danados = _estado_dia_3()
	var escena_danada = Dia3.instantiate()
	escena_danada.configurar(danados, true)
	root.add_child(escena_danada)
	await process_frame
	assert(danados.estado().reservas.agua == 3)
	assert(danados.estado().reservas.oxigeno == 5)
	escena_danada._comenzar_recorrido()
	escena_danada._abrir_panel_plantas()
	escena_danada._cerrar_panel_plantas()
	escena_danada._activar_fallo()
	escena_danada._elegir_invernadero()
	var estado_danado: Dictionary = danados.estado()
	assert(escena_danada.decision == "invernadero")
	assert(estado_danado.aire_asegurado)
	assert(estado_danado.bandejas.has("rabano"))
	assert(estado_danado.reservas == {"energia": 5, "agua": 2, "oxigeno": 3, "alimento": 8})
	escena_danada.queue_free()
	await process_frame

	var prueba_local = Dia3.instantiate()
	root.add_child(prueba_local)
	await process_frame
	assert(prueba_local.modo_prueba and prueba_local.recursos.estado().sol == 3)
	assert(prueba_local.recursos.estado().bandejas.rabano == 0.0)
	prueba_local._comenzar_recorrido()
	prueba_local.puesto.punto = PuestoUmbra.TERMINALES.cultivos
	prueba_local._accion()
	prueba_local._cerrar_panel_plantas()
	prueba_local.puesto.punto = PuestoUmbra.ESTACION_OXIGENO
	prueba_local._accion()
	prueba_local._elegir_invernadero()
	prueba_local.puesto.punto = PuestoUmbra.TERMINALES.dormitorio
	prueba_local._accion()
	assert(prueba_local.recursos.estado().sol == 4)
	assert(prueba_local.fase == "terminado")
	prueba_local.queue_free()
	await process_frame

	print("DIA3_OK: rutina, consecuencias, decisiones e indicadores pixel art verificados.")
	quit()
