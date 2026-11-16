extends Control
## Presentación del guion y entrada a las actividades aprobadas.
const Campana := preload("res://scripts/campana_narrativa.gd")
const Viaje := preload("res://scripts/viaje_espacial.gd")
const DialogoEscena := preload("res://scripts/dialogo_escena.gd")
const AccionEscena := preload("res://scripts/accion_escena.gd")
const Invernadero := preload("res://scripts/invernadero_umbra.gd")
const Laboratorio := preload("res://scripts/laboratorio_umbra.gd")
const AccionSostenida := preload("res://scripts/mecanicas/accion_sostenida.gd")
const DerrotaUmbra := preload("res://scripts/derrota_umbra.gd")
const SabiasQue := preload("res://scripts/sabias_que.gd")
const VISTAS_FINALES := {
	"--final-recursos": "res://scenes/pruebas/banco_recursos.tscn",
	"--final-incompleta": "res://scenes/final_incompleta.tscn",
	"--final-cumplida": "res://scenes/final_cumplida.tscn",
}
const AREA := Rect2(0, 0, 1280, 720)
const PAPEL := Color("#fff1db")
const CIAN := Color("#7df0e0")
const DURACION_IDA := 5.4
const DURACION_ATERRIZAJE := 2.6
const DURACION_REGRESO := 9.0
const FICHAS := {
	"energia": "base.ficha.energia",
	"agua": "base.ficha.agua",
	"cultivos": "base.ficha.cultivos",
	"cierre": "base.ficha.cierre",
	"taller": "base.ficha.taller",
}
const Recursos := preload("res://scripts/mecanicas/recursos_mision.gd")
const Tutorial := preload("res://scenes/dias/dia_1/tutorial_sol_uno.gd")
var recursos := Recursos.new()
const SOLES_JUGABLES := {
	2: "res://scenes/dias/dia_2/dia_2.tscn",
	3: "res://scenes/dias/dia_3/dia_3.tscn",
	4: "res://scenes/dias/tramo_final/nivel.tscn",
	5: "res://scenes/dias/tramo_final/nivel.tscn",
}
var nivel_activo: Control
var historial_soles := {}
var menu_soles: ColorRect
var prueba_soles := false
var integrar_soles := true
const PanelControl := preload("res://scripts/panel_control.gd")
const Tablet := preload("res://scripts/tablet_reservas.gd")
const DORMITORIO_NOCHE := preload("res://assets/dormitorio_noche.png")
const AMANECER_MARTE := preload("res://assets/NarrativaInicio/MartePixelArt.png")
const MapaNucleo := preload("res://scenes/dias/tramo_final/mapa_tramo.gd")
var visita_nucleo: MapaNucleo
var marco_nucleo: Control
var panel_control: PanelControl
var interfaz_tablet: Tablet
var boton_tablet: LinkButton
var sol_anunciado := 0
var anuncio_sol: Control
var escena_descanso: TextureRect
var extraccion_hasta := 0.0
var taladro := AccionSostenida.new()
var estacion := ""
var huerto: Invernadero
var laboratorio: Laboratorio
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
var sabias_que: SabiasQue
var _ciencia_pendiente := ""

func _ready() -> void:
	get_window().min_size = Vector2i(800, 450)
	I18n.idioma()
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
	if is_instance_valid(menu_soles) or is_instance_valid(interfaz_tablet) or is_instance_valid(anuncio_sol):
		return
	if is_instance_valid(nivel_activo):
		if campana.sol == 2 and nivel_activo.juego_activo():
			if not _avanzar_recursos(delta):
				return
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
				if is_instance_valid(huerto):
					if not _avanzar_recursos(delta):
						return
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
			if taladro.activa():
				puesto.tiempo += delta
				if taladro.avanzar(delta):
					_completar_taladro()
				else:
					puesto.avance_muestra = taladro.progreso
					boton.text = I18n.tf("sol1.btn.perforando", [floori(taladro.progreso * 100)])
				puesto.queue_redraw()
				return
			if reloj < extraccion_hasta:
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
			voz.decir("Pluto", I18n.t("base.esclusa.abrir" if reloj > 2.22 else "base.esclusa.cerrar"))
			if reloj >= 3.5:
				posicion = puesto.punto
				_cambiar("base")
				_guardar()
		"noche":
			escena_descanso.modulate.a = smoothstep(0.15, 0.95, reloj)
			escena_descanso.scale = Vector2.ONE * lerpf(1.0, 1.045, smoothstep(0.0, 3.0, reloj))
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
		_soltar_taladro(&"")
		if is_instance_valid(interfaz_tablet):
			_cerrar_tablet()
		_cerrar_anuncio_sol()
		if is_instance_valid(menu_soles):
			_cerrar_menu_soles()
		else:
			_abrir_menu_soles()
	elif not is_instance_valid(menu_soles) and (((evento.keycode == KEY_Q or evento.physical_keycode == KEY_Q) and fase in ["base", "expedicion_sol_1"]) or
			(evento.physical_keycode == KEY_ESCAPE and is_instance_valid(interfaz_tablet))):
		get_viewport().set_input_as_handled()
		_alternar_tablet()
	elif is_instance_valid(anuncio_sol) and evento.physical_keycode in [KEY_E, KEY_ENTER, KEY_SPACE, KEY_ESCAPE]:
		_cerrar_anuncio_sol()
		get_viewport().set_input_as_handled()

