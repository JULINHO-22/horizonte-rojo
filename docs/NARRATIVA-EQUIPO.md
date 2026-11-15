# Narrativa del equipo: inicio, noches y final

Fuente leída el 14 de noviembre de 2026: [textos y narrativa](https://docs.google.com/document/d/1cFQ3KtIn4GHJJl9zSPl1GzB6LqcOVEkylplL1z2zlDc/edit?tab=t.0).

**Alcance confirmado por el usuario:** trabajar el inicio, el final y las noches. Las actividades de los días todavía NO están definidas. La lista del documento es una propuesta; no autoriza implementar las misiones. Esta guía tiene prioridad sobre las tablas antiguas de actividades de este repositorio.

## Transcripción del documento recibido

### ESCENA 1: 7s

Observa: Desde la tierra vista en 3ra persona, se observa salir una nave espacial que pasa por orbitas bajas y para llegar a una orbita alta hace un impulso extra. Hasta que llega al planeta de Marte (7-9 meses)

Texto 1: Saludos, astronautas.

Texto 1: Su misión es ir a Marte para recolectar rocas y minerales.

Texto 1: Al analizarlas en la Tierra, entenderemos más sobre el pasado de Marte.

Texto 1: ¡Buen viaje! .

### ESCENA 2: 10s

Observa: Instalacion de la nave espacial en tierra marciana y los astronautas se acercan al rover Percy. Este les da informacion escencial y los dirige a la base para instalarse. Percy se queda afuera.

EXPLICACION CON PERCY: 11s

Texto (Percy): ¡Bienvenidos a Marte!

Texto (Percy): Me llamo Rover Percervance, ¡llámenme Percy!

Texto (Percy): Trabajaremos juntos para recolectar los minerales que he extraído de cráteres

Texto (Percy): Al mismo tiempo deben realizar su misiones diarias en su base

Texto (Percy): ¡Mucha suerte!

Observa: Los astronautas entran a la nave e inicia el juego con un fade.

### JUEGO: 5min

Dia 1: Misiones basicas

Dia 2: Misiones basicas+sale a ver percy que los guia a recoger minerales y hielo

Dia 3: Misiones basicas+Tormenta

Dia 4: Misiones basicas+sale a ver percy que los guia a recoger minerales y hielo

Dia 5: Misiones basicas+preparar salida dejando a percy a recolecetar mas cosas para el futuro

### ESCENA 3 DORMIR: 3s

Observa: La pantalla se hace cada vez mas oscura. Al terminar los 3 segundos, se llega al siguiente dia

Observa: Tras la última dormida en el dia 5, aparecera en la base, y con una guia se lleva a la astronauta a la zona de piloto para iniciar con un boton el vuelo de regreso.

Observa: Animacion de salida de la base desde la tierra de marte hasta el cielo.

Observa: Animacion de la nave viajando desde marte hasta la tierra con la misma animacion de ida. Fade final de 1s al llegar a la tierra

### ESCENA FINAL: 10s

Observa: Escenario en un laboratorio. los astronautas mientras son revisados sus signos vitales unos cientificos les agradecen por su colaboracion.

Texto (Cientificos): ¡Excelente misión astronautas! Al analizar estos minerales entenderemos mejor a Marte.

Observa: Cientificos (3) moviendo la boca

Texto: Astronautas, sus aportes impulsan la vida e innovación hacia un futuro brillante. ¡Sigan esforzándose!

Fin

SPEECH

## Validación y adaptación actual

| Punto | Decisión aplicada / pendiente |
| --- | --- |
| Objetivo de muestras | Presentado en la bienvenida. No se afirma que el jugador recogió muestras que aún no existen como actividad. |
| Base frente a nave | La bienvenida lleva al refugio, no de nuevo a la nave. La nave se usa para el regreso. |
| Percy y Pluto | Personajes separados: Percy es guía exterior; Pluto explica las salas y acompaña el descanso. |
| Nombre del rover | «Perseverance» es el nombre real. Percy representa al Perseverance real en la ficción. Usa un sprite generado detallado; el SVG provisional ya no se utiliza. Pluto es otro robot, ficticio. |
| Viaje espacial | Montaje de ida y vuelta con seis capas 2D pixel art de `assets/NarrativaInicio/`: Tierra, espacio profundo, Marte, estela, etapa de transferencia y módulo. La nave sale acoplada y el módulo se desprende al llegar; `puesto.gd` muestra la variante aterrizada del mismo diseño. Usa fundidos, paralaje, zoom y trayectorias separadas sin dibujar planetas o estrellas mediante primitivas. Ver [Arte del viaje](ARTE-VIAJE.md). La ida dura 5,4 s en pantalla y el regreso 9 s. Ambos representan meses. La mecánica orbital sigue siendo ilustrativa, no una simulación. |
| Aterrizaje | Reutiliza la animación de descenso existente, comprimida a 2,6 s. Esc o el botón permiten ir directo al tramo jugable. |
| Diálogo de Percy | Percy dice una frase mientras la tripulación ya puede caminar. La indicación señala el refugio. |
| Noches | Oscurecimiento progresivo de 3 s, entrada bloqueada, avance automático y despertar en el dormitorio. La quinta noche conserva «día 5» y abre el regreso; no existe día 6. |
| Trayectoria interior | Entrada → Control; oeste → Energía → Centro de agua; este → Taller; desvío norte → Plantas/Dormitorio. Colisiones verificadas por tramos. |
| Regreso | Control orienta hacia la salida; recorrido hasta la nave; puesto de pilotaje permite iniciar el despegue; trayectoria de vuelta y fundido de 1 s. |
| Final terrestre | Epílogo de 10 s con la tripulación y agradecimiento; fondo de laboratorio reutilizado. Quedan pendientes el arte propio del laboratorio, los tres científicos animados y la revisión de signos vitales. No presentar este epílogo provisional como la escena final terminada. |
| Actividades | El [tutorial del Sol 1](dias/DIA-1.md) recorre Control, Oxígeno, Plantas y la expedición por hielo. Los demás soles conservan las estaciones comunes y el simulador anterior permanece en una escena separada. |

## Finales alternativos

Las escenas independientes de misión incompleta y misión cumplida ya se pueden revisar con F6. Las condiciones de campaña y el final trágico se decidirán con las actividades. Consulta [Finales en la Tierra](FINALES.md).

## Ciencia y ficción

Los cinco días son la estancia de la historia, no el viaje total. Los viajes reales dependen de la trayectoria y de las oportunidades de salida; no asumir que la misma nave puede volver de inmediato tras cinco días. El montaje comprime los tiempos y no pretende validar ese plan de vuelo. [NASA: duración típica del traslado, 6–9 meses](https://blogs.nasa.gov/redplanetdispatch/).

Perseverance recoge y guarda muestras de roca en tubos sellados. No es un camión tripulado ni una máquina que suministra agua potable o hielo a una base humana. Las capacidades de guía de Percy son ficción; no atribuirlas al rover real. [NASA: toma y almacenamiento de muestras](https://www.nasa.gov/solar-system/with-first-martian-samples-packed-perseverance-initiates-remarkable-sample-return-mission/).

La apertura y el final todavía no demuestran por sí solos el reto NASA: el equipo deberá definir después decisiones con costes y consecuencias sobre aire, energía, protección y alimentos. No incorporar actividades para completar ese requisito sin acordarlas primero.

## Revisión pendiente con el equipo

- Definir las actividades y consecuencias de cada día sin confundir propuestas con decisiones aprobadas.
- Decidir cuánto detalle visual llevarán lanzamiento, órbitas, pilotaje y laboratorio final.
- Mantener las muestras encerradas y separadas de las personas en el laboratorio final; no mostrar manipulación abierta junto a la revisión médica.
- Acordar la duración de diálogos probándolos con lectores de 7–12 años; no sacrificar comprensión por cumplir segundos exactos.
