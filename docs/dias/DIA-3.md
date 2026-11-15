# Día 3 | Oxígeno o invernadero

## Alcance

Esta entrega implementa únicamente el tercer día. Reutiliza el mapa interior, el arte 2D pixel art y el modelo común de recursos. No modifica la escena principal, el guardado general, Firebase ni los finales. La escena se puede abrir directamente con F6 desde `scenes/dias/dia_3/dia_3.tscn`.

## Entrada

La campaña debe entregar la misma instancia de `scripts/mecanicas/recursos_mision.gd` usada por los otros días, ya abierta en el sol 3, más el indicador `sistemas_danados` heredado del día 2. Si ese indicador es verdadero, al despertar se aplican una sola vez agua -1 y oxígeno -1 mediante el ID estable `consecuencia_tormenta_dia_2`.

Para F6 la escena crea una partida local de prueba en el sol 3, con polvo medio, una bandeja de rábano lista y reservas suficientes para recorrer ambas decisiones. Este estado no sustituye los días anteriores.

## Flujo jugable

1. Nora despierta en el dormitorio. Los indicadores pixel art conservan sus valores y se aplican las consecuencias pendientes del día 2.
2. Pluto dice: «La tormenta terminó. Vamos a revisar cómo quedaron los sistemas de Umbra. Empecemos por el invernadero y, si las reservas lo permiten, plantemos algo».
3. El jugador camina hasta Plantas. Puede comer una cosecha lista, sembrar uno de los cuatro cultivos existentes o continuar si faltan recursos. Se usan exactamente los costos, límites y tiempos del contrato común.
4. Pluto guía al jugador hacia la estación de oxígeno dentro del laboratorio conjunto de Agua y Oxígeno.
5. Al interactuar, el regulador falla antes de cobrar una activación normal. Se presentan costo y consecuencia de ambas opciones.
6. Priorizar oxígeno usa `activar_oxigeno()`. Con sistemas protegidos cuesta 6 de energía, 1 de agua y 2 de alimento; con sistemas dañados cuesta 7, 2 y 2. El oxígeno queda lleno y estable.
7. Priorizar invernadero usa `usar_tanques_emergencia()`. Con sistemas protegidos cuesta 3 de energía; con sistemas dañados, 4. El método común aplica además agua -1, oxígeno -2 y alimento +2, y asegura el aire de esa noche.
8. El jugador puede volver a Plantas para comer una cosecha lista si el alimento quedó en cero. Después camina al dormitorio.
9. En F6, dormir cierra el sol y comprueba que las reservas persistan. En campaña, la escena emite `descanso_solicitado`; el controlador conserva la responsabilidad de cerrar el día.

## Salida

La escena devuelve un diccionario con el día, la decisión `oxigeno` o `invernadero`, el estado heredado de los sistemas, si se revisó el invernadero y una copia del estado de recursos. No selecciona el final ni abre el día 4.

## Arte reutilizado

Se instancia `PuestoUmbra`, que conserva `plantas_horizonte.png`, `energia_interior.png`, `dormitorio_umbra.png`, `control_pasillos.png`, `dron.png` y los sprites existentes de la tripulación. Energía, oxígeno, agua y alimento se representan con `indicadores_refugio.gd`, alimentado por el mismo estado que aplica las decisiones; la gota anima los cambios de agua. Las conversaciones usan `dialogo_escena.gd`, con el nombre de Pluto y la frase cerca de su posición, mientras que la acción aparece junto al jugador. No se generaron imágenes ni formas provisionales para reemplazar el escenario final.

## Pruebas

- Abrir `scenes/dias/dia_3/dia_3.tscn` y pulsar F6. Recorrer Plantas, la estación de oxígeno del laboratorio y el dormitorio.
- Probar una siembra con costo disponible y otra acción sin recursos suficientes.
- Probar entrada con sistemas protegidos y dañados.
- Ejecutar `tests/dia_3_smoke.gd`; el resultado esperado termina con `DIA3_OK` y comprueba las reservas y el estado de los cultivos después de cada decisión.

En campaña, Control muestra la revisión pendiente y **T** abre la tablet. El reloj de cada bandeja avanza durante el menú de Plantas. Si priorizas el oxígeno se pierden los cultivos que estaban en las bandejas y se guarda la decisión.
- Ejecutar también `tests/recursos_smoke.gd`; el resultado esperado termina con `RECURSOS_OK`.

No se incorporan fuentes científicas nuevas en esta entrega. Se reutilizan las explicaciones y fuentes del contrato de mecánicas comunes.