func _unhandled_key_input(event: InputEvent) -> void:
	if is_instance_valid(nivel_activo) or is_instance_valid(menu_soles) or is_instance_valid(anuncio_sol) or is_instance_valid(interfaz_tablet) or is_instance_valid(huerto) or is_instance_valid(laboratorio):
		return
	if not event is InputEventKey or event.echo:
		return
	var codigo: Key = event.keycode if event.keycode != KEY_NONE else event.physical_keycode
	if not event.pressed:
		if codigo in [KEY_E, KEY_ENTER]:
			_soltar_taladro(&"teclado")
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
	if codigo in [KEY_E, KEY_ENTER]:
		if not _iniciar_taladro(&"teclado"):
			_accion()
	elif event.physical_keycode == KEY_M and fase == "base":
		plano = not plano
		puesto.plano = plano
		if plano and is_instance_valid(sabias_que):
			sabias_que.ocultar()
	elif event.physical_keycode == KEY_ESCAPE and fase in ["ida", "aterrizaje"]:
		_iniciar_caminata()

func _notification(que: int) -> void:
	if que == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_soltar_taladro(&"")

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
		voz.decir("Percy", I18n.t("sol1.percy.ya_hielo" if recogido else "sol1.percy.poca_agua"))
	pista.text = I18n.t("sol1.pista.refugio_izq" if recogido else "sol1.pista.depositos_der")
	if absf(posicion.x - PuestoUmbra.ESCLUSA.x) < 28:
		boton.text = I18n.t("sol1.btn.entrar_refugio")
	elif not recogido and not sitio.is_empty():
		var agua := mini(Recursos.LIMITES.agua - int(recursos.estado().reservas.agua), sitio.hielo * 3)
		if aviso_tiempo <= 0:
			voz.decir("Percy", I18n.t("sol1.percy.cerca" if sitio.hielo == 1 else "sol1.percy.profundo"))
		boton.text = I18n.tf("sol1.btn.deposito", [Tutorial.etiqueta_deposito(sitio), agua])
		pista.text = I18n.t("sol1.pista.taladro")
	else:
		return
	boton.show()
	boton.size = boton.get_minimum_size().max(Vector2(256, 45))
	_ubicar_accion()

func _accion_expedicion() -> void:
	if not taladro.activa() and reloj >= extraccion_hasta and absf(posicion.x - PuestoUmbra.ESCLUSA.x) < 28:
		posicion = PuestoUmbra.ENTRADA
		_cambiar("esclusa")

func _iniciar_taladro(fuente: StringName) -> bool:
	if fase != "expedicion_sol_1" or is_instance_valid(interfaz_tablet):
		return false
	var sitio := _deposito_cercano()
	var datos := recursos.estado()
	if sitio.is_empty() or not Tutorial.deposito(datos).is_empty():
		return false
	if datos.reservas.energia < sitio.energia or datos.reservas.alimento < sitio.alimento:
		voz.decir("Iris", I18n.t("sol1.iris.tablet"))
		aviso_tiempo = 6
		return true
	if not taladro.iniciar(fuente, 1.5):
		return true
	puesto.taladro_sol_uno_x = sitio.x
	puesto.avance_muestra = 0.0
	puesto.velocidad = Vector2.ZERO
	puesto.caminando = false
	voz.decir("Iris", I18n.t("sol1.iris.sostener_taladro"))
	aviso_tiempo = 3
	return true

