extends SceneTree

const Escena := preload("res://scenes/dias/dia_2/dia_2.tscn")
const Dia := preload("res://scenes/dias/dia_2/dia_2.gd")
const Recursos := preload("res://scripts/mecanicas/recursos_mision.gd")
const Paso := Dia.Paso
const DT := 1.0 / 60.0

class ErroresDeScript extends Logger:
	var mutex := Mutex.new()
	var detectados: Array[String] = []

	func _log_error(funcion: String, archivo: String, linea: int, codigo: String,
			motivo: String, _notificar_editor: bool, tipo: int, _trazas: Array[ScriptBacktrace]) -> void:
		if tipo == Logger.ERROR_TYPE_SCRIPT:
			mutex.lock()
			detectados.append("%s:%d %s · %s %s" % [archivo, linea, funcion, codigo, motivo])
			mutex.unlock()

var registro := ErroresDeScript.new()


func _initialize() -> void:
	OS.add_logger(registro)
	call_deferred("_probar")


func _probar() -> void:
	var dia := _instanciar()
	var resultados: Array[Dictionary] = []
	dia.finalizado.connect(resultados.append)
	await _captura(dia, "inicio")
	_clic(dia.interfaz.confirmar)
	assert(dia.juego_activo(), "El botón de inicio debe abrir el recorrido.")
	assert(dia.interfaz.aviso_pluto.visible)
	_tecla_virtual(dia, KEY_ESCAPE)
	assert(not dia.juego_activo())
	_tecla_virtual(dia, KEY_E)
	assert(dia.juego_activo())
	_tecla(dia, KEY_M)
	assert(not dia.juego_activo())
	_tecla(dia, KEY_M)
	assert(dia.juego_activo())
	await _caminar(dia)
	assert(dia.paso == Paso.DECISION)
	assert(dia.puesto.terminal_cercana() == "radio", "La decisión debe estar en la terminal de Control.")
	await _captura(dia, "control")
	_clic(dia.interfaz.accion)
	assert(is_instance_valid(dia.panel_control))
	dia._plan_reparar()
	assert(dia.paso == Paso.AIRE)
	await _caminar(dia)
	await _captura(dia, "laboratorio")
	_clic(dia.interfaz.accion)
	assert(dia.taller.visible and not dia.juego_activo())
	var oxigeno_lectura: int = dia.recursos.estado().reservas.oxigeno
	dia._process(20.0)
	assert(dia.recursos.estado().reservas.oxigeno == oxigeno_lectura)
	_tecla(dia, KEY_Q)
	assert(not dia.taller.visible and not dia.recursos.estado().aire_asegurado)
	_tecla(dia, KEY_E)
	await _resolver(dia)
	assert(dia.recursos.estado().aire_asegurado and dia.paso == Paso.SALIR)
	await _captura(dia, "camino-esclusa")
	await _caminar(dia)
	await _captura(dia, "salida")
	_clic(dia.interfaz.accion)
	await _caminar(dia)
	await _captura(dia, "exterior")
	var antes: Dictionary = dia.recursos.estado().reservas
	_tecla(dia, KEY_E)
	await _resolver(dia)
	var reparado := dia.recursos.estado()
	assert(reparado.reservas.energia == antes.energia - 4)
	assert(reparado.reservas.alimento == antes.alimento - 1)
	assert(Dia.REPARAR in reparado.decisiones and dia.paso == Paso.ENTRAR)
	await _captura(dia, "regreso")
	await _caminar(dia)
	_clic(dia.interfaz.accion)
	await _caminar(dia)
	await _captura(dia, "dormitorio")
	_clic(dia.interfaz.accion)
	assert(resultados.size() == 1 and resultados[0].completado)
	assert(resultados[0].decision == "reparar" and resultados[0].paneles_protegidos)
	assert(resultados[0].perdidas_dia_3.is_empty() and not resultados[0].sistemas_danados)
	assert(dia.recursos.estado().sol == 2 and dia.recursos.estado().en_curso)
	assert(dia.recursos.estado().reservas.energia == 2)
	await _captura(dia, "cierre")
	_tecla(dia, KEY_E)
	assert(dia.paso == Paso.DECISION and not dia.juego_activo())
	dia.free()

	var partida := _partida(6, 3)
	dia = _instanciar(partida)
	resultados.clear()
	dia.finalizado.connect(resultados.append)
	_tecla(dia, KEY_E)
	dia._process(45.0)
	assert(partida.estado().reservas.oxigeno == 8, "Solo el controlador puede avanzar su reloj.")
	partida.avanzar(16.0)
	assert(partida.estado().reservas.oxigeno == 6 and partida.estado().reservas.energia == 6)
	await _caminar(dia)
	var reservas: Dictionary = partida.estado().reservas
	_clic(dia.interfaz.alternativa)
	await _captura(dia, "resguardo")
	assert(partida.estado().reservas == reservas)
	await _accion(dia, Paso.AIRE)
	assert(partida.estado().aire_asegurado and partida.estado().reservas.energia == 0)
	await _captura(dia, "sin-energia")
	await _accion(dia, Paso.DESCANSO)
	assert(resultados.size() == 1 and resultados[0].completado)
	assert(resultados[0].decision == "resguardarse" and resultados[0].sistemas_danados)
	assert(resultados[0].perdidas_dia_3.recursos == {"agua": 1, "oxigeno": 1})
	assert(partida.estado().reservas.agua == 2 and partida.estado().reservas.oxigeno == 8)
	assert(partida.dormir() and partida.iniciar_sol("medio"))
	var perdidas: Dictionary = resultados[0].perdidas_dia_3
	assert(partida.aplicar_perdidas(perdidas.id, perdidas.recursos))
	assert(not partida.aplicar_perdidas(perdidas.id, perdidas.recursos))
	assert(partida.estado().reservas.agua == 1 and partida.estado().reservas.oxigeno == 7)
	dia.free()

	dia = _instanciar(_partida(12, 3))
	_tecla(dia, KEY_E)
	# Ir al Centro de agua antes de tomar la decisión de Control.
	_caminar_a(dia, Dia.CRUCE_SUR)
	_caminar_a(dia, Dia.CRUCE_OESTE)
	_caminar_a(dia, Dia.GIRO_AGUA)
	_caminar_a(dia, Dia.ENTRADA_AGUA)
	_caminar_a(dia, Dia.AIRE)
	_tecla(dia, KEY_E)
	await _resolver(dia)
	assert(dia.recursos.estado().aire_asegurado and dia.paso == Paso.DECISION)
	await _accion(dia, Paso.DECISION)
	await _accion(dia, Paso.SALIR)
	await _accion(dia, Paso.REPARAR)
	await _accion(dia, Paso.ENTRAR)
	assert(dia.paso == Paso.DESCANSO)
	await _accion(dia, Paso.DESCANSO)
	assert(dia.concluido)
	dia.free()

	dia = _instanciar(_partida(3, 0))
	_tecla(dia, KEY_E)
	await _accion(dia, Paso.DECISION)
	await _caminar(dia)
	_tecla(dia, KEY_Q) # Se permite intentar salir antes del aire.
	await _accion(dia, Paso.SALIR)
	await _accion(dia, Paso.REPARAR)
	assert(dia.paso == Paso.REPARAR and dia.recursos.estado().reservas.energia == 3)
	_caminar_a(dia, PuestoUmbra.ESCLUSA, 25.0)
	_tecla(dia, KEY_Q)
	_tecla(dia, KEY_Q)
	await _accion(dia, Paso.AIRE)
	assert(dia.paso == Paso.AIRE and not dia.recursos.estado().aire_asegurado)
	_tecla(dia, KEY_Q)
	resultados.clear()
	dia.finalizado.connect(resultados.append)
	await _accion(dia, Paso.DESCANSO)
	assert(resultados.size() == 1 and resultados[0].derrota == "aire_sin_activar")
	dia.free()

	# Aire después de reparar: debe llevar a la cama, sin repetir la salida.
	dia = _instanciar(_partida(12, 3))
	_tecla(dia, KEY_E)
	await _accion(dia, Paso.DECISION)
	await _caminar(dia)
	_tecla(dia, KEY_Q)
	await _accion(dia, Paso.SALIR)
	await _accion(dia, Paso.REPARAR)
	await _accion(dia, Paso.ENTRAR)
	await _accion(dia, Paso.AIRE)
	assert(dia.paso == Paso.DESCANSO)
	await _accion(dia, Paso.DESCANSO)
	assert(dia.concluido)
	dia.free()

	# Hielo del día anterior: se purifica en el filtro azul de main.
	partida = _partida(8, 0)
	assert(partida.recoger_hielo())
	dia = _instanciar(partida)
	_tecla(dia, KEY_E)
	await _caminar(dia)
	_tecla(dia, KEY_Q)
	await _caminar(dia)
	_tecla(dia, KEY_E)
	assert(not dia.taller.visible and not partida.estado().aire_asegurado)
	_tecla(dia, KEY_Q)
	_caminar_a(dia, Dia.AGUA)
	dia._process(0.0)
	assert(dia.interfaz.alternativa.visible)
	_clic(dia.interfaz.alternativa)
	assert(partida.estado().reservas.agua == 3 and partida.estado().hielo == 0)
	await _accion(dia, Paso.AIRE)
	assert(partida.estado().aire_asegurado and partida.estado().reservas.energia == 0)
	dia.free()

	# Hambre recuperable: plantar, esperar, comer y descansar.
	partida = _partida(9, 3)
	assert(partida.activar_oxigeno())
	assert(partida.aplicar_decision(Dia.RESGUARDARSE, {}))
	assert(partida.aplicar_perdidas("prueba_hambre", {"alimento": 10}))
	dia = _instanciar(partida)
	_tecla(dia, KEY_E)
	await _caminar(dia)
	_tecla(dia, KEY_Q)
	await _accion(dia, Paso.PLANTAS)
	assert(partida.estado().bandejas.has("lechuga"))
	partida.avanzar(15.0)
	dia._process(0.0)
	await _captura(dia, "cosecha-lista")
	_clic(dia.interfaz.alternativa)
	assert(partida.estado().reservas.alimento == 2)
	_tecla(dia, KEY_Q)
	await _accion(dia, Paso.DESCANSO)
	assert(dia.concluido)
	dia.free()

	dia = _instanciar()
	_tecla(dia, KEY_E)
	dia._process(64.0)
	assert(dia.concluido and dia.recursos.estado().derrota == "oxigeno_agotado")
	assert(dia.recursos.estado().reservas.energia == Recursos.LIMITES.energia)
	dia.free()
	OS.remove_logger(registro)
	if not registro.detectados.is_empty():
		for mensaje: String in registro.detectados:
			printerr(mensaje)
		quit(1)
		return
	print("DIA_2_OK: rutas, retos con clic/teclado, pausas, errores recuperables, aire antes/después, hielo, hambre, relevo y derrota.")
	quit()


