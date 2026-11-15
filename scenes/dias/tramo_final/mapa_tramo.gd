extends PuestoUmbra

const REFUGIO_SOLAR := preload("res://assets/dias/dia_5/nucleo_radiacion.png")
const PUERTA_ABIERTA := preload("res://assets/dias/dia_5/nucleo_paso_abierto.png")
const CultivoPixel := preload("res://scripts/cultivo_pixel.gd")
const Recursos := preload("res://scripts/mecanicas/recursos_mision.gd")
const BANDEJAS := {"lechuga": Vector2(338, 77), "rabano": Vector2(372, 77),
	"tomate": Vector2(442, 77), "papa": Vector2(476, 77)}
const SUELO_PROTEGIDO := 319.0
const UMBRAL := Vector2(342, PuestoUmbra.SUELO)
const MARCO_PASO := Rect2(0.402, 0.431, 0.196, 0.333)
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
var entrada_nucleo := 1.0
var huerto: Node2D
var _cultivos: Dictionary = {}

func mostrar_huerto(bandejas: Dictionary) -> void:
	if huerto == null:
		huerto = Node2D.new()
		huerto.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(huerto)
		for cultivo: String in BANDEJAS:
			var planta := CultivoPixel.new()
			planta.position = BANDEJAS[cultivo]
			planta.altura_madura = 17.0
			huerto.add_child(planta)
			_cultivos[cultivo] = planta
	for cultivo: String in _cultivos:
		var planta: CultivoPixel = _cultivos[cultivo]
		var resto: float = bandejas.get(cultivo, -1.0)
		var etapa := CultivoPixel.etapa_del_cultivo(resto, Recursos.CULTIVOS[cultivo].segundos) if resto >= 0 else -1
		planta.mostrar(cultivo, etapa)
	ubicar_huerto()

func ubicar_huerto() -> void:
	if huerto == null:
		return
	huerto.visible = zona == "base" and not plano
	huerto.position = _origen_mundo()
	huerto.scale = Vector2.ONE * escala_camara

func recoger_cultivo(cultivo: String) -> void:
	var planta: CultivoPixel = _cultivos[cultivo]
	planta.levantar().connect(planta.mostrar.bind(cultivo, -1, false), CONNECT_ONE_SHOT)

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
	_dibujar_compuerta(marco.size)
	if impacto > 0:
		draw_rect(marco, Color(0.38, 0.08, 0.06, impacto * 0.28))
		draw_rect(marco, Color(0.01, 0.04, 0.08, impacto * 0.44))
	for i in range(3):
		var x := 256.0 + i * 84.0
		var led := Color("#7ee6d8") if paneles == 3 or placas.has("montaje_%d" % i) else Color("#ed9b55")
		draw_circle(Vector2(x, 127), 2.5, led, true, -1.0, true)
	_sprite(IRIS, Vector2(445, SUELO_PROTEGIDO), 52)
	_sprite(TEO_NORMAL, Vector2(582, SUELO_PROTEGIDO), 51)
	_sprite(DRON, Vector2(clampf(punto.x + 30, 40, ancho_visible - 24), SUELO_PROTEGIDO - 10), 30)
	var cruzando := entrada_nucleo < 1.0
	var andando := NORA_PASOS if caminando or cruzando else NORA
	var pies := Vector2(punto.x, lerpf(283.0, SUELO_PROTEGIDO, entrada_nucleo))
	var pose := mini(7, int(fposmod(entrada_nucleo * 1.6, 1.0) * 8)) if cruzando else int(paso * 8)
	_sprite(andando, pies, lerpf(38.0, 51.0, entrada_nucleo), 0, direccion_izquierda,
		pose if caminando or cruzando else -1)

