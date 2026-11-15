extends Control
## Instrumentos reutilizables del refugio. Consume una copia del estado, sin controlar las reglas.
const ICONOS := preload("res://assets/instrumentos_control.png")
# Regiones normalizadas del atlas de ImageGen. Mantener un pequeño margen de transparencia.
const RAYO := Rect2(0.115, 0.037, 0.29, 0.43)
const BURBUJA := Rect2(0.545, 0.056, 0.385, 0.395)
const GOTA := Rect2(0.085, 0.54, 0.32, 0.435)
const TOMATE := Rect2(0.55, 0.56, 0.37, 0.40)
const APAGADO := Color(0.38, 0.50, 0.58, 0.40)
const ORO := Color("#ffca63")
const CIAN := Color("#8ff1e7")
const AZUL := Color("#75baff")
const ROJO := Color("#ff8274")
const PAPEL := Color("#fff2d9")
var datos := {}
var solo_alimento := false
var en_consola := false
var agua_visible := 0.0:
	set(valor):
		agua_visible = valor
		queue_redraw()
var animacion_agua: Tween

func actualizar(estado: Dictionary) -> void:
	if datos.get("reservas") == estado.reservas:
		if datos.get("polvo") == estado.polvo:
			return
	var nivel := int(estado.reservas.agua) / 6.0
	var cambio_de_agua: bool = datos.is_empty() or datos.reservas.agua != estado.reservas.agua
	if not solo_alimento and cambio_de_agua:
		if datos.is_empty() or not is_inside_tree():
			agua_visible = nivel
		else:
			if is_instance_valid(animacion_agua):
				animacion_agua.kill()
			animacion_agua = create_tween()
			animacion_agua.tween_property(self, "agua_visible", nivel, 0.28)
	datos = estado
	queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	size = Vector2(276, 40) if solo_alimento else Vector2(386, 152)

func _draw() -> void:
	if datos.is_empty():
		return
	var r: Dictionary = datos.reservas
	if en_consola:
		_dibujar_consola(r)
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color("#0c2029"))
	if solo_alimento:
		_rotulo("Comida", Vector2(8, 25), ROJO)
		for i in range(10):
			_icono(TOMATE, Rect2(73 + i * 19, 10, 17, 19), i < r.alimento)
		return
	draw_rect(Rect2(2, 2, 382, 148), Color("#3c7880"), false, 2)
	draw_line(Vector2(144, 4), Vector2(144, 148), Color("#3c7880"), 2)
	draw_line(Vector2(266, 4), Vector2(266, 148), Color("#3c7880"), 2)
	_rotulo("Energía", Vector2(12, 26), ORO)
	for i in range(12):
		_icono(RAYO, Rect2(11 + i * 10, 42, 9, 15), i < r.energia)
	var rendimiento: String = {"bajo": "Alto", "medio": "Medio", "alto": "Bajo", "tormenta": "Pausado"}[datos.polvo]
	_rotulo("%d / 12" % r.energia, Vector2(12, 84), PAPEL)
	_rotulo("Solar: " + rendimiento, Vector2(12, 117), {"bajo": CIAN, "medio": ORO, "alto": ROJO, "tormenta": ROJO}[datos.polvo])
	_rotulo("Oxígeno · O₂", Vector2(154, 26), CIAN)
	draw_rect(Rect2(172, 36, 62, 104), Color("#427d84"), false, 2)
	for i in range(8):
		var sitio := Vector2(183 + (i % 2) * 25, 116 - floori(i / 2.0) * 23)
		_icono(BURBUJA, Rect2(sitio, Vector2(16, 16)), i < r.oxigeno)
	_rotulo("Agua", Vector2(298, 26), AZUL)
	_dibujar_gota(Rect2(292, 39, 63, 85))

func _dibujar_consola(r: Dictionary) -> void:
	# El metal, el cristal y los tres biseles pertenecen al arte de la máquina.
	_rotulo("Oxígeno", Vector2(1, 27), CIAN, 15)
	for i in range(8):
		var sitio := Vector2(7 + (i % 2) * 24, 76 - floori(i / 2.0) * 13)
		_icono(BURBUJA, Rect2(sitio, Vector2(11, 11)), i < r.oxigeno)
	_rotulo("Energía", Vector2(94, 23), ORO, 18)
	_rotulo("%02d / 12" % r.energia, Vector2(202, 24), PAPEL, 20)
	for i in range(12):
		_icono(RAYO, Rect2(92 + i * 16, 38, 11, 17), i < r.energia)
	var estado_solar: Array = {
		"bajo": ["Alto", CIAN], "medio": ["Medio", ORO],
		"alto": ["Bajo", ROJO], "tormenta": ["Pausado", ROJO],
	}[datos.polvo]
	_rotulo("Solar: " + estado_solar[0], Vector2(94, 76), estado_solar[1], 16)
	_rotulo("Agua", Vector2(321, 26), AZUL, 16)
	_dibujar_gota(Rect2(323, 35, 29, 50))

func _dibujar_gota(gota: Rect2) -> void:
	_icono(GOTA, gota, false)
	if agua_visible > 0.0:
		# Dibujar el tramo inferior del mismo sprite conserva la silueta a cada nivel.
		var corte := 1.0 - agua_visible
		var fuente := _region(GOTA)
		fuente.position.y += fuente.size.y * corte
		fuente.size.y *= agua_visible
		gota.position.y += gota.size.y * corte
		gota.size.y *= agua_visible
		draw_texture_rect_region(ICONOS, gota, fuente)

func _region(region: Rect2) -> Rect2:
	var atlas := ICONOS.get_size()
	return Rect2(region.position * atlas, region.size * atlas)

func _icono(region: Rect2, destino: Rect2, activo: bool) -> void:
	draw_texture_rect_region(ICONOS, destino, _region(region), Color.WHITE if activo else APAGADO)

func _rotulo(texto: String, origen: Vector2, color: Color, puntos := 16) -> void:
	draw_string(ThemeDB.fallback_font, origen, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, puntos, color)
