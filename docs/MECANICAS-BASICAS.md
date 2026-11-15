# Mecánicas básicas y contrato de los niveles

Esta entrega se basa en **Mecánicas básicas (3)** y **Flujo de los cinco días y finales**. Contiene el modelo, el banco de pruebas y la conexión al recorrido principal. Dentro del refugio se ven las cuatro reservas en tiempo real. Un solo laboratorio de Agua y Oxígeno reúne el filtro azul para purificar hielo y los depósitos verdes para asegurar el aire. Plantas permite sembrar y comer. El [Sol 1](dias/DIA-1.md) obtiene hielo en la expedición. En los soles 2 a 5, el laboratorio ofrece una unidad de hielo de prueba por sol hasta que se definan las actividades.

## Cómo probarlo

En Godot 4.7.2, abre `scenes/pruebas/banco_recursos.tscn` y pulsa **F6**. Elige el polvo e inicia el día. Los botones **+8 s** y **+20 s** hacen avanzar todos los relojes. Prueba recargar el aire, sembrar y comer, o recoger y purificar hielo. Dormir conserva las reservas. Esta escena sirve para que el equipo compruebe reglas y valores sin tener que terminar una misión.

Para automatizar la comprobación, desde la raíz del checkout ejecuta:

```powershell
& "<ruta al ejecutable de consola de Godot 4.7.2>" --headless --script res://tests/recursos_smoke.gd --quit-after 140
```

El resultado esperado incluye `RECURSOS_OK`.

## Reglas implementadas

| Recurso | Inicial provisional / máximo | Regla |
| --- | --- | --- |
| Energía | 9 / 12 | Gana un rayo cada 10, 15 o 20 segundos según el polvo. Durante tormenta la generación es cero. Con batería vacía las acciones con costo eléctrico se rechazan. |
| Agua | 3 / 6 | No hay sed. Con agua a cero, no se pueden cultivar plantas ni recargar oxígeno. El hielo se carga como inventario. Purificar consume un hielo y 2 rayos, y aporta hasta 3 unidades de agua. Si el tanque ya está lleno, la operación se rechaza y conserva el hielo. |
| Oxígeno | 8 / 8 | Pierde una burbuja cada 8 segundos. La recarga normal cuesta 6 rayos y 1 agua, llena el tanque y lo estabiliza hasta dormir. El día 3 admite tanques de emergencia. |
| Alimento | 10 / 10 | Pierde un punto cada 20 segundos. A cero todavía se puede comer antes de dormir. Cultivar cuesta 1 agua más la energía de la ficha. Una bandeja por cultivo. La cosecha se consume de forma explícita cuando está lista. |

| Cultivo | Rayos | Espera | Alimento |
| --- | ---: | ---: | ---: |
| Lechuga | 1 | 15 s | +2 |
| Rábano | 3 | 10 s | +3 |
| Tomate | 2 | 20 s | +3 |
| Papa | 2 | 30 s | +5 |

Dormir con aire sin asegurar, dormir sin alimento o perder todo el oxígeno registra derrota. Dormir correctamente mantiene las barras, el hielo y las bandejas. Al despertar se reinician los intervalos de los relojes y se vuelve a comprobar el aire. Completar la quinta noche detiene el modelo. El valor `terminado` indica cierre del calendario y la futura integración decide qué final corresponde.

Los valores iniciales, la recuperación de hambre antes de dormir, el uso de emergencia del día 3 y el rechazo de la purificación con tanque lleno son decisiones provisionales de balance. Antes de cerrar los días 1 a 5, probar con números las rutas de éxito, emergencia y derrota. Verificar en particular el presupuesto para reparación más oxígeno del día 2 y para hielo, refuerzo y oxígeno del día 4.

## API que usarán los niveles

```gdscript
const Recursos := preload("res://scripts/mecanicas/recursos_mision.gd")

# En un banco local:
var partida := Recursos.new()
partida.iniciar_sol("medio")
partida.activar_oxigeno()
partida.avanzar(15.0)
print(partida.estado().reservas)
```

