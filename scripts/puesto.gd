class_name PuestoUmbra
extends Node2D

const EXTERIOR := preload("res://assets/exterior.jpg")
const MAPA := preload("res://assets/base.jpg")
const TORMENTA := preload("res://assets/tormenta.png")
const CLINICA := preload("res://assets/enfermeria.png")
const NORA := preload("res://assets/nora.png")
const IRIS := preload("res://assets/iris.png")
const TEO := preload("res://assets/teo.png")
const TEO_RECUPERADO := preload("res://assets/teo_recuperado.png")
const DRON := preload("res://assets/dron.png")
const VEHICULO := preload("res://assets/rover.png")
const PUERTA := preload("res://assets/esclusa.png")
const OSCURO := Color("#131820")
const LUZ := Color("#83eadc")
const OCRE := Color("#f6a44e")
# Coordenadas sobre la imagen de referencia escalada a 804 × 527.
const ENTRADA := Vector2(400, 394)
const ROOMS := {
	"cultivos": Rect2(273, 89, 256, 33),
	"energia": Rect2(44, 167, 172, 135),
	"radio": Rect2(300, 158, 198, 143),
	"medicina": Rect2(567, 161, 200, 144),
	"cierre": Rect2(355, 353, 96, 49),
}
const PASILLOS := [
	Rect2(385, 116, 30, 61), Rect2(208, 224, 98, 35),
	Rect2(492, 222, 83, 39), Rect2(382, 294, 39, 65),
]
const TERMINALES := {
	"cultivos": Vector2(401, 100), "energia": Vector2(185, 242),
	"radio": Vector2(402, 202), "medicina": Vector2(692, 238),
	"cierre": Vector2(400, 382),
}
const EQUIPOS := [
	Rect2(50, 168, 94, 63), Rect2(69, 259, 79, 43),
	Rect2(348, 172, 109, 15), Rect2(375, 233, 53, 47),
	Rect2(580, 161, 175, 47), Rect2(732, 209, 35, 81),
]
const ROVER := Vector2(493, 337)
const ESCLUSA := Vector2(701, 333)

var interior := false
var punto := Vector2(111, 343)
var paso := 0.0
var tiempo := 0.0
var cinematica := false
var evacuacion := false
var extraccion := false
var usa_cabrestante := false
var decision := false
var cultivo_activo := true
var atendido := false
var lesion_grave := false
var teo_recuperado := false
var velocidad := Vector2.ZERO
var direccion_izquierda := false
var escala_camara := 1.0
var centro_camara := Vector2(402, 263.5)
static var recortes: Dictionary = {}
var radio_enviada := false


func avanzar(direccion: Vector2, delta: float) -> void:
	velocidad = velocidad.move_toward(direccion * 176.0, delta * 1750.0)
	if absf(direccion.x) > 0.1:
		direccion_izquierda = direccion.x < 0
	var antes := punto
	var avance := velocidad * delta
	for eje in [Vector2(avance.x, 0), Vector2(0, avance.y)]:
		if transitable(punto + eje):
			punto += eje
	paso = fposmod(paso + punto.distance_to(antes) * 0.15, TAU) if punto != antes else 0.0


func actualizar_camara(delta: float) -> void:
	if not interior:
		return
	var objetivo := Vector2(402, 263.5)
	var escala := 1.0
	for zona: String in ROOMS:
		var sala: Rect2 = ROOMS[zona]
		if sala.has_point(punto):
			escala = 3.05 if zona != "cierre" else 2.5
			objetivo = sala.get_center().lerp(punto, 0.24) + Vector2(0, -16)
			break
	var peso := 1.0 - exp(-delta * 5.8)
	escala_camara = lerpf(escala_camara, escala, peso)
	centro_camara = centro_camara.lerp(objetivo, peso)


func transitable(destino: Vector2) -> bool:
	if not interior:
		return Rect2(31, 296, 735, 97).has_point(destino)
	for equipo: Rect2 in EQUIPOS:
		if equipo.grow(3).has_point(destino):
			return false
	for sector: Rect2 in ROOMS.values() + PASILLOS:
		if sector.has_point(destino):
			return true
	return false


func terminal_cercana() -> String:
	for id: String in TERMINALES:
		if punto.distance_to(TERMINALES[id]) <= 24.0:
			return id
	return ""


func _draw() -> void:
	if interior:
		_dibujar_interior()
	else:
		_dibujar_exterior()


