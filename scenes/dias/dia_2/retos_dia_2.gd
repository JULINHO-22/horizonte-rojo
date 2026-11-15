extends RefCounted
## Reglas de los tableros. No consume recursos ni controla el reloj de misión.

const PIEZAS := [1, 4, 5, 8]
const METAS := [2, 6, 4]
var giros: Array[int] = [0, 1, 3, 1]
var cierre := 0
var ajuste := 4
var tiempo := 0.0
var fallos := 0

func girar(indice: int) -> void:
	if indice >= 0 and indice < giros.size():
		giros[indice] = (giros[indice] + 1) % 4

func conexiones(celda: int) -> Array:
	if celda == 0:
		return [1, 3]
	var indice := PIEZAS.find(celda)
	if indice < 0:
		return []
	var giro: int = giros[indice]
	return [giro, (giro + 1) % 4] # Norte, este, sur, oeste.

func recorrido() -> Array[int]:
	var visitadas: Array[int] = []
	var celda := 0
	var entrada := 3
	while celda >= 0 and celda < 9 and celda not in visitadas:
		var pasos := conexiones(celda)
		if entrada not in pasos:
			break
		visitadas.append(celda)
		var salida: int = pasos[1] if pasos[0] == entrada else pasos[0]
		if celda == 8 and salida == 1:
			visitadas.append(9) # Depósito conectado.
			break
		if (salida == 1 and celda % 3 == 2) or (salida == 3 and celda % 3 == 0):
			break
		celda += [-3, 1, 3, -1][salida]
		entrada = (salida + 2) % 4
	return visitadas

func aire_conectado() -> bool:
	return 9 in recorrido()

func mover(cantidad: int) -> void:
	ajuste = clampi(ajuste + cantidad, 0, 8)

func calma() -> bool:
	return fposmod(tiempo, 4.0) < 2.8

func asegurar() -> String:
	if cierre >= METAS.size():
		return "listo"
	if ajuste != METAS[cierre]:
		fallos += 1
		return "alinear"
	if not calma():
		fallos += 1
		return "viento"
	cierre += 1
	ajuste = 4
	return "listo" if cierre == METAS.size() else "siguiente"
