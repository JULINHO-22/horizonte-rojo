# Horizonte Rojo | Contexto para Codex

Horizonte Rojo es un juego narrativo 2D de cinco soles en Godot 4.7.2. El alcance actual es inicio, noches y final según [Narrativa del equipo](docs/NARRATIVA-EQUIPO.md). Las actividades diarias NO están definidas: no implementar nuevas misiones sin acordarlas. Percy guía fuera y Pluto dentro. No hay Enfermería ni accidente; el Centro de agua es independiente.

1. Lee [README.md](README.md) para ejecutar el juego.
2. Abre solo la guía que corresponda a tu tarea.
   - [Reto NASA](docs/RETO-NASA.md) para el enunciado, los criterios y las propuestas de niveles.
   - [Datos NASA](docs/DATOS-NASA.md) para fuentes verificadas y su uso en el juego.
   - [Historia](docs/HISTORIA.md) para personajes, escenas y continuidad.
   - [Diseño](docs/DISEÑO.md) para reglas, balance y ciencia.
   - [Arquitectura](docs/ARQUITECTURA.md) para código, arte, contrato de estado y pruebas.
   - [Publicación](docs/PUBLICACION.md) para GitHub, exportación Web y Render.
3. Revisa [CHANGELOG.md](CHANGELOG.md) y el diff de Git antes de modificar un sistema compartido.

La escena principal `scenes/umbra.tscn` usa `guion_inicio_final.gd`. `campana_narrativa.gd` conserva noches y días; `viaje_espacial.gd` presenta las trayectorias. `puesto.gd` comparte mapa, cámara y colisiones. Las actividades anteriores quedan aisladas en `scenes/simulacion_provisional.tscn` (`umbra.gd` + `sol_uno.gd`), como referencia provisional. La portada web está en `web/umbra.html`.

En el mismo PR, registra los cambios relevantes en `CHANGELOG.md` y actualiza la guía afectada. Si cambia la instalación o el punto de entrada, actualiza `README.md`. Mantén esta cabecera breve y revisa su contenido al cambiar el alcance o la arquitectura.

Para mecánicas nuevas, separa las reglas de la entrada, el dibujo y el diálogo. Mantén una sola fuente de verdad para cada estado y usa la misma acción para teclado y botones cuando hagan lo mismo. Comprueba el recorrido normal y los casos de error recuperables.

Regla visual del usuario: cuando una escena necesite ilustraciones, genera imágenes de calidad e intégralas como recursos del proyecto; no sustituyas el arte final por formas geométricas provisionales. Registra recursos, prompts y cambios en los `.md`. Percy representa al rover Perseverance en la ficción; Pluto es otro personaje, el asistente ficticio del refugio.

Trabaja en ramas por tarea y acuerda con el equipo los cambios al contrato de relevo. Antes de integrar, abre el proyecto, prueba los accesos, las cinco noches y el regreso; comprueba guardado y reanudación. Incluye en el PR los archivos de Godot junto a sus `.uid` y `.import` asociados. El binario local y la caché `.godot/` se excluyen.
