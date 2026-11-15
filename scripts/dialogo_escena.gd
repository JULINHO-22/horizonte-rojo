extends Control
## Subtítulo de escena: nombre, frase y sombra amplia que se funde con el fondo.
const ANCHO := 360.0

var nombre: Label
var frase: Label

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(ANCHO, 165)
	var sombra := TextureRect.new()
	sombra.position = Vector2(-52, -35)
	sombra.size = Vector2(ANCHO + 104, 250)
	sombra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var degradado := Gradient.new()
	degradado.offsets = PackedFloat32Array([0, 0.53, 1])
	degradado.colors = PackedColorArray([Color("#0a121bec"), Color("#0a121bd9"), Color("#0a121b00")])
	var textura := GradientTexture2D.new()
	textura.gradient = degradado
	textura.width = 512
	textura.height = 256
	textura.fill = GradientTexture2D.FILL_RADIAL
	textura.fill_from = Vector2(0.5, 0.46)
	textura.fill_to = Vector2(1.0, 0.46)
	sombra.texture = textura
	sombra.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	add_child(sombra)
	nombre = _linea(0, 18, Color("#b5d9cf"))
	frase = _linea(32, 22, Color("#e7eef0"))
	hide()

func decir(quien: String, texto: String) -> void:
	var encabezado := quien + ":"
	if frase.text != texto or nombre.text != encabezado:
		nombre.text = encabezado
		frase.text = texto
	show()

func _linea(y: float, puntos: int, tinta: Color) -> Label:
	var linea := Label.new()
	linea.position = Vector2(0, y)
	linea.size.x = ANCHO
	linea.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	linea.mouse_filter = Control.MOUSE_FILTER_IGNORE
	linea.add_theme_font_size_override("font_size", puntos)
	linea.add_theme_color_override("font_color", tinta)
	linea.add_theme_color_override("font_outline_color", Color("#0a121b"))
	linea.add_theme_constant_override("outline_size", 4)
	linea.add_theme_constant_override("line_spacing", 5)
	add_child(linea)
	return linea
