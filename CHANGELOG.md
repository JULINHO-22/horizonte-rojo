# Cambios

## 2026-11-14 | Base compartida de mecánicas

- Modelo separado de energía, agua, oxígeno, alimento, cultivos y continuidad entre días. Incluye reglas de noche, registro de decisiones y estado para guardar.
- Banco de pruebas independiente en Godot y prueba automatizada de recursos. El equipo dispone del contrato y un prompt base para cada día.

## 2026-11-14 | Cinemática inicial 2D pixel art por etapas

- La dirección visual definitiva del proyecto es 2D pixel art. Se reemplaza la iteración que mezclaba fondos realistas con una nave pixelada.
- `viaje_espacial.gd` usa seis `TextureRect`: `TierraPixelArt.png`, `EspacioProfundoPixelArt.png`, `MartePixelArt.png`, `EstelaPropulsionPixelArt.png`, `NaveTransferenciaPixelArt.png` y `ModuloDescensoOrbitalPixelArt.png`.
- La etapa grande y el módulo aparecen acoplados al salir de la Tierra; al aproximarse a Marte toman rutas, escalas y giros distintos. La estela pulsa durante los impulsos y se apaga en el desacople.
- `puesto.gd` usa `ModuloDescensoAterrizajePixelArt.png`, variante terrestre del mismo diseño, para mantener continuidad entre separación y llegada.
- El regreso invierte los fondos y comienza con el módulo separado antes de acoplarlo. La secuencia sigue siendo un montaje ilustrativo de nueve segundos, no una simulación orbital.
- El preset Web excluye los recursos visuales anteriores. Godot empaqueta los PNG en `index.pck`, por lo que Firebase Hosting conserva el mismo flujo y no necesita video, códecs ni descargas externas.
- Se validaron importación, prueba narrativa completa, exportación Web y revisión visual del acople inicial y el aterrizaje. Los recursos y el conjunto de prompts quedan registrados en `docs/ARTE-VIAJE.md`.

## 2026-11-14 | Guion del equipo, cinco noches y mapa compacto

- Se copia y contrasta el guion de Google Docs en `docs/NARRATIVA-EQUIPO.md`, con alcances y pendientes explícitos.
- La escena principal pasa a un recorrido narrativo separado de las actividades provisionales; no se añaden actividades diarias.
- Ida y regreso comparten una trayectoria ilustrativa. Percy recibe al equipo; Pluto guía dentro. Cinco noches con fundido progresivo de tres segundos y despertar automático. Tras la quinta: salida a la nave, pilotaje, regreso y epílogo provisional.
- Se compactan Centro de agua y Taller, se elimina el resto de Enfermería del terreno y se completa el piso de la unión Control–esclusa. La puerta interior permanece abierta tras presurizar.
- Guardado narrativo independiente y pruebas de rutas, cinco noches, reanudación y final.
- Pendiente: lanzamiento orbital detallado y arte/animación de científicos para la escena terrestre. La secuencia actual no es una campaña de actividades terminada.

## 2026-11-14 | Centro de agua y regreso de la tripulación

- El Centro de agua ocupa un módulo propio conectado a Energía. Se retiran Enfermería, el accidente de Teo y la tarea de cuidados.
- La tormenta corta la generación solar y el equipo vuelve junto. Los tres tripulantes aportan un turno. Los guardados anteriores conservan el progreso.

## 2026-11-14 | Esclusa interior y consultorio

- La cámara de entrada sigue a Nora entre ambas puertas. El encuadre cercano usa el piso interior de Control y conserva abierto el acceso una vez presurizada la esclusa.
- Soporte vital incorpora un consultorio y tres estaciones de agua. El laboratorio de muestras se retira del mapa, de las interacciones y de la exportación web.

## 2026-11-14 | Publicación en Firebase

- La exportación Web se publica en Firebase Hosting desde `build/web`. La guía de publicación incluye el enlace y el comando de despliegue.

## 2026-11-14 | Recorrido de Pluto y guardado

- Pluto guía a Nora por el terreno. Nora se detiene para comprobar la energía solar y luego continúa hasta Iris.
- La partida recupera puntos de control locales después de volver a abrir o recargar el juego.
- La exportación Web excluye ilustraciones en desuso y archivos generados. El lienzo conserva su tamaño interno al recibir un evento de resize que no cambia sus dimensiones.

## 2026-11-14 | Hielo, esclusa y soporte vital

- La camioneta aparece a partir del accidente. En el sondeo, Nora recoge el hielo junto al taladro y lo lleva a la caja.
- La radio separa el diálogo, la instrucción y el coste. Al llegar al refugio se animan las dos puertas de la esclusa.
- La estación de agua comparte el módulo de Soporte vital con Enfermería. Solo repone la reserva tras tratar la muestra y aprobar la revisión.

## 2026-11-14 | Rescate en el barranco

- Nora puede caminar al gato eléctrico o al abrigo, escuchar la consecuencia por radio y confirmar con E en el terreno. El viento baja durante la espera y Nora vuelve junto a la camioneta.

