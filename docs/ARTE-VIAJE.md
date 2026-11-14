# Arte generado del viaje y Percy

## Entrega 2026-11-14
Se usa el generador integrado de imágenes (ImageGen), sin CLI ni clave API. Recursos copiados al proyecto; conservar sus archivos .import. Los fondos son ilustraciones, no fotografías ni mapas científicos de la NASA.

| Recurso | Uso |
| --- | --- |
| assets/viaje_tierra.png | Fondo orbital de la Tierra, con océanos, continentes, nubes y atmósfera. |
| assets/viaje_marte.png | Fondo de aproximación a Marte, con relieve y cráteres. |
| assets/nave_transferencia.png | Capa transparente independiente: cápsula del juego acoplada a módulo de servicio ficticio. |
| assets/percy_perseverance.png | Representación artística de Perseverance; sustituye el SVG provisional. No es un plano técnico. |

La salida y llegada usan dos tomas con paneo y acercamiento moderados; la nave sigue curvas y cambia de tamaño. El corte a negro central indica meses de viaje. No se dibujan los planetas con círculos. El regreso invierte los fondos. La cápsula que aterriza conserva su identidad; el módulo de transferencia no representa una nave NASA existente.

## Percy no es Pluto
Percy es el apodo de Perseverance: lanzado el 30 de julio de 2020 y aterrizado el 18 de febrero de 2021. Es un rover científico, no un robot humanoide. En el guion habla como recurso narrativo; no se afirma que hable realmente. Pluto es un asistente ficticio independiente, con su propio arte y papel interior.
Fuente: [NASA, misión Perseverance](https://science.nasa.gov/mission/mars-2020-perseverance/).

El arte de Percy prioriza ruedas, mástil de cámaras, brazo y generador trasero, sin paneles solares. Su representación es estilizada y no debe usarse para inferir medidas o configuración exactas.

## Prompts usados (texto íntegro)

### Tierra
Use case: stylized-concept. Create a premium production-ready 16:9 cinematic BACKGROUND for a polished 2D space exploration game, 1536x864 or wider. View from Earth orbit: Earth fills lower-left two thirds, real recognizable blue oceans, detailed African continental coast and Atlantic, swirling white cloud systems, delicate blue atmospheric limb, night terminator with sparse city lights. Upper right is deep navy almost black space with subtle small stars and ample empty space for an independently animated spacecraft. Warm sunlight from upper left. Rich hand-painted realistic digital matte painting, precise fine detail, nuanced volumes, crisp edges, beautiful atmospheric depth; compatible with detailed retro science fiction game backgrounds, NOT flat vector shapes, NOT simplistic circles, NOT childish drawing, NOT blurry. The Earth must look natural, not made of geometric spots. No spacecraft, no rockets, no astronauts, no planets other than Earth, no orbital lines, NO TEXT, no interface, no logos, no watermark. Full bleed landscape.

### Marte
Use case: stylized-concept. Production-ready cinematic 16:9 2D space-game background, high resolution. Close orbital view of MARS. Large red ochre planet dominates right two-thirds and lower frame, curved limb and convincing spherical lighting, intricate cratered surface and dramatic Valles Marineris-like canyon geography, thin subtle dusty atmospheric edge, pale small polar area near upper rim, NO oceans, NO green vegetation, NO Earth clouds, NO cities. Left upper third and upper margin deep almost black navy space with sparse fine stars, left side ample uncluttered space for a separately animated spacecraft approaching Mars. Warm sunlight from upper left. Premium meticulously hand-painted realistic digital matte painting, crisp rich natural geological texture, cinematic light, sophisticated detailed 2D adventure-game art, no crude geometric shapes, no vector infographic, no childish cartoon, no blur. No spaceship, no people, no text, no labels, no trajectory lines, no interface, no logos, no watermark. Match an Earth orbit cinematic with detailed realistic clouds and blue atmospheric limb in rendering sophistication. Full bleed landscape.

### Nave
Referencia de identidad: assets/nave_llegada.png. Salida solicitada con transparencia.
Use case: stylized-concept. Input image is a STYLE AND IDENTITY REFERENCE of this game's landing capsule, not the desired composition. Generate a beautiful high-detail 2D game sprite of the INTERPLANETARY TRANSFER SPACECRAFT carrying this same cream-colored capsule with purple stripe and cyan cockpit. Three-quarter side view, horizontal, pointing toward the RIGHT. Capsule is attached at the FRONT right of a believable longer silver service module with cylindrical propellant tanks, small symmetrical blue solar arrays, thin antenna, and an engine nozzle at rear left. Capsule landing legs and entry ladder are stowed and folded, no feet extended. Entire spacecraft visible with margin. Premium detailed retro adventure digital game art, carefully shaded metal plates, crisp readable silhouette, realistic engineering-inspired proportions, not 3D game geometry, not crude vector clipart. No long exhaust flame, no floor, NO background, true alpha transparency all around, no colored matte or shadow rectangle, no text, logos, watermarks, people or planets. One spacecraft only; not a sprite sheet.

### Percy
Salida solicitada con transparencia.
Use case: scientific-educational. Generate a single clean transparent-background 2D game character sprite representing NASA's actual PERSEVERANCE Mars rover, nicknamed Percy. Recognizable six individually treaded metal wheels on rocker-bogie suspension, cream white rectangular rover body, tall camera mast with rectangular dual camera head, robotic sampling arm folded at front, rear cylindrical finned radioisotope power generator. NO solar panels: Perseverance is nuclear powered. No humanoid face, no cartoon eyes, no smile, no cabin or windshield, no passenger seats, no truck, no antenna dish giant, no wheels like rubber car tires. Three-quarter side view facing RIGHT, entire rover visible, mechanical silhouette legible at 150 pixel width. Detailed shaded premium retro 2D adventure-game sprite, hand-painted precision with restrained pixel-style crisp edges, realistic engineering-inspired proportions, cream metal and gray aluminum, dark charcoal wheels and copper wiring. Warm rim light, cool cyan subtle lens reflections. Not flat vector, not geometric placeholder, not low-poly. Accurate visual identity more important than embellishments. True alpha transparency, no ground, no background, no shadow rectangle, no text, labels, logos, watermark. One rover only.

## Alcance
Solo se modifica arte, animación de viaje y la identificación de Percy. No se implementan actividades diarias. El lanzamiento desde tierra, la inserción orbital detallada y los científicos animados del final siguen pendientes.
