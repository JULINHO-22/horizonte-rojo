extends Control
## Componentes de las vistas cercanas de equipos y bandejas.

const AccionEscena := preload("res://scripts/accion_escena.gd")
const PAPEL := Color("#fff1db")
const ORO := Color("#ffcd91")
const AGUA := Color("#a2e5ff")


func _imagen(textura: Texture2D, marco: Rect2) -> TextureRect:
	var imagen := TextureRect.new()
	imagen.texture = textura
	imagen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagen.position = marco.position
	imagen.size = marco.size
	imagen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(imagen)
	return imagen


func _texto(contenido: String, marco: Rect2, tamano: int, color: Color,
		alineacion := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var rotulo := Label.new()
	rotulo.text = contenido
	rotulo.position = marco.position
	rotulo.size = marco.size
	rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rotulo.horizontal_alignment = alineacion
	rotulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rotulo.add_theme_font_size_override("font_size", tamano)
	rotulo.add_theme_color_override("font_color", color)
	rotulo.add_theme_color_override("font_outline_color", Color("#1b1114"))
	rotulo.add_theme_constant_override("outline_size", 7)
	add_child(rotulo)
	return rotulo


func _boton(contenido: String, marco: Rect2, tamano: int, al_pulsar: Callable = Callable()) -> Button:
	var control := Button.new()
	control.text = contenido
	control.position = marco.position
	control.size = marco.size
	control.focus_mode = Control.FOCUS_NONE
	control.add_theme_font_size_override("font_size", tamano)
	AccionEscena.aplicar(control)
	if al_pulsar.is_valid():
		control.pressed.connect(al_pulsar)
	add_child(control)
	return control


func _sombra_superior(alto := 154.0) -> void:
	var degradado := Gradient.new()
	degradado.colors = PackedColorArray([Color("#160f16e8"), Color("#160f1600")])
	var textura := GradientTexture2D.new()
	textura.gradient = degradado
	textura.fill_to = Vector2(0, 1)
	_imagen(textura, Rect2(0, 0, size.x, alto))
