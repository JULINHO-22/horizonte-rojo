class_name PuestoUmbra
extends Node2D

const SENDERO := preload("res://assets/refugio_horizonte.png")
const CAMPO := preload("res://assets/barranco_horizonte.png")
const TALLER := preload("res://assets/taller_umbra.png")
const CONTROL := preload("res://assets/control_pasillos.png")
const PLANTAS := preload("res://assets/plantas_horizonte.png")
const DORMITORIO := preload("res://assets/dormitorio_umbra.png")
const NAVE := preload("res://assets/NarrativaInicio/ModuloDescensoAterrizajePixelArt.png")
const PERCY := preload("res://assets/NarrativaInicio/Percy(robotQueExuisteEnLaLuna).png")
const MAPA := preload("res://assets/base.jpg")
const TORMENTA := preload("res://assets/tormenta.png")
const CENTRO_AGUA := preload("res://assets/laboratorio_agua.png")
const ENERGIA := preload("res://assets/energia_interior.png")
const REFUGIO := preload("res://assets/esclusa_interior.png")
const NORA := preload("res://assets/nora_reposo.png")
const NORA_PASOS := preload("res://assets/nora_caminar.png")
const NOMBRES := {"energia": "ENERGÍA", "cultivos": "SALA DE PLANTAS", "agua": "CENTRO DE AGUA", "radio": "CONTROL", "dormitorio": "DORMITORIO"}
const IRIS := preload("res://assets/iris.png")
const IRIS_PASOS := preload("res://assets/iris_caminar.png")
const TEO_NORMAL := preload("res://assets/teo_normal.png")
const TEO_PASOS := preload("res://assets/teo_caminar.png")
const DRON := preload("res://assets/dron.png")
const CAJA_CERRADA := preload("res://assets/caja_hielo_cerrada.png")
const CAJA_ABIERTA := preload("res://assets/caja_hielo_abierta.png")
const NUCLEO_HIELO := preload("res://assets/nucleo_hielo.png")
const OSCURO := Color("#131820")
const LUZ := Color("#83eadc")
const MARFIL_SALA := Color("#e7d9c8")
const OCRE := Color("#f6a44e")
# Coordenadas sobre la imagen de referencia escalada a 804 × 527.
const LIMITES_BASE := Rect2(-148, -72, 1024, 588)
const TAMANO_MAPA := Vector2(804, 527)
const ENTRADA := Vector2(400, 394)
const CENTRO_ESCLUSA_X := 402.0
const LIMITE_CONTROL := 339.0
const PASO_ESCLUSA := Rect2(393, 310, 20, 52)
# El desvío sale del pasillo este. Sus tres brazos se cruzan sobre el piso.
const PASO_DORMITORIO := [
	Rect2(526, 123, 25, 127), Rect2(526, 121, 174, 25), Rect2(668, 103, 27, 43),
]
const PASO_PLANTAS := [Rect2(389, 98, 31, 41), Rect2(390, 121, 161, 20)]
const SENDAS_PLANTAS := [
	Rect2(362, 48, 157, 7), Rect2(496, 53, 20, 36),
	Rect2(373, 92, 55, 19),
]
const ENTRADA_AGUA := Vector2(191, 42)
const PASO_AGUA := [Rect2(166, 32, 40, 20), Rect2(182, 41, 24, 129)]
const PASO_TALLER := Rect2(526, 235, 48, 20)
const INSPECCIONES := {
	"aire": Vector2(167, 280), "mapa": Vector2(442, 215), "plantas": Vector2(466, 93),
	"literas": Vector2(616, 89),
	"rover_taller": Vector2(713, 229),
	"sello_traje": Vector2(716, 277), "repuestos": Vector2(816, 229),
}
const ENCUADRES := {
	"energia": Rect2(15, 134, 236, 205), "cultivos": Rect2(235, 0, 334, 150),
	"radio": Rect2(268, 137, 270, 207), "agua": Rect2(-128, -52, 306, 188),
	"cierre": Rect2(331, 321, 142, 137), "dormitorio": Rect2(570, 0, 230, 133),
	"taller": Rect2(560, 155, 306, 184),
}
# Recortes de cámara por dentro de la carcasa. Las colisiones usan ROOMS.
const VISTAS := {
	"energia": Rect2(39, 151, 184, 169),
	"cultivos": Rect2(267, 19, 271, 105),
	"radio": Rect2(279, 155, 248, 174),
	"agua": Rect2(-116, -43, 284, 170),
	"dormitorio": Rect2(588, 13, 194, 112),
	"taller": Rect2(570, 165, 286, 164),
}
const ROOMS := {
	"cultivos": Rect2(299, 86, 239, 10),
	"energia": Rect2(46, 163, 175, 137),
	"radio": Rect2(282, 209, 242, 110),
	"agua": Rect2(-114, 17, 286, 60),
	"cierre": Rect2(369, 354, 69, 42),
	"dormitorio": Rect2(600, 58, 169, 50),
	"taller": Rect2(570, 222, 284, 60),
}
const PASILLOS := [
	Rect2(194, 235, 100, 20), Rect2(511, 235, 40, 20),
	PASO_ESCLUSA, PASO_TALLER,
]
const TERMINALES := {
	"cultivos": Vector2(407, 97), "energia": Vector2(185, 242),
	"radio": Vector2(450, 218),
	"cierre": Vector2(400, 382), "dormitorio": Vector2(685, 89),
}
const EQUIPOS := [
	Rect2(34, 144, 106, 77), Rect2(124, 144, 34, 78), Rect2(42, 253, 104, 49),
	Rect2(313, 55, 56, 27), Rect2(380, 55, 43, 27), Rect2(436, 55, 52, 27),
	Rect2(356, 372, 19, 29), Rect2(431, 351, 18, 57),
]
const ALTURA_INTERIOR := 25.0
const EQUIPO_AGUA := [Vector2(25, 19), Vector2(-1, 19), Vector2(51, 19)]
const ALCANCE_AGUA := 10.0
const SUELO := 351.0
const DISTANCIA_PANORAMA := 700.0
const MUESTRA := Vector2(659, SUELO)
const CAJA_HIELO := Vector2(703, SUELO)
const SONDEOS := [Vector2(555, SUELO), Vector2(607, SUELO), MUESTRA]
const PUNTO_AVISO := 416.0
const ALTURA_TRAJE := 49.0
const ESCLUSA := Vector2(732, SUELO)
const REVISION_SOLAR := Vector2(460, SUELO)
const RELES := [Vector2(633, SUELO), Vector2(490, SUELO), Vector2(312, SUELO)]
const ABRIGOS := [Vector2(463, SUELO), Vector2(590, SUELO), Vector2(731, SUELO)]

