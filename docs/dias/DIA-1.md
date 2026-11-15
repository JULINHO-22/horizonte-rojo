# Sol 1

Pluto acompaña a Nora dentro de Umbra y sugiere el siguiente paso. Las estaciones y el descanso están disponibles desde la llegada, con sus requisitos de recursos habituales. En el laboratorio, mantén **E** o la rueda ámbar hasta estabilizar la presión de los tanques. Asegurar el oxígeno consume 6 de energía y 1 de agua. Los relojes siguen activos durante la exploración y al atender las bandejas.

En Plantas, elige una bandeja con el ratón o **1–4** y coloca la semilla. Mantén **E** o la tierra pulsada para regar. El coste se aplica cuando se completa el riego. El reloj y el aspecto de la planta muestran cuánto falta para recoger y comer en esa misma bandeja. Puedes quedarte o seguir explorando. Si sales por la esclusa, Iris acompaña a Nora hacia el este. Percy explica que hay hielo bajo el suelo y que el mapa SWIM ayuda a decidir dónde buscar. El paisaje, los personajes y la caja se reutilizan del recorrido base. El nuevo taladro anima el desplazamiento de la broca.

| Depósito | Extracción | Purificación | Resultado con 1 de agua inicial |
| --- | --- | --- | --- |
| Cercano | 1 de energía, 1 de hielo | 2 de energía | +3 de agua |
| Profundo | 1 de energía y 1 de comida, 2 de hielo | 4 de energía | +5 de agua, hasta llenar el tanque |

Elige un depósito y mantén **E** o su indicación pulsada hasta extraer la muestra. Si falta batería, los paneles siguen recargando durante la caminata o la espera fuera del menú. Teo lleva la muestra en la caja. En el filtro, arrastra el hielo a la cubeta o pulsa **E** para cargarlo. Después mantén el botón ámbar o **E** para derretir y filtrar la muestra. Pluto recuerda los requisitos del descanso al terminar.

El mapa SWIM PIA26045 representa evidencia regional de hielo bajo la superficie marciana. Los depósitos, cantidades y costos de Umbra son valores de juego. Créditos del mapa a NASA/JPL-Caltech/Planetary Science Institute. [NASA Science](https://science.nasa.gov/photojournal/swim-map-shows-subsurface-water-ice-on-mars/)

El controlador usa la misma instancia de recursos durante el tutorial. El guardado narrativo conserva la posición exterior y el depósito elegido. Tras la primera noche se transfieren las reservas y las bandejas mediante el contrato común.

Para probarlo, inicia una partida nueva con **F5**. La prueba `tests/narrativa_smoke.gd` comprueba el acceso a las estaciones, ambos depósitos, el rechazo por batería insuficiente, el guardado exterior, el filtro, la cosecha y el relevo hasta el regreso a la Tierra. Usa un perfil temporal.

## Relevo al Sol 2

Consulta la comida y las demás reservas en la tablet con **Q**. Para descansar, prepara el aire, conserva comida y guarda 6 de energía y 1 de agua para el siguiente sol. La tormenta del Sol 2 detiene la recarga solar. Si falta algo, Pluto indica cómo conseguirlo. Los guardados anteriores que ya llegaron al Sol 2 sin batería o agua suficientes reciben solo lo que falta para activar el aire, una vez por sol.
