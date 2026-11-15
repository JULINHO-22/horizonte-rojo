# Diseño de Horizonte Rojo

Horizonte Rojo es el nombre del juego. Umbra es el nombre del refugio. Los panoramas del refugio y del barranco mantienen la altura del sendero y la ubicación de los accesos. Las proporciones exteriores toman como referencia la abertura de la puerta.

## Alcance vigente

El recorrido principal mantiene [inicio, noches y final](NARRATIVA-EQUIPO.md). El Día 3 tiene un flujo aprobado e independiente en [Día 3](dias/DIA-3.md): revisión del invernadero, fallo eléctrico y elección entre oxígeno e invernadero. Todavía no sustituye el descanso libre del recorrido principal. Los días 4 y 5 se revisan en su banco propio; las actividades y el balance del simulador anterior permanecen separados.

## Simulador anterior

El [guion y los personajes](HISTORIA.md) tienen su propia guía. La campaña tiene cinco objetivos obligatorios. Pluto guía al jugador y marca el módulo activo. El dormitorio permite terminar el día al cumplir la misión. Las acciones opcionales dejan margen de batería y turnos para la misión pendiente. Pluto guía primero a la tarea del día, luego ofrece dedicar el turno sobrante a otra sala y lleva al dormitorio para revisar el cierre. El gasto se aplica al completar la tarea.

El arte combina las referencias del equipo e ilustraciones generadas para los panoramas, las salas y los personajes. El repositorio conserva los recursos del proyecto. El registro completo de autoría y permisos de las referencias está pendiente.

### Recorrido y zonas

