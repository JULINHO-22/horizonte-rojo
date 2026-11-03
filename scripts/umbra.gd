extends Control

const EXTERIOR := preload("res://assets/exterior.jpg")
const BASE := preload("res://assets/base.jpg")
const ROBOT := preload("res://assets/robot.jpg")
const ASTRONAUTA := preload("res://assets/astronauta.jpg")
const FONDO := Color("#101318")
const PANEL := Color("#1a2129")
const LINEA := Color("#394652")
const MARFIL := Color("#fff1db")
const MUTED := Color("#b3bfc8")
const CIAN := Color("#7df0e0")
const AMBAR := Color("#ffb46f")
const MODULOS := {
	"energia": ["01  /  ENERGÍA", "Consume 3 UE. Recupera 5 UE del banco auxiliar.", Vector2(205, 412)],
	"cultivos": ["02  /  INVERNADERO", "Consume 4 UE. Protege las bandejas durante la noche.", Vector2(418, 124)],
	"medicina": ["03  /  ENFERMERÍA", "Consume 3 UE. Estabiliza al compañero, que sigue en reposo.", Vector2(640, 255)],
	"radio": ["04  /  COMUNICACIONES", "Consume 2 UE. Envía la lectura del polvo y el informe. Respuesta pendiente.", Vector2(578, 405)],
}

var estado := SolUno.new()
var fase := "apertura"
var modulo := "energia"
var pantalla: Control
var polvo: Control
var reloj := 0.0


func _ready() -> void:
	get_window().min_size = Vector2i(800, 450)
	_render()


func _process(delta: float) -> void:
	reloj += delta
	if is_instance_valid(polvo):
		polvo.queue_redraw()


func _render() -> void:
	if is_instance_valid(pantalla):
		remove_child(pantalla)
		pantalla.queue_free()
	pantalla = Control.new()
	add_child(pantalla)
	_panel(Rect2(0, 0, 1280, 720), FONDO, FONDO)
	_texto("UMBRA", Rect2(32, 17, 230, 46), 36)
	_texto("CINCO SOLES PARA SOBREVIVIR", Rect2(184, 33, 390, 24), 15, MUTED)
	_texto("MARTE   /   PUESTO UMBRA", Rect2(988, 32, 266, 26), 16, CIAN)
	_panel(Rect2(32, 74, 1216, 1), LINEA, LINEA)
	match fase:
		"apertura":
			_apertura()
		"base":
			_base()
		"relevo":
			_relevo()
	_texto("UMBRA  /  PROTOTIPO 01", Rect2(32, 682, 440, 22), 14, MUTED)
	_texto("SOL 01 DE 05   •   TORMENTA DE POLVO", Rect2(914, 682, 334, 22), 14, MUTED)


func _apertura() -> void:
	_imagen(EXTERIOR, Rect2(32, 92, 804, 468))
	polvo = Control.new()
	polvo.position = Vector2(32, 92)
	polvo.size = Vector2(804, 468)
	polvo.clip_contents = true
	polvo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pantalla.add_child(polvo)
	polvo.draw.connect(_dibujar_polvo)
	_panel(Rect2(47, 109, 233, 34), FONDO)
	_texto("EXTERIOR   /   ESCLUSA 01", Rect2(60, 116, 205, 20), 14, AMBAR)
	_panel(Rect2(32, 511, 804, 49), Color("#15191f"))
	_texto("«¡CIERREN LAS COMPUERTAS! ¡LA TORMENTA ESTÁ ENCIMA!»",
		Rect2(48, 524, 780, 25), 20)
	_panel(Rect2(32, 578, 804, 84), PANEL)
	_imagen(_recorte(ASTRONAUTA, Rect2(178, 10, 255, 240)), Rect2(45, 587, 66, 66))
	_texto("CANAL DE TRIPULACIÓN", Rect2(124, 592, 300, 20), 14, CIAN)
	_texto("«Me caí junto al rover. No puedo sacar la pierna.»",
		Rect2(124, 617, 690, 32), 20)
	_panel(Rect2(856, 92, 392, 570), PANEL)
	_texto("01   /   ALERTA DE ESCLUSA", Rect2(876, 111, 351, 24), 16, AMBAR)
	_texto("Alguien sigue afuera", Rect2(876, 146, 351, 50), 30)
	_texto("Tres astronautas corren al refugio. Uno tropieza y queda atrapado junto al rover averiado.",
		Rect2(876, 198, 351, 94), 20)
	_imagen(_recorte(ROBOT, Rect2(65, 70, 565, 523)), Rect2(875, 296, 66, 66))
	_texto("ROBOT DE A BORDO", Rect2(954, 294, 270, 20), 13, CIAN)
	_texto("El cabrestante usa el circuito del invernadero.", Rect2(954, 317, 272, 58), 18)
	_boton("Rescatar ahora", Rect2(876, 391, 351, 43), _elegir.bind(SolUno.RESCATE), CIAN)
	_texto("6 UE · Invernadero en pausa. Atención temprana.", Rect2(877, 442, 350, 52), 16, MUTED)
	_boton("Cerrar y esperar una tregua", Rect2(876, 506, 351, 43), _elegir.bind(SolUno.ESPERA), AMBAR)
	_texto("4 UE para la extracción posterior. Cultivos activos. La lesión puede agravarse.",
		Rect2(877, 556, 350, 75), 16, MUTED)


