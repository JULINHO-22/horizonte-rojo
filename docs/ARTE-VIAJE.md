# Arte 2D pixel art del viaje

## Dirección visual definitiva

Horizonte Rojo es un juego 2D pixel art. La cinemática no debe mezclar fondos realistas con sprites pixelados ni volver a formas geométricas dibujadas manualmente. `viaje_espacial.gd` crea seis capas `TextureRect` y anima únicamente imágenes: opacidad, encuadre, paralaje, escala, posición, giro y separación. Godot las empaqueta dentro de `index.pck`, por lo que la exportación Web/Firebase no depende de video, códecs o recursos remotos.

La continuidad física es obligatoria: la etapa de transferencia grande lleva el módulo acoplado al salir de la Tierra, lo libera cerca de Marte y `puesto.gd` presenta una variante aterrizada del mismo módulo. En el regreso, el orden se invierte y el módulo vuelve a acoplarse.

## Recursos activos

| Recurso | Uso |
| --- | --- |
| `assets/NarrativaInicio/TierraPixelArt.png` | Fondo de salida de la ida y llegada del regreso. |
| `assets/NarrativaInicio/EspacioProfundoPixelArt.png` | Fondo intermedio del traslado de meses. |
| `assets/NarrativaInicio/MartePixelArt.png` | Fondo de llegada de la ida y salida del regreso. |
| `assets/NarrativaInicio/NaveTransferenciaPixelArt.png` | Etapa propulsora grande, con aro de acople frontal. |
| `assets/NarrativaInicio/ModuloDescensoOrbitalPixelArt.png` | Módulo compacto acoplado y luego separado en órbita. |
| `assets/NarrativaInicio/ModuloDescensoAterrizajePixelArt.png` | El mismo módulo con patas y escalera desplegadas en Marte. |
| `assets/NarrativaInicio/EstelaPropulsionPixelArt.png` | Llama/estela transparente que pulsa durante los impulsos. |

Conservar cada PNG junto con su `.import`. Los recursos anteriores sin el sufijo `PixelArt`, las primeras naves realistas y las imágenes raíz `viaje_*.png`/`nave_*.png` están obsoletos y se excluyen del preset Web.

## Conjunto de prompts final

Las siete imágenes se generaron con ImageGen integrado, sin CLI ni clave API. El conjunto de prompts exigió una estética común: pixel art 2D de alta calidad, píxel deliberado y nítido, paleta retro de ciencia ficción con crema, cobre, azul oscuro y luces cian, perspectiva lateral/tres cuartos, sin texto, interfaz, logotipos o marcas de agua.

- **Tierra:** fondo panorámico 16:9 desde órbita, planeta grande a la izquierda, África y Atlántico legibles, nubes, halo azul, espacio oscuro libre a la derecha; sin nave.
- **Espacio profundo:** fondo panorámico 16:9, estrellas finas, banda tenue de polvo cósmico y gran zona central despejada; sin planetas grandes ni nave.
- **Marte:** fondo panorámico 16:9, planeta/terreno rojo ocre, cráteres y cañones, borde atmosférico tenue, espacio libre para la aproximación; sin nave.
- **Etapa de transferencia:** sprite horizontal completo apuntando a la derecha, gran cuerpo propulsor cilíndrico, tanques, paneles solares cortos, antena, motor a la izquierda y aro de acople a la derecha; fondo transparente, sin módulo ni llama.
- **Módulo orbital:** sprite compacto apuntando a la derecha, cabina crema con franja violeta, ventanas cian y aro de acople visible a la izquierda; patas y escalera guardadas; fondo transparente.
- **Módulo aterrizado:** misma identidad, colores, ventanas y proporciones del módulo orbital; vista lateral/tres cuartos, patas desplegadas y escalera hacia el suelo; fondo transparente.
- **Estela:** llama de motor horizontal apuntando a la izquierda, núcleo blanco/cian, transición azul y naranja, bordes pixelados; fondo transparente y sin motor.

## Composición y movimiento

La ida dura 5,4 segundos y el aterrizaje 2,6. Los fondos pixel art se funden con paneo limitado al visor. Los aros de acople son los puntos de referencia al colocar las dos piezas. Entre el 49 % y el 73 % del trayecto el propulsor se aparta hacia arriba e izquierda. La cámara vuelve a encuadrar la cápsula, que aumenta de tamaño y continúa sola. Un breve fundido da paso al módulo con patas y escalera del aterrizaje. La cinemática reutiliza las ilustraciones de NarrativaInicio. El texto y el botón de salto aparecen en las esquinas.

Las coordenadas de acople consideran el margen transparente interno de los PNG; no deben sustituirse por una separación visual fija. La revisión Web final comprobó que el módulo sale acoplado y que la llegada muestra el mismo diseño ya aterrizado.

## Alcance

Esta secuencia representa meses de viaje de forma ilustrativa; no es una simulación orbital ni valida un plan de vuelo. No añade actividades diarias. Percy sigue siendo Perseverance dentro de la ficción y Pluto es el asistente ficticio del refugio.

## Regreso a la Tierra

Solo viaja el módulo de descenso. La etapa de transferencia y su estela se ocultan durante todo el regreso.

## Acabado de la nave

ImageGen integrado revisó la etapa de transferencia, la cápsula orbital, la cápsula con patas desplegadas y la cápsula que se ve en el hangar y en el noticiero. Las placas usan azul pizarra, las bandas violeta apagado y las luces verde petróleo. Se conservan los aros de acople, la escalera y las patas. La portada usa pizarra, verde suave y lavanda sobre el panorama de Marte.

Prompt de paleta

> Use a dark desaturated slate-blue hull (midtones #526575, highlights #82929e), charcoal shadow structure, muted dusty violet stripe (#736783), restrained sea-glass teal lenses and fittings (#538b87). Replace all orange/yellow hardware accents with dark petrol teal and all cream/white plating with painted slate-blue titanium. Preserve the readable contrast and each pixel-art edge. No orange paint or white hull. Preserve exact object bounding box, camera, silhouette, crop, transparent canvas, each connector, leg, and proportion.
