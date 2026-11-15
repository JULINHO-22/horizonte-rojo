extends SceneTree

func _initialize() -> void:
	var textura := load("res://assets/refugio_horizonte.png") as Texture2D
	var portada := textura.get_image() if textura != null else null
	if portada == null:
		push_error("No se pudo abrir el arte de portada.")
		quit(1)
		return
	portada.resize(1440, roundi(portada.get_height() * 1440.0 / portada.get_width()), Image.INTERPOLATE_LANCZOS)
	var error := portada.save_jpg("res://build/web/portada.jpg", 0.87)
	if error != OK:
		push_error("No se pudo generar la portada web: " + error_string(error))
	quit(0 if error == OK else 1)
