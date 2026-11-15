extends RefCounted
## Objetivos del tutorial derivados de las reservas y la bitácora del Sol 1.
const CONTROL := "sol_1_control"
const COMIDA := "sol_1_comida"
const PREFIJO_COSECHA := "sol_1_cosecha_"
const DEPOSITOS := [
	{"id": "sol_1_hielo_cercano", "nombre": "Cercano", "x": 1040.0, "energia": 1, "hielo": 1},
	{"id": "sol_1_hielo_profundo", "nombre": "Profundo", "x": 1290.0, "energia": 3, "hielo": 2},
]
const GUIA := {
	"radio": "Acércate a la pantalla de Control. Revisemos las reservas.",
	"oxigeno": "Ve a la izquierda por Energía y sube al laboratorio de Agua y Oxígeno. Busca los depósitos verdes.",
	"sembrar": "Ve a Plantas por el pasillo derecho. Siembra una bandeja. Cada semilla cuesta agua y energía y tarda un tiempo distinto.",
	"cosechar": "Mira el reloj de tu cultivo. Cuando esté listo, recógelo y come aquí mismo. Los tomates muestran cuánta comida te queda.",
	"cierre": "Nos queda poca agua. Sal por la esclusa con Iris y busca hielo a la derecha. Aquí lo derretiremos y limpiaremos antes de beberlo.",
	"agua": "Vuelve al filtro azul del laboratorio. Derrite el hielo, limpia el agua y comprueba que esté lista para beber.",
	"dormitorio": "Cuando quieras terminar el día, revisa que tengas comida y aire asegurado. Puedes descansar en el dormitorio.",
}

static func deposito(datos: Dictionary) -> Dictionary:
	for sitio: Dictionary in DEPOSITOS:
		if sitio.id in datos.decisiones:
			return sitio
	return {}

static func objetivo(datos: Dictionary) -> String:
	if CONTROL not in datos.decisiones:
		return "radio"
	if datos.reservas.agua == 0 and not datos.aire_asegurado:
		return "cierre" if deposito(datos).is_empty() else "agua"
	if not datos.aire_asegurado:
		return "oxigeno"
	if datos.hielo > 0 and datos.reservas.agua < 6:
		return "agua"
	if not deposito(datos).is_empty():
		return "dormitorio"
	if cosecha(datos).is_empty() and COMIDA not in datos.decisiones:
		return "sembrar" if datos.bandejas.is_empty() else "cosechar"
	return "cierre"

static func cosecha(datos: Dictionary) -> String:
	for id: String in datos.decisiones:
		if id.begins_with(PREFIJO_COSECHA):
			return id.trim_prefix(PREFIJO_COSECHA)
	return ""

static func etiqueta_deposito(sitio: Dictionary) -> String:
	return "%s · %d energía · %d hielo" % [sitio.nombre, sitio.energia, sitio.hielo]
