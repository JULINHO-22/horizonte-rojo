# Diseño de Horizonte Rojo

Horizonte Rojo es el nombre del juego. Umbra es el nombre del refugio. Los panoramas del refugio y del barranco mantienen la altura del sendero y la ubicación de los accesos. Las proporciones exteriores toman como referencia la abertura de la puerta.

## Alcance actual

El [guion y los personajes](HISTORIA.md) tienen su propia guía. La campaña tiene cinco objetivos obligatorios. Pluto guía al jugador y marca el módulo activo. El dormitorio permite terminar el día al cumplir la misión. Las acciones opcionales dejan margen de batería y turnos para la misión pendiente. El gasto se aplica al completar la tarea.

El arte combina las referencias del equipo e ilustraciones generadas para los panoramas, las salas y los personajes. El repositorio conserva los recursos del proyecto. El registro completo de autoría y permisos de las referencias está pendiente.

### Recorrido y zonas

La esclusa al sur desemboca en Control, el centro de comunicaciones. Tres pasillos conectan Control con Energía al oeste, la sala de plantas al norte y Enfermería al este. La cámara vuelve a una vista general en los pasillos y se acerca al entrar en cada sala. El acercamiento queda entre 1,85× y 2×, y Control usa una ilustración de alta resolución con los accesos visibles. Los equipos bloquean el paso y los terminales se abren con **E** al acercarse. Iris patrulla Control. En Enfermería, Teo ocupa el colchón a lo largo. El dormitorio queda al noreste y se alcanza por el corredor que sale del paso entre Control y Enfermería. Allí se cierra el día. Los límites y puntos de interacción están en `scripts/puesto.gd`.

## Presupuesto del Sol 1

Los valores son de diseño y están sujetos a pruebas. **UE** significa unidad abstracta de energía. El estado inicial tiene 16 UE, 9 raciones, 6 de agua y 100% de soporte. La noche cuesta 4 UE, 3 raciones y 2 de agua.

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

## Reservas entre días

Consulta el [contrato técnico](ARQUITECTURA.md#contrato-de-campaña) para los nombres y el significado de los campos. Los cuidados cuestan 4 UE si se esperó y Teo sigue sin atender, 1 UE en observación o reposo y 0 UE al recuperarse. Después de descontarlos, la batería recibe 9 UE más el número del nuevo día y 2 UE adicionales si se revisaron los paneles. El máximo al amanecer es 24 UE.

Después del primer día, si las plantas siguen activas o protegidas aportan 2 raciones antes del consumo nocturno. Cada unidad faltante de comida, agua o batería reduce el soporte vital en 12, 15 o 10 puntos, respectivamente.

### Campaña de cinco soles

| Sol | Decisiones y consecuencias |
| --- | --- |
| 2 | Procesa el hielo como objetivo obligatorio. El turno restante puede ir a Enfermería o al banco auxiliar. |
| 3 | Comunica el experimento a Tierra como objetivo obligatorio. Repite el procesamiento como tarea adicional si hace falta agua. |
| 4 | Durante la alerta solar, Nora pilota a Pluto desde Energía. Activa tres relés exteriores en orden y vuelve a la esclusa para conectar el blindaje. La cosecha vuelve a estar disponible. |
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

El salto de superficie usa una caída más lenta como adaptación jugable de la gravedad marciana. El refugio sellado suministra aire respirable. [JPL, Mars at a Glance](https://www.jpl.nasa.gov/news/press_kits/insight/landing/facts/mars-at-a-glance/)
