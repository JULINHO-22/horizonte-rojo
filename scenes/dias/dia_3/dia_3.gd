extends Control
## Sol 3 aislado: rutina en Plantas, fallo eléctrico y decisión de soporte vital.
## La campaña debe llamar configurar() antes de añadir la escena al árbol.

signal descanso_solicitado(resultado: Dictionary)
signal dia_completado(resultado: Dictionary)
signal avance_guardado

const Recursos := preload("res://scripts/mecanicas/recursos_mision.gd")
const PanelControl := preload("res://scripts/panel_control.gd")
const DialogoEscena := preload("res://scripts/dialogo_escena.gd")
const AccionEscena := preload("res://scripts/accion_escena.gd")
const Invernadero := preload("res://scripts/invernadero_umbra.gd")
const Diagnostico := preload("res://scripts/diagnostico_umbra.gd")
const SabiasQue := preload("res://scripts/sabias_que.gd")
const ControlesTactiles := preload("res://scripts/controles_tactiles.gd")
const AREA := Rect2(0, 0, 1280, 720)
const TINTA_CLARA := Color("#2a1c17")
const PAPEL := Color("#fff1db")
const CIAN := Color("#83eadc")
const NARANJA := Color("#f6a44e")
const ROJO := Color("#ff6b6b")

var recursos
var sistemas_danados := false
var modo_prueba := true
var fase := "inicio"
var decision := ""
var invernadero_revisado := false
var puesto: PuestoUmbra
var capa_mapa: Control
var modal: PanelContainer
var velo_fallo: ColorRect
var titulo: Label
var objetivo: Label
var dialogo
var pista: Label
var boton_accion: Button
var panel_control: PanelControl
var huerto: Invernadero
var diagnostico: Diagnostico
var sabias_que: SabiasQue
var pad_tactil: ControlesTactiles
var boton_plano: Button
var _ciencia_huerto := false
var plano := false


func configurar(instancia_recursos, heredado_sistemas_danados := false) -> void:
	recursos = instancia_recursos
	sistemas_danados = heredado_sistemas_danados
	modo_prueba = false
	if is_inside_tree():
		_preparar_dia()


func _ready() -> void:
	get_window().min_size = Vector2i(800, 450)
	if recursos == null:
		recursos = _crear_estado_de_prueba()
		modo_prueba = true
	_crear_mapa()
	_crear_interfaz()
	_preparar_dia()


func _process(delta: float) -> void:
	if recursos == null or puesto == null:
		return
	var datos: Dictionary = recursos.estado()
	if datos.derrota != "":
		_mostrar_derrota(datos.derrota)
		return
	if _juego_activo():
		var paso := minf(delta, 0.05)
		_caminar(paso)
		recursos.avanzar(paso)
	elif is_instance_valid(huerto):
		recursos.avanzar(delta)
		if is_instance_valid(pad_tactil):
			pad_tactil.establecer_habilitado(false)
		if is_instance_valid(boton_plano):
			boton_plano.hide()
		if is_instance_valid(sabias_que):
			sabias_que.ocultar()
		return
	if is_instance_valid(pad_tactil):
		pad_tactil.establecer_habilitado(_juego_activo() and not plano)
	if is_instance_valid(boton_plano):
		boton_plano.text = I18n.t("ui.m_cerrar_plano" if plano else "ui.m_plano")
		var libre := modal == null and not is_instance_valid(panel_control) and not is_instance_valid(huerto) and not is_instance_valid(diagnostico) and fase in ["ir_plantas", "ir_oxigeno", "cierre"]
		boton_plano.visible = libre and (ControlesTactiles.activo() or plano)
	if is_instance_valid(pista):
		pista.position.x = 204.0 if (is_instance_valid(pad_tactil) and pad_tactil.visible) else 24.0
	if is_instance_valid(sabias_que):
		if not _juego_activo() or plano:
			sabias_que.ocultar()
		else:
			var zonas: Array[Rect2] = [Rect2(24, 18, 520, 68), Rect2(24, 676, 540, 32)]
			if boton_accion.visible:
				zonas.append(boton_accion.get_global_rect())
			if dialogo.visible:
				zonas.append(dialogo.get_global_rect())
			sabias_que.evitar(zonas)
	_actualizar_guia()
	_ubicar_interfaz()


