# Día 2 · Tormenta de polvo

## Recorrido

En este checkout también puedes abrir `jugar_dia_2.bat` (usa el Godot local de `build/tools`). Para otro equipo, abre `scenes/dias/dia_2/dia_2.tscn` en Godot 4.7.2 y pulsa **F6**. Usa **WASD** o las **flechas** para caminar, **E** para interactuar, **F** para la opción alternativa, **M** para el plano y **Esc** para pausar. Los botones ejecutan las mismas acciones. El plano y las pausas detienen el reloj local.

1. En Control elige entre proteger los equipos o quedarte dentro. Los botones muestran el coste y la consecuencia antes de elegir. Resguardarse cuesta 0 inmediatamente; deja sistemas dañados y pérdidas de 1 agua y 1 oxígeno para el Día 3.
2. La guía lleva primero a los **tanques verdes de Agua y Oxígeno**, usando el laboratorio nuevo de `main`. Abre el tablero con E. Lee la instrucción con el reloj detenido y pulsa «Entendido, empezar».
3. **Conecta el aire**: gira cuatro codos hasta unir la entrada con el tanque. La luz azul muestra el tramo conectado. Clic o teclas **1–4** giran cada pieza; también puedes elegir con A/D y girar con Enter o Espacio. E prueba el circuito y, si está completo, activa el aire por **6 energía + 1 agua**, una sola vez. Un intento incorrecto no cobra. El oxígeno se llena y queda estable hasta dormir.
4. Si elegiste reparar, sal por la esclusa y sigue la marca hasta los paneles. **Asegura tres cierres**: panel izquierdo, panel derecho y toma del laboratorio. A/D o botones desplazan la pieza azul hasta la marca dorada. Pulsa E o «Fijar» durante **CALMA**; durante **RÁFAGA**, espera. Los errores conservan los cierres anteriores y no añaden costes. Completar los tres cobra **4 energía + 1 alimento** una sola vez. No reactiva la generación solar durante la tormenta.
5. Vuelve al refugio y termina en el Dormitorio. Si falta comida, F lleva a Plantas. Siembra lechuga (1 energía + 1 agua), observa la cuenta de 15 segundos y pulsa F para comer cuando esté lista. Puedes recuperarte del hambre antes de dormir.

En los tableros, **Esc pausa y conserva las piezas**; E o Esc continúa. **F cancela sin cobrar** y permite reiniciar el reto al abrirlo de nuevo. El reloj compartido corre durante el trabajo activo; se detiene al leer la explicación o pausar. Nora no se mueve mientras opera un tablero. Las reservas se validan de nuevo al confirmar, pues la comida puede bajar mientras se trabaja.

Se conserva la libertad del contrato: puedes preparar aire antes de decidir, o posponerlo desde los tanques y hacerlo después de reparar. Antes de completar la reparación puedes volver por la esclusa y resguardarte. Si falta agua y traes hielo, F en los tanques guía al **filtro azul**; F junto al filtro purifica con la API común (2 energía por hasta 3 agua). Dormir sin aire o sin comida, o agotar el oxígeno, devuelve derrota con un consejo para el siguiente intento.

## Criterios de diseño para 7–12 años

- Una instrucción inmediata por actividad, frases cortas y ejemplos visuales. Los términos técnicos se reservan para la documentación.
- Ruta visible **Plan → Aire → Equipos → Descanso**, acciones cerca del equipo y mensajes de éxito sin bloquear el recorrido.
- Los retos combinan orientación espacial y coordinación sencilla. Hay pistas por texto, posición y color; el éxito no depende de reconocer solo un color ni de oír el audio.
- La primera explicación de cada tablero no consume reservas. La guía recomienda asegurar aire antes de salir para evitar añadir presión de oxígeno a la reparación. No se alteran los intervalos del modelo común.
- Los tableros son esquemas de operación del juego, no una representación científica de tuberías reales o del viento de Marte. La ventana de calma dura 2,8 s de un ciclo de 4 s como simplificación jugable.

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

La escena reutiliza `PuestoUmbra` para el refugio, las colisiones, los sprites y el polvo marciano. En campaña, el aviso del Sol 2 señala la computadora de Control para elegir el plan. La tablet de campaña muestra las reservas y el estado de la generación solar.

Los retos originales conservan el recorrido del aire y los tres cierres durante la calma. El atlas [piezas_mantenimiento.png](../../assets/dias/dia_2/piezas_mantenimiento.png), generado con ImageGen, aporta las piezas del tablero. Se reutiliza `instrumentos_control.png` en las lecturas del circuito. Prompt del atlas. «True transparent alpha, square canvas, four separate items with empty gutters. Orthographic upper-right pipe elbow, horizontal straight pipe, blue steel mechanical rail clamp and empty copper equipment rail. Hand-placed 16-bit pixel clusters, readable at 80 game pixels, no words, no UI or background.»