var interior := false
var cielo_sereno := false
var bienvenida_percy := false
var chequeo := false
var guia_pluto := false
var panel_comprobado := false
var avance_panel := 0.0
var pluto_superficie_x := 0.0
var campo := false
var sondeo := false
var caja_abierta := false
var carga_hielo := false
var corte_suelo := -1
var perforando := false
var avance_muestra := 0.0
var polvo_taladro_hasta := 0.0
var frente_polvo := 0.0
var sondeos_hechos: Array[int] = []
var hielo_en_mano := false
var esclusa_activa := false
var avance_esclusa := 0.0
var agua_en_curso := false
var etapa_agua := 0
var avance_agua := 0.0
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
var tiempo_averia := 0.0
var evacuacion := false
var cultivo_activo := true
var reserva_en_prueba := false
var desvio_energia := false
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
	var rapidez := 79.0 if interior else 176.0
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
		paso = fposmod(paso + distancia / (33.0 if interior else 67.0), 1.0)
	if guia_pluto:
		var siguiente := ESCLUSA.x - 14.0 if panel_comprobado else REVISION_SOLAR.x
		pluto_superficie_x = move_toward(pluto_superficie_x, minf(siguiente, punto.x + 50.0), delta * 183.0)


func saltar() -> void:
	if not interior and not evacuacion and not mando_nido and not anclado and altura == 0.0:
		velocidad_vertical = 78.0


func intensidad_viento() -> float:
	if interior or chequeo or aterrizaje:
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
	var marco := Vector2(ancho_visible, 527)
	var objetivo := punto - Vector2(0, 12)
	var escala := 3.25
	if not plano and (esclusa_activa or en_esclusa()):
		objetivo = Vector2(CENTRO_ESCLUSA_X, clampf(punto.y - 2.0, 354.0, 408.0))
		escala = 6.45
	elif plano:
		objetivo = LIMITES_BASE.get_center()
		escala = minf(ancho_visible / LIMITES_BASE.size.x, marco.y / LIMITES_BASE.size.y)
	else:
		for zona: String in VISTAS:
			var suelo: Rect2 = ROOMS[zona]
			if not suelo.has_point(punto):
				continue
			var vista: Rect2 = VISTAS[zona]
			var anexo := zona in ["agua", "taller"]
			var zoom_sala := 3.85 if anexo else 4.45
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


func en_esclusa() -> bool:
	return punto.y >= LIMITE_CONTROL and (ROOMS.cierre.has_point(punto) or PASO_ESCLUSA.has_point(punto))


func transitable(destino: Vector2) -> bool:
	if not interior:
		return destino.x >= 42.0 and destino.x <= 756.0 and is_equal_approx(destino.y, SUELO)
	for equipo: Rect2 in EQUIPOS:
		if equipo.grow(3).has_point(destino):
			return false
	for sector: Rect2 in ROOMS.values() + PASILLOS + PASO_DORMITORIO + PASO_PLANTAS + PASO_AGUA + SENDAS_PLANTAS:
		if sector.has_point(destino):
			return true
	return false


func terminal_cercana() -> String:
	if punto.distance_to(EQUIPO_AGUA[0]) <= ALCANCE_AGUA:
		return "agua"
	for id: String in TERMINALES:
		if punto.distance_to(TERMINALES[id]) <= 22.0:
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


