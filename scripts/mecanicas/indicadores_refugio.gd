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

func actualizar(estado: Dictionary) -> void:
	if datos.get("reservas") == estado.reservas:
		if datos.get("polvo") == estado.polvo:
			return
	datos = estado
	queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(386, 147)

func _draw() -> void:
	if datos.is_empty():
		return
	var r: Dictionary = datos.reservas
	draw_rect(Rect2(Vector2.ZERO, size), Color("#101a23ee"))
	draw_line(Vector2(0, 1), Vector2(size.x, 1), Color("#486975"), 2)
	_rotulo("Energía   %d/12" % r.energia, Vector2(14, 24), ORO)
	var rendimiento: String = {"bajo": "Alto", "medio": "Medio", "alto": "Bajo", "tormenta": "Pausado"}[datos.polvo]
	_rotulo("Solar: " + rendimiento, Vector2(247, 24), PAPEL)
	_fila(RAYO, 12, r.energia, Vector2(15, 31), ORO)
	_rotulo("Oxígeno   %d/8" % r.oxigeno, Vector2(14, 73), CIAN)
	_fila(BURBUJA, 8, r.oxigeno, Vector2(15, 81), CIAN)
	_rotulo("Agua", Vector2(247, 73), AZUL)
	_icono(GOTA, Vector2(297, 54), AZUL, ceili(r.agua * 9.0 / 6.0), 3)
	_rotulo("Alimento", Vector2(14, 130), ROJO)
	_fila(TOMATE, 10, r.alimento, Vector2(109, 116), ROJO)

func _fila(mascara: Array, maximo: int, llenos: int, origen: Vector2, color: Color) -> void:
	for i in range(maximo):
		_icono(mascara, origen + Vector2(i * 23, 0), color, mascara.size() if i < llenos else 0)

func _icono(mascara: Array, origen: Vector2, color: Color, filas_llenas: int, pixel := 2) -> void:
	for y in range(mascara.size()):
		for x in range(mascara[y].length()):
			if mascara[y][x] == "X":
				draw_rect(Rect2(origen + Vector2(x, y) * pixel, Vector2.ONE * pixel),
					color if y >= mascara.size() - filas_llenas else VACIO)

func _rotulo(texto: String, origen: Vector2, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, origen, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, color)
