class_name PuestoUmbra
extends Node2D

const EXTERIOR := preload("res://assets/exterior.jpg")
const MAPA := preload("res://assets/base.jpg")
const TORMENTA := preload("res://assets/tormenta.png")
const FRENTE := preload("res://assets/frente_polvo.png")
const CLINICA := preload("res://assets/enfermeria.png")
const ENERGIA := preload("res://assets/energia_interior.png")
const REFUGIO := preload("res://assets/esclusa_interior.png")
const NORA := preload("res://assets/nora_reposo.png")
const NORA_PASOS := preload("res://assets/nora_caminar.png")
const NOMBRES := {"energia": "ENERGÍA", "cultivos": "INVERNADERO", "medicina": "ENFERMERÍA", "radio": "CONTROL", "cierre": "ESCLUSA"}
const IRIS := preload("res://assets/iris.png")
const IRIS_PASOS := preload("res://assets/iris_caminar.png")
const TEO := preload("res://assets/teo.png")
const TEO_NORMAL := preload("res://assets/teo_normal.png")
const TEO_PASOS := preload("res://assets/teo_caminar.png")
const TEO_REPOSO := preload("res://assets/teo_reposo.png")
const TEO_RECUPERADO := preload("res://assets/teo_recuperado.png")
const DRON := preload("res://assets/dron.png")
const VEHICULO := preload("res://assets/rover.png")
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
	Rect2(41, 163, 113, 68), Rect2(49, 256, 93, 47),
	Rect2(348, 172, 109, 15), Rect2(375, 233, 53, 47),
	Rect2(580, 161, 175, 47), Rect2(732, 209, 35, 81),
	Rect2(356, 372, 19, 29), Rect2(431, 351, 18, 57),
]
const ROVER := Vector2(493, 337)
const ESCLUSA := Vector2(750, 329)
const RELES := [Vector2(633, 345), Vector2(490, 364), Vector2(312, 330)]
const ABRIGOS := [Vector2(482, 352), Vector2(645, 315), Vector2(733, 320)]

var interior := false
var chequeo := false
var mando_nido := false
var rele_actual := 0
var anclado := false
var plano := false
var objetivo_mision := ""
var ancho_visible := 804.0
var escala_visual := 1.0
var caminando := false
static var secuencias: Dictionary = {}
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
	var rapidez := 112.0 if interior else 176.0
	if evacuacion:
		rapidez = 135.0
	elif mando_nido:
		rapidez = 161.0
	if anclado:
		rapidez *= 0.18
	velocidad = velocidad.move_toward(direccion * rapidez, delta * 1100.0)
	if absf(direccion.x) > 0.1:
		direccion_izquierda = direccion.x < 0
	var antes := punto
	var avance := (velocidad + Vector2(-empuje_viento(), 0)) * delta
	for eje in [Vector2(avance.x, 0), Vector2(0, avance.y)]:
		if transitable(punto + eje):
			punto += eje
	var distancia := punto.distance_to(antes)
	caminando = distancia > 0.14 and direccion != Vector2.ZERO and not anclado
	if caminando:
		paso = fposmod(paso + distancia / (42.0 if interior else 67.0), 1.0)


func intensidad_viento() -> float:
	if interior or chequeo:
		return 0.0
	var pulso := pow(maxf(0, cos((tiempo - 20.0) * TAU / 6.5)), 6.0)
	return (0.18 + 0.82 * pulso) * smoothstep(6.0, 13.0, tiempo)


func bajo_abrigo() -> bool:
	for refugio: Vector2 in ABRIGOS:
		if punto.distance_to(refugio) < 29:
			return true
	return false


func empuje_viento() -> float:
	var fuerza := intensidad_viento() * (93.0 if mando_nido else 226.0)
	if bajo_abrigo():
		fuerza *= 0.18
	if anclado:
		fuerza *= 0.06
	return fuerza


func actualizar_camara(delta: float) -> void:
	if not interior:
		return
	var objetivo := Vector2(402, 263.5)
	var escala := 1.0
	for zona: String in ROOMS:
		var sala: Rect2 = ROOMS[zona]
		if sala.has_point(punto) and not plano:
			escala = 3.2 if zona != "cierre" else 2.5
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


func _origen_mundo() -> Vector2:
	if interior:
		return Vector2(ancho_visible * 0.5, 263.5) - centro_camara * escala_camara
	return Vector2((ancho_visible - 804) * 0.5, -63)


