# Finales en la Tierra

Las dos cinemáticas son escenas independientes de Godot. Abre la escena elegida y pulsa **F6**. El viaje dura seis segundos y se puede adelantar con **Esc** o con el botón de la esquina. El regreso muestra solo la cápsula. El diálogo usa nombre seguido de dos puntos y texto sobre sombra difuminada, junto a cada interlocutor. **Salir al menú** vuelve a la portada. En el navegador se recarga la portada para poder elegir otra vista previa. Tras la ceremonia, la medalla entra animada y aparece **¡Has ganado!**. Al terminar aparece **Repetir final**. La portada web también permite abrir cada cinemática mediante sus dos botones de vista previa.

| Escena | Secuencia |
| --- | --- |
| `scenes/final_incompleta.tscn` | Regreso a la Tierra, entrada al hangar y recepción de Control. La tripulación vuelve con los suministros justos. Control reconoce que volvieron a salvo y explica que todavía falta comprobar parte de los hallazgos. |
| `scenes/final_cumplida.tscn` | Regreso y recepción en el mismo hangar. Control confirma que el equipo completó la misión. La directora del programa entrega la Medalla Horizonte a Nora, Iris y Teo en una ceremonia. El último diálogo conecta el logro con la siguiente tripulación. |

Las dos escenas comparten `scripts/final_tierra.gd` y la animación de `viaje_espacial.gd`. La propiedad exportada `mision_cumplida` se configura en la escena. Su valor no se calcula dentro de la cinemática. El equipo decidirá los criterios y conectará las escenas cuando estén listas las actividades y las consecuencias de los cinco días. El epílogo provisional sigue siendo el punto de llegada del recorrido actual.

El tercer final queda como requisito pendiente de diseño. Si el equipo determina que ya no se puede continuar por falta de suministros, la tripulación queda varada en Marte y aparece una pantalla negra con «Game Over». Los días y el estado de campaña determinarán cuándo ocurre.

## Recursos visuales

ImageGen integrado generó cuatro PNG para `assets/Finales/`. El motor anima el regreso, la caminata con las hojas existentes de Nora, Iris y Teo, y la entrega de tres medallas. La directora es un personaje ficticio del programa espacial.

### hangar.png

Production background 16:9 for a serious all-ages 2D pixel art Mars adventure game, visibly hand-placed pixel texture and clean material clusters, sophisticated depth. Earth space agency recovery hangar, interior at blue hour with warm practical lamps. The open hangar at back reveals blue ocean sky and a strip of green grass on Earth, a small cream landing pod with purple stripe and turquoise glass parked in far middle distance. Three people will be composited later. Entire lower half is empty dark cool gray floor with perspective markings, free of furniture and obstacles, for sprites to walk; no foreground obstacles. Along edges only a sealed sample rack and testing equipment, large window above. Quiet and relieved, no damage, no dystopia. Medium-wide eye-level side-scroller camera. No people, no text, logos, letters, banners, panels or UI. Detailed cohesive retro pixel art.

### ceremonia.png

Production background 16:9 for a detailed 2D pixel art Mars adventure game, crisp deliberate pixel clusters, not photographic. An elegant Earth space agency awards hall, warm amber stage lighting through tall windows, teal walls, copper trim, three stage spotlights, abstract Earth and Mars orbital motif carved into a distant circular wall sculpture. Formal but warm and believable public science ceremony. Empty stage with clear dark wood flooring and feet contact line in lower half to place 4 character sprites later, no podium or furniture across stage, no crowds or people, empty foreground. The stage floor fills bottom 32 percent of the image with space to walk. Eye-level side-scroller angle, depth, expressive highlights, contrast. No text, flags, symbols of specific countries, logos, lettering, watermark or UI.

### directora.png

Single isolated full body transparent sprite, hand-crafted detailed 2D pixel art for Horizonte Rojo retro space adventure. Mature woman flight director, short salt and pepper hair, friendly composed expression, teal navy civilian agency dress uniform with cream collar and small amber pin, no text logos or flags. Three quarter standing facing LEFT, both feet visible, right arm gently extended forward at chest height to greet astronauts or present an award, empty hand, other arm relaxed. Clear reassuring body posture. Ground-level eye-line, realistic human proportions with clean clear pixel clusters and carefully dithered shading, no outlines around empty space. Transparent alpha, no floor or shadows, no backdrop, one figure only, entire body fully inside the frame.

### medalla.png

A single small unobstructed game sprite of a gold space exploration medal hanging from a V-shaped short deep teal ribbon, medallion stamped with a tiny simple relief of two planets. Front facing orthographic. Detailed crisp 2D pixel art with intentional hard pixel clusters and clear gold silhouette for use at 24 pixels high. Transparent alpha background, no lettering, no people, no outline box, no glow, no floor. Single object centered with clear margin.
