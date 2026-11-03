# Diseño de UMBRA

## Alcance del primer prototipo

Iris presenta a Tierra el objetivo de mantener un puesto con recursos locales. El viento levanta polvo y baja la generación solar. Iris ordena cerrar la esclusa. Teo, técnico de superficie, cae y queda atrapado junto al rover averiado. Nora, piloto y personaje jugable, se acerca al rover para evaluar el rescate. El robot advierte que el cabrestante comparte el circuito del invernadero. Nora elige usar el circuito ahora o cerrar la esclusa y volver por Teo tras una tregua. La extracción se representa con una secuencia corta y el jugador lleva a Teo hasta la esclusa.

La nave aterriza junto al refugio. Iris explica que el equipo quiere vivir cinco días en Marte y probar si su hielo puede darles agua. Nora explora el sendero lateral y encuentra a Teo junto a la primera muestra. El cielo se oscurece y los tres corren hacia la base. El viento puede hacer retroceder a Nora. Antes de la puerta, Teo tropieza, se desliza y queda con la bota atrapada bajo la camioneta. La misma muestra vuelve al primer plano el segundo día y el informe cierra la historia.

La interfaz usa «día», «puntos de batería» y «canal de radio». En el rescate se explica el costo concreto de cada decisión: apagar las luces de las plantas para usar la cuerda eléctrica o esperar a que baje el viento con Teo todavía afuera. Los costos internos siguen en el presupuesto del diseño.

La campaña tiene cinco objetivos obligatorios en orden: recuperar soporte vital, procesar hielo, informar a Tierra, activar el blindaje y transmitir el informe final. NIDO explica la meta en una banda central y marca el módulo en el mapa. La esclusa permite cerrar el sol después de completar esa meta. Las acciones opcionales reservan un turno y suficiente batería para el objetivo pendiente. Los procedimientos usan secuencias de mandos o una antena sintonizable. El gasto se aplica al completar la tarea.

El exterior y el mapa usan las referencias del equipo. El arte generado añade la tormenta, una enfermería de mayor detalle y sprites con iluminación neutra. Nora lleva violeta, Iris lleva cian y Teo lleva azul cobalto y blanco con acentos granate. Nora reacciona con alarma, Iris da órdenes con expresión firme y Teo pasa de dolor a reposo y reincorporación. Registrar la procedencia y los permisos de las referencias antes de distribuir públicamente el juego.

### Recorrido y zonas

La esclusa al sur desemboca en control, el centro de comunicaciones. Tres pasillos conectan control con energía al oeste, el invernadero al norte y enfermería al este. La cámara vuelve a una vista general en los pasillos y se acerca al entrar en cada sala. Los equipos bloquean el paso y los terminales se abren con **E** al acercarse. Las luces de los cultivos, la consola de radio, el monitor médico y la postura de Teo reflejan las decisiones. El registro de la esclusa cierra el día. Los límites y puntos de interacción están en `scripts/puesto.gd`.

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

### Campaña de cinco soles

| Sol | Decisiones y consecuencias |
| --- | --- |
| 2 | Usa la reserva de hielo para obtener agua o dedica turnos a estabilizar a Teo y recuperar el banco auxiliar. |
| 3 | Repite el procesamiento si hace falta agua. Comunica el experimento a Tierra y recibe la respuesta en el siguiente sol. |
| 4 | Durante la alerta solar, Nora pilota a NIDO desde Energía. Activa tres relés exteriores en orden y vuelve a la esclusa para conectar el blindaje. La cosecha vuelve a estar disponible. |
| 5 | Asegura la última noche y transmite el informe. Completar la misión exige soporte vital y al menos tres datos además de ese informe. |

El relevo añade agua, soporte vital, datos acumulados e informe del día. Los déficits de agua, comida o batería reducen el soporte vital. Dos sesiones médicas devuelven un turno a la tripulación a partir del siguiente sol. La misión completa exige recuperar a Teo, conservar al menos 80% de soporte vital y enviar el último informe con tres datos acumulados. La electrólisis, la construcción con regolito, el escenario lunar y el guardado quedan como candidatos de desarrollo.

### Clima y referencias de juego

- En superficie las rachas alternan con treguas. El frente de polvo, las partículas, el sonido y el indicador avisan de la intensidad. Los círculos señalan dónde baja el empuje y Shift permite anclarse. El retroceso fuerte está exagerado para el entrenamiento. En Marte, la atmósfera tenue limita la fuerza del viento y el polvo que bloquea la luz sí amenaza la generación solar. [NASA, Helio and You](https://science.nasa.gov/helio-and-you-seasons-on-earth-mars-and-beyond/)
- La alternancia entre exposición y refugio toma como referencia el papel del clima en [The Long Dark](https://store.steampowered.com/app/305620/The_Long_Dark/). El circuito de agua y las reservas compartidas se inspiran en las dependencias de tuberías, energía y soporte vital de [Oxygen Not Included](https://store.steampowered.com/app/457140/Oxygen_Not_Included/).

## Ciencia y reto

- El polvo puede reducir la generación solar. NASA documenta que InSight redujo su actividad científica para conservar batería durante una tormenta. Ese mecanismo inspira el presupuesto del juego. [NASA, Mars Report: Dust Storms on Mars](https://science.nasa.gov/resource/mars-report-dust-storms-on-mars/)
- Una tormenta de polvo y un evento de radiación solar son fenómenos distintos. Si se añade radiación, darle su propia alerta, decisiones y consecuencias. [NASA, energía y calor en Marte](https://science.nasa.gov/wp-content/uploads/2024/02/mars-power-heating.pdf)
- El hielo de agua marciano sirve como punto de partida para una futura misión de extracción. El equipo deberá documentar el costo de extraerlo, purificarlo y procesarlo antes de convertirlo en una mecánica. [NASA, Mars Facts](https://science.nasa.gov/mars/facts/)
- La comunicación del prototipo es asíncrona. La bitácora distingue los informes enviados de los que quedaron en la base. [NASA, comunicaciones con Marte](https://science.nasa.gov/resource/mars-in-a-minute-what-happens-when-the-sun-blocks-our-signal/)
- La página indicada por el equipo devolvió HTTP 502 al consultarla. Confirmar el nombre, la numeración y los criterios de entrega cuando vuelva a estar accesible. [NASA Space Apps, Junior Astronaut Mission Trainer](https://www.spaceappschallenge.org/2026/challenges/junior-astronaut-mission-trainer/)