func proyectar_suelo(sitio: Vector2) -> Vector2:
	return (_origen_mundo() + sitio * _zoom_mundo()) * escala_visual


func _origen_mundo() -> Vector2:
	if interior:
		var marco := Vector2(ancho_visible, 527)
		var mitad := marco / (2.0 * escala_camara)
		var margen := mitad.min(LIMITES_BASE.size * 0.5)
		var centro := centro_camara.clamp(LIMITES_BASE.position + margen, LIMITES_BASE.end - margen)
		return marco * 0.5 - centro * escala_camara
	var foco := punto.x
	if perforando or hallazgo:
		foco = MUESTRA.x
	var temblor := sin(tiempo * 39.0) * intensidad_viento() * 2.4
	var zoom := _zoom_mundo()
	var origen_campo := DISTANCIA_PANORAMA if campo else 0.0
	var foco_global := foco + origen_campo
	var suelo_en_pantalla := 252.0 if perforando or hallazgo else 275.0
	return Vector2(clampf(ancho_visible * 0.5 - foco_global * zoom,
		ancho_visible - (DISTANCIA_PANORAMA + 886.0) * zoom, 0.0) + origen_campo * zoom,
		maxf(385.0 - 462.0 * zoom, suelo_en_pantalla - SUELO * zoom + temblor))


func _zoom_mundo() -> float:
	if interior:
		return escala_camara
	if perforando or hallazgo:
		return 1.30
	if sondeo:
		return 1.12
	return 1.0


