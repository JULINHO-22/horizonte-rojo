extends Control
## Controles táctiles (joystick analógico izquierdo) activados automáticamente en pantallas táctiles.

const CENTRO := Vector2(108.0, 598.0)
const RADIO_BASE := 54.0
const RADIO_TOQUE := 84.0
const RADIO_POMO := 23.0
const ZONA_MUERTA := 0.10

static var _activo := false
static var _detectado := false
static var _vector := Vector2.ZERO
static var _visibles: Array[Control] = []

var _dedo := -1
var _raton := false
var _pomo := Vector2.ZERO
var _habilitado := true


static func _asegurar_deteccion() -> void:
	if _detectado:
		return
	_detectado = true
	if OS.has_feature("mobile") or "--touch" in OS.get_cmdline_user_args():
		_activo = true
		return
	if OS.has_feature("web") and Engine.has_singleton(&"JavaScriptBridge"):
		var js := Engine.get_singleton(&"JavaScriptBridge")
		var eval_res: Variant = js.call(&"eval", "navigator.maxTouchPoints > 0 || window.matchMedia('(pointer: coarse)').matches")
		if eval_res is bool and eval_res:
			_activo = true


static func activo() -> bool:
	_asegurar_deteccion()
	return _activo


static func activar(estado := true) -> void:
	_detectado = true
	if _activo == estado:
		return
	_activo = estado
	if not _activo:
		_vector = Vector2.ZERO
	for inst in _visibles:
		if is_instance_valid(inst):
			inst._refrescar_visibilidad()


static func reiniciar_vector() -> void:
	_vector = Vector2.ZERO


static func direccion() -> Vector2:
	return _vector if activo() else Vector2.ZERO


static func zona_stick() -> Rect2:
	if not activo():
		return Rect2()
	return Rect2(CENTRO - Vector2(74.0, 74.0), Vector2(148.0, 148.0))


func _ready() -> void:
	size = Vector2(1280.0, 720.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 8
	if self not in _visibles:
		_visibles.append(self)
	_refrescar_visibilidad()


func _exit_tree() -> void:
	_visibles.erase(self)
	if _dedo >= 0 or _raton:
		_soltar()


func establecer_habilitado(estado: bool) -> void:
	_habilitado = estado
	if not _habilitado:
		_soltar()
	_refrescar_visibilidad()


func _refrescar_visibilidad() -> void:
	visible = activo() and _habilitado
	queue_redraw()


func _input(evento: InputEvent) -> void:
	if not _habilitado:
		return
	if evento is InputEventScreenTouch:
		if not activo():
			activar(true)
		var toque := evento as InputEventScreenTouch
		var pos := _a_lienzo(toque.position)
		if toque.pressed:
			if _dedo == -1 and pos.distance_to(CENTRO) <= RADIO_TOQUE:
				_dedo = toque.index
				_raton = false
				_actualizar_pomo(pos)
				get_viewport().set_input_as_handled()
		elif toque.index == _dedo:
			_soltar()
			get_viewport().set_input_as_handled()
	elif evento is InputEventScreenDrag:
		var arrastre := evento as InputEventScreenDrag
		if arrastre.index == _dedo:
			_actualizar_pomo(_a_lienzo(arrastre.position))
			get_viewport().set_input_as_handled()
	elif evento is InputEventMouseButton and activo() and _dedo == -1:
		var mb := evento as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		var pos := _a_lienzo(mb.position)
		if mb.pressed:
			if pos.distance_to(CENTRO) <= RADIO_BASE + 8.0:
				_raton = true
				_actualizar_pomo(pos)
				get_viewport().set_input_as_handled()
		elif _raton:
			_soltar()
			get_viewport().set_input_as_handled()
	elif evento is InputEventMouseMotion and _raton and _dedo == -1:
		_actualizar_pomo(_a_lienzo((evento as InputEventMouseMotion).position))
		get_viewport().set_input_as_handled()


func _a_lienzo(pos_ventana: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * pos_ventana


func _actualizar_pomo(pos: Vector2) -> void:
	var delta := pos - CENTRO
	var largo := delta.length()
	if largo > RADIO_BASE:
		delta = delta / largo * RADIO_BASE
	_pomo = delta
	var mag := _pomo.length() / RADIO_BASE
	_vector = Vector2.ZERO if mag < ZONA_MUERTA else (_pomo / RADIO_BASE)
	queue_redraw()


func _soltar() -> void:
	_dedo = -1
	_raton = false
	_pomo = Vector2.ZERO
	_vector = Vector2.ZERO
	queue_redraw()


func _draw() -> void:
	if not visible:
		return
	var activo_drag := _dedo >= 0 or _raton
	draw_circle(CENTRO, RADIO_BASE, Color("#101b249e") if not activo_drag else Color("#152532bd"))
	draw_arc(CENTRO, RADIO_BASE, 0.0, TAU, 48, Color("#7bece070") if not activo_drag else Color("#7bece0cc"), 2.0, true)
	for dir: Vector2 in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		var marca: Vector2 = CENTRO + dir * (RADIO_BASE - 12.0)
		draw_circle(marca, 2.5, Color("#fff1db55"))
	var centro_pomo := CENTRO + _pomo
	draw_circle(centro_pomo, RADIO_POMO, Color("#fff1dba8") if not activo_drag else Color("#fff1dbdc"))
	draw_arc(centro_pomo, RADIO_POMO, 0.0, TAU, 32, Color("#7bece0cc"), 2.0, true)
