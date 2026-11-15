extends Control
## Cinemática por capas de imagen con propulsión, paralaje y separación de etapas.
const TIERRA := preload("res://assets/NarrativaInicio/TierraPixelArt.png")
const ESPACIO := preload("res://assets/NarrativaInicio/EspacioProfundoPixelArt.png")
const MARTE := preload("res://assets/NarrativaInicio/MartePixelArt.png")
const TRANSFERENCIA := preload("res://assets/NarrativaInicio/NaveTransferenciaPixelArt.png")
const MODULO := preload("res://assets/NarrativaInicio/ModuloDescensoOrbitalPixelArt.png")
const ESTELA := preload("res://assets/NarrativaInicio/EstelaPropulsionPixelArt.png")
const TAMANO := Vector2(1280, 720)

var progreso := 0.0:
	set(valor):
		progreso = clampf(valor, 0.0, 1.0)
		if is_node_ready():
			_actualizar_toma()
var regreso := false:
	set(valor):
		regreso = valor
		if is_node_ready():
			_asignar_fondos()
			_actualizar_toma()

const INICIO_SEPARACION := 0.49
const FIN_SEPARACION := 0.73

var fondo_salida: TextureRect
var fondo_espacio: TextureRect
var fondo_llegada: TextureRect
var estela: TextureRect
var transferencia: TextureRect
var modulo: TextureRect

func _ready() -> void:
	size = TAMANO
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	fondo_salida = _crear_imagen(TIERRA)
	fondo_espacio = _crear_imagen(ESPACIO)
	fondo_llegada = _crear_imagen(MARTE)
	estela = _crear_imagen(ESTELA, true)
	transferencia = _crear_imagen(TRANSFERENCIA, true)
	modulo = _crear_imagen(MODULO, true)
	_asignar_fondos()
	_actualizar_toma()

func etapa() -> String:
	if regreso:
		if progreso < 0.30:
			return "El módulo se acopla para volver"
		if progreso < 0.68:
			return "Meses de viaje después…"
		return "Nos acercamos a la Tierra"
	if progreso < 0.28:
		return "Impulso de salida desde la Tierra"
	if progreso < INICIO_SEPARACION:
		return "Meses de viaje después…"
	if progreso < FIN_SEPARACION:
		return "Separación del módulo de descenso"
	return "El módulo se acerca a Marte"

func _crear_imagen(textura: Texture2D, transparente := false) -> TextureRect:
	var imagen := TextureRect.new()
	imagen.texture = textura
	imagen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagen.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	imagen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if transparente:
		imagen.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(imagen)
	return imagen

func _asignar_fondos() -> void:
	if not is_instance_valid(fondo_salida):
		return
	fondo_salida.texture = MARTE if regreso else TIERRA
	fondo_llegada.texture = TIERRA if regreso else MARTE