func _dibujar_exterior() -> void:
	var origen := _origen_mundo()
	var zoom := _zoom_mundo()
	var origen_campo := 0.0 if campo else DISTANCIA_PANORAMA
	draw_set_transform(origen, 0, Vector2.ONE * zoom)
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
	var rafaga := 0.0 if cielo_sereno else intensidad_viento()
	var polvo := maxf(frente_polvo, 0.08 if sondeo else 0.0 if chequeo or aterrizaje else smoothstep(2.9, 6.7, tiempo))
	if cielo_sereno:
		polvo = 0.0
	if frente_polvo > 0.0:
		draw_set_transform(Vector2.ZERO)
		draw_rect(Rect2(0, 0, ancho_visible, 385), Color(0.16, 0.11, 0.18, frente_polvo * 0.56))
		draw_set_transform(origen, 0, Vector2.ONE * zoom)
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
	if corte:
		_dibujar_corte()
		_dibujar_polvo(lerpf(0.62, 0.94, smoothstep(0.8, 2.2, tiempo_averia)), 0.76)
		return

	var nora := punto
	var iris := Vector2(284, SUELO)
	var teo := MUESTRA if campo else Vector2(695, SUELO)
	var salida := smoothstep(7.0, 9.6, tiempo)
	if aterrizaje:
		nora = Vector2(lerpf(194, 220, salida), lerpf(SUELO - 21.0, SUELO, salida))
		iris.x = lerpf(194, 284, smoothstep(5.6, 8.7, tiempo))
		teo.x = lerpf(194, MUESTRA.x, smoothstep(9.3, 13.5, tiempo))
	elif sondeo or perforando or hallazgo:
		iris.x = MUESTRA.x - 37
		teo.x = MUESTRA.x + 35
		if perforando:
			iris.x += 20 * smoothstep(0.0, 0.35, avance_muestra)
			teo.x -= 20 * sin(PI * avance_muestra)
	elif guia_pluto:
		iris.x = ESCLUSA.x - 10.0
		teo.x = 205.0
	elif bienvenida_percy:
		iris.x = clampf(punto.x + 35, 38, 780)
		teo.x = clampf(punto.x - 35, 38, 780)

	elif carrera or evacuacion:
		var sentido := -1.0 if direccion_izquierda else 1.0
		iris.x = clampf(punto.x + 46.0 * sentido, 38.0, 784.0)
		teo.x = clampf(punto.x - 42.0 * sentido, 38.0, 784.0)

	if mando_nido:
		_sprite(DRON, punto, 30, sin(tiempo * 10.0), direccion_izquierda)
	elif not aterrizaje or tiempo >= 6.0:
		var corriendo := carrera and caminando
		var iris_x := iris.x
		if aterrizaje:
			iris_x = lerpf(194.0, 284.0, smoothstep(5.6, 8.7, tiempo))
		elif chequeo and not campo and not guia_pluto and not bienvenida_percy:
			iris_x = lerpf(284.0, 717.0, smoothstep(0.0, 5.0, tiempo))
		iris.x = iris_x
		var iris_camina := (perforando and avance_muestra < 0.34) or corriendo or (evacuacion and caminando) or (aterrizaje and tiempo < 8.7) or (chequeo and not campo and not guia_pluto and tiempo < 5.0)
		iris_camina = iris_camina or (bienvenida_percy and caminando)
		_sprite(IRIS_PASOS if iris_camina else IRIS, iris, ALTURA_TRAJE, 0.0, (carrera or evacuacion) and direccion_izquierda,
			int(fposmod(iris.x / 48.0, 1.0) * 8) if iris_camina else -1)
		if not aterrizaje or tiempo >= 9.3:
			var teo_camina := perforando or corriendo or (evacuacion and caminando) or (aterrizaje and tiempo < 13.5)
			teo_camina = teo_camina or (bienvenida_percy and caminando)
			_sprite(TEO_PASOS if teo_camina else TEO_NORMAL, teo, ALTURA_TRAJE - 1.0, 0.0, (carrera or evacuacion) and direccion_izquierda,
				int(fposmod(teo.x / 60.0, 1.0) * 8) if teo_camina else -1)
		if not aterrizaje or tiempo >= 7.0:
			var andando := (caminando or (aterrizaje and tiempo < 9.6)) and altura <= 0.0
			var fotograma := int(fposmod(nora.x / 61.0, 1.0) * 8) if aterrizaje else int(paso * 8)
			_sprite(NORA_PASOS if andando else NORA, nora, ALTURA_TRAJE - 2.0, altura + (3.0 if anclado else 0.0),
				direccion_izquierda, fotograma if andando else -1)
	if guia_pluto:
		var pluto := Vector2(pluto_superficie_x, SUELO)
		_sprite(DRON, pluto, 31, 0.0, false)
		draw_circle(pluto - Vector2(6, 32), 2.2, LUZ, true, -1.0, true)
	if bienvenida_percy:
		_sprite(PERCY, Vector2(minf(punto.x + 85, ESCLUSA.x - 44), SUELO), 39)
	if perforando:
		_dibujar_extraccion()
	elif caja_abierta:
		_dibujar_objeto(CAJA_ABIERTA, CAJA_HIELO - Vector2(0, 1), 25)
		var apoyo := nora + Vector2(-8 if direccion_izquierda else 8, -16) if hielo_en_mano else MUESTRA + Vector2(5, -1)
		_dibujar_objeto(NUCLEO_HIELO, apoyo, 15)
	elif carga_hielo and (hallazgo or carrera or evacuacion):
		_dibujar_maletin(teo, caminando and (carrera or evacuacion))
	_dibujar_polvo(polvo, maxf(rafaga, frente_polvo * 0.55))
	draw_set_transform(_origen_mundo(), 0, Vector2.ONE * _zoom_mundo())
	if mando_nido:
		for i in range(RELES.size()):
			var torre: Vector2 = RELES[i]
			draw_line(torre, torre + Vector2(0, -34), OSCURO, 5, true)
			draw_circle(torre + Vector2(0, -35), 5, LUZ if i <= rele_actual else OCRE)
		var objetivo: Vector2 = RELES[rele_actual] if rele_actual < RELES.size() else ESCLUSA
		_baliza(objetivo + Vector2(0, -91), "PUESTO %d" % (rele_actual + 1) if rele_actual < RELES.size() else "REGRESO", LUZ)
	elif sondeo:
		if caja_abierta:
			_marca_sondeo(CAJA_HIELO if hielo_en_mano else MUESTRA, LUZ, true)
		else:
			for i in range(SONDEOS.size()):
				var sitio: Vector2 = SONDEOS[i]
				var color := LUZ if sondeos_hechos.has(i) else Color.WHITE
				_marca_sondeo(sitio, color, absf(punto.x - sitio.x) <= 23.0)
				if sondeos_hechos.has(i):
					_dibujar_corte_suelo(i)
	elif guia_pluto:
		var destino := ESCLUSA if panel_comprobado else REVISION_SOLAR
		var sentido := 1.0 if destino.x >= punto.x else -1.0
		var tramo := minf(250.0, absf(destino.x - punto.x))
		if tramo >= 20.0:
			for i in range(20, int(tramo), 20):
				var x := destino.x - i * sentido
				var color := Color(LUZ, 0.26 + 0.45 * (0.5 + 0.5 * sin(tiempo * 5.0 - x * 0.045)))
				var centro := Vector2(x, SUELO + 6)
				draw_polyline(PackedVector2Array([centro + Vector2(-4 * sentido, -2), centro + Vector2(2 * sentido, 0),
					centro + Vector2(-4 * sentido, 2)]), color, 2.0, true)
		_marca_sondeo(destino, LUZ, punto.distance_to(destino) <= 30.0)
		if not panel_comprobado and avance_panel > 0.0:
			draw_arc(destino + Vector2(0, -8), 14.0, -PI * 0.5, TAU * avance_panel - PI * 0.5, 32, LUZ, 2.0, true)
	elif chequeo and not campo:
		_baliza(ESCLUSA + Vector2(0, -102), "REFUGIO", LUZ)
	elif carrera or evacuacion:
		var meta := Vector2(60, SUELO) if campo else ESCLUSA
		_baliza(meta + Vector2(0, -102), "←  REGRESO" if campo else "REFUGIO", LUZ)
		for refugio: Vector2 in ABRIGOS:
			draw_arc(refugio, 21, 0.0, TAU, 28, Color(0.68, 0.94, 0.82, 0.52), 1.5, true)
	draw_set_transform(Vector2.ZERO)