Pluto ofrece diálogos contextuales reactivos mediante `dialogo_escena.gd`, advirtiendo al jugador si reparar dejaría la batería por debajo de las 6 unidades necesarias para el aire. En el exterior, se dibuja una baliza sobre los paneles (`EXPUESTOS` / `ASEGURADOS`) y el panel de interacción se ancla dinámicamente en el suelo sin tapar a Nora, Iris ni la esclusa.

El nivel incorpora audio procedural en `dia_2_audio.gd` mediante síntesis de ondas PCM en memoria (WAV): ráfagas de viento marciano moduladas por la intensidad de la tormenta, despresurización de la esclusa, sonido mecánico de pestillos térmicos al reparar, acorde de soporte vital al activar oxígeno y tonos táctiles de interfaz, sin dependencias de archivos de sonido externos.

Pancam estimó la opacidad atmosférica de Marte con imágenes del Sol. El polvo en suspensión reduce la luz que alcanza los paneles. La generación en cero, las ráfagas, el coste y la duración son reglas de juego acordadas. [NASA PDS, opacidad atmosférica MER Pancam](https://pds.nasa.gov/ds-view/pds/viewProfile.jsp?dsid=MER1%2FMER2-M-PANCAM-5-ATMOS-OPACITY-V1.0)

## Verificación

- Ejecutar la escena con F6 desde `scenes/dias/dia_2/dia_2.tscn`.
- `Godot --headless --path . --script res://scenes/dias/dia_2/dia_2_smoke.gd --quit-after 4000`. Resultado esperado `DIA_2_OK`. Recorre las colisiones e introduce clics y teclas por el Viewport: ambas decisiones, circuito, cierres, fallo por desalineación y ráfaga, cancelación, pausa conservando piezas, coste exacto, aire antes/después de reparar, hielo en el filtro, recuperación del hambre, relevo al Día 3 y derrota. El test captura errores de script, incluidos los del dibujo.
- `Godot --path . --script res://scenes/dias/dia_2/dia_2_smoke.gd --quit-after 4000`. Ejecuta la prueba en ventana gráfica a 1280 × 720, captura las transiciones en `build/qa/` y confirma que no existen errores ni advertencias de script al renderizar.
- `Godot --headless --path . --script res://tests/recursos_smoke.gd --quit-after 140`. Resultado esperado `RECURSOS_OK`.
- `Godot --headless --path . --script res://tests/narrativa_smoke.gd --quit-after 500`. Resultado esperado `NARRATIVA_OK`.
- `git diff --check`. Verifica que no existan conflictos ni espacios espurios.

## Archivos y límites de integración

- `dia_2.gd`: recorrido, conexión al modelo y resultado. Usa las estaciones y el arte compartidos de `main` sin modificar sus scripts.
- `retos_dia_2.gd`: reglas del circuito y cierres, sin recursos ni entrada gráfica.
- `taller_dia_2.gd`: tableros, dibujo, controles y pausa de actividad.
- `dia_2_hud.gd`: instrucciones, ruta, avisos y resumen; se corrige texto mal codificado de la entrega anterior.
- `dia_2_audio.gd`: efectos existentes reutilizados.
- `dia_2_smoke.gd`: pruebas de flujo e interacciones reales del Viewport y capturas gráficas en `build/qa/`.

Esta entrega sigue siendo una escena independiente para F6. No conecta por su cuenta los otros días, la noche ni el guardado de campaña. Los tableros no tienen progreso persistente: cerrar o reabrir un reto sin completarlo reinicia sus piezas sin cargo; las decisiones ya pagadas se recuperan mediante los IDs comunes. La conexión de campaña sigue siendo responsabilidad del coordinador.

### Comprobación de esta entrega

Se ejecutaron las pruebas de Día 2 en modo headless y gráfico, `RECURSOS_OK` y `NARRATIVA_OK`, y se revisaron las capturas de inicio, Control, laboratorio, circuito conectado, ráfaga, cierres, regreso, cosecha y final. La prueba gráfica usa 1280 × 720 y registra `DIA_2_OK` sin errores de script. También se abrió la escena real con su proceso normal y se verificaron clic de inicio, tecla E y pausa con Esc.

La comprobación nativa detectó que la inyección de teclado de Windows podía enviar un símbolo lógico correcto con un scancode diferente. Los atajos ahora usan el símbolo lógico (con respaldo físico), y WASD acepta ambos. La prueba incluye ese caso para evitar que los eventos sintéticos oculten el problema.