func _soltar_taladro(fuente: StringName) -> void:
	if taladro.soltar(fuente):
		puesto.taladro_sol_uno_x = -1.0
		puesto.avance_muestra = 0.0
		puesto.queue_redraw()
		_actualizar_guia()

func _completar_taladro() -> void:
	var sitio := _deposito_cercano()
	if not recursos.recoger_hielo(sitio.hielo, sitio.energia, sitio.id, sitio.alimento):
		puesto.taladro_sol_uno_x = -1.0
		voz.decir("Iris", I18n.t("sol1.iris.revisar_antes"))
		aviso_tiempo = 6
		return
	puesto.depositos_sol_uno = []
	puesto.hielo_sol_uno = true
	puesto.avance_muestra = 1.0
	extraccion_hasta = reloj + 0.28
	boton.hide()
	voz.decir("Iris", I18n.tf("sol1.iris.sacamos", [sitio.hielo]))
	aviso_tiempo = 5
	_mostrar_ciencia("hielo")
	_guardar()

func _actualizar_guia() -> void:
	boton.visible = false
	_actualizar_guia_cuerpo()
	if is_instance_valid(sabias_que):
		var zonas: Array[Rect2] = [Rect2(24, 24, 1230, 52)]
		if is_instance_valid(boton) and boton.visible:
			zonas.append(Rect2(boton.position, boton.size))
		if is_instance_valid(voz) and voz.visible:
			zonas.append(Rect2(voz.position, voz.size))
		if is_instance_valid(pista) and not pista.text.is_empty():
			zonas.append(Rect2(pista.position, pista.size))
		sabias_que.evitar(zonas)

func _actualizar_guia_cuerpo() -> void:
	if fase == "expedicion_sol_1":
		_guia_expedicion()
	elif fase == "camino_base":
		pista.text = I18n.t("base.pista.camino_base")
		var rover := puesto.proyectar_suelo(Vector2(minf(puesto.punto.x + 85, PuestoUmbra.ESCLUSA.x - 44), PuestoUmbra.SUELO))
		voz.position = Vector2(clampf(rover.x + 20, 40, 860), clampf(rover.y - 250, 74, 350))
		voz.visible = reloj < 6.0
	elif fase == "camino_nave":
		pista.text = I18n.t("base.pista.camino_nave")
		if absf(posicion.x - 220) < 30:
			boton.visible = true
			boton.text = I18n.t("base.btn.subir_nave")
			_ubicar_accion()
		return
	elif fase == "base":
		pista.text = I18n.t("base.pista.base") if reloj < 6.0 else ""
		var cerca := _estacion_cercana()
		if _sol_uno():
			_guia_sol_uno(cerca)
			return
		if cerca == "dormitorio" and not campana.listo_para_regresar():
			boton.text = I18n.t("base.btn.descansar")
			boton.visible = true
		elif cerca == "radio" and not plano:
			boton.text = I18n.t("base.btn.abrir_control")
			boton.visible = true
		elif cerca == "nucleo":
			boton.text = I18n.t("base.btn.bajar_nucleo")
			boton.visible = true
		elif cerca == "cierre" and campana.listo_para_regresar():
			boton.text = I18n.t("base.btn.salir_nave")
			boton.visible = true
		elif cerca in ["agua", "oxigeno"] and not campana.listo_para_regresar():
			boton.text = I18n.t("base.btn.purificar_agua" if cerca == "agua" else "base.btn.preparar_oxigeno")
			boton.visible = true
		elif not cerca.is_empty() and FICHAS.has(cerca):
			boton.text = I18n.t("puesto.accion." + cerca, I18n.t("puesto.accion.entrada"))
			boton.visible = true
		if boton.visible:
			_ubicar_accion()
		if aviso_tiempo <= 0:
			voz.decir("Pluto", I18n.t("base.guia.aire_o_control" if not campana.listo_para_regresar() else "base.guia.ruta_control"))
			voz.visible = reloj < 6.0
		else:
			voz.visible = true

func _guia_sol_uno(cerca: String) -> void:
	var objetivo := Tutorial.objetivo(recursos.estado())
	if aviso_tiempo <= 0:
		voz.decir("Pluto", Tutorial.guia(objetivo))
	if cerca not in ["radio", "oxigeno", "cultivos", "cierre", "agua", "dormitorio", "nucleo"]:
		return
	boton.text = I18n.tf("ui.e_prefix", [I18n.t("sol1.act." + cerca)])
	boton.show()
	_ubicar_accion()

