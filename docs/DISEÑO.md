# Diseño de UMBRA

## Alcance del primer prototipo

Iris presenta a Tierra el objetivo de mantener un puesto con recursos locales. El viento levanta polvo y baja la generación solar. Iris ordena cerrar la esclusa. Teo, técnico de superficie, cae y queda atrapado junto al rover averiado. Nora, piloto y personaje jugable, se acerca al rover para evaluar el rescate. El robot advierte que el cabrestante comparte el circuito del invernadero. Nora elige usar el circuito ahora o cerrar la esclusa y volver por Teo tras una tregua. La extracción se representa con una secuencia corta y el jugador lleva a Teo hasta la esclusa.

El objetivo del Sol 1 es mantener el soporte vital y elegir qué trabajos hacer con dos personas disponibles. La misión completa tiene cinco soles. La duración de la tormenta, la curva de recuperación y los desenlaces de los soles 2 a 5 quedan abiertos para el equipo.

El aspecto provisional usa las referencias como ilustración exterior y retratos. El plano original se conserva como referencia de composición. El interior se dibuja en 2D con suelos, paredes, muebles, personajes y luces. Los trajes distinguen a Nora (rosa), Iris (turquesa) y Teo (ámbar). El robot cumple el papel de guía y explica el costo inmediato. Registrar la autoría y los permisos de las referencias antes de distribuir públicamente el juego.

### Recorrido y zonas

La esclusa al sur desemboca en control, el centro de comunicaciones. Tres pasillos conectan control con energía al oeste, el invernadero al norte y enfermería al este. Los equipos bloquean el paso y los terminales se abren con **E** al acercarse. Las luces de los cultivos, la consola de radio y la camilla reflejan el estado del Sol 1. El registro de la esclusa cierra el día. Los límites y puntos de interacción están en `scripts/puesto.gd`.

## Presupuesto del Sol 1

Los valores son de diseño y están sujetos a pruebas. **UE** significa unidad abstracta de energía. El estado inicial tiene 16 UE y 9 raciones. El cierre reserva 4 UE de soporte vital y consume 3 raciones.

| Decisión | UE antes de operar | Cultivos | Salud al entrar | Trabajo disponible |
| --- | ---: | --- | --- | ---: |
| Rescatar ahora | 10 | En pausa | Estable en observación | 2 |
| Cerrar y esperar | 12 | Estables | Lesión agravada | 2 |

Cada módulo se puede operar una vez por sol. Cada tarea consume un turno de trabajo y respeta la reserva nocturna.

| Módulo | Efecto |
| --- | --- |
| Energía | Usa 3 UE para recuperar 5 UE del banco auxiliar. |
| Invernadero | Usa 4 UE y deja las bandejas protegidas durante la noche. |
| Enfermería | Usa 3 UE y deja al compañero atendido y en reposo. |
| Comunicaciones | Usa 2 UE y envía la lectura del polvo a Tierra. La respuesta queda pendiente. |

Con energía y radio en ambas rutas, el rescate deja **6 UE**, cultivos en pausa y **1 UE** de cuidados previstos. La espera deja **8 UE**, cultivos estables y **4 UE** de cuidados previstos. Una vez cubiertos los cuidados, quedarían **5 UE** tras el rescate temprano y **4 UE** tras la espera. La espera preserva producción y batería a corto plazo. Dedicarle un turno a enfermería reduce la previsión de cuidados a 1 UE y desplaza otro trabajo.

## Contrato con el Sol 2

`SolUno.relevo()` devuelve un diccionario en memoria. Se obtiene después de ejecutar las tareas elegidas. El Sol 2 podrá consumirlo para iniciar su propia escena.

| Clave | Tipo y significado |
| --- | --- |
| `ruta` | String, `rescate` o `espera`. |
| `energia`, `raciones` | Enteros, reservas después de la noche. |
| `operativos` | Entero, personas disponibles al cierre. |
| `cultivo`, `paciente` | Strings, estados visibles en la bitácora. |
| `energia_comprometida` | Entero, previsión de cuidados que el Sol 2 podrá aplicar. La batería del relevo ya refleja la noche y conserva esta previsión por separado. |
| `ciencia_enviada` | Booleano, informe en tránsito. |
| `acciones` | Array[String], identificadores de tareas hechas en orden. |

### Espacio de trabajo para los siguientes soles

| Sol | Posible pregunta de diseño |
| --- | --- |
| 2 | ¿Cómo recuperar cultivos y atender la lesión con el presupuesto heredado? |
| 3 | ¿Cuándo compensa salir por hielo para reponer agua? |
| 4 | ¿Qué actividad se puede detener si hay una alerta de radiación? |
| 5 | ¿Qué parte de la misión científica pudo sostener la tripulación? |

Estas preguntas son propuestas. El equipo puede repartir un sol por rama y acordar entradas y salidas en cada PR. Las expediciones, electrólisis, construcción con regolito, escenario lunar, cronómetro, guardado y desenlaces quedan como candidatos de desarrollo.

## Ciencia y reto

- El polvo puede reducir la generación solar. NASA documenta que InSight redujo su actividad científica para conservar batería durante una tormenta. Ese mecanismo inspira el presupuesto del juego. [NASA, Mars Report: Dust Storms on Mars](https://science.nasa.gov/resource/mars-report-dust-storms-on-mars/)
- Una tormenta de polvo y un evento de radiación solar son fenómenos distintos. Si se añade radiación, darle su propia alerta, decisiones y consecuencias. [NASA, energía y calor en Marte](https://science.nasa.gov/wp-content/uploads/2024/02/mars-power-heating.pdf)
- El hielo de agua marciano sirve como punto de partida para una futura misión de extracción. El equipo deberá documentar el costo de extraerlo, purificarlo y procesarlo antes de convertirlo en una mecánica. [NASA, Mars Facts](https://science.nasa.gov/mars/facts/)
- La comunicación del prototipo es asíncrona. La bitácora distingue los informes enviados de los que quedaron en la base. [NASA, comunicaciones con Marte](https://science.nasa.gov/resource/mars-in-a-minute-what-happens-when-the-sun-blocks-our-signal/)
- La página indicada por el equipo devolvió HTTP 502 al consultarla. Confirmar el nombre, la numeración y los criterios de entrega cuando vuelva a estar accesible. [NASA Space Apps, Junior Astronaut Mission Trainer](https://www.spaceappschallenge.org/2026/challenges/junior-astronaut-mission-trainer/)
