# Día 4 | Antes de la tormenta

El día empieza con una alerta en Control. Pluto avisa si los sistemas quedaron dañados el día 2. El jugador ve sus cuatro reservas y elige si quiere conseguir agua, proteger el núcleo o hacer las dos tareas. El refugio, las salas y el personaje reutilizan el mapa y las animaciones existentes.

| Plan | Disponible con | Al completar |
| --- | --- | --- |
| Traer hielo | 5 de energía y 1 de comida | Gasta esas reservas y añade hasta 3 de agua. |
| Reforzar | 3 de energía | Gasta esa energía y activa el blindaje. |
| Ambas | 8 de energía y 5 de comida | Gasta 7 de energía y 1 de comida, añade hasta 3 de agua y activa el blindaje. |

**Hielo.** La salida del día 4 ocurre con cielo despejado y sin ráfagas. Cruza la esclusa y toca los dos puntos que marca Percy. En Control puedes consultar el mapa SWIM de NASA. El mapa orienta la búsqueda a escala regional y el sondeo ficticio comprueba lo que hay en cada punto. El polvo blanquecino en la superficie no garantiza que haya hielo debajo. Extrae la muestra en la veta, cárgala de vuelta y arrastra la caja al filtro azul. El gasto incluye la purificación. Se utiliza un identificador común para que no se puedan cobrar o acumular varias alternativas.

**Blindaje.** Recoge las protecciones en el Taller y trasládalas al núcleo, cuyo acceso se encuentra en la esclusa. Arrastra una pieza de blindaje a cada uno de los tres soportes junto a la compuerta. Si pruebas en la rejilla, Teo explica por qué debe seguir libre. Comprueba el aire al terminar. En el plan combinado las dos tareas concluyen antes de registrar las reservas y el refuerzo, de modo que se aplica el precio del plan completo.

**Cierre.** Agua y Oxígeno permite preparar el aire antes de salir o después de terminar. Cerca de las baterías puedes esperar un intervalo solar y ver cambiar las reservas. En Plantas puedes sembrar lechuga o comer de una bandeja madura. El dormitorio avisa de las consecuencias de descansar con hambre o sin aire preparado. El anfitrión ejecuta el descanso mediante el modelo compartido.

## Contrato de entrada y salida

- Antes de añadir `nivel.tscn` al árbol, llama a `configurar(recursos, historial)` con el modelo común en el día 4 ya abierto. El historial aporta `sistemas_danados` del día 2. Las reservas vigentes arrastran las consecuencias de los días 1, 2 y 3.
- `preparacion_completada(historial)` añade `plan_dia4` y `refugio_reforzado`. Guarda esos valores junto al estado del modelo. Si se retoma desde ese punto, se entra directamente en la preparación de la noche.
- `terminado("dia4_listo", historial)` pide al anfitrión llamar a `dormir()`, resolver derrota si falla y abrir el día 5 si se completa. La misma escena emite `derrota` si se agota el aire esperando.
- El paso del tiempo durante desplazamientos y herramientas se representa en los costos del plan. Solo avanzar la espera desde las baterías mueve el reloj del modelo en este tramo. El anfitrión suspende su propio reloj mientras la escena está activa.

Abre `scenes/dias/tramo_final/prueba.tscn` con F6 y selecciona una entrada de día 4. Usa WASD o flechas, toca o arrastra sobre los equipos y pulsa M para el plano. Las marcas muestran el nombre del destino. Cerca del equipo, pulsa E o haz clic. Los objetos se pueden arrastrar o colocar con E. Para la ruta combinada, después de trabajar debes recuperar al menos un punto de batería antes de preparar el aire. Si quieres terminar la misión, deja reservas suficientes para la mañana.

El filtro y los depósitos se inspiran en funciones reales de recuperación de agua y de producción de oxígeno. El juego representa ambas con reservas simplificadas. [Soporte vital, NASA](https://www.nasa.gov/reference/environmental-control-and-life-support-systems-eclss/) · [Hielo subterráneo, NASA SWIM](https://science.nasa.gov/resource/swim-map-shows-subsurface-water-ice-on-mars/)

Abre la computadora para consultar la tarea y elegir el plan. En campaña, consulta las reservas con **T**. Confirma la espera o el descanso volviendo a tocar el equipo. Alejarte cancela la confirmación.
