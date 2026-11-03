# Horizonte Rojo

**Horizonte Rojo** es un juego narrativo 2D de cinco días en Marte. Una tormenta de polvo deja al refugio Umbra con energía limitada. Tomas decisiones de rescate y repartes el trabajo de la tripulación para mantener el refugio y avanzar la investigación.

## Jugar en Godot

1. Abre Godot 4.7.2. En esta carpeta hay una copia local para Windows.
2. En el gestor de proyectos, elige **Importar** y selecciona `project.godot`.
3. Pulsa **F6** con `scenes/umbra.tscn` abierta o **F5** desde cualquier escena.
4. Pulsa **Iniciar misión** y mira el aterrizaje. En el camino de afuera usa **A/D o izquierda/derecha**. Reúnete con Iris en la puerta y pulsa **E**. En el barranco, recoge la piedra y compara los puntos numerados con **E**. Cuando Pluto confirme la veta, sigue los tres pasos en pantalla con **E** o con el botón. Guarda el hielo en la caja marcada con **E**. Dentro de la base usa **WASD o flechas** y pulsa **Esc** para salir de un terminal.
5. Cada día tiene una misión. Sigue el marcador turquesa y usa el terminal de ese módulo. Puedes gastar los turnos sobrantes en cuidados y reservas. Desde Control, toma el pasillo hacia Enfermería y gira hacia arriba donde dice **Dormitorio**. En la sala, pulsa **E** y elige **Descansar y terminar el día** para revisar las reservas y continuar.

En superficie, pulsa **Espacio** para dar un salto corto y mira la fuerza del viento. Las rachas pueden hacerte retroceder. Mantén **Shift** para anclarte y aprovecha la tregua para avanzar. Los círculos del terreno indican abrigo. Dentro del refugio, **M** alterna entre el plano general y la cámara de cerca. En la vista de cerca, camina por las puertas para recorrer el interior de cada sala. Desde Energía, sube por la puerta del fondo y gira a la izquierda para llegar al laboratorio. Para llegar al taller, sigue derecho por el corredor que pasa debajo del dormitorio. Pulsa **E** en las estaciones señaladas. En el Sol 4, **E** activa los relés mientras controlas a Pluto.

## Jugar en navegador

Instala las plantillas de exportación de **Godot 4.7.2** y ejecuta `./web/exportar.ps1 -Godot "<ruta al ejecutable de consola de Godot>"` en PowerShell. El script exporta el juego, copia la portada y arma `build/Horizonte-Rojo-Web.zip`. Sirve el directorio completo por HTTP. Para probarlo desde PowerShell, ejecuta `python -m http.server 8065 --bind 127.0.0.1 --directory build/web` y abre [Horizonte Rojo en el navegador](http://127.0.0.1:8065/). Pulsa **Iniciar expedición** para comenzar el aterrizaje.

El preset usa WebGL 2 sin hilos. La página de lanzamiento está en [web/umbra.html](web/umbra.html) y el juego completo corre dentro de ella. Publica juntos el HTML, el motor y el paquete de datos en el alojamiento del equipo.

## Colaborar

Prueba la versión publicada en [Render](https://horizonte-rojo.onrender.com/). El [repositorio privado](https://github.com/JULINHO-22/horizonte-rojo) contiene el código y las imágenes en `main`. Cada integrante necesita acceso al repositorio e instalar Godot en su equipo.

- [AGENTS.md](AGENTS.md) orienta a Codex y fija qué documentación mantener.
- [Historia](docs/HISTORIA.md) reúne el guion, los personajes y la continuidad.
- [Diseño](docs/DISEÑO.md) explica las reglas, el balance y la ciencia.
- [Arquitectura](docs/ARQUITECTURA.md) indica qué código tocar y cómo verificarlo.
- [Publicación](docs/PUBLICACION.md) explica las ramas y el despliegue en Render.
- [Cambios](CHANGELOG.md) registra los avances del equipo.
