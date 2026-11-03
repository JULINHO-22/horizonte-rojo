class_name PuestoUmbra
extends Node2D

const SENDERO := preload("res://assets/refugio_horizonte.png")
const CAMPO := preload("res://assets/barranco_horizonte.png")
const LABORATORIO := preload("res://assets/laboratorio_agua.png")
const TALLER := preload("res://assets/taller_umbra.png")
const CONTROL := preload("res://assets/control_detalle.png")
const PLANTAS := preload("res://assets/plantas_horizonte.png")
const DORMITORIO := preload("res://assets/dormitorio_umbra.png")
const TEO_CAMA := preload("res://assets/teo_cama.png")
const CONTORNO_CONTROL := [
	Vector2(0.0, 0.40), Vector2(0.07, 0.39), Vector2(0.07, 0.16),
	Vector2(0.16, 0.075), Vector2(0.39, 0.075), Vector2(0.40, 0.015),
	Vector2(0.60, 0.015), Vector2(0.61, 0.075), Vector2(0.84, 0.075),
	Vector2(0.93, 0.16), Vector2(0.93, 0.39), Vector2(1.0, 0.40),
	Vector2(1.0, 0.61), Vector2(0.93, 0.62), Vector2(0.93, 0.80),
	Vector2(0.84, 0.89), Vector2(0.61, 0.89), Vector2(0.61, 0.98),
	Vector2(0.39, 0.98), Vector2(0.39, 0.89), Vector2(0.16, 0.89),
	Vector2(0.07, 0.80), Vector2(0.07, 0.62), Vector2(0.0, 0.61),
]
const NAVE := preload("res://assets/nave_llegada.png")
const TEO_CAIDA := preload("res://assets/teo_caida.png")
const MAPA := preload("res://assets/base.jpg")
const TORMENTA := preload("res://assets/tormenta.png")
const CLINICA := preload("res://assets/enfermeria.png")
const ENERGIA := preload("res://assets/energia_interior.png")
const REFUGIO := preload("res://assets/esclusa_interior.png")
const NORA := preload("res://assets/nora_reposo.png")
const NORA_PASOS := preload("res://assets/nora_caminar.png")
const NOMBRES := {"energia": "ENERGÍA", "cultivos": "SALA DE PLANTAS", "medicina": "ENFERMERÍA", "radio": "CONTROL", "cierre": "PUERTA", "dormitorio": "DORMITORIO"}
const IRIS := preload("res://assets/iris.png")
const IRIS_PASOS := preload("res://assets/iris_caminar.png")
const TEO := preload("res://assets/teo.png")
const TEO_NORMAL := preload("res://assets/teo_normal.png")
const TEO_PASOS := preload("res://assets/teo_caminar.png")
const TEO_RECUPERADO := preload("res://assets/teo_recuperado.png")
const DRON := preload("res://assets/dron.png")
const VEHICULO := preload("res://assets/rover.png")
const OSCURO := Color("#131820")
const LUZ := Color("#83eadc")
const OCRE := Color("#f6a44e")
# Coordenadas sobre la imagen de referencia escalada a 804 × 527.
const LIMITES_BASE := Rect2(-408, -50, 1650, 577)
const TAMANO_MAPA := Vector2(804, 527)
const ENTRADA := Vector2(400, 394)
# El desvío sale del pasillo este. Sus tres brazos se cruzan sobre el piso.
const PASO_DORMITORIO := [
	Rect2(526, 123, 25, 127), Rect2(526, 121, 174, 25), Rect2(668, 103, 27, 43),
]
const PASO_PLANTAS := [Rect2(390, 100, 25, 39), Rect2(390, 121, 161, 20)]
const PASO_ANEXOS := [
	Rect2(-14, 80, 216, 24), Rect2(173, 80, 29, 88), Rect2(692, 120, 154, 26),
]
const INSPECCIONES := {
	"aire": Vector2(167, 280), "mapa": Vector2(448, 281), "plantas": Vector2(466, 96),
	"teo": Vector2(651, 275), "literas": Vector2(616, 89),
	"muestras_frias": Vector2(-285, 62), "filtro_lab": Vector2(-195, 62),
	"capas_hielo": Vector2(-314, 119), "rover_taller": Vector2(1030, 106),
	"sello_traje": Vector2(1030, 164), "repuestos": Vector2(1163, 106),
}
const ENCUADRES := {
	"energia": Rect2(15, 134, 236, 205), "cultivos": Rect2(235, 0, 334, 150),
	"radio": Rect2(278, 142, 249, 198), "medicina": Rect2(554, 132, 245, 209),
	"cierre": Rect2(331, 321, 142, 137), "dormitorio": Rect2(570, 0, 230, 133),
	"laboratorio": Rect2(-392, -33, 402, 240), "taller": Rect2(823, 11, 402, 240),
}
# Recortes de cámara por dentro de la carcasa. Las colisiones usan ROOMS.
const VISTAS := {
	"energia": Rect2(39, 151, 184, 169),
	"cultivos": Rect2(267, 19, 271, 105),
	"radio": Rect2(308, 166, 189, 145),
	"medicina": Rect2(576, 152, 201, 162),
	"dormitorio": Rect2(588, 13, 194, 112),
	"laboratorio": Rect2(-378, -22, 373, 209), "taller": Rect2(836, 22, 374, 214),
}
const ROOMS := {
	"cultivos": Rect2(313, 87, 185, 14),
	"energia": Rect2(75, 158, 135, 151),
	"radio": Rect2(318, 209, 171, 80),
	"medicina": Rect2(585, 208, 187, 100),
	"cierre": Rect2(355, 353, 96, 49),
	"dormitorio": Rect2(600, 58, 169, 50),
	"laboratorio": Rect2(-376, 52, 371, 79), "taller": Rect2(838, 98, 371, 75),
}
const PASILLOS := [
	Rect2(194, 235, 146, 20), Rect2(463, 235, 129, 20),
	Rect2(390, 280, 22, 79),
]
const TERMINALES := {
	"cultivos": Vector2(401, 100), "energia": Vector2(185, 242),
	"radio": Vector2(450, 218), "medicina": Vector2(692, 238),
	"cierre": Vector2(400, 382), "dormitorio": Vector2(685, 89),
}
const EQUIPOS := [
	Rect2(75, 150, 71, 99), Rect2(74, 255, 60, 54),
	Rect2(357, 198, 91, 12), Rect2(394, 211, 14, 9),
	Rect2(381, 230, 42, 34), Rect2(364, 231, 10, 15), Rect2(430, 231, 10, 15),
	Rect2(318, 225, 12, 12), Rect2(475, 225, 13, 12),
	Rect2(313, 274, 30, 16), Rect2(465, 274, 28, 16),
	Rect2(734, 205, 39, 18), Rect2(734, 243, 39, 51),
	Rect2(356, 372, 19, 29), Rect2(431, 351, 18, 57),
]
const SUELO := 351.0
const DISTANCIA_PANORAMA := 700.0
const ROCA := Vector2(250, SUELO)
const MUESTRA := Vector2(659, SUELO)
const SONDEOS := [Vector2(548, SUELO), Vector2(600, SUELO), MUESTRA]
const ABRIGO_TEO := Vector2(463, SUELO)
const ROVER := Vector2(506, SUELO)
const INICIO_CAIDA := 416.0
const ALTURA_TRAJE := 49.0
const ESCLUSA := Vector2(732, SUELO)
const RELES := [Vector2(633, SUELO), Vector2(490, SUELO), Vector2(312, SUELO)]
const ABRIGOS := [Vector2(463, SUELO), Vector2(590, SUELO), Vector2(731, SUELO)]

