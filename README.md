# UMBRA

**Cinco soles para sobrevivir** es un juego narrativo 2D en el que una tormenta de polvo deja a una base marciana con energía limitada. Tomas decisiones de rescate y repartes el trabajo de la tripulación para mantener el refugio y avanzar la investigación.

## Jugar en Godot

1. Abre Godot 4.7.2. En esta carpeta hay una copia local para Windows.
2. En el gestor de proyectos, elige **Importar** y selecciona `project.godot`.
3. Pulsa **F6** con `scenes/umbra.tscn` abierta o **F5** desde cualquier escena.
4. Pulsa **Iniciar misión** para ver la cinemática. Mueve a Nora con **WASD o flechas** y pulsa **E** cerca del rover, la esclusa o un terminal. En los menús, elige con el ratón o usa **Tab** y **Enter**.
5. Entra a cada sala para acercar la cámara. Usa el terminal y elige un procedimiento. Al comienzo tienes dos turnos por sol. Regresa a la esclusa, pulsa **E** y elige **Cerrar el sol** para revisar las reservas y continuar.

## Jugar en navegador

Instala las plantillas de exportación de **Godot 4.7.2** y elige **Proyecto → Exportar → Web**. El destino configurado es `build/web/index.html`. Sirve el directorio completo por HTTP. Para probarlo desde PowerShell, ejecuta `python -m http.server 8065 --bind 127.0.0.1 --directory build/web` y abre [UMBRA en el navegador](http://127.0.0.1:8065/).

El preset usa WebGL 2 sin hilos. La página de lanzamiento está en [web/umbra.html](web/umbra.html) y el juego completo corre dentro de ella. Publica juntos el HTML, el motor y el paquete de datos en el alojamiento del equipo.

## Colaborar

El repositorio Git local está inicializado en `main`. Cuando el equipo tenga su repositorio de GitHub, se puede asociar como remoto y publicar desde Git. Para una copia clonada, cada integrante debe instalar Godot por separado.

- [AGENTS.md](AGENTS.md) orienta a Codex y fija qué documentación mantener.
- [Diseño y relevo](docs/DISEÑO.md) define la apertura y las variables que recibe el Sol 2.
- [Cambios](CHANGELOG.md) registra los avances del equipo.