func _accion_sol_uno(cerca: String) -> void:
	match cerca:
		"radio":
			recursos.aplicar_decision(Tutorial.CONTROL, {})
			voz.decir("Pluto", I18n.t("sol1.pluto.control"))
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
	if integrar_soles and _sol_uno():
		var datos := recursos.estado()
		var pendientes := PackedStringArray()
		if not datos.aire_asegurado:
			pendientes.append(I18n.t("sol1.dormir.aire"))
		if datos.reservas.alimento == 0:
			pendientes.append(I18n.t("sol1.dormir.comida"))
		var faltantes := _faltantes_para_tormenta(datos.reservas)
		if faltantes.agua > 0:
			pendientes.append(I18n.t("sol1.dormir.agua"))
		if faltantes.energia > 0:
			pendientes.append(I18n.t("sol1.dormir.energia"))
		if not pendientes.is_empty():
			voz.decir("Pluto", I18n.tf("sol1.dormir.antes", [" ".join(pendientes)]))
			aviso_tiempo = 12
			return
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
				voz.decir("Pluto", I18n.t("base.pluto.pancam"))
				aviso_tiempo = 9
			elif FICHAS.has(cerca):
				voz.decir("Pluto", I18n.t(FICHAS[cerca]))
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

func _faltantes_para_tormenta(reservas: Dictionary) -> Dictionary:
	return {
		"energia": maxi(0, Recursos.COSTO_AIRE_ENERGIA - int(reservas.energia)),
		"agua": maxi(0, Recursos.COSTO_AIRE_AGUA - int(reservas.agua)),
	}

