# Prompt para el Codex de cada compañero

Completa el número del día y pega este prompt en el Codex del compañero. Adjunta **Flujo de los cinco días y finales** y **Mecánicas básicas (3)** para resolver dudas del encargo. Las reglas de recursos que ya usa el código se explican en el contrato de este repositorio.

```text
Implementa únicamente el Día [NÚMERO] de Horizonte Rojo. Trabaja con Godot 4.7.2.
Lee AGENTS.md, docs/MECANICAS-BASICAS.md y la sección de tu día en el PDF
Flujo de los cinco días y finales. Lee solo las reglas aplicables del otro PDF.
Si los documentos se contradicen, conserva el contrato que usa el código y anota
la diferencia en docs/dias/DIA-[NÚMERO].md para que la resuelva el equipo.

Parte de la rama compartida codex/mecanicas-basicas, o del commit integrado
que te indique el coordinador. Crea tu propia rama codex/dia-[NÚMERO].
Antes de editar, revisa git status. Conserva los cambios que ya estén en la carpeta.

Crea tu escena y scripts dentro de scenes/dias/dia_[NÚMERO]/. Coloca las
imágenes y sonidos propios dentro de assets/dias/dia_[NÚMERO]/. Puedes añadir
archivos en esas carpetas e instanciar escenas del juego que ya existen.
Usa referencias a recursos existentes y conserva sus archivos .uid y .import.
Crea el Markdown docs/dias/DIA-[NÚMERO].md con el plan y después con la entrega.

Usa scripts/mecanicas/recursos_mision.gd mediante los métodos documentados.
Diseña tu escena para recibir la instancia de recursos que le pasa el
controlador. Para probar con F6, puedes crear una instancia local de prueba
desde tu propia escena. Mantén un solo reloj por partida. Tu día informa
qué decisión tomó el jugador, qué cambió y si su objetivo se completó.
Devuelve los estados que el siguiente día necesita, sin cambiar de día solo
ni elegir la cinemática de cierre. Para cada acción comprueba el resultado
antes de mostrar éxito. Prueba también cuando falten recursos.

Los archivos compartidos son responsabilidad del coordinador. Esto incluye
project.godot, la escena de entrada, mapa y cámara, cinemáticas, guardado,
módulo de recursos, exportación web y Firebase. Si necesitas ampliar alguno,
anota la necesidad, el archivo y el comportamiento esperado. Propón el cambio
aparte. Resuelve mientras tanto el trabajo local que no dependa de ese cambio.

Haz que la actividad se entienda viendo y usando el escenario. Indica costo
y consecuencia antes de elegir. Usa lenguaje cotidiano, el estilo pixel art
y diálogos breves. Si utilizas un dato de la NASA, documenta fuente oficial,
dato aplicado y qué valores son una simplificación del juego. Describe el arte
del PDF que se reutiliza y lo que necesita un recurso nuevo.

Verifica tu escena con F6, la prueba común de recursos y git diff --check.
En tu Markdown explica qué recibe el día, qué acciones y consecuencias ofrece,
qué entrega a los otros días, fuentes, archivos modificados y cómo reproducir
las pruebas. Revisa el diff completo antes de subir. Envía un PR con tu rama
para revisión del coordinador. Integra y publica desde una revisión conjunta.
```

El coordinador mantiene una sola base para los cinco encargos. Cuando una decisión afecte otro día, el responsable actualiza el Markdown de su entrega y el coordinador incorpora el acuerdo al contrato común. Las cinemáticas y el despliegue se revisan aparte.
