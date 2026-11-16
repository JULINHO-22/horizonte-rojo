extends RefCounted
## Objetivos del tutorial derivados de las reservas y la bitácora del Sol 1.
const CONTROL := "sol_1_control"
const COMIDA := "sol_1_comida"
const PREFIJO_COSECHA := "sol_1_cosecha_"
const DEPOSITOS := [
	{"id": "sol_1_hielo_cercano", "clave": "cercano", "x": 1040.0, "energia": 1, "hielo": 1, "alimento": 0},
	{"id": "sol_1_hielo_profundo", "clave": "profundo", "x": 1290.0, "energia": 1, "hielo": 2, "alimento": 1},
]
static func guia(objetivo_id: String) -> String:
	return I18n.t("sol1.guia." + objetivo_id, "")

static func nombre_deposito(sitio: Dictionary, baliza := false) -> String:
	var sufijo := ".baliza" if baliza else ""
	return I18n.t("sol1.dep." + sitio.get("clave", "cercano") + sufijo)

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
	var cansancio := I18n.t("sol1.dep.cansancio") if sitio.alimento > 0 else ""
	return I18n.tf("sol1.dep.etiqueta", [nombre_deposito(sitio), sitio.energia + sitio.hielo * 2, cansancio])
