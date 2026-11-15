extends Control
## Día 3 aislado: rutina en Plantas, fallo eléctrico y decisión de soporte vital.
## La campaña debe llamar configurar() antes de añadir la escena al árbol.

signal descanso_solicitado(resultado: Dictionary)
signal dia_completado(resultado: Dictionary)

const Recursos := preload("res://scripts/mecanicas/recursos_mision.gd")
const Indicadores := preload("res://scripts/mecanicas/indicadores_refugio.gd")
const DialogoEscena := preload("res://scripts/dialogo_escena.gd")
const AREA := Rect2(0, 0, 1280, 720)
const TINTA := Color("#101c28")
const TINTA_CLARA := Color("#1b3140")
const PAPEL := Color("#fff1db")
const CIAN := Color("#83eadc")
const NARANJA := Color("#f6a44e")
const ROJO := Color("#ff6b6b")
const NOMBRES_CULTIVOS := {
	"lechuga": "Lechuga", "rabano": "Rábano", "tomate": "Tomate", "papa": "Papa",
}

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
var lecturas
var comida_ui
var mensaje_panel := ""
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
	_actualizar_guia()
	_ubicar_interfaz()


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
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
			_mostrar_error("No se pudieron aplicar las consecuencias pendientes del día 2.")
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
	_mostrar_inicio()


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
	titulo = _etiqueta("DÍA 3 · OXÍGENO O INVERNADERO", Rect2(24, 18, 430, 29), 20, CIAN)
	_aplicar_sombra(titulo)
	add_child(titulo)
	objetivo = _etiqueta("", Rect2(24, 49, 480, 28), 17, PAPEL)
	_aplicar_sombra(objetivo)
	add_child(objetivo)

	lecturas = Indicadores.new()
	lecturas.position = Vector2(24, 86)
	lecturas.scale = Vector2.ONE * 0.72
	add_child(lecturas)
	comida_ui = Indicadores.new()
	comida_ui.solo_alimento = true
	comida_ui.position = Vector2(974, 22)
	add_child(comida_ui)

	dialogo = DialogoEscena.new()
	add_child(dialogo)
	pista = _etiqueta("WASD / flechas · Caminar   E · Interactuar   M · Plano", Rect2(24, 682, 520, 24), 14, CIAN)
	_aplicar_sombra(pista)
	add_child(pista)

	boton_accion = _boton("Continuar", Rect2(0, 0, 294, 50), _accion)
	add_child(boton_accion)

	velo_fallo = ColorRect.new()
	velo_fallo.color = Color(0.55, 0.04, 0.08, 0)
	velo_fallo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	velo_fallo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(velo_fallo)
	move_child(velo_fallo, capa_mapa.get_index() + 1)
	_ubicar_interfaz()


func _mostrar_inicio() -> void:
	var columna := _crear_modal("Después de la tormenta")
	_texto_modal(columna, "Las reservas conservan los valores de los días anteriores. %s" % (
		"Los sistemas quedaron dañados y se aplicaron las pérdidas pendientes." if sistemas_danados
		else "La reparación del día 2 protegió los sistemas."), 19)
	_decir_pluto("La tormenta terminó. Vamos a revisar cómo quedaron los sistemas de Umbra. Empecemos por el invernadero y, si las reservas lo permiten, plantemos algo.")
	var continuar := _boton_fila(columna, "Comenzar la revisión", _comenzar_recorrido)
	continuar.grab_focus()


func _comenzar_recorrido() -> void:
	_cerrar_modal()
	fase = "ir_plantas"
	puesto.objetivo_mision = "cultivos"
	_decir_pluto("Empecemos por el invernadero. Revisa las bandejas y planta algo si las reservas lo permiten.")
	_actualizar_guia()


func _caminar(delta: float) -> void:
	var direccion := Vector2(
		int(Input.is_physical_key_pressed(KEY_D) or Input.is_action_pressed("ui_right")) - int(Input.is_physical_key_pressed(KEY_A) or Input.is_action_pressed("ui_left")),
		int(Input.is_physical_key_pressed(KEY_S) or Input.is_action_pressed("ui_down")) - int(Input.is_physical_key_pressed(KEY_W) or Input.is_action_pressed("ui_up")))
	puesto.avanzar(direccion.normalized(), delta)
	puesto.actualizar_camara(delta)
	puesto.tiempo += delta
	puesto.queue_redraw()


func _juego_activo() -> bool:
	return modal == null and fase in ["ir_plantas", "ir_oxigeno", "cierre"]