func _dibujar_polvo() -> void:
	for indice in range(46):
		var x := fposmod(indice * 109.7 + reloj * (55.0 + (indice % 4) * 27.0), 820.0)
		var y := fposmod(indice * 73.1 + reloj * 9.0, 425.0)
		polvo.draw_line(Vector2(x, y), Vector2(x + 14 + (indice % 5) * 5, y + 4),
			Color(1.0, 0.65, 0.4, 0.27), 2.0)


func _elegir(ruta: String) -> void:
	estado.abrir(ruta)
	fase = "base"
	_render()


func _base() -> void:
	_imagen(BASE, Rect2(32, 92, 804, 527), TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	for id: String in MODULOS:
		var posicion: Vector2 = MODULOS[id][2] + Vector2(32, 92)
		_boton(MODULOS[id][0].left(2), Rect2(posicion, Vector2(42, 36)),
			_seleccionar.bind(id), CIAN if modulo == id else MARFIL)
	_panel(Rect2(32, 625, 804, 37), PANEL)
	_texto("BASE   /   Selecciona un módulo en el plano", Rect2(47, 633, 770, 24), 16, CIAN)
	_panel(Rect2(856, 92, 392, 570), PANEL)
	_texto("SOL 01   /   ESTABILIZAR LA BASE", Rect2(875, 108, 351, 24), 16, AMBAR)
	_texto("Reserva de batería", Rect2(875, 143, 285, 28), 22)
	_texto("%02d UE" % estado.energia, Rect2(1145, 143, 85, 28), 22, CIAN)
	_panel(Rect2(876, 180, 350, 8), LINEA, LINEA)
	_panel(Rect2(876, 180, 350 * estado.energia / 16.0, 8), CIAN, CIAN)
	_texto("%d raciones    •    %d / %d tareas disponibles" % [
		estado.raciones, estado.operativos - estado.acciones.size(), estado.operativos],
		Rect2(875, 199, 352, 42), 17, MARFIL)
	_texto("Cultivos · %s\nTripulante · %s" % [estado.cultivo, estado.paciente],
		Rect2(875, 243, 352, 74), 17, MUTED)
	_panel(Rect2(875, 322, 352, 195), FONDO)
	_texto(MODULOS[modulo][0], Rect2(888, 335, 327, 24), 14, CIAN)
	_texto(MODULOS[modulo][1], Rect2(888, 366, 327, 74), 17)
	var accion: String = SolUno.ACCIONES[modulo]["titulo"]
	if estado.acciones.has(modulo):
		accion = "Tarea completada"
	elif estado.acciones.size() == estado.operativos:
		accion = "Turnos agotados"
	elif not estado.disponible(modulo):
		accion = "Batería reservada para la noche"
	_boton(accion, Rect2(888, 451, 326, 48), _accion.bind(modulo), CIAN,
		not estado.disponible(modulo))
	_texto("Reserva nocturna · 4 UE y 3 raciones.\nCada persona operativa puede hacer una tarea.",
		Rect2(875, 527, 352, 63), 16, MUTED)
	_boton("Cerrar el sol", Rect2(875, 603, 352, 43), _cerrar, AMBAR)


func _seleccionar(id: String) -> void:
	modulo = id
	_render()


func _accion(id: String) -> void:
	estado.aplicar(id)
	_render()


func _cerrar() -> void:
	fase = "relevo"
	_render()


func _relevo() -> void:
	var informe := estado.relevo()
	_imagen(EXTERIOR, Rect2(32, 92, 728, 570))
	_panel(Rect2(32, 470, 728, 192), PANEL)
	_texto("BITÁCORA   /   FIN DEL SOL 01", Rect2(54, 491, 680, 25), 16, CIAN)
	_texto("La base aguanta", Rect2(54, 527, 680, 54), 43)
	_texto("El polvo redujo la luz de los paneles. La batería hizo posible el rescate y mantuvo el refugio durante la noche.",
		Rect2(54, 591, 680, 62), 19, MUTED)
	_panel(Rect2(780, 92, 468, 570), PANEL)
	_texto("RELEVO   /   AMANECER DEL SOL 02", Rect2(802, 112, 423, 30), 17, AMBAR)
	var ruta := "Rescate inmediato" if estado.ruta == SolUno.RESCATE else "Extracción tras la tregua"
	_texto(ruta, Rect2(802, 155, 424, 43), 27)
	var datos := "%d UE en batería  ·  %d raciones\n%d de 3 tripulantes operativos\n\nCultivos · %s\nTripulante · %s\nCuidados previstos · %d UE al próximo sol" % [
		informe.energia, informe.raciones, informe.operativos, informe.cultivo,
		informe.paciente, informe.energia_comprometida]
	_texto(datos, Rect2(802, 212, 424, 190), 20)
	var radio := "Informe en tránsito. Respuesta de Tierra pendiente." if informe.ciencia_enviada else "Lectura del polvo sin enviar."
	_texto(radio, Rect2(802, 422, 424, 58), 19, CIAN)
	var leccion := "El rescate temprano reduce los cuidados. Si los cultivos quedan en pausa, mañana dependes de las raciones."
	if estado.ruta == SolUno.ESPERA:
		leccion = "La espera conservó los cultivos. Si la lesión sigue sin atenderse, mañana compromete más batería."
	_texto(leccion, Rect2(802, 490, 424, 94), 17, MUTED)
	_boton("Probar otra decisión", Rect2(802, 600, 424, 44), _reiniciar, CIAN)


func _reiniciar() -> void:
	estado = SolUno.new()
	modulo = "energia"
	fase = "apertura"
	_render()


func _estilo(color: Color, borde: Color) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = color
	estilo.border_color = borde
	estilo.set_border_width_all(1)
	return estilo


func _colocar(control: Control, area: Rect2) -> void:
	pantalla.add_child(control)
	control.position = area.position
	control.size = area.size


func _panel(area: Rect2, color: Color, borde := LINEA) -> void:
	var panel := Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _estilo(color, borde))
	_colocar(panel, area)


