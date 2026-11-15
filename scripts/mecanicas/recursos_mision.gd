extends RefCounted
## Reglas de los cinco soles. La escena decide cuándo el tiempo está corriendo.
signal cambiado

const LIMITES := {"energia": 12, "agua": 6, "oxigeno": 8, "alimento": 10}
const RESERVAS_INICIALES := {"energia": 9, "agua": 3, "oxigeno": 8, "alimento": 10}
const POLVOS_NORMALES := ["bajo", "medio", "alto"]
const RECARGA_SOLAR := {"bajo": 10.0, "medio": 15.0, "alto": 20.0, "tormenta": INF}
const CULTIVOS := {
	"lechuga": {"energia": 1, "alimento": 2, "segundos": 15.0},
	"rabano": {"energia": 3, "alimento": 3, "segundos": 10.0},
	"tomate": {"energia": 2, "alimento": 3, "segundos": 20.0},
	"papa": {"energia": 2, "alimento": 5, "segundos": 30.0},
}
const TIEMPO_OXIGENO := 8.0
const TIEMPO_ALIMENTO := 20.0
const ULTIMO_SOL := 5

var _sol := 1
var _reservas := RESERVAS_INICIALES.duplicate()
var _polvo := "medio"
var _en_curso := false
var _terminado := false
var _motivo := ""
var _aire_asegurado := false
var _hielo := 0
var _bandejas: Dictionary = {}
var _decisiones: Dictionary = {}
var _reloj_energia := 0.0
var _reloj_oxigeno := 0.0
var _reloj_alimento := 0.0

func iniciar_sol(polvo := "") -> bool:
	if _en_curso or _terminado or not _motivo.is_empty():
		return false
	if polvo.is_empty():
		polvo = POLVOS_NORMALES.pick_random()
	if not RECARGA_SOLAR.has(polvo):
		return false
	_polvo = polvo
	_en_curso = true
	cambiado.emit()
	return true

func avanzar(segundos: float) -> void:
	if not _en_curso or not is_finite(segundos) or segundos <= 0:
		return
	var restantes := segundos
	var periodo_solar: float = RECARGA_SOLAR[_polvo]
	var hubo_cambio := false
	while restantes > 0 and _en_curso:
		var hasta_aire := INF if _aire_asegurado else TIEMPO_OXIGENO - _reloj_oxigeno
		var paso := minf(restantes, minf(periodo_solar - _reloj_energia,
			minf(hasta_aire, TIEMPO_ALIMENTO - _reloj_alimento)))
		restantes -= paso
		if periodo_solar != INF:
			_reloj_energia += paso
		if not _aire_asegurado:
			_reloj_oxigeno += paso
		_reloj_alimento += paso
		for cultivo: String in _bandejas:
			var antes: float = _bandejas[cultivo]
			_bandejas[cultivo] = maxf(0, antes - paso)
			hubo_cambio = hubo_cambio or antes > 0
		if _reloj_energia >= periodo_solar:
			_reloj_energia = 0
			hubo_cambio = _cambiar_reserva("energia", 1) or hubo_cambio
		if _reloj_alimento >= TIEMPO_ALIMENTO:
			_reloj_alimento = 0
			hubo_cambio = _cambiar_reserva("alimento", -1) or hubo_cambio
		if not _aire_asegurado and _reloj_oxigeno >= TIEMPO_OXIGENO:
			_reloj_oxigeno = 0
			_cambiar_reserva("oxigeno", -1)
			hubo_cambio = true
			_comprobar_aire()
	if hubo_cambio:
		cambiado.emit()

func activar_oxigeno(energia := 6, agua := 1, alimento := 0) -> bool:
	if _aire_asegurado or energia < 1 or agua < 1 or alimento < 0:
		return false
	if not _aplicar({"energia": -energia, "agua": -agua, "alimento": -alimento}):
		return false
	_reservas.oxigeno = LIMITES.oxigeno
	_aire_asegurado = true
	_reloj_oxigeno = 0
	cambiado.emit()
	return true

func usar_tanques_emergencia(energia := 3) -> bool:
	# Decisión del Sol 3: protege la noche con una reserva más pequeña.
	if _sol != 3 or _aire_asegurado or energia < 1:
		return false
	if not _aplicar({"energia": -energia, "agua": -1, "oxigeno": -2, "alimento": 2}):
		return false
	_aire_asegurado = true
	_reloj_oxigeno = 0
	_comprobar_aire()
	cambiado.emit()
	return true

func recoger_hielo() -> bool:
	if not _en_curso:
		return false
	_hielo += 1
	cambiado.emit()
	return true

func purificar_hielo() -> bool:
	if _hielo == 0 or _reservas.agua == LIMITES.agua:
		return false
	if not _aplicar({"energia": -2, "agua": 3}):
		return false
	_hielo -= 1
	cambiado.emit()
	return true

func sembrar(cultivo: String) -> bool:
	if not CULTIVOS.has(cultivo) or _bandejas.has(cultivo):
		return false
	var ficha: Dictionary = CULTIVOS[cultivo]
	if not _aplicar({"energia": -ficha.energia, "agua": -1}):
		return false
	_bandejas[cultivo] = ficha.segundos
	cambiado.emit()
	return true

func comer(cultivo: String) -> bool:
	if not _en_curso or _bandejas.get(cultivo, -1) != 0 or _reservas.alimento == LIMITES.alimento:
		return false
	_cambiar_reserva("alimento", CULTIVOS[cultivo].alimento)
	_bandejas.erase(cultivo)
	cambiado.emit()
	return true