func _unhandled_key_input(event: InputEvent) -> void:
	if is_instance_valid(huerto) or is_instance_valid(diagnostico) or not event is InputEventKey or not event.pressed or event.echo:
		return
	if is_instance_valid(panel_control):
		if event.physical_keycode == KEY_ESCAPE:
			_cerrar_control()
		get_viewport().set_input_as_handled()
		return
	if event.physical_keycode in [KEY_E, KEY_ENTER]:
		_accion()
	elif event.physical_keycode == KEY_M and modal == null and fase not in ["inicio", "decision", "terminado"]:
		plano = not plano
		puesto.plano = plano
		puesto.queue_redraw()
	elif event.physical_keycode == KEY_ESCAPE and modal != null and fase not in ["inicio", "decision", "terminado"]:
		_cerrar_modal()


func _preparar_dia() -> void:
	if recursos == null or puesto == null:
		return
	var datos: Dictionary = recursos.estado()
	if datos.sol != 3 or not datos.en_curso:
		_mostrar_error_de_entrada(datos)
		return
	if not recursos.cambiado.is_connected(_actualizar_hud):
		recursos.cambiado.connect(_actualizar_hud)
	if sistemas_danados and not datos.decisiones.has("consecuencia_tormenta_dia_2"):
		if not recursos.aplicar_perdidas("consecuencia_tormenta_dia_2", {"agua": 1, "oxigeno": 1}):
			_mostrar_error(I18n.t("sol3.err.consecuencias"))
			return
		if recursos.estado().derrota != "":
			_mostrar_derrota(recursos.estado().derrota)
			return
	puesto.punto = PuestoUmbra.TERMINALES.dormitorio
	puesto.objetivo_mision = "cultivos"
	puesto.actualizar_camara(2.0)
	puesto.queue_redraw()
	fase = "inicio"
	decision = ""
	_actualizar_hud()
	if recursos.estado().aire_asegurado:
		var decisiones: Array = recursos.estado().decisiones
		decision = "invernadero" if "sol_3_invernadero" in decisiones else "oxigeno"
		_cerrar_decision(I18n.t("sol3.pluto.aire_listo"))
	elif modo_prueba:
		_mostrar_inicio()
	else:
		_comenzar_recorrido()
		_decir_pluto(I18n.t("sol3.pluto.inicio"))


func _crear_estado_de_prueba():
	var prueba := Recursos.new()
	var datos: Dictionary = prueba.guardar_estado()
	datos.sol = 3
	datos.polvo = "medio"
	datos.reservas = {"energia": 9, "agua": 4, "oxigeno": 6, "alimento": 6}
	datos.bandejas = {"rabano": 0.0}
	datos.decisiones = []
	datos.relojes = [0.0, 0.0, 0.0]
	assert(prueba.restaurar_estado(datos))
	assert(prueba.iniciar_sol("medio"))
	return prueba


func _crear_mapa() -> void:
	capa_mapa = Control.new()
	capa_mapa.size = AREA.size
	capa_mapa.clip_contents = true
	capa_mapa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(capa_mapa)
	puesto = PuestoUmbra.new()
	puesto.interior = true
	puesto.laboratorio_activo = true
	puesto.pluto_acompana = true
	puesto.cielo_sereno = true
	puesto.punto = PuestoUmbra.TERMINALES.dormitorio
	puesto.objetivo_mision = "cultivos"
	puesto.escala_visual = 720.0 / 527.0
	puesto.ancho_visible = 1280.0 / puesto.escala_visual
	puesto.scale = Vector2.ONE * puesto.escala_visual
	puesto.tiempo = 17.0
	capa_mapa.add_child(puesto)
	puesto.actualizar_camara(2.0)