## 2026-11-14 | Fuentes para la simulación

- Se documentan los registros de polvo, radiación, comunicaciones, hielo y cultivos que puede usar el equipo.
- Se verifican los siete recursos del reto y se documentan las consultas de DONKI, RadLab y OSDR, la capa de Mars Trek y las actividades educativas de la CSA.

## 2026-11-13 | Rescate y avisos en escena

- La rueda dañada se muestra en la escena. El maletín sigue el guante del personaje que lo transporta.
- Control indica los objetivos pendientes sin detener la marcha y abre la radio en una franja inferior cuando se puede usar.
- Teo está de pie en observación tras el rescate temprano. La ruta de espera lo deja en cama hasta el primer cuidado.

## 2026-11-13 | Pulido del barranco y el rescate

- Los cortes del suelo quedan a la altura de los aros y la flecha señala la caja. Las indicaciones de Iris quedan al pie de la pantalla.
- La caja abierta, la caja cerrada y el trozo de hielo tienen sprites propios. La caja cerrada se mueve con quien la transporta.
- La camioneta se inclina al caer en la zanja. La rueda rota explica que quede inmovilizada y el gato permite liberar la bota de Teo.

## 2026-11-13 | Salida y recolección de hielo

- Iris acompaña la salida con diálogo durante el recorrido. El sondeo tiene una sola acción contextual, disponible con E o clic.
- Guardar la muestra en la caja confirma la carga en pantalla y permite comenzar el regreso.

## 2026-11-13 | Sondeo, pasillos y guía de tareas

- El hielo se elige comparando capas del suelo. Una perforación en seco reduce la batería de llegada y la tripulación participa en la extracción correcta.
- El cielo se oscurece antes del regreso y Teo lleva la caja. Su pose de reposo se ajusta al lado derecho del colchón.
- Energía permite cruzar el pasillo oeste entre equipos. Plantas tiene recorridos alrededor de las bandejas.
- Pluto guía la tarea principal antes de habilitar tareas opcionales. La reserva de Energía se prueba eligiendo qué alimentar y el cierre anticipa el efecto de cuidados y cultivo.

## 2026-11-13 | Circulación, cuidados y rescate

- Control tiene consolas al norte y un paso libre entre las puertas laterales. Los personajes de interior usan una escala intermedia ajustada a las puertas y estaciones y Plantas conserva su acceso por el corredor señalizado.
- Para cuidar a Teo, se recoge una férula en el botiquín, se lleva a la camilla y se sujeta la correa con E. El panel de trabajo conserva visible la escena.
- El fallo solar ocurre antes del rescate. Iris pide sujetar la cuerda. El jugador decide si usa la batería portátil del equipo para mover la pieza que atrapó la bota o espera con la cuerda sujeta.

## 2026-11-12 | Enunciado del reto

- Se documenta el reto de NASA Space Apps y su relación con las decisiones de cada sol.

## 2026-11-03 | Referentes reales de Umbra

- La apertura presenta Umbra como una misión simulada. Pluto explica el ajuste de presión en la esclusa y la comprobación de calidad después de filtrar el agua.
- La guía de diseño distingue los ejemplos operativos de la EEI, el hábitat de simulación CHAPEA y la investigación sobre recursos marcianos.

## 2026-11-03 | Ampliación del refugio

- Dos módulos ilustrados y transitables amplían el plano. El laboratorio se alcanza desde Energía y el taller desde el corredor del dormitorio.
- Seis estaciones nuevas explican el trabajo de Umbra. En dos de ellas se puede probar el filtro y localizar una fuga en un traje, con explicación de Pluto y posibilidad de volver a intentarlo.

## 2026-11-03 | Cámara de interior y tormenta continua

- La cámara entra en las salas con un encuadre cercano y pasa por las puertas y corredores. Las ilustraciones mantienen su iluminación y M abre el plano general.
- El polvo y las ráfagas cubren toda la vista exterior, incluido el regreso a la esclusa y la avería de los paneles. La animación sigue al cambiar de panorama.

## 2026-11-03 | Dormitorio y extracción guiada

- El dormitorio tiene un desvío señalizado antes de Enfermería. Desde allí también se accede a la sala de plantas.
- Nora se mueve por los pasillos y el suelo visible de las salas. Los límites se ajustaron a paredes, camas, jardineras y equipos.
- Pluto guía la extracción en tres pasos que se activan con E o el botón. Las lecturas del terreno y el guardado de la muestra siguen siendo parte de la expedición.

## 2026-11-03 | Pasillos, sondeos y rutas de rescate

- La cámara sigue a Nora por salas y pasillos. El plano completo se consulta con M; al caminar se revelan las habitaciones cercanas.
- Los panoramas del refugio y el barranco comparten un tramo de sendero. La entrada a la base muestra el cierre de la puerta antes de pasar al interior.
- Dos lecturas del terreno permiten distinguir hielo de escarcha o suelo seco. El taladro avanza mientras se mantiene Espacio y se enfría al soltarlo.
- El rescate temprano devuelve a Teo a pie con Iris. En la otra ruta, Nora busca abrigo, espera la tregua y vuelve con Teo en camilla.

