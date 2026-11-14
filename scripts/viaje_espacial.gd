extends Node2D
## Montaje de viaje con arte generado. Meses de traslado, no una órbita simulada.
const TIERRA := preload("res://assets/viaje_tierra.png")
const MARTE := preload("res://assets/viaje_marte.png")
const NAVE := preload("res://assets/nave_transferencia.png")
const TAMANO := Vector2(1280, 720)
const CAMBIO_PLANO := 0.50
var progreso := 0.0
var regreso := false

func punto_ruta(t: float) -> Vector2:
	# Dos tomas con trayectoria suave y velocidades compatibles con el montaje.
	if t < CAMBIO_PLANO:
		return Vector2(440, 355).bezier_interpolate(Vector2(570, 320), Vector2(720, 250), Vector2(900, 210), smoothstep(0, CAMBIO_PLANO, t))
	return Vector2(330, 280).bezier_interpolate(Vector2(480, 250), Vector2(650, 260), Vector2(815, 290), smoothstep(CAMBIO_PLANO, 1, t))

func etapa() -> String:
	if progreso < 0.35:
		return "Dejamos Marte atrás" if regreso else "Dejamos la Tierra atrás"
	if progreso < 0.65:
		return "Meses de viaje después…"
	return "Nos acercamos a la Tierra" if regreso else "Nos acercamos a Marte"

func _draw() -> void:
	var llegada := progreso >= CAMBIO_PLANO
	var planeta: Texture2D = (TIERRA if regreso else MARTE) if llegada else (MARTE if regreso else TIERRA)
	var tramo := clampf((progreso - CAMBIO_PLANO) * 2 if llegada else progreso * 2, 0, 1)
	var escala := lerpf(1.0, 1.10, tramo) if llegada else lerpf(1.10, 1.0, tramo)
	# Cubrir el visor sin deformar el arte ni exponer bordes durante el paneo.
	var ajuste := maxf(TAMANO.x / planeta.get_width(), TAMANO.y / planeta.get_height())
	var dimensiones := planeta.get_size() * ajuste * escala
	var origen := (TAMANO - dimensiones) * 0.5
	draw_texture_rect(planeta, Rect2(origen, dimensiones), false)
	var lugar := punto_ruta(progreso)
	var ancho := lerpf(345, 215, tramo) if not llegada else lerpf(340, 230, tramo)
	var tamano := Vector2(ancho, ancho * NAVE.get_height() / float(NAVE.get_width()))
	# El módulo de descenso conserva su diseño y viaja acoplado al módulo de servicio.
	draw_set_transform(lugar, lerpf(-0.10, 0.02, tramo))
	draw_texture_rect(NAVE, Rect2(-tamano * 0.5, tamano), false)
	draw_set_transform(Vector2.ZERO)
	# Corte a negro: separa las localizaciones y representa el tiempo transcurrido.
	var fundido := smoothstep(0.41, 0.50, progreso) * (1.0 - smoothstep(0.50, 0.59, progreso))
	if fundido > 0:
		draw_rect(Rect2(Vector2.ZERO, TAMANO), Color(0.015, 0.025, 0.045, fundido))
