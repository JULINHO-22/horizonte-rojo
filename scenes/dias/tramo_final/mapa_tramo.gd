extends PuestoUmbra

const REFUGIO_SOLAR := preload("res://assets/dias/dia_5/nucleo_radiacion.png")
const SUELO_PROTEGIDO := 319.0
var zona := "base"
var blancos: Dictionary = {}
var nombres: Dictionary = {}
var foco := ""
var permite_tocar := true
var cursor := Vector2.ZERO
var arrastre := ""
var fase_radiacion := ""
var nivel_radiacion := 0.0
var carga := ""
var paneles := 0
var placas: Array[String] = []
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
		var apoyo := ancla_carga() / escala_visual + Vector2(0, 9)
		if arrastre == "objeto":
			apoyo = cursor / escala_visual + Vector2(0, 9)
		_dibujar_objeto(CAJA_CERRADA, apoyo, 28.0 if interior else 16.0)
		if carga == "hielo":
			draw_circle(apoyo - Vector2(0, 9), 2.4, LUZ, true, -1.0, true)
	if plano:
		_dibujar_acceso()
		return
	if not fase_radiacion.is_empty():
		_dibujar_radiacion()
	if not permite_tocar:
		return
	for id: String in blancos:
		_dibujar_marca(id, blancos[id])

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
		var led := Color("#7ee6d8") if paneles == 3 or placas.has("montaje_%d" % i) else Color("#ed9b55")
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


func ancla_carga() -> Vector2:
	var desplazamiento := Vector2(-12.0 if direccion_izquierda else 12.0, -59.0 if interior else -34.0)
	return proyectar_suelo(punto) + desplazamiento * escala_visual

func ancla_interaccion(id: String, sitio: Vector2) -> Vector2:
	var sobre_suelo := proyectar_suelo(sitio)
	if id.begins_with("montaje_"):
		return Vector2(sobre_suelo.x, 161.0 * escala_visual)
	if zona == "hielo" or id in ["afuera", "refugio", "retorno"]:
		return sobre_suelo + Vector2(0, 5)
	return sobre_suelo - Vector2(0, 75.0 if id in ["sello", "montaje"] else 52.0)

func _dibujar_acceso() -> void:
	var sitio := proyectar_suelo(Vector2(400, 372)) / escala_visual
	draw_line(sitio, sitio + Vector2(42, -7), LUZ, 1.6, true)
	draw_circle(sitio, 5, LUZ, true, -1, true)
	_rotulo_suelo(sitio + Vector2(120, -7), "NÚCLEO PROTEGIDO")

func _dibujar_radiacion() -> void:
	var origen := Vector2(ancho_visible - 225, 116)
	_rotulo_suelo(origen + Vector2(93, -13), fase_radiacion)
	draw_line(origen, origen + Vector2(186, 0), Color("#39434a"), 3.4, true)
	draw_line(origen, origen + Vector2(186 * nivel_radiacion, 0), OCRE, 3.4, true)
	_rotulo_suelo(origen + Vector2(93, 21), "Curiosity · datos de 2017")

func _dibujar_marca(id: String, sitio: Vector2) -> void:
	var centro := ancla_interaccion(id, sitio) / escala_visual
	var cerca := sitio.distance_to(punto) <= (18.0 if interior else 27.0)
	var borde := centro.clamp(Vector2(25, 84), Vector2(ancho_visible - 25, 487 if interior else 338))
	if centro.distance_to(borde) > 12:
		var direccion := (centro - borde).normalized()
		var lateral := direccion.orthogonal()
		draw_colored_polygon(PackedVector2Array([borde + direccion * 9,
			borde - direccion * 7 + lateral * 6, borde - direccion * 7 - lateral * 6]), LUZ)
		return
	var activa := foco == id
	var color := Color.WHITE if activa else LUZ if cerca else Color("#b5c4c3")
	if id == "sello" and cerca:
		var final := centro + Vector2(100.0 / escala_visual, 0)
		var x := clampf(cursor.x / escala_visual, centro.x, final.x) if arrastre == "sello" else centro.x
		draw_line(centro, final, Color("#17282d"), 8, true)
		draw_line(centro, final, LUZ, 2, true)
		draw_circle(Vector2(x, centro.y), 9, color, true, -1, true)
		_rotulo_suelo(centro.lerp(final, 0.5) - Vector2(0, 17), "Desliza para cerrar")
	else:
		draw_circle(centro, 8, Color("#10232b"), true, -1, true)
		draw_arc(centro, 8, 0.0, TAU, 28, color, 2.0, true)
		if cerca:
			draw_circle(centro, 3.0, color, true, -1.0, true)
			_rotulo_suelo(centro - Vector2(0, 17), nombres.get(id, ""))

func _rotulo_suelo(centro: Vector2, texto: String) -> void:
	if texto.is_empty():
		return
	var fuente := ThemeDB.fallback_font
	const TAMANO := 19
	var ancho := fuente.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, TAMANO).x
	var ancla := centro * escala_visual - Vector2(ancho * 0.5, 0)
	# Mantiene las letras a resolución de pantalla aunque el mundo tenga zoom.
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE / escala_visual)
	draw_string_outline(fuente, ancla, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, TAMANO, 5, Color("#101b23"))
	draw_string(fuente, ancla, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, TAMANO, Color("#e8f2ee"))
	draw_set_transform(Vector2.ZERO)