La esclusa al sur desemboca en Control. El corredor oeste lleva a Energía y su pasillo norte conecta con el Centro de agua. Desde Control, el corredor este sube hacia Plantas y el Dormitorio. El taller está inmediatamente al este de Control; ya no requiere seguir el desvío del dormitorio. El Centro de agua contiene la estación del Sol 2. Derretir el hielo, tratar el agua y comprobar su calidad son pasos distintos. La primera prueba del ejercicio detecta impurezas y retiene el lote. Al tratarlo de nuevo y superar la revisión, el tanque recibe agua y la campaña registra el resultado. Las cantidades, el reintento y el tiempo son decisiones de diseño. En la Estación Espacial Internacional, el soporte vital incluye aire y agua. El sistema real aplica controles de calidad antes de usar el agua recuperada. [NASA sobre soporte vital](https://www.nasa.gov/reference/environmental-control-and-life-support-systems-eclss/) · [Mapa de hielo SWIM](https://science.nasa.gov/resource/swim-map-shows-subsurface-water-ice-on-mars/).

## Presupuesto del Sol 1

Los valores son de diseño y están sujetos a pruebas. **UE** significa unidad abstracta de energía. El estado inicial tiene 16 UE, 9 raciones, 6 de agua y 100% de soporte. La noche cuesta 4 UE, 3 raciones y 2 de agua.

Con el regreso comienza el perfil de emergencia. La batería baja de 16 a 12 UE y se apagan las luces de cultivo. Perforar en suelo seco deja 11 UE. Los tres astronautas pueden trabajar y cada tarea usa un turno.

## Reservas entre días

Consulta el [contrato técnico](ARQUITECTURA.md#contrato-de-campaña). Al comenzar el día, la batería recibe 9 UE más el número del nuevo día y 2 UE si se revisaron los paneles. El máximo es 24 UE.

Después del primer día, si las plantas siguen activas o protegidas aportan 2 raciones antes del consumo nocturno. Cada unidad faltante de comida, agua o batería reduce el soporte vital en 12, 15 o 10 puntos, respectivamente.

### Campaña de cinco soles

| Sol | Decisiones y consecuencias |
| --- | --- |
| 2 | Procesa el hielo como objetivo obligatorio. El turno restante puede ir a las plantas o al banco auxiliar. |
| 3 | Comunica a Tierra el resultado del lote del Sol 2. Los turnos adicionales pueden dedicarse al banco auxiliar o al cultivo. |
| 4 | Durante la alerta solar, Nora pilota a Pluto desde Energía. Activa tres relés exteriores en orden y vuelve a la esclusa para conectar el blindaje. La cosecha vuelve a estar disponible. |
| 5 | Asegura la última noche y transmite el informe. Completar la misión exige soporte vital y al menos tres datos además de ese informe. |

El relevo añade agua, soporte vital, datos acumulados e informe del día. Los déficits de agua, comida o batería reducen el soporte vital. La misión completa exige conservar al menos 80% de soporte vital y enviar el último informe con tres datos acumulados. La electrólisis, la construcción con regolito, el escenario lunar y el guardado quedan como candidatos de desarrollo.

### Clima y referencias de juego

- En superficie las rachas alternan con treguas. El frente de polvo, las partículas, el sonido y el indicador avisan de la intensidad. Los círculos señalan dónde baja el empuje y Shift permite anclarse. El retroceso fuerte está exagerado para el entrenamiento. En Marte, la atmósfera tenue limita la fuerza del viento y el polvo que bloquea la luz sí amenaza la generación solar. [NASA, Helio and You](https://science.nasa.gov/helio-and-you-seasons-on-earth-mars-and-beyond/)
- La alternancia entre exposición y refugio toma como referencia el papel del clima en [The Long Dark](https://store.steampowered.com/app/305620/The_Long_Dark/). El circuito de agua y las reservas compartidas se inspiran en las dependencias de tuberías, energía y soporte vital de [Oxygen Not Included](https://store.steampowered.com/app/457140/Oxygen_Not_Included/).

## Qué representa cada módulo

Umbra es un refugio marciano ficticio. Su distribución separa las funciones para que el jugador pueda ubicarlas. Una tripulación real puede compartir salas y agrupar equipos. Mars Dune Alpha es un hábitat de simulación en la Tierra. La Estación Espacial Internacional (EEI) ofrece ejemplos de equipos operativos en órbita.

| Zona en Umbra | Referente |
| --- | --- |
| Control y Dormitorio | El análogo Mars Dune Alpha incluye puestos de trabajo, una estación médica y cuatro camarotes. Sus misiones simulan retrasos de comunicación. [NASA, hábitat CHAPEA](https://www.nasa.gov/reference/jsc-analogs-mockups/) · [NASA, misión CHAPEA 1](https://www.nasa.gov/humans-in-space/chapea/chapea-mission-1/) |
| Sala de plantas | CHAPEA incluye estaciones de cultivo y ensayos de producción. En el juego las plantas complementan las raciones. [NASA, misión CHAPEA 1](https://www.nasa.gov/humans-in-space/chapea/chapea-mission-1/) |
| Energía y soporte vital | La EEI utiliza sistemas que controlan el aire, la presión y la recuperación del agua. La dependencia del refugio respecto de los paneles representa un escenario de entrenamiento. [NASA, soporte vital](https://www.nasa.gov/reference/environmental-control-and-life-support-systems-eclss/) · [NASA, polvo y paneles en Marte](https://science.nasa.gov/solar-system/10-things-dust-in-the-wind-on-mars-and-well-beyond/) |
| Esclusa y taller | La esclusa Quest tiene un espacio para mantenimiento de trajes y otro para entrada y salida. El taller de Umbra separa esa función e incorpora un vehículo de reserva como decisión de diseño. [NASA, esclusa Quest](https://www.nasa.gov/international-space-station/quest-airlock/) · [NASA, vehículos de exploración](https://www.nasa.gov/reference/vehicle-systems-interfaces-structure-environmental-design/) |
| Centro de agua | Tratar y comprobar la calidad del agua son funciones reales de soporte vital. Extraer hielo marciano para abastecer un hábitat es una tecnología en estudio. [NASA, soporte vital](https://www.nasa.gov/reference/environmental-control-and-life-support-systems-eclss/) · [NASA, aprovechamiento de recursos locales](https://www.nasa.gov/overview-in-situ-resource-utilization/) |

## Ciencia y reto

- El polvo puede reducir la generación solar. NASA documenta que InSight redujo su actividad científica para conservar batería durante una tormenta. Ese mecanismo inspira el presupuesto del juego. [NASA, Mars Report: Dust Storms on Mars](https://science.nasa.gov/resource/mars-report-dust-storms-on-mars/)
- Una tormenta de polvo y un evento de radiación solar son fenómenos distintos. Si se añade radiación, darle su propia alerta, decisiones y consecuencias. [NASA, energía y calor en Marte](https://science.nasa.gov/wp-content/uploads/2024/02/mars-power-heating.pdf)
- La extracción de muestras de hielo y el tratamiento del agua del Sol 2 son actividades de entrenamiento. El juego simplifica el tiempo, el equipo y las comprobaciones de calidad. [NASA, Mars Facts](https://science.nasa.gov/mars/facts/)
- La comunicación del prototipo es asíncrona. La bitácora distingue los informes enviados de los que quedaron en la base. [NASA, comunicaciones con Marte](https://science.nasa.gov/resource/mars-in-a-minute-what-happens-when-the-sun-blocks-our-signal/)
- La página indicada por el equipo devolvió HTTP 502 al consultarla. Confirmar el nombre, la numeración y los criterios de entrega cuando vuelva a estar accesible. [NASA Space Apps, Junior Astronaut Mission Trainer](https://www.spaceappschallenge.org/2026/challenges/junior-astronaut-mission-trainer/)

El salto de superficie usa una caída más lenta como adaptación jugable de la gravedad marciana. El refugio sellado suministra aire respirable. [JPL, Mars at a Glance](https://www.jpl.nasa.gov/news/press_kits/insight/landing/facts/mars-at-a-glance/)