func _partida(energia: int, agua: int) -> Recursos:
	var recursos := Recursos.new()
	var datos := recursos.guardar_estado()
	datos.sol = 2
	datos.reservas.energia = energia
	datos.reservas.agua = agua
	assert(recursos.restaurar_estado(datos))
	assert(recursos.iniciar_sol("tormenta"))
	return recursos


func _instanciar(partida: Recursos = null) -> Dia:
	var dia := Escena.instantiate() as Dia
	if partida != null:
		dia.configurar(partida)
	root.add_child(dia)
	dia.set_process(false)
	return dia


func _tecla(dia: Dia, codigo: Key) -> void:
	var evento := InputEventKey.new()
	evento.physical_keycode = codigo
	evento.pressed = true
	root.push_input(evento, true)
	var soltar := evento.duplicate() as InputEventKey
	soltar.pressed = false
	root.push_input(soltar, true)
	dia._process(0.0)


func _clic(boton: Button) -> void:
	assert(boton.is_visible_in_tree() and not boton.disabled, "El botón debe estar disponible.")
	var evento := InputEventMouseButton.new()
	evento.button_index = MOUSE_BUTTON_LEFT
	evento.position = boton.get_global_rect().get_center()
	evento.global_position = evento.position
	evento.pressed = true
	root.push_input(evento, true)
	var soltar := evento.duplicate() as InputEventMouseButton
	soltar.pressed = false
	root.push_input(soltar, true)


