# Mecánicas básicas y contrato de los niveles

Esta entrega se basa en **Mecánicas básicas (3)** y **Flujo de los cinco días y finales**. Contiene el modelo, el banco de pruebas y la conexión al recorrido principal. Las cuatro reservas se consultan en la tablet. Un solo laboratorio de Agua y Oxígeno reúne el filtro azul para purificar hielo y los depósitos verdes para asegurar el aire. Plantas permite sembrar, regar, recoger y comer. El [Sol 1](dias/DIA-1.md) obtiene hielo en la expedición.

## Cómo probarlo

En Godot 4.7.2, abre `scenes/pruebas/banco_recursos.tscn` y pulsa **F6**. Elige el polvo e inicia el día. Los botones **+8 s** y **+20 s** hacen avanzar todos los relojes. Prueba recargar el aire, sembrar y comer, o recoger y purificar hielo. Dormir conserva las reservas. Esta escena sirve para que el equipo compruebe reglas y valores sin tener que terminar una misión.

Para automatizar la comprobación, desde la raíz del checkout ejecuta:

```powershell
& "<ruta al ejecutable de consola de Godot 4.7.2>" --headless --script res://tests/recursos_smoke.gd --quit-after 140
```

El resultado esperado incluye `RECURSOS_OK`.

## Reglas implementadas

| Recurso | Inicial provisional / máximo | Regla |
| --- | --- | --- |
| Energía | 9 / 12 | Gana un rayo cada 10, 15 o 20 segundos según el polvo. Durante tormenta la generación es cero. Con batería vacía las acciones con costo eléctrico se rechazan. |
| Agua | 3 / 6 | No hay sed. Con agua a cero, no se pueden cultivar plantas ni recargar oxígeno. El hielo se carga como inventario. Purificar consume un hielo y 2 rayos, y aporta hasta 3 unidades de agua. Si el tanque ya está lleno, la operación se rechaza y conserva el hielo. |
| Oxígeno | 8 / 8 | Pierde una burbuja cada 8 segundos. La recarga normal cuesta 6 rayos y 1 agua, llena el tanque y lo estabiliza hasta dormir. El día 3 admite tanques de emergencia. |
| Alimento | 10 / 10 | Pierde un punto cada 20 segundos. A cero todavía se puede comer antes de dormir. Cultivar cuesta 1 agua más la energía de la ficha. Una bandeja por cultivo. La cosecha se consume de forma explícita cuando está lista. |

| Cultivo | Rayos | Espera | Alimento |
| --- | ---: | ---: | ---: |
| Lechuga | 1 | 15 s | +2 |
| Rábano | 3 | 10 s | +3 |
| Tomate | 2 | 20 s | +3 |
| Papa | 2 | 30 s | +5 |

Dormir con aire sin asegurar, dormir sin alimento o perder todo el oxígeno registra derrota. Dormir correctamente mantiene las barras, el hielo y las bandejas. Al despertar se reinician los intervalos de los relojes y se vuelve a comprobar el aire. Completar la quinta noche detiene el modelo. El valor `terminado` indica cierre del calendario y la futura integración decide qué final corresponde.

Los valores iniciales, la recuperación de hambre antes de dormir, el uso de emergencia del día 3 y el rechazo de la purificación con tanque lleno son decisiones provisionales de balance. Antes de cerrar los días 1 a 5, probar con números las rutas de éxito, emergencia y derrota. Verificar en particular el presupuesto para reparación más oxígeno del día 2 y para hielo, refuerzo y oxígeno del día 4.

## API que usarán los niveles

```gdscript
const Recursos := preload("res://scripts/mecanicas/recursos_mision.gd")

# En un banco local:
var partida := Recursos.new()
partida.iniciar_sol("medio")
partida.activar_oxigeno()
partida.avanzar(15.0)
print(partida.estado().reservas)
```

En campaña, el coordinador crea una instancia por partida, la entrega a cada día y se encarga de abrir y cerrar cada sol. Cada día **recibe la misma instancia** y emite su resultado al controlador. El reloj tiene **un solo dueño**. El controlador llama a `avanzar(delta)` durante juego activo y deja de llamarlo al pausar, dormir o mostrar cinemáticas y explicaciones. Un nivel nunca debe reiniciar la instancia o correr otro reloj de recursos.

