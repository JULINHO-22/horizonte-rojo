# UMBRA | Contexto para Codex

UMBRA es un juego de gestión narrativa 2D en Godot 4.7.2 para un equipo de seis estudiantes. El prototipo abarca la apertura marciana y el Sol 1. En la apertura, tres astronautas corren al refugio durante una tormenta de polvo y uno queda atrapado junto a un rover averiado. El rescate temprano interrumpe el invernadero. Esperar una tregua ahorra energía hoy y agrava la lesión. En ambas rutas quedan dos personas operativas.

1. Lee [README.md](README.md) para ejecutar el juego.
2. Lee [docs/DISEÑO.md](docs/DISEÑO.md) para historia, balance, ciencia y contrato de relevo. Consulta solo las secciones que afecte tu tarea.
3. Revisa [CHANGELOG.md](CHANGELOG.md) y el diff de Git antes de modificar un sistema compartido.

La escena de inicio está en `scenes/umbra.tscn`. `scripts/umbra.gd` maneja la presentación y `scripts/sol_uno.gd` concentra el estado y las reglas del primer sol.

En el mismo PR, registra los cambios relevantes para jugadores o equipo en `CHANGELOG.md`. Si cambias historia, reglas, valores, fuentes o el contrato entre soles, actualiza también `docs/DISEÑO.md`. Si cambia la instalación o la entrada principal, actualiza `README.md`. Mantén esta cabecera breve y revisa su contenido al cambiar el alcance o la arquitectura.

Trabaja en ramas por tarea y acuerda con el equipo los cambios al contrato de relevo. Antes de integrar, abre el proyecto, prueba ambas rutas y comprueba el estado del Sol 2. Incluye en el PR los archivos de Godot junto a sus `.uid` y `.import` asociados. El binario local y la caché `.godot/` se excluyen.