var interior := false
var chequeo := false
var campo := false
var sondeo := false
var muestra_roca := false
var muestra_preparada := false
var sondeos_hechos: Array[int] = []
var altura := 0.0
var velocidad_vertical := 0.0
var corte := false
var mando_nido := false
var rele_actual := 0
var anclado := false
var plano := false
var objetivo_mision := ""
var pruebas_anexos: Dictionary = {}
var ancho_visible := 804.0
var escala_visual := 1.0
var caminando := false
static var secuencias: Dictionary = {}
static var nube_polvo := _crear_nube_polvo()
var punto := Vector2(111, 343)
var paso := 0.0
var tiempo := 0.0
var aterrizaje := false
var hallazgo := false
var carrera := false
var caida := false
var tiempo_caida := 0.0
var evacuacion := false
var camilla := false
var refugio_teo := false
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
	var rapidez := 120.0 if interior else 176.0
	if evacuacion:
		rapidez = 135.0
	elif mando_nido:
		rapidez = 161.0
	if anclado:
		rapidez *= 0.18
	var aceleracion := 1050.0 if interior else 640.0 if altura > 0.0 else 850.0
	velocidad = velocidad.move_toward(direccion * rapidez, delta * aceleracion)
	if altura > 0.0 or velocidad_vertical > 0.0:
		velocidad_vertical -= 156.0 * delta
		altura = maxf(0.0, altura + velocidad_vertical * delta)
	if absf(direccion.x) > 0.1:
		direccion_izquierda = direccion.x < 0
	var antes := punto
	var avance := (velocidad + Vector2(empuje_viento() if campo else -empuje_viento(), 0)) * delta
	# Comprueba el trayecto aunque el navegador entregue un fotograma largo.
	var pasos := maxi(1, ceili(avance.length() / 3.0)) if interior else 1
	avance /= pasos
	for i in range(pasos):
		for eje in [Vector2(avance.x, 0), Vector2(0, avance.y)]:
			if transitable(punto + eje):
				punto += eje
	var distancia := punto.distance_to(antes)
	caminando = distancia > 0.14 and direccion != Vector2.ZERO and not anclado
	if caminando:
		paso = fposmod(paso + distancia / (42.0 if interior else 67.0), 1.0)