func _crear_interfaz() -> void:
	titulo = _etiqueta(I18n.t("sol3.hud.titulo"), Rect2(24, 18, 430, 29), 20, CIAN)
	_aplicar_sombra(titulo)
	add_child(titulo)
	objetivo = _etiqueta("", Rect2(24, 49, 480, 28), 17, PAPEL)
	_aplicar_sombra(objetivo)
	add_child(objetivo)

	dialogo = DialogoEscena.new()
	add_child(dialogo)
	pista = _etiqueta(I18n.t("sol3.hud.ayuda"), Rect2(24, 682, 520, 24), 14, CIAN)
	_aplicar_sombra(pista)
	add_child(pista)

	boton_accion = _boton(I18n.t("ui.continuar"), Rect2(0, 0, 294, 50), _accion)
	add_child(boton_accion)

	velo_fallo = ColorRect.new()
	velo_fallo.color = Color(0.55, 0.04, 0.08, 0)
	velo_fallo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	velo_fallo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(velo_fallo)
	move_child(velo_fallo, capa_mapa.get_index() + 1)
	sabias_que = SabiasQue.new()
	add_child(sabias_que)
	pad_tactil = ControlesTactiles.new()
	add_child(pad_tactil)
	boton_plano = _boton(I18n.t("ui.m_plano"), Rect2(1096, 62, 160, 36), _alternar_plano)
	boton_plano.focus_mode = Control.FOCUS_NONE
	boton_plano.add_theme_font_size_override("font_size", 16)
	boton_plano.visible = false
	add_child(boton_plano)
	_ubicar_interfaz()


func _mostrar_inicio() -> void:
	var columna := _crear_modal(I18n.t("sol3.intro.tit"))
	_texto_modal(columna, I18n.tf("sol3.intro.res", [
		I18n.t("sol3.intro.danados") if sistemas_danados
		else I18n.t("sol3.intro.protegidos")]), 19)
	_decir_pluto(I18n.t("sol3.intro.desc"))
	var continuar := _boton_fila(columna, I18n.t("sol3.intro.btn"), _comenzar_recorrido)
	continuar.grab_focus()


func _comenzar_recorrido() -> void:
	_cerrar_modal()
	fase = "ir_plantas"
	puesto.objetivo_mision = "cultivos"
	_decir_pluto(I18n.t("sol3.pluto.empecemos"))
	_actualizar_guia()


func _caminar(delta: float) -> void:
	var direccion := Vector2(
		int(Input.is_physical_key_pressed(KEY_D) or Input.is_action_pressed("ui_right")) - int(Input.is_physical_key_pressed(KEY_A) or Input.is_action_pressed("ui_left")),
		int(Input.is_physical_key_pressed(KEY_S) or Input.is_action_pressed("ui_down")) - int(Input.is_physical_key_pressed(KEY_W) or Input.is_action_pressed("ui_up")))
	puesto.avanzar((direccion + ControlesTactiles.direccion()).limit_length(1.0), delta)
	puesto.actualizar_camara(delta)
	puesto.tiempo += delta
	puesto.queue_redraw()


func _alternar_plano() -> void:
	if modal != null or fase not in ["ir_plantas", "ir_oxigeno", "cierre"] or is_instance_valid(panel_control) or is_instance_valid(huerto) or is_instance_valid(diagnostico):
		return
	plano = not plano
	puesto.plano = plano
	puesto.queue_redraw()


func _juego_activo() -> bool:
	return modal == null and not is_instance_valid(panel_control) and not is_instance_valid(huerto) and fase in ["ir_plantas", "ir_oxigeno", "cierre"]


func _actualizar_guia() -> void:
	if puesto == null or boton_accion == null:
		return
	boton_accion.visible = false
	match fase:
		"inicio":
			objetivo.text = I18n.t("sol3.obj.escuchar")
		"ir_plantas":
			objetivo.text = I18n.t("sol3.obj.plantas")
		"ir_oxigeno":
			objetivo.text = I18n.t("sol3.obj.agua")
			if _oxigeno_cercano():
				boton_accion.text = I18n.t("sol3.act.oxigeno")
				boton_accion.visible = modal == null
		"decision":
			objetivo.text = I18n.t("sol3.obj.emergencia")
		"cierre":
			objetivo.text = I18n.t("sol3.obj.descansar")
			if puesto.terminal_cercana() == "dormitorio":
				boton_accion.text = I18n.t("sol3.act.dormir")
				boton_accion.visible = modal == null
		"terminado":
			objetivo.text = I18n.t("sol3.obj.fin")
	if _juego_activo() and not plano and puesto.terminal_cercana() == "radio":
		boton_accion.text = I18n.t("sol3.act.tareas")
		boton_accion.show()
	elif _juego_activo() and not plano and puesto.terminal_cercana() == "cultivos":
		boton_accion.text = I18n.t("sol3.act.invernadero")
		boton_accion.show()
	if boton_accion.visible:
		_ubicar_accion()