func _montar_sol() -> void:
	var escena := load(SOLES_JUGABLES[campana.sol]) as PackedScene
	nivel_activo = escena.instantiate()
	match campana.sol:
		2:
			var datos := recursos.estado()
			if datos.derrota.is_empty() and not datos.aire_asegurado:
				var faltantes := _faltantes_para_tormenta(datos.reservas)
				if faltantes.energia > 0 or faltantes.agua > 0:
					if recursos.aplicar_decision("sol_2_reserva_emergencia", faltantes):
						_guardar("base")
			nivel_activo.configurar(recursos)
			nivel_activo.finalizado.connect(_cerrar_sol_2, CONNECT_DEFERRED)
			nivel_activo.avance_guardado.connect(_guardar.bind("base"))
		3:
			nivel_activo.configurar(recursos, historial_soles.get("sistemas_danados", false))
			nivel_activo.descanso_solicitado.connect(_cerrar_sol_3, CONNECT_DEFERRED)
			nivel_activo.avance_guardado.connect(_guardar.bind("base"))
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
	if not datos.completado:
		historial_soles.motivo_derrota = datos.get("derrota", "")
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
	_ocultar_ciencia()
	capa.process_mode = Node.PROCESS_MODE_DISABLED
	menu_soles = ColorRect.new()
	menu_soles.color = Color("#1d2a36")
	menu_soles.size = AREA.size
	add_child(menu_soles)
	var anterior := capa
	capa = menu_soles
	_etiqueta(I18n.t("menu_soles.titulo"), Rect2(124, 88, 1032, 64), 43)
	_etiqueta(I18n.t("menu_soles.subtitulo"), Rect2(128, 166, 990, 64), 23)
	for i in range(5):
		_boton(I18n.tf("menu_soles.item", [i + 1, I18n.t("menu_soles.nom.%d" % (i + 1))]), Rect2(130, 245 + i * 61, 505, 45), _probar_sol.bind(i + 1))
	_boton(I18n.t("ui.continuar"), Rect2(800, 590, 292, 47), _cerrar_menu_soles)
	if prueba_soles:
		_boton(I18n.t("menu_soles.volver"), Rect2(800, 528, 292, 47), _volver_a_campana)
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
	sol_anunciado = 0
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
	SabiasQue.reiniciar_vistos()
	_ciencia_pendiente = ""
	_ocultar_ciencia()
	sol_anunciado = 0
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
	if fase == "noche":
		posicion = PuestoUmbra.TERMINALES.dormitorio
	estacion = ""
	taladro.soltar()
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
	huerto = null
	laboratorio = null
	interfaz_tablet = null
	boton_tablet = null
	anuncio_sol = null
	panel_control = null
	visita_nucleo = null
	marco_nucleo = null
	if is_instance_valid(capa):
		remove_child(capa)
		capa.queue_free()
	puesto = null
	viaje = null
	capa = Control.new()
	capa.size = AREA.size
	capa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(capa)
	if fase in ["final_cumplida", "final_incompleta"]:
		_ver_final("--" + fase.replace("_", "-"))
		return
	if fase == "derrota":
		var cierre := DerrotaUmbra.new()
		cierre.sol = campana.sol
		var motivo: String = recursos.estado().derrota
		cierre.motivo = historial_soles.get("motivo_derrota", motivo) if motivo.is_empty() else motivo
		cierre.reinicio_solicitado.connect(_reiniciar)
		capa.add_child(cierre)
		return
	if integrar_soles and fase == "base" and SOLES_JUGABLES.has(campana.sol) and not campana.listo_para_regresar():
		_ocultar_ciencia()
		_montar_sol()
		_mostrar_accesos_sol()
		return
	if fase not in ["camino_base", "base", "esclusa", "expedicion_sol_1"]:
		_ocultar_ciencia()
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
		"epilogo":
			_imagen(PuestoUmbra.CENTRO_AGUA, AREA)
			_sombra(Rect2(0, 0, 1280, 720), Color(0.03, 0.07, 0.12, 0.78))
			_imagen(PuestoUmbra.NORA, Rect2(190, 235, 175, 270), true)
			_imagen(PuestoUmbra.IRIS, Rect2(390, 235, 175, 270), true)
			_imagen(PuestoUmbra.TEO_NORMAL, Rect2(590, 235, 175, 270), true)
			_etiqueta(I18n.t("epilogo.gracias"), Rect2(105, 120, 1060, 75), 44)
			_etiqueta(I18n.t("epilogo.de_vuelta"), Rect2(810, 283, 340, 65), 26)
			_etiqueta(I18n.t("epilogo.nota"), Rect2(810, 355, 340, 130), 21)
		_:
			_imagen(PuestoUmbra.SENDERO, AREA)
			_sombra(AREA, Color(0.03, 0.07, 0.12, 0.30))
			_etiqueta(I18n.t("portada.titulo"), Rect2(85, 145, 1100, 100), 64)
			_etiqueta(I18n.t("portada.subtitulo"), Rect2(90, 255, 900, 60), 32)
			_etiqueta(I18n.t("portada.bajada"), Rect2(90, 322, 660, 72), 24)
	titulo = _etiqueta("", Rect2(34, 26, 590, 36), 23)
	voz = DialogoEscena.new()
	voz.position = Vector2(45, 82)
	capa.add_child(voz)
	pista = _etiqueta("", Rect2(34, 653, 445, 35), 17)
	boton = _boton("", Rect2(986, 28, 256, 45), _accion)
	boton.button_down.connect(_iniciar_taladro.bind(&"puntero"))
	boton.button_up.connect(_soltar_taladro.bind(&"puntero"))
	boton.visible = false
	match fase:
		"portada":
			_selector_idioma()
			boton.position = Vector2(90, 402)
			boton.text = I18n.t("portada.continuar") if not restaurado.is_empty() else I18n.t("portada.comenzar")
			boton.visible = true
			if not restaurado.is_empty():
				_boton(I18n.t("portada.reiniciar"), Rect2(90, 460, 256, 45), _reiniciar)
			for i in range(2):
				var opcion := I18n.t(["portada.final_incompleta", "portada.final_cumplida"][i])
				var clave := ["--final-incompleta", "--final-cumplida"][i] as String
				var btn_final := _boton(I18n.tf("portada.ver_final", [opcion]), Rect2(90 + i * 318, 529, 302, 44), _ver_final.bind(clave))
				btn_final.add_theme_font_size_override("font_size", 17)
		"ida":
			titulo.text = I18n.t("viaje.salida_tierra")
			boton.text = I18n.t("viaje.saltar")
			boton.visible = true
		"regreso", "llegada_tierra":
			titulo.text = I18n.t("viaje.marte_tierra")
			voz.decir("Iris", I18n.t("viaje.iris_regreso"))
			pista.text = ""
		"aterrizaje":
			titulo.text = I18n.t("viaje.aterrizaje")
			boton.text = I18n.t("viaje.saltar")
			boton.visible = true
		"pilotaje":
			titulo.text = I18n.t("viaje.pilotaje")
			voz.decir("Iris", I18n.t("viaje.iris_pilotaje"))
			pista.text = I18n.t("viaje.pista_pilotaje")
			boton.text = I18n.t("viaje.iniciar_vuelo")
			boton.visible = true
		"camino_base":
			voz.decir("Percy", I18n.t("viaje.percy_llegada"))
			_actualizar_guia()
			_mostrar_ciencia("atmosfera")
		"camino_nave":
			voz.decir("Percy", I18n.t("viaje.percy_despedida"))
		"expedicion_sol_1":
			titulo.text = I18n.t("soles.dia1_titulo")
			_actualizar_guia()
		"base":
			_refrescar_recursos()
			titulo.text = I18n.tf("soles.base_titulo", [campana.sol])
			_actualizar_guia()
		"noche":
			titulo.text = I18n.tf("soles.fin_sol", [campana.sol])
			voz.position = Vector2(80, 423)
			voz.decir("Pluto", I18n.t("soles.noche_pluto"))
			escena_descanso = _imagen(DORMITORIO_NOCHE, Rect2(-80, 0, 1440, 720))
			capa.move_child(escena_descanso, titulo.get_index())
			escena_descanso.pivot_offset = escena_descanso.size * 0.5
			escena_descanso.modulate.a = 0.0
		"amanecer":
			voz.decir("Pluto", I18n.t("soles.amanecer_regreso") if campana.listo_para_regresar() else I18n.tf("soles.amanecer_dia", [campana.sol]))
		"despegue":
			voz.decir("Nora", I18n.t("viaje.nora_despegue"))
		"epilogo":
			titulo.text = I18n.t("epilogo.titulo")
			voz.decir("Equipo científico", I18n.t("epilogo.equipo"))
			boton.text = I18n.t("ui.volver_comienzo")
	if fase in ["noche", "amanecer", "llegada_tierra", "aterrizaje"]:
		velo = _sombra(AREA, Color(0, 0, 0, 1 if fase in ["amanecer", "aterrizaje"] else 0))
	if fase in ["base", "expedicion_sol_1"]:
		_mostrar_accesos_sol()

