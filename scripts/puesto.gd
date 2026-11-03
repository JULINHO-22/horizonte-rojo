class_name PuestoUmbra
extends Node2D

const SENDERO := preload("res://assets/sendero.png")
const NAVE := preload("res://assets/nave_llegada.png")
const TEO_CAIDA := preload("res://assets/teo_caida.png")
const MAPA := preload("res://assets/base.jpg")
const TORMENTA := preload("res://assets/tormenta.png")
const CLINICA := preload("res://assets/enfermeria.png")
const ENERGIA := preload("res://assets/energia_interior.png")
const REFUGIO := preload("res://assets/esclusa_interior.png")
const NORA := preload("res://assets/nora_reposo.png")
const NORA_PASOS := preload("res://assets/nora_caminar.png")
const NOMBRES := {"energia": "ENERGÍA", "cultivos": "SALA DE PLANTAS", "medicina": "ENFERMERÍA", "radio": "CONTROL", "cierre": "PUERTA"}
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
const SUELO := 351.0
const MUESTRA := Vector2(365, SUELO)
const ROVER := Vector2(649, SUELO)
const INICIO_CAIDA := 626.0
const ESCLUSA := Vector2(732, SUELO)
const RELES := [Vector2(633, SUELO), Vector2(490, SUELO), Vector2(312, SUELO)]
const ABRIGOS := [Vector2(463, SUELO), Vector2(590, SUELO), Vector2(731, SUELO)]

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
var aterrizaje := false
var hallazgo := false
var carrera := false
var caida := false
var tiempo_caida := 0.0
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
	if not interior:
		direccion.y = 0.0
		direccion = direccion.normalized()
		punto.y = SUELO
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
	if interior or chequeo or aterrizaje:
		return 0.0
	if caida:
		return lerpf(1.0, 0.53, smoothstep(1.0, 3.8, tiempo_caida))
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
		return destino.x >= 42.0 and destino.x <= 756.0 and is_equal_approx(destino.y, SUELO)
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
	var foco := punto.x
	if caida:
		foco = lerpf(foco, ROVER.x, smoothstep(0.0, 1.4, tiempo_caida))
	var temblor := sin(tiempo * 39.0) * intensidad_viento() * 2.4
	var zoom := _zoom_mundo()
	return Vector2(clampf(ancho_visible * 0.5 - foco * zoom, ancho_visible - 804.0 * zoom, 0.0),
		-112.0 - SUELO * (zoom - 1.0) + temblor)


func _zoom_mundo() -> float:
	return escala_camara if interior else 1.0 + 0.35 * smoothstep(0.0, 1.35, tiempo_caida)


