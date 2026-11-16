extends Node2D
## Dibuja el cultivo anclado al suelo y anima sus cambios de etapa.

const ATLAS := preload("res://assets/huerto_cultivos.png")
const REGIONES := {
	"lechuga": [Rect2(109, 163, 180, 104), Rect2(466, 67, 267, 199), Rect2(853, 35, 315, 241)],
	"rabano": [Rect2(114, 445, 160, 102), Rect2(466, 347, 263, 210), Rect2(864, 311, 313, 276)],
	"tomate": [Rect2(101, 745, 194, 118), Rect2(456, 637, 275, 228), Rect2(852, 605, 340, 260)],
	"papa": [Rect2(108, 1057, 184, 110), Rect2(456, 945, 270, 222), Rect2(832, 903, 370, 307)],
}
const ALTURAS := [0.34, 0.70, 1.0]

var altura_madura := 122.0
var cultivo := ""
var etapa := -1
var animacion: Tween
var offset_y := 0.0:
	set(valor):
		offset_y = valor
		queue_redraw()


static func etapa_del_cultivo(restante: float, total: float) -> int:
	if restante <= 0.0:
		return 2
	return 1 if restante <= total * 0.55 else 0


func mostrar(id: String, fase: int, animar := true) -> void:
	if cultivo == id and etapa == fase:
		return
	_detener_animacion()
	cultivo = id
	etapa = fase
	queue_redraw()
	if animar and etapa >= 0:
		scale = Vector2(0.82, 0.58)
		animacion = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		animacion.tween_property(self, "scale", Vector2.ONE, 0.36)


func levantar() -> Signal:
	_detener_animacion()
	animacion = create_tween().set_parallel()
	animacion.tween_property(self, "offset_y", -altura_madura * 0.53, 0.48).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	animacion.tween_property(self, "modulate:a", 0.0, 0.27).set_delay(0.23)
	return animacion.finished


func _detener_animacion() -> void:
	if is_instance_valid(animacion):
		animacion.kill()
	scale = Vector2.ONE
	offset_y = 0.0
	modulate = Color.WHITE


func _draw() -> void:
	if etapa < 0:
		return
	var region: Rect2 = REGIONES[cultivo][etapa]
	var proporcion: float = altura_madura * ALTURAS[etapa] / region.size.y
	var medida := region.size * proporcion
	draw_texture_rect_region(ATLAS, Rect2(Vector2(-medida.x / 2, offset_y - medida.y), medida), region)