func _dibujar_exterior() -> void:
	var zoom := 1.0 + 0.10 * clampf(tiempo / 16.0, 0, 1)
	var lienzo := Vector2(804, 490)
	var origen := _origen_mundo()
	var ancho_fondo := ancho_visible / zoom
	draw_set_transform(Vector2(0, origen.y), 0, Vector2.ONE * zoom)
	var fondo := Rect2(-ancho_fondo * 0.04, -25, ancho_fondo * 1.08, lienzo.y)
	draw_texture_rect(EXTERIOR, fondo, false)
	var polvo := 0.0 if chequeo else smoothstep(3.5, 10.5, tiempo)
	var rafaga := intensidad_viento()
	draw_texture_rect(TORMENTA, fondo, false, Color(1, 1, 1, polvo))
	draw_texture_rect(FRENTE, fondo, false, Color(1, 1, 1, polvo * (0.35 + rafaga * 0.65)))
	draw_set_transform(origen)
	draw_rect(Rect2(-42, 302, 888, 182), Color(0.17, 0.07, 0.04, polvo * 0.21))
	_sprite(VEHICULO, ROVER + Vector2(15, 6), 62)
	var nora := punto
	var iris := Vector2(668, 316)
	var teo := ROVER + Vector2(-25, 14)
	var accidente := not chequeo
	var carrera := cinematica and tiempo >= 4.0
	if cinematica:
		nora = Vector2(lerpf(punto.x, 339, smoothstep(4, 12, tiempo)), 352)
		iris = Vector2(lerpf(618, 667, smoothstep(4, 9, tiempo)), 319)
		teo = Vector2(lerpf(443, ROVER.x - 25, smoothstep(4, 11.7, tiempo)), 351)
		accidente = tiempo >= 11.8
	elif extraccion:
		var avance := smoothstep(17.3, 19.5, tiempo)
		teo = teo.lerp(punto + Vector2(-26, 4), avance)
		if usa_cabrestante:
			draw_line(ROVER + Vector2(-7, -15), teo + Vector2(0, -10), OCRE, 2)
	elif evacuacion:
		teo = punto + Vector2(-26 if not direccion_izquierda else 26, 4)
		iris = ESCLUSA + Vector2(-18, -13)
	if chequeo:
		iris = Vector2(618, 319)
		teo.x = 443
	var iris_camina := carrera and tiempo < 9.0
	var iris_paso := int(fposmod((iris.x - 618) / 30.0, 1.0) * 8)
	if not mando_nido:
		_sprite(IRIS_PASOS if iris_camina else IRIS, iris, 49, 0.0, false, iris_paso if iris_camina else -1)
	if accidente and not mando_nido:
		if evacuacion or extraccion:
			draw_line(teo + Vector2(-24, -5), teo + Vector2(24, -5), Color("#b9b6b1"), 4, true)
			draw_circle(teo + Vector2(-16, 0), 3, OSCURO)
			draw_circle(teo + Vector2(17, 0), 3, OSCURO)
		_sprite(TEO, teo, 18)
	elif not mando_nido:
		var teo_paso := int(fposmod((teo.x - 443) / 28.0, 1.0) * 8)
		_sprite(TEO_PASOS if carrera else TEO_NORMAL, teo, 48, 0.0, false, teo_paso if carrera else -1)
	var ciclo := fposmod(absf(nora.x - punto.x) / 61.0, 1.0) if cinematica else paso
	if mando_nido:
		_sprite(DRON, punto, 39, sin(tiempo * 10.0) * 1.0, direccion_izquierda)
	else:
		_sprite(NORA_PASOS if caminando or (carrera and tiempo < 12) else NORA,
			nora, 51, 3.0 if anclado else rafaga, carrera or direccion_izquierda,
			int(ciclo * 8) if caminando or (carrera and tiempo < 12) else -1)
	for indice in range(132):
		var x := fposmod(indice * 83.7 - tiempo * (185 + indice % 8 * 42), 886) - 42
		var y := fposmod(indice * 51.9 + tiempo * 16, 480)
		var estela := 12.0 + rafaga * 46.0 + indice % 23
		draw_line(Vector2(x, y), Vector2(x - estela, y + 6), Color(1, 0.73, 0.49, polvo * (0.18 + rafaga * 0.4)), 2)
	if polvo > 0.0:
		draw_rect(Rect2(-44, 42, ancho_visible + 88, 440), Color(0.73, 0.36, 0.13, rafaga * 0.24))
	if mando_nido:
		for i in range(RELES.size()):
			var torre: Vector2 = RELES[i]
			draw_line(torre, torre + Vector2(0, -34), OSCURO, 5, true)
			draw_circle(torre + Vector2(0, -35), 5, LUZ if i <= rele_actual else OCRE)
		var objetivo: Vector2 = RELES[rele_actual] if rele_actual < RELES.size() else ESCLUSA
		_baliza(objetivo + Vector2(0, -58), "RELÉ %d" % (rele_actual + 1) if rele_actual < RELES.size() else "REGRESO", LUZ)
	elif not cinematica and not extraccion and not decision:
		_baliza((ESCLUSA if evacuacion else ROVER) + Vector2(0, -83),
			"ESCLUSA" if evacuacion else "TEO", LUZ)
		if not chequeo:
			for refugio: Vector2 in ABRIGOS:
				draw_arc(refugio, 21, 0.0, TAU, 28, Color(0.68, 0.94, 0.82, 0.52), 1.5, true)
	draw_set_transform(Vector2.ZERO)


