# Horizonte Rojo | Contexto para Codex

Horizonte Rojo es un juego de gestión narrativa 2D en Godot 4.7.2 para un equipo de seis estudiantes. La campaña abarca cinco soles y puede exportarse al navegador. La apertura visita el refugio y un campo de hielo distante. En el regreso durante la tormenta, Teo queda atrás y se atasca junto a la camioneta. Pluto muestra la avería de la energía solar. El rescate temprano interrumpe el invernadero. Esperar una tregua ahorra energía hoy y agrava la lesión. Al comienzo quedan dos personas operativas.

1. Lee [README.md](README.md) para ejecutar el juego.
2. Abre solo la guía que corresponda a tu tarea.
   - [Historia](docs/HISTORIA.md) para personajes, escenas y continuidad.
   - [Diseño](docs/DISEÑO.md) para reglas, balance y ciencia.
   - [Arquitectura](docs/ARQUITECTURA.md) para código, arte, contrato de estado y pruebas.
   - [Publicación](docs/PUBLICACION.md) para GitHub, exportación Web y Render.
3. Revisa [CHANGELOG.md](CHANGELOG.md) y el diff de Git antes de modificar un sistema compartido.

La escena de inicio está en `scenes/umbra.tscn`. `scripts/umbra.gd` maneja el flujo, la guía de Pluto y las operaciones de terminal. `scripts/puesto.gd` dibuja el mapa, anima la tripulación y define cámara, colisiones y terminales. `scripts/sol_uno.gd` concentra los objetivos obligatorios y el estado de campaña. `web/umbra.html` es la plantilla de lanzamiento para el preset Web.

En el mismo PR, registra los cambios relevantes en `CHANGELOG.md` y actualiza la guía afectada. Si cambia la instalación o el punto de entrada, actualiza `README.md`. Mantén esta cabecera breve y revisa su contenido al cambiar el alcance o la arquitectura.

Trabaja en ramas por tarea y acuerda con el equipo los cambios al contrato de relevo. Antes de integrar, abre el proyecto, prueba ambas rutas y comprueba el estado del Sol 2. Incluye en el PR los archivos de Godot junto a sus `.uid` y `.import` asociados. El binario local y la caché `.godot/` se excluyen.
