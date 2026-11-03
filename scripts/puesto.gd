class_name PuestoUmbra
extends Node2D

const EXTERIOR := preload("res://assets/exterior.jpg")
const OSCURO := Color("#131820")
const METAL := Color("#b48a72")
const LUZ := Color("#83eadc")
const OCRE := Color("#f6a44e")
const ROOMS := [
	Rect2(301, 23, 222, 134), Rect2(29, 179, 218, 169),
	Rect2(288, 191, 247, 170), Rect2(575, 179, 199, 169),
	Rect2(331, 400, 161, 105),
]
const PASILLOS := [
	Rect2(382, 151, 62, 46), Rect2(240, 241, 55, 58),
	Rect2(527, 241, 56, 58), Rect2(381, 354, 64, 53),
]
const TERMINALES := {
	"cultivos": Vector2(411, 103), "energia": Vector2(147, 253),
	"radio": Vector2(411, 250), "medicina": Vector2(675, 260),
	"cierre": Vector2(411, 450),
}
const EQUIPOS := [
	Rect2(321, 49, 61, 51), Rect2(441, 49, 61, 51),
	Rect2(54, 201, 46, 49), Rect2(180, 201, 43, 49),
	Rect2(319, 209, 67, 28), Rect2(600, 201, 46, 49),
	Rect2(707, 204, 46, 89), Rect2(438, 209, 67, 28),
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
var radio_enviada := false


func avanzar(direccion: Vector2, delta: float) -> void:
	var avance := direccion * 179.0 * delta
	for eje in [Vector2(avance.x, 0), Vector2(0, avance.y)]:
		if transitable(punto + eje):
			punto += eje
	paso += delta * 14.0 if direccion != Vector2.ZERO else 0.0
	if direccion == Vector2.ZERO:
		paso = 0.0


func transitable(destino: Vector2) -> bool:
	if not interior:
		return Rect2(31, 296, 735, 97).has_point(destino)
	for equipo: Rect2 in EQUIPOS:
		if equipo.grow(8).has_point(destino):
			return false
	for sector: Rect2 in ROOMS + PASILLOS:
		if sector.has_point(destino):
			return true
	return false


func terminal_cercana() -> String:
	for id: String in TERMINALES:
		if punto.distance_to(TERMINALES[id]) <= 35.0:
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
	draw_set_transform(Vector2.ZERO)
	draw_rect(Rect2(Vector2.ZERO, lienzo), Color(0.21, 0.07, 0.03, 0.17))
	draw_rect(Rect2(0, 302, 804, 119), Color(0.23, 0.09, 0.06, 0.37))
	_dibujar_esclusa()
	_dibujar_rover()
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
	_traje(iris, Color("#33a9ac"), sin(tiempo * 13) * 2.0 if cinematica and tiempo < 12.0 else 0.0)
	_traje(teo, OCRE, sin(tiempo * 14) * 2.0 if cinematica and not caido else 0.0, caido)
	_traje(nora, Color("#c25c7f"), sin(tiempo * 15) * 2.0 if cinematica else sin(paso) * 3.0)
	for indice in range(74):
		var x := fposmod(indice * 83.7 - tiempo * (180 + indice % 8 * 22), 804)
		var y := fposmod(indice * 51.9 + tiempo * 16, 420)
		var fin := Vector2(maxf(0, x - 18 - indice % 23), minf(420, y + 5))
		var densidad := lerpf(0.02, 0.29, clampf((tiempo - 2.5) / 6.0, 0, 1))
		draw_line(Vector2(x, y), fin, Color(1, 0.70, 0.45, densidad), 2)
	if not cinematica and not extraccion and not decision:
		_baliza(ESCLUSA if evacuacion else ROVER, "ESCLUSA" if evacuacion else "TEO", OCRE)


func _dibujar_rover() -> void:
	draw_rect(Rect2(ROVER + Vector2(-20, -14), Vector2(63, 21)), Color("#352427"))
	draw_rect(Rect2(ROVER + Vector2(-15, -26), Vector2(57, 22)), Color("#96513c"))
	draw_rect(Rect2(ROVER + Vector2(-8, -30), Vector2(40, 10)), Color("#e6ab77"))
	draw_rect(Rect2(ROVER + Vector2(20, -25), Vector2(15, 10)), Color("#426971"))
	for x in [-12, 26]:
		draw_rect(Rect2(ROVER + Vector2(x, -7), Vector2(15, 14)), OSCURO)
		draw_rect(Rect2(ROVER + Vector2(x + 3, -4), Vector2(9, 8)), METAL)
	draw_rect(Rect2(ROVER + Vector2(-15, -20), Vector2(6, 4)), OCRE)


func _dibujar_esclusa() -> void:
	draw_rect(Rect2(ESCLUSA + Vector2(-31, -70), Vector2(62, 73)), METAL)
	draw_rect(Rect2(ESCLUSA + Vector2(-23, -63), Vector2(46, 66)), OSCURO)
	draw_rect(Rect2(ESCLUSA + Vector2(-19, -51), Vector2(38, 49)), Color("#655957"))
	draw_line(ESCLUSA + Vector2(0, -50), ESCLUSA + Vector2(0, -3), OSCURO, 3)
	draw_rect(Rect2(ESCLUSA + Vector2(-13, -58), Vector2(26, 4)), LUZ)


func _dibujar_interior() -> void:
	draw_rect(Rect2(0, 0, 804, 527), Color("#422a28"))
	for indice in range(320):
		var grava := Vector2((indice * 317) % 801, (indice * 191) % 523)
		draw_rect(Rect2(grava, Vector2(2 + indice % 3, 2)), Color("#603933"))
	for habitacion: Rect2 in ROOMS:
		_piso(habitacion, Color("#323d47"))
	for pasillo: Rect2 in PASILLOS:
		_piso(pasillo, Color("#596064"), 3.0)
		for indice in range(5):
			draw_rect(Rect2(pasillo.position + Vector2(9 + indice * 7, 6), Vector2(4, 4)), OCRE)
	_senal(Vector2(411, 464), Color("#efaa61"))
	_senal(Vector2(411, 311), Color("#56968d"))
	_senal(Vector2(145, 306), Color("#588fb2"))
	_senal(Vector2(674, 309), Color("#ad7893"))
	for indice in range(EQUIPOS.size()):
		var mueble: Rect2 = EQUIPOS[indice]
		var relleno := Color("#546977")
		if indice < 2:
			relleno = Color("#638b5b") if cultivo_activo else Color("#786b48")
		elif indice in [5, 6]:
			relleno = Color("#826f93")
		_equipo(mueble, relleno)
		if indice < 2:
			for x in range(3):
				for y in range(2):
					var planta := mueble.position + Vector2(12 + x * 17, 14 + y * 21)
					draw_rect(Rect2(planta, Vector2(12, 10)), Color("#a9ce6b") if cultivo_activo else Color("#9f854f"))
		elif indice in [4, 7]:
			for x in range(2):
				draw_rect(Rect2(mueble.position + Vector2(8 + x * 26, 5), Vector2(23, 12)),
					LUZ if radio_enviada else Color("#5f9da0"))
		elif indice in [2, 3]:
			var tanque := mueble.position + Vector2(9, 6)
			draw_rect(Rect2(tanque, Vector2(24, 34)), Color("#3d7999"))
			draw_rect(Rect2(tanque + Vector2(4, 2), Vector2(7, 28)), Color("#75abbe"))
			draw_rect(Rect2(tanque + Vector2(0, 20), Vector2(24, 5)), Color("#a8b3ac"))
			draw_rect(Rect2(tanque + Vector2(15, 5), Vector2(7, 4)), LUZ)
		elif indice in [5, 6]:
			draw_rect(Rect2(mueble.position + Vector2(5, 4), Vector2(36, 21)), Color("#b9b6b2"))
	_traje(Vector2(725, 257), OCRE, 0, true)
	if atendido:
		draw_rect(Rect2(725, 246, 11, 5), Color("#e0ece6"))
	_traje(Vector2(472, 286), LUZ, 0)
	_robot(Vector2(355, 278))
	var terminal := terminal_cercana()
	_baliza(TERMINALES.cultivos, "02  INVERNADERO", LUZ if terminal == "cultivos" else OCRE)
	_baliza(TERMINALES.energia, "01  ENERGÍA", LUZ if terminal == "energia" else OCRE)
	_baliza(TERMINALES.radio, "04  CONTROL", LUZ if terminal == "radio" else OCRE)
	_baliza(TERMINALES.medicina, "03  ENFERMERÍA", LUZ if terminal == "medicina" else OCRE)
	_baliza(TERMINALES.cierre, "05  ESCLUSA", LUZ if terminal == "cierre" else OCRE)
	_traje(punto, Color("#c25c7f"), sin(paso) * 3.0)


func _piso(area: Rect2, color: Color, borde := 8.0) -> void:
	draw_rect(Rect2(area.position + Vector2(-borde, -borde + 5), area.size + Vector2.ONE * borde * 2), OSCURO)
	draw_rect(area.grow(borde), METAL)
	draw_line(area.position - Vector2(0, borde - 2), Vector2(area.end.x, area.position.y - borde + 2),
		Color("#dfb9a0"), 3)
	draw_rect(area, color)
	if borde == 8.0:
		draw_rect(Rect2(area.position, Vector2(area.size.x, 12)), color.darkened(0.30))
		for x in range(11, int(area.size.x) - 7, 39):
			draw_rect(Rect2(area.position + Vector2(x, -6), Vector2(6, 6)), Color("#a36346"))
			draw_rect(Rect2(area.position + Vector2(x + 2, -6), Vector2(2, 6)), OCRE)
	for x in range(0, int(area.size.x), 18):
		draw_line(area.position + Vector2(x, 0), area.position + Vector2(x, area.size.y), OSCURO, 1)
	for y in range(0, int(area.size.y), 18):
		draw_line(area.position + Vector2(0, y), area.position + Vector2(area.size.x, y), OSCURO, 1)


func _senal(centro: Vector2, color: Color) -> void:
	draw_rect(Rect2(centro - Vector2(32, 15), Vector2(64, 30)), color.darkened(0.35), false, 2.0)
	draw_line(centro - Vector2(32, 15), centro - Vector2(20, 15), color, 3)
	draw_line(centro + Vector2(20, 15), centro + Vector2(32, 15), color, 3)


func _equipo(area: Rect2, color: Color) -> void:
	draw_rect(Rect2(area.position + Vector2(2, 7), area.size), OSCURO)
	draw_rect(area, color.darkened(0.33))
	draw_rect(area.grow(-3), color)
	draw_line(area.position + Vector2(2, 2), Vector2(area.end.x - 2, area.position.y + 2), color.lightened(0.32), 3)


func _traje(ancla: Vector2, acento: Color, zancada: float, caido := false) -> void:
	draw_set_transform(ancla)
	draw_rect(Rect2(-13, -2, 26, 6), Color(0.06, 0.04, 0.06, 0.52))
	if caido:
		draw_set_transform(ancla + Vector2(4, -3), -PI / 2)
	draw_rect(Rect2(-12, -31, 24, 20), OSCURO)
	draw_rect(Rect2(-10, -29, 20, 17), acento)
	draw_rect(Rect2(-7, -29, 15, 17), Color("#ddc1a4"))
	draw_rect(Rect2(-7, -13 + zancada, 6, 12), Color("#c3a48e"))
	draw_rect(Rect2(2, -13 - zancada, 6, 12), Color("#ead2ad"))
	draw_rect(Rect2(-9, -3 + zancada, 8, 4), OSCURO)
	draw_rect(Rect2(2, -3 - zancada, 8, 4), OSCURO)
	draw_rect(Rect2(-10, -47, 21, 20), OSCURO)
	draw_rect(Rect2(-8, -46, 18, 17), Color("#f5dbbd"))
	draw_rect(Rect2(-5, -43, 13, 10), Color("#255463"))
	draw_rect(Rect2(-4, -42, 9, 3), LUZ)
	draw_rect(Rect2(-4, -25, 7, 4), acento)
	draw_set_transform(Vector2.ZERO)


func _robot(ancla: Vector2) -> void:
	_equipo(Rect2(ancla - Vector2(10, 21), Vector2(20, 19)), METAL)
	draw_rect(Rect2(ancla - Vector2(7, 18), Vector2(14, 8)), OSCURO)
	draw_rect(Rect2(ancla - Vector2(5, 16), Vector2(3, 4)), LUZ)
	draw_rect(Rect2(ancla - Vector2(-2, 16), Vector2(3, 4)), LUZ)


func _baliza(centro: Vector2, texto: String, color: Color) -> void:
	var fuente := ThemeDB.fallback_font
	var ancho := fuente.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
	draw_rect(Rect2(centro - Vector2(ancho * 0.5 + 7, 1), Vector2(ancho + 14, 23)), OSCURO)
	draw_string(fuente, centro + Vector2(-ancho * 0.5, 15), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, color)
