# Construye un simulador de misión para astronautas junior

Enunciado en español compartido por el equipo el 12 de noviembre de 2026. Se normalizaron los saltos de línea del texto pegado.

[Build a Junior Astronaut Mission Trainer](https://www.spaceappschallenge.org/2026/challenges/junior-astronaut-mission-trainer/)

## Enunciado

El contenido STEM con temática espacial a menudo simplifica en exceso las disyuntivas de ingeniería que definen una misión real o las presenta a un nivel demasiado complejo para captar la atención de un estudiante joven. Pocas herramientas hacen que esas disyuntivas sean a la vez tangibles y divertidas. Tu reto es diseñar y crear un juego o aplicación interactiva que permita a los estudiantes gestionar un puesto avanzado lunar o marciano, equilibrando demandas contrapuestas como el soporte vital, el blindaje contra la radiación, la energía y la producción de alimentos, para que experimenten de primera mano las decisiones que determinan el éxito o el fracaso de una misión.

Mientras la NASA trabaja para establecer una presencia sostenida en la Luna y extender la exploración humana hacia Marte, uno de los desafíos más persistentes no es solo el diseño de hardware, sino también la comprensión pública de lo que realmente requiere la supervivencia en estos entornos. Los astronautas en un puesto avanzado lunar o marciano deben equilibrar demandas contrapuestas: la energía limitada debe dividirse entre el soporte vital, las comunicaciones y la investigación científica; la exposición a la radiación debe sopesarse con los objetivos de la misión; y cada decisión conlleva un costo de recursos que se acumula con el tiempo. Estos son los mismos dilemas que los planificadores de misiones de la NASA manejan a diario, basándose en datos reales: la actividad solar y el riesgo de radiación de la Base de Datos del Clima Espacial (DONKI), la dosimetría de radiación de los astronautas y la investigación biológica del Repositorio Abierto de Datos Científicos (OSDR), y los datos ambientales de las misiones Artemis y de superficie de Marte.

La dificultad radica en la traducción. El contenido educativo sobre el espacio para niños suele ser demasiado abstracto (por ejemplo, carteles y datos generales) para transmitir las implicaciones reales de las decisiones, o bien presupone un nivel técnico demasiado avanzado para que un público joven lo comprenda de forma significativa. Como resultado, muchos estudiantes nunca llegan a conocer la lógica real de la toma de decisiones que hay detrás de una misión, sino solo sus resultados. El contenido puramente educativo suele tener dificultades para captar la atención; el contenido puramente lúdico puede perder precisión.

Los participantes podrían priorizar el diseño de mecánicas —no solo visuales— que reflejen limitaciones reales: una decisión que ahorra energía hoy podría costar oxígeno mañana. Se recomienda basar la jugabilidad en datos abiertos reales de la NASA, en lugar de estadísticas inventadas. Entre los posibles enfoques se incluyen la gestión de recursos al estilo de la supervivencia, árboles de decisión narrativos o simuladores de control de misión tipo panel de control; sin embargo, se anima a los participantes a explorar el formato que mejor enseñe la disyuntiva subyacente, en lugar de ajustarse a una única plantilla.

Tu reto consiste en diseñar y crear un juego o aplicación interactiva que permita a niños de entre 7 y 12 años gestionar un puesto avanzado lunar o marciano, tomando decisiones reales sobre el soporte vital, el blindaje contra la radiación, el presupuesto energético, la producción de alimentos y los retrasos en las comunicaciones, y experimentando cómo esas decisiones se desarrollan a lo largo de una misión simulada.

Piensa en cómo tu herramienta puede convertir las limitaciones reales de una misión en un juego: ¿qué se siente al intercambiar reservas de oxígeno por una oportunidad de investigación adicional, o al reforzar el blindaje contra un evento de radiación a costa del suministro eléctrico de esta noche? ¿Cómo representarás los recursos en competencia para que ninguna opción sea gratuita y cada decisión revele algo real sobre lo que los astronautas y los planificadores de misiones realmente deben afrontar?

Se recomienda basar la simulación en datos abiertos reales de la NASA siempre que sea posible; por ejemplo, utilizando DONKI para reflejar la actividad solar y el riesgo de radiación reales, el OSDR para obtener datos reales sobre la salud de los astronautas y los hallazgos de investigaciones biológicas, o datos de las misiones Artemis y de la superficie de Marte para informar sobre las condiciones ambientales en el lugar elegido. Incorporar conjuntos de datos de la NASA, tanto en tiempo real como archivados, en lugar de cifras inventadas, hará que la experiencia sea más auténtica y brindará a los jugadores una visión genuina de cómo se toman las decisiones cruciales para la misión.

El formato es abierto: puedes crear un juego de supervivencia con gestión de recursos, un simulador de decisiones narrativo, una experiencia de panel de control tipo centro de operaciones o cualquier otra cosa, ya sea para navegador, móvil o ordenador. El objetivo es un prototipo funcional que demuestre la mecánica de compensación con la suficiente claridad como para que un jugador joven comprenda una limitación real de la supervivencia en el espacio profundo, y no solo haya jugado un juego divertido. Se aceptan interpretaciones creativas de "puesto avanzado", "sitio" o "misión" más allá de la Luna y Marte, siempre que el objetivo educativo subyacente —enseñar decisiones de ingeniería reales a través del juego— siga siendo fundamental.

Usted puede (pero no está obligado a) considerar lo siguiente:

### Audiencia y accesibilidad

- Tu público objetivo son niños de entre 7 y 12 años, pero considera si tu herramienta puede adaptarse para involucrar también a hermanos mayores, padres o en entornos escolares.
- Priorice el lenguaje sencillo sobre la jerga; cuando un término científico sea inevitable (dosis de radiación, microgravedad, sol), explíquelo brevemente en contexto en lugar de asumir conocimientos previos.
- Es importante que la entrada sea sencilla: una experiencia jugable desde el navegador, sin necesidad de descargas ni cuentas, llegará a más participantes durante la fase de evaluación y a más estudiantes posteriormente.

### Fundamentación en datos reales

- Siempre que sea posible, recurra a las API públicas de la NASA y a los conjuntos de datos abiertos en lugar de inventar cifras que suenen plausibles; incluso una pequeña cantidad de datos reales (una lectura real de radiación, una foto real de Marte, un hallazgo real sobre la salud de un astronauta) hace que la experiencia sea mucho más creíble que una completamente simulada.
- Indica claramente las fuentes de tus datos dentro de la propia herramienta, para que los jugadores entiendan que están interactuando con ciencia real de la NASA, y no solo con un juego temático.
- Si las llamadas a la API en tiempo real no son factibles durante el período de compilación, un conjunto de datos reales seleccionados e integrado directamente en su herramienta es una alternativa razonable y honesta; simplemente no presente datos estáticos como si fueran en tiempo real.

### Errores de diseño y jugabilidad que se deben evitar

- Evite diseñar una opción "segura" que no tenga ningún costo; el valor educativo proviene de cada decisión que implica una compensación real, reflejando la planificación de una misión real.
- No dejes que el pulido visual sustituya la precisión mecánica: un juego sencillo que enseña una limitación real es mejor que uno bonito que no lo hace.
- Evite abrumar a los jugadores jóvenes con demasiados sistemas simultáneos que controlar; dos o tres recursos básicos (soporte vital, energía, protección) suelen ser más eficaces que cinco o seis.

### ¿Qué haría que una solución destacara?

- Herramientas que permiten a los jugadores ver las consecuencias en el mundo real de sus decisiones dentro del juego, vinculando la decisión de protegerse contra la radiación con datos reales y actuales del clima espacial.
- La rejugabilidad —mecánicas o eventos que varían entre partidas— anima a los niños a probar diferentes estrategias y aprender de los fracasos sin que esto les resulte punitivo.
- Se incluye un prototipo funcional acompañado de una breve explicación de qué conjuntos de datos de la NASA se utilizaron y por qué, lo que permite a los jueces rastrear y verificar la ciencia.

*Para obtener datos y recursos relacionados con este desafío, consulte la pestaña Recursos en la parte superior de la página. Es posible que se añadan más recursos antes de que comience el hackathon.*

La [guía de datos](DATOS-NASA.md) compara las fuentes y documenta las consultas para la simulación.

## Propuesta para Horizonte Rojo

- Sol 1. Priorizar la energía del aire y la calefacción tras la tormenta y recuperar las plantas con la carga restante.
- Sol 2. Llevar el hielo a la Centro de agua, procesarlo y decidir cuánto agua guardar para la tripulación y cuánto enviar a las plantas.
- Sol 3. Ver el resultado del riego y elegir entre recuperar una bandeja o dedicar el turno a energía. Enviar un mensaje mientras se continúa trabajando. La respuesta llega después de una decisión.
- Sol 4. Usar una alerta solar con un registro archivado. Poner a la tripulación a cubierto y elegir entre ahorrar batería o mandar a Pluto a recoger datos. Registrar fecha, fuente, observación original y adaptación para el juego. El registro de actividad solar no mide por sí solo la dosis dentro del refugio.
- Sol 5. Resolver una escasez final con las reservas, la cosecha y el tiempo de tripulación que dejaron los soles anteriores.
- Mostrar como máximo tres indicadores persistentes. Presentar el agua, la comida, la exposición y el estado del mensaje en los lugares o escenas donde importan.
- Cerrar con una bitácora visual que explique tres consecuencias de esa partida. Permitir volver al punto de reparto de batería para comparar estrategias.
- Usar diálogos históricos breves y opcionales. Priorizar que el jugador pueda explicar con sus propias palabras qué ganó, qué gastó y qué probaría en otra partida.
