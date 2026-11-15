# Arquitectura y verificación

## Recorrido narrativo principal

- `scenes/umbra.tscn` ejecuta `guion_inicio_final.gd`: entrada, movimiento, presentación y transiciones del guion.
- `campana_narrativa.gd` conserva el día y las noches en `user://narrativa.cfg`, valida al cargar y escribe por archivo temporal. No aplica costes ni completa tareas.
- `viaje_espacial.gd` compone seis capas pixel art de `assets/NarrativaInicio/`: tres fondos (`TierraPixelArt.png`, `EspacioProfundoPixelArt.png`, `MartePixelArt.png`), estela, etapa de transferencia y módulo orbital. Usa nodos `TextureRect`, fundidos, paralaje, zoom, curva de movimiento, impulso y desacople; no dibuja planetas, estrellas o la nave con `_draw()`. `etapa()` aporta el título según el progreso. `puesto.gd` muestra `ModuloDescensoAterrizajePixelArt.png` después de la llegada y mantiene la identidad visual del módulo separado.
- `puesto.gd` sigue siendo la única geometría del mapa. Centro de agua al noroeste de Energía, Taller al este de Control. `PASO_AGUA` y `PASO_TALLER` conectan las puertas. La esclusa recorta el casco y extiende el piso interior sin terreno rojo; su puerta interior queda visualmente abierta tras la entrada.
- `assets/NarrativaInicio/Percy(robotQueExuisteEnLaLuna).png` representa artísticamente al rover real. El nombre del archivo se conserva por compatibilidad, aunque Percy está en Marte. Reemplaza al SVG provisional; Pluto conserva `dron.png`. Prompts y recursos: [Arte del viaje](ARTE-VIAJE.md).
- `tests/narrativa_smoke.gd` verifica que el viaje cargue las seis capas `TextureRect` y las rutas exactas de los recursos pixel art, además de tramos de paso, ida, entrada, noches, guardado, embarque y regreso. Genera capturas en `build/qa/` cuando hay un servidor gráfico y omite solo las capturas al ejecutarse en modo `headless`. Ejecutar en perfil temporal: no usar la partida del jugador.

Flujo: `portada → ida → aterrizaje → camino_base → esclusa → base → noche (3 s) → amanecer → base`. Tras la quinta noche: `base → camino_nave → pilotaje → despegue → regreso → llegada_tierra (1 s) → epilogo (10 s)`. La ida y el descenso suman 8 s. Esc o el botón de la esquina adelantan al tramo jugable. `_ubicar_accion()` proyecta la posición del jugador para colocar acciones cercanas. Cada noche se confirma una vez. No se crea un sexto día. La posición al amanecer es el dormitorio.

El simulador anterior permanece en `scenes/simulacion_provisional.tscn`, con `umbra.gd`, `sol_uno.gd` y `guardado_mision.gd`. Los apartados siguientes documentan ese simulador, **no las actividades aprobadas**. La exportación principal abre el recorrido narrativo.

## Simulador provisional conservado

## Dónde trabajar

| Si vas a cambiar… | Abre primero… |
| --- | --- |
| La escena de entrada o su enlace al controlador | [scenes/umbra.tscn](../scenes/umbra.tscn) y [project.godot](../project.godot) |
| Diálogos, navegación entre fases, HUD o terminales | [scripts/umbra.gd](../scripts/umbra.gd) |
| Cámara, animación, recorrido, clima o colisiones | [scripts/puesto.gd](../scripts/puesto.gd) |
| Costos, límites, objetivos, recuperación o cierre | [scripts/sol_uno.gd](../scripts/sol_uno.gd) |
| Portada, exportación o paquete web | [web/umbra.html](../web/umbra.html), [web/exportar.ps1](../web/exportar.ps1) y [export_presets.cfg](../export_presets.cfg) |

Los nombres internos `umbra`, `SolUno` y `nido` vienen de versiones anteriores. La interfaz usa Horizonte Rojo y Pluto. El controlador recrea la presentación al cambiar de fase o menú. `guardado_mision.gd` escribe una instantánea versionada en `user://mision.cfg`. Se guarda al completar los pasos de apertura, llegar al refugio, completar tareas, cerrar el día y comenzar el siguiente. Recargar recupera el último punto. Una animación o tarea a medias vuelve a empezar desde el punto previo. «Reiniciar» elimina el guardado.

