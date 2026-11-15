extends RefCounted
## Acciones legibles sobre un escenario. El tamaño y la posición pertenecen a cada vista.

static func aplicar(boton: Button) -> void:
	var sin_marco := StyleBoxEmpty.new()
	for estado in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		boton.add_theme_stylebox_override(estado, sin_marco)
	boton.add_theme_color_override("font_color", Color("#fff1db"))
	boton.add_theme_color_override("font_hover_color", Color("#ffc78b"))
	boton.add_theme_color_override("font_pressed_color", Color("#f1a76e"))
	boton.add_theme_color_override("font_focus_color", Color("#ffc78b"))
	boton.add_theme_color_override("font_disabled_color", Color("#bcb1aa"))
	boton.add_theme_color_override("font_outline_color", Color("#160e0b"))
	boton.add_theme_constant_override("outline_size", 7)
	boton.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
