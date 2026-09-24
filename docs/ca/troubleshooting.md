# Solució de problemes

Problemes que han passat de debò i què cal fer-hi.

## L’instal·lador s’atura en un pas

La pantalla d’error indica el pas, mostra les últimes línies i assenyala el registre complet: `~/.local/state/aucoop-mint/install.log`. És segur tornar a executar la mateixa ordre i normalment n’hi ha prou, perquè la feina acabada se salta.

## «No hi ha connexió a internet» abans de començar

L’instal·lador comprova la xarxa abans de demanar la contrasenya. Connecta la màquina i torna-ho a provar. Si el portàtil diu que està connectat però l’instal·lador no hi està d’acord, probablement NetworkManager ha detectat un portal captiu: obre Chrome, entra a la xarxa i repeteix l’ordre.

## Les descàrregues fallen en una xarxa que inspecciona TLS

Ens va passar en una xarxa amb la passarel·la Zero Trust de Cloudflare. Totes les descàrregues HTTPS fallaven i `wget` mostrava una cosa semblant a aquesta:

```
ERROR: cannot verify dl.google.com's certificate, issued by
'CN=Gateway CA - Cloudflare Managed G1 ...':
Self-signed certificate encountered.
```

La xarxa desxifra el trànsit i el torna a signar amb la seva autoritat de certificació, que la instal·lació nova de Mint encara no coneix. Potser el teu ordinador sí que hi confia, i per això la mateixa descàrrega hi funciona. Instal·la aquesta CA al portàtil:

```bash
sudo cp your-gateway-ca.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates
```

Després torna a executar l’instal·lador. També passa en xarxes corporatives, alguns campus universitaris i aparells de filtratge escolar.

## Chrome pregunta quin cercador ha d’utilitzar

És normal, no pas un error. Chrome mostra aquest diàleg la primera vegada que s’obre a la Unió Europea. Tria’n un i no tornarà a aparèixer.

## AUCOOP Welcome no s’obre després del reinici

Només s’obre automàticament mentre la preparació estigui pendent. Fes doble clic a la icona AUCOOP Welcome de l’escriptori per recuperar-lo quan vulguis.

## Les actualitzacions semblen encallades

Probablement encara treballen. Mira la línia sota la barra: indica el paquet que s’instal·la en aquell moment. Un Mint 22.3 acabat d’instal·lar pot tenir centenars d’actualitzacions i uns quants centenars de megabytes pendents. Obre «Detalls tècnics» si vols veure la sortida d’apt.

## «No hi ha prou espai» quan s’instal·la la IA

El model i l’entorn necessiten més espai del que queda. Welcome ho comprova abans de descarregar per no omplir el disc i fallar al final. Tria un model més petit o allibera espai.

## L’assistent d’IA no arrenca

Rebràs una notificació. El registre és a `/tmp/aucoop-local-ai.log`. Hem vist dues causes: un model esborrat o malmès, que s’arregla reinstal·lant, i un altre programa al port 8091. El llançador actual resol el segon cas passant al port lliure següent.

## L’assistent desapareix al cap d’una estona

És intencionat. Quan no hi ha cap navegador connectat durant deu minuts, s’apaga per alliberar memòria, perquè un model carregat ocupa tota la seva mida a la RAM. Prem la icona per tornar-lo a engegar.

## Falla el registre de l’últim pas

Comprova primer el testimoni i després l’URL de la instància. Workbench necessita root, que obté mitjançant el diàleg de contrasenya, i també necessita xarxa. Executa’l des de Welcome perquè tot això quedi preparat.

## Un altre problema

Obre una incidència a [github.com/aucoop/AUCOOP-Mint](https://github.com/aucoop/AUCOOP-Mint/issues) i adjunta `~/.local/state/aucoop-mint/install.log`. No conté contrasenyes, només les accions dels scripts.
