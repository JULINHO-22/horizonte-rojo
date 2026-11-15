extends Control
## Banco jugable para el equipo. No usa ni modifica las partidas de campaña.
const Nivel := preload("res://scenes/dias/tramo_final/nivel.tscn")
const Vista := preload("res://scenes/dias/tramo_final/vista.gd")
const Recursos := preload("res://scripts/mecanicas/recursos_mision.gd")
const FINAL_BUENO := preload("res://scenes/final_cumplida.tscn")
const FINAL_EVACUACION := preload("res://scenes/final_incompleta.tscn")
const PERFILES := [
	{"clave": "s4_res", "sol": 4, "reservas": {"energia": 12, "agua": 3, "oxigeno": 7, "alimento": 8}, "danio": false, "refuerzo": false},
	{"clave": "s4_dan", "sol": 4, "reservas": {"energia": 7, "agua": 1, "oxigeno": 5, "alimento": 4}, "danio": true, "refuerzo": false},
	{"clave": "s5_ref", "sol": 5, "reservas": {"energia": 9, "agua": 3, "oxigeno": 7, "alimento": 6}, "danio": false, "refuerzo": true},
	{"clave": "s5_jus", "sol": 5, "reservas": {"energia": 10, "agua": 2, "oxigeno": 7, "alimento": 3}, "danio": true, "refuerzo": false},
	{"clave": "s5_ox", "sol": 5, "reservas": {"energia": 9, "agua": 2, "oxigeno": 4, "alimento": 3}, "danio": true, "refuerzo": false},
]
const TEXTO := Color("#e4ecef")
const ACENTO := Color("#9cbfba")
const PIZARRA := Color("#243440")

var _pantalla: Control
var _recursos: Recursos
var _selector: Control
var _dia_elegido := 4
var _modo_anterior := Node.PROCESS_MODE_INHERIT

func _ready() -> void:
	_menu()

func _input(evento: InputEvent) -> void:
	if evento is InputEventKey and evento.pressed and not evento.echo:
		if evento.ctrl_pressed and evento.shift_pressed and evento.physical_keycode == KEY_M:
			get_viewport().set_input_as_handled()
			if is_instance_valid(_selector) and is_instance_valid(_pantalla):
				_cerrar_menu()
			elif not is_instance_valid(_selector):
				_menu()

func _menu() -> void:
	if is_instance_valid(_pantalla) and not is_instance_valid(_selector):
		_modo_anterior = _pantalla.process_mode
		_pantalla.process_mode = Node.PROCESS_MODE_DISABLED
	_elegir_dia(_recursos.estado().sol if is_instance_valid(_pantalla) and _recursos != null else _dia_elegido)

func _elegir_dia(dia: int) -> void:
	_dia_elegido = dia
	if is_instance_valid(_selector):
		remove_child(_selector)
		_selector.queue_free()
	_selector = Control.new()
	_selector.size = Vector2(1280, 720)
	add_child(_selector)
	var fondo := TextureRect.new()
	fondo.texture = PuestoUmbra.SENDERO
	fondo.size = _selector.size
	fondo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_selector.add_child(fondo)
	var sombra := ColorRect.new()
	sombra.color = Color(0.07, 0.12, 0.17, 0.66)
	sombra.size = _selector.size
	_selector.add_child(sombra)
	Vista.rotulo(_selector, I18n.t("portada.titulo"), Rect2(64, 42, 730, 78), 55, TEXTO)
	Vista.rotulo(_selector, I18n.t("prueba.sub"), Rect2(68, 128, 850, 42), 26, TEXTO)
	_boton_brief(_selector, I18n.t("prueba.s4.btn"), Rect2(68, 198, 310, 53), _elegir_dia.bind(4), dia == 4)
	_boton_brief(_selector, I18n.t("prueba.s5.btn"), Rect2(392, 198, 310, 53), _elegir_dia.bind(5), dia == 5)
	var resumen := I18n.t("prueba.s4.desc") if dia == 4 else I18n.t("prueba.s5.desc")
	Vista.rotulo(_selector, resumen, Rect2(70, 278, 1140, 52), 24, TEXTO)
	var columna := 0
	for i in range(PERFILES.size()):
		var perfil: Dictionary = PERFILES[i]
		if perfil.sol != dia:
			continue
		var x := 68 + columna * 386
		var tarjeta := Vista.placa(_selector, Rect2(x, 348, 372, 250))
		tarjeta.add_theme_stylebox_override("panel", Vista._estilo(PIZARRA, Color("#607986")))
		Vista.rotulo(tarjeta, I18n.t("prueba.perf.%s.t" % perfil.clave), Rect2(22, 20, 328, 39), 26, ACENTO)
		Vista.rotulo(tarjeta, I18n.t("prueba.perf.%s.n" % perfil.clave), Rect2(22, 75, 328, 92), 20, TEXTO)
		_boton_brief(tarjeta, I18n.t("prueba.jugar"), Rect2(22, 181, 328, 46), iniciar.bind(i))
		columna += 1
	Vista.rotulo(_selector, I18n.t("prueba.atajo"), Rect2(68, 652, 630, 36), 19, TEXTO)
	if is_instance_valid(_pantalla):
		_boton_brief(_selector, I18n.t("prueba.continuar"), Rect2(947, 637, 265, 50), _cerrar_menu).grab_focus()