func saltar() -> void:
	if not interior and not evacuacion and not mando_nido and not anclado and altura == 0.0:
		velocidad_vertical = 78.0


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
	var marco := Vector2(ancho_visible, 527)
	var objetivo := punto - Vector2(0, 12)
	var escala := 3.5
	if plano:
		objetivo = LIMITES_BASE.get_center()
		escala = minf(ancho_visible / LIMITES_BASE.size.x, marco.y / LIMITES_BASE.size.y)
	else:
		for zona: String in VISTAS:
			var suelo: Rect2 = ROOMS[zona]
			if not suelo.has_point(punto):
				continue
			var vista: Rect2 = VISTAS[zona]
			var anexo := zona == "laboratorio" or zona == "taller"
			var zoom_sala := 4.0 if anexo else 5.15
			if anexo:
				# Al acercarse a los bancos del sur, la cámara deja ver el equipo.
				objetivo.y += 33.0 * smoothstep(suelo.get_center().y, suelo.end.y - 6.0, punto.y)
			escala = maxf(zoom_sala, maxf(marco.x / vista.size.x, marco.y / vista.size.y))
			var margen := marco / (2.0 * escala)
			objetivo = objetivo.clamp(vista.position + margen, vista.end - margen)
			break
	var peso := 1.0 - exp(-delta * 8.0)
	escala_camara = lerpf(escala_camara, escala, peso)
	centro_camara = centro_camara.lerp(objetivo, peso)


func transitable(destino: Vector2) -> bool:
	if not interior:
		return destino.x >= 42.0 and destino.x <= 756.0 and is_equal_approx(destino.y, SUELO)
	for equipo: Rect2 in EQUIPOS:
		if equipo.grow(3).has_point(destino):
			return false
	for sector: Rect2 in ROOMS.values() + PASILLOS + PASO_DORMITORIO + PASO_PLANTAS + PASO_ANEXOS:
		if sector.has_point(destino):
			return true
	return false


func terminal_cercana() -> String:
	for id: String in TERMINALES:
		if punto.distance_to(TERMINALES[id]) <= 24.0:
			return id
	return ""


func inspeccion_cercana() -> String:
	for id: String in INSPECCIONES:
		if punto.distance_to(INSPECCIONES[id]) <= 15.0:
			return id
	return ""


func _draw() -> void:
	if interior:
		_dibujar_interior()
	else:
		_dibujar_exterior()


func _origen_mundo() -> Vector2:
	if interior:
		var marco := Vector2(ancho_visible, 527)
		var mitad := marco / (2.0 * escala_camara)
		var margen := mitad.min(LIMITES_BASE.size * 0.5)
		var centro := centro_camara.clamp(LIMITES_BASE.position + margen, LIMITES_BASE.end - margen)
		return marco * 0.5 - centro * escala_camara
	var foco := punto.x
	if caida:
		foco = lerpf(foco, ROVER.x, smoothstep(0.0, 1.4, tiempo_caida))
	var temblor := sin(tiempo * 39.0) * intensidad_viento() * 2.4
	var zoom := _zoom_mundo()
	var origen_campo := DISTANCIA_PANORAMA if campo else 0.0
	var foco_global := foco + origen_campo
	return Vector2(clampf(ancho_visible * 0.5 - foco_global * zoom,
		ancho_visible - (DISTANCIA_PANORAMA + 886.0) * zoom, 0.0) + origen_campo * zoom,
		maxf(385.0 - 462.0 * zoom, -76.0 - SUELO * (zoom - 1.0) + temblor))