func aplicar_decision(id: String, cambios: Dictionary) -> bool:
	if id.is_empty() or _decisiones.has(id) or not _aplicar(cambios):
		return false
	_decisiones[id] = true
	_comprobar_aire()
	cambiado.emit()
	return true

func aplicar_perdidas(id: String, perdidas: Dictionary) -> bool:
	# Un evento obligatorio, por ejemplo una tormenta, puede agotar una reserva.
	if not _en_curso or id.is_empty() or _decisiones.has(id):
		return false
	for recurso: Variant in perdidas:
		if not LIMITES.has(recurso) or not perdidas[recurso] is int or perdidas[recurso] < 0:
			return false
	for recurso: String in perdidas:
		_cambiar_reserva(recurso, -perdidas[recurso])
	_decisiones[id] = true
	_comprobar_aire()
	cambiado.emit()
	return true

func dormir() -> bool:
	if not _en_curso:
		return false
	_en_curso = false
	if not _aire_asegurado:
		_motivo = "aire_sin_activar"
	elif _reservas.alimento == 0:
		_motivo = "hambre_al_dormir"
	elif _sol == ULTIMO_SOL:
		_terminado = true
	else:
		_sol += 1
		_aire_asegurado = false
		_decisiones.clear()
		_reloj_energia = 0
		_reloj_oxigeno = 0
		_reloj_alimento = 0
	cambiado.emit()
	return _motivo.is_empty()

func estado() -> Dictionary:
	# Copias para UI y niveles. Las escenas escriben solo mediante acciones.
	return {
		"sol": _sol, "reservas": _reservas.duplicate(), "polvo": _polvo, "en_curso": _en_curso,
		"terminado": _terminado, "derrota": _motivo, "aire_asegurado": _aire_asegurado,
		"hielo": _hielo, "bandejas": _bandejas.duplicate(),
		"decisiones": _decisiones.keys(), "sin_luz": _reservas.energia == 0,
	}

func guardar_estado() -> Dictionary:
	var datos := estado()
	datos["version"] = 1
	datos["relojes"] = [_reloj_energia, _reloj_oxigeno, _reloj_alimento]
	return datos

func restaurar_estado(datos: Dictionary) -> bool:
	if datos.get("version") != 1:
		return false
	for campo in ["sol", "hielo"]:
		if not datos.get(campo) is int:
			return false
	for campo in ["en_curso", "terminado", "aire_asegurado"]:
		if not datos.get(campo) is bool:
			return false
	if datos.sol < 1 or datos.sol > ULTIMO_SOL or datos.hielo < 0 or not RECARGA_SOLAR.has(datos.get("polvo")):
		return false
	if datos.get("derrota") not in ["", "oxigeno_agotado", "aire_sin_activar", "hambre_al_dormir"]:
		return false
	if datos.en_curso and (datos.terminado or not datos.derrota.is_empty()):
		return false
	if datos.terminado and (datos.sol != ULTIMO_SOL or not datos.derrota.is_empty()):
		return false
	if not datos.get("reservas") is Dictionary or not datos.get("bandejas") is Dictionary:
		return false
	for recurso: String in LIMITES:
		var valor: Variant = datos.reservas.get(recurso)
		if not valor is int or valor < 0 or valor > LIMITES[recurso]:
			return false
	if (datos.reservas.oxigeno == 0) != (datos.derrota == "oxigeno_agotado"):
		return false
	for cultivo: Variant in datos.bandejas:
		if not CULTIVOS.has(cultivo) or not _tiempo_valido(datos.bandejas[cultivo], CULTIVOS[cultivo].segundos):
			return false
	if not datos.get("decisiones") is Array or not datos.get("relojes") is Array or datos.relojes.size() != 3:
		return false
	var decisiones: Dictionary = {}
	for id: Variant in datos.decisiones:
		if not id is String or id.is_empty() or decisiones.has(id):
			return false
		decisiones[id] = true
	var periodos := [RECARGA_SOLAR[datos.polvo], TIEMPO_OXIGENO, TIEMPO_ALIMENTO]
	for indice in range(3):
		if not _tiempo_valido(datos.relojes[indice], periodos[indice]):
			return false
	_sol = datos.sol
	_hielo = datos.hielo
	_polvo = datos.polvo
	_en_curso = datos.en_curso
	_terminado = datos.terminado
	_aire_asegurado = datos.aire_asegurado
	_motivo = datos.derrota
	_reservas = datos.reservas.duplicate()
	_bandejas = datos.bandejas.duplicate()
	_decisiones = decisiones
	_reloj_energia = datos.relojes[0]
	_reloj_oxigeno = datos.relojes[1]
	_reloj_alimento = datos.relojes[2]
	cambiado.emit()
	return true

func _tiempo_valido(valor: Variant, limite: float) -> bool:
	return (valor is float or valor is int) and is_finite(valor) and valor >= 0 and valor <= limite

func _aplicar(cambios: Dictionary) -> bool:
	if not _en_curso:
		return false
	for recurso: Variant in cambios:
		if not LIMITES.has(recurso) or not cambios[recurso] is int:
			return false
		if _reservas[recurso] + cambios[recurso] < 0:
			return false
	for recurso: String in cambios:
		_cambiar_reserva(recurso, cambios[recurso])
	return true

func _cambiar_reserva(recurso: String, diferencia: int) -> bool:
	var anterior: int = _reservas[recurso]
	_reservas[recurso] = clampi(anterior + diferencia, 0, LIMITES[recurso])
	return anterior != _reservas[recurso]

func _comprobar_aire() -> void:
	if _reservas.oxigeno == 0:
		_motivo = "oxigeno_agotado"
		_en_curso = false
