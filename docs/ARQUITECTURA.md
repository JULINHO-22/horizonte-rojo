# Arquitectura y verificación

## Dónde trabajar

| Si vas a cambiar… | Abre primero… |
| --- | --- |
| La escena de entrada o su enlace al controlador | [scenes/umbra.tscn](../scenes/umbra.tscn) y [project.godot](../project.godot) |
| Diálogos, navegación entre fases, HUD o terminales | [scripts/umbra.gd](../scripts/umbra.gd) |
| Cámara, animación, recorrido, clima o colisiones | [scripts/puesto.gd](../scripts/puesto.gd) |
| Costos, límites, objetivos, recuperación o cierre | [scripts/sol_uno.gd](../scripts/sol_uno.gd) |
| Portada, exportación o paquete web | [web/umbra.html](../web/umbra.html), [web/exportar.ps1](../web/exportar.ps1) y [export_presets.cfg](../export_presets.cfg) |

Los nombres internos `umbra`, `SolUno` y `nido` vienen de versiones anteriores. La interfaz usa Horizonte Rojo y Pluto. El controlador mantiene el estado de la partida en memoria y recrea la presentación al cambiar de fase o menú. Recargar la página reinicia la partida.

## Flujo de escenas

`inicio → aterrizaje → chequeo → salida → sondeo → taladro → sondeo → hallazgo → exterior → caida → averia → sujetar → decision → extraccion → evacuacion → base → noche → relevo`. En `sondeo`, E y el botón visible ejecutan la misma acción contextual. `expedicion_hielo.gd` decide qué acción está disponible y guarda las lecturas, el gasto de un intento seco y el estado de la muestra. Tras la animación del taladro, la caja se puede usar para recoger el hielo. Al recogerlo, empieza `hallazgo` y sube la intensidad del polvo. La ruta de espera inserta `apagado → abrigo → tregua` antes de `extraccion`. Las dos rutas pasan por `esclusa_entrada` antes de la base. En el navegador se entra al aterrizaje desde el botón de la portada web. Al avanzar de día, Nora despierta en el dormitorio. El cuarto día, la misión de Energía abre la fase exterior `nido` para controlar a Pluto.

El sondeo dibuja los cortes de terreno a ras del suelo y marca la caja con un aro y una flecha. Los tres sprites recortados de ImageGen son `caja_hielo_cerrada.png`, `caja_hielo_abierta.png` y `nucleo_hielo.png`. La hoja original se pidió con una caja de campo aislada, la misma caja abierta y un trozo irregular de hielo con costra de tierra. La caja cerrada usa como referencia la posición del personaje que la lleva.


En superficie se camina sobre un eje horizontal. El refugio y el barranco tienen panoramas distintos. Dentro, las áreas `ROOMS` y `PASILLOS` permiten el paso, `EQUIPOS` lo bloquea y `TERMINALES` fija dónde interactuar. Al mover un mueble, puerta o panorama, comprueba su posición respecto de esas coordenadas. La cámara sigue al jugador. En una sala, `VISTAS` limita el encuadre al interior de la ilustración. En corredores la cámara sigue la posición con un acercamiento intermedio. **M** muestra el plano general. En superficie, `DISTANCIA_PANORAMA` conecta ambas ilustraciones y compensa la coordenada local al cruzar el tramo compartido. El regreso conserva el mismo reloj al cambiar de panorama. `_dibujar_polvo` usa coordenadas de pantalla para cubrir todo el visor.

El arte está en `assets/`. Los panoramas activos son `refugio_horizonte.png` y `barranco_horizonte.png`. `base.jpg` define la distribución del refugio y las ilustraciones de detalle se superponen en sus salas. Los ciclos de caminata usan hojas de ocho fotogramas. La caída de Teo usa cuatro recortes propios. Conserva los archivos `.import` y `.uid` generados por Godot junto al recurso que corresponda.

Los dos anexos usan `PASO_ANEXOS` para los corredores y amplían `LIMITES_BASE`. Sus zonas de movimiento viven en `ROOMS`. `PRUEBAS_ANEXOS` define las dos comprobaciones opcionales y su resultado vive en memoria durante la partida. Estos resultados quedan fuera de `SolUno.relevo()`.