func _accion(dia: Dia, etapa: int) -> void:
	assert(dia.paso == etapa)
	await _caminar(dia)
	_tecla(dia, KEY_E)
	if etapa == Paso.DECISION:
		assert(is_instance_valid(dia.panel_control))
		dia._plan_reparar()
	if dia.taller.visible:
		await _resolver(dia)


func _caminar(dia: Dia) -> void:
	var sitio: Vector2 = Dia.OBJETIVOS[dia.paso][0]
	var teclas := [&"ui_right", &"ui_left", &"ui_down", &"ui_up"]
	for i in 1000:
		var objetivo: Vector2 = sitio if dia.ruta.is_empty() else dia.ruta.front()
		var diferencia := objetivo - dia.puesto.punto
		var pulsadas := [diferencia.x > 3, diferencia.x < -3, diferencia.y > 3, diferencia.y < -3]
		for indice in teclas.size():
			if pulsadas[indice]:
				Input.action_press(teclas[indice])
		dia._process(DT)
		for tecla: StringName in teclas:
			Input.action_release(tecla)
		if i % 12 == 0 and DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
		if dia.ruta.is_empty() and dia._cerca(sitio):
			return
	assert(false, "Ruta bloqueada. Paso %d, posición %s, objetivo %s" % [dia.paso, dia.puesto.punto, dia.ruta])


