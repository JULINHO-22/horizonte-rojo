extends Control

signal reinicio_solicitado

const AccionEscena := preload("res://scripts/accion_escena.gd")
const ARTE := preload("res://assets/umbra_sin_senal.png")
const MOTIVOS := {
	"oxigeno_agotado": "derrota.motivo.oxigeno_agotado",
	"aire_sin_activar": "derrota.motivo.aire_sin_activar",
	"hambre_al_dormir": "derrota.motivo.hambre_al_dormir",
}
var sol := 1
var motivo := ""

func _ready() -> void:
	size = Vector2(1280, 720)
	var fondo := TextureRect.new()
	fondo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fondo.texture = ARTE
	fondo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fondo.size = size
	fondo.pivot_offset = size * 0.5
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fondo)
	var degradado := Gradient.new()
	degradado.offsets = PackedFloat32Array([0.0, 0.42, 0.78, 1.0])
	degradado.colors = PackedColorArray([Color("#110c0ced"), Color("#110c0cd0"), Color("#110c0c30"), Color("#110c0c00")])
	var sombra := GradientTexture2D.new()
	sombra.gradient = degradado
	sombra.width = 1280
	sombra.height = 8
	var velo := TextureRect.new()
	velo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	velo.texture = sombra
	velo.size = size
	velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(velo)

	_rotulo(I18n.tf("derrota.encabezado", [sol]), Rect2(90, 166, 570, 27), 18, Color("#ffbf86"))
	_rotulo(I18n.t("derrota.titulo_s5" if sol == 5 else "derrota.titulo"), Rect2(87, 211, 638, 89), 57)
	var clave_motivo: String = MOTIVOS.get(motivo, "")
	var detalle: String = I18n.t(clave_motivo) if not clave_motivo.is_empty() else I18n.t("derrota.detalle_s5" if sol == 5 else "derrota.detalle_def")
	_rotulo(detalle, Rect2(91, 315, 480, 130), 22)

	var volver := Button.new()
	volver.text = I18n.t("derrota.volver")
	volver.position = Vector2(87, 495)
	volver.size = Vector2(360, 48)
	volver.alignment = HORIZONTAL_ALIGNMENT_LEFT
	volver.add_theme_font_size_override("font_size", 22)
	AccionEscena.aplicar(volver)
	volver.pressed.connect(reinicio_solicitado.emit)
	add_child(volver)
	volver.grab_focus()

	modulate.a = 0.0
	var entrada := create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
	entrada.tween_property(self, "modulate:a", 1.0, 0.55)
	entrada.tween_property(fondo, "scale", Vector2.ONE * 1.035, 4.0)

func _unhandled_key_input(evento: InputEvent) -> void:
	if evento is InputEventKey and evento.pressed and not evento.echo and evento.physical_keycode == KEY_E:
		get_viewport().set_input_as_handled()
		reinicio_solicitado.emit()

func _rotulo(texto: String, rect: Rect2, puntos: int, color := Color("#fff1db")) -> void:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.position = rect.position
	etiqueta.size = rect.size
	etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	etiqueta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	etiqueta.add_theme_color_override("font_color", color)
	etiqueta.add_theme_font_size_override("font_size", puntos)
	add_child(etiqueta)