func _dibujar_exterior() -> void:
	draw_set_transform(_origen_mundo(), 0, Vector2.ONE * _zoom_mundo())
	draw_texture_rect(SENDERO, Rect2(0, 0, 886, 462), false)
	var rafaga := intensidad_viento()
	var polvo := 0.0 if chequeo or aterrizaje else smoothstep(2.9, 6.7, tiempo)
	var llegada := smoothstep(0.45, 5.2, tiempo) if aterrizaje else 1.0
	var nave := Vector2(182, lerpf(35.0, SUELO - 21, llegada))
	if aterrizaje and llegada < 1.0:
		for i in range(23):
			var x := sin(i * 8.31 + tiempo * 9.0) * (12.0 + llegada * 45.0)
			var y := fposmod(i * 7.53 + tiempo * 145.0, 75.0)
			draw_circle(nave + Vector2(x, y - 8), 1.7 + float(i % 5),
				Color(1.0, 0.61, 0.27, (1.0 - y / 75.0) * 0.66))
	_sprite(NAVE, nave, 171)
	_sprite(VEHICULO, ROVER + Vector2(27, -5), 56)

	var nora := punto
	var iris := Vector2(284, SUELO)
	var teo := MUESTRA
	var afectado := caida or decision or extraccion or evacuacion
	var salida := smoothstep(7.0, 9.6, tiempo)
	if aterrizaje:
		nora = Vector2(lerpf(194, 220, salida), lerpf(SUELO - 21.0, SUELO, salida))
		iris.x = lerpf(194, 284, smoothstep(5.6, 8.7, tiempo))
		teo.x = lerpf(194, MUESTRA.x, smoothstep(9.3, 13.5, tiempo))
	elif carrera:
		iris.x = minf(ESCLUSA.x, maxf(415.0, punto.x + 110.0))
		teo.x = maxf(MUESTRA.x, punto.x + 62.0)
	elif afectado:
		iris.x = ESCLUSA.x - 10
		teo.x = ROVER.x - 9
		if caida:
			nora.x -= 24.0 * smoothstep(0.0, 1.6, tiempo_caida)
			teo.x = lerpf(INICIO_CAIDA + 62.0, teo.x, smoothstep(0.20, 1.65, tiempo_caida))
		elif extraccion:
			teo.x = lerpf(teo.x, punto.x - 27, smoothstep(17.3, 19.5, tiempo))
			if usa_cabrestante:
				draw_line(ESCLUSA - Vector2(8, 12), teo - Vector2(0, 8), OCRE, 2)
		elif evacuacion:
			teo.x = punto.x - 29 if not direccion_izquierda else punto.x + 29

	if mando_nido:
		_sprite(DRON, punto, 53, sin(tiempo * 10.0), direccion_izquierda)
	elif not aterrizaje or tiempo >= 6.0:
		var corriendo := carrera and caminando
		_sprite(IRIS_PASOS if corriendo else IRIS, iris, 69, 0.0, false,
			int(fposmod(iris.x / 60.0, 1.0) * 8) if corriendo else -1)
		if caida and tiempo_caida < 1.65:
			var pose := mini(3, int(tiempo_caida / 0.41))
			_sprite(TEO_CAIDA, teo, [68.0, 54.0, 37.0, 27.0][pose], 0.0, false, pose, 4)
		elif afectado:
			if evacuacion or extraccion:
				draw_line(teo + Vector2(-26, -4), teo + Vector2(25, -4), Color("#c5bbb2"), 5, true)
				draw_circle(teo + Vector2(-16, 1), 3.5, OSCURO)
				draw_circle(teo + Vector2(17, 1), 3.5, OSCURO)
			_sprite(TEO, teo, 24)
		elif not aterrizaje or tiempo >= 9.3:
			var teo_camina := corriendo or (aterrizaje and tiempo < 13.5)
			_sprite(TEO_PASOS if teo_camina else TEO_NORMAL, teo, 69, 0.0, false,
				int(fposmod(teo.x / 60.0, 1.0) * 8) if teo_camina else -1)
		if not aterrizaje or tiempo >= 7.0:
			var andando := caminando or (aterrizaje and tiempo < 9.6)
			_sprite(NORA_PASOS if andando else NORA, nora, 73, 3.0 if anclado else 0.0,
				direccion_izquierda, int(fposmod(nora.x / 61.0, 1.0) * 8) if andando else -1)
	if polvo > 0.0:
		draw_rect(Rect2(0, 0, 804, 462), Color(0.61, 0.25, 0.08, polvo * (0.16 + rafaga * 0.35)))
		for i in range(8):
			var x := fposmod(i * 159.0 - tiempo * (111.0 + i * 9.0), 1300.0) - 215.0
			var y := 80.0 + i * 44.0
			draw_colored_polygon(PackedVector2Array([
				Vector2(x - 150, y + 26), Vector2(x + 35, y + 4),
				Vector2(x + 153, y - 5), Vector2(x + 226, y + 13),
				Vector2(x + 76, y + 28), Vector2(x - 75, y + 38),
			]), Color(0.96, 0.58, 0.29, polvo * rafaga * 0.13))
		for i in range(145):
			var x := fposmod(i * 83.7 - tiempo * (180 + i % 8 * 46), 964) - 80
			var y := fposmod(i * 51.9 + tiempo * 13, 485)
			var estela := 16.0 + rafaga * 59.0 + i % 21
			draw_line(Vector2(x, y), Vector2(x - estela, y + 5), Color(1, 0.68, 0.43, polvo * (0.13 + rafaga * 0.34)), 2)
	if mando_nido:
		for i in range(RELES.size()):
			var torre: Vector2 = RELES[i]
			draw_line(torre, torre + Vector2(0, -34), OSCURO, 5, true)
			draw_circle(torre + Vector2(0, -35), 5, LUZ if i <= rele_actual else OCRE)
		var objetivo: Vector2 = RELES[rele_actual] if rele_actual < RELES.size() else ESCLUSA
		_baliza(objetivo + Vector2(0, -91), "PUESTO %d" % (rele_actual + 1) if rele_actual < RELES.size() else "REGRESO", LUZ)
	elif chequeo:
		draw_circle(MUESTRA - Vector2(18, 6), 4, LUZ)
		_baliza(MUESTRA + Vector2(0, -92), "TEO", LUZ)
	elif carrera or evacuacion:
		_baliza(ESCLUSA + Vector2(0, -102), "REFUGIO", LUZ)
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
		invertido := false, fotograma := -1, columnas := 4) -> void:
	if not recortes.has(textura):
		recortes[textura] = textura.get_image().get_used_rect()
	var region: Rect2 = recortes[textura]
	if fotograma >= 0:
		if not secuencias.has(textura):
			var imagen := textura.get_image()
			var filas := 1 if textura == TEO_CAIDA else 2
			var ancho_celda := imagen.get_width() / columnas
			var alto_celda := imagen.get_height() / filas
			var poses: Array[Rect2] = []
			for i in range(columnas * filas):
				var celda := Rect2i(i % columnas * ancho_celda, i / columnas * alto_celda, ancho_celda, alto_celda)
				if textura == TEO_CAIDA:
					var marco: Rect2 = [
						Rect2(0.0, 0.0, 0.243, 0.92),
						Rect2(0.244, 0.14, 0.216, 0.76),
						Rect2(0.441, 0.36, 0.24, 0.54),
						Rect2(0.688, 0.44, 0.312, 0.46),
					][i]
					var tamano := Vector2(imagen.get_size())
					celda = Rect2i(Vector2i(marco.position * tamano), Vector2i(marco.size * tamano))
				var limites := imagen.get_region(celda).get_used_rect()
				poses.append(Rect2(celda.position + limites.position, limites.size))
			secuencias[textura] = poses
		region = secuencias[textura][fotograma]
	var ancho := alto * region.size.x / region.size.y
	var tam := Vector2(ancho, alto)
	var origen := ancla - Vector2(ancho * 0.5, alto + absf(balanceo))
	if textura != NAVE and textura != VEHICULO:
		draw_rect(Rect2(ancla - Vector2(7, 2), Vector2(14, 4)), Color(0.08, 0.06, 0.11, 0.43))
	if invertido:
		var zoom := _zoom_mundo()
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