## 2026-11-03 | Exploración, extracción y descanso

- Nora puede dar un salto corto en superficie. La aceleración cambia entre el interior, el suelo marciano y el aire.
- El hielo se extrae con dos cortes al ritmo del taladro y se guarda en una caja antes del regreso.
- Las salas tienen puntos de inspección y el encuadre resalta el módulo que se está recorriendo.
- El dormitorio al noreste cierra cada día con una escena de descanso. La puerta del refugio indica que el interior tiene aire respirable.

## 2026-11-03 | Guía de continuidad para el equipo

- Contexto narrativo y fichas de personajes para continuar el guion.
- Mapa del código, contrato de estado entre días y recorridos de verificación.
- Procedimiento para colaborar en GitHub y actualizar la versión pública de Render.

## 2026-11-03 | Horizonte Rojo

- Nuevo nombre y portada web. El escenario ocupa el área de juego sin la cabecera y el pie decorativos.
- Panoramas recreados del refugio y del barranco. Los personajes toman la abertura de la puerta como referencia de escala.
- Sala de plantas ilustrada a mayor resolución, con el recorrido ajustado al pasillo y las jardineras.

## 2026-11-03 | Expedición al campo de hielo y salas

- El robot se llama Pluto. La tripulación recibe el aviso en el refugio, viaja a un barranco y recoge una piedra y una muestra de hielo.
- Teo va al final del grupo durante el regreso. La avería de los paneles se ve antes del dilema; esperar muestra el corte de la toma exterior y la salida con camilla.
- Iris usa sus fotogramas de marcha al salir de la nave, durante la carrera y al patrullar Control.
- Cámara de interior más abierta, ilustración de Control a mayor resolución y Teo acostado a lo largo del colchón.

## 2026-11-03 | Aterrizaje y apertura para público infantil

- Portada ilustrada que inicia el juego con un solo botón y deja el área del juego a todo el ancho disponible.
- Aterrizaje animado, búsqueda de hielo, carrera jugable hacia el refugio y caída animada de Teo antes del rescate.
- Sendero lateral dibujado bajo los pies. Las direcciones verticales se usan dentro del refugio.
- Opciones de rescate y órdenes de NIDO en lenguaje cotidiano. La pantalla muestra días, batería, comida, agua y tareas restantes.

## 2026-11-03 | Tormenta, refugio y salida de NIDO

- Ráfagas con empuje, refugios de superficie, anclaje manual, reducción de visibilidad y sonido variable.
- Arte nuevo para el frente de polvo, la esclusa y el módulo de Energía. Transición de entrada y plano general con M.
- Circuito de válvulas para procesar hielo y salida pilotable de NIDO para activar tres relés en el Sol 4.
- El desenlace diferencia entre enviar el informe con margen de operación y sobrevivir con cuidados o soporte vital pendientes.

## 2026-11-03 | Chequeo inicial y misiones guiadas

- Chequeo jugable con Teo antes de la tormenta, y estados de salud diferenciados.
- Caminata con fotogramas de cuerpo completo y animación vinculada al desplazamiento.
- Mapa a todo el ancho, operaciones y bitácora centradas, guía de NIDO y marcador del objetivo.
- Una misión obligatoria por sol, con turnos reservados y tareas adicionales de supervivencia. Operación de circuitos y filtros por pasos y sintonización de radio.

## 2026-11-03 | Arte de tripulación, supervivencia y Web

- El mapa de referencia se usa como mundo explorable con zoom por sala, y enfermería tiene una ilustración ampliada.
- Sprites y retratos nuevos de Nora, Iris, Teo y el robot, con expresiones de emergencia y una variante de recuperación.
- Cinco soles jugables con procedimientos en terminales, agua, alimentos, cuidados, alerta solar y resultados científicos.
- Preset Web de Godot y página de lanzamiento con controles y progreso de carga.

## 2026-11-03 | Apertura narrativa y base explorable

- Inicio de misión y cinemática animada con Nora, Iris, Teo, tormenta, caída y extracción.
- Movimiento de Nora con WASD y flechas, e interacción por cercanía con E.
- Interior 2D construido a partir de la referencia, con pasillos, equipos, colisiones y cinco zonas.
- Los terminales operan desde el mapa y la esclusa abre el cierre del sol.

## 2026-11-03 | Prototipo del Sol 1

- Proyecto 2D en Godot con apertura ilustrada, plano interactivo y bitácora.
- Rescate inmediato o extracción tras una tregua, con consecuencias en energía, cultivos y cuidados.
- Cuatro módulos de base, dos turnos de trabajo y presupuesto nocturno.
- Contrato de estado para el Sol 2 y documentación de arranque para el equipo.