Control usa la ilustración cenital generada con ImageGen en `assets/control_pasillos.png`. El encargo situó monitores y sillas al norte, dejó un piso continuo entre las puertas laterales y mantuvo la puerta sur hacia la esclusa. Las áreas de paso deben seguir las tres aberturas del dibujo. La entrada a Plantas se alcanza por el corredor este.

Los cuidados de Teo usan el estado temporal de la interacción en `umbra.gd`. El sprite `assets/teo_reposo_cenital.png` se generó con ImageGen con el encargo de un astronauta rubio acostado visto desde arriba, con manta azul y fondo transparente. El dibujo de la férula y la correa acompaña el recorrido y el tiempo que se mantiene E. El turno se consume al terminar la animación.

### Ilustraciones de los anexos

Se crearon con el generador integrado de imágenes, como fondos retro 2D de vista cenital, sin personajes ni texto. Los prompts pidieron una carcasa marfil con bandas naranjas, un pasillo central despejado y equipos al norte y al sur.

- [Laboratorio de agua](../assets/laboratorio_agua.png) con escotilla al este, cajones helados, filtro transparente, depósitos y núcleo de hielo.
- [Taller](../assets/taller_umbra.png) con escotilla al oeste, mesa de herramientas, camioneta elevada, repuestos, cascos y comprobador de aire.

## Contrato de campaña

`SolUno.abrir(ruta)` aplica una sola vez la decisión inicial. `disponible(id)` comprueba batería y turnos, reserva lo necesario para la noche y protege el objetivo obligatorio pendiente. `aplicar(id)` registra la tarea al completarse. Los identificadores de acción son `energia`, `cultivos`, `medicina` y `radio`.

`relevo()` calcula un resumen sin avanzar el día. `siguiente_sol()` aplica ese resumen, descuenta los cuidados, añade la carga de la mañana y limpia las acciones del día. `respuesta` indica si se transmitió un informe el día anterior. La recuperación médica se conserva y, tras dos sesiones, hay tres personas operativas a partir del día siguiente.

| Campo de `relevo()` | Significado |
| --- | --- |
| `ruta` | `rescate` o `espera`. |
| `energia`, `raciones`, `agua`, `soporte` | Reservas y estado después del gasto nocturno. |
| `energia_comprometida` | Batería prevista para cuidar a Teo al avanzar. Está separada de `energia`. |
| `muestras` | Hallazgos acumulados de la campaña. |
| `cultivo`, `paciente`, `operativos` | Estado visible de las plantas, Teo y la capacidad de trabajo. |
| `ciencia_enviada`, `informe_hoy` | Si se envió algún informe y si se envió uno en el día que termina. |
| `acciones` | Copia ordenada de las tareas completadas ese día. |

Acuerda con el equipo cualquier cambio a nombres, tipos o significado de estos campos. Los valores y desenlaces están en [Diseño](DISEÑO.md).

## Verificación antes de integrar

1. Importa el proyecto en Godot 4.7.2 y ejecuta con F5.
2. Haz la salida, recoge piedra y hielo en orden y comprueba que se puede regresar con el viento.
3. Prueba cada decisión de rescate. Comprueba la batería, plantas y cuidados al comienzo del día 2.
4. Recorre todos los módulos y los puntos de inspección. Desde Control cruza a la derecha, sube por las flechas del desvío y gira a la derecha al llegar a la bifurcación. Comprueba que el mapa, la cámara y los pies de Nora sigan ese recorrido. Entra al laboratorio desde Energía y al taller desde el corredor norte. Prueba ambas respuestas en el filtro y el comprobador del traje, y verifica que no gasten recursos. Verifica que el dormitorio impida descansar antes del objetivo y que aún sea posible completar la misión después de las tareas opcionales permitidas.
5. Completa el circuito de agua, la sintonización, los tres relés de Pluto y el informe final. Verifica una partida con dos sesiones médicas y otra con cuidados pendientes.
6. Si cambias la portada o el preset, abre la exportación servida por HTTP. Pulsa **Iniciar expedición** y comprueba que aparece el aterrizaje.