En campaña, el coordinador crea una instancia por partida, la entrega a cada día y se encarga de abrir y cerrar cada sol. Cada día **recibe la misma instancia** y emite su resultado al controlador. El reloj tiene **un solo dueño**. El controlador llama a `avanzar(delta)` durante juego activo y deja de llamarlo al pausar, dormir o mostrar cinemáticas y explicaciones. Un nivel nunca debe reiniciar la instancia o correr otro reloj de recursos.

| Método | Para qué sirve |
| --- | --- |
| `iniciar_sol()` / `iniciar_sol("tormenta")` | Sin argumento sortea polvo normal. Con argumento fija `bajo`, `medio`, `alto` o `tormenta`. Rechaza iniciar un sol en curso. |
| `estado()` y señal `cambiado` | Lee una copia del estado. Úsalo para dibujar indicadores, actualizar controles o mostrar la causa de derrota. |
| `recoger_hielo(cantidad, energia, deposito, alimento)` y `purificar_hielo()` | La extracción admite un costo de batería y comida y un identificador de depósito de un solo uso por sol. Cada uso del filtro procesa 1 hielo, cuesta 2 de energía y rinde hasta 3 de agua. El nivel comprueba cercanía y si ya se eligió otro depósito. |
| `activar_oxigeno(energia, agua, alimento, perder_cultivos)` | Recarga el aire una vez por sol. Por defecto usa 6, 1 y 0 sin afectar los cultivos. El Sol 3 puede variar los costos y perder las bandejas cuando se prioriza el aire. |
| `usar_tanques_emergencia(energia)` | Solo día 3, antes de asegurar el aire. Costo base de 3 energía, 1 agua y 2 oxígeno. Aporta 2 alimento y habilita el descanso si queda oxígeno. |
| `sembrar(id)` / `comer(id)` | Usa `lechuga`, `rabano`, `tomate` o `papa`. La ficha de costos y tiempos está en `CULTIVOS`. |
| `aplicar_decision(id, cambios)` | Cambios enteros con signo. Se aplican juntos si todos los costos caben. Se registra una vez por sol. La ganancia se limita al máximo. Ejemplo: `{"energia": -4, "alimento": -1}`. |
| `aplicar_perdidas(id, perdidas)` | Evento obligatorio como la tormenta final. Acepta cantidades positivas y puede agotar una barra. Se aplica una vez por sol. |
| `guardar_estado()` / `restaurar_estado(datos)` | Exporta y valida el estado con relojes y decisiones. El futuro controlador lo incluirá en el guardado general. Si ya hay un día activo restaurado, se continúa con su polvo y relojes. |
| `dormir()` | Cierra el día. Devuelve `false` en caso de derrota o si el día no estaba abierto. Lee `estado().derrota` para distinguir ambas situaciones. |

Las acciones devuelven si se aplicaron. La señal se emite después de actualizar el estado. Un resultado completado por un nivel debe usar su propio ID estable y avisar al controlador si deja efectos persistentes como paneles protegidos o refugio reforzado. El contrato de esos efectos, la selección de finales y la conexión con el guardado narrativo se integrarán con el equipo. Ningún día abre o modifica por su cuenta las cinemáticas.

## Ciencia y texto en pantalla

- Polvo y energía. «Con más polvo en el aire, llega menos luz a los paneles». Fuente para la relación: [NASA PDS, Pancam](https://pds.nasa.gov/ds-view/pds/viewProfile.jsp?dsid=MER1%2FMER2-M-PANCAM-5-ATMOS-OPACITY-V1.0).
- Cultivos y luz. «En un invernadero de prueba, el rábano recibió más luz que la lechuga». [NASA OSDR, EDEN ISS](https://osdr.nasa.gov/bio/repo/data/studies/OSD-895) y [NASA NTRS, cultivo de papa](https://ntrs.nasa.gov/citations/19950005536).
- Los rayos, burbujas y segundos son unidades del juego. En el juego principal se podrán mostrar 12 rayos, un tanque con la palabra «Oxígeno» y una gota para el agua. El banco interno usa controles simples para probar el contrato. Las fuentes pueden consultarse como enlaces, sin depender de una API para jugar.

La campaña abre la tablet con **T** y le pasa una copia de las reservas del modelo. La tablet reutiliza el atlas de iconos de `scripts/mecanicas/indicadores_refugio.gd`. Control muestra objetivos y decisiones.
