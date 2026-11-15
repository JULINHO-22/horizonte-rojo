extends PuestoUmbra

const REFUGIO_SOLAR := preload("res://assets/dias/dia_5/nucleo_radiacion.png")
const SUELO_PROTEGIDO := 319.0
var zona := "base"
var blancos: Dictionary = {}
var carga := ""
var paneles := 0
var impacto := 0.0
var lecturas: Array[String] = []
var compuerta := 0.0

func entrar(destino: String, sitio: Vector2) -> void:
	zona = destino
	interior = zona == "base"
	campo = zona == "hielo"
	sondeo = false
	cielo_sereno = true
	laboratorio_activo = true
	escala_visual = 720.0 / (527.0 if interior else 385.0)
	ancho_visible = 1280.0 / escala_visual
	scale = Vector2.ONE * escala_visual
	punto = sitio
	velocidad = Vector2.ZERO
	caminando = false
	actualizar_camara(2.0)
	queue_redraw()

func transitable(destino: Vector2) -> bool:
	if zona == "refugio":
		return is_equal_approx(destino.y, SUELO) and destino.x >= 42 and destino.x <= ancho_visible - 42
	return super(destino)

func proyectar_suelo(sitio: Vector2) -> Vector2:
	if zona == "refugio":
		return Vector2(sitio.x, SUELO_PROTEGIDO) * escala_visual
	return super(sitio)

func _origen_mundo() -> Vector2:
	return Vector2.ZERO if zona == "refugio" else super()

func _draw() -> void:
	if zona == "refugio":
		_dibujar_refugio()
	else:
		super()
		if zona == "hielo":
			_dibujar_reconocimiento()
	if not carga.is_empty():
		var ancla := proyectar_suelo(punto) / escala_visual
		var alto := 52.0 if interior else 27.0
		var apoyo := ancla + Vector2(-12.0 if direccion_izquierda else 12.0, -alto)
		_dibujar_objeto(CAJA_CERRADA, apoyo, 28.0 if interior else 16.0)
		if carga == "hielo":
			draw_circle(apoyo - Vector2(0, 9), 2.4, LUZ, true, -1.0, true)
	if plano:
		return
	for id: String in blancos:
		_dibujar_marca(blancos[id])

func _dibujar_refugio() -> void:
	var marco := Rect2(0, 0, ancho_visible, 385)
	draw_texture_rect(REFUGIO_SOLAR, marco, false)
	var separacion := (1.0 - compuerta) * 10.0
	if separacion > 0.0:
		var junta := ancho_visible * 0.5
		draw_rect(Rect2(junta - separacion * 0.5, 171, separacion, 122), Color("#172124"))
		draw_line(Vector2(junta - separacion * 0.5, 172), Vector2(junta - separacion * 0.5, 292), Color("#6d7373"), 1.0)
	if impacto > 0:
		draw_rect(marco, Color(0.38, 0.08, 0.06, impacto * 0.28))
		draw_rect(marco, Color(0.01, 0.04, 0.08, impacto * 0.44))
	for i in range(3):
		var x := 256.0 + i * 84.0
		var led := Color("#7ee6d8") if i < paneles else Color("#ed9b55")
		draw_circle(Vector2(x, 127), 2.5, led, true, -1.0, true)
	_sprite(IRIS, Vector2(445, SUELO_PROTEGIDO), 52)
	_sprite(TEO_NORMAL, Vector2(582, SUELO_PROTEGIDO), 51)
	_sprite(DRON, Vector2(127, SUELO_PROTEGIDO), 30)
	var andando := NORA_PASOS if caminando else NORA
	_sprite(andando, Vector2(punto.x, SUELO_PROTEGIDO), 51, 0, direccion_izquierda,
		int(paso * 8) if caminando else -1)

func _dibujar_reconocimiento() -> void:
	draw_set_transform(_origen_mundo(), 0, Vector2.ONE * _zoom_mundo())
	_sprite(PERCY, Vector2(485, SUELO), 35.0)
	if lecturas.has("escarcha"):
		_dibujar_objeto(NUCLEO_HIELO, SONDEOS[0] + Vector2(-11, 1), 6.0)
	if lecturas.has("veta"):
		_dibujar_objeto(NUCLEO_HIELO, MUESTRA + Vector2(-13, 1), 13.0)
	draw_set_transform(Vector2.ZERO)

func _dibujar_marca(sitio: Vector2) -> void:
	var centro := proyectar_suelo(sitio) / escala_visual
	var cerca := sitio.distance_to(punto) <= (16.0 if interior else 25.0)
	var borde := centro.clamp(Vector2(24, 76), Vector2(ancho_visible - 24, 465 if interior else 325))
	if centro.distance_to(borde) > 12:
		var direccion := (centro - borde).normalized()
		var lateral := direccion.orthogonal()
		draw_colored_polygon(PackedVector2Array([borde + direccion * 9,
			borde - direccion * 7 + lateral * 6, borde - direccion * 7 - lateral * 6]), LUZ)
	else:
		draw_arc(centro + Vector2(0, 5), 8.0, 0.0, TAU, 24, Color(0.05, 0.09, 0.13, 0.9), 4, true)
		draw_arc(centro + Vector2(0, 5), 8.0, 0.0, TAU, 24, Color.WHITE if cerca else LUZ, 2, true)