En la fase `chequeo`, `PuestoUmbra` dibuja a Pluto, la ruta del suelo y el avance de la lectura solar. El controlador comprueba si Nora se detiene sobre la marca. Al terminar la lectura, la ruta cambia hacia Iris y el siguiente tramo se abre por cercanía.

## Flujo de escenas

`inicio → aterrizaje → chequeo → salida → sondeo → taladro → sondeo → hallazgo → exterior → averia → evacuacion → esclusa_entrada → base → noche → relevo`. En `sondeo`, E ejecuta la acción del punto cercano. `expedicion_hielo.gd` guarda las lecturas, el gasto de un intento seco y el estado de la muestra. Tras perforar, Nora recoge el núcleo junto al taladro. Cuando lo lleva a la caja empieza `hallazgo` y sube la intensidad del polvo. Durante `averia`, Pluto muestra el efecto del polvo sobre los paneles. Los tres continúan hacia la esclusa. La esclusa se activa al llegar y anima las puertas en orden. En el navegador se entra al aterrizaje desde el botón de la portada web. Al avanzar de día, Nora despierta en el dormitorio. El cuarto día, la misión de Energía abre la fase exterior `nido` para controlar a Pluto.

El mapa usa `PASO_AGUA` para conectar Energía con el Centro de agua. Los puntos de operación están en `EQUIPO_AGUA`.

El sondeo dibuja los cortes de terreno a ras del suelo y marca la caja con un aro y una flecha. Los tres sprites recortados de ImageGen son `caja_hielo_cerrada.png`, `caja_hielo_abierta.png` y `nucleo_hielo.png`. La hoja original se pidió con una caja de campo aislada, la misma caja abierta y un trozo irregular de hielo con costra de tierra. La caja cerrada usa como referencia la posición del personaje que la lleva.


En superficie se camina sobre un eje horizontal. El refugio y el barranco tienen panoramas distintos. Dentro, las áreas `ROOMS` y `PASILLOS` permiten el paso, `EQUIPOS` lo bloquea y `TERMINALES` fija dónde interactuar. Al mover un mueble, puerta o panorama, comprueba su posición respecto de esas coordenadas. La cámara sigue al jugador. En una sala, `VISTAS` limita el encuadre al interior de la ilustración. En corredores la cámara sigue la posición con un acercamiento intermedio. **M** muestra el plano general. En superficie, `DISTANCIA_PANORAMA` conecta ambas ilustraciones y compensa la coordenada local al cruzar el tramo compartido. El regreso conserva el mismo reloj al cambiar de panorama. `_dibujar_polvo` usa coordenadas de pantalla para cubrir todo el visor.

El arte está en `assets/`. Los panoramas activos son `refugio_horizonte.png` y `barranco_horizonte.png`. `base.jpg` aporta el terreno y el patio; `ENCUADRES` define la distribución compacta del refugio y las ilustraciones de detalle se superponen en sus salas. Los ciclos de caminata usan hojas de ocho fotogramas. Conserva los archivos `.import` y `.uid` generados por Godot junto al recurso que corresponda.

El taller usa `PASO_TALLER` para su corredor. `PRUEBAS_ANEXOS` conserva la comprobación opcional del traje. Los guardados anteriores migran al nuevo esquema. Si su posición quedó en un módulo retirado, Nora reaparece en la esclusa.

Control usa la ilustración cenital generada con ImageGen en `assets/control_pasillos.png`. El encargo situó monitores y sillas al norte, dejó un piso continuo entre las puertas laterales y mantuvo la puerta sur hacia la esclusa. Las áreas de paso deben seguir las tres aberturas del dibujo. La entrada a Plantas se alcanza por el corredor este.



### Ilustraciones interiores

Se crearon con el generador integrado de imágenes como fondos retro 2D de vista cenital. La cámara cercana de la esclusa sigue a Nora y dibuja el casco sobre una extensión del piso de Control. El contorno exterior del módulo se usa en el plano general.

- [Centro de agua](../assets/laboratorio_agua.png) reutiliza el módulo occidental y alinea el tratamiento y la revisión con sus equipos.
- [Taller](../assets/taller_umbra.png) con escotilla al oeste, mesa de herramientas, camioneta elevada, repuestos, cascos y comprobador de aire.

## Contrato de campaña

