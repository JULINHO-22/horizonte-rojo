extends RefCounted
## Puntos archivados para adaptar al ritmo del nivel. Las reservas siguen el PDF del equipo.
const DONKI_ID := "2017-09-10T16:25:00-SEP-001"
const DONKI := "https://ccmc.gsfc.nasa.gov/DONKI/view/SEP/13101/-1"
const SWIM := "https://science.nasa.gov/resource/swim-map-shows-subsurface-water-ice-on-mars/"
const GUIA_RAD := "https://visualization.osdr.nasa.gov/radlab/gui/knowledgebase/MSL-RAD-Surface"

# Medianas de ventanas UTC de una hora en el CSV de MSL-RAD-Surface, µGy/h.
const LECTURAS := [
	{"hora_utc": "2017-09-11T00", "tasa": 8.030, "fase": "Antes de la subida"},
	{"hora_utc": "2017-09-11T06", "tasa": 12.234, "fase": "Sube la radiación"},
	{"hora_utc": "2017-09-11T14", "tasa": 21.816, "fase": "Pico de radiación"},
	{"hora_utc": "2017-09-12T12", "tasa": 11.145, "fase": "Baja la radiación"},
]

static func nivel(indice: int) -> float:
	var base: float = LECTURAS[0].tasa
	return clampf((LECTURAS[indice].tasa - base) / (LECTURAS[2].tasa - base), 0.0, 1.0)
