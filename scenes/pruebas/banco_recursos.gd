extends Control
## Banco interno de pruebas. Abrir esta escena con F6.
const Recursos := preload("res://scripts/mecanicas/recursos_mision.gd")
const CLIMAS := ["bajo", "medio", "alto", "tormenta"]
const AVISOS := {
	"oxigeno_agotado": "banco.aviso.ox0",
	"aire_sin_activar": "banco.aviso.sin_aire",
	"hambre_al_dormir": "banco.aviso.sin_comida",
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
	_texto(columna, I18n.t("banco.titulo"), 39)
	_texto(columna, I18n.t("banco.nota"), 19)
	estado = _texto(columna, "", 24)
	for recurso: String in Recursos.LIMITES:
		var fila := _fila(columna)
		var nombre_recurso := I18n.t("banco.nom.alimento") if recurso == "alimento" else I18n.t("tablet.ficha." + recurso)
		_texto(fila, nombre_recurso, 18).custom_minimum_size.x = 100
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
		clima.add_item(I18n.clima(nombre_clima, true))
	clima.select(1)
	acciones.add_child(clima)
	_boton(acciones, I18n.t("banco.btn.iniciar"), _iniciar)
	_boton(acciones, I18n.t("banco.btn.8s"), _avanzar.bind(8.0))
	_boton(acciones, I18n.t("banco.btn.20s"), _avanzar.bind(20.0))
	_boton(acciones, I18n.t("banco.btn.dormir"), _hacer.bind(mision.dormir, "banco.log.noche"))
	_boton(acciones, I18n.t("banco.btn.restablecer"), get_tree().reload_current_scene)
	var laboratorio := _fila(columna)
	_boton(laboratorio, I18n.t("banco.btn.hielo"), _hacer.bind(mision.recoger_hielo, "banco.log.hielo"))
	_boton(laboratorio, I18n.t("banco.btn.purificar"), _hacer.bind(mision.purificar_hielo, "banco.log.purificar"))
	_boton(laboratorio, I18n.t("banco.btn.ox"), _hacer.bind(mision.activar_oxigeno, "banco.log.ox"))
	_boton(laboratorio, I18n.t("banco.btn.tanques"), _hacer.bind(mision.usar_tanques_emergencia, "banco.log.tanques"))
	for cultivo: String in Recursos.CULTIVOS:
		var fila := _fila(columna)
		var ficha: Dictionary = Recursos.CULTIVOS[cultivo]
		_texto(fila, I18n.tf("banco.ficha_cultivo", [
			I18n.cultivo(cultivo), ficha.energia, ficha.alimento, int(ficha.segundos)]), 17).custom_minimum_size.x = 395
		_boton(fila, I18n.t("banco.btn.sembrar"), _hacer.bind(mision.sembrar.bind(cultivo), "banco.log.sembrar"))
		_boton(fila, I18n.t("banco.btn.comer"), _hacer.bind(mision.comer.bind(cultivo), "banco.log.comer"))
		botones_cultivo[cultivo] = _texto(fila, "", 17)
	aviso = _texto(columna, "", 18)
	mision.cambiado.connect(_actualizar)
	_actualizar()

func _actualizar() -> void:
	var datos := mision.estado()
	var etapa := I18n.t("banco.estado.inicio")
	if datos.en_curso:
		etapa = I18n.t("banco.estado.aire_ok") if datos.aire_asegurado else I18n.t("banco.estado.aire_pend")
	elif datos.terminado:
		etapa = I18n.t("banco.estado.noches")
	elif not datos.derrota.is_empty():
		etapa = I18n.t("ui.game_over")
	estado.text = I18n.tf("banco.estado.dia", [datos.sol, etapa, datos.hielo])
	for recurso: String in contadores:
		var total: int = datos.reservas[recurso]
		contadores[recurso][0].value = total
		contadores[recurso][1].text = "%d / %d" % [total, Recursos.LIMITES[recurso]]
	for cultivo: String in botones_cultivo:
		var espera: float = datos.bandejas.get(cultivo, -1.0)
		botones_cultivo[cultivo].text = "" if espera < 0 else (I18n.t("banco.listo") if espera == 0 else I18n.tf("banco.seg", [ceili(espera)]))

func _iniciar() -> void:
	_hacer(mision.iniciar_sol.bind(CLIMAS[clima.selected]), "banco.en_marcha")

func _avanzar(segundos: float) -> void:
	mision.avanzar(segundos)
	var datos := mision.estado()
	aviso.text = _texto_derrota(datos.derrota, I18n.t("banco.sin_comida_dormir") if datos.reservas.alimento == 0 else "")

func _hacer(accion: Callable, clave_mensaje: String) -> void:
	var resultado: bool = accion.call()
	aviso.text = _texto_derrota(mision.estado().derrota, I18n.t(clave_mensaje) if resultado else I18n.t("banco.no_disp"))

func _texto_derrota(motivo: String, respaldo: String) -> String:
	if AVISOS.has(motivo):
		return I18n.t(AVISOS[motivo])
	return respaldo

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
