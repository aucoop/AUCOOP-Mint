# AUCOOP Mint

Llega un portátil donado, alguien borra el disco y entonces empieza el trabajo de verdad: qué navegador instalar, qué paquete ofimático elegir, por qué está todo en inglés o dónde se han metido los códecs. AUCOOP Mint se ocupa de todo con un solo comando, para que quien reciba el equipo encuentre algo que ya funciona.

![El escritorio de AUCOOP Mint](assets/desktop.jpg)

No es una distribución nueva. Debajo hay un Linux Mint 22.3 Cinnamon normal, que sigue recibiendo sus actualizaciones de Mint. Nosotros quitamos lo que sobra, instalamos Chrome y un paquete ofimático, dejamos un escritorio familiar para quien venga de Windows y añadimos dos recursos útiles cuando la conexión es mala o no existe: una Wikipedia sin conexión y un pequeño asistente de IA que se ejecuta en el propio portátil.

> Las capturas están en inglés. AUCOOP Mint y el instalador aparecerán en español cuando el sistema esté configurado en español.

## El recorrido completo

```mermaid
flowchart LR
    A[Memoria USB con Linux Mint] -->|instalación normal de Mint<br/>~15 min| B[Mint 22.3 recién instalado]
    B -->|un comando<br/>~2 min| C[AUCOOP Mint]
    C -->|reiniciar| D[AUCOOP Welcome<br/>5 pasos guiados]
    D -->|actualizaciones, códecs<br/>y extras| E[Listo para entregar]
```

Solo dos de esas cajas necesitan que estés delante del teclado. El resto trabaja solo.

## Por dónde empezar

Si estás preparando un portátil para otra persona, ve a la [guía rápida](deployment/quick-start.md). Reserva media hora desde la memoria USB hasta el equipo terminado; la conexión y la edad del portátil decidirán el tiempo real.

¿Ya está instalado y no sabes para qué sirve cada icono? [Qué incluye](use/index.md) explica el escritorio. El [asistente de IA sin conexión](use/offline-ai.md) tiene su propia página porque merece una explicación más detallada.

Si vas a tocar los scripts, empieza por [Arquitectura](architecture/index.md) y sigue con [Pruebas en una máquina virtual](testing/index.md). Todo está hecho con shell y un poco de Python; se puede leer entero en una tarde.

## Para quién es

AUCOOP reacondiciona portátiles donados y los envía [allí donde hacen falta](https://aucoop.upc.edu/projectes-internacionals/), sobre todo a escuelas. Muchas tienen una conexión lenta, pagan por megabyte o pasan días enteros sin internet. Eso condiciona casi todas las decisiones: el instalador indica cuánto va a descargar antes de empezar, puede esperar hasta la noche y sus dos funciones principales trabajan con la red desconectada.

Habla inglés, español, catalán, francés y portugués, y utiliza el idioma elegido al instalar el portátil.
