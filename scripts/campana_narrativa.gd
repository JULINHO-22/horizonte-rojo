extends RefCounted
## Estado del ensayo del guion. No calcula recursos ni aprueba actividades.
const ARCHIVO := "user://narrativa.cfg"
const SOLES := 5
var sol := 1
var noches := 0

func terminar_noche() -> bool:
	# Una noche solo se registra una vez, también tras recargar.
	if noches >= sol:
		return false
	noches = sol
	if sol < SOLES:
		sol += 1
	return true

func listo_para_regresar() -> bool:
	return noches == SOLES

func guardar(fase: String, posicion: Vector2) -> Error:
	var archivo := ConfigFile.new()
	archivo.set_value("guion", "version", 1)
	archivo.set_value("guion", "sol", sol)
	archivo.set_value("guion", "noches", noches)
	archivo.set_value("guion", "fase", fase)
	archivo.set_value("guion", "posicion", posicion)
	var resultado := archivo.save(ARCHIVO + ".tmp")
	if resultado != OK:
		return resultado
	return DirAccess.rename_absolute(ARCHIVO + ".tmp", ARCHIVO)

func cargar() -> Dictionary:
	var archivo := ConfigFile.new()
	if archivo.load(ARCHIVO) != OK or archivo.get_value("guion", "version") != 1:
		return {}
	var dia: Variant = archivo.get_value("guion", "sol")
	var descanso: Variant = archivo.get_value("guion", "noches")
	var lugar: Variant = archivo.get_value("guion", "posicion")
	var fase: Variant = archivo.get_value("guion", "fase")
	if not dia is int or not descanso is int or not lugar is Vector2:
		return {}
	if dia < 1 or dia > SOLES or descanso != (SOLES if descanso == SOLES else dia - 1):
		return {}
	if descanso == SOLES and dia != SOLES:
		return {}
	if not lugar.is_finite() or fase not in ["base", "camino_base", "camino_nave", "epilogo"]:
		return {}
	sol = dia
	noches = descanso
	return {"fase": fase, "posicion": lugar}

func borrar() -> void:
	if FileAccess.file_exists(ARCHIVO):
		DirAccess.remove_absolute(ARCHIVO)
