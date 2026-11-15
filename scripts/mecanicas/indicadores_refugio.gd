extends Control
## Instrumentos reutilizables del refugio. Consume una copia del estado, sin controlar las reglas.
const RAYO := ["...XX..","..XX...","..X....",".XXXXX.","...XX..","..XX...","..X...."]
const BURBUJA := ["..XXX..",".XXXXX.","XX.XXXX","XXXXXXX","XXXXXXX",".XXXXX.","..XXX.."]
const GOTA := ["...X...","...X...","..XXX..","..XXX..",".XXXXX.","XXXXXXX","XXXXXXX",".XXXXX.","..XXX.."]
const TOMATE := ["..XX...","...X...",".XXXXX.","XX.XXXX","XXXXXXX","XXXXXXX",".XXXXX."]
const ORO := Color("#ffca63")
const CIAN := Color("#8ff1e7")
const AZUL := Color("#75baff")
const ROJO := Color("#ff8274")
const VACIO := Color("#384754")
const PAPEL := Color("#fff2d9")
var datos := {}
var solo_alimento := false

func actualizar(estado: Dictionary) -> void:
	if datos.get("reservas") == estado.reservas:
		if datos.get("polvo") == estado.polvo:
			return
	datos = estado
	queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(276, 40) if solo_alimento else Vector2(386, 152)

func _draw() -> void:
	if datos.is_empty():
		return
	var r: Dictionary = datos.reservas
	draw_rect(Rect2(Vector2.ZERO, size), Color("#0c2029"))
	if solo_alimento:
		_rotulo("Comida", Vector2(8, 25), ROJO)
		for i in range(10):
			_icono(TOMATE, Vector2(73 + i * 19, 12), ROJO, 7 if i < r.alimento else 0)
		return
	draw_rect(Rect2(2, 2, 382, 148), Color("#3c7880"), false, 2)
	draw_line(Vector2(144, 4), Vector2(144, 148), Color("#3c7880"), 2)
	draw_line(Vector2(266, 4), Vector2(266, 148), Color("#3c7880"), 2)
	_rotulo("Energía", Vector2(12, 26), ORO)
	for i in range(12):
		_icono(RAYO, Vector2(12 + i * 10, 43), ORO, 7 if i < r.energia else 0, 1)
	var rendimiento: String = {"bajo": "Alto", "medio": "Medio", "alto": "Bajo", "tormenta": "Pausado"}[datos.polvo]
	_rotulo("%d / 12" % r.energia, Vector2(12, 84), PAPEL)
	_rotulo("Solar: " + rendimiento, Vector2(12, 117), {"bajo": CIAN, "medio": ORO, "alto": ROJO, "tormenta": ROJO}[datos.polvo])
	_rotulo("Oxígeno · O₂", Vector2(154, 26), CIAN)
	draw_rect(Rect2(172, 36, 62, 104), Color("#427d84"), false, 2)
	for i in range(8):
		var sitio := Vector2(183 + (i % 2) * 25, 116 - floori(i / 2.0) * 23)
		_icono(BURBUJA, sitio, CIAN, 7 if i < r.oxigeno else 0)
	_rotulo("Agua", Vector2(298, 26), AZUL)
	_icono(GOTA, Vector2(298, 42), AZUL, ceili(r.agua * 9.0 / 6.0), 8)

func _icono(mascara: Array, origen: Vector2, color: Color, filas_llenas: int, pixel := 2) -> void:
	for y in range(mascara.size()):
		for x in range(mascara[y].length()):
			if mascara[y][x] == "X":
				draw_rect(Rect2(origen + Vector2(x, y) * pixel, Vector2.ONE * pixel),
					color if y >= mascara.size() - filas_llenas else VACIO)

func _rotulo(texto: String, origen: Vector2, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, origen, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, color)