func _texto(contenido: String, area: Rect2, puntos: int, color := MARFIL) -> void:
	var etiqueta := Label.new()
	etiqueta.text = contenido
	etiqueta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	etiqueta.add_theme_font_size_override("font_size", puntos)
	etiqueta.add_theme_color_override("font_color", color)
	_colocar(etiqueta, area)


func _imagen(textura: Texture2D, area: Rect2, ajuste := TextureRect.STRETCH_KEEP_ASPECT_COVERED) -> void:
	var imagen := TextureRect.new()
	imagen.texture = textura
	imagen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagen.stretch_mode = ajuste
	imagen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_colocar(imagen, area)


func _recorte(textura: Texture2D, region: Rect2) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = textura
	atlas.region = region
	return atlas


func _boton(titulo: String, area: Rect2, evento: Callable, acento: Color,
		desactivado := false) -> void:
	var boton := Button.new()
	boton.text = titulo
	boton.disabled = desactivado
	boton.add_theme_font_size_override("font_size", 17)
	boton.add_theme_color_override("font_color", acento)
	boton.add_theme_color_override("font_hover_color", FONDO)
	boton.add_theme_color_override("font_pressed_color", FONDO)
	boton.add_theme_color_override("font_disabled_color", MUTED)
	boton.add_theme_stylebox_override("normal", _estilo(FONDO, acento))
	boton.add_theme_stylebox_override("hover", _estilo(acento, acento))
	boton.add_theme_stylebox_override("pressed", _estilo(acento.darkened(0.2), acento))
	boton.add_theme_stylebox_override("disabled", _estilo(PANEL, LINEA))
	boton.add_theme_stylebox_override("focus", _estilo(Color.TRANSPARENT, MARFIL))
	_colocar(boton, area)
	boton.pressed.connect(evento)
