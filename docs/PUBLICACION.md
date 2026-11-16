# GitHub, Firebase Hosting y Render

| Recurso | Uso |
| --- | --- |
| [Repositorio privado](https://github.com/JULINHO-22/horizonte-rojo) | Código, imágenes y documentación. El propietario invita a los colaboradores por su usuario de GitHub. |
| [Rama main](https://github.com/JULINHO-22/horizonte-rojo/tree/main) | Fuente del proyecto de Godot. Las tareas se trabajan en ramas y se revisan en PR. |
| [Rama render-web](https://github.com/JULINHO-22/horizonte-rojo/tree/render-web) | Exportación jugable en `public/`. Un cambio en `main` por sí solo no actualiza Render. |
| [Juego público en Firebase](https://horizonte-rojo-game.web.app/) | Enlace de la exportación optimizada. Abre sin cuenta. |
| [Juego público en Render](https://horizonte-rojo.onrender.com/) | Enlace del despliegue alternativo. |
| [Panel del servicio](https://dashboard.render.com/static/srv-dbkvu895efls73fr6f5g) | Historial y estado de despliegue. Requiere acceso al espacio de Render. |

## Publicar en Firebase

El proyecto `horizonte-rojo-game` usa Firebase Hosting. La portada de Umbra al anochecer ofrece las cinemáticas finales y el banco de mecánicas en «Escenas extra». El motor y el paquete se descargan en paralelo con progreso visible. Al llegar al 100 %, la portada distingue la apertura de la partida de la descarga. Algunos fondos usan compresión de textura con calidad 0,90 y los sprites conservan transparencia. Se limita el tamaño importado de los sprites sobredimensionados. Los archivos `index.*` se revalidan para que el navegador use el paquete de la versión publicada. Desde la raíz del repositorio, genera la exportación Web de Godot, inicia sesión con una cuenta con acceso al proyecto y ejecuta `firebase deploy --only hosting --project horizonte-rojo-game`. [Guía oficial de Firebase Hosting](https://firebase.google.com/docs/hosting/quickstart).

`firebase.json` publica `build/web` y omite los metadatos de importación de Godot. Comprueba el enlace público con un perfil de navegador limpio. Inicia la expedición, revisa los paneles con Pluto y recarga. El guardado se conserva por dirección y por perfil del navegador.

El repositorio no contiene un flujo de GitHub Actions para Firebase. Subir cambios a `main` actualiza el código. Hosting recibe la compilación cuando se ejecuta el despliegue con una cuenta autorizada. Para automatizar ese paso hace falta configurar la integración y sus credenciales. [Integración oficial de Firebase con GitHub](https://firebase.google.com/docs/hosting/github-integration)

La optimización redujo `index.pck` de 36,4 MB a 16,3 MB y la portada de 2,9 MB a 366 KB. En Edge, con una conexión simulada de 20 Mb/s, un perfil limpio y compresión HTTP del motor, la apertura pasó de 26 a 15 segundos.

La cinemática inicial usa texturas PNG pixel art empacadas por Godot dentro de `index.pck`; Firebase no necesita servirlas como archivos independientes ni habilitar un códec de video. El preset incluye el conjunto `*PixelArt.png` activo de `assets/NarrativaInicio/` y excluye los fondos, naves y variantes realistas anteriores que ya no consume el código.

La revisión del 14 de noviembre de 2026 exportó el preset Web con Godot 4.7.2 y cargó la portada y la cinemática desde un servidor HTTP local. Se verificaron el acople inicial y el módulo aterrizado. Esto comprueba el arte dentro del paquete que utiliza Firebase; no implica un despliegue nuevo al sitio público.

## Configuración de Render

Render usa un **Static Site** conectado a `JULINHO-22/horizonte-rojo` con la credencial GitHub del propietario. Despliega desde `render-web`, con raíz del repositorio y directorio de publicación `public`. El comando de construcción comprueba la exportación preparada por el equipo.

```sh
test -s public/index.html && test -s public/index.wasm && test -s public/index.pck
```

## Publicar una nueva versión

1. Integra y prueba la revisión de código que se va a publicar. Anota su commit.
2. Instala las plantillas de exportación de Godot 4.7.2. Desde la raíz del proyecto, ejecuta `./web/exportar.ps1 -Godot "<ruta al ejecutable de consola de Godot>"`. El script exporta a `build/web`, copia la portada y crea el ZIP.
3. En un checkout separado de `render-web`, extrae a `public` el contenido de `build/Red-Horizon-Web.zip`. El archivo incluye el HTML, el cargador `.js`, el motor, los datos, el audio, `index.png`, `portada-umbra.webp` y las fuentes Barlow con su licencia.
4. Haz commit en `render-web` y sube la rama. Revisa el despliegue en Render y comprueba que muestra **Live**. Si el despliegue automático está desactivado, el propietario puede lanzar el despliegue manual del último commit.
5. Abre la URL pública, pulsa **Iniciar expedición** y confirma que carga la escena de aterrizaje.

Si la portada abre pero el juego no arranca, comprueba primero que `index.wasm` e `index.pck` responden y pertenecen a la misma exportación. El preset usa WebGL 2 sin hilos y aloja los archivos del juego en el mismo sitio. El sitio público sirve la compilación, incluida el arte que necesita para funcionar. El código fuente editable se comparte mediante el repositorio privado.

## Ilustración y tipografía de la portada

`web/estaticos/portada_umbra.png` se generó con ImageGen integrado usando `assets/refugio_horizonte.png` como referencia de arquitectura. La exportación redimensiona la imagen y la guarda como WebP. Barlow y Barlow Condensed se sirven desde la propia exportación junto con su licencia SIL OFL. [Barlow](https://fonts.google.com/specimen/Barlow) · [Barlow Condensed](https://fonts.google.com/specimen/Barlow+Condensed).

> video-game-cover | Create a brand-new 16:9 editorial cover illustration for the retro 2D pixel-art game Red Horizon. Use the supplied Umbra exterior as reference for the real game's cream alloy habitat, copper stripes and teal windows only. Recompose from a low viewpoint near the Martian soil at blue hour after sunset. On the right, a cream-and-rust pressure habitat glows from the open airlock and a greenhouse dome, with solar wings and a tiny rover. Three small astronauts in cream suits, one with purple accents leading and one with teal accents, are walking toward the lit door, seen from behind, recognizable silhouettes. Place the door, group and small amber pools on the ground around 68% to 82% horizontal, 50% to 72% vertical; that crop should read independently on a phone. Behind them show a small pale rising sun and terraced rust mesas fading into blue plum twilight, with a hint of copper dust in the wind. The LEFT 43 percent is naturally dark uncluttered indigo rock and empty muted sky for separately typeset cream website copy; keep the horizon low contrast there. Use a disciplined palette of midnight eggplant, muted rust, apricot, bone alloy, and restrained mineral green lights. Sophisticated restrained cinematic lighting, visibly square hand-placed pixels, intentional luminous silhouettes, real 16-bit console environment, polished not photorealistic or painterly. A single continuous landscape, no typography or glyphs of any kind, no logos, no UI, no watermarks.

## Mantener estable la versión de evaluación

- Usa el **Static Site** existente. Render sirve sus archivos por CDN. El apagado por inactividad de 15 minutos corresponde a los [Web Services gratuitos](https://render.com/docs/free#spinning-down-on-idle).
- En Render, **Settings → Auto-Deploy → Off** conserva la versión publicada mientras el equipo prepara cambios. Cuando tengan una compilación verificada en `render-web`, usa **Manual Deploy → Deploy latest commit**. Comprueba **Deploys** para saber si una descarga nueva coincide con una publicación. [Opciones de despliegue](https://render.com/docs/deploys#configuring-auto-deploys).
- El juego restaura el último punto desde el almacenamiento del navegador de esa dirección. Si el navegador descarta la pestaña o el usuario vuelve a abrir la URL, arranca Godot y recupera la partida cuando el almacenamiento está disponible. Los datos locales dependen del dominio y del perfil del navegador. [Persistencia de Godot Web](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html#using-cookies-for-data-persistence).
