class_name SolUno
extends RefCounted

const RESCATE := "rescate"
const ESPERA := "espera"
const RESERVA_NOCTURNA := 4
const ACCIONES := {
	"energia": {"costo": 3, "titulo": "Reconfigurar el inversor"},
	"cultivos": {"costo": 4, "titulo": "Estabilizar los cultivos"},
	"medicina": {"costo": 3, "titulo": "Atender al compañero"},
	"radio": {"costo": 2, "titulo": "Enviar datos a Tierra"},
}

var ruta := ""
var energia := 16
var raciones := 9
var operativos := 2
var cultivo := "Estable"
var paciente := ""
var ciencia_enviada := false
var acciones: Array[String] = []
var sol := 1
var agua := 6
var soporte := 100
var recuperacion := 0
var muestras := 0
var respuesta := false
var paneles_revisados := false

const EVENTOS := [
	"Polvo sobre los paneles. El refugio funciona con batería.",
	"El banco auxiliar sigue cargado. El robot puede traer hielo del depósito.",
	"El hielo almacenado puede fundirse y entrar al circuito de agua.",
	"Alerta de partículas solares. Usa el robot para las operaciones exteriores.",
	"Queda una ventana de radio. Envía el resultado del experimento a Tierra.",
]


func abrir(ruta_elegida: String) -> void:
	if not ruta.is_empty():
		return
	if ruta_elegida == RESCATE:
		energia -= 6
		cultivo = "En pausa"
		paciente = "Estable · en observación"
	elif ruta_elegida == ESPERA:
		energia -= 4
		paciente = "Lesión agravada · requiere vigilancia"
	else:
		return
	ruta = ruta_elegida


func disponible(id: String) -> bool:
	return (
		not ruta.is_empty()
		and ACCIONES.has(id)
		and acciones.size() < operativos
		and not acciones.has(id)
		and energia - RESERVA_NOCTURNA >= ACCIONES[id]["costo"]
	)


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
				if sol in [2, 3]:
					agua += 4
					muestras += 1
				else:
					raciones += 4
			cultivo = "Protegido"
		"medicina":
			recuperacion += 1
			paciente = "Recuperado · activo" if recuperacion >= 2 else "Atendido · en reposo"
		"radio":
			ciencia_enviada = true
			if sol > 1:
				muestras += 1


func siguiente_sol() -> void:
	var cierre := relevo()
	energia = maxi(0, int(cierre.energia) - int(cierre.energia_comprometida))
	raciones = cierre.raciones
	agua = cierre.agua
	soporte = cierre.soporte
	respuesta = acciones.has("radio")
	sol += 1
	energia = mini(24, energia + 9 + sol + (2 if paneles_revisados else 0))
	operativos = 3 if recuperacion >= 2 else 2
	acciones.clear()
	paneles_revisados = false


func relevo() -> Dictionary:
	var cuidados := 0 if recuperacion >= 2 else 4 if paciente.begins_with("Lesión") else 1
	var comida := raciones + (2 if sol > 1 and cultivo != "En pausa" else 0) - 3
	var agua_final := agua - 2
	var blindaje := 2 if sol == 4 and not paneles_revisados else 0
	var bateria := energia - RESERVA_NOCTURNA - blindaje
	var soporte_final := maxi(0, soporte - maxi(0, -comida) * 12 -
		maxi(0, -agua_final) * 15 - maxi(0, -bateria) * 10)
	return {
		"ruta": ruta,
		"energia": maxi(0, bateria),
		"raciones": maxi(0, comida),
		"agua": maxi(0, agua_final),
		"soporte": soporte_final,
		"muestras": muestras,
		"operativos": operativos,
		"cultivo": cultivo,
		"paciente": paciente,
		"energia_comprometida": cuidados,
		"ciencia_enviada": ciencia_enviada,
		"informe_hoy": acciones.has("radio"),
		"acciones": acciones.duplicate(),
	}