func _mostrar_accesos_sol() -> void:
	boton_tablet = LinkButton.new()
	boton_tablet.text = I18n.t("ui.tablet_btn")
	boton_tablet.tooltip_text = I18n.t("ui.tablet_tooltip")
	boton_tablet.underline = LinkButton.UNDERLINE_MODE_ALWAYS
	boton_tablet.add_theme_font_size_override("font_size", 20)
	boton_tablet.add_theme_color_override("font_color", Color("#ffdbac"))
	boton_tablet.add_theme_color_override("font_hover_color", Color("#fff5df"))
	boton_tablet.add_theme_color_override("font_focus_color", Color("#fff5df"))
	boton_tablet.add_theme_color_override("font_outline_color", Color("#18110d"))
	boton_tablet.add_theme_constant_override("outline_size", 7)
	boton_tablet.position = Vector2(minf(957.0, 1246.0 - boton_tablet.get_minimum_size().x), 26.0)
	boton_tablet.pressed.connect(_alternar_tablet)
	boton_tablet.z_index = 10
	capa.add_child(boton_tablet)
	if fase != "base" or sol_anunciado == campana.sol or campana.listo_para_regresar():
		return
	sol_anunciado = campana.sol
	anuncio_sol = Control.new()
	anuncio_sol.size = AREA.size
	anuncio_sol.mouse_filter = Control.MOUSE_FILTER_STOP
	anuncio_sol.z_index = 20
	capa.add_child(anuncio_sol)
	if is_instance_valid(nivel_activo):
		nivel_activo.process_mode = Node.PROCESS_MODE_DISABLED

	var anterior := capa
	capa = anuncio_sol
	_imagen(AMANECER_MARTE, AREA)
	_sombra(AREA, Color("#130e17a9"))
	var texto := Control.new()
	texto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.add_child(texto)
	capa = texto
	var rotulos := [
		_etiqueta(I18n.tf("soles.sol_num_anuncio", [campana.sol]), Rect2(240, 194, 800, 130), 96),
		_etiqueta(I18n.t("soles.nom.%d" % campana.sol), Rect2(240, 337, 800, 60), 35),
		_etiqueta(I18n.t("soles.aviso.%d" % campana.sol), Rect2(230, 414, 820, 96), 22),
	]
	capa = anuncio_sol
	var continuar := _boton(I18n.t("ui.e_continuar"), Rect2(540, 610, 200, 44), _cerrar_anuncio_sol)
	continuar.focus_mode = Control.FOCUS_NONE
	capa = anterior
	for rotulo: Label in rotulos:
		rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rotulos[2].add_theme_color_override("font_color", Color("#ffcb91"))
	texto.modulate.a = 0.0
	texto.position.y = 14
	var entrada := anuncio_sol.create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
	entrada.tween_property(texto, "modulate:a", 1.0, 0.45)
	entrada.tween_property(texto, "position:y", 0.0, 0.45)
	entrada.chain().tween_interval(2.25)
	entrada.chain().tween_property(anuncio_sol, "modulate:a", 0.0, 0.4)
	entrada.chain().tween_callback(_cerrar_anuncio_sol)