func _marca_sondeo(sitio: Vector2, color: Color, activa: bool) -> void:
	var radio := 9.0 if activa else 6.0
	var centro := sitio + Vector2(0, 4)
	draw_set_transform(_origen_mundo() + centro * _zoom_mundo(), 0, Vector2(_zoom_mundo(), _zoom_mundo() * 0.47))
	draw_arc(Vector2.ZERO, radio, 0, TAU, 28, OSCURO, 4.0, true)
	draw_arc(Vector2.ZERO, radio, 0, TAU, 28, color, 1.8, true)
	draw_set_transform(_origen_mundo(), 0, Vector2.ONE * _zoom_mundo())
	if activa or caja_abierta:
		var punta := sitio - Vector2(0, 42 + 2 * sin(tiempo * 4))
		var flecha := PackedVector2Array([punta + Vector2(-6, -5), punta + Vector2(6, -5), punta + Vector2(0, 3)])
		draw_colored_polygon(flecha, color)
		flecha.append(flecha[0])
		draw_polyline(flecha, OSCURO, 1.6, true)


func _dibujar_corte_suelo(indice: int) -> void:
	var sitio: Vector2 = SONDEOS[indice]
	var centro := sitio + Vector2(0, 13)
	var tierra := PackedVector2Array([centro + Vector2(-15, -4), centro + Vector2(8, -6),
		centro + Vector2(15, -1), centro + Vector2(10, 10), centro + Vector2(-11, 10), centro + Vector2(-16, 4)])
	draw_colored_polygon(tierra, Color("#623b33"))
	tierra.append(tierra[0])
	draw_polyline(tierra, OSCURO, 2.2, true)
	if indice == 1:
		draw_polyline(PackedVector2Array([centro + Vector2(-14, -3), centro + Vector2(0, -4),
			centro + Vector2(12, -2)]), Color("#e1f4f7"), 2.3, true)
	elif indice == 2:
		draw_colored_polygon(PackedVector2Array([centro + Vector2(-13, 4), centro + Vector2(-3, 2),
			centro + Vector2(13, 0), centro + Vector2(9, 7), centro + Vector2(-10, 8)]), Color("#3c778c"))
		draw_polyline(PackedVector2Array([centro + Vector2(-12, 4), centro + Vector2(-4, 4),
			centro + Vector2(2, 2), centro + Vector2(12, 1)]), Color("#bde7f1"), 1.6, true)
	for i in range(6):
		var grano := centro + Vector2(-11 + i * 4, (i * 5 % 9) - 2)
		draw_circle(grano, 0.85, Color("#bd896a"))
	if indice == corte_suelo and tiempo < polvo_taladro_hasta:
		var dt := 0.7 - (polvo_taladro_hasta - tiempo)
		for i in range(9):
			var salida := Vector2(float(i - 4) * dt * 9, -sin(dt * PI / 0.7) * (6 + i))
			draw_circle(sitio + salida, 2.0, Color("#d29366"))


func _dibujar_maletin(portador: Vector2, en_marcha: bool) -> void:
	const MANO_TEO := [
		Vector2(5, -22), Vector2(8, -21), Vector2(9, -22), Vector2(12, -23),
		Vector2(12, -23), Vector2(7, -22), Vector2(5, -22), Vector2(10, -22),
	]
	var mano := Vector2(6, -22)
	if en_marcha:
		var fotograma := int(fposmod(portador.x / 60.0, 1.0) * 8)
		mano = MANO_TEO[fotograma]
	if direccion_izquierda:
		mano.x = -mano.x
	var ancho := 15.0
	var alto := ancho * CAJA_CERRADA.get_height() / CAJA_CERRADA.get_width()
	var agarre := portador + mano
	draw_texture_rect(CAJA_CERRADA, Rect2(agarre - Vector2(ancho * 0.5, 1), Vector2(ancho, alto)), false)
	draw_circle(agarre, 1.6, Color("#53657c"), true, -1.0, true)


func _dibujar_objeto(textura: Texture2D, apoyo: Vector2, ancho: float) -> void:
	var alto := ancho * textura.get_height() / textura.get_width()
	draw_texture_rect(textura, Rect2(apoyo - Vector2(ancho * 0.5, alto), Vector2(ancho, alto)), false)


