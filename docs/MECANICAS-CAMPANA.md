# Mecánicas de campaña: decisiones y finales

## Objetivo

La campaña muestra los últimos cinco días de una misión que ya llevaba varios soles en Marte. Cada día presenta una decisión que modifica recursos o deja una consecuencia para el día siguiente. Todos los caminos llegan a la tormenta de radiación del día 5.

No se añade una barra de integridad. El juego usa cuatro recursos visibles y recuerda decisiones mediante estados como `sistemas_danados`, `paneles_limpios` y `refugio_reforzado`.

## Recursos

| Recurso | Máximo | Uso | Al llegar a 0 |
| --- | ---: | --- | --- |
| Energía | 12 rayos | Laboratorio, cultivos, reparaciones y expediciones | Se apagan los sistemas; no es derrota inmediata |
| Oxígeno | 8 burbujas | Mantener con vida a la tripulación | Final malo |
| Agua | 6 niveles | Producir oxígeno y cultivar alimentos | Bloquea esas actividades; no es derrota inmediata |
| Alimento | 10 tomates | Mantener activa a la tripulación | Final malo |

Estado inicial recomendado: energía 9, oxígeno 6, agua 1 y alimento 7.

Las cantidades nunca bajan de 0 ni superan su máximo. Antes de confirmar una decisión, la interfaz debe mostrar su coste y su consecuencia. Si no se puede pagar un coste obligatorio, la opción se desactiva y explica qué recurso falta.

## Generación y estados bajos

| Condición | Efecto |
| --- | --- |
| Paneles limpios | Recuperan +3 de energía al comenzar el día siguiente |
| Paneles cubiertos | Recuperan solo +1 de energía al comenzar el día siguiente |
| Tormenta de radiación | Generación de energía 0 |
| Energía entre 1 y 5 | No permite activar operaciones que cuestan 6 o más |
| Alimento entre 3 y 4 | La tripulación se mueve más lento; la expedición siguiente cuesta +1 de energía |
| Alimento entre 1 y 2 | Solo se puede transportar una carga pequeña de hielo |
| Oxígeno entre 1 y 3 | Estado crítico y avisos constantes en Control |

## Prólogo

Después del aterrizaje aparece el texto **«Varios soles después…»**. Percy informa que la reserva de agua está bajando y localiza hielo. El juego comienza cuando la rutina de la misión ya está establecida.

## Día 1: primera expedición por agua

Misión especial: salir con Percy, llegar al punto de extracción, recoger hielo y purificarlo. El Monte Olimpo puede aparecer como referencia visual en el fondo sin afirmar que el hielo proviene directamente del volcán.

| Decisión | Coste | Beneficio | Consecuencia |
| --- | --- | --- | --- |
| Depósito cercano | Energía -3 | Agua +3 | Expedición segura, pero reserva limitada |
| Depósito profundo | Energía -5 y alimento -1 | Agua +5 y muestra científica | Más agua para oxígeno y cultivos, pero se llega cansado al día 2 |

La energía gastada incluye desplazamiento, extracción y purificación.

## Día 2: tormenta de polvo

La tormenta cubre los paneles y fuerza polvo hacia los sistemas exteriores. Cuando el viento disminuye brevemente, se decide si realizar una reparación exterior.

| Decisión | Efecto inmediato | Estado guardado | Consecuencia del día 3 |
| --- | --- | --- | --- |
| Salir a reparar | Energía -4 y alimento -1 | `paneles_limpios = true`, `sistemas_danados = false` | No se pierde agua ni oxígeno; generación +3 |
| Permanecer dentro | Sin coste inmediato | `paneles_limpios = false`, `sistemas_danados = true` | Agua -1, oxígeno -1 y generación +1 |

Salir protege el futuro, pero deja reservas bajas. Permanecer dentro conserva recursos, pero hace más cara la emergencia del día siguiente.

## Día 3: emergencia de agua y oxígeno

La tormenta provoca un fallo en el distribuidor eléctrico aunque se hayan protegido los equipos. Solo se puede alimentar el sistema de oxígeno o el invernadero.

