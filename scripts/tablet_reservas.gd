extends Control
## Instrumentos del panel original, accesibles desde cualquier zona de la campaña.
signal cerrar_solicitado

const Recursos := preload("res://scripts/mecanicas/recursos_mision.gd")
const FONDO := Color("#101d25")
const BORDE := Color("#486168")
const PISTA := Color("#294149")
const TITULO := Color("#f8eddb")
const TEXTO := Color("#b9ccd1")
const AMBAR := Color("#d6c48e")
const MENTA := Color("#8de3d7")
const AZUL := Color("#81c4f2")
const CRISTAL := Color("#0d161e")
const ANCHO := 944.0
const ALTO := 486.0
const SOLAR := {
	"bajo": ["Carga solar alta", "Está llegando bastante luz a los paneles.", MENTA],
	"medio": ["Carga solar media", "El polvo deja pasar parte de la luz.", AMBAR],
	"alto": ["Carga solar baja", "El polvo bloquea buena parte de la luz.", Color("#e2a3a8")],
	"tormenta": ["Carga solar detenida", "La tormenta impide recargar la batería.", Color("#e2a3a8")],
}

var estado: Dictionary

func _ready() -> void:
	size = Vector2(ANCHO, ALTO)
	position = (get_viewport_rect().size - size) * 0.5
	# El velo bloquea clics hacia el escenario mientras el panel está abierto.
	var velo := ColorRect.new()
	velo.color = Color(0.01, 0.03, 0.06, 0.68)
	velo.position = -position
	velo.size = get_viewport_rect().size
	add_child(velo)
	move_child(velo, 0)
	# El marco y los instrumentos comparten una capa encima del velo.
	var superficie := Control.new()
	superficie.mouse_filter = MOUSE_FILTER_IGNORE
	superficie.draw.connect(_dibujar.bind(superficie))
	add_child(superficie)

	_etiqueta("Estado del refugio", Rect2(32, 22, 600, 45), 33, TITULO)
	_etiqueta("Tablet  /  Sol %d de %d" % [estado.sol, Recursos.ULTIMO_SOL],
		Rect2(34, 68, 600, 26), 17, TEXTO)
	var cerrar := _boton("Cerrar · Q / Esc", Rect2(755, 28, 157, 42), cerrar_solicitado.emit)
	cerrar.grab_focus()

	_etiqueta("Energía", Rect2(34, 113, 340, 32), 23, AMBAR)
	_etiqueta("Oxígeno", Rect2(399, 113, 240, 32), 23, MENTA, HORIZONTAL_ALIGNMENT_CENTER)
	_etiqueta("Agua", Rect2(657, 113, 255, 32), 23, AZUL, HORIZONTAL_ALIGNMENT_CENTER)

	var reserva: Dictionary = estado.reservas
	_valor(reserva.energia, Recursos.LIMITES.energia, Rect2(34, 312, 330, 52))
	_valor(reserva.oxigeno, Recursos.LIMITES.oxigeno, Rect2(399, 312, 240, 52), HORIZONTAL_ALIGNMENT_CENTER)
	_valor(reserva.agua, Recursos.LIMITES.agua, Rect2(657, 312, 255, 52), HORIZONTAL_ALIGNMENT_CENTER)
	var solar: Array = SOLAR[estado.polvo]
	_etiqueta(solar[0], Rect2(34, 366, 331, 27), 19, solar[2])
	_etiqueta(solar[1], Rect2(34, 392, 330, 32), 17, TEXTO)
	var aire := "El aire ya está asegurado por hoy." if estado.aire_asegurado else "La reserva baja hasta que prepares más oxígeno."
	_etiqueta(aire, Rect2(405, 367, 228, 60), 17, TEXTO, HORIZONTAL_ALIGNMENT_CENTER)
	_etiqueta("Úsala para producir oxígeno y cuidar las plantas.",
		Rect2(667, 367, 235, 60), 17, TEXTO, HORIZONTAL_ALIGNMENT_CENTER)
	_etiqueta("Comida  %d / %d" % [reserva.alimento, Recursos.LIMITES.alimento],
		Rect2(34, 440, 350, 28), 19, AMBAR)
	_etiqueta("Hielo  %d" % estado.hielo, Rect2(659, 440, 253, 28), 19, AZUL, HORIZONTAL_ALIGNMENT_RIGHT)

	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.16)

