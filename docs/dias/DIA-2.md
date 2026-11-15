# Día 2 · Tormenta de polvo

## Recorrido

Abre `scenes/dias/dia_2/dia_2.tscn` en Godot 4.7.2 y pulsa **F6**. Usa **WASD** o las **flechas** para caminar, **E** para interactuar, **Q** para la opción alternativa, **M** para el plano y **Esc** para pausar. Los botones ejecutan las mismas acciones. El plano y las pausas detienen el reloj local.

1. Acércate al anillo frente a la supercomputadora de Control y elige entre ir a reparar o resguardarte. Resguardarse cuesta 0 inmediatamente. Al comenzar el Día 3 se pierden 1 de agua y 1 de oxígeno y queda el estado de sistemas dañados.
2. Si sales, cruza la esclusa y sigue la marca hasta los paneles. Las ráfagas empujan a Nora. Asegurar los paneles y la toma del laboratorio cuesta 4 de energía y 1 de alimento. Puedes volver por la esclusa y cambiar de decisión antes de confirmar la reparación. Los paneles quedan protegidos después de reparar y la generación sigue en cero durante la tormenta.
3. Activa el oxígeno en el Centro de agua por 6 de energía y 1 agua. Puedes ir desde Control por Energía antes de decidir, o seguir la marca al regresar o resguardarte. Si el tanque está vacío y queda hielo del Día 1, puedes purificarlo en el Centro de agua con la API común.
4. Termina en el Dormitorio. Puedes volver a Plantas si necesitas comer. Dormir sin aire asegurado o con alimento en cero devuelve derrota al controlador. Agotar el oxígeno durante el recorrido también termina el día.

## Balance y decisiones de adaptación

El modo local empieza con 12 de energía, 3 de agua, 8 de oxígeno y 10 de alimento para que ambas rutas se puedan jugar. Reparar y asegurar el aire requieren 10 de energía y 1 de agua, además del alimento de la salida. Resguardarse y asegurar el aire requieren 6 de energía y 1 de agua. Con el tanque de oxígeno lleno hay 64 segundos de juego activo para asegurar el aire. La tormenta cubre todo el Sol 2 en esta entrega porque el modelo aplica el polvo al abrir cada sol.

La [sección Día 2 del flujo del equipo](https://docs.google.com/document/d/1c4HhF6DT6FRXE5An-bsyz_JuIiPXzEtXyh5EHFvSg7I/edit) define la tormenta y el dilema. La salida con Percy de [Narrativa del equipo](../NARRATIVA-EQUIPO.md) y el reparto de agua de [Reto NASA](../RETO-NASA.md) son propuestas anteriores. El contrato de [Mecánicas básicas del repositorio](../MECANICAS-BASICAS.md) conserva la recuperación de hambre antes de dormir, mientras que [Mecánicas básicas del equipo](https://docs.google.com/document/d/1T_78hepP_Zc7xXMa4ro6A1NTh3oMSG_25LR-fu90aVE/edit) contempla derrota inmediata con alimento en cero. Esta escena conserva la regla del código.

## Entrada y relevo

El controlador abre el Sol 2 con `iniciar_sol("tormenta")`. Llama a `configurar(recursos)` antes de añadir la escena al árbol y conecta `finalizado(resultado)`. El controlador llama a `recursos.avanzar(delta)` mientras `juego_activo()` devuelva verdadero. La escena solo avanza el reloj cuando se abre por separado con su partida de prueba.

- `id` es `dia_2`. `completado` indica un cierre seguro y `derrota` contiene el motivo, cuando corresponda.
- `decision` puede ser `reparar` o `resguardarse`. El resultado indica `paneles_protegidos` y `sistemas_danados`. Los IDs de decisión en el modelo son `dia_2_reparar` y `dia_2_resguardarse`.
- `perdidas_dia_3` está vacío si se reparó. Si la tripulación se resguardó, incluye `id: "dia_3_danos_del_dia_2"` y `recursos: {"agua": 1, "oxigeno": 1}` para que el controlador llame a `aplicar_perdidas(id, recursos)` una vez al abrir el Sol 3. El estado de sistemas dañados se conserva aparte para los efectos posteriores que describe el flujo.
- `cambios_reservas` informa la diferencia desde la entrada. `estado_recursos` es la copia previa al cierre. El controlador es dueño de la instancia, de `dormir()`, del guardado y de la transición de la noche.

Queda pendiente acordar con el coordinador la conexión en `scripts/guion_inicio_final.gd` o su futuro controlador y los campos del guardado de campaña. Los IDs de decisión permiten reconocer un Sol 2 reabierto después de tomar una decisión. Si se necesita reanudar en la posición exacta, habrá que guardar el punto y el tramo de la escena en el guardado de campaña.

## Arte y ciencia

La base es `origin/main` en `4030c9d` (con los instrumentos pixel art generados y lecturas integradas). La escena reutiliza `PuestoUmbra` para el refugio, las colisiones, los sprites de la tripulación y el polvo marciano. En [Control](../ARTE-CONTROL.md), la supercomputadora muestra en vivo el componente `Indicadores` con los 12 rayos de energía, 8 burbujas de oxígeno y gota de agua con animación de llenado, destacando en rojo la alerta `Solar: Pausado`. La comida se refleja con los iconos de tomate arriba a la derecha.

Pluto ofrece diálogos contextuales reactivos mediante `dialogo_escena.gd`, advirtiendo al jugador si reparar dejaría la batería por debajo de las 6 unidades necesarias para el aire. En el exterior, se dibuja una baliza sobre los paneles (`EXPUESTOS` / `ASEGURADOS`) y el panel de interacción se ancla dinámicamente en el suelo sin tapar a Nora, Iris ni la esclusa.

El nivel incorpora audio procedural en `dia_2_audio.gd` mediante síntesis de ondas PCM en memoria (WAV): ráfagas de viento marciano moduladas por la intensidad de la tormenta, despresurización de la esclusa, sonido mecánico de pestillos térmicos al reparar, acorde de soporte vital al activar oxígeno y tonos táctiles de interfaz, sin dependencias de archivos de sonido externos.

Pancam estimó la opacidad atmosférica de Marte con imágenes del Sol. El polvo en suspensión reduce la luz que alcanza los paneles. La generación en cero, las ráfagas, el coste y la duración son reglas de juego acordadas. [NASA PDS, opacidad atmosférica MER Pancam](https://pds.nasa.gov/ds-view/pds/viewProfile.jsp?dsid=MER1%2FMER2-M-PANCAM-5-ATMOS-OPACITY-V1.0)

## Verificación

- Ejecutar la escena con F6 desde `scenes/dias/dia_2/dia_2.tscn`.
- `Godot --headless --path . --script res://scenes/dias/dia_2/dia_2_smoke.gd --quit-after 2000`. Resultado esperado `DIA_2_OK`. Recorre las colisiones, comprueba ambas decisiones, el coste exacto, el aire antes y después de decidir, el relevo al Día 3, la falta de reservas y la derrota.
- `Godot --path . --script res://scenes/dias/dia_2/dia_2_smoke.gd --quit-after 2000`. Ejecuta la prueba en ventana gráfica a 1280 × 720, captura las transiciones en `build/qa/` y confirma que no existen errores ni advertencias de script al renderizar.
- `Godot --headless --path . --script res://tests/recursos_smoke.gd --quit-after 140`. Resultado esperado `RECURSOS_OK`.
- `Godot --headless --path . --script res://tests/narrativa_smoke.gd --quit-after 500`. Resultado esperado `NARRATIVA_OK`.
- `git diff --check`. Verifica que no existan conflictos ni espacios espurios.