func _dibujar_extraccion() -> void:
	var sitio := MUESTRA + Vector2(5, -2)
	var caja := CAJA_HIELO - Vector2(0, 1)
	_dibujar_objeto(CAJA_ABIERTA, caja, 25)
	var profundidad := 19 * smoothstep(0.0, 0.44, avance_muestra)
	draw_line(sitio + Vector2(-11, 0), sitio + Vector2(0, -27), OSCURO, 3.0, true)
	draw_line(sitio + Vector2(11, 0), sitio + Vector2(0, -27), OSCURO, 3.0, true)
	draw_line(sitio + Vector2(0, -24), sitio + Vector2(0, -18 + profundidad), OCRE, 4.0, true)
	if avance_muestra >= 0.43:
		var salida := smoothstep(0.43, 0.72, avance_muestra)
		var depositado := smoothstep(0.72, 1.0, avance_muestra)
		_dibujar_objeto(NUCLEO_HIELO, sitio + Vector2(0, 13 - 27 * salida + 14 * depositado), 15)


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
	var sin_sol := smoothstep(0.45, 1.5, tiempo_averia)
	draw_rect(Rect2(372, 310, 133, 25), Color(0.26, 0.16, 0.17, sin_sol * 0.58))
	var baliza := Vector2(608, 308)
	draw_circle(baliza, 2.5, LUZ.lerp(OCRE, sin_sol), true, -1.0, true)
	_baliza(Vector2(531, 215), "FUNCIONANDO CON BATERÍA" if sin_sol > 0.9 else "PANELES SOLARES", OCRE if sin_sol > 0.9 else LUZ)


func _dibujar_desvio() -> void:
	var tramos := PASO_DORMITORIO + PASO_PLANTAS
	# En las entradas se conserva el umbral de la ilustración.
	tramos[2] = Rect2(668, 116, 27, 30)
	tramos[3] = Rect2(390, 108, 25, 31)
	tramos.append(Rect2(237, 235, 31, 20))
	tramos.append(Rect2(538, 235, 35, 20))
	tramos.append_array(PASO_AGUA)
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


func _dibujar_superficie_base() -> void:
	var escala_mapa := MAPA.get_size() / TAMANO_MAPA
	var superficie := Rect2(Vector2(566, 2) * escala_mapa, Vector2(234, 123) * escala_mapa)
	draw_texture_rect_region(MAPA, Rect2(-160, -85, 1048, 620), superficie)
	var patio := Rect2(146, 361, 489, 145)
	draw_texture_rect_region(MAPA, patio, Rect2(patio.position * escala_mapa, patio.size * escala_mapa))


func _dibujar_piso_esclusa() -> void:
	var sala: Rect2 = ENCUADRES.radio
	var factor := CONTROL.get_size() / sala.size
	var piso := Rect2((Vector2(322, 255) - sala.position) * factor, Vector2(160, 33) * factor)
	for columna in range(7):
		for fila in range(20):
			draw_texture_rect_region(CONTROL, Rect2(-160 + columna * 160, -85 + fila * 33, 160, 33), piso, Color("#747e85"))


func _dibujar_esclusa() -> void:
	var casco: Rect2 = ENCUADRES.cierre
	var silueta := PackedVector2Array([
		Vector2(383, 323), Vector2(390, 325), Vector2(414, 325), Vector2(422, 323),
		Vector2(425, 327), Vector2(449, 327), Vector2(465, 344),
		Vector2(468, 361), Vector2(469, 395), Vector2(465, 412),
		Vector2(452, 429), Vector2(429, 440), Vector2(425, 457),
		Vector2(380, 457), Vector2(376, 441), Vector2(351, 430),
		Vector2(337, 411), Vector2(335, 395), Vector2(336, 363),
		Vector2(339, 345), Vector2(355, 327), Vector2(380, 327),
	])
	var uv := PackedVector2Array()
	for vertice in silueta:
		uv.append((vertice - casco.position) / casco.size)
	draw_polygon(silueta, PackedColorArray([Color.WHITE]), uv, REFUGIO)
	_dibujar_puertas()


func _dibujar_puertas() -> void:
	var exterior := smoothstep(0.05, 0.68, avance_esclusa) * (1.0 - smoothstep(1.22, 1.62, avance_esclusa)) if esclusa_activa else 0.0
	var interior_abierta := smoothstep(2.22, 2.90, avance_esclusa) if esclusa_activa else 1.0
	_hojas_esclusa(Rect2(385, 412, 34, 22), exterior, true)
	_hojas_esclusa(Rect2(394, 338, 16, 15), interior_abierta)


func _hojas_esclusa(umbral: Rect2, abierta: float, exterior := false) -> void:
	draw_rect(umbral, OSCURO)
	var escala := REFUGIO.get_size() / ENCUADRES.cierre.size
	draw_texture_rect_region(REFUGIO, umbral.grow(-1),
		Rect2((Vector2(388, 391) - ENCUADRES.cierre.position) * escala, Vector2(21, 14) * escala))
	var ancho := umbral.size.x * 0.5
	for lado in range(2):
		var visible := ancho * (1.0 - abierta)
		if visible < 0.1:
			continue
		var x := umbral.position.x if lado == 0 else umbral.end.x - visible
		var hoja := Rect2(x, umbral.position.y, visible, umbral.size.y)
		if exterior:
			var corte := hoja.position - ENCUADRES.cierre.position
			corte.x += ancho * abierta * (1.0 if lado == 0 else -1.0)
			draw_texture_rect_region(REFUGIO, hoja, Rect2(corte * escala, hoja.size * escala))
		else:
			var corte := Vector2(384.0 + lado * 18.0, 411.0) - ENCUADRES.cierre.position
			if lado == 0:
				corte.x += 18.0 * abierta
			draw_texture_rect_region(REFUGIO, hoja, Rect2(corte * escala, Vector2(18.0 * (1.0 - abierta), 23) * escala))


