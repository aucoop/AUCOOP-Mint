# Preparar un portàtil

Comença amb un portàtil que tingui Linux Mint 22.3 Cinnamon acabat d’instal·lar i res més. Et caldran la contrasenya del compte i connexió a internet. Reserva mitja hora; passaràs gairebé tot aquest temps esperant les descàrregues.

Prefereixes veure-ho primer? Aquest vídeo de 5 minuts mostra tots els passos d’aquesta pàgina, des de la descàrrega de Linux Mint fins al portàtil acabat. No té veu, així que deixa els subtítols activats.

<div style="position:relative;aspect-ratio:16/9;width:100%;margin:1em 0 2em">
  <iframe src="https://www.youtube-nocookie.com/embed/B49QS7KgN3Y?cc_load_policy=1&amp;cc_lang_pref=ca&amp;hl=ca&amp;rel=0" title="AUCOOP Mint video guide" loading="lazy" style="position:absolute;inset:0;width:100%;height:100%;border:0" allow="encrypted-media; picture-in-picture; fullscreen" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
</div>

## 1. Instal·lar Linux Mint

No hi ha cap pas especial: fes servir l’instal·lador normal de Mint des d’una memòria USB.

Dues decisions d’aquesta instal·lació importen després. La llengua que triïs serà la d’AUCOOP Mint; si el portàtil va a una escola de Moçambic, tria ara el portuguès. Pots deixar desmarcada la casella dels «còdecs multimèdia», perquè AUCOOP Welcome els instal·larà més tard.

## 2. Executar una ordre

Obre un terminal a la màquina acabada d’instal·lar i enganxa-hi això:

```bash
wget -qO- https://raw.githubusercontent.com/aucoop/AUCOOP-Mint/master/boot.sh | bash
```

Abans de prémer **Retorn** s’hauria de veure així:

![L’ordre d’instal·lació d’AUCOOP Mint esperant al terminal](../assets/installer-command.jpg)

Et demanarà una vegada la contrasenya de l’ordinador. El cursor no es mourà mentre l’escrius; Linux no mostra la contrasenya, ni tan sols amb punts. Prem **Retorn** quan acabis.

L’instal·lador agafarà el relleu:

![L’instal·lador en marxa](../assets/installer-running.jpg)

Hi ha set passos, cadascun amb el seu cronòmetre. Una màquina de prova neta va trigar 1 minut i 44 segons; un portàtil vell o una connexió lenta necessitaran més temps. OnlyOffice sol ser la part més lenta perquè la descàrrega és grossa.

Prem **D** en qualsevol moment si vols veure les ordres reals:

![Els detalls tècnics de la instal·lació](../assets/installer-details.jpg)

Prem **D** una altra vegada per tornar a la vista senzilla. L’instal·lador desa la mateixa sortida a `~/.local/state/aucoop-mint/install.log`, tant si el plafó és obert com si és tancat.

Quan acaba pregunta si vols reiniciar:

![Instal·lació acabada](../assets/installer-done.jpg)

Prem **Retorn** per acceptar l’opció predeterminada, **Y**, i reiniciar. L’escriptori nou apareixerà després del reinici.

### Prefereixes clonar el repositori?

```bash
git clone https://github.com/aucoop/AUCOOP-Mint.git
cd AUCOOP-Mint
git submodule update --init --recursive
bash install.sh
```

El resultat és el mateix; l’ordre curta només fa la clonació per tu. Afegeix `--verbose` si prefereixes veure tota la sortida en comptes de la pantalla de progrés.

## 3. Acabar amb AUCOOP Welcome

Després del reinici, inicia la sessió. AUCOOP Welcome s’obrirà tot sol amb cinc passos: benvinguda, preparació, extres, registre i final. La [pàgina següent](first-boot.md) els explica.

## Què canvia l’ordre

Elimina Firefox, LibreOffice, Thunderbird, Transmission, Hypnotix, Warpinator i algunes aplicacions més que gairebé ningú obre en un portàtil escolar compartit.

Instal·la Google Chrome, OnlyOffice amb accessos anomenats Word, Excel i PowerPoint, i afegeix Flathub al Gestor de programari.

Canvia el tema, el fons, el cursor, la barra de tasques, les aplicacions fixades i el botó del menú. També desactiva la benvinguda pròpia de Mint perquè no apareguin dos assistents al primer inici.

Deixa per a més endavant les actualitzacions del sistema, els còdecs, els controladors i els extres opcionals. AUCOOP Welcome se n’ocupa perquè puguis decidir quan gastar l’amplada de banda.

## Es pot executar dues vegades

Repetir l’instal·lador és segur. Els passos acabats se salten o es repeteixen sense fer mal. Si una descàrrega ha fallat a mig camí o no saps si ha acabat, torna a executar la mateixa ordre.

## Si falla

La pantalla d’error indica quin pas ha fallat, suggereix què pot haver passat i mostra les últimes línies del registre. Nou de cada deu vegades és la xarxa. Consulta la [solució de problemes](../troubleshooting.md) per veure els casos que hem trobat de debò.

## Requisits, en poques paraules

Linux Mint 22.x Cinnamon, una connexió que funcioni i executar l’ordre des del compte normal de l’escriptori. No ho facis com a root: l’script s’hi nega perquè bona part de la feina modifica la configuració del teu usuari.
