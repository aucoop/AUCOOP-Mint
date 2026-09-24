# Dépannage

Des problèmes réellement rencontrés, avec leur solution.

## Le programme s’arrête à une étape

L’écran d’erreur donne le nom de l’étape, affiche les dernières lignes et indique le journal complet : `~/.local/state/aucoop-mint/install.log`. Relancer la même commande ne présente aucun risque et suffit généralement, car le travail terminé est ignoré.

## « Pas de connexion internet » avant le début

Le programme teste la connexion avant de demander le mot de passe. Connectez la machine, puis relancez. Si le portable se dit connecté mais que le programme n’est pas d’accord, NetworkManager signale probablement un portail captif : ouvrez Chrome, connectez-vous au réseau et réessayez.

## Échec des téléchargements sur un réseau qui inspecte TLS

Nous avons rencontré ce cas sur un réseau équipé de la passerelle Zero Trust de Cloudflare. Tous les téléchargements HTTPS échouaient et `wget` affichait quelque chose comme :

```
ERROR: cannot verify dl.google.com's certificate, issued by
'CN=Gateway CA - Cloudflare Managed G1 ...':
Self-signed certificate encountered.
```

Le réseau déchiffre le trafic puis le signe avec sa propre autorité de certification, inconnue de la nouvelle installation Mint. Votre ordinateur lui fait peut-être déjà confiance, ce qui explique pourquoi le même téléchargement y réussit. Installez cette autorité sur le portable :

```bash
sudo cp your-gateway-ca.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates
```

Relancez ensuite l’installation. Les réseaux d’entreprise, certains campus et des filtres scolaires fonctionnent aussi de cette manière.

## Chrome demande de choisir un moteur de recherche

C’est normal. Chrome affiche cette fenêtre lors de son premier lancement dans l’Union européenne. Choisissez un moteur ; elle ne reviendra plus.

## AUCOOP Welcome ne s’ouvre pas après le redémarrage

Il s’ouvre automatiquement uniquement tant que la préparation reste inachevée. Double-cliquez sur l’icône AUCOOP Welcome du bureau pour le rappeler à tout moment.

## Les mises à jour semblent bloquées

Elles travaillent probablement encore. La ligne sous la barre indique le paquet en cours. Un Mint 22.3 neuf peut attendre plusieurs centaines de mises à jour et de mégaoctets. Ouvrez « Détails techniques » pour voir la sortie d’apt.

## « Espace disque insuffisant » pendant l’installation de l’IA

Le modèle et son environnement demandent plus de place qu’il n’en reste. Welcome vérifie avant de télécharger, au lieu de remplir le disque puis d’échouer. Choisissez un modèle plus petit ou libérez de l’espace.

## L’assistant IA ne démarre pas

Une notification vous prévient. Le journal se trouve dans `/tmp/aucoop-local-ai.log`. Nous avons vu deux causes : un modèle supprimé ou corrompu, corrigé par une réinstallation, et un autre programme sur le port 8091. Le lanceur actuel contourne le second cas en choisissant le prochain port libre.

## L’assistant disparaît après un moment

C’est volontaire. Sans navigateur connecté pendant dix minutes, il s’arrête pour libérer la mémoire, car un modèle chargé occupe toute sa taille en RAM. Cliquez sur l’icône pour le relancer.

## Échec de l’enregistrement à la dernière étape

Vérifiez d’abord le jeton, puis l’URL de l’instance. Workbench a besoin des droits root, obtenus par la fenêtre de mot de passe, ainsi que du réseau. Lancez-le depuis Welcome pour que tout soit préparé correctement.

## Un autre problème

Ouvrez un ticket sur [github.com/aucoop/AUCOOP-Mint](https://github.com/aucoop/AUCOOP-Mint/issues) et joignez `~/.local/state/aucoop-mint/install.log`. Il ne contient aucun mot de passe, seulement les actions des scripts.
