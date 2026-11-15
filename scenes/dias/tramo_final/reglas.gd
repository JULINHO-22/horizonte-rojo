extends RefCounted
## Opera sobre la instancia común. El integrador guarda el resultado al recibir la señal del nivel.
const Recursos := preload("res://scripts/mecanicas/recursos_mision.gd")
const PLANES := {
	"hielo": {"titulo": "Traer hielo", "energia": 5, "alimento": 1, "agua": 3,
		"min_energia": 5, "min_alimento": 1, "refuerzo": false},
	"refuerzo": {"titulo": "Reforzar el refugio", "energia": 3, "alimento": 0, "agua": 0,
		"min_energia": 3, "min_alimento": 0, "refuerzo": true},
	"ambas": {"titulo": "Preparar las dos cosas", "energia": 7, "alimento": 1, "agua": 3,
		"min_energia": 8, "min_alimento": 5, "refuerzo": true},
}
const ID_PLAN := "dia4_preparacion"
const ID_TORMENTA := "dia5_tormenta_solar"

static func impedimento(plan: String, estado: Dictionary) -> String:
	if not PLANES.has(plan) or estado.sol != 4 or not estado.en_curso or estado.decisiones.has(ID_PLAN):
		return "Ya hay un plan completado para hoy."
	var ficha: Dictionary = PLANES[plan]
	if estado.reservas.energia < ficha.min_energia or estado.reservas.alimento < ficha.min_alimento:
		return "Requiere %d de energía y %d de alimento." % [ficha.min_energia, ficha.min_alimento]
	return ""

static func completar_plan(recursos: Recursos, plan: String) -> bool:
	if not impedimento(plan, recursos.estado()).is_empty():
		return false
	var ficha: Dictionary = PLANES[plan]
	return recursos.aplicar_decision(ID_PLAN,
		{"energia": -ficha.energia, "alimento": -ficha.alimento, "agua": ficha.agua})

static func impacto(recursos: Recursos, historial: Dictionary) -> Dictionary:
	var estado := recursos.estado()
	if estado.sol != 5:
		return {}
	var previo: Dictionary = historial.get("impacto_solar", {})
	if estado.decisiones.has(ID_TORMENTA):
		return previo.duplicate(true)
	var refuerzo: bool = historial.get("refugio_reforzado", false)
	var danio := int(historial.get("sistemas_danados", false))
	var perdidas := {
		"energia": (4 if refuerzo else 7) + danio,
		"oxigeno": (1 if refuerzo else 3) + danio,
		"agua": 0 if refuerzo else 1,
	}
	if not recursos.aplicar_perdidas(ID_TORMENTA, perdidas):
		return {}
	var despues := recursos.estado()
	return {"antes": estado.reservas, "despues": despues.reservas,
		"final": desenlace(despues, refuerzo)}

static func desenlace(estado: Dictionary, refuerzo: bool) -> String:
	var reserva: Dictionary = estado.reservas
	if not estado.derrota.is_empty() or reserva.oxigeno == 0 or reserva.alimento == 0:
		return "derrota"
	if refuerzo and reserva.energia >= 2 and reserva.oxigeno >= 3 and reserva.agua >= 1 and reserva.alimento >= 2:
		return "mision_cumplida"
	return "evacuacion"