func _zoom_mundo() -> float:
	return escala_camara if interior else 1.0 + 0.35 * smoothstep(0.0, 1.35, tiempo_caida)


func _dibujar_exterior() -> void:
	draw_set_transform(_origen_mundo(), 0, Vector2.ONE * _zoom_mundo())
	var origen_campo := 0.0 if campo else DISTANCIA_PANORAMA
	draw_texture_rect(SENDERO, Rect2(origen_campo - DISTANCIA_PANORAMA, 0, 886, 462), false)
	const INICIO_MEZCLA := 104.0
	const FIN_MEZCLA := 177.0
	const ANCHO_PANORAMA := 886.0
	var inicio_mezcla := origen_campo + INICIO_MEZCLA
	var fin_mezcla := origen_campo + FIN_MEZCLA
	var uv := PackedVector2Array([Vector2(INICIO_MEZCLA / ANCHO_PANORAMA, 0), Vector2(FIN_MEZCLA / ANCHO_PANORAMA, 0),
		Vector2(FIN_MEZCLA / ANCHO_PANORAMA, 1), Vector2(INICIO_MEZCLA / ANCHO_PANORAMA, 1)])
	draw_polygon(PackedVector2Array([Vector2(inicio_mezcla, 0), Vector2(fin_mezcla, 0),
		Vector2(fin_mezcla, 462), Vector2(inicio_mezcla, 462)]),
		PackedColorArray([Color(1, 1, 1, 0), Color.WHITE, Color.WHITE, Color(1, 1, 1, 0)]), uv, CAMPO)
	var resto := ANCHO_PANORAMA - FIN_MEZCLA
	var ancho_campo := CAMPO.get_width() / ANCHO_PANORAMA
	draw_texture_rect_region(CAMPO, Rect2(fin_mezcla, 0, resto, 462),
		Rect2(FIN_MEZCLA * ancho_campo, 0, resto * ancho_campo, CAMPO.get_height()))
	var rafaga := intensidad_viento()
	var polvo := (0.22 if muestra_roca else 0.06) if sondeo else 0.0 if chequeo or aterrizaje else smoothstep(2.9, 6.7, tiempo)
	var llegada := smoothstep(0.45, 5.2, tiempo) if aterrizaje else 1.0
	var nave := Vector2(182, lerpf(35.0, SUELO - 21, llegada))
	if aterrizaje and llegada < 1.0:
		for i in range(23):
			var x := sin(i * 8.31 + tiempo * 9.0) * (12.0 + llegada * 45.0)
			var y := fposmod(i * 7.53 + tiempo * 145.0, 75.0)
			draw_circle(nave + Vector2(x, y - 8), 1.7 + float(i % 5),
				Color(1.0, 0.61, 0.27, (1.0 - y / 75.0) * 0.66))
	if not campo:
		_sprite(NAVE, nave, 171)
	if campo:
		_sprite(VEHICULO, ROVER + Vector2(26, -5), 48)
	if corte:
		_dibujar_corte()
		_dibujar_polvo(lerpf(0.62, 0.94, smoothstep(0.8, 2.2, tiempo_caida)), 0.76)
		return

	var nora := punto
	var iris := Vector2(284, SUELO)
	var teo := MUESTRA if campo else Vector2(695, SUELO)
	var afectado := caida or decision or extraccion or evacuacion or refugio_teo
	var salida := smoothstep(7.0, 9.6, tiempo)
	if aterrizaje:
		nora = Vector2(lerpf(194, 220, salida), lerpf(SUELO - 21.0, SUELO, salida))
		iris.x = lerpf(194, 284, smoothstep(5.6, 8.7, tiempo))
		teo.x = lerpf(194, MUESTRA.x, smoothstep(9.3, 13.5, tiempo))
	elif carrera:
		iris.x = maxf(54.0, punto.x - 103.0)
		teo.x = minf(MUESTRA.x + 3.0, punto.x + 63.0)
	elif afectado:
		iris.x = maxf(55.0, punto.x - 101.0) if campo else ESCLUSA.x - 10
		teo.x = ROVER.x - 9
		if caida:
			nora.x += 19.0 * smoothstep(0.0, 1.6, tiempo_caida)
			teo.x = lerpf(INICIO_CAIDA + 62.0, teo.x, smoothstep(0.20, 1.65, tiempo_caida))
		elif extraccion:
			teo.x = lerpf(teo.x, punto.x + 27, smoothstep(17.3, 19.5, tiempo))
			if usa_cabrestante:
				draw_line(Vector2(100, SUELO - 12), teo - Vector2(0, 8), OCRE, 2)
		elif evacuacion:
			teo.x = punto.x - 29 if not direccion_izquierda else punto.x + 29
			if not camilla:
				iris.x = teo.x + (14.0 if direccion_izquierda else -14.0)

	if mando_nido:
		_sprite(DRON, punto, 30, sin(tiempo * 10.0), direccion_izquierda)
	elif not aterrizaje or tiempo >= 6.0:
		var corriendo := carrera and caminando
		var iris_x := iris.x
		if aterrizaje:
			iris_x = lerpf(194.0, 284.0, smoothstep(5.6, 8.7, tiempo))
		elif chequeo and not campo:
			iris_x = lerpf(284.0, 717.0, smoothstep(0.0, 5.0, tiempo))
		iris.x = iris_x
		var iris_camina := corriendo or (evacuacion and caminando and not camilla) or (aterrizaje and tiempo < 8.7) or (chequeo and not campo and tiempo < 5.0)
		_sprite(IRIS_PASOS if iris_camina else IRIS, iris, ALTURA_TRAJE, 0.0, carrera or (evacuacion and direccion_izquierda),
			int(fposmod(iris.x / 48.0, 1.0) * 8) if iris_camina else -1)
		if caida and tiempo_caida < 1.65:
			var pose := mini(3, int(tiempo_caida / 0.41))
			_sprite(TEO_CAIDA, teo, [49.0, 39.0, 27.0, 20.0][pose], 0.0, false, pose, 4)
		elif evacuacion and not camilla:
			_sprite(TEO_PASOS if caminando else TEO_NORMAL, teo, 45, 2.0 if caminando else 0.0,
				direccion_izquierda, int(paso * 8) if caminando else -1)
		elif afectado:
			if camilla and (evacuacion or (extraccion and tiempo >= 17.5)):
				draw_line(teo + Vector2(-26, -4), teo + Vector2(25, -4), Color("#c5bbb2"), 5, true)
				draw_circle(teo + Vector2(-16, 1), 3.5, OSCURO)
				draw_circle(teo + Vector2(17, 1), 3.5, OSCURO)
			_sprite(TEO, teo, 18)
		elif not aterrizaje or tiempo >= 9.3:
			var teo_camina := corriendo or (aterrizaje and tiempo < 13.5)
			_sprite(TEO_PASOS if teo_camina else TEO_NORMAL, teo, ALTURA_TRAJE - 1.0, 0.0, carrera,
				int(fposmod(teo.x / 60.0, 1.0) * 8) if teo_camina else -1)
		if not aterrizaje or tiempo >= 7.0:
			var andando := (caminando or (aterrizaje and tiempo < 9.6)) and altura <= 0.0
			var fotograma := int(paso * 8) if not aterrizaje else int(fposmod(nora.x / 61.0, 1.0) * 8)
			_sprite(NORA_PASOS if andando else NORA, nora, ALTURA_TRAJE - 2.0, altura + (3.0 if anclado else 0.0),
				direccion_izquierda, fotograma if andando else -1)
	_dibujar_polvo(polvo, rafaga)
	draw_set_transform(_origen_mundo(), 0, Vector2.ONE * _zoom_mundo())
	if mando_nido:
		for i in range(RELES.size()):
			var torre: Vector2 = RELES[i]
			draw_line(torre, torre + Vector2(0, -34), OSCURO, 5, true)
			draw_circle(torre + Vector2(0, -35), 5, LUZ if i <= rele_actual else OCRE)
		var objetivo: Vector2 = RELES[rele_actual] if rele_actual < RELES.size() else ESCLUSA
		_baliza(objetivo + Vector2(0, -91), "PUESTO %d" % (rele_actual + 1) if rele_actual < RELES.size() else "REGRESO", LUZ)
	elif refugio_teo:
		_baliza(ABRIGO_TEO + Vector2(0, -91), "ABRIGO", LUZ)
	elif sondeo and muestra_roca and not muestra_preparada:
		for i in range(SONDEOS.size()):
			var sitio: Vector2 = SONDEOS[i]
			draw_circle(sitio - Vector2(0, 5), 4, LUZ if sondeos_hechos.has(i) else OCRE)
			_baliza(sitio + Vector2(0, -68 - 17 * (i % 2)), str(i + 1), LUZ if sondeos_hechos.has(i) else OCRE)
	elif sondeo:
		var meta := MUESTRA + Vector2(44, 0) if muestra_preparada else ROCA
		draw_circle(meta - Vector2(0, 7), 5, LUZ)
		_baliza(meta + Vector2(0, -82), "CAJA DE MUESTRAS" if muestra_preparada else "VETA DE HIELO" if muestra_roca else "PIEDRA", LUZ)
	elif chequeo and not campo:
		_baliza(ESCLUSA + Vector2(0, -102), "REFUGIO", LUZ)
	elif carrera or evacuacion:
		var meta := Vector2(60, SUELO) if campo else ESCLUSA
		_baliza(meta + Vector2(0, -102), "←  REGRESO" if campo else "REFUGIO", LUZ)
		for refugio: Vector2 in ABRIGOS:
			draw_arc(refugio, 21, 0.0, TAU, 28, Color(0.68, 0.94, 0.82, 0.52), 1.5, true)
	draw_set_transform(Vector2.ZERO)