func _accion() -> void:
	if not _juego_activo() or plano:
		return
	if puesto.terminal_cercana() == "radio":
		panel_control = PanelControl.new()
		panel_control.configurar(3, false)
		panel_control.cerrar_solicitado.connect(_cerrar_control)
		add_child(panel_control)
		var tarea: String = {
			"ir_plantas": I18n.t("sol3.tarea.0"),
			"ir_oxigeno": I18n.t("sol3.tarea.1"),
			"cierre": I18n.t("sol3.tarea.2"),
		}[fase]
		panel_control.mostrar_tarea(tarea)
		return
	if puesto.terminal_cercana() == "cultivos":
		_abrir_huerto()
		return
	match fase:
		"ir_oxigeno":
			if _oxigeno_cercano():
				_activar_fallo()
		"cierre":
			if puesto.terminal_cercana() == "dormitorio":
				_solicitar_dormir()

func _cerrar_control() -> void:
	remove_child(panel_control)
	panel_control.queue_free()
	panel_control = null

func _abrir_huerto() -> void:
	invernadero_revisado = true
	_ciencia_huerto = false
	huerto = Invernadero.new()
	huerto.recursos = recursos
	huerto.cerrar_solicitado.connect(_cerrar_huerto)
	huerto.cultivo_atendido.connect(func(_cosechado: bool):
		_ciencia_huerto = true
		avance_guardado.emit())
	boton_accion.hide()
	add_child(huerto)
	if is_instance_valid(pad_tactil):
		pad_tactil.establecer_habilitado(false)
	if is_instance_valid(boton_plano):
		boton_plano.hide()
	if is_instance_valid(sabias_que):
		sabias_que.ocultar()


func _cerrar_huerto() -> void:
	remove_child(huerto)
	huerto.queue_free()
	huerto = null
	if fase == "ir_plantas" and recursos.estado().derrota.is_empty():
		fase = "ir_oxigeno"
		puesto.objetivo_mision = "agua"
		_decir_pluto(I18n.t("sol3.plantas.sig"))
	_actualizar_guia()
	if _ciencia_huerto:
		_ciencia_huerto = false
		if is_instance_valid(sabias_que) and _juego_activo() and not plano:
			sabias_que.mostrar("cultivos")


func _activar_fallo() -> void:
	if fase != "ir_oxigeno":
		return
	fase = "decision"
	puesto.objetivo_mision = ""
	velo_fallo.color.a = 0.38
	var tween := create_tween()
	tween.tween_property(velo_fallo, "color:a", 0.0, 0.65)
	_mostrar_decision()


func _mostrar_decision(aviso := "") -> void:
	var datos: Dictionary = recursos.estado()
	var costo_oxigeno_energia := 7 if sistemas_danados else 6
	var costo_oxigeno_agua := 2 if sistemas_danados else 1
	var costo_tanques := 4 if sistemas_danados else 3
	_decir_pluto(I18n.t("sol3.fallo.desc"))
	_cerrar_modal()
	diagnostico = Diagnostico.new()
	diagnostico.rutas = [
		{"id": "oxigeno", "titulo": I18n.t("sol3.diag.ox.tit"),
			"costo": I18n.tf("sol3.diag.ox.costo", [costo_oxigeno_energia, costo_oxigeno_agua]),
			"efecto": I18n.t("sol3.diag.ox.efecto"),
			"posible": datos.reservas.energia >= costo_oxigeno_energia and
				datos.reservas.agua >= costo_oxigeno_agua and datos.reservas.alimento >= 2},
		{"id": "invernadero", "titulo": I18n.t("sol3.diag.inv.tit"),
			"costo": I18n.tf("sol3.diag.inv.costo", [costo_tanques]),
			"efecto": I18n.t("sol3.diag.inv.efecto"),
			"posible": datos.reservas.energia >= costo_tanques and datos.reservas.agua >= 1 and datos.reservas.oxigeno > 2},
	]
	diagnostico.aviso = aviso
	diagnostico.confirmada.connect(_aplicar_ruta)
	diagnostico.cerrar_solicitado.connect(_volver_desde_decision)
	boton_accion.hide()
	add_child(diagnostico)


func _aplicar_ruta(id: String) -> void:
	if id == "oxigeno":
		_elegir_oxigeno()
	else:
		_elegir_invernadero()


func _volver_desde_decision() -> void:
	_cerrar_modal()
	fase = "ir_oxigeno"
	puesto.objetivo_mision = "agua"
	_decir_pluto(I18n.t("sol3.fallo.sigue"))


