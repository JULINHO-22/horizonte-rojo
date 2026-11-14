extends RefCounted

enum Accion { EXAMINAR, PERFORAR, RECOGER, CAMINAR, ESPERAR }
enum Resultado { NINGUNO, EXAMINADO, SECO, SECO_REPETIDO, PERFORANDO, GUARDADO }

const ALCANCE := 23.0
const LECTURAS := [
	"Tierra seca de arriba abajo.",
	"Escarcha arriba. Debajo sigue seco.",
	"Una franja de hielo bajo la tierra.",
]
const VETA := 2

var examinados: Array[int] = []
var lectura := -1
var gasto := 0
var muestra_lista := false
var muestra_guardada := false


func accion(sitio: int, cerca_caja: bool) -> Accion:
	if muestra_guardada:
		return Accion.ESPERAR
	if muestra_lista:
		return Accion.RECOGER if cerca_caja else Accion.CAMINAR
	if sitio < 0:
		return Accion.CAMINAR
	if not examinados.has(sitio):
		return Accion.EXAMINAR
	if examinados.size() >= 2:
		return Accion.PERFORAR
	return Accion.CAMINAR


func interactuar(sitio: int, cerca_caja: bool) -> Resultado:
	match accion(sitio, cerca_caja):
		Accion.EXAMINAR:
			examinados.append(sitio)
			lectura = sitio
			return Resultado.EXAMINADO
		Accion.PERFORAR:
			lectura = sitio
			if sitio == VETA:
				return Resultado.PERFORANDO
			if gasto > 0:
				return Resultado.SECO_REPETIDO
			gasto = 1
			return Resultado.SECO
		Accion.RECOGER:
			muestra_guardada = true
			return Resultado.GUARDADO
	return Resultado.NINGUNO
