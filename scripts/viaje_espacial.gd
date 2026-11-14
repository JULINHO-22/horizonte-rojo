extends Node2D
## Trayectoria cinematográfica resumida; no es un cálculo orbital.
const NAVE := preload("res://assets/nave_llegada.png")
var progreso := 0.0
var regreso := false

func punto_ruta(t: float) -> Vector2:
	var origen := Vector2(265, 466) if not regreso else Vector2(1030, 290)
	var destino := Vector2(1030, 290) if not regreso else Vector2(265, 466)
	return origen.bezier_interpolate(Vector2(330, 110), Vector2(890, 100), destino, t)

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color("#080f20"))
	for i in range(170):
		var punto := Vector2(fposmod(i * 117.31, 1280), fposmod(i * 71.77, 720))
		draw_circle(punto, 0.6 + float(i % 3) * 0.35, Color(0.7, 0.84, 1.0, 0.25 + (i % 5) * 0.13))
	_planeta(Vector2(265, 466), 102, Color("#23678f"), true)
	_planeta(Vector2(1030, 290), 58, Color("#bd6048"), false)
	var ruta := PackedVector2Array()
	for i in range(101):
		ruta.append(punto_ruta(i / 100.0))
	draw_polyline(ruta, Color("#284357"), 2.0, true)
	var tramo := PackedVector2Array()
	for i in range(maxi(2, int(progreso * 100))):
		tramo.append(punto_ruta(i / 100.0))
	draw_polyline(tramo, Color("#83eadc"), 3.0, true)
	var lugar := punto_ruta(progreso)
	var rumbo := punto_ruta(minf(progreso + 0.01, 1.0)) - punto_ruta(maxf(progreso - 0.01, 0.0))
	draw_set_transform(lugar, rumbo.angle() + PI / 2)
	draw_colored_polygon(PackedVector2Array([Vector2(-7, 15), Vector2(0, 32 + sin(progreso * 240) * 5), Vector2(7, 15)]), Color("#f0af74"))
	var lado := Vector2(44, 64)
	draw_texture_rect(NAVE, Rect2(-lado * 0.5, lado), false)
	draw_set_transform(Vector2.ZERO)

func _planeta(centro: Vector2, radio: float, color: Color, tierra: bool) -> void:
	draw_circle(centro, radio + 7, Color(color, 0.14))
	draw_circle(centro, radio, color)
	for i in range(7):
		var x := -radio * 0.55 + i * radio * 0.16
		var y := sin(i * 2.1) * radio * 0.45
		draw_circle(centro + Vector2(x, y), radio * (0.13 + (i % 3) * 0.025), Color("#67a7a2") if tierra else Color("#9f4c3c"))
	draw_arc(centro, radio - 1, PI * 0.7, PI * 1.7, 60, color.lightened(0.32), 3, true)
