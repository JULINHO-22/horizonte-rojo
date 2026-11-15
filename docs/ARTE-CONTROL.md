# Sala de Control

La sala utiliza `assets/control_supercomputadora.png`. Conserva las tres puertas del mapa y concentra el equipo en una sola máquina. La pantalla y los indicadores forman parte de la ilustración. Las lecturas de energía, agua y oxígeno se implementarán con las mecánicas diarias del equipo.

La textura de referencia fue `assets/control_pasillos.png`. ImageGen integrado conservó el perímetro y generó la máquina en el centro. La huella en `EQUIPOS` evita que se pueda caminar sobre la computadora. El anillo de interacción se sitúa delante, a la altura del pasillo libre.

## Prompt de ImageGen

Precise asset edit for 2D pixel art top-down game. Preserve exactly the reference image's rectangular outer footprint, viewpoint, outer walls, left and right doorways at midheight, bottom centered doorway, orange and cream wall details, gray square floor grid and all framing. Replace only the row of computers and chairs along the upper wall with blank utility wall and matching dark gray floor. Add ONE substantial freestanding retro NASA supercomputer on upper-central FLOOR, centered horizontally with silhouette from 37% to 63% image width and from 24% to 44% image height; one unified curved cyan display with three small amber/cyan/blue indicator zones and heavy cream-and-graphite compute housing, facing bottom of image, equipment integrated as a single object, no chair. Keep its bottom edge ABOVE 44% so all space from 46% to the foreground/bottom door is uninterrupted WALKABLE original tiled floor. Keep both left and right side door landings and aisle completely unobstructed. No other PCs or screen banks, no people, no text. Preserve the existing floor texture below the new central machine and exact outer edge geometry for engine overlay. Very crisp detailed pixel art consistent with reference. Output same aspect ratio as reference, edge to edge.

## Iconos generados para las lecturas

ImageGen integrado generó `assets/instrumentos_control.png`. El arte tiene transparencia y bordes suaves. El código toma cuatro regiones del atlas y coloca cada icono según el estado de la reserva. La gota conserva una silueta atenuada y muestra la porción inferior en azul. El cambio de nivel se anima al subir o bajar.

Prompt:
Clean game instrumentation icon atlas, transparent alpha, square canvas divided into EXACT four equally sized imaginary quadrants, NO dividing lines. Four separate large crisp icons each centered precisely in its own quadrant with ample transparent gaps, visually clear when 14px tall: TOP LEFT a graceful solid golden yellow lightning bolt, TOP RIGHT a round glossy soft cyan oxygen bubble with small white highlight, BOTTOM LEFT a solid smooth symmetric light blue water droplet silhouette, BOTTOM RIGHT a small ripe red tomato with muted green stem. Rounded precise edges, subtle controlled bevels, consistent premium futuristic control panel icon set, no visible pixel grid, no stair steps, no glow beyond silhouettes, no text, no background, no extra shapes, no labels. Droplet must be completely opaque blue inside its shape for clipping and transparent outside.