func _dibujar_equipo_agua() -> void:
	var sitio: Vector2 = EQUIPO_AGUA[mini(etapa_agua, EQUIPO_AGUA.size() - 1)]
	if objetivo_mision == "agua" or agua_en_curso or punto.distance_to(sitio) <= 34.0:
		var color := LUZ if objetivo_mision == "agua" or agua_en_curso else OCRE
		draw_arc(sitio + Vector2(0, 3), 4.0, 0.0, TAU, 20, color, 1.1, true)
	if not agua_en_curso:
		return
	var modulo_agua := sitio - Vector2(0, 25)
	var medidor := Rect2(modulo_agua - Vector2(4, 2), Vector2(8, 4))
	draw_rect(medidor.grow(1), OSCURO)
	draw_rect(medidor, Color("#214750"))
	draw_rect(Rect2(medidor.position, Vector2(medidor.size.x * avance_agua, medidor.size.y)),
		OCRE if etapa_agua == 0 else LUZ)
	if etapa_agua == 0 and avance_agua > 0.0:
		_dibujar_objeto(NUCLEO_HIELO, modulo_agua - Vector2(0, 5), lerpf(11.0, 3.0, avance_agua))
	if etapa_agua == 2:
		draw_circle(modulo_agua + Vector2(8, -1), 1.7, LUZ)


func _dibujar_interior() -> void:
	draw_rect(Rect2(0, 0, ancho_visible, 527), Color("#21272c"))
	draw_set_transform(_origen_mundo(), 0, Vector2.ONE * escala_camara)
	_dibujar_superficie_base()
	var vista_esclusa := not plano and (esclusa_activa or punto.y >= LIMITE_CONTROL - 28.0 or centro_camara.y > 306.0)
	if vista_esclusa:
		_dibujar_piso_esclusa()
	var fondos := {
		"energia": ENERGIA, "cultivos": PLANTAS, "agua": CENTRO_AGUA, "radio": CONTROL,
		"dormitorio": DORMITORIO, "taller": TALLER,
	}
	for id: String in fondos:
		draw_texture_rect(fondos[id], ENCUADRES[id], false)
	_dibujar_esclusa()
	if esclusa_activa:
		_sprite(NORA_PASOS if caminando else NORA, punto, ALTURA_INTERIOR, 0.0, false,
			int(paso * 8) if caminando else -1)
		draw_set_transform(Vector2.ZERO)
		return
	_dibujar_desvio()
	_dibujar_equipo_agua()
	if reserva_en_prueba:
		var color := LUZ if desvio_energia else OCRE
		draw_polyline(PackedVector2Array([Vector2(129, 273), Vector2(164, 266),
			Vector2(164, 226), Vector2(177, 205)]), color, 2.0, true)
		draw_circle(Vector2(177, 205), 3.5 + sin(tiempo * 7), color, true, -1.0, true)
	if not cultivo_activo:
		draw_rect(Rect2(259, 33, 282, 88), Color(0.14, 0.19, 0.26, 0.52))
	if radio_enviada:
		draw_circle(Vector2(402, 181), 4.0, Color(0.34, 1.0, 0.84, 0.55))
	_sprite(TEO_NORMAL, Vector2(635, 89), ALTURA_INTERIOR)
	var patrulla := fposmod(tiempo - 17.0, 8.0)
	var iris_x := 457.0 + 21.0 * (smoothstep(0.5, 2.7, patrulla) - smoothstep(4.1, 6.3, patrulla))
	var iris_camina := (patrulla > 0.5 and patrulla < 2.7) or (patrulla > 4.1 and patrulla < 6.3)
	_sprite(IRIS_PASOS if iris_camina else IRIS, Vector2(iris_x, 218), ALTURA_INTERIOR, 0.0,
		patrulla >= 4.1, int(fposmod(iris_x / 20.0, 1.0) * 8) if iris_camina else -1)
	_sprite(DRON, Vector2(340, 260), 17, sin(tiempo * 4.5))
	var terminal := terminal_cercana()
	var radio_marca := 3.2 * minf(1.0, 2.4 / escala_camara)
	for id: String in TERMINALES:
		var color := LUZ if id == objetivo_mision or terminal == id else OCRE
		draw_circle(TERMINALES[id] + Vector2(0, 8), radio_marca, color, false, 1.0, true)
	for id: String in INSPECCIONES:
		var sitio: Vector2 = INSPECCIONES[id]
		if plano or punto.distance_to(sitio) < 108:
			draw_circle(sitio, radio_marca, LUZ if pruebas_anexos.has(id) else Color("#ebc8ff"), false, 1.0, true)
	_sprite(NORA_PASOS if caminando else NORA, punto, ALTURA_INTERIOR, 0.0,
		direccion_izquierda, int(paso * 8) if caminando else -1)
	draw_set_transform(Vector2.ZERO)
	var carteles := {
		Vector2(302, 227): "← ENERGÍA",
		Vector2(187, 155): "↑ CENTRO DE AGUA",
		Vector2(188, 29): "← CENTRO DE AGUA",
		Vector2(529, 211): "↑ PLANTAS Y DORMITORIO",
		Vector2(549, 255): "TALLER →",
		Vector2(538, 110): "← PLANTAS   ·   DORMITORIO →",
	}
	for sitio: Vector2 in carteles:
		if not plano and not vista_esclusa and punto.distance_to(sitio) < 72:
			_baliza(_origen_mundo() + sitio * escala_camara, carteles[sitio], LUZ)
	if plano:
		var nombres_plano := {
			"taller": "TALLER",
			"energia": "ENERGÍA", "radio": "CONTROL", "dormitorio": "DORMITORIO",
			"cultivos": "PLANTAS", "agua": "CENTRO DE AGUA", "cierre": "PUERTA",
		}
		for id: String in nombres_plano:
			var encuadre: Rect2 = ENCUADRES[id]
			var marca := _origen_mundo() + (encuadre.get_center() - Vector2(0, 44)) * escala_camara
			var activa := id == objetivo_mision
			_baliza(marca, nombres_plano[id], LUZ if activa else Color("#f3e3cc"))
	if en_esclusa() and not plano:
		var entrada_control := _origen_mundo() + Vector2(CENTRO_ESCLUSA_X, 338) * escala_camara
		entrada_control.y = maxf(entrada_control.y, 70.0)
		_baliza(entrada_control, "↑ CONTROL", LUZ)
	elif not plano and not agua_en_curso and terminal != objetivo_mision and (TERMINALES.has(objetivo_mision) or objetivo_mision == "agua"):
		var destino: Vector2 = EQUIPO_AGUA[0] if objetivo_mision == "agua" else TERMINALES[objetivo_mision]
		if objetivo_mision == "agua" and punto.x > 222.0:
			destino = Vector2(202, 245)
		elif objetivo_mision == "agua" and punto.x > 172.0:
			destino = ENTRADA_AGUA
		elif objetivo_mision in ["cultivos", "dormitorio"] and punto.y >= 149.0 and punto.x < 528.0:
			destino = Vector2(528, 245)
		elif objetivo_mision in ["cultivos", "dormitorio"] and punto.y >= 149.0:
			destino = Vector2(538, 142)
		var marca := _origen_mundo() + destino * escala_camara
		var etiqueta := marca - Vector2(0, 44.0)
		var visible := Vector2(clampf(etiqueta.x, 82, ancho_visible - 82), clampf(etiqueta.y, 58, 410))
		if etiqueta.distance_to(visible) > 15.0:
			var hacia := (marca - visible).normalized()
			draw_line(visible - hacia * 18, visible, LUZ, 2.2, true)
			draw_circle(visible, 3, LUZ, true, -1, true)
		_baliza(visible, NOMBRES[objetivo_mision], LUZ)


