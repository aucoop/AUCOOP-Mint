# AUCOOP Mint

Arriba un portàtil donat, algú n’esborra el disc i aleshores comença la feina de debò: quin navegador hi posem, quin paquet ofimàtic triem, per què tot és en anglès, on han anat a parar els còdecs. AUCOOP Mint se n’ocupa amb una sola ordre, perquè la persona que rebi l’ordinador trobi una màquina que ja funciona.

![L’escriptori d’AUCOOP Mint](assets/desktop.jpg)

No és una distribució nova. A sota hi ha un Linux Mint 22.3 Cinnamon normal, que continua rebent les actualitzacions de Mint. Nosaltres traiem el que sobra, instal·lem Chrome i un paquet ofimàtic, deixem un escriptori familiar per a qui ve de Windows i hi afegim dues eines útils quan internet va malament o no n’hi ha: una Viquipèdia sense connexió i un petit assistent d’IA que s’executa al mateix portàtil.

> Les captures de pantalla són en anglès. AUCOOP Mint i l’instal·lador es mostraran en català quan el sistema estigui configurat en català.

## Tot el recorregut

```mermaid
flowchart LR
    A[Memòria USB amb Linux Mint] -->|instal·lació normal de Mint<br/>~15 min| B[Mint 22.3 acabat d’instal·lar]
    B -->|una ordre<br/>~2 min| C[AUCOOP Mint]
    C -->|reinici| D[AUCOOP Welcome<br/>5 passos guiats]
    D -->|actualitzacions, còdecs<br/>i extres| E[A punt per lliurar]
```

Només cal ser davant del teclat en dues d’aquestes caixes. La resta funciona sol.

## Per on començo

Si prepares un portàtil per a una altra persona, ves a la [guia ràpida](deployment/quick-start.md). Reserva mitja hora des de la memòria USB fins a tenir la màquina acabada; la connexió i l’edat del portàtil en marcaran el temps real.

Ja està instal·lat i no saps què fa cada icona? [Què hi ha instal·lat](use/index.md) explica l’escriptori. L’[assistent d’IA sense connexió](use/offline-ai.md) té una pàgina pròpia perquè necessita una mica més d’explicació.

Si vols modificar els scripts, comença per l’[arquitectura](architecture/index.md) i continua amb les [proves en una màquina virtual](testing/index.md). Tot és shell i una mica de Python; es pot llegir sencer en una tarda.

## Per a qui és

AUCOOP reacondiciona portàtils donats i els envia [allà on fan falta](https://aucoop.upc.edu/projectes-internacionals/), sobretot a escoles. Moltes tenen una connexió lenta, paguen per megabyte o passen dies sense internet. Aquesta realitat condiciona gairebé totes les decisions: l’instal·lador diu quant vol descarregar abans de començar, pot esperar fins a la nit i les dues funcions principals treballen amb la xarxa desconnectada.

Parla anglès, castellà, català, francès i portuguès, i segueix la llengua triada durant la instal·lació del portàtil.
