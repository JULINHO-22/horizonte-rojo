extends RefCounted
## Regiones de los sprites de herramientas y de los instrumentos ya usados en la tablet.

const Indicadores := preload("res://scripts/mecanicas/indicadores_refugio.gd")
const ATLAS := preload("res://assets/equipo_actividades.png")
const TALADRO := preload("res://assets/taladro_hielo.png")
const MEDIDA_ORIGINAL := Vector2(1536, 1024)
const MEDIDA_TALADRO := Vector2(1774, 887)


static func hielo() -> AtlasTexture:
	return _escalar_recorte(ATLAS, Rect2(108, 322, 478, 448), MEDIDA_ORIGINAL)


static func boquilla() -> AtlasTexture:
	return _escalar_recorte(ATLAS, Rect2(846, 283, 540, 484), MEDIDA_ORIGINAL)


static func perforadora() -> AtlasTexture:
	return _escalar_recorte(TALADRO, Rect2(168, 138, 800, 588), MEDIDA_TALADRO)


static func broca() -> AtlasTexture:
	return _escalar_recorte(TALADRO, Rect2(1350, 273, 98, 426), MEDIDA_TALADRO)


static func indicador(region_normalizada: Rect2) -> AtlasTexture:
	var medida := Indicadores.ICONOS.get_size()
	return _recorte(Indicadores.ICONOS, Rect2(region_normalizada.position * medida, region_normalizada.size * medida))


static func _escalar_recorte(textura: Texture2D, marco: Rect2, medida: Vector2) -> AtlasTexture:
	var escala := textura.get_size() / medida
	return _recorte(textura, Rect2(marco.position * escala, marco.size * escala))


static func _recorte(textura: Texture2D, marco: Rect2) -> AtlasTexture:
	var parte := AtlasTexture.new()
	parte.atlas = textura
	parte.region = marco
	parte.filter_clip = true
	return parte
