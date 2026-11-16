extends SceneTree

func _initialize() -> void:
	var portada := Image.load_from_file("res://web/estaticos/portada_umbra.png")
	if portada == null or portada.is_empty():
		push_error("No se pudo abrir el arte de portada.")
		quit(1)
		return
	portada.resize(1600, roundi(portada.get_height() * 1600.0 / portada.get_width()), Image.INTERPOLATE_LANCZOS)
	var error := portada.save_webp("res://build/web/portada-umbra.webp", true, 0.86)
	if error != OK:
		push_error("No se pudo generar la portada web: " + error_string(error))
	quit(0 if error == OK else 1)