static func _crear_nube_polvo() -> GradientTexture2D:
	var gradiente := Gradient.new()
	gradiente.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
	var nube := GradientTexture2D.new()
	nube.width = 128
	nube.height = 128
	nube.gradient = gradiente
	nube.fill = GradientTexture2D.FILL_RADIAL
	nube.fill_from = Vector2(0.5, 0.5)
	nube.fill_to = Vector2(1.0, 0.5)
	return nube


# La tormenta pertenece a la pantalla, no al panorama que está debajo.
func _dibujar_polvo(densidad: float, rafaga: float) -> void:
	draw_set_transform(Vector2.ZERO)
	if densidad <= 0.0:
		return
	const ALTO := 385.0
	draw_rect(Rect2(0, 0, ancho_visible, ALTO),
		Color(0.49, 0.23, 0.15, densidad * (0.29 + rafaga * 0.31)))
	for i in range(14):
		var x := fposmod(i * 193.0 - tiempo * (81.0 + i * 8.0), ancho_visible + 680.0) - 340.0
		var y := (i + 0.5) * ALTO / 14.0
		draw_texture_rect(nube_polvo, Rect2(x - 280.0, y - 60.0, 560.0, 120.0), false,
			Color(0.99, 0.66, 0.40, densidad * (0.14 + rafaga * 0.22)))
	for i in range(170):
		var x := fposmod(i * 83.7 - tiempo * (180 + i % 8 * 46), ancho_visible + 170.0)
		var y := fposmod(i * 51.9 + tiempo * 13.0, ALTO + 12.0) - 6.0
		var estela := 13.0 + rafaga * 53.0 + i % 21
		draw_line(Vector2(x, y), Vector2(x - estela, y + 4.0),
			Color(1, 0.71, 0.47, densidad * (0.14 + rafaga * 0.32)), 1.35, true)