| Decisión | Sistemas protegidos | Sistemas dañados | Resultado |
| --- | --- | --- | --- |
| Priorizar oxígeno | Energía -6, agua -1, oxígeno = 8 | Energía -7, agua -2, oxígeno = 8 | El invernadero pierde la cosecha: alimento -2 |
| Priorizar invernadero | Energía -3, agua -1, alimento +2, oxígeno -2 | Energía -4, agua -1, alimento +2, oxígeno -2 | Se conserva la fuerza del equipo, pero el aire queda bajo |

Estados guardados: `oxigeno_priorizado` o `invernadero_priorizado`. Ninguna opción mata inmediatamente si los recursos estaban por encima de 0.

## Día 4: aviso de tormenta solar

Control informa que una tormenta de radiación llegará al día siguiente. El equipo debe decidir entre buscar agua para el encierro o preparar el refugio.

| Decisión | Requisito/coste | Beneficio | Estado guardado |
| --- | --- | --- | --- |
| Segunda expedición por hielo | Energía -5 y alimento -1 | Agua +3 | `refugio_reforzado = false` |
| Reforzar el refugio | Energía -3 | Prepara sellos, cableado y protección | `refugio_reforzado = true` |
| Hacer ambas tareas | Requiere energía >= 8 y alimento >= 5; energía -7 y alimento -1 | Agua +3 y refugio preparado | `refugio_reforzado = true` |

Si el alimento es 4 o menos, la expedición cuesta un punto adicional de energía. Con alimento 1 o 2 solo se obtiene agua +2. La opción de hacer ambas tareas recompensa la buena administración de los días anteriores.

## Día 5: tormenta de radiación

La generación solar baja a 0. La tripulación entra al refugio y el resultado se calcula con los recursos actuales y el estado `refugio_reforzado`.

Cada condición segura aporta un punto:

| Condición | Punto |
| --- | ---: |
| Energía >= 4 | +1 |
| Oxígeno >= 4 | +1 |
| Agua >= 2 | +1 |
| Alimento >= 3 | +1 |

`puntos_recursos` puede valer entre 0 y 4. Oxígeno 0 o alimento 0 producen el final malo sin importar el puntaje.

## Cálculo de finales

| Refugio reforzado | Puntos de recursos | Final |
| --- | ---: | --- |
| Sí | 3 o 4 | Misión completada |
| Sí | 1 o 2 | Regreso de emergencia |
| No | 3 o 4 | Regreso de emergencia |
| No | 0, 1 o 2 | Final malo |

### Misión completada

El refugio resiste, los sistemas esenciales continúan activos y la tripulación completa la misión. Después de la tormenta restablecen comunicaciones y regresan a la Tierra según el plan.

### Regreso de emergencia

La tripulación sobrevive, pero la base queda inhabitable o las reservas no permiten continuar. Control ordena despegar inmediatamente. Regresan a la Tierra con vida, pero la misión científica se considera abortada.

### Final malo

El refugio no fue preparado y los recursos críticos no alcanzan, o el oxígeno/alimento llega a 0. Las luces se apagan, se pierde la transmisión y aparece una pantalla negra con el mensaje: **«La estación Umbra dejó de transmitir»**. No se muestra una muerte gráfica.

## Flujos de ejemplo

| Ruta | Día 1 | Día 2 | Día 3 | Día 4 | Resultado probable |
| --- | --- | --- | --- | --- | --- |
| Administración buena | Depósito cercano | Reparar | Oxígeno o invernadero según reservas | Hielo + refuerzo | Misión completada |
| Supervivencia limitada | Depósito cercano | Permanecer dentro | Oxígeno | Reforzar | Regreso de emergencia |
| Base vulnerable | Depósito profundo | Permanecer dentro | Invernadero | Buscar hielo | Final malo |

Las rutas son ejemplos, no finales prefijados. El cálculo usa el estado real de los cuatro recursos y la preparación del refugio. Una sola decisión equivocada no debe provocar la derrota; el final refleja la acumulación de las decisiones.

## Resumen de misiones especiales

| Día | Misión jugable |
| ---: | --- |
| 1 | Expedición, extracción y purificación de hielo |
| 2 | Reparación exterior opcional durante la tregua de polvo |
| 3 | Operación del laboratorio o del invernadero |
| 4 | Segunda expedición, preparación del refugio o ambas |
| 5 | Secuencia narrativa dentro del refugio y cálculo del final |
