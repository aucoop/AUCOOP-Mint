# AUCOOP Mint

Un ordinateur portable donné arrive, quelqu’un efface le disque, puis le vrai travail commence : quel navigateur choisir, quelle suite bureautique installer, pourquoi tout est en anglais, où sont passés les codecs. AUCOOP Mint règle tout cela avec une seule commande, afin que la personne qui reçoit l’ordinateur trouve une machine déjà prête.

![Le bureau AUCOOP Mint](assets/desktop.jpg)

Ce n’est pas une nouvelle distribution. En dessous, c’est un Linux Mint 22.3 Cinnamon ordinaire qui continue de recevoir les mises à jour de Mint. Nous retirons le superflu, installons Chrome et une suite bureautique, rendons le bureau familier aux personnes habituées à Windows et ajoutons deux outils utiles lorsque la connexion est mauvaise ou absente : une Wikipédia hors ligne et un petit assistant IA qui tourne sur l’ordinateur.

> Les captures d’écran sont en anglais. AUCOOP Mint et son programme d’installation s’affichent en français lorsque le système est configuré en français.

## Le parcours complet

```mermaid
flowchart LR
    A[Clé USB Linux Mint] -->|installation normale de Mint<br/>~15 min| B[Mint 22.3 tout neuf]
    B -->|une commande<br/>~2 min| C[AUCOOP Mint]
    C -->|redémarrage| D[AUCOOP Welcome<br/>5 étapes guidées]
    D -->|mises à jour, codecs<br/>et options| E[Prêt à être remis]
```

Deux de ces cases seulement demandent votre présence au clavier. Le reste se fait tout seul.

## Par où commencer

Si vous préparez un ordinateur pour quelqu’un, suivez le [démarrage rapide](deployment/quick-start.md). Prévoyez une demi-heure entre la clé USB et la machine terminée ; la qualité de la connexion et l’âge de l’ordinateur détermineront la durée réelle.

L’installation est déjà faite et vous vous demandez à quoi servent les icônes ? La page [Ce qui est installé](use/index.md) présente le bureau. L’[assistant IA hors ligne](use/offline-ai.md) dispose de sa propre page, car quelques explications s’imposent.

Pour modifier les scripts, commencez par l’[architecture](architecture/index.md), puis lisez [Tests dans une machine virtuelle](testing/index.md). Tout repose sur des scripts shell et un peu de Python ; l’ensemble se lit en un après-midi.

## À qui s’adresse le projet

AUCOOP remet en état des ordinateurs portables donnés et les envoie [là où ils sont nécessaires](https://aucoop.upc.edu/projectes-internacionals/), principalement dans des écoles. Beaucoup disposent d’une connexion lente, paient au mégaoctet ou restent plusieurs jours sans internet. Cette réalité guide presque tous nos choix : le programme indique le volume à télécharger avant de commencer, peut attendre la nuit et ses deux fonctions principales marchent sans réseau.

Il parle anglais, espagnol, catalan, français et portugais, selon la langue choisie lors de l’installation de l’ordinateur.
