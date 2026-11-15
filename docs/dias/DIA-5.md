# Día 5 | Bajo protección

Consulta Control, envía el informe a Tierra y ve al núcleo protegido por la esclusa. Cuando cierres la compuerta, llega el pico de la tormenta solar. El día 2 fue una tormenta de polvo. En el día 5 nos protegemos de las partículas del Sol. El núcleo enseña en qué zona se reúne la tripulación y muestra el estado del blindaje.

| Antecedente | Pérdidas del impacto |
| --- | --- |
| Núcleo reforzado | 4 de energía y 1 de oxígeno. |
| Núcleo sin refuerzo | 7 de energía, 3 de oxígeno y 1 de agua. |
| Sistemas dañados el día 2 | Se pierde 1 de energía y 1 de oxígeno adicional. |

Después del impacto, la emisora muestra las reservas antes y después. La respuesta de Tierra llega tras haberse refugiado la tripulación. El jugador envía los resultados o confirma la evacuación en función del diagnóstico.

- `mision_cumplida` exige refuerzo y al menos 2 de energía, 3 de oxígeno, 1 de agua y 2 de comida.
- `evacuacion` se usa si queda aire y comida pero falta otra condición de misión cumplida.
- `derrota` se usa si llega a 0 el aire o la comida en el impacto, o el modelo ya registró derrota. Se muestra solo Game Over sobre negro.

El umbral de evacuación y resolver la salida sin una quinta noche son decisiones de esta rama. El PDF describe supervivencia sin cifras exactas para evacuar y permite resolver tras el impacto. Si el equipo cambia ese criterio, edita `Reglas.desenlace()` y sus pruebas.

## Integración

Instancia el mismo `nivel.tscn` para el día 5 con el modelo común abierto y el historial del día 4. `impacto_registrado(historial)` entrega el resumen `impacto_solar` con `antes`, `despues` y `final`. Guarda el historial con el estado de recursos en un mismo punto de control. El evento tiene identificador estable y no vuelve a cobrar pérdidas al retomar. `terminado` devuelve uno de los tres resultados. La integración elige la transición de campaña y la cinemática.

El banco `scenes/dias/tramo_final/prueba.tscn` ofrece las tres entradas de prueba, llama a las cinemáticas existentes de regreso y permite probar también el relevo completo desde el día 4. Las entradas son perfiles de prueba. En campaña vendrán del progreso real.

## Arte y fuente

`assets/dias/dia_5/nucleo_radiacion.png` se generó con ImageGen integrado. El fondo fija la emisora a la izquierda, el blindaje y la compuerta en el centro y los tanques y asientos a la derecha. Los LED, la iluminación de emergencia y los personajes se dibujan sobre el fondo en Godot.

Prompt de ImageGen

> Production playable background for Horizonte Rojo, detailed retro 2D pixel-art Mars game. Entire frame represents the underground radiation-safe core of a believable modular space outpost. Fixed orthographic side-on cutaway platformer viewpoint, wide landscape 16:9. Hefty cream ceramic and orange-trim metal ribs, matte charcoal machinery, a few turquoise diagnostics, warm amber emergency lights. The ground must be a single level, wide, clean empty horizontal gray floor walkway with the contact line exactly at 76% image height for character sprites to walk. All props behind that line. Across the back wall: on the left x=16% a communications console with three cyan screens, around x=50% a large interior pressure bulkhead framed by three unmistakable built-in silver and amber shielding panels and sealed wall cabinets, on the right x=78% bench seats and racks of silver emergency air tanks, no clinic or beds. Recognizable silhouettes, controlled contrast around the floor, visible crisp hand-placed pixel clusters, no blur. Edge-to-edge full scene, no sky, no open exit to Mars, no sprites, no people, no letters or signs, no UI. Floor at the bottom spans full width.

Curiosity detectó un aumento de radiación en la superficie durante la tormenta solar de mayo de 2024. El caso documenta el fenómeno que inspira la alerta. Los costos, daños, tiempos y reservas de esta misión son reglas de juego y no lecturas de radiación. [Observación de Curiosity, NASA Science](https://science.nasa.gov/resource/curiosity-sees-streaks-and-specks-during-2024-solar-storm/)