func _oxigeno_cercano() -> bool:
	return puesto.punto.distance_to(PuestoUmbra.ESTACION_OXIGENO) <= 13.0


func _elegir_oxigeno() -> void:
	var costo_energia := 7 if sistemas_danados else 6
	var costo_agua := 2 if sistemas_danados else 1
	if not recursos.activar_oxigeno(costo_energia, costo_agua, 2, true):
		_mostrar_decision(I18n.t("sol3.fallo.no_ox"))
		return
	decision = "oxigeno"
	recursos.aplicar_decision("sol_3_oxigeno", {})
	avance_guardado.emit()
	_cerrar_decision(I18n.t("sol3.fallo.ok_ox"))


func _elegir_invernadero() -> void:
	var costo_energia := 4 if sistemas_danados else 3
	if not recursos.usar_tanques_emergencia(costo_energia):
		_mostrar_decision(I18n.t("sol3.fallo.no_inv"))
		return
	decision = "invernadero"
	recursos.aplicar_decision("sol_3_invernadero", {})
	avance_guardado.emit()
	_cerrar_decision(I18n.t("sol3.fallo.ok_inv"))


func _cerrar_decision(mensaje: String) -> void:
	_cerrar_modal()
	fase = "cierre"
	puesto.objetivo_mision = "dormitorio"
	_decir_pluto(mensaje + I18n.t("sol3.fallo.revisa_alim"))
	_actualizar_hud()
	_actualizar_guia()
	if is_instance_valid(sabias_que) and _juego_activo() and not plano:
		sabias_que.mostrar("soporte")


func _solicitar_dormir() -> void:
	var datos: Dictionary = recursos.estado()
	if not datos.aire_asegurado:
		_decir_pluto(I18n.t("sol3.dormir.sin_aire"))
		return
	if datos.reservas.alimento == 0:
		_decir_pluto(I18n.t("sol3.dormir.sin_comida"))
		puesto.objetivo_mision = "cultivos"
		return
	var resultado := _resultado()
	if not modo_prueba:
		descanso_solicitado.emit(resultado)
		_mostrar_fin(I18n.t("sol3.fin.campana_tit"), I18n.t("sol3.fin.campana_msg"))
		return
	var completado: bool = recursos.dormir()
	if completado:
		resultado["estado_despues_de_dormir"] = recursos.estado()
		dia_completado.emit(resultado)
		_mostrar_fin(I18n.t("sol3.fin.local_tit"), I18n.t("sol3.fin.local_msg"))
	else:
		_mostrar_derrota(recursos.estado().derrota)


func _resultado() -> Dictionary:
	return {
		"dia": 3,
		"decision": decision,
		"sistemas_danados": sistemas_danados,
		"invernadero_revisado": invernadero_revisado,
		"estado": recursos.estado(),
	}


func _actualizar_hud() -> void:
	if recursos == null:
		return
	var datos: Dictionary = recursos.estado()
	if datos.derrota != "":
		_mostrar_derrota(datos.derrota)


func _decir_pluto(texto: String) -> void:
	dialogo.decir("Pluto", texto)
	_ubicar_interfaz()


func _ubicar_interfaz() -> void:
	if puesto == null or dialogo == null:
		return
	dialogo.position = Vector2(24, 90)
	dialogo.visible = modal == null and not is_instance_valid(diagnostico) and not is_instance_valid(huerto) and not is_instance_valid(panel_control) and not plano and not dialogo.frase.text.is_empty()


func _ubicar_accion() -> void:
	var suelo := puesto.proyectar_suelo(puesto.punto)
	boton_accion.position = Vector2(
		clampf(suelo.x - boton_accion.size.x / 2.0, 24, 1256 - boton_accion.size.x),
		clampf(suelo.y + 18, 235, 628))


func _mostrar_fin(encabezado: String, texto: String) -> void:
	if is_instance_valid(pad_tactil):
		pad_tactil.establecer_habilitado(false)
	if is_instance_valid(boton_plano):
		boton_plano.hide()
	if is_instance_valid(sabias_que):
		sabias_que.ocultar()
	fase = "terminado"
	puesto.objetivo_mision = ""
	var columna := _crear_modal(encabezado)
	_texto_modal(columna, texto, 20, CIAN)
	var texto_decision := I18n.t("sol3.dec.ninguna")
	if decision == "oxigeno":
		texto_decision = I18n.t("sol3.dec.oxigeno")
	elif decision == "invernadero":
		texto_decision = I18n.t("sol3.dec.invernadero")
	elif decision != "":
		texto_decision = decision
	_texto_modal(columna, I18n.tf("sol3.fin.resumen", [
		texto_decision,
		I18n.t("sol3.sist.danados") if sistemas_danados else I18n.t("sol3.sist.protegidos")]), 18)
	if modo_prueba:
		_boton_fila(columna, I18n.t("sol3.btn.reiniciar"), get_tree().reload_current_scene)