| Método | Para qué sirve |
| --- | --- |
| `iniciar_sol()` / `iniciar_sol("tormenta")` | Sin argumento sortea polvo normal. Con argumento fija `bajo`, `medio`, `alto` o `tormenta`. Rechaza iniciar un sol en curso. |
| `estado()` y señal `cambiado` | Lee una copia del estado. Úsalo para dibujar indicadores, actualizar controles o mostrar la causa de derrota. |
| `recoger_hielo(cantidad, energia, deposito, alimento)` y `purificar_hielo()` | La extracción admite un costo de batería y comida y un identificador de depósito de un solo uso por sol. Cada uso del filtro procesa 1 hielo, cuesta 2 de energía y rinde hasta 3 de agua. El nivel comprueba cercanía y si ya se eligió otro depósito. |
| `activar_oxigeno(energia, agua, alimento, perder_cultivos)` | Recarga el aire una vez por sol. Por defecto usa 6, 1 y 0 sin afectar los cultivos. El Sol 3 puede variar los costos y perder las bandejas cuando se prioriza el aire. |
| `usar_tanques_emergencia(energia)` | Solo día 3, antes de asegurar el aire. Costo base de 3 energía, 1 agua y 2 oxígeno. Aporta 2 alimento y habilita el descanso si queda oxígeno. |
| `sembrar(id)` / `comer(id)` | Usa `lechuga`, `rabano`, `tomate` o `papa`. La ficha de costos y tiempos está en `CULTIVOS`. |
| `aplicar_decision(id, cambios)` | Cambios enteros con signo. Se aplican juntos si todos los costos caben. Se registra una vez por sol. La ganancia se limita al máximo. Ejemplo: `{"energia": -4, "alimento": -1}`. |
| `aplicar_perdidas(id, perdidas)` | Evento obligatorio como la tormenta final. Acepta cantidades positivas y puede agotar una barra. Se aplica una vez por sol. |
| `guardar_estado()` / `restaurar_estado(datos)` | Exporta y valida el estado con relojes y decisiones. El futuro controlador lo incluirá en el guardado general. Si ya hay un día activo restaurado, se continúa con su polvo y relojes. |
| `dormir()` | Cierra el día. Devuelve `false` en caso de derrota o si el día no estaba abierto. Lee `estado().derrota` para distinguir ambas situaciones. |

Las acciones devuelven si se aplicaron. La señal se emite después de actualizar el estado. Un resultado completado por un nivel debe usar su propio ID estable y avisar al controlador si deja efectos persistentes como paneles protegidos o refugio reforzado. El contrato de esos efectos, la selección de finales y la conexión con el guardado narrativo se integrarán con el equipo. Ningún día abre o modifica por su cuenta las cinemáticas.

## Ciencia y texto en pantalla