func _actualizar_toma() -> void:
	if not is_instance_valid(transferencia):
		return
	var salida_a_espacio := smoothstep(0.22, 0.38, progreso)
	var espacio_a_llegada := smoothstep(0.58, 0.75, progreso)
	fondo_salida.modulate.a = 1.0
	fondo_espacio.modulate.a = salida_a_espacio
	fondo_llegada.modulate.a = espacio_a_llegada

	# El encuadre cambia de forma visible; las estrellas y los planetas no quedan clavados al visor.
	_colocar_fondo(fondo_salida, lerpf(1.18, 1.03, progreso), Vector2(72, 20) * progreso)
	_colocar_fondo(fondo_espacio, lerpf(1.02, 1.16, progreso), Vector2(-82, 18) * progreso)
	_colocar_fondo(fondo_llegada, lerpf(1.01, 1.22, progreso), Vector2(-94, -32) * progreso)

	var separacion := 1.0 - smoothstep(0.10, 0.31, progreso) if regreso else smoothstep(INICIO_SEPARACION, FIN_SEPARACION, progreso)
	var escala_conjunto := lerpf(0.78, 1.07, smoothstep(0.0, 0.66, progreso))
	if regreso:
		escala_conjunto = lerpf(1.07, 0.82, smoothstep(0.30, 1.0, progreso))
	var tam_transferencia := Vector2(560, 560.0 * TRANSFERENCIA.get_height() / float(TRANSFERENCIA.get_width())) * escala_conjunto
	var tam_modulo := Vector2(218, 218.0 * MODULO.get_height() / float(MODULO.get_width())) * escala_conjunto

	var inicio := Vector2(170, 405)
	var control_a := Vector2(405, 290)
	var control_b := Vector2(720, 235)
	var final := Vector2(930, 315)
	var centro_ruta := inicio.bezier_interpolate(control_a, control_b, final, progreso)
	var avance_descenso := smoothstep(FIN_SEPARACION, 1.0, progreso) if not regreso else 0.0
	var centro_transferencia := centro_ruta + Vector2(-270, -68) * separacion - Vector2(400, 95) * avance_descenso
	var giro_base := lerpf(-0.09, 0.02, progreso)
	var giro_transferencia := giro_base - 0.13 * separacion
	var giro_modulo := giro_base + 0.20 * separacion - 0.25 * avance_descenso
	# Los puntos de anclaje corresponden al centro de los aros en cada PNG.
	var aro_transferencia := Vector2(0.31, 0.07) * tam_transferencia
	var aro_modulo := Vector2(-0.29, 0.08) * tam_modulo
	var centro_modulo := centro_transferencia + aro_transferencia.rotated(giro_transferencia) - aro_modulo.rotated(giro_modulo)
	centro_modulo += Vector2(370, 180) * separacion
	centro_modulo = centro_modulo.lerp(Vector2(615, 365), avance_descenso)
	var visible_general := smoothstep(0.0, 0.04, progreso)
	_colocar_capa(transferencia, centro_transferencia, tam_transferencia, giro_transferencia)
	_colocar_capa(modulo, centro_modulo, tam_modulo * lerpf(1.0, 1.34, avance_descenso), giro_modulo)
	transferencia.modulate.a = visible_general * (1.0 - avance_descenso)
	modulo.modulate.a = visible_general * (1.0 - smoothstep(0.97, 1.0, progreso) if regreso else 1.0)

	# La estela aparece en los impulsos y palpita levemente; se apaga al separar el módulo.
	var potencia := 0.24
	if progreso < 0.23:
		potencia = 0.95
	elif progreso > 0.48 and progreso < 0.66:
		potencia = 0.72
	if separacion > 0.08:
		potencia *= 1.0 - smoothstep(0.08, 0.55, separacion)
	var tam_estela := Vector2(tam_transferencia.x * 0.47, tam_transferencia.y * 0.62)
	var centro_estela := centro_transferencia - Vector2(tam_transferencia.x * 0.59, 0)
	_colocar_capa(estela, centro_estela, tam_estela, giro_transferencia)
	estela.modulate.a = transferencia.modulate.a * potencia * (0.84 + 0.16 * sin(progreso * 92.0))

func _colocar_capa(capa: TextureRect, centro: Vector2, dimensiones: Vector2, giro: float) -> void:
	if regreso:
		centro.x = TAMANO.x - centro.x
	capa.size = dimensiones
	capa.pivot_offset = dimensiones * 0.5
	capa.position = centro - dimensiones * 0.5
	capa.scale = Vector2(-1.0 if regreso else 1.0, 1.0)
	capa.rotation = giro * (-1.0 if regreso else 1.0)

func _colocar_fondo(imagen: TextureRect, zoom: float, paneo: Vector2) -> void:
	var dimensiones := TAMANO * zoom
	var margen := (dimensiones - TAMANO) * 0.5
	imagen.position = -margen + paneo.clamp(-margen, margen)
	imagen.size = dimensiones