func _sprite(textura: Texture2D, ancla: Vector2, alto: float, balanceo := 0.0,
		invertido := false, fotograma := -1, columnas := 4, giro := 0.0) -> void:
	if not recortes.has(textura):
		recortes[textura] = textura.get_image().get_used_rect()
	var region: Rect2 = recortes[textura]
	if fotograma >= 0:
		if not secuencias.has(textura):
			var imagen := textura.get_image()
			var filas := 2
			var ancho_celda := imagen.get_width() / columnas
			var alto_celda := imagen.get_height() / filas
			var poses: Array[Rect2] = []
			for i in range(columnas * filas):
				var celda := Rect2i(i % columnas * ancho_celda, i / columnas * alto_celda, ancho_celda, alto_celda)
				var limites := imagen.get_region(celda).get_used_rect()
				poses.append(Rect2(celda.position + limites.position, limites.size))
			secuencias[textura] = poses
		region = secuencias[textura][fotograma]
	var ancho := alto * region.size.x / region.size.y
	var tam := Vector2(ancho, alto)
	var origen := ancla - Vector2(ancho * 0.5, alto + absf(balanceo))
	if textura != NAVE:
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
	elif not is_zero_approx(giro):
		var zoom := _zoom_mundo()
		var desplazamiento := _origen_mundo()
		draw_set_transform(desplazamiento + ancla * zoom, giro, Vector2.ONE * zoom)
		draw_texture_rect_region(textura, Rect2(origen - ancla, tam), region)
		draw_set_transform(desplazamiento, 0, Vector2.ONE * zoom)
	else:
		draw_texture_rect_region(textura, Rect2(origen, tam), region)


func _baliza(centro: Vector2, texto: String, color: Color) -> void:
	var fuente := ThemeDB.fallback_font
	var ancho := fuente.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
	draw_rect(Rect2(centro - Vector2(ancho * 0.5 + 7, 1), Vector2(ancho + 14, 23)), OSCURO)
	draw_string(fuente, centro + Vector2(-ancho * 0.5, 15), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, color)