func _cerrar_anuncio_sol() -> void:
	if not is_instance_valid(anuncio_sol):
		return
	anuncio_sol.hide()
	anuncio_sol.queue_free()
	anuncio_sol = null
	if is_instance_valid(nivel_activo):
		nivel_activo.process_mode = Node.PROCESS_MODE_INHERIT

func _alternar_tablet() -> void:
	if is_instance_valid(interfaz_tablet):
		_cerrar_tablet()
		return
	_ocultar_ciencia()
	_cerrar_anuncio_sol()
	_soltar_taladro(&"")
	interfaz_tablet = Tablet.new()
	interfaz_tablet.estado = recursos.estado()
	interfaz_tablet.z_index = 25
	interfaz_tablet.cerrar_solicitado.connect(_cerrar_tablet)
	if is_instance_valid(nivel_activo):
		nivel_activo.process_mode = Node.PROCESS_MODE_DISABLED
	elif is_instance_valid(huerto):
		huerto.process_mode = Node.PROCESS_MODE_DISABLED
	elif is_instance_valid(laboratorio):
		laboratorio.process_mode = Node.PROCESS_MODE_DISABLED
	capa.add_child(interfaz_tablet)

func _cerrar_tablet() -> void:
	capa.remove_child(interfaz_tablet)
	interfaz_tablet.queue_free()
	interfaz_tablet = null
	if is_instance_valid(nivel_activo):
		nivel_activo.process_mode = Node.PROCESS_MODE_INHERIT
	elif is_instance_valid(huerto):
		huerto.process_mode = Node.PROCESS_MODE_INHERIT
	elif is_instance_valid(laboratorio):
		laboratorio.process_mode = Node.PROCESS_MODE_INHERIT

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
	_ocultar_ciencia()
	boton.hide()
	panel_control = PanelControl.new()
	var estado := recursos.estado()
	var regreso := campana.listo_para_regresar()
	panel_control.configurar(campana.sol, regreso)
	panel_control.cerrar_solicitado.connect(_cerrar_control)
	panel_control.ruta_confirmada.connect(_confirmar_ruta)
	capa.add_child(panel_control)
	capa.move_child(boton_tablet, -1)
	if not regreso:
		var tarea := I18n.t("control.aire_ok" if estado.aire_asegurado else "control.aire_falta")
		if _sol_uno():
			tarea = Tutorial.guia(Tutorial.objetivo(estado))
		panel_control.mostrar_tarea(tarea)

func _cerrar_control() -> void:
	capa.remove_child(panel_control)
	panel_control.queue_free()
	panel_control = null
	_actualizar_guia()

func _confirmar_ruta() -> void:
	_cerrar_control()
	voz.decir("Iris", I18n.t("base.ruta_preparada"))
	puesto.objetivo_mision = "cierre"
	aviso_tiempo = 9

func _abrir_nucleo() -> void:
	_ocultar_ciencia()
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
	guia.decir("Pluto", I18n.t("base.pluto.nucleo"))
	capa.move_child(boton, -1)
	var puerta := visita_nucleo.proyectar_suelo(MapaNucleo.UMBRAL)
	boton.position = puerta + Vector2(-128, 28)
	boton.text = I18n.t("base.btn.volver_esclusa")
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
	_ocultar_ciencia()
	estacion = id
	boton.hide()
	if id == "cultivos":
		_abrir_huerto()
		return
	laboratorio = Laboratorio.new()
	laboratorio.tipo = id
	laboratorio.recursos = recursos
	laboratorio.cerrar_solicitado.connect(_cerrar_estacion)
	laboratorio.trabajo_completado.connect(_registrar_laboratorio)
	capa.add_child(laboratorio)
	capa.move_child(boton_tablet, -1)

