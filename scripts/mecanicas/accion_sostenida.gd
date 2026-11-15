extends RefCounted
## Un gesto se completa al sostener su entrada. Soltar antes cancela el intento.

var fuente: StringName = &""
var progreso := 0.0
var _duracion := 1.0


func iniciar(origen: StringName, segundos: float) -> bool:
	if activa():
		return false
	fuente = origen
	_duracion = segundos
	return true


func activa() -> bool:
	return not fuente.is_empty()


func soltar(origen: StringName = &"") -> bool:
	if not activa() or (not origen.is_empty() and origen != fuente):
		return false
	fuente = &""
	progreso = 0.0
	return true


func avanzar(delta: float) -> bool:
	if not activa():
		return false
	progreso = minf(1.0, progreso + delta / _duracion)
	if progreso < 1.0:
		return false
	soltar()
	return true
