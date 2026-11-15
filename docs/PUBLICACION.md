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

El proyecto `horizonte-rojo-game` usa Firebase Hosting. Desde la raíz del repositorio, genera la exportación Web de Godot, inicia sesión con una cuenta con acceso al proyecto y ejecuta `firebase deploy --only hosting --project horizonte-rojo-game`. [Guía oficial de Firebase Hosting](https://firebase.google.com/docs/hosting/quickstart).

`firebase.json` publica `build/web` y omite los metadatos de importación de Godot. Comprueba el enlace público con un perfil de navegador limpio. Inicia la expedición, revisa los paneles con Pluto y recarga. El guardado se conserva por dirección y por perfil del navegador.

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
3. En un checkout separado de `render-web`, copia desde `build/web` a `public` el HTML, el cargador `.js`, los dos archivos de audio `.worklet.js`, el motor `.wasm`, el paquete `.pck` y las dos imágenes `index.png` y `portada.png`. Actualiza esos archivos juntos para evitar mezclar versiones.
4. Haz commit en `render-web` y sube la rama. Revisa el despliegue en Render y comprueba que muestra **Live**. Si el despliegue automático está desactivado, el propietario puede lanzar el despliegue manual del último commit.
5. Abre la URL pública, pulsa **Iniciar expedición** y confirma que carga la escena de aterrizaje.

Si la portada abre pero el juego no arranca, comprueba primero que `index.wasm` e `index.pck` responden y pertenecen a la misma exportación. El preset usa WebGL 2 sin hilos y aloja los archivos del juego en el mismo sitio. El sitio público sirve la compilación, incluida el arte que necesita para funcionar. El código fuente editable se comparte mediante el repositorio privado.

## Mantener estable la versión de evaluación

- Usa el **Static Site** existente. Render sirve sus archivos por CDN. El apagado por inactividad de 15 minutos corresponde a los [Web Services gratuitos](https://render.com/docs/free#spinning-down-on-idle).
- En Render, **Settings → Auto-Deploy → Off** conserva la versión publicada mientras el equipo prepara cambios. Cuando tengan una compilación verificada en `render-web`, usa **Manual Deploy → Deploy latest commit**. Comprueba **Deploys** para saber si una descarga nueva coincide con una publicación. [Opciones de despliegue](https://render.com/docs/deploys#configuring-auto-deploys).
- El juego restaura el último punto desde el almacenamiento del navegador de esa dirección. Si el navegador descarta la pestaña o el usuario vuelve a abrir la URL, arranca Godot y recupera la partida cuando el almacenamiento está disponible. Los datos locales dependen del dominio y del perfil del navegador. [Persistencia de Godot Web](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html#using-cookies-for-data-persistence).
