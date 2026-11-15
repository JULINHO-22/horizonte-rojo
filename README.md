# Horizonte Rojo

**Horizonte Rojo** es un proyecto de juego narrativo 2D de cinco días en Marte. La versión principal permite revisar el viaje, la llegada al refugio, las noches y el regreso. Las actividades de gestión se definirán con el equipo.

## Estado y ejecución actual

La escena principal es un **recorrido narrativo en revisión**: cinemática 2D pixel art de ida, llegada, Percy, exploración del refugio, cinco noches y regreso. La nave sale con el módulo acoplado, lo separa al aproximarse a Marte y conserva ese diseño en el aterrizaje. La secuencia usa imágenes locales de `assets/NarrativaInicio/`; no reproduce video externo ni depende de recursos remotos. Las actividades de los días están pendientes de definición. Consulta [Narrativa del equipo](docs/NARRATIVA-EQUIPO.md) para el documento fuente, las adaptaciones y lo que falta.

1. Importa `project.godot` en Godot 4.7.2 y pulsa **F5**.
2. Inicia el viaje. Puedes saltarlo con **Esc** o con el botón de la esquina. Percy te saluda mientras ya puedes caminar.
3. Camina con **A/D o flechas** hacia la derecha hasta entrar al refugio. En el interior usa **WASD/flechas** y **M** para el plano.
4. Desde Control, cruza la puerta derecha, sube por el corredor y gira a la derecha hacia Dormitorio. Cerca de la marca pulsa **E** o **Descansar**. La pantalla se oscurece durante tres segundos y comienza la siguiente mañana.
5. Tras la quinta noche, revisa Control, sal por la esclusa y sigue el camino hacia la izquierda hasta la nave. **E** permite subir; en el puesto de pilotaje, **Iniciar vuelo** activa el regreso.

El laboratorio de Agua y Oxígeno está al noroeste, pasando por Energía. Purifica agua junto al filtro azul y prepara oxígeno junto a los depósitos verdes. El taller está inmediatamente al este de Control. Plantas se alcanza por el desvío norte del corredor este, girando a la izquierda. No hay Enfermería ni accidente de Teo.

El recorrido guarda su avance en `user://narrativa.cfg`, separado de las partidas del simulador anterior. Para revisar el inicio usa **Empezar de nuevo** en la portada. Durante una transición se recupera el último punto estable.

El código anterior de actividades sigue disponible para el equipo en `scenes/simulacion_provisional.tscn` (**F6**). No es el guion aprobado ni la versión principal.

Para ver los dos finales alternativos abre `scenes/final_incompleta.tscn` o `scenes/final_cumplida.tscn` y pulsa **F6**. Consulta [Finales en la Tierra](docs/FINALES.md).

## Probar los días 4 y 5

En la rama `codex/dias-4-y-5`, abre `scenes/dias/tramo_final/prueba.tscn` y pulsa **F6**. Puedes empezar en el día 4 con diferentes antecedentes o probar directamente los tres desenlaces del día 5. Los dos niveles comparten las reservas. El banco funciona al margen del guardado de campaña. Consulta [Día 4](docs/dias/DIA-4.md) y [Día 5](docs/dias/DIA-5.md) para el contrato de integración.

## Probar la base de mecánicas

Abre `scenes/pruebas/banco_recursos.tscn` y pulsa **F6**. Consulta [reglas y API](docs/MECANICAS-BASICAS.md) y [prompt por día](docs/PROMPT-NIVELES.md).

## Jugar en navegador

Instala las plantillas de exportación de **Godot 4.7.2** y ejecuta `./web/exportar.ps1 -Godot "<ruta al ejecutable de consola de Godot>"` en PowerShell. El script exporta el juego, copia la portada y arma `build/Horizonte-Rojo-Web.zip`. Sirve el directorio completo por HTTP. Para probarlo desde PowerShell, ejecuta `python -m http.server 8065 --bind 127.0.0.1 --directory build/web` y abre [Horizonte Rojo en el navegador](http://127.0.0.1:8065/). Pulsa **Entrar al recorrido**. La primera partida inicia el viaje automáticamente después de cargar. Si ya hay una partida, puedes continuarla o comenzar de nuevo. Si el mismo navegador conserva una partida para esa dirección, retoma el último punto guardado.

El preset usa WebGL 2 sin hilos. La página de lanzamiento está en [web/umbra.html](web/umbra.html) y el juego completo corre dentro de ella. Publica juntos el HTML, el motor y el paquete de datos en el alojamiento del equipo.

## Colaborar

Prueba la versión publicada en [Firebase Hosting](https://horizonte-rojo-game.web.app/). El [repositorio privado](https://github.com/JULINHO-22/horizonte-rojo) contiene el código y las imágenes en `main`. Cada integrante necesita acceso al repositorio e instalar Godot en su equipo.

- [AGENTS.md](AGENTS.md) orienta a Codex y fija qué documentación mantener.
- [Reto NASA](docs/RETO-NASA.md) reúne el enunciado y las propuestas de niveles.
- [Historia](docs/HISTORIA.md) reúne el guion, los personajes y la continuidad.
- [Diseño](docs/DISEÑO.md) explica las reglas, el balance y la ciencia.
- [Arquitectura](docs/ARQUITECTURA.md) indica qué código tocar y cómo verificarlo.
- [Publicación](docs/PUBLICACION.md) explica las ramas y el despliegue en Render.
- [Cambios](CHANGELOG.md) registra los avances del equipo.