func _actualizar_guia() -> void:
	if puesto == null or boton_accion == null:
		return
	boton_accion.visible = false
	match fase:
		"inicio":
			objetivo.text = "OBJETIVO · Escuchar a Pluto"
		"ir_plantas":
			objetivo.text = "OBJETIVO · Revisar Plantas"
			if puesto.terminal_cercana() == "cultivos":
				boton_accion.text = "E · Revisar el invernadero"
				boton_accion.visible = modal == null
		"ir_oxigeno":
			objetivo.text = "OBJETIVO · Revisar el oxígeno"
			if puesto.inspeccion_cercana() == "aire":
				boton_accion.text = "E · Comprobar el oxígeno"
				boton_accion.visible = modal == null
		"decision":
			objetivo.text = "EMERGENCIA · Elige un circuito"
		"cierre":
			objetivo.text = "OBJETIVO · Comer si hace falta y dormir"
			if puesto.terminal_cercana() == "cultivos":
				boton_accion.text = "E · Revisar alimento"
				boton_accion.visible = modal == null
			elif puesto.terminal_cercana() == "dormitorio":
				boton_accion.text = "E · Dormir y cerrar el día"
				boton_accion.visible = modal == null
		"terminado":
			objetivo.text = "DÍA 3 COMPLETADO"
	if boton_accion.visible:
		_ubicar_accion()


func _accion() -> void:
	if modal != null:
		return
	match fase:
		"ir_plantas":
			if puesto.terminal_cercana() == "cultivos":
				_abrir_panel_plantas()
		"ir_oxigeno":
			if puesto.inspeccion_cercana() == "aire":
				_activar_fallo()
		"cierre":
			if puesto.terminal_cercana() == "cultivos":
				_abrir_panel_plantas()
			elif puesto.terminal_cercana() == "dormitorio":
				_solicitar_dormir()


func _abrir_panel_plantas() -> void:
	invernadero_revisado = true
	var datos: Dictionary = recursos.estado()
	var columna := _crear_modal("Sala de Plantas")
	_texto_modal(columna, "Las bandejas, el alimento, el agua y la energía pertenecen al mismo estado persistente de la campaña.", 17)
	if mensaje_panel != "":
		_texto_modal(columna, mensaje_panel, 17, CIAN)
		mensaje_panel = ""
	for cultivo: String in Recursos.CULTIVOS:
		var ficha: Dictionary = Recursos.CULTIVOS[cultivo]
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 10)
		columna.add_child(fila)
		var descripcion := "%s · %d energía + 1 agua · %d s · +%d alimento" % [
			NOMBRES_CULTIVOS[cultivo], ficha.energia, int(ficha.segundos), ficha.alimento]
		var texto := _texto_modal(fila, descripcion, 16)
		texto.custom_minimum_size.x = 520
		var espera: float = datos.bandejas.get(cultivo, -1.0)
		if espera < 0:
			var sembrar := _boton_fila(fila, "Sembrar", _sembrar.bind(cultivo))
			sembrar.disabled = datos.reservas.energia < ficha.energia or datos.reservas.agua < 1 or fase == "cierre"
		elif is_zero_approx(espera):
			var comer := _boton_fila(fila, "Comer", _comer.bind(cultivo))
			comer.disabled = datos.reservas.alimento >= Recursos.LIMITES.alimento
		else:
			_texto_modal(fila, "%d s" % ceili(espera), 16, NARANJA)
	var pie := HBoxContainer.new()
	pie.add_theme_constant_override("separation", 12)
	columna.add_child(pie)
	var volver_texto := "Continuar hacia el oxígeno" if fase == "ir_plantas" else "Volver al recorrido"
	_boton_fila(pie, volver_texto, _cerrar_panel_plantas)


func _sembrar(cultivo: String) -> void:
	if recursos.sembrar(cultivo):
		mensaje_panel = "%s sembrado. El tiempo de crecimiento avanza durante el juego activo." % NOMBRES_CULTIVOS[cultivo]
	else:
		mensaje_panel = "No se pudo sembrar: revisa energía, agua y bandejas disponibles."
	_cerrar_modal()
	_abrir_panel_plantas()


func _comer(cultivo: String) -> void:
	if recursos.comer(cultivo):
		mensaje_panel = "La tripulación comió %s y recuperó alimento." % NOMBRES_CULTIVOS[cultivo].to_lower()
	else:
		mensaje_panel = "Ese cultivo todavía no está listo o la reserva de alimento ya está llena."
	_cerrar_modal()
	_abrir_panel_plantas()