func _dibujar_corte() -> void:
	var roto := tiempo_caida >= 1.25
	var extremo := Vector2(535, 320)
	var caja := Vector2(603, 313)
	draw_polyline(PackedVector2Array([caja, Vector2(576, 327), Vector2(557, 326) if roto else extremo]),
		Color("#242230"), 3.8, true)
	if roto:
		draw_line(extremo, Vector2(547, 330), Color("#242230"), 3.8, true)
		if tiempo_caida < 2.2:
			for i in range(12):
				var chispa := Vector2.from_angle(i * TAU / 12.0) * (6 + 25 * (tiempo_caida - 1.25))
				draw_line(Vector2(550, 327) + chispa, Vector2(550, 327) + chispa * 1.32, OCRE, 2, true)
	var luz := Color("#5b292b") if roto else LUZ
	draw_rect(Rect2(caja + Vector2(1, -4), Vector2(9, 4)), luz)
	_baliza(caja + Vector2(-45, -92), "CABLE SUELTO" if roto else "ENERGÍA DEL SOL", OCRE if roto else LUZ)


func _dibujar_desvio() -> void:
	var tramos := PASO_DORMITORIO + PASO_PLANTAS
	# En las entradas se conserva el umbral de la ilustración.
	tramos[2] = Rect2(668, 116, 27, 30)
	tramos[3] = Rect2(390, 108, 25, 31)
	tramos.append(Rect2(514, 235, 45, 20))
	tramos.append_array(PASO_ANEXOS)
	for corredor: Rect2 in tramos:
		draw_rect(corredor.grow(4), Color("#2e2126"))
		draw_rect(corredor.grow(2), Color("#ad9480"))
	for corredor: Rect2 in tramos:
		draw_rect(corredor, Color("#3d424a"))
	for corredor: Rect2 in tramos:
		var horizontal := corredor.size.x > corredor.size.y
		var avance := Vector2.RIGHT if horizontal else Vector2.DOWN
		var ancho := Vector2.DOWN if horizontal else Vector2.RIGHT
		var longitud := int(corredor.size.x if horizontal else corredor.size.y)
		var piso := corredor.size.y if horizontal else corredor.size.x
		for i in range(6, longitud - 5, 8):
			var inicio := corredor.position + avance * i
			draw_line(inicio + ancho * 4, inicio + ancho * (piso - 4),
				Color("#262931"), 1.0)
			draw_line(inicio + avance + ancho * 4, inicio + avance + ancho * (piso - 4),
				Color("#61666b"), 1.0)
			if i % 24 == 6:
				var luz := OCRE
				draw_line(inicio + ancho * 2, inicio + ancho * 2 + avance * 3, luz, 1.4)
				draw_line(inicio + ancho * (piso - 2),
					inicio + ancho * (piso - 2) + avance * 3, luz, 1.4)
	for y in [220, 208, 196, 184, 172, 160]:
		draw_polyline(PackedVector2Array([Vector2(533, y), Vector2(538, y - 5),
			Vector2(543, y)]), LUZ, 1.4, true)