- Polvo y energía. «Con más polvo en el aire, llega menos luz a los paneles». Fuente para la relación: [NASA PDS, Pancam](https://pds.nasa.gov/ds-view/pds/viewProfile.jsp?dsid=MER1%2FMER2-M-PANCAM-5-ATMOS-OPACITY-V1.0).
- Cultivos y luz. «En un invernadero de prueba, el rábano recibió más luz que la lechuga». [NASA OSDR, EDEN ISS](https://osdr.nasa.gov/bio/repo/data/studies/OSD-895) y [NASA NTRS, cultivo de papa](https://ntrs.nasa.gov/citations/19950005536).
- Los rayos, burbujas y segundos son unidades del juego. En el juego principal se podrán mostrar 12 rayos, un tanque con la palabra «Oxígeno» y una gota para el agua. El banco interno usa controles simples para probar el contrato. Las fuentes pueden consultarse como enlaces, sin depender de una API para jugar.

La campaña abre la tablet con **Q** y le pasa una copia de las reservas del modelo. La tablet reutiliza los instrumentos del panel original. Control muestra objetivos y decisiones.

## Arte e interacción en Plantas

`scripts/invernadero_umbra.gd` comparte la vista de los soles 1 a 3. Colocar una semilla es un paso reversible. El riego se sostiene con **E** o presionando la tierra. Completar el gesto aplica `sembrar(id)` con el coste original y guarda la bandeja. El cultivo cambia de brote a planta joven y luego a cosecha según los segundos restantes. Comer usa `comer(id)` y muestra la ganancia efectiva según el espacio disponible. En el Sol 4, la animación se dibuja sobre el mapa y el reloj se actualiza al confirmar la espera solar.

El banco y el atlas se generaron con ImageGen integrado. `assets/instrumentos_control.png` aporta las gotas del riego. Los prompts del arte nuevo se registran aquí.

**Banco · `assets/huerto_banco.png`**, con `assets/plantas_horizonte.png` como referencia de estilo.

> Create a NEW in-world close-up angle of the greenhouse from the supplied Red Horizon pixel-art room, using the reference for material, palette and pixel style only. 16:9 environmental game background, front-facing slightly downward (see soil surfaces), highly readable crafted 2D pixel art, no photorealism. A continuous long workbench runs horizontally across the whole scene. Exactly four identical UNPLANTED low rectangular soil trays in one straight horizontal row on the bench, centered at 19%, 40%, 60%, 81% canvas width. The TOP SOIL lines of the four planters are equal at 55–60% canvas height, broad and free for sprites to be dynamically composited. Keep the four spaces above the planters quiet and clear, and leave a dark uncluttered band BELOW the trays with no important detail from 71% to bottom for game controls. The trays are real off-white steel containers with dark cocoa soil, small hose connections, rear amber grow lamps, pipes and dust-filtered Mars view far behind. Keep the top left similarly quiet for a short title. Warm cream alloy, charcoal steel, bright muted copper trim, warm amber highlights, coherent pixel detailing and deep rust window view. All four trays must be completely empty soil, no living plants anywhere in the central workbench, no foreground clutter or people, no text, labels, digits, borders or UI. Polished pixel art environment, native 16-bit game style.

**Atlas · `assets/huerto_cultivos.png`**, con doce sprites y transparencia.

> Game sprite atlas of greenhouse plants grown on Mars in highly readable retro 2D pixel art, square canvas with genuine transparent alpha background. A precise 3-column by 4-row atlas with 12 isolated objects, no others, evenly spaced with large transparent gutters of at least 12% around each sprite. Each sprite is centered in its own cell, ground base aligned within the row, top-down/front inspection angle, no pots, no square soil patches, no text, no labels, no guides. Every row is a different crop. Columns left to right are a tiny sprouted stage with two leaves, an adolescent plant, a mature harvestable plant. Row 1 lettuce (light green broad leaves, mature tightly ruffled head). Row 2 radish (thin green leaves and pink red round root, mature red root clearly visible for a depiction). Row 3 tomato (deep green distinct split leaves, mature small branch with ripe red tomatoes). Row 4 potato (sober green oval foliage, mature leafy stem plus three visible beige potato tubers). Clean distinctive sprites for small display sizes; visible crisp chunky hand-placed pixel blocks and dark brown/green pixel outlining, olive/amber warm greenhouse lighting, no antialias gradients, no scenery, no writing. Keep every object fully inside its own equal cell and disconnected from its neighbors.

## Arte y operación del laboratorio

`scripts/laboratorio_umbra.gd` presenta el filtro y la válvula del Sol 1. El Sol 2 reutiliza el filtro cuando hace falta agua. Colocar una muestra y sostener un mando muestran las fases del equipo. El coste se aplica al completar el gesto mediante `purificar_hielo()` o `activar_oxigeno()`. Soltar antes conserva los recursos. El Sol 3 usa el mismo banco para comparar los dos circuitos.

**Banco · `assets/laboratorio_banco.png`**, generado con ImageGen integrado a partir del estilo de `assets/laboratorio_agua_oxigeno.png`.

> game-asset | Design a new 16:9 playable close-up of Umbra's WATER AND OXYGEN laboratory, a straight-on cut-in view of the equipment bench shown in the reference. Match the very crisp 2D pixel art, warm bone enamel, copper orange edges, mineral cyan and green lights, and dark plum metal. Compose like a tangible point-and-click environment, two large distinct stations with highly readable touch targets, no game UI. LEFT half: at about 18 percent x and 47 percent y, a broad waist-height TRAY with an unobstructed DARK OPEN HATCH and dark soil-blue interior where a game ice chunk can be dragged. At 36 percent x, a tall cylindrical clear BLUE GLASS melt/filter column with a visible copper fitting and no ice inside, a small old-fashioned amber process button beneath it. RIGHT half: at about 60 to 85 percent x, two WHITE steel industrial cylinders with green mid bands, obvious pipes, twin round pressure gauges, and one large amber brass hand-wheel valve at about 69 percent x 53 percent y. Even, deeply shaded workshop walls, warmer amber footlights. Keep hardware and the bright centers between 24 and 72 percent of canvas height. Reserve the bottom 23 percent as visually quiet near-black iron floor and keep the upper left quiet for very short UI labels. Weathering detail where needed, exact industrial textures, pixel-art game aesthetic only. No labels, no text, no symbols, no numbers, no typography, no frames or cards, no people. High quality curated pixel art; the ice hatch and valve must stand out by material and lighting alone.

**Herramientas · `assets/equipo_actividades.png`**, generado con ImageGen integrado y recortado por regiones en Godot.

> game-asset | A strip of exactly two isolated handcrafted retro 2D pixel-art game sprites on genuine transparent alpha. Wide canvas 3:2, with a wide clear gutter between objects and large transparent margins, no shadows outside the objects. Left half centered around x=25 percent: a single fist-sized angular chunk of blue-white Martian water ice, visible ice facets, hints of rusty dust encrusted on one lower side, dark blue-purple silhouette outline. Right half centered around x=75 percent: a compact hand-held watering nozzle from a space greenhouse, a short brass nozzle and cream alloy body with a teal handle and copper trim. The nozzle tip points diagonally down and LEFT at about 45 degrees, with a clear recognizable tip, and no hose or hand, no stream. Very readable shapes at small size, blocky intentional pixels, warm highlights and plum outlines to match a polished 16-bit Mars game. No other objects, no frames, gray backdrop, patterns, UI, numbers, or lettering.

**Perforadora · `assets/taladro_hielo.png`**, generada con ImageGen integrado. Godot mueve la broca y la muestra en el escenario.

> game-asset | Generate a game-ready sprite atlas with exactly two separate objects on transparent RGBA for the 2D retro pixel art game Red Horizon. Use a landscape canvas, large empty margins and a wide gutter. LEFT half: a complete compact Mars ice sampling rig WITHOUT its bit, an off-white enamel and copper orange coring drill head bolted to a low dark teal rectangular steel gantry with two short sturdy footpads and a visible open center beneath the drill motor. Front/three-quarter from a very slight downward angle, reads at 36 pixels high. Cool graphite outlines and two mint service lights. The frame should look like purposeful meteorological field equipment, with a horizontal upper crossbeam and mechanical housings, not a triangle or construction scaffolding. The open gap should occupy the lowest half of the center so a separate bit can move down there. RIGHT half: an isolated slender vertical corkscrew coring BIT alone, short steel shaft in dark cool tones and bright edges, distinctly pointed end at bottom facing down, ready to move in the gantry. Fine intentional squared-off pixels in a 16-bit console visual style. Both objects fully visible, sharply separated, no terrain base, no characters, no separate shadow, no text, no cards, no symbols, no modern vector graphic.

> Remove the entire pale checker-like white-grey haze and alpha halo from the supplied pixel-art drill asset. This is a technical cutout request, keep the exact same two objects in the same positions, scale, and pixel style with all their internal cream and silver details preserved. Set every pixel outside the two object silhouettes to completely transparent alpha zero, including the full empty opening and floor under the upside-U-shaped left rig, all space within and between both feet, and all space surrounding the drill bit. Preserve crisp opaque pixels on the objects. Nothing behind or between them. NO filled white, gray, black, colored, mist, aura, shadow, glow, backdrop, stars or checkerboard baked into the art. Output as transparent RGBA asset with true empty gutters, do not crop either object.