`SolUno.iniciar_regreso(gasto_taladro)` aplica el perfil de emergencia una vez. `disponible(id)` comprueba batería y turnos, reserva lo necesario para la noche y protege el objetivo obligatorio pendiente. `aplicar(id)` registra la tarea al completarse. Los identificadores de acción son `energia`, `cultivos`, `agua` y `radio`. `agua` se activa en el Sol 2. El controlador aplica la acción después de superar la revisión. `cultivos` se usa para plantas y comida.

`relevo()` calcula un resumen sin avanzar el día. `siguiente_sol()` aplica ese resumen, añade la carga de la mañana y limpia las acciones del día. `respuesta` indica si se transmitió un informe el día anterior. Los tres tripulantes aportan un turno cada día.

| Campo de `relevo()` | Significado |
| --- | --- |

| `energia`, `raciones`, `agua`, `soporte` | Reservas y estado después del gasto nocturno. |

| `muestras` | Hallazgos acumulados de la campaña. |
| `cultivo`, `operativos` | Estado de las plantas y turnos de la tripulación. |
| `ciencia_enviada`, `informe_hoy` | Si se envió algún informe y si se envió uno en el día que termina. |
| `acciones` | Copia ordenada de las tareas completadas ese día. |

Acuerda con el equipo cualquier cambio a nombres, tipos o significado de estos campos. Los valores y desenlaces están en [Diseño](DISEÑO.md).

## Verificación antes de integrar

1. Importa el proyecto en Godot 4.7.2 y ejecuta con F5.
2. Haz la salida, recoge piedra y hielo en orden y comprueba que se puede regresar con el viento.
3. Vuelve con la tripulación, cruza la esclusa y comprueba la batería y los cultivos al despertar.
4. Desde Control, toma la puerta oeste hacia Energía. Usa el pasillo del fondo para llegar al Centro de agua. Comprueba las tres estaciones y el acceso al dormitorio y al taller.
5. Completa las misiones de agua, radio y Pluto. Verifica el cierre del Sol 5.
6. Si cambias la portada o el preset, abre la exportación servida por HTTP. Pulsa **Iniciar expedición** y comprueba que aparece el aterrizaje.

## Resultado de verificación del recorrido narrativo (2026-11-14)

- Cinemática de `NarrativaInicio`: importación sin errores de script en Godot 4.7.2. La prueba comprueba las seis capas `TextureRect`, sus rutas pixel art y finaliza con `NARRATIVA_OK`; en modo `headless` se omiten las capturas, pero no las aserciones ni el recorrido.
- Exportación Web `release` completada con las plantillas oficiales 4.7.2. El paquete contiene `index.html`, `index.js`, `index.wasm`, `index.pck`, los dos worklets de audio, `index.png` y `portada.png`; se generó `build/Horizonte-Rojo-Web.zip`.
- Revisión visual de la exportación Web: portada, carga del motor, nave y módulo acoplados al salir de la Tierra, y el mismo módulo ya aterrizado en Marte. Toda la escena conserva 2D pixel art y el controlador no dibuja planetas ni estrellas con primitivas.
- Godot 4.7.2: importación y ejecución sin errores de script.
- `tests/narrativa_smoke.gd`: `NARRATIVA_OK`. Comprueba tramos de acceso al Centro de agua, Energía, Taller, Plantas y Dormitorio, obstáculos representativos, cinco fundidos, guardado al despertar, ausencia de sexto día y regreso desde la nave.
- Las capturas de `build/qa/` se revisaron visualmente: umbral sin terreno rojo lateral, mapa compacto, bienvenida, noche y epílogo. Se corrigió el desbordamiento del texto final. La calidad del arte final sigue pendiente según el documento del equipo.
- El simulador anterior también pasó regreso durante tormenta, procesamiento de agua, cierre hasta el día 5 y migración del guardado versión 1. Esta prueba solo conserva compatibilidad; no aprueba esas actividades.
- Exportación Web completada. Se abrió en `http://127.0.0.1:8065/`, se inició con teclado y se observó el aterrizaje. No se registraron errores ni advertencias en la consola del navegador durante esa comprobación. El recorrido completo se comprobó en Godot; no se afirma un playtest completo de cinco días en navegador.
- Esta entrega es local; no se ha desplegado a Firebase ni enviado al repositorio remoto.
