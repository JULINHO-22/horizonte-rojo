extends Control
## Banco interno de pruebas. Abrir esta escena con F6.
const Recursos := preload("res://scripts/mecanicas/recursos_mision.gd")
const NOMBRES := {
	"energia": "Energía", "agua": "Agua", "oxigeno": "Oxígeno", "alimento": "Alimento",
	"lechuga": "Lechuga", "rabano": "Rábano", "tomate": "Tomate", "papa": "Papa",
}
const CLIMAS := ["bajo", "medio", "alto", "tormenta"]
const AVISOS := {
	"oxigeno_agotado": "El oxígeno llegó a cero.",
	"aire_sin_activar": "Se cerró el día sin asegurar el aire.",
	"hambre_al_dormir": "Se cerró el día sin alimento.",
}
var mision := Recursos.new()
var estado: Label
var aviso: Label
var clima: OptionButton
var contadores := {}
var botones_cultivo := {}

func _ready() -> void:
	var fondo := ColorRect.new()
	fondo.color = Color("#101c28")
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	var columna := VBoxContainer.new()
	columna.position = Vector2(54, 44)
	columna.custom_minimum_size.x = 760
	columna.add_theme_constant_override("separation", 10)
	add_child(columna)
	_texto(columna, "Banco de pruebas del refugio", 39)
	_texto(columna, "Los relojes avanzan al pulsar los botones de tiempo.", 19)
	estado = _texto(columna, "", 24)
	for recurso: String in Recursos.LIMITES:
		var fila := _fila(columna)
		_texto(fila, NOMBRES[recurso], 18).custom_minimum_size.x = 100
		var barra := ProgressBar.new()
		barra.max_value = Recursos.LIMITES[recurso]
		barra.custom_minimum_size = Vector2(220, 20)
		barra.show_percentage = false
		fila.add_child(barra)
		var valor := _texto(fila, "", 18)
		contadores[recurso] = [barra, valor]
	var acciones := _fila(columna)
	clima = OptionButton.new()
	for nombre_clima: String in CLIMAS:
		clima.add_item(nombre_clima.capitalize())
	clima.select(1)
	acciones.add_child(clima)
	_boton(acciones, "Iniciar día", _iniciar)
	_boton(acciones, "+8 s", _avanzar.bind(8.0))
	_boton(acciones, "+20 s", _avanzar.bind(20.0))
	_boton(acciones, "Dormir", _hacer.bind(mision.dormir, "Noche terminada."))
	_boton(acciones, "Restablecer prueba", get_tree().reload_current_scene)
	var laboratorio := _fila(columna)
	_boton(laboratorio, "Recoger hielo", _hacer.bind(mision.recoger_hielo, "Hielo recogido."))
	_boton(laboratorio, "Purificar · 2 rayos", _hacer.bind(mision.purificar_hielo, "Hielo convertido en agua."))
	_boton(laboratorio, "Asegurar aire · 6 rayos y 1 agua", _hacer.bind(mision.activar_oxigeno, "Aire asegurado por hoy."))
	_boton(laboratorio, "Tanques · Sol 3", _hacer.bind(mision.usar_tanques_emergencia, "Tanques abiertos para pasar la noche."))
	for cultivo: String in Recursos.CULTIVOS:
		var fila := _fila(columna)
		var ficha: Dictionary = Recursos.CULTIVOS[cultivo]
		_texto(fila, "%s · %d rayos + 1 agua · +%d alimento · %d s" % [
			NOMBRES[cultivo], ficha.energia, ficha.alimento, int(ficha.segundos)], 17).custom_minimum_size.x = 395
		_boton(fila, "Sembrar", _hacer.bind(mision.sembrar.bind(cultivo), "Siembra iniciada."))
		_boton(fila, "Comer", _hacer.bind(mision.comer.bind(cultivo), "Alimento recuperado."))
		botones_cultivo[cultivo] = _texto(fila, "", 17)
	aviso = _texto(columna, "", 18)
	mision.cambiado.connect(_actualizar)
	_actualizar()

func _actualizar() -> void:
	var datos := mision.estado()
	var etapa := "Elige el polvo e inicia el día"
	if datos.en_curso:
		etapa = "Aire asegurado" if datos.aire_asegurado else "Aire pendiente"
	elif datos.terminado:
		etapa = "Cinco noches completadas"
	elif not datos.derrota.is_empty():
		etapa = "Game Over"
	estado.text = "Día %d   |   %s   |   Hielo: %d" % [datos.sol, etapa, datos.hielo]
	for recurso: String in contadores:
		var total: int = datos.reservas[recurso]
		contadores[recurso][0].value = total
		contadores[recurso][1].text = "%d / %d" % [total, Recursos.LIMITES[recurso]]
	for cultivo: String in botones_cultivo:
		var espera: float = datos.bandejas.get(cultivo, -1.0)
		botones_cultivo[cultivo].text = "" if espera < 0 else ("Listo" if espera == 0 else "%d s" % ceili(espera))

func _iniciar() -> void:
	_hacer(mision.iniciar_sol.bind(CLIMAS[clima.selected]), "El día ya está en marcha.")

func _avanzar(segundos: float) -> void:
	mision.avanzar(segundos)
	var datos := mision.estado()
	aviso.text = AVISOS.get(datos.derrota, "No queda alimento. Come antes de dormir." if datos.reservas.alimento == 0 else "")

func _hacer(accion: Callable, mensaje: String) -> void:
	var resultado: bool = accion.call()
	aviso.text = AVISOS.get(mision.estado().derrota, mensaje if resultado else "Acción no disponible con el estado actual.")

func _fila(padre: Control) -> HBoxContainer:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	padre.add_child(fila)
	return fila

func _texto(padre: Control, texto: String, tamano: int) -> Label:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.add_theme_font_size_override("font_size", tamano)
	padre.add_child(etiqueta)
	return etiqueta

func _boton(padre: Control, texto: String, accion: Callable) -> void:
	var boton := Button.new()
	boton.text = texto
	boton.pressed.connect(accion)
	padre.add_child(boton)
