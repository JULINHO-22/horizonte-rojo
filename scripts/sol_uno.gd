class_name SolUno
extends RefCounted

const COSTO_RETORNO := 4
const TAMANO_TRIPULACION := 3
const RESERVA_NOCTURNA := 4
const MISIONES := ["energia", "agua", "radio", "energia", "radio"]
const OBJETIVOS := [
	"Devuelve la energía al aire y la calefacción",
	"Derrite el hielo y limpia el agua",
	"Cuenta a Tierra qué pasó con el agua",
	"Usa a Pluto para encender la protección del refugio",
	"Envía a Tierra los resultados de los cinco días",
]
const ACCIONES := {
	"energia": {"costo": 3, "titulo": "Conectar la batería de reserva"},
	"cultivos": {"costo": 4, "titulo": "Cuidar las plantas"},
	"agua": {"costo": 4, "titulo": "Comprobar y guardar el agua"},
	"radio": {"costo": 2, "titulo": "Enviar datos a Tierra"},
}

var regreso_iniciado := false
var energia := 16
var raciones := 9
var operativos := TAMANO_TRIPULACION
var cultivo := "Estable"
var ciencia_enviada := false
var acciones: Array[String] = []
var sol := 1
var agua := 6
var soporte := 100
var muestras := 0
var respuesta := false
var paneles_revisados := false

const CAMPOS_GUARDADO := [
	"regreso_iniciado", "energia", "raciones", "cultivo",
	"ciencia_enviada", "sol", "agua", "soporte", "muestras",
	"respuesta", "paneles_revisados",
]

const EVENTOS := [
	"Ve a Energía. El polvo tapó la luz del Sol. Usa la batería para mantener el aire limpio.",
	"Desde Energía, toma el pasillo del fondo. En el Centro de agua revisa la muestra antes de llenar el tanque.",
	"Ve a Control. Tierra necesita saber si el filtro funcionó antes de abrir otra reserva.",
	"Ve a Energía. Se acerca una tormenta del Sol. Pluto puede salir a encender la protección mientras ustedes esperan dentro.",
	"Ve a Control. La radio puede llegar a Tierra otra vez. Envía el resumen del agua y del refugio.",
]


func iniciar_regreso(gasto_taladro: int) -> void:
	if regreso_iniciado:
		return
	regreso_iniciado = true
	energia -= COSTO_RETORNO + gasto_taladro
	cultivo = "En pausa"


func disponible(id: String) -> bool:
	if id == "agua" and sol != 2:
		return false
	if not (
		regreso_iniciado
		and ACCIONES.has(id)
		and acciones.size() < operativos
		and not acciones.has(id)
		and energia - RESERVA_NOCTURNA >= ACCIONES[id]["costo"]
	):
		return false
	var principal: String = MISIONES[sol - 1]
	if id == principal or acciones.has(principal):
		return true
	var costo_total: int = ACCIONES[id]["costo"] + ACCIONES[principal]["costo"]
	if id == "energia":
		costo_total -= 6
	return acciones.size() < operativos - 1 and energia - RESERVA_NOCTURNA >= costo_total


func mision_cumplida() -> bool:
	return acciones.has(MISIONES[sol - 1])


func aplicar(id: String) -> void:
	if not disponible(id):
		return
	energia -= ACCIONES[id]["costo"]
	acciones.append(id)
	match id:
		"energia":
			energia += 5 if sol == 1 else 6
			paneles_revisados = sol > 1
		"cultivos":
			if sol > 1:
				raciones += 4
			cultivo = "Protegido"
		"agua":
			agua += 4
			muestras += 1
		"radio":
			ciencia_enviada = true
			if sol > 1:
				muestras += 1


func siguiente_sol() -> void:
	var cierre := relevo()
	energia = cierre.energia
	raciones = cierre.raciones
	agua = cierre.agua
	soporte = cierre.soporte
	respuesta = acciones.has("radio")
	sol += 1
	energia = mini(24, energia + 9 + sol + (2 if paneles_revisados else 0))
	acciones.clear()
	paneles_revisados = false


func datos_guardado() -> Dictionary:
	var datos := {"acciones": acciones.duplicate()}
	for campo: String in CAMPOS_GUARDADO:
		datos[campo] = get(campo)
	return datos


func restaurar_guardado(datos: Dictionary) -> bool:
	for campo: String in CAMPOS_GUARDADO:
		if not datos.has(campo) or typeof(datos[campo]) != typeof(get(campo)):
			return false
	if datos.sol < 1 or datos.sol > MISIONES.size():
		return false
	if not datos.get("acciones") is Array:
		return false
	for accion: Variant in datos.acciones:
		if not ACCIONES.has(accion):
			return false
	for campo: String in CAMPOS_GUARDADO:
		set(campo, datos[campo])
	acciones.assign(datos.acciones)
	return true


func relevo() -> Dictionary:
	var comida := raciones + (2 if sol > 1 and cultivo != "En pausa" else 0) - 3
	var agua_final := agua - 2
	var blindaje := 2 if sol == 4 and not paneles_revisados else 0
	var bateria := energia - RESERVA_NOCTURNA - blindaje
	var soporte_final := maxi(0, soporte - maxi(0, -comida) * 12 -
		maxi(0, -agua_final) * 15 - maxi(0, -bateria) * 10)
	return {
		"energia": maxi(0, bateria),
		"raciones": maxi(0, comida),
		"agua": maxi(0, agua_final),
		"soporte": soporte_final,
		"muestras": muestras,
		"operativos": operativos,
		"cultivo": cultivo,
		"ciencia_enviada": ciencia_enviada,
		"informe_hoy": acciones.has("radio"),
		"acciones": acciones.duplicate(),
	}