func _dibujar_interior() -> void:
	var marco := Vector2(804, 527)
	draw_rect(Rect2(0, 0, ancho_visible, marco.y), Color("#171c22"))
	draw_set_transform(_origen_mundo(), 0, Vector2.ONE * escala_camara)
	draw_texture_rect(MAPA, Rect2(Vector2.ZERO, marco), false)
	draw_texture_rect(ENERGIA, Rect2(10, 130, 236, 211), false)
	draw_texture_rect(REFUGIO, Rect2(331, 321, 142, 137), false)
	draw_texture_rect(CLINICA, Rect2(554, 132, 245, 209), false)
	if not cultivo_activo:
		draw_rect(Rect2(259, 33, 282, 88), Color(0.14, 0.19, 0.26, 0.52))
	if radio_enviada:
		draw_circle(Vector2(402, 188), 4.0, Color(0.34, 1.0, 0.84, 0.55))
	var estado_teo := LUZ if atendido or teo_recuperado else Color("#ee8377") if lesion_grave else OCRE
	if teo_recuperado:
		_sprite(TEO_RECUPERADO, Vector2(365, 216), 33)
	else:
		_sprite(TEO_REPOSO if atendido else TEO, Vector2(753, 202), 14)
		if atendido:
			draw_line(Vector2(752, 190), Vector2(755, 196), Color("#e5f2ef"), 1.5, true)
	draw_circle(Vector2(728, 181), 2.0 + sin(tiempo * 6) * 0.5, estado_teo)
	_sprite(IRIS, Vector2(455, 217), 31)
	_sprite(DRON, Vector2(340, 257), 22, sin(tiempo * 4.5))
	_sprite(NORA_PASOS if caminando else NORA, punto, 32, 0.0,
		direccion_izquierda, int(paso * 8) if caminando else -1)
	var terminal := terminal_cercana()
	for id: String in TERMINALES:
		var color := LUZ if id == objetivo_mision or terminal == id else OCRE
		draw_circle(TERMINALES[id] + Vector2(0, 8), 3.2, color, false, 1.0, true)
	draw_set_transform(Vector2.ZERO)
	if TERMINALES.has(objetivo_mision):
		var destino: Vector2 = TERMINALES[objetivo_mision]
		var marca := _origen_mundo() + destino * escala_camara
		var visible := Vector2(clampf(marca.x, 82, ancho_visible - 82), clampf(marca.y - 27, 58, 410))
		if marca.distance_to(visible) > 42:
			var hacia := (marca - visible).normalized()
			draw_line(visible - hacia * 18, visible, LUZ, 2.2, true)
			draw_circle(visible, 3, LUZ, true, -1, true)
		_baliza(visible, NOMBRES[objetivo_mision], LUZ)


func _sprite(textura: Texture2D, ancla: Vector2, alto: float, balanceo := 0.0,
		invertido := false, fotograma := -1) -> void:
	if not recortes.has(textura):
		recortes[textura] = textura.get_image().get_used_rect()
	var region: Rect2 = recortes[textura]
	if fotograma >= 0:
		if not secuencias.has(textura):
			var imagen := textura.get_image()
			var ancho_celda := imagen.get_width() / 4
			var alto_celda := imagen.get_height() / 2
			var poses: Array[Rect2] = []
			for i in range(8):
				var celda := Rect2i(i % 4 * ancho_celda, i / 4 * alto_celda, ancho_celda, alto_celda)
				var limites := imagen.get_region(celda).get_used_rect()
				poses.append(Rect2(celda.position + limites.position, limites.size))
			secuencias[textura] = poses
		region = secuencias[textura][fotograma]
	var ancho := alto * region.size.x / region.size.y
	var tam := Vector2(ancho, alto)
	var origen := ancla - Vector2(ancho * 0.5, alto + absf(balanceo))
	draw_circle(ancla, 6.0, Color(0.08, 0.06, 0.11, 0.55))
	if invertido:
		var zoom := escala_camara if interior else 1.0
		var desplazamiento := _origen_mundo()
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