func _registrar_laboratorio(_ganancia: int) -> void:
	_ciencia_pendiente = "agua" if estacion == "agua" else "oxigeno"
	_refrescar_recursos()
	if _sol_uno():
		var datos := recursos.estado()
		voz.decir("Pluto", Tutorial.guia(Tutorial.objetivo(datos)))
		aviso_tiempo = 6
	_guardar()

func _abrir_huerto() -> void:
	huerto = Invernadero.new()
	huerto.recursos = recursos
	if _sol_uno():
		var datos := recursos.estado()
		var anterior := Tutorial.cosecha(datos)
		if Recursos.CULTIVOS.has(anterior) and Tutorial.COMIDA not in datos.decisiones:
			huerto.cosecha_guardada = anterior
			huerto.comer_guardado = _comer_guardado
	huerto.cerrar_solicitado.connect(_cerrar_estacion)
	huerto.cultivo_atendido.connect(_guardar_huerto)
	capa.add_child(huerto)
	capa.move_child(boton_tablet, -1)

func _guardar_huerto(cosechado: bool) -> void:
	_ciencia_pendiente = "cultivos"
	if _sol_uno() and cosechado:
		recursos.aplicar_decision(Tutorial.COMIDA, {})
	_refrescar_recursos()
	_guardar()

func _comer_guardado(cultivo: String) -> bool:
	if recursos.estado().reservas.alimento == Recursos.LIMITES.alimento:
		return false
	return recursos.aplicar_decision(Tutorial.COMIDA, {"alimento": Recursos.CULTIVOS[cultivo].alimento})

func _cerrar_estacion() -> void:
	estacion = ""
	var actividad: Control = huerto if is_instance_valid(huerto) else laboratorio
	capa.remove_child(actividad)
	actividad.queue_free()
	huerto = null
	laboratorio = null
	_actualizar_guia()
	if not _ciencia_pendiente.is_empty():
		var tema := _ciencia_pendiente
		_ciencia_pendiente = ""
		_mostrar_ciencia(tema)

func _mostrar_ciencia(tema: String) -> void:
	if is_instance_valid(panel_control) or is_instance_valid(huerto) or is_instance_valid(laboratorio) or is_instance_valid(interfaz_tablet) or is_instance_valid(menu_soles) or is_instance_valid(anuncio_sol) or is_instance_valid(marco_nucleo) or plano:
		return
	if not is_instance_valid(sabias_que):
		sabias_que = SabiasQue.new()
		add_child(sabias_que)
	sabias_que.mostrar(tema)

func _ocultar_ciencia() -> void:
	if is_instance_valid(sabias_que):
		sabias_que.ocultar()

func _crear_mapa(interior: bool) -> void:
	var marco := Control.new()
	marco.size = AREA.size
	marco.clip_contents = true
	marco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.add_child(marco)
	puesto = PuestoUmbra.new()
	puesto.interior = interior
	puesto.guia_sol_uno = _sol_uno() and fase == "base"
	puesto.pluto_acompana = fase == "base"
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
	AccionEscena.aplicar(control)
	control.pressed.connect(accion)
	capa.add_child(control)
	return control

func _selector_idioma() -> void:
	var etiqueta := _etiqueta(I18n.t("ui.idioma_titulo"), Rect2(616, 16, 630, 26), 15)
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	for i in range(I18n.IDIOMAS.size()):
		var codigo: String = I18n.IDIOMAS[i]
		var btn := _boton(I18n.etiqueta(codigo), Rect2(616 + i * 106, 52, 100, 36), _elegir_idioma.bind(codigo))
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_font_size_override("font_size", 15)
		if codigo == I18n.idioma():
			var activo := StyleBoxFlat.new()
			activo.bg_color = Color("#1e3f4d")
			activo.border_color = CIAN
			activo.set_border_width_all(2)
			activo.set_corner_radius_all(7)
			btn.add_theme_stylebox_override("normal", activo)
			btn.add_theme_color_override("font_color", CIAN)

func _elegir_idioma(codigo: String) -> void:
	I18n.set_idioma(codigo)
	_mostrar()
