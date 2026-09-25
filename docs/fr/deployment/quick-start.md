# Préparer un ordinateur

Commencez avec un ordinateur portable sur lequel Linux Mint 22.3 Cinnamon vient d’être installé, sans rien d’autre. Il faut le mot de passe du compte et une connexion internet. Prévoyez une demi-heure ; les téléchargements occupent l’essentiel de ce temps.

Vous préférez regarder d’abord ? Cette vidéo de 5 minutes montre toutes les étapes de cette page, du téléchargement de Linux Mint jusqu’à l’ordinateur prêt. Elle n’a pas de voix : gardez les sous-titres activés (anglais, espagnol ou catalan).

<div style="position:relative;aspect-ratio:16/9;width:100%;margin:1em 0 2em">
  <iframe src="https://www.youtube-nocookie.com/embed/B49QS7KgN3Y?cc_load_policy=1&amp;cc_lang_pref=en&amp;hl=fr&amp;rel=0" title="AUCOOP Mint video guide" loading="lazy" style="position:absolute;inset:0;width:100%;height:100%;border:0" allow="encrypted-media; picture-in-picture; fullscreen" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
</div>

## 1. Installer Linux Mint

Rien de particulier : utilisez le programme d’installation normal de Mint depuis une clé USB.

Deux choix auront leur importance. La langue sélectionnée devient celle d’AUCOOP Mint ; si l’ordinateur part dans une école au Mozambique, choisissez le portugais dès maintenant. Vous pouvez laisser la case « codecs multimédias » décochée, car AUCOOP Welcome les installera plus tard.

## 2. Exécuter une commande

Ouvrez un terminal sur la machine fraîchement installée et collez ceci :

```bash
wget -qO- https://raw.githubusercontent.com/aucoop/AUCOOP-Mint/master/boot.sh | bash
```

Avant d’appuyer sur **Entrée**, l’écran doit ressembler à ceci :

![La commande d’installation d’AUCOOP Mint dans un terminal](../assets/installer-command.jpg)

Le mot de passe de l’ordinateur est demandé une fois. Le curseur ne bouge pas pendant la saisie ; Linux n’affiche pas le mot de passe, même sous forme de points. Appuyez sur **Entrée** lorsque vous avez terminé.

Le programme prend ensuite le relais :

![L’installation en cours](../assets/installer-running.jpg)

Sept étapes apparaissent, chacune avec son chronomètre. Une machine de test propre a terminé en 1 minute et 44 secondes ; un portable ancien ou une connexion lente prendra davantage de temps. OnlyOffice est généralement l’étape la plus longue, car son téléchargement est volumineux.

Appuyez sur **D** à tout moment pour voir les commandes exécutées :

![Les détails techniques de l’installation](../assets/installer-details.jpg)

Appuyez de nouveau sur **D** pour revenir à la vue simple. La même sortie est enregistrée dans `~/.local/state/aucoop-mint/install.log`, que ce panneau soit ouvert ou fermé.

À la fin, le programme propose de redémarrer :

![Installation terminée](../assets/installer-done.jpg)

Appuyez sur **Entrée** pour accepter la réponse par défaut, **Y**, et redémarrer. Le nouveau bureau apparaîtra ensuite.

### Vous préférez cloner le dépôt ?

```bash
git clone https://github.com/aucoop/AUCOOP-Mint.git
cd AUCOOP-Mint
git submodule update --init --recursive
bash install.sh
```

Le résultat est identique ; la commande courte effectue simplement le clonage à votre place. Ajoutez `--verbose` si vous préférez la sortie brute à l’écran de progression.

## 3. Terminer dans AUCOOP Welcome

Après le redémarrage, connectez-vous. AUCOOP Welcome s’ouvre automatiquement avec cinq étapes : accueil, préparation, options, enregistrement et fin. La [page suivante](first-boot.md) les explique.

## Ce que la commande modifie

Elle retire Firefox, LibreOffice, Thunderbird, Transmission, Hypnotix, Warpinator et quelques autres logiciels rarement ouverts sur un ordinateur scolaire partagé.

Elle installe Google Chrome, OnlyOffice avec des lanceurs nommés Word, Excel et PowerPoint, puis ajoute Flathub au gestionnaire de logiciels.

Elle change le thème, le fond d’écran, le pointeur, la barre des tâches, ses applications épinglées et le bouton du menu. Elle désactive aussi l’écran de bienvenue de Mint pour éviter deux assistants au premier démarrage.

Les mises à jour du système, les codecs, les pilotes et les options restent pour plus tard. AUCOOP Welcome s’en charge afin que vous puissiez choisir quand consommer la bande passante.

## Une deuxième exécution ne pose aucun problème

Le programme peut être relancé sans risque. Les étapes terminées sont ignorées ou refaites sans dommage. Si un téléchargement s’est interrompu ou si vous avez un doute, exécutez de nouveau la même commande.

## En cas d’échec

L’écran d’erreur indique l’étape concernée, suggère une cause et affiche les dernières lignes du journal. Neuf fois sur dix, le réseau est responsable. Consultez le [dépannage](../troubleshooting.md) pour les cas réellement rencontrés.

## Conditions requises

Linux Mint 22.x Cinnamon, une connexion fonctionnelle et une exécution depuis le compte normal du bureau. Ne lancez pas le script en tant que root : il le refuse, car une grande partie du travail concerne les réglages de votre compte.
