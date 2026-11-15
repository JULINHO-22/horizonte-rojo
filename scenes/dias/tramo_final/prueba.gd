extends Control
## Banco jugable para el equipo. No usa ni modifica las partidas de campaña.
const Nivel := preload("res://scenes/dias/tramo_final/nivel.tscn")
const Vista := preload("res://scenes/dias/tramo_final/vista.gd")
const Recursos := preload("res://scripts/mecanicas/recursos_mision.gd")
const FINAL_BUENO := preload("res://scenes/final_cumplida.tscn")
const FINAL_EVACUACION := preload("res://scenes/final_incompleta.tscn")
const PERFILES := [
	{"nombre": "Día 4 · Paneles protegidos", "descripcion": "La reparación del día 2 dejó los sistemas disponibles. Hay margen para preparar ambos trabajos.",
		"sol": 4, "reservas": {"energia": 12, "agua": 3, "oxigeno": 7, "alimento": 8}, "danio": false, "refuerzo": false},
	{"nombre": "Día 4 · Sistemas dañados", "descripcion": "El equipo se quedó bajo techo el día 2. Con menos reservas, decidir qué preparar importa más.",
		"sol": 4, "reservas": {"energia": 7, "agua": 1, "oxigeno": 5, "alimento": 4}, "danio": true, "refuerzo": false},
	{"nombre": "Día 5 · Refugio reforzado", "descripcion": "Punto de prueba para misión completada.",
		"sol": 5, "reservas": {"energia": 9, "agua": 3, "oxigeno": 7, "alimento": 6}, "danio": false, "refuerzo": true},
	{"nombre": "Día 5 · Suministros justos", "descripcion": "Punto de prueba para evacuación.",
		"sol": 5, "reservas": {"energia": 9, "agua": 2, "oxigeno": 6, "alimento": 3}, "danio": true, "refuerzo": false},
	{"nombre": "Día 5 · Aire al límite", "descripcion": "Punto de prueba para pérdida de señal.",
		"sol": 5, "reservas": {"energia": 9, "agua": 2, "oxigeno": 4, "alimento": 3}, "danio": true, "refuerzo": false},
]
var _pantalla: Control
var _recursos: Recursos

func _ready() -> void:
	_menu()

func _menu() -> void:
	_limpiar()
	_pantalla = Control.new()
	add_child(_pantalla)
	var fondo := TextureRect.new()
	fondo.texture = PuestoUmbra.SENDERO
	fondo.size = Vector2(1280, 720)
	fondo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_pantalla.add_child(fondo)
	var panel := Vista.placa(_pantalla, Rect2(110, 58, 1060, 603))
	Vista.rotulo(panel, "Horizonte Rojo", Rect2(38, 24, 970, 54), 40, Vista.PAPEL)
	Vista.rotulo(panel, "Días 4 y 5  /  Elige un punto de entrada", Rect2(40, 83, 960, 41), 22, Vista.MENTA)
	for i in range(PERFILES.size()):
		var perfil: Dictionary = PERFILES[i]
		var y := 143 + i * 82
		Vista.boton(panel, perfil.nombre, Rect2(40, y, 355, 54), iniciar.bind(i))
		Vista.rotulo(panel, perfil.descripcion, Rect2(421, y + 4, 591, 64), 19, Vista.PAPEL)
	Vista.rotulo(panel, "WASD o flechas para caminar   ·   Toca o arrastra sobre el escenario   ·   Espacio como alternativa   ·   M para el plano",
		Rect2(40, 557, 965, 35), 17, Vista.MENTA)

func iniciar(indice: int) -> void:
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
	Vista.rotulo(_pantalla, "Fin del día 4", Rect2(410, 247, 500, 72), 44, Vista.PAPEL).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var detalle := "El refugio está reforzado." if historial.refugio_reforzado else "La base conserva su protección original."
	Vista.rotulo(_pantalla, detalle, Rect2(380, 331, 560, 43), 22, Vista.MENTA).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Vista.boton(_pantalla, "Comenzar el día 5", Rect2(509, 424, 302, 49), _montar.bind(historial)).grab_focus()

func _derrota() -> void:
	_limpiar()
	_pantalla = ColorRect.new()
	_pantalla.color = Color.BLACK
	_pantalla.size = Vector2(1280, 720)
	add_child(_pantalla)
	Vista.rotulo(_pantalla, "Game Over", Rect2(440, 280, 400, 90), 52, Vista.PAPEL).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Vista.boton(_pantalla, "Volver a probar", Rect2(523, 394, 234, 49), _menu).grab_focus()

func _limpiar() -> void:
	if is_instance_valid(_pantalla):
		remove_child(_pantalla)
		_pantalla.queue_free()