func _dibujar_exterior() -> void:
	var zoom := 1.0 + 0.10 * clampf(tiempo / 12.0, 0, 1)
	var lienzo := Vector2(804, 421)
	draw_set_transform((lienzo - lienzo * zoom) * 0.5, 0, Vector2.ONE * zoom)
	draw_texture_rect(EXTERIOR, Rect2(Vector2.ZERO, lienzo), false)
	draw_texture_rect(TORMENTA, Rect2(Vector2.ZERO, lienzo), false,
		Color(1, 1, 1, smoothstep(1.0, 8.0, tiempo)))
	draw_set_transform(Vector2.ZERO)
	draw_rect(Rect2(Vector2.ZERO, lienzo), Color(0.21, 0.07, 0.03, 0.17))
	draw_rect(Rect2(0, 302, 804, 119), Color(0.23, 0.09, 0.06, 0.37))
	_sprite(PUERTA, ESCLUSA, 68)
	_sprite(VEHICULO, ROVER + Vector2(13, 6), 62)
	var nora := punto
	var iris := Vector2(668, 316)
	var teo := ROVER + Vector2(-25, 14)
	var caido := not evacuacion
	if cinematica:
		nora = Vector2(lerpf(95, 339, clampf((tiempo - 3.0) / 7.0, 0, 1)), 352)
		iris = Vector2(lerpf(177, 667, clampf((tiempo - 3.0) / 9.0, 0, 1)), 319)
		teo = Vector2(lerpf(130, ROVER.x - 25, clampf((tiempo - 3.0) / 6.0, 0, 1)), 351)
		caido = tiempo >= 9.0
	elif extraccion:
		var avance := clampf((tiempo - 14.2) / 1.7, 0, 1)
		teo = teo.lerp(punto + Vector2(-24, 4), avance)
		if usa_cabrestante:
			draw_line(ROVER + Vector2(-7, -15), teo + Vector2(0, -10), OCRE, 2)
		else:
			draw_rect(Rect2(teo + Vector2(-23, -7), Vector2(48, 8)), Color("#b15b44"))
		caido = avance < 0.9
	elif evacuacion:
		teo = punto + Vector2(-24, 4)
		iris = ESCLUSA + Vector2(-18, -13)
	_sprite(IRIS, iris, 49, sin(tiempo * 13) * 2.0 if cinematica and tiempo < 12.0 else 0.0)
	if caido:
		_sprite(TEO, teo, 18)
	else:
		_sprite(TEO_RECUPERADO, teo, 48, sin(tiempo * 14.0) * 1.8)
	_sprite(NORA, nora, 51, sin(tiempo * 15) * 2.0 if cinematica else sin(paso) * 2.0,
		direccion_izquierda)
	for indice in range(74):
		var x := fposmod(indice * 83.7 - tiempo * (180 + indice % 8 * 22), 804)
		var y := fposmod(indice * 51.9 + tiempo * 16, 420)
		var fin := Vector2(maxf(0, x - 18 - indice % 23), minf(420, y + 5))
		var densidad := lerpf(0.02, 0.29, clampf((tiempo - 2.5) / 6.0, 0, 1))
		draw_line(Vector2(x, y), fin, Color(1, 0.70, 0.45, densidad), 2)
	if not cinematica and not extraccion and not decision:
		_baliza(ESCLUSA if evacuacion else ROVER, "ESCLUSA" if evacuacion else "TEO", OCRE)


func _dibujar_interior() -> void:
	var marco := Vector2(804, 527)
	draw_rect(Rect2(Vector2.ZERO, marco), Color("#372321"))
	draw_set_transform(marco * 0.5 - centro_camara * escala_camara, 0, Vector2.ONE * escala_camara)
	draw_texture_rect(MAPA, Rect2(Vector2.ZERO, marco), false)
	draw_texture_rect(CLINICA, Rect2(554, 132, 245, 209), false)
	if not cultivo_activo:
		draw_rect(Rect2(259, 33, 282, 88), Color(0.14, 0.19, 0.26, 0.52))
	if radio_enviada:
		draw_circle(Vector2(402, 188), 4.0, Color(0.34, 1.0, 0.84, 0.55))
	var estado_teo := LUZ if atendido or teo_recuperado else Color("#ee8377") if lesion_grave else OCRE
	if teo_recuperado:
		_sprite(TEO_RECUPERADO, Vector2(717, 242), 33)
	else:
		_sprite(TEO, Vector2(753, 202), 14)
		if atendido:
			draw_line(Vector2(752, 190), Vector2(755, 196), Color("#e5f2ef"), 1.5, true)
	draw_circle(Vector2(728, 181), 2.0 + sin(tiempo * 6) * 0.5, estado_teo)
	_sprite(IRIS, Vector2(455, 217), 31)
	_sprite(DRON, Vector2(340, 257), 22, sin(tiempo * 4.5))
	_sprite(NORA, punto, 32, sin(paso) * 1.5, direccion_izquierda)
	var terminal := terminal_cercana()
	for id: String in TERMINALES:
		var color := LUZ if terminal == id else OCRE
		draw_circle(TERMINALES[id] + Vector2(0, 8), 3.2, color, false, 1.0, true)
	draw_set_transform(Vector2.ZERO)


func _sprite(textura: Texture2D, ancla: Vector2, alto: float, balanceo := 0.0,
		invertido := false) -> void:
	if not recortes.has(textura):
		recortes[textura] = textura.get_image().get_used_rect()
	var region: Rect2 = recortes[textura]
	var ancho := alto * region.size.x / region.size.y
	var tam := Vector2(ancho, alto)
	var origen := ancla - Vector2(ancho * 0.5, alto + absf(balanceo))
	draw_circle(ancla, 6.0, Color(0.08, 0.06, 0.11, 0.55))
	if invertido:
		var zoom := escala_camara if interior else 1.0
		var desplazamiento := Vector2(402, 263.5) - centro_camara * zoom if interior else Vector2.ZERO
		draw_set_transform(desplazamiento + (origen + Vector2(ancho, 0)) * zoom, 0, Vector2(-zoom, zoom))
		draw_texture_rect_region(textura, Rect2(Vector2.ZERO, tam), region)
		draw_set_transform(desplazamiento, 0, Vector2.ONE * zoom)
	else:
		draw_texture_rect_region(textura, Rect2(origen, tam), region)


func _baliza(centro: Vector2, texto: String, color: Color) -> void:
	var fuente := ThemeDB.fallback_font
	var ancho := fuente.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
	draw_rect(Rect2(centro - Vector2(ancho * 0.5 + 7, 1), Vector2(ancho + 14, 23)), OSCURO)
	draw_string(fuente, centro + Vector2(-ancho * 0.5, 15), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, color)
