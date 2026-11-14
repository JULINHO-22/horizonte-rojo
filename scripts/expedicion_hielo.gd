extends RefCounted

enum Accion { EXAMINAR, PERFORAR, RECOGER, CAMINAR, ESPERAR }
enum Resultado { NINGUNO, EXAMINADO, SECO, SECO_REPETIDO, PERFORANDO, EN_MANO }

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
var muestra_en_mano := false
var muestra_guardada := false


func accion(sitio: int) -> Accion:
	if muestra_guardada or muestra_en_mano:
		return Accion.ESPERAR
	if muestra_lista:
		return Accion.RECOGER if sitio == VETA else Accion.CAMINAR
	if sitio < 0:
		return Accion.CAMINAR
	if not examinados.has(sitio):
		return Accion.EXAMINAR
	if examinados.size() >= 2:
		return Accion.PERFORAR
	return Accion.CAMINAR


func interactuar(sitio: int) -> Resultado:
	match accion(sitio):
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
			muestra_en_mano = true
			return Resultado.EN_MANO
	return Resultado.NINGUNO


func guardar_muestra() -> bool:
	if not muestra_en_mano:
		return false
	muestra_en_mano = false
	muestra_guardada = true
	return true