func _dibujar_terreno_anexos() -> void:
	var escala_mapa := MAPA.get_size() / TAMANO_MAPA
	const BALDOSA := 96
	var muestras := [Vector2(6, 22), Vector2(126, 6), Vector2(7, 354)]
	for zona: Rect2i in [Rect2i(-408, -50, 408, 577), Rect2i(0, -50, 804, 50), Rect2i(804, -50, 438, 577)]:
		for y in range(zona.position.y, zona.end.y, BALDOSA):
			for x in range(zona.position.x, zona.end.x, BALDOSA):
				var tamano := Vector2(mini(BALDOSA, zona.end.x - x), mini(BALDOSA, zona.end.y - y))
				var origen: Vector2 = muestras[posmod(x * 17 + y * 31 + (x - zona.position.x) / BALDOSA, muestras.size())]
				draw_texture_rect_region(MAPA, Rect2(Vector2(x, y), tamano),
					Rect2(origen * escala_mapa, tamano * escala_mapa))


func _dibujar_interior() -> void:
	draw_rect(Rect2(0, 0, ancho_visible, 527), Color("#452c29"))
	draw_set_transform(_origen_mundo(), 0, Vector2.ONE * escala_camara)
	_dibujar_terreno_anexos()
	draw_texture_rect(MAPA, Rect2(Vector2.ZERO, TAMANO_MAPA), false)
	var fondos := {
		"energia": ENERGIA, "cultivos": PLANTAS, "medicina": CLINICA,
		"cierre": REFUGIO, "dormitorio": DORMITORIO, "laboratorio": LABORATORIO, "taller": TALLER,
	}
	for id: String in fondos:
		draw_texture_rect(fondos[id], ENCUADRES[id], false)
	var silueta := PackedVector2Array()
	for vertice: Vector2 in CONTORNO_CONTROL:
		silueta.append(Vector2(279, 141) + vertice * Vector2(247, 197))
	draw_polygon(silueta, PackedColorArray([Color.WHITE]), PackedVector2Array(CONTORNO_CONTROL), CONTROL)
	_dibujar_desvio()
	if not cultivo_activo:
		draw_rect(Rect2(259, 33, 282, 88), Color(0.14, 0.19, 0.26, 0.52))
	if radio_enviada:
		draw_circle(Vector2(402, 188), 4.0, Color(0.34, 1.0, 0.84, 0.55))
	var estado_teo := LUZ if atendido or teo_recuperado else Color("#ee8377") if lesion_grave else OCRE
	if teo_recuperado:
		_sprite(TEO_RECUPERADO, Vector2(365, 216), 33)
	else:
		_sprite(TEO_CAMA, Vector2(752, 213), 29)
	draw_circle(Vector2(728, 181), 2.0 + sin(tiempo * 6) * 0.5, estado_teo)
	var patrulla := fposmod(tiempo - 17.0, 8.0)
	var iris_x := 457.0 + 21.0 * (smoothstep(0.5, 2.7, patrulla) - smoothstep(4.1, 6.3, patrulla))
	var iris_camina := (patrulla > 0.5 and patrulla < 2.7) or (patrulla > 4.1 and patrulla < 6.3)
	_sprite(IRIS_PASOS if iris_camina else IRIS, Vector2(iris_x, 215), 31, 0.0,
		patrulla >= 4.1, int(fposmod(iris_x / 20.0, 1.0) * 8) if iris_camina else -1)
	_sprite(DRON, Vector2(340, 257), 22, sin(tiempo * 4.5))
	var terminal := terminal_cercana()
	var radio_marca := 3.2 * minf(1.0, 2.4 / escala_camara)
	for id: String in TERMINALES:
		var color := LUZ if id == objetivo_mision or terminal == id else OCRE
		draw_circle(TERMINALES[id] + Vector2(0, 8), radio_marca, color, false, 1.0, true)
	for id: String in INSPECCIONES:
		var sitio: Vector2 = INSPECCIONES[id]
		if plano or punto.distance_to(sitio) < 108:
			draw_circle(sitio, radio_marca, LUZ if pruebas_anexos.has(id) else Color("#ebc8ff"), false, 1.0, true)
	_sprite(NORA_PASOS if caminando else NORA, punto, 32, 0.0,
		direccion_izquierda, int(paso * 8) if caminando else -1)
	draw_set_transform(Vector2.ZERO)
	var carteles := {
		Vector2(538, 208): "↑ DORMITORIO Y TALLER",
		Vector2(538, 110): "← PLANTAS   ·   DORMITORIO Y TALLER →",
		Vector2(188, 148): "↑ LABORATORIO",
		Vector2(188, 70): "← LABORATORIO",
		Vector2(750, 109): "TALLER →",
		Vector2(852, 117): "← CORREDOR CENTRAL",
		Vector2(-30, 75): "ENERGÍA →",
	}
	for sitio: Vector2 in carteles:
		if not plano and punto.distance_to(sitio) < 72:
			_baliza(_origen_mundo() + sitio * escala_camara, carteles[sitio], LUZ)
	if plano:
		var nombres_plano := {
			"laboratorio": "LABORATORIO DE AGUA", "taller": "TALLER",
			"energia": "ENERGÍA", "radio": "CONTROL", "dormitorio": "DORMITORIO",
			"cultivos": "PLANTAS", "medicina": "ENFERMERÍA", "cierre": "PUERTA",
		}
		for id: String in nombres_plano:
			var encuadre: Rect2 = ENCUADRES[id]
			var marca := _origen_mundo() + (encuadre.get_center() - Vector2(0, 44)) * escala_camara
			_baliza(marca, nombres_plano[id], LUZ if id == objetivo_mision else Color("#f3e3cc"))
	if not plano and TERMINALES.has(objetivo_mision):
		var destino: Vector2 = TERMINALES[objetivo_mision]
		var marca := _origen_mundo() + destino * escala_camara
		var etiqueta := marca - Vector2(0, 44.0)
		var visible := Vector2(clampf(etiqueta.x, 82, ancho_visible - 82), clampf(etiqueta.y, 58, 410))
		if etiqueta.distance_to(visible) > 15.0:
			var hacia := (marca - visible).normalized()
			draw_line(visible - hacia * 18, visible, LUZ, 2.2, true)
			draw_circle(visible, 3, LUZ, true, -1, true)
		_baliza(visible, NOMBRES[objetivo_mision], LUZ)


func _sprite(textura: Texture2D, ancla: Vector2, alto: float, balanceo := 0.0,
		invertido := false, fotograma := -1, columnas := 4) -> void:
	if not recortes.has(textura):
		recortes[textura] = textura.get_image().get_used_rect()
	var region: Rect2 = recortes[textura]
	if textura == TEO_CAMA:
		var tamano := textura.get_size()
		region = Rect2(tamano * Vector2(0.56, 0.01), tamano * Vector2(0.43, 0.98))
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
		var zoom := _zoom_mundo()
		var desplazamiento := _origen_mundo()
		draw_set_transform(desplazamiento + ancla * zoom, 0, Vector2(zoom, zoom * 0.28))
		draw_circle(Vector2.ZERO, 8.0, Color(0.08, 0.06, 0.11, 0.25), true, -1.0, true)
		draw_set_transform(desplazamiento, 0, Vector2.ONE * zoom)
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
