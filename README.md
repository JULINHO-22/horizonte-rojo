# UMBRA

**Cinco soles para sobrevivir** es un juego narrativo 2D en el que una tormenta de polvo deja a una base marciana con energía limitada. Tomas decisiones de rescate y repartes el trabajo de la tripulación para mantener el refugio y avanzar la investigación.

## Jugar en Godot

1. Abre Godot 4.7.2. En esta carpeta hay una copia local para Windows.
2. En el gestor de proyectos, elige **Importar** y selecciona `project.godot`.
3. Pulsa **F6** con `scenes/umbra.tscn` abierta o **F5** desde cualquier escena.
4. Pulsa **Iniciar misión** y mira el aterrizaje. En el camino de afuera usa **A/D o izquierda/derecha**. Reúnete con Iris en la puerta y pulsa **E**. Ya en el campo de hielo, pulsa **E** para recoger primero la piedra y luego el hielo. Dentro de la base, usa **WASD o flechas** en las cuatro direcciones. Pulsa **Esc** para salir de un terminal.
5. Cada sol tiene una misión. Sigue el marcador turquesa y usa el terminal de ese módulo. Puedes gastar los turnos sobrantes en cuidados y reservas. Regresa a la esclusa y elige **Cerrar el sol** para revisar las reservas y continuar.

En superficie, mira la carga de viento. Las rachas pueden hacerte retroceder. Mantén **Shift** para anclarte y aprovecha la tregua para avanzar. Los círculos del terreno indican abrigo. Dentro del refugio, **M** alterna entre el plano general y el acercamiento por sala. En el Sol 4, **E** activa los relés mientras controlas a Pluto.

## Jugar en navegador

Instala las plantillas de exportación de **Godot 4.7.2** y ejecuta `./web/exportar.ps1 -Godot "<ruta al ejecutable de consola de Godot>"` en PowerShell. El script exporta el juego, copia la portada y arma `build/UMBRA-Web.zip`. Sirve el directorio completo por HTTP. Para probarlo desde PowerShell, ejecuta `python -m http.server 8065 --bind 127.0.0.1 --directory build/web` y abre [UMBRA en el navegador](http://127.0.0.1:8065/). Pulsa **Iniciar expedición** para comenzar el aterrizaje.

El preset usa WebGL 2 sin hilos. La página de lanzamiento está en [web/umbra.html](web/umbra.html) y el juego completo corre dentro de ella. Publica juntos el HTML, el motor y el paquete de datos en el alojamiento del equipo.

## Colaborar

El repositorio Git local está inicializado en `main`. Cuando el equipo tenga su repositorio de GitHub, se puede asociar como remoto y publicar desde Git. Para una copia clonada, cada integrante debe instalar Godot por separado.

- [AGENTS.md](AGENTS.md) orienta a Codex y fija qué documentación mantener.
- [Diseño y relevo](docs/DISEÑO.md) define la apertura y las variables que recibe el Sol 2.
- [Cambios](CHANGELOG.md) registra los avances del equipo.
