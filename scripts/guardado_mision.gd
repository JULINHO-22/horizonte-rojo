extends RefCounted

const ARCHIVO := "user://mision.cfg"
const VERSION := 3
const PUNTOS := ["chequeo", "salida", "exterior", "evacuacion", "base", "relevo"]


static func guardar(punto: Dictionary, estado: SolUno) -> bool:
	var registro := ConfigFile.new()
	registro.set_value("mision", "version", VERSION)
	registro.set_value("mision", "punto", punto)
	registro.set_value("mision", "campana", estado.datos_guardado())
	var temporal := ARCHIVO + ".tmp"
	if registro.save(temporal) != OK:
		return false
	return DirAccess.rename_absolute(temporal, ARCHIVO) == OK


static func cargar(estado: SolUno) -> Dictionary:
	var registro := ConfigFile.new()
	if registro.load(ARCHIVO) != OK:
		return {}
	var version: Variant = registro.get_value("mision", "version", 0)
	if version not in [1, 2, VERSION]:
		return {}
	var punto: Variant = registro.get_value("mision", "punto", {})
	var campana: Variant = registro.get_value("mision", "campana", {})
	if not punto is Dictionary or not campana is Dictionary:
		return {}
	if not PUNTOS.has(punto.get("fase")) or not punto.get("posicion") is Vector2:
		return {}
	if version == 1:
		campana["regreso_iniciado"] = punto.fase in ["evacuacion", "base", "relevo"]
		if campana.get("acciones") is Array:
			campana.acciones = campana.acciones.filter(func(id: Variant) -> bool: return id != "medicina")
	var lugar: Vector2 = punto.posicion
	if not lugar.is_finite() or not estado.restaurar_guardado(campana):
		return {}
	if version < VERSION and punto.fase == "base":
		if Rect2(-392, -33, 402, 240).has_point(lugar):
			punto.posicion = PuestoUmbra.EQUIPO_AGUA[0]
		elif Rect2(823, 11, 402, 240).has_point(lugar):
			punto.posicion = Vector2(601, 245)
		elif version == 1 and Rect2(554, 147, 245, 194).has_point(lugar):
			punto.posicion = PuestoUmbra.ENTRADA
	return punto


static func borrar() -> void:
	if FileAccess.file_exists(ARCHIVO):
		DirAccess.remove_absolute(ARCHIVO)
