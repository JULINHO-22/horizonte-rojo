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
			energia += 5
		"cultivos":
			cultivo = "Protegido"
		"medicina":
			paciente = "Atendido · en reposo"
		"radio":
			ciencia_enviada = true


func relevo() -> Dictionary:
	var cuidados := 4 if paciente.begins_with("Lesión") else 1
	return {
		"ruta": ruta,
		"energia": energia - RESERVA_NOCTURNA,
		"raciones": raciones - 3,
		"operativos": operativos,
		"cultivo": cultivo,
		"paciente": paciente,
		"energia_comprometida": cuidados,
		"ciencia_enviada": ciencia_enviada,
		"acciones": acciones.duplicate(),
	}
