# Día 5 | Bajo protección

En Control, pulsa **E** o toca el equipo para avisar a Tierra. La respuesta tarda. Sigue por la puerta sur y baja por el acceso lateral dentro de la esclusa, marcado también en el plano. La campaña permite visitar el mismo núcleo antes de la emergencia. La esclusa sigue siendo el vestíbulo que conecta la base con el exterior. Nora aparece cruzando el umbral abierto hasta el lado donde esperan Iris y Teo. El control a la derecha acciona la compuerta detrás de la tripulación. El indicador exterior sube y baja según las lecturas archivadas de Curiosity. La tormenta del día 2 es de polvo y la del día 5 corresponde a partículas del Sol.

| Antecedente | Pérdidas del impacto |
| --- | --- |
| Núcleo reforzado | 4 de energía y 1 de oxígeno. |
| Núcleo sin refuerzo | 7 de energía, 3 de oxígeno y 1 de agua. |
| Sistemas dañados el día 2 | Se pierde 1 de energía y 1 de oxígeno adicional. |

Después del impacto, la emisora muestra las reservas antes y después. La respuesta de Tierra llega tras haberse refugiado la tripulación. El jugador envía los resultados o confirma la evacuación en función del diagnóstico.

- `mision_cumplida` exige refuerzo y al menos 2 de energía, 3 de oxígeno, 1 de agua y 2 de comida.
- `evacuacion` requiere margen de seguridad sin refuerzo o, con refuerzo, oxígeno y comida pese a una reserva inferior al umbral de misión cumplida.
- `derrota` se usa si llega a 0 el aire o la comida en el impacto, o el modelo ya registró derrota. Se muestra solo Game Over sobre negro.

Con reservas insuficientes y sin refuerzo, la estación deja de transmitir. La salida se resuelve tras el impacto, el informe y la vuelta a la cápsula.

## Integración

Instancia el mismo `nivel.tscn` para el día 5 con el modelo común abierto y el historial del día 4. `impacto_registrado(historial)` entrega el resumen `impacto_solar` con `antes`, `despues` y `final`. Guarda el historial con el estado de recursos en un mismo punto de control. El evento tiene identificador estable y no vuelve a cobrar pérdidas al retomar. `terminado` devuelve uno de los tres resultados. La integración elige la transición de campaña y la cinemática.

El banco `scenes/dias/tramo_final/prueba.tscn` ofrece las tres entradas de prueba, llama a las cinemáticas existentes de regreso y permite probar también el relevo completo desde el día 4. Las entradas son perfiles de prueba. En campaña vendrán del progreso real.

## Arte y fuente

`assets/dias/dia_5/nucleo_radiacion.png` se generó con ImageGen integrado. El fondo fija la emisora a la izquierda, el blindaje y la compuerta en el centro y los tanques y asientos a la derecha. Los LED, la iluminación de emergencia y los personajes se dibujan sobre el fondo en Godot.

Prompt de ImageGen

> Production playable background for Horizonte Rojo, detailed retro 2D pixel-art Mars game. Entire frame represents the underground radiation-safe core of a believable modular space outpost. Fixed orthographic side-on cutaway platformer viewpoint, wide landscape 16:9. Hefty cream ceramic and orange-trim metal ribs, matte charcoal machinery, a few turquoise diagnostics, warm amber emergency lights. The ground must be a single level, wide, clean empty horizontal gray floor walkway with the contact line exactly at 76% image height for character sprites to walk. All props behind that line. Across the back wall: on the left x=16% a communications console with three cyan screens, around x=50% a large interior pressure bulkhead framed by three unmistakable built-in silver and amber shielding panels and sealed wall cabinets, on the right x=78% bench seats and racks of silver emergency air tanks, no clinic or beds. Recognizable silhouettes, controlled contrast around the floor, visible crisp hand-placed pixel clusters, no blur. Edge-to-edge full scene, no sky, no open exit to Mars, no sprites, no people, no letters or signs, no UI. Floor at the bottom spans full width.

La alerta usa el episodio de septiembre de 2017 documentado en DONKI con el identificador `2017-09-10T16:25:00-SEP-001`. El detector GOES-13 reportó el evento cerca de la Tierra. Las lecturas de la animación provienen del instrumento `MSL-RAD-Surface` de Curiosity en Marte. El juego usa las medianas de cuatro ventanas de una hora UTC.

| Hora UTC | Dosis absorbida en µGy/h | Fase del juego |
| --- | ---: | --- |
| 11 sep 00:00 | 8.030 | Antes de la subida |
| 11 sep 06:00 | 12.234 | Subida |
| 11 sep 14:00 | 21.816 | Pico |
| 12 sep 12:00 | 11.145 | Bajada |

El catálogo y las lecturas se consultaron por API pública. La muestra archivada está integrada en `archivo_nasa.gd`. El indicador normaliza los puntos respecto al primero y al pico, y comprime el tiempo. Las lecturas corresponden al exterior de Marte. Las pérdidas de reservas son reglas de diseño, y el evento no simula una dosis personal real.

- [Registro DONKI](https://ccmc.gsfc.nasa.gov/DONKI/view/SEP/13101/-1)
- [CSV de Curiosity en NASA OSDR/RadLab](https://visualization.osdr.nasa.gov/radlab/api/?spacecraft=Curiosity&timestamp%3E=2017-09-10&timestamp%3C2017-09-13&timestamp&absorbed_dose_rate)
- [NASA sobre áreas protegidas contra la radiación](https://www.nasa.gov/science-research/heliophysics/real-martians-how-to-protect-astronauts-from-space-radiation-on-mars/)

El día 5 presenta las acciones junto a la computadora, el control de la puerta y la emisora. La respuesta de Tierra y el informe del impacto se leen sobre sombras difuminadas dentro de la sala. Vuelve a usar la emisora para enviar resultados o confirmar la evacuación. Tras la señal de fin de alerta, abre la compuerta para volver a la cápsula. En campaña, **T** consulta las reservas.

El arte de la compuerta abierta se generó con ImageGen editando la ilustración del núcleo. El archivo `assets/dias/dia_5/nucleo_paso_abierto.png` aporta el pasillo. Godot desplaza las hojas de la compuerta original sobre el pasillo durante el cierre.

> Edit only the central hatch in the attached pixel art game background. Preserve exact framing, proportions, all walls, exact floor y, all vents, lights, three shield plates overhead, console, benches and tanks unchanged. Fully open the central double-leaf silver armored hatch by sliding the leaves to the sides into its existing orange armored frame, exposing a deep EMPTY CONNECTING INTERIOR PASSAGE inside the Mars base (no outdoors, no sky). Put cold bluish ceiling practicals, receding ribs and continuation of the walking floor INSIDE the open central doorway, with convincing depth and threshold. Maintain EXACT aperture x 41–59% of the canvas and y 43.5–76.4% of the canvas for compositing; keep all original orange bevels outside this region. The frame and scale should strongly match the reference. No new objects or humans, no lettering. Crisp 16:9 pixel art, same straight-on cutaway game perspective.
