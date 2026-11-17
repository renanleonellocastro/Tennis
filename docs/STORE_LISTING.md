# Connect IQ store listing: Tennis

Text to copy and paste into the
[Connect IQ developer dashboard](https://apps.garmin.com/developer/dashboard),
in the six languages of the app: English, Portuguese, Spanish, French, German
and Italian.

The app is **not published yet**. This listing describes version 1.0.0 as
agreed in [PLAN.md](PLAN.md). Every statement that still depends on work in
progress or on a test with a real watch is in
[To confirm before release](#to-confirm-before-release).

## Rules for every text

* Short description: 140 characters at most, as in the Stretches listing.
* Descriptions are plain text. The store rejects emojis and does not render
  markdown, so the blocks below have neither. Paste them as they are.
* Button names (UP, DOWN, START, BACK) and the on screen names (MENU, FAULT
  and the menu entries) are written as the watch shows them in each language.

## Category and type

Health & Fitness. Type: Watch App. This is the category of Stretches; pick
the closest one the dashboard offers.

## Supported devices

The 80 watch models of `manifest.xml`, the same list as Stretches:
Forerunner 55 (the reference device), 70, 165, 170, 245, 255, 265, 570, 745,
945, 955, 965 and 970; fenix 6, 7, 7 Pro, 8, E and 9; Epix 2 and Epix Pro;
Enduro 3; Venu, Venu 2, 3, 4, X1 and Venu Sq; vivoactive 4, 5 and 6;
Instinct 3 AMOLED and Instinct Crossover AMOLED; MARQ 2; Descent Mk3 and
D2 Mach. All of them run Connect IQ API 3.2 or newer.

Notes for the listing:

* Singles only in version 1.
* The GPS switch shows only on watches that have GPS.
* Watches without UP and DOWN buttons score by touch and show MENU and
  FAULT buttons on the screen.

## Permissions

The three permissions of `manifest.xml` and why each one is needed.

* **Fit**: records the match or the practice as an activity (Tennis sport),
  with the heart rate, calories and time that the watch measures.
* **FitContributor**: adds the data of the app to that activity. Today:
  steps and distance, for the activity and for each set. Planned for
  version 1: set scores, final score, statistics, match setup with tags and
  the point log.
* **Positioning**: turns the GPS on only when the player switches GPS on in
  the match setup. The watch adds the track to the activity. The app itself
  does not read or keep the positions.

The app asks for no other permission. It has no Communications permission,
so it cannot reach the internet or the phone.

## Privacy

Privacy policy: not required, the app collects no personal data. Statement
for the dashboard, in English (each full description below carries the same
statement in its own language):

> Tennis has no accounts, no ads and no data collection. It has no internet
> access. The match in progress is kept on the watch, and saved matches are
> recorded as activities in your own Garmin account. The export converter
> runs on your own computer and sends nothing anywhere.

## English

### App name

Tennis: Score and Match Stats

### Short description

> Keep the tennis score on your watch, log how every point ended and get a full statistics report of your match.

### Tags

`tennis` · `score` · `scoreboard` · `match` · `statistics` · `serve` · `ace` · `double fault` · `tie break` · `practice` · `racket sports` · `export`

### Full description

```
Your tennis match, point by point, on your wrist.

Tennis keeps the score while you play and remembers how every point ended. One press gives the point to you or to your opponent. The watch tracks who serves, from which side and when to change ends, and records the match as a Tennis activity with heart rate, calories, steps and distance. When the match is over you get a statistics report of your game.

WHAT YOU CAN DO
* Play five formats: best of 3 sets, 2 sets plus a 10 point match tie break, 1 set, pro set to 8 games, or a tie break only. No advantage scoring is a switch.
* Choose how much to log. Simple: one press, who won the point. Detailed: a second press says how it ended (winner, ace, error in the net, error out).
* Log serve faults with one button. The first press marks a second serve. The second press is a double fault and the point goes to the receiver.
* Read the score at a glance: game points in large digits, set score on top, a ball next to the server, a mini court with the side to serve from, heart rate and match clock.
* See the break point, set point and match point labels, and feel a vibration when it is time to change ends.
* Undo the last entry with one press, or fix the score from the menu.
* Pause, end, save or discard. A match interrupted when the app closes can be resumed.
* Study your game after the match: aces, double faults, first serve percentage, points won on first and on second serve, break points won and saved, winners, errors, longest run of points and more, for both players.
* Find it in Garmin Connect as a Tennis activity, with one lap per set and the main statistics.
* Tag the match when you save it: clay, hard or grass, match or friendly.
* Practice mode: record a training session and count hits and misses in blocks, with the success rate of each block.
* Optional GPS on watches that have it.
* Six languages, following the language of your watch: English, Portuguese, Spanish, French, German and Italian.

CONTROLS
* UP: point for me. DOWN: point for the opponent.
* START: serve fault. BACK: undo.
* Hold UP: menu with Pause, Fix the score and End match.
* Touch screens: tap the left half for your point and the right half for the opponent. Watches without UP and DOWN buttons show MENU and FAULT buttons on the screen.

YOUR DATA IS YOURS
Every point is stored inside the activity file, in the open FIT format. A free converter, published with the source code, turns that file into CSV and JSON on your own computer and draws an approximate heat map of the court when GPS was on. Watch GPS is off by 3 to 5 meters, so the heat map shows tendencies, not exact positions.

SUPPORTED WATCHES
80 Garmin models: Forerunner, fenix, Epix, Enduro, Venu, vivoactive, Instinct AMOLED, MARQ, Descent and D2 Mach. This version is for singles.

PERMISSIONS
* Fit: records the match as an activity.
* FitContributor: adds the tennis data to that activity (steps, distance, set scores, statistics and the point log).
* Positioning: used only when you turn the GPS switch on.

PRIVACY
No accounts, no ads and no data collection. The app has no internet access. Your matches stay on your watch and in your own Garmin account, and the converter runs on your own computer.

Free and open source under the MIT license.
```

### What is new in 1.0.0

```
First release: live score in five match formats, simple or detailed point logging, serve faults with one button, a statistics report after the match, a Tennis activity in Garmin Connect with one lap per set, practice mode, open data export, six languages and 80 watches.
```

## Portuguese (Português)

### App name

Tennis: placar e estatísticas da partida

### Short description

> Marque o placar do tênis no relógio, registre como cada ponto terminou e veja as estatísticas completas da sua partida.

### Tags

`tênis` · `placar` · `partida` · `estatísticas` · `saque` · `ace` · `dupla falta` · `tie break` · `treino` · `esportes de raquete` · `exportação`

### Full description

```
Sua partida de tênis, ponto a ponto, no pulso.

O Tennis marca o placar enquanto você joga e guarda como cada ponto terminou. Um aperto de botão dá o ponto para você ou para o adversário. O relógio acompanha quem saca, de que lado e quando trocar de lado, e grava a partida como uma atividade de Tênis com frequência cardíaca, calorias, passos e distância. No fim da partida você recebe um relatório com as estatísticas do seu jogo.

O QUE VOCÊ PODE FAZER
* Jogar em cinco formatos: melhor de 3 sets, 2 sets mais um super tie break de 10 pontos, 1 set, pro set até 8 games ou só um tie break. O jogo sem vantagem é uma opção que você liga ou desliga.
* Escolher o nível de detalhe. Simples: um aperto, quem ganhou o ponto. Detalhado: um segundo aperto diz como o ponto terminou (winner, ace, erro na rede, erro fora).
* Marcar as faltas de saque com um só botão. O primeiro aperto indica o segundo saque. O segundo é dupla falta e o ponto vai para quem recebe.
* Ler o placar de relance: pontos do game em números grandes, placar dos sets no alto, uma bolinha ao lado de quem saca, uma mini quadra com o lado do saque, frequência cardíaca e tempo de jogo.
* Ver os avisos de break point, set point e match point e sentir uma vibração na hora de trocar de lado.
* Desfazer o último lançamento com um aperto ou corrigir o placar pelo menu.
* Pausar, encerrar, salvar ou descartar. Uma partida interrompida quando o app fecha pode ser retomada.
* Estudar o seu jogo depois da partida: aces, duplas faltas, percentual de primeiro saque, pontos ganhos com o primeiro e com o segundo saque, break points ganhos e salvos, winners, erros, maior sequência de pontos e mais, para os dois jogadores.
* Encontrar tudo no Garmin Connect como uma atividade de Tênis, com uma volta por set e as principais estatísticas.
* Classificar a partida ao salvar: saibro, quadra dura ou grama, partida oficial ou amistoso.
* Modo treino: grave uma sessão e conte acertos e erros em blocos, com o aproveitamento de cada bloco.
* GPS opcional nos relógios que têm GPS.
* Seis idiomas, de acordo com o idioma do relógio: inglês, português, espanhol, francês, alemão e italiano.

CONTROLES
* UP: ponto para mim. DOWN: ponto para o adversário.
* START: falta de saque. BACK: desfazer.
* Segurar UP: menu com Pausar, Corrigir placar e Encerrar partida.
* Telas de toque: toque na metade esquerda para o seu ponto e na metade direita para o ponto do adversário. Relógios sem os botões UP e DOWN mostram os botões MENU e FALTA na tela.

SEUS DADOS SÃO SEUS
Cada ponto fica gravado dentro do arquivo da atividade, no formato aberto FIT. Um conversor gratuito, publicado junto com o código do app, transforma esse arquivo em CSV e JSON no seu próprio computador e desenha um mapa de calor aproximado da quadra quando o GPS estava ligado. O GPS do relógio erra de 3 a 5 metros, então o mapa mostra tendências, não posições exatas.

RELÓGIOS COMPATÍVEIS
80 modelos Garmin: Forerunner, fenix, Epix, Enduro, Venu, vivoactive, Instinct AMOLED, MARQ, Descent e D2 Mach. Esta versão é para partidas de simples.

PERMISSÕES
* Fit: grava a partida como uma atividade.
* FitContributor: acrescenta os dados do tênis a essa atividade (passos, distância, placar dos sets, estatísticas e o registro dos pontos).
* Positioning: usada somente quando você liga o GPS.

PRIVACIDADE
Sem contas, sem anúncios e sem coleta de dados. O app não tem acesso à internet. Suas partidas ficam no seu relógio e na sua própria conta Garmin, e o conversor roda no seu próprio computador.

Gratuito e de código aberto, sob a licença MIT.
```

### What is new in 1.0.0

```
Primeira versão: placar ao vivo em cinco formatos de partida, registro simples ou detalhado dos pontos, faltas de saque com um só botão, relatório de estatísticas depois da partida, atividade de Tênis no Garmin Connect com uma volta por set, modo treino, exportação aberta dos dados, seis idiomas e 80 relógios.
```

## Spanish (Español)

### App name

Tennis: marcador y estadísticas del partido

### Short description

> Lleva el marcador del tenis en tu reloj, registra cómo terminó cada punto y consulta las estadísticas completas de tu partido.

### Tags

`tenis` · `marcador` · `partido` · `estadísticas` · `saque` · `ace` · `doble falta` · `tie break` · `práctica` · `deportes de raqueta` · `exportación`

### Full description

```
Tu partido de tenis, punto a punto, en la muñeca.

Tennis lleva el marcador mientras juegas y recuerda cómo terminó cada punto. Una pulsación da el punto a ti o a tu rival. El reloj sigue quién saca, desde qué lado y cuándo hay que cambiar de lado, y graba el partido como una actividad de Tenis con frecuencia cardiaca, calorías, pasos y distancia. Al terminar el partido recibes un informe con las estadísticas de tu juego.

LO QUE PUEDES HACER
* Jugar en cinco formatos: al mejor de 3 sets, 2 sets más un súper tie break a 10 puntos, 1 set, pro set a 8 juegos o solo un tie break. El juego sin ventaja es una opción que activas o desactivas.
* Elegir el nivel de detalle. Simple: una pulsación, quién ganó el punto. Detallado: una segunda pulsación indica cómo terminó (winner, ace, error en la red, error fuera).
* Anotar las faltas de saque con un solo botón. La primera pulsación marca el segundo saque. La segunda es doble falta y el punto va para quien resta.
* Leer el marcador de un vistazo: puntos del juego en cifras grandes, marcador de sets arriba, una pelota junto a quien saca, una mini pista con el lado del saque, frecuencia cardiaca y tiempo de partido.
* Ver los avisos de punto de break, punto de set y punto de partido, y sentir una vibración cuando toca cambiar de lado.
* Deshacer la última anotación con una pulsación o corregir el marcador desde el menú.
* Pausar, terminar, guardar o descartar. Un partido interrumpido al cerrarse la app se puede reanudar.
* Estudiar tu juego después del partido: aces, dobles faltas, porcentaje de primer saque, puntos ganados con el primer y con el segundo saque, puntos de break ganados y salvados, winners, errores, mayor racha de puntos y más, para los dos jugadores.
* Encontrarlo en Garmin Connect como una actividad de Tenis, con una vuelta por set y las estadísticas principales.
* Etiquetar el partido al guardarlo: tierra batida, pista dura o hierba, partido oficial o amistoso.
* Modo práctica: graba una sesión y cuenta aciertos y fallos por bloques, con el porcentaje de acierto de cada bloque.
* GPS opcional en los relojes que lo tienen.
* Seis idiomas, según el idioma de tu reloj: inglés, portugués, español, francés, alemán e italiano.

CONTROLES
* UP: punto para mí. DOWN: punto para el rival.
* START: falta de saque. BACK: deshacer.
* Mantener pulsado UP: menú con Pausar, Corregir marcador y Terminar partido.
* Pantallas táctiles: toca la mitad izquierda para tu punto y la mitad derecha para el punto del rival. Los relojes sin botones UP y DOWN muestran los botones MENÚ y FALTA en la pantalla.

TUS DATOS SON TUYOS
Cada punto queda guardado dentro del archivo de la actividad, en el formato abierto FIT. Un conversor gratuito, publicado junto con el código de la app, convierte ese archivo en CSV y JSON en tu propio ordenador y dibuja un mapa de calor aproximado de la pista cuando el GPS estaba activado. El GPS del reloj tiene un error de 3 a 5 metros, así que el mapa muestra tendencias, no posiciones exactas.

RELOJES COMPATIBLES
80 modelos Garmin: Forerunner, fenix, Epix, Enduro, Venu, vivoactive, Instinct AMOLED, MARQ, Descent y D2 Mach. Esta versión es para partidos de individuales.

PERMISOS
* Fit: graba el partido como una actividad.
* FitContributor: añade los datos del tenis a esa actividad (pasos, distancia, marcador de los sets, estadísticas y el registro de puntos).
* Positioning: se usa solo cuando activas el GPS.

PRIVACIDAD
Sin cuentas, sin anuncios y sin recogida de datos. La app no tiene acceso a internet. Tus partidos se quedan en tu reloj y en tu propia cuenta Garmin, y el conversor se ejecuta en tu propio ordenador.

Gratis y de código abierto, bajo la licencia MIT.
```

### What is new in 1.0.0

```
Primera versión: marcador en vivo en cinco formatos de partido, registro simple o detallado de los puntos, faltas de saque con un solo botón, informe de estadísticas después del partido, actividad de Tenis en Garmin Connect con una vuelta por set, modo práctica, exportación abierta de los datos, seis idiomas y 80 relojes.
```

## French (Français)

### App name

Tennis : score et statistiques du match

### Short description

> Tenez le score du tennis sur votre montre, notez comment chaque point a fini et consultez les statistiques complètes du match.

### Tags

`tennis` · `score` · `match` · `statistiques` · `service` · `ace` · `double faute` · `tie break` · `entraînement` · `sports de raquette` · `export`

### Full description

```
Votre match de tennis, point par point, au poignet.

Tennis tient le score pendant que vous jouez et retient comment chaque point a fini. Une pression donne le point à vous ou à votre adversaire. La montre suit qui sert, de quel côté et quand changer de côté, et enregistre le match comme une activité Tennis avec fréquence cardiaque, calories, pas et distance. À la fin du match, vous recevez un rapport avec les statistiques de votre jeu.

CE QUE VOUS POUVEZ FAIRE
* Jouer dans cinq formats : 2 sets gagnants, 2 sets plus un super tie break en 10 points, 1 set, pro set à 8 jeux ou un tie break seul. Le jeu sans avantage est une option à activer.
* Choisir le niveau de détail. Simple : une pression, qui a gagné le point. Détaillé : une seconde pression indique comment il a fini (coup gagnant, ace, faute dans le filet, faute dehors).
* Noter les fautes de service avec un seul bouton. La première pression signale la seconde balle. La deuxième est une double faute et le point va au relanceur.
* Lire le score en un coup d'œil : points du jeu en grands chiffres, score des sets en haut, une balle à côté du serveur, un mini court avec le côté du service, fréquence cardiaque et durée du match.
* Voir les mentions balle de break, balle de set et balle de match, et sentir une vibration au moment de changer de côté.
* Annuler la dernière saisie d'une pression ou corriger le score depuis le menu.
* Mettre en pause, terminer, enregistrer ou supprimer. Un match interrompu à la fermeture de l'application peut être repris.
* Analyser votre jeu après le match : aces, doubles fautes, pourcentage de premières balles, points gagnés sur première et sur seconde balle, balles de break gagnées et sauvées, coups gagnants, fautes, plus longue série de points et plus encore, pour les deux joueurs.
* Retrouver le match dans Garmin Connect comme une activité Tennis, avec un tour par set et les principales statistiques.
* Classer le match à l'enregistrement : terre battue, dur ou gazon, match officiel ou amical.
* Mode entraînement : enregistrez une séance et comptez les coups réussis et manqués par blocs, avec le taux de réussite de chaque bloc.
* GPS en option sur les montres qui en ont un.
* Six langues, selon la langue de votre montre : anglais, portugais, espagnol, français, allemand et italien.

COMMANDES
* UP : point pour moi. DOWN : point pour l'adversaire.
* START : faute de service. BACK : annuler.
* Appui long sur UP : menu avec Pause, Corriger le score et Terminer le match.
* Écrans tactiles : touchez la moitié gauche pour votre point et la moitié droite pour le point de l'adversaire. Les montres sans boutons UP et DOWN affichent les boutons MENU et FAUTE à l'écran.

VOS DONNÉES VOUS APPARTIENNENT
Chaque point est enregistré dans le fichier de l'activité, au format ouvert FIT. Un convertisseur gratuit, publié avec le code de l'application, transforme ce fichier en CSV et JSON sur votre propre ordinateur et dessine une carte de chaleur approximative du court quand le GPS était activé. Le GPS de la montre se trompe de 3 à 5 mètres : la carte montre des tendances, pas des positions exactes.

MONTRES COMPATIBLES
80 modèles Garmin : Forerunner, fenix, Epix, Enduro, Venu, vivoactive, Instinct AMOLED, MARQ, Descent et D2 Mach. Cette version est prévue pour le simple.

AUTORISATIONS
* Fit : enregistre le match comme une activité.
* FitContributor : ajoute les données du tennis à cette activité (pas, distance, score des sets, statistiques et journal des points).
* Positioning : utilisée seulement quand vous activez le GPS.

CONFIDENTIALITÉ
Pas de compte, pas de publicité et aucune collecte de données. L'application n'a pas accès à internet. Vos matchs restent sur votre montre et dans votre propre compte Garmin, et le convertisseur fonctionne sur votre propre ordinateur.

Gratuit et open source, sous licence MIT.
```

### What is new in 1.0.0

```
Première version : score en direct dans cinq formats de match, saisie simple ou détaillée des points, fautes de service avec un seul bouton, rapport de statistiques après le match, activité Tennis dans Garmin Connect avec un tour par set, mode entraînement, export ouvert des données, six langues et 80 montres.
```

## German (Deutsch)

### App name

Tennis: Spielstand und Matchstatistik

### Short description

> Zähle den Spielstand beim Tennis auf deiner Uhr, erfasse, wie jeder Punkt endete, und sieh dir die Statistik deines Matches an.

### Tags

`Tennis` · `Spielstand` · `Match` · `Statistik` · `Aufschlag` · `Ass` · `Doppelfehler` · `Tiebreak` · `Training` · `Schlägersport` · `Export`

### Full description

```
Dein Tennismatch, Punkt für Punkt, am Handgelenk.

Tennis zählt den Spielstand, während du spielst, und merkt sich, wie jeder Punkt endete. Ein Tastendruck gibt den Punkt dir oder deinem Gegner. Die Uhr weiß, wer aufschlägt, von welcher Seite und wann die Seiten gewechselt werden, und zeichnet das Match als Tennisaktivität mit Herzfrequenz, Kalorien, Schritten und Distanz auf. Nach dem Match bekommst du einen Bericht mit den Statistiken deines Spiels.

DAS KANNST DU TUN
* Fünf Formate spielen: 2 Gewinnsätze, 2 Sätze plus Match Tiebreak bis 10 Punkte, 1 Satz, Pro Set bis 8 Spiele oder nur ein Tiebreak. Die Zählweise ohne Vorteil lässt sich einschalten.
* Die Detailtiefe wählen. Einfach: ein Tastendruck, wer den Punkt gewonnen hat. Detailliert: ein zweiter Tastendruck sagt, wie der Punkt endete (Winner, Ass, Fehler ins Netz, Fehler ins Aus).
* Aufschlagfehler mit einer einzigen Taste erfassen. Der erste Druck markiert den zweiten Aufschlag. Der zweite ist ein Doppelfehler und der Punkt geht an den Rückschläger.
* Den Spielstand auf einen Blick lesen: Punkte des laufenden Spiels in großen Ziffern, Satzstand oben, ein Ball neben dem Aufschläger, ein kleines Spielfeld mit der Aufschlagseite, dazu Herzfrequenz und Spielzeit.
* Die Hinweise auf Breakball, Satzball und Matchball sehen und eine Vibration spüren, wenn der Seitenwechsel ansteht.
* Den letzten Eintrag mit einem Tastendruck zurücknehmen oder den Spielstand im Menü korrigieren.
* Pausieren, beenden, speichern oder verwerfen. Ein Match, das beim Schließen der App unterbrochen wurde, lässt sich fortsetzen.
* Dein Spiel nach dem Match auswerten: Asse, Doppelfehler, Quote des ersten Aufschlags, gewonnene Punkte nach dem ersten und nach dem zweiten Aufschlag, genutzte und abgewehrte Breakbälle, Winner, Fehler, längste Punkteserie und mehr, für beide Spieler.
* Alles in Garmin Connect als Tennisaktivität wiederfinden, mit einer Runde pro Satz und den wichtigsten Statistiken.
* Das Match beim Speichern einordnen: Sand, Hartplatz oder Rasen, Wettkampf oder Freundschaftsspiel.
* Trainingsmodus: Zeichne eine Einheit auf und zähle Treffer und Fehler in Blöcken, mit der Trefferquote jedes Blocks.
* GPS zum Zuschalten auf Uhren, die GPS haben.
* Sechs Sprachen, passend zur Sprache deiner Uhr: Englisch, Portugiesisch, Spanisch, Französisch, Deutsch und Italienisch.

BEDIENUNG
* UP: Punkt für mich. DOWN: Punkt für den Gegner.
* START: Aufschlagfehler. BACK: zurücknehmen.
* UP gedrückt halten: Menü mit Pause, Spielstand korrigieren und Match beenden.
* Touchscreens: Tippe auf die linke Hälfte für deinen Punkt und auf die rechte Hälfte für den Punkt des Gegners. Uhren ohne die Tasten UP und DOWN zeigen die Schaltflächen MENÜ und FEHLER auf dem Bildschirm.

DEINE DATEN GEHÖREN DIR
Jeder Punkt wird in der Aktivitätsdatei gespeichert, im offenen Format FIT. Ein kostenloser Konverter, der zusammen mit dem Quellcode der App veröffentlicht ist, wandelt diese Datei auf deinem eigenen Computer in CSV und JSON um und zeichnet eine ungefähre Heatmap des Platzes, wenn GPS eingeschaltet war. Das GPS der Uhr liegt 3 bis 5 Meter daneben, die Heatmap zeigt also Tendenzen und keine genauen Positionen.

UNTERSTÜTZTE UHREN
80 Modelle von Garmin: Forerunner, fenix, Epix, Enduro, Venu, vivoactive, Instinct AMOLED, MARQ, Descent und D2 Mach. Diese Version ist für das Einzel gedacht.

BERECHTIGUNGEN
* Fit: zeichnet das Match als Aktivität auf.
* FitContributor: ergänzt diese Aktivität um die Tennisdaten (Schritte, Distanz, Satzergebnisse, Statistiken und das Punkteprotokoll).
* Positioning: wird nur genutzt, wenn du GPS einschaltest.

DATENSCHUTZ
Keine Konten, keine Werbung und keine Datensammlung. Die App hat keinen Zugang zum Internet. Deine Matches bleiben auf deiner Uhr und in deinem eigenen Konto bei Garmin, und der Konverter läuft auf deinem eigenen Computer.

Kostenlos und quelloffen, unter der MIT Lizenz.
```

### What is new in 1.0.0

```
Erste Version: Spielstand live in fünf Matchformaten, einfache oder detaillierte Erfassung der Punkte, Aufschlagfehler mit einer einzigen Taste, Statistikbericht nach dem Match, Tennisaktivität in Garmin Connect mit einer Runde pro Satz, Trainingsmodus, offener Datenexport, sechs Sprachen und 80 Uhren.
```

## Italian (Italiano)

### App name

Tennis: punteggio e statistiche della partita

### Short description

> Tieni il punteggio del tennis sull'orologio, registra come è finito ogni punto e guarda le statistiche complete della partita.

### Tags

`tennis` · `punteggio` · `partita` · `statistiche` · `servizio` · `ace` · `doppio fallo` · `tie break` · `allenamento` · `sport di racchetta` · `esportazione`

### Full description

```
La tua partita di tennis, punto per punto, al polso.

Tennis tiene il punteggio mentre giochi e ricorda come è finito ogni punto. Una pressione assegna il punto a te o al tuo avversario. L'orologio segue chi serve, da quale lato e quando cambiare campo, e registra la partita come attività Tennis con frequenza cardiaca, calorie, passi e distanza. Alla fine della partita ricevi un rapporto con le statistiche del tuo gioco.

COSA PUOI FARE
* Giocare in cinque formati: al meglio di 3 set, 2 set più un super tie break a 10 punti, 1 set, pro set a 8 game o solo un tie break. Il gioco senza vantaggi è un'opzione da attivare.
* Scegliere il livello di dettaglio. Semplice: una pressione, chi ha vinto il punto. Dettagliato: una seconda pressione dice come è finito (vincente, ace, errore in rete, errore fuori).
* Segnare i falli di servizio con un solo tasto. La prima pressione indica la seconda di servizio. La seconda è un doppio fallo e il punto va a chi risponde.
* Leggere il punteggio a colpo d'occhio: punti del game in cifre grandi, punteggio dei set in alto, una pallina accanto a chi serve, un mini campo con il lato del servizio, frequenza cardiaca e tempo di gioco.
* Vedere gli avvisi di palla break, set point e match point e sentire una vibrazione quando è ora di cambiare campo.
* Annullare l'ultima voce con una pressione o correggere il punteggio dal menu.
* Mettere in pausa, terminare, salvare o eliminare. Una partita interrotta alla chiusura dell'app si può riprendere.
* Studiare il tuo gioco dopo la partita: ace, doppi falli, percentuale di prime di servizio, punti vinti con la prima e con la seconda, palle break vinte e salvate, vincenti, errori, serie di punti più lunga e altro ancora, per entrambi i giocatori.
* Ritrovare tutto in Garmin Connect come attività Tennis, con un giro per set e le statistiche principali.
* Classificare la partita al salvataggio: terra, cemento o erba, partita ufficiale o amichevole.
* Modalità allenamento: registra una sessione e conta colpi riusciti ed errori a blocchi, con la percentuale di riuscita di ogni blocco.
* GPS opzionale sugli orologi che lo hanno.
* Sei lingue, in base alla lingua dell'orologio: inglese, portoghese, spagnolo, francese, tedesco e italiano.

COMANDI
* UP: punto per me. DOWN: punto per l'avversario.
* START: fallo di servizio. BACK: annulla.
* Tenere premuto UP: menu con Pausa, Correggi punteggio e Termina partita.
* Schermi touch: tocca la metà sinistra per il tuo punto e la metà destra per il punto dell'avversario. Gli orologi senza i tasti UP e DOWN mostrano i pulsanti MENU e FALLO sullo schermo.

I TUOI DATI SONO TUOI
Ogni punto viene salvato dentro il file dell'attività, nel formato aperto FIT. Un convertitore gratuito, pubblicato insieme al codice dell'app, trasforma quel file in CSV e JSON sul tuo computer e disegna una mappa di calore approssimativa del campo quando il GPS era attivo. Il GPS dell'orologio sbaglia da 3 a 5 metri, quindi la mappa mostra tendenze, non posizioni esatte.

OROLOGI COMPATIBILI
80 modelli Garmin: Forerunner, fenix, Epix, Enduro, Venu, vivoactive, Instinct AMOLED, MARQ, Descent e D2 Mach. Questa versione è per il singolare.

AUTORIZZAZIONI
* Fit: registra la partita come attività.
* FitContributor: aggiunge i dati del tennis a quell'attività (passi, distanza, punteggio dei set, statistiche e registro dei punti).
* Positioning: usata solo quando attivi il GPS.

PRIVACY
Nessun account, nessuna pubblicità e nessuna raccolta di dati. L'app non ha accesso a internet. Le tue partite restano sul tuo orologio e nel tuo account Garmin, e il convertitore gira sul tuo computer.

Gratuita e open source, con licenza MIT.
```

### What is new in 1.0.0

```
Prima versione: punteggio dal vivo in cinque formati di partita, registrazione semplice o dettagliata dei punti, falli di servizio con un solo tasto, rapporto con le statistiche dopo la partita, attività Tennis in Garmin Connect con un giro per set, modalità allenamento, esportazione aperta dei dati, sei lingue e 80 orologi.
```

## Screenshots to capture

None exists yet. Capture them on the Forerunner 55 simulator (the reference
device) once every screen is built, and save them under
`docs/images/screenshots/`. Upload them in this order, so the preview tells
the whole story:

1. Match screen in the middle of a game: set score on top, large game
   points, serve ball, mini court, heart rate and clock.
2. Match screen with a BREAK POINT label and the second serve mark on the
   ball.
3. Match setup: Format, No advantage, Point detail, First serve, GPS, Start.
4. Detailed mode: the list that asks how the point ended.
5. The Change ends notice.
6. Final score with You won, the sets and the time played.
7. One page of the watch report (serve numbers).
8. Practice mode with a block in progress.
9. Home screen.
10. A touch watch without UP and DOWN buttons (for example the Venu 2):
    match screen with the MENU and FAULT buttons.

Other assets, following Stretches:

* App icon: built per device from `resources/drawables/launcher_icon.png`.
* Hero image: a marketing graphic, `docs/images/store-hero.png` (not made
  yet).

## Support and metadata

* Support email: the developer's email, filled in on the dashboard.
* Source code and issues: the GitHub repository of the app.
* License: MIT.

## To confirm before release

Every item below must be checked, and the texts above corrected where the
app ends up different.

1. **Watch report (M5, in progress).** The description promises a statistics
   report on the watch after the match. Confirm the pages and the list of
   statistics named in the text.
2. **Match tags (M5, in progress).** Surface (clay, hard, grass) and match
   or friendly, chosen when saving. Confirm the option names in each
   language against the strings of the app.
3. **Statistics in Garmin Connect (M5, in progress).** Today only steps and
   distance are written as extra fields. "The main statistics" depends on
   M5 and on how Garmin Connect shows them.
4. **Point log in the activity file.** The "Your data is yours" section
   and the FitContributor line depend on it. Confirmed on the simulator
   (Forerunner 55): scripted matches, one of them closed and resumed, were
   converted and matched the script point by point. Still to confirm with
   a file of a real watch.
5. **Practice mode on a real watch.** Counters, blocks and the success
   rate per block work on the simulator; nothing ran on a real watch.
6. **Controls on real watches.** Hold UP for the menu, taps on touch
   screens, the MENU and FAULT buttons on watches without UP and DOWN
   buttons, and the vibration at the change of ends need the watch pass of
   `docs/TESTING.md`.
7. **All 80 devices.** The Tennis sport type, steps and the hidden GPS
   switch on watches without GPS are open checks of the plan.
8. **Version.** The About text of the app still says 0.1.0. It must read
   1.0.0 before this listing is used.
9. **Dashboard limits.** Only the 140 character limit of the short
   description is known from Stretches. Check the limits of the app name,
   the full description and the tags on the dashboard, and the category
   list.
10. **App name.** The watch shows "Tennis" ("Tênis" in Portuguese, "Tenis"
    in Spanish). The longer store name is a proposal.
11. **Screenshots and hero image.** Not captured yet.