func _cerrar_panel_plantas() -> void:
	_cerrar_modal()
	if fase == "ir_plantas":
		fase = "ir_oxigeno"
		puesto.objetivo_mision = "energia"
		_decir_pluto("Bien. Ahora revisemos el oxígeno antes de continuar con el día.")
	_actualizar_guia()


func _activar_fallo() -> void:
	if fase != "ir_oxigeno":
		return
	fase = "decision"
	puesto.objetivo_mision = ""
	velo_fallo.color.a = 0.38
	var tween := create_tween()
	tween.tween_property(velo_fallo, "color:a", 0.0, 0.65)
	_mostrar_decision()


func _mostrar_decision() -> void:
	var datos: Dictionary = recursos.estado()
	var costo_oxigeno_energia := 7 if sistemas_danados else 6
	var costo_oxigeno_agua := 2 if sistemas_danados else 1
	var costo_tanques := 4 if sistemas_danados else 3
	var columna := _crear_modal("Fallo eléctrico")
	_decir_pluto("Espera… el regulador no responde. La energía disponible solo puede mantener uno de los circuitos: oxígeno o invernadero.")
	_texto_modal(columna, "Elige después de revisar el costo y la consecuencia.", 17)

	var oxigeno := _boton_fila(columna,
		"PRIORIZAR OXÍGENO · -%d energía · -%d agua · -2 alimento\nLlena y estabiliza el oxígeno; activación diaria cumplida." % [costo_oxigeno_energia, costo_oxigeno_agua],
		_elegir_oxigeno)
	oxigeno.custom_minimum_size.y = 72
	oxigeno.disabled = (datos.reservas.energia < costo_oxigeno_energia
		or datos.reservas.agua < costo_oxigeno_agua or datos.reservas.alimento < 2)

	var invernadero := _boton_fila(columna,
		"PRIORIZAR INVERNADERO · -%d energía · -1 agua · -2 oxígeno · +2 alimento\nActiva los tanques de emergencia y asegura el aire de esta noche." % costo_tanques,
		_elegir_invernadero)
	invernadero.custom_minimum_size.y = 72
	invernadero.disabled = (datos.reservas.energia < costo_tanques
		or datos.reservas.agua < 1 or datos.reservas.oxigeno <= 2)

	if oxigeno.disabled and invernadero.disabled:
		_texto_modal(columna, "Las reservas actuales no permiten completar ninguna activación. El aire seguirá sin asegurar.", 17, ROJO)
	_boton_fila(columna, "Volver al recorrido y revisar las reservas", _volver_desde_decision)


func _volver_desde_decision() -> void:
	_cerrar_modal()
	fase = "ir_oxigeno"
	puesto.objetivo_mision = "energia"
	_decir_pluto("El fallo sigue activo. Revisa las reservas y vuelve al sistema de oxígeno para decidir.")


func _elegir_oxigeno() -> void:
	var costo_energia := 7 if sistemas_danados else 6
	var costo_agua := 2 if sistemas_danados else 1
	if not recursos.activar_oxigeno(costo_energia, costo_agua, 2):
		mensaje_panel = "No hay reservas suficientes para priorizar el oxígeno."
		_cerrar_modal()
		_mostrar_decision()
		return
	decision = "oxigeno"
	_cerrar_decision("Oxígeno estabilizado. La cosecha recibió menos energía, pero el aire quedó asegurado por hoy.")


func _elegir_invernadero() -> void:
	var costo_energia := 4 if sistemas_danados else 3
	if not recursos.usar_tanques_emergencia(costo_energia):
		mensaje_panel = "No hay reservas suficientes para activar los tanques de emergencia."
		_cerrar_modal()
		_mostrar_decision()
		return
	decision = "invernadero"
	_cerrar_decision("Invernadero priorizado. Los tanques de emergencia cubrirán el suministro nocturno de hoy.")


func _cerrar_decision(mensaje: String) -> void:
	_cerrar_modal()
	fase = "cierre"
	puesto.objetivo_mision = "dormitorio"
	_decir_pluto(mensaje + " Revisa el alimento y vuelve al dormitorio.")
	_actualizar_hud()
	_actualizar_guia()


