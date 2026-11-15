# Sol 1

Pluto acompaña a Nora dentro de Umbra y sugiere el siguiente paso. Las estaciones y el descanso están disponibles desde la llegada, con sus requisitos de recursos habituales. En el laboratorio, asegurar el oxígeno consume 6 de energía y 1 de agua. Los relojes siguen activos durante la exploración y en el menú de Plantas. Los mensajes aparecen arriba a la izquierda y los controles de actividad arriba a la derecha. Los botones de Plantas usan fondos opacos y texto legible durante la cuenta regresiva.

En Plantas puedes sembrar varias bandejas si tienes recursos. El menú muestra el costo y el tiempo de cada cultivo. Una cuenta regresiva por bandeja indica cuánto falta para recoger y comer en la misma estación. Puedes quedarte allí a esperar o seguir explorando. Si sales por la esclusa, Iris acompaña a Nora hacia el este. Percy explica que hay hielo bajo el suelo y que el mapa SWIM ayuda a decidir dónde buscar. El juego reutiliza el paisaje, los personajes, el taladro y los sprites de hielo y caja del simulador.

| Depósito | Extracción | Purificación | Resultado con 1 de agua inicial |
| --- | --- | --- | --- |
| Cercano | 1 de energía, 1 de hielo | 2 de energía | +3 de agua |
| Profundo | 1 de energía y 1 de comida, 2 de hielo | 4 de energía | +5 de agua, hasta llenar el tanque |

Se elige un depósito. Si falta batería, los paneles siguen recargando durante la caminata o la espera fuera del menú. Teo lleva la muestra en la caja. El filtro azul derrite, filtra y comprueba una unidad de hielo por uso. Pluto recuerda los requisitos del descanso cuando termina la purificación.

El mapa SWIM PIA26045 representa evidencia regional de hielo bajo la superficie marciana. Los depósitos, cantidades y costos de Umbra son valores de juego. Créditos del mapa a NASA/JPL-Caltech/Planetary Science Institute. [NASA Science](https://science.nasa.gov/photojournal/swim-map-shows-subsurface-water-ice-on-mars/)

El controlador usa la misma instancia de recursos durante el tutorial. El guardado narrativo conserva la posición exterior y el depósito elegido. Tras la primera noche se transfieren las reservas y las bandejas mediante el contrato común.

Para probarlo, inicia una partida nueva con **F5**. La prueba `tests/narrativa_smoke.gd` comprueba el acceso a las estaciones, ambos depósitos, el rechazo por batería insuficiente, el guardado exterior, el filtro, la cosecha y el relevo hasta el regreso a la Tierra. Usa un perfil temporal.

## Relevo al Sol 2

Consulta la comida y las demás reservas en la tablet con **Q**. Para descansar, prepara el aire, conserva comida y guarda 6 de energía y 1 de agua para el siguiente sol. La tormenta del Sol 2 detiene la recarga solar. Si falta algo, Pluto indica cómo conseguirlo. Los guardados anteriores que ya llegaron al Sol 2 sin batería o agua suficientes reciben solo lo que falta para activar el aire, una vez por sol.