func _mostrar_derrota(motivo: String) -> void:
	if fase == "terminado":
		return
	if is_instance_valid(huerto):
		_cerrar_huerto()
	var textos := {
		"oxigeno_agotado": I18n.t("sol3.derrota.ox"),
		"aire_sin_activar": I18n.t("sol3.derrota.aire"),
		"hambre_al_dormir": I18n.t("sol3.derrota.comida"),
	}
	_mostrar_fin(I18n.t("ui.game_over_upper"), textos.get(motivo, I18n.t("sol3.derrota.sub")))


func _mostrar_error_de_entrada(datos: Dictionary) -> void:
	_mostrar_error(I18n.tf("sol3.err.estado", [
		str(datos.get("sol", "?")), str(datos.get("en_curso", false))]))


func _mostrar_error(texto: String) -> void:
	fase = "terminado"
	var columna := _crear_modal(I18n.t("sol3.err.tit"))
	_texto_modal(columna, texto, 19, ROJO)


func _crear_modal(encabezado: String) -> VBoxContainer:
	_cerrar_modal()
	modal = PanelContainer.new()
	modal.position = Vector2(214, 112)
	modal.size = Vector2(852, 438)
	modal.add_theme_stylebox_override("panel", _estilo_modal())
	add_child(modal)
	var margen := MarginContainer.new()
	margen.add_theme_constant_override("margin_left", 28)
	margen.add_theme_constant_override("margin_right", 28)
	margen.add_theme_constant_override("margin_top", 24)
	margen.add_theme_constant_override("margin_bottom", 24)
	modal.add_child(margen)
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 12)
	margen.add_child(columna)
	_texto_modal(columna, encabezado, 28, CIAN)
	boton_accion.visible = false
	return columna


func _cerrar_modal() -> void:
	if is_instance_valid(diagnostico):
		remove_child(diagnostico)
		diagnostico.queue_free()
		diagnostico = null
	if modal != null:
		modal.queue_free()
		modal = null


func _texto_modal(padre: Control, texto: String, tamano: int, color := PAPEL) -> Label:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	etiqueta.add_theme_font_size_override("font_size", tamano)
	etiqueta.add_theme_color_override("font_color", color)
	etiqueta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	padre.add_child(etiqueta)
	return etiqueta


func _boton_fila(padre: Control, texto: String, accion: Callable) -> Button:
	var boton := Button.new()
	boton.text = texto
	boton.custom_minimum_size.y = 42
	boton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	boton.add_theme_font_size_override("font_size", 16)
	AccionEscena.aplicar(boton)
	boton.pressed.connect(accion)
	padre.add_child(boton)
	return boton


func _etiqueta(texto: String, rect: Rect2, tamano: int, color: Color) -> Label:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.position = rect.position
	etiqueta.size = rect.size
	etiqueta.add_theme_font_size_override("font_size", tamano)
	etiqueta.add_theme_color_override("font_color", color)
	etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return etiqueta


func _aplicar_sombra(etiqueta: Label) -> void:
	etiqueta.add_theme_color_override("font_outline_color", Color("#0a121b"))
	etiqueta.add_theme_constant_override("outline_size", 5)


func _boton(texto: String, rect: Rect2, accion: Callable) -> Button:
	var boton := Button.new()
	boton.text = texto
	boton.position = rect.position
	boton.size = rect.size
	boton.add_theme_font_size_override("font_size", 18)
	AccionEscena.aplicar(boton)
	boton.pressed.connect(accion)
	return boton


func _estilo_modal() -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = TINTA_CLARA
	estilo.shadow_color = Color("#120b08b8")
	estilo.shadow_size = 24
	estilo.set_corner_radius_all(7)
	estilo.content_margin_left = 12
	estilo.content_margin_right = 12
	estilo.content_margin_top = 8
	estilo.content_margin_bottom = 8
	return estilo