func _solicitar_dormir() -> void:
	var datos: Dictionary = recursos.estado()
	if not datos.aire_asegurado:
		_decir_pluto("No podemos dormir: el aire todavía no está asegurado.")
		return
	if datos.reservas.alimento == 0:
		_decir_pluto("No podemos dormir con alimento en cero. Vuelve a Plantas y come una cosecha lista.")
		puesto.objetivo_mision = "cultivos"
		return
	var resultado := _resultado()
	if not modo_prueba:
		descanso_solicitado.emit(resultado)
		_mostrar_fin("Día 3 listo", "El controlador de campaña recibió la solicitud de descanso.")
		return
	var completado: bool = recursos.dormir()
	if completado:
		resultado["estado_despues_de_dormir"] = recursos.estado()
		dia_completado.emit(resultado)
		_mostrar_fin("Día 3 completado", "La prueba local avanzó al día 4 sin reiniciar las reservas.")
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
	if recursos == null or lecturas == null or comida_ui == null:
		return
	var datos: Dictionary = recursos.estado()
	lecturas.actualizar(datos)
	comida_ui.actualizar(datos)
	if datos.derrota != "":
		_mostrar_derrota(datos.derrota)


func _decir_pluto(texto: String) -> void:
	dialogo.decir("Pluto", texto)
	dialogo.show()
	move_child(dialogo, get_child_count() - 1)
	_ubicar_interfaz()


func _ubicar_interfaz() -> void:
	if puesto == null or dialogo == null:
		return
	# Pluto permanece dibujado en Control; la frase se acerca a su posición proyectada
	# y se limita a la pantalla cuando la cámara recorre otra sala.
	var pluto := puesto.proyectar_suelo(Vector2(340, 260))
	dialogo.position = Vector2(
		clampf(pluto.x + 24, 24, 896),
		clampf(pluto.y - 210, 82, 475))


func _ubicar_accion() -> void:
	var suelo := puesto.proyectar_suelo(puesto.punto)
	boton_accion.position = Vector2(
		clampf(suelo.x - boton_accion.size.x / 2.0, 24, 1256 - boton_accion.size.x),
		clampf(suelo.y + 18, 235, 628))


func _mostrar_fin(encabezado: String, texto: String) -> void:
	fase = "terminado"
	puesto.objetivo_mision = ""
	var columna := _crear_modal(encabezado)
	_texto_modal(columna, texto, 20, CIAN)
	_texto_modal(columna, "Decisión: %s. Sistemas heredados: %s." % [
		"priorizar " + decision if decision != "" else "sin decisión",
		"dañados" if sistemas_danados else "protegidos"], 18)
	if modo_prueba:
		_boton_fila(columna, "Reiniciar prueba del Día 3", get_tree().reload_current_scene)


func _mostrar_derrota(motivo: String) -> void:
	if fase == "terminado":
		return
	var textos := {
		"oxigeno_agotado": "El oxígeno llegó a cero.",
		"aire_sin_activar": "Se intentó dormir sin asegurar el aire.",
		"hambre_al_dormir": "Se intentó dormir sin alimento.",
	}
	_mostrar_fin("GAME OVER", textos.get(motivo, "La tripulación no puede continuar."))


func _mostrar_error_de_entrada(datos: Dictionary) -> void:
	_mostrar_error("El Día 3 necesita una partida abierta en el sol 3. Estado recibido: sol %s, en curso: %s." % [
		str(datos.get("sol", "?")), str(datos.get("en_curso", false))])


func _mostrar_error(texto: String) -> void:
	fase = "terminado"
	var columna := _crear_modal("No se puede iniciar el Día 3")
	_texto_modal(columna, texto, 19, ROJO)


func _crear_modal(encabezado: String) -> VBoxContainer:
	_cerrar_modal()
	modal = PanelContainer.new()
	modal.position = Vector2(214, 112)
	modal.size = Vector2(852, 438)
	modal.add_theme_stylebox_override("panel", _estilo(TINTA_CLARA, CIAN, 0.98))
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
	boton.add_theme_stylebox_override("normal", _estilo(TINTA, CIAN, 1.0))
	boton.add_theme_stylebox_override("hover", _estilo(Color("#23495a"), CIAN, 1.0))
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
	boton.add_theme_stylebox_override("normal", _estilo(TINTA, CIAN, 0.96))
	boton.add_theme_stylebox_override("hover", _estilo(Color("#23495a"), CIAN, 1.0))
	boton.pressed.connect(accion)
	return boton


func _estilo(fondo: Color, borde: Color, opacidad: float) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	var color_fondo := fondo
	color_fondo.a = opacidad
	estilo.bg_color = color_fondo
	estilo.border_color = borde
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(7)
	estilo.content_margin_left = 12
	estilo.content_margin_right = 12
	estilo.content_margin_top = 8
	estilo.content_margin_bottom = 8
	return estilo