func _dibujar_compuerta(tamano: Vector2) -> void:
	if compuerta >= 1.0:
		return
	var destino := Rect2(MARCO_PASO.position * tamano, MARCO_PASO.size * tamano)
	var tamano_abierto := PUERTA_ABIERTA.get_size()
	draw_texture_rect_region(PUERTA_ABIERTA, destino,
		Rect2(MARCO_PASO.position * tamano_abierto, MARCO_PASO.size * tamano_abierto))
	# Los bordes interiores de las hojas entran desde los costados, sin deformar el arte.
	var mitad_fuente := MARCO_PASO.size.x * REFUGIO_SOLAR.get_width() * 0.5
	var mitad_destino := destino.size.x * 0.5
	var fuente := MARCO_PASO.position * REFUGIO_SOLAR.get_size()
	var alto := MARCO_PASO.size.y * REFUGIO_SOLAR.get_height()
	var ancho := mitad_destino * compuerta
	var recorte := mitad_fuente * compuerta
	if recorte <= 0.1:
		return
	draw_texture_rect_region(REFUGIO_SOLAR, Rect2(destino.position, Vector2(ancho, destino.size.y)),
		Rect2(fuente.x + mitad_fuente - recorte, fuente.y, recorte, alto))
	draw_texture_rect_region(REFUGIO_SOLAR, Rect2(destino.end.x - ancho, destino.position.y, ancho, destino.size.y),
		Rect2(fuente.x + mitad_fuente, fuente.y, recorte, alto))

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

func _dibujar_radiacion() -> void:
	var origen := Vector2(ancho_visible - 225, 116)
	_rotulo_suelo(origen + Vector2(93, -13), fase_radiacion)
	draw_line(origen, origen + Vector2(186, 0), Color("#39434a"), 3.4, true)
	draw_line(origen, origen + Vector2(186 * nivel_radiacion, 0), OCRE, 3.4, true)
	_rotulo_suelo(origen + Vector2(93, 21), "Curiosity · datos de 2017")

func alcance_interaccion() -> float:
	return 22.0 if interior else 34.0

func _dibujar_marca(id: String, sitio: Vector2) -> void:
	var centro := ancla_interaccion(id, sitio) / escala_visual
	var cerca := sitio.distance_to(punto) < alcance_interaccion()
	var borde := centro.clamp(Vector2(25, 84), Vector2(ancho_visible - 25, 487 if interior else 338))
	if centro.distance_to(borde) > 12:
		var direccion := (centro - borde).normalized()
		var lateral := direccion.orthogonal()
		draw_colored_polygon(PackedVector2Array([borde + direccion * 9,
			borde - direccion * 7 + lateral * 6, borde - direccion * 7 - lateral * 6]), LUZ)
		return
	var activa := foco == id
	var color := Color.WHITE if activa else LUZ if cerca else Color("#b5c4c3")
	draw_circle(centro, 8, Color("#10232b"), true, -1, true)
	draw_arc(centro, 8, 0.0, TAU, 28, color, 2.0, true)
	var nombre: String = nombres.get(id, "")
	if cerca:
		draw_circle(centro, 3.0, color, true, -1.0, true)
		var prefijo := "Arrastra o pulsa E · " if id == "filtro" or id.begins_with("montaje_") else "E · "
		nombre = prefijo + nombre
	elif zona == "hielo" and id in ["escarcha", "veta"]:
		nombre = "Sondeo A" if id == "escarcha" else "Sondeo B"
	_rotulo_suelo(centro - Vector2(0, 17), nombre)

func _rotulo_suelo(centro: Vector2, texto: String) -> void:
	if texto.is_empty():
		return
	var fuente := ThemeDB.fallback_font
	const TAMANO := 19
	var ancho := fuente.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, TAMANO).x
	var ancla := centro * escala_visual - Vector2(ancho * 0.5, 0)
	ancla.x = clampf(ancla.x, 16, ancho_visible * escala_visual - ancho - 16)
	# Mantiene las letras a resolución de pantalla aunque el mundo tenga zoom.
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE / escala_visual)
	draw_string_outline(fuente, ancla, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, TAMANO, 5, Color("#101b23"))
	draw_string(fuente, ancla, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, TAMANO, Color("#e8f2ee"))
	draw_set_transform(Vector2.ZERO)