func _caminar_a(dia: Dia, objetivo: Vector2, margen := 7.0) -> void:
	var anterior: Array[Vector2] = dia.ruta
	dia.ruta = []
	for i in 1000:
		var diferencia := objetivo - dia.puesto.punto
		if diferencia.length() < margen:
			dia.ruta = anterior
			return
		var teclas := [&"ui_right", &"ui_left", &"ui_down", &"ui_up"]
		var pulsadas := [diferencia.x > 3, diferencia.x < -3, diferencia.y > 3, diferencia.y < -3]
		for indice in teclas.size():
			if pulsadas[indice]:
				Input.action_press(teclas[indice])
		dia._process(DT)
		for tecla: StringName in teclas:
			Input.action_release(tecla)
	assert(false, "No se pudo llegar a %s desde %s" % [objetivo, dia.puesto.punto])


func _captura(dia: Dia, nombre: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	dia.puesto.queue_redraw()
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://build/qa/dia-2-%s.png" % nombre) == OK)

func _resolver(dia: Dia) -> void:
	assert(dia.taller.visible)
	var antes: Dictionary = dia.recursos.estado().reservas
	await _captura(dia, "taller-" + dia.taller.tipo)
	_clic(dia.taller.principal)
	assert(dia.juego_activo())
	var giros := dia.taller.reglas.giros.duplicate()
	_tecla(dia, KEY_ESCAPE)
	assert(not dia.juego_activo())
	var en_pausa: Dictionary = dia.recursos.estado().reservas
	dia._process(30.0)
	assert(dia.recursos.estado().reservas == en_pausa)
	_tecla(dia, KEY_ESCAPE)
	assert(dia.juego_activo() and dia.taller.reglas.giros == giros)
	var posicion := dia.puesto.punto
	Input.action_press("ui_right")
	dia._process(0.02)
	Input.action_release("ui_right")
	assert(dia.puesto.punto == posicion, "Trabajar no debe mover a Nora.")
	if dia.taller.tipo == "aire":
		_tecla_virtual(dia, KEY_E) # Un circuito incompleto no cobra.
		assert(not dia.recursos.estado().aire_asegurado)
		assert(dia.recursos.estado().reservas.energia == antes.energia)
		var metas := [2, 0, 2, 0]
		for i in 4:
			for intento in 4:
				if dia.taller.reglas.giros[i] == metas[i]: break
				if i % 2 == 0:
					_clic(dia.taller.piezas[i])
				else:
					_tecla(dia, [KEY_1, KEY_2, KEY_3, KEY_4][i])
		assert(dia.taller.reglas.aire_conectado())
		await _captura(dia, "circuito-listo")
		_tecla(dia, KEY_E)
		assert(dia.recursos.estado().aire_asegurado)
		assert(dia.recursos.estado().reservas.energia == antes.energia - 6)
		assert(dia.recursos.estado().reservas.agua == antes.agua - 1)
	else:
		_tecla(dia, KEY_E) # Cierre desalineado.
		assert(dia.taller.reglas.cierre == 0)
		for i in 3:
			var meta: int = dia.taller.reglas.METAS[i]
			while dia.taller.reglas.ajuste != meta:
				_tecla(dia, KEY_A if dia.taller.reglas.ajuste > meta else KEY_D)
			if i == 0:
				dia.taller.reglas.tiempo = 3.0
				_tecla(dia, KEY_E)
				assert(dia.taller.reglas.cierre == 0, "La ráfaga no permite fijar.")
				await _captura(dia, "rafaga")
				dia.taller.avanzar(1.1)
				assert(dia.taller.reglas.calma(), "La ráfaga debe dar paso a una ventana de calma.")
			await _captura(dia, "cierre-%d" % i)
			_clic(dia.taller.principal)
		assert(dia.paso == Paso.ENTRAR)
	assert(not dia.taller.visible)

func _tecla_virtual(dia: Dia, codigo: Key) -> void:
	# SendInput en Windows puede informar un scancode distinto del símbolo lógico.
	var evento := InputEventKey.new()
	evento.keycode = codigo
	evento.physical_keycode = KEY_PAUSE
	evento.pressed = true
	root.push_input(evento, true)
	evento = evento.duplicate() as InputEventKey
	evento.pressed = false
	root.push_input(evento, true)
	dia._process(0.0)