func _boton_brief(padre: Control, texto: String, zona: Rect2, accion: Callable, activo := false) -> Button:
	var boton := Vista.boton(padre, texto, zona, accion)
	boton.add_theme_color_override("font_color", PIZARRA if activo else TEXTO)
	boton.add_theme_color_override("font_hover_color", PIZARRA)
	boton.add_theme_color_override("font_pressed_color", PIZARRA)
	boton.add_theme_stylebox_override("normal", Vista._estilo(ACENTO if activo else PIZARRA, ACENTO))
	boton.add_theme_stylebox_override("hover", Vista._estilo(Color("#c0d8d4"), ACENTO))
	boton.add_theme_stylebox_override("pressed", Vista._estilo(ACENTO, TEXTO))
	boton.add_theme_stylebox_override("focus", Vista._estilo(Color.TRANSPARENT, TEXTO))
	return boton

func _cerrar_menu() -> void:
	if is_instance_valid(_selector):
		remove_child(_selector)
		_selector.queue_free()
		_selector = null
	if is_instance_valid(_pantalla):
		_pantalla.process_mode = _modo_anterior

func iniciar(indice: int) -> void:
	_cerrar_menu()
	var perfil: Dictionary = PERFILES[indice]
	_recursos = Recursos.new()
	var guardado := _recursos.guardar_estado()
	guardado.sol = perfil.sol
	guardado.reservas = perfil.reservas.duplicate()
	_recursos.restaurar_estado(guardado)
	_recursos.iniciar_sol("bajo")
	_montar({"sistemas_danados": perfil.danio, "refugio_reforzado": perfil.refuerzo})

func _montar(historial: Dictionary) -> void:
	_limpiar()
	var nivel := Nivel.instantiate()
	nivel.configurar(_recursos, historial)
	nivel.terminado.connect(_resultado, CONNECT_DEFERRED)
	_pantalla = nivel
	add_child(nivel)

func _resultado(resultado: String, historial: Dictionary) -> void:
	match resultado:
		"dia4_listo":
			if _recursos.dormir():
				_recursos.iniciar_sol("bajo")
				_mostrar_noche(historial)
			else:
				_derrota()
		"derrota":
			_derrota()
		"mision_cumplida", "evacuacion":
			_limpiar()
			_pantalla = (FINAL_BUENO if resultado == "mision_cumplida" else FINAL_EVACUACION).instantiate()
			add_child(_pantalla)

func _mostrar_noche(historial: Dictionary) -> void:
	_limpiar()
	_pantalla = ColorRect.new()
	_pantalla.color = Color("#0b1620")
	_pantalla.size = Vector2(1280, 720)
	add_child(_pantalla)
	Vista.rotulo(_pantalla, I18n.t("prueba.fin_s4"), Rect2(410, 247, 500, 72), 44, Vista.PAPEL).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var detalle := I18n.t("tramo.nucleo_protegido") if historial.refugio_reforzado else I18n.t("tramo.nucleo_original")
	Vista.rotulo(_pantalla, detalle, Rect2(380, 331, 560, 43), 22, Vista.MENTA).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Vista.boton(_pantalla, I18n.t("prueba.s5_btn"), Rect2(509, 424, 302, 49), _montar.bind(historial)).grab_focus()

func _derrota() -> void:
	_limpiar()
	_pantalla = ColorRect.new()
	_pantalla.color = Color.BLACK
	_pantalla.size = Vector2(1280, 720)
	add_child(_pantalla)
	Vista.rotulo(_pantalla, I18n.t("ui.game_over"), Rect2(440, 280, 400, 90), 52, Vista.PAPEL).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Vista.boton(_pantalla, I18n.t("prueba.volver"), Rect2(523, 394, 234, 49), _menu).grab_focus()

func _limpiar() -> void:
	if is_instance_valid(_pantalla):
		remove_child(_pantalla)
		_pantalla.queue_free()
