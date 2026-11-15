extends Control
## Consulta común de la partida. El controlador pausa el recorrido mientras está abierta.
signal cerrar_solicitado

const Recursos := preload("res://scripts/mecanicas/recursos_mision.gd")
const Instrumentos := preload("res://scripts/mecanicas/indicadores_refugio.gd")
const ARTE := preload("res://assets/tablet_umbra.png")
const MARCO := Rect2(180, 92, 920, 536)
const FICHAS := [
	["energia", "tablet.ficha.energia", Instrumentos.RAYO], ["oxigeno", "tablet.ficha.oxigeno", Instrumentos.BURBUJA],
	["agua", "tablet.ficha.agua", Instrumentos.GOTA], ["alimento", "tablet.ficha.comida", Instrumentos.TOMATE],
]
var estado: Dictionary

func _ready() -> void:
	size = Vector2(1280, 720)
	var velo := ColorRect.new()
	velo.color = Color("#100c0be0")
	velo.size = size
	add_child(velo)
	var marco := TextureRect.new()
	marco.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	marco.texture = ARTE
	marco.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	marco.position = MARCO.position
	marco.size = MARCO.size
	add_child(marco)

	_rotulo(I18n.t("tablet.titulo"), Vector2(311, 181), 32)
	_rotulo(I18n.tf("soles.sol_num", [estado.sol]), Vector2(314, 224), 17, Color("#dfaa78"))
	var cerrar := Button.new()
	cerrar.text = I18n.t("tablet.cerrar")
	cerrar.position = Vector2(802, 185)
	cerrar.custom_minimum_size = Vector2(158, 40)
	cerrar.pressed.connect(cerrar_solicitado.emit)
	add_child(cerrar)
	cerrar.grab_focus()

	for i in range(FICHAS.size()):
		var ficha: Array = FICHAS[i]
		var x := 314.0 + (i % 2) * 350.0
		var y := 282.0 + floori(i / 2.0) * 104.0
		var icono := AtlasTexture.new()
		icono.atlas = Instrumentos.ICONOS
		var region: Rect2 = ficha[2]
		var atlas := icono.atlas.get_size()
		icono.region = Rect2(region.position * atlas, region.size * atlas)
		var imagen := TextureRect.new()
		imagen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		imagen.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		imagen.texture = icono
		imagen.position = Vector2(x, y + 5)
		imagen.size = Vector2(40, 47)
		imagen.mouse_filter = MOUSE_FILTER_IGNORE
		add_child(imagen)
		_rotulo(I18n.t(ficha[1]), Vector2(x + 55, y), 19, Color("#e1c7ae"))
		_rotulo("%d / %d" % [estado.reservas[ficha[0]], Recursos.LIMITES[ficha[0]]], Vector2(x + 55, y + 25), 29)
	var carga := I18n.t("tablet.carga." + estado.polvo)
	var aire := I18n.t("tablet.aire_ok" if estado.aire_asegurado else "tablet.aire_falta")
	_rotulo(I18n.tf("tablet.estado", [aire, carga, estado.hielo]), Vector2(314, 501), 18, Color("#dfaa78"))

func _rotulo(texto: String, origen: Vector2, puntos: int, tinta := Color("#fff2db")) -> void:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.position = origen
	etiqueta.mouse_filter = MOUSE_FILTER_IGNORE
	etiqueta.add_theme_color_override("font_color", tinta)
	etiqueta.add_theme_font_size_override("font_size", puntos)
	add_child(etiqueta)