func _dibujar(lienzo: Control) -> void:
	var marco := StyleBoxFlat.new()
	marco.bg_color = FONDO
	marco.border_color = BORDE
	marco.set_border_width_all(1)
	marco.set_corner_radius_all(12)
	marco.shadow_color = Color(0, 0, 0, 0.45)
	marco.shadow_size = 14
	lienzo.draw_style_box(marco, Rect2(Vector2.ZERO, size))
	for y in [98, 429]:
		lienzo.draw_line(Vector2(32, y), Vector2(912, y), BORDE, 1.0)
	for x in [382, 648]:
		lienzo.draw_line(Vector2(x, 112), Vector2(x, 406), PISTA, 1.0)
	_dibujar_bateria(lienzo, estado.reservas.energia)
	_dibujar_oxigeno(lienzo, estado.reservas.oxigeno)
	_dibujar_agua(lienzo, estado.reservas.agua)

func _dibujar_bateria(lienzo: Control, energia: int) -> void:
	var cantidad: int = Recursos.LIMITES.energia
	var ficha := StyleBoxFlat.new()
	ficha.bg_color = CRISTAL
	ficha.set_corner_radius_all(6)
	lienzo.draw_style_box(ficha, Rect2(34, 206, 330, 62))
	var forma := PackedVector2Array([
		Vector2(10, 0), Vector2(20, 0), Vector2(13, 12), Vector2(21, 12),
		Vector2(4, 30), Vector2(9, 16), Vector2(1, 16),
	])
	for indice in range(cantidad):
		var rayo := Transform2D(0.0, Vector2(42 + indice * 26, 223)) * forma
		var color := AMBAR if indice < energia else PISTA
		lienzo.draw_colored_polygon(rayo, color)
		rayo.append(rayo[0])
		lienzo.draw_polyline(rayo, color, 1.0, true)

func _dibujar_oxigeno(lienzo: Control, oxigeno: int) -> void:
	var tanque := StyleBoxFlat.new()
	tanque.bg_color = CRISTAL
	tanque.border_color = BORDE
	tanque.set_border_width_all(1)
	tanque.set_corner_radius_all(22)
	lienzo.draw_style_box(tanque, Rect2(465, 167, 108, 140))
	for indice in range(Recursos.LIMITES.oxigeno):
		var centro := Vector2(499 + (indice % 2) * 40, 284 - floorf(indice / 2.0) * 31)
		var color := MENTA if indice < oxigeno else PISTA
		lienzo.draw_circle(centro, 11, color, false, 1.5, true)
		lienzo.draw_circle(centro, 6.5, color, true, -1.0, true)

func _dibujar_agua(lienzo: Control, agua: int) -> void:
	var cima := Vector2(784, 168)
	var fondo := Vector2(784, 306)
	var contorno := PackedVector2Array()
	for indice in range(25):
		var t := indice / 24.0
		contorno.append(cima.bezier_interpolate(Vector2(805, 198), Vector2(874, 291), fondo, t))
	for indice in range(1, 25):
		var t := indice / 24.0
		contorno.append(fondo.bezier_interpolate(Vector2(694, 291), Vector2(763, 198), cima, t))
	lienzo.draw_colored_polygon(contorno, CRISTAL)
	if agua > 0:
		var nivel := lerpf(fondo.y, cima.y, float(agua) / Recursos.LIMITES.agua)
		var limite := PackedVector2Array([Vector2(720, nivel), Vector2(848, nivel),
			Vector2(848, fondo.y + 1), Vector2(720, fondo.y + 1)])
		for relleno in Geometry2D.intersect_polygons(contorno, limite):
			lienzo.draw_colored_polygon(relleno, Color("#377aab"))
	lienzo.draw_polyline(contorno, AZUL, 2.0, true)

func _valor(actual: int, maximo: int, rect: Rect2, alineacion := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	_etiqueta("%d de %d" % [actual, maximo], rect, 34, TITULO, alineacion)

func _etiqueta(texto: String, rect: Rect2, puntos: int, color: Color,
		alineacion := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.horizontal_alignment = alineacion
	etiqueta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	etiqueta.add_theme_font_size_override("font_size", puntos)
	etiqueta.add_theme_color_override("font_color", color)
	etiqueta.position = rect.position
	etiqueta.size = rect.size
	add_child(etiqueta)

func _boton(texto: String, rect: Rect2, accion: Callable) -> Button:
	var boton := Button.new()
	boton.text = texto
	boton.add_theme_font_size_override("font_size", 17)
	boton.add_theme_color_override("font_color", TITULO)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#1b3038")
	normal.border_color = BORDE
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(6)
	var resalte := normal.duplicate() as StyleBoxFlat
	resalte.bg_color = Color("#29464d")
	resalte.border_color = MENTA
	var foco := resalte.duplicate() as StyleBoxFlat
	foco.draw_center = false
	boton.add_theme_stylebox_override("normal", normal)
	boton.add_theme_stylebox_override("hover", resalte)
	boton.add_theme_stylebox_override("pressed", resalte)
	boton.add_theme_stylebox_override("focus", foco)
	boton.position = rect.position
	boton.size = rect.size
	boton.pressed.connect(accion)
	add_child(boton)
	return boton
