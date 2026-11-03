# GitHub y Render

| Recurso | Uso |
| --- | --- |
| [Repositorio privado](https://github.com/JULINHO-22/horizonte-rojo) | Código, imágenes y documentación. El propietario invita a los colaboradores por su usuario de GitHub. |
| [Rama main](https://github.com/JULINHO-22/horizonte-rojo/tree/main) | Fuente del proyecto de Godot. Las tareas se trabajan en ramas y se revisan en PR. |
| [Rama render-web](https://github.com/JULINHO-22/horizonte-rojo/tree/render-web) | Exportación jugable en `public/`. Un cambio en `main` por sí solo no actualiza Render. |
| [Juego público](https://horizonte-rojo.onrender.com/) | Enlace para compartir y jugar sin cuenta de GitHub. |
| [Panel del servicio](https://dashboard.render.com/static/srv-dbkvu895efls73fr6f5g) | Historial y estado de despliegue. Requiere acceso al espacio de Render. |

## Configuración del sitio

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
