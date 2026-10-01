# 🎮 Mega Obby Simulator

Ein komplettes Roblox-Spiel, das die beliebtesten Roblox-Genres kombiniert:
**Obby + Simulator + Pets**. Die ganze Welt wird per Code gebaut, du brauchst also
keine `.rbxl`-Datei. Einfach mit Rojo in Roblox Studio syncen und auf „Play“ drücken.

## ✨ Features

| Feature | Beschreibung |
|---|---|
| 🏁 **Obby mit 30 Stufen** | 8 Hindernistypen: Sprünge, Lava-Steine, bewegte Plattformen, Drehbalken, verschwindende Plattformen, schmale Balken, Lava-Fliesen, Kletterwand. Wird mit jeder Stufe schwerer. |
| 📍 **Checkpoints** | Fortschritt wird gespeichert. Nach dem Tod startest du am letzten Checkpoint. |
| 🏆 **Ziel-Belohnung** | Viele Münzen + Edelsteine. Alle Spieler bekommen eine Nachricht, wenn jemand es schafft. |
| 💰 **Münzen & 💎 Edelsteine** | Liegen in der Lobby verteilt und spawnen immer wieder neu. |
| 🛒 **Shop-Upgrades** | Turbo-Schuhe (Speed), Sprungfedern (Jump), Münzmagnet (Sammelradius). |
| 🐾 **Pets** | 3 Eier, 10 Pets in 6 Seltenheiten (Common bis Mythic). Pets folgen dir und erhöhen deinen Münz-Multiplikator. Mit Ausbrüt-Animation! |
| ✨ **Trails** | Feuer, Eis, Gift, Regenbogen. |
| 🔁 **Rebirth** | Münzen opfern für einen dauerhaften Multiplikator + Edelsteine. |
| 🎁 **Tägliche Belohnung** | 7-Tage-Serie mit steigenden Belohnungen. |
| 🎟️ **Codes** | `WELCOME`, `RELEASE`, `PETLOVER` (in `Config.luau` änderbar). |
| 🏅 **Globale Bestenliste** | Tafel in der Lobby mit den Top-10-Spielern (meiste Münzen). |
| 🦘 **Doppelsprung** | Einfach in der Luft nochmal springen. |
| 🏃 **Sprint** | `Shift` am PC, eigener Knopf auf dem Handy. |
| 💾 **Speichern** | DataStore mit Wiederholungsversuchen, Auto-Save und Schutz vor Datenverlust. |
| 🌅 **Tag/Nacht-Zyklus** | Plus Atmosphäre, Bloom und Farbkorrektur. |
| 📱 **Handy-tauglich** | Das UI skaliert mit, und es gibt einen Sprint-Knopf. |
| 🛡️ **Anti-Cheat-Grundlagen** | Alle Käufe & Belohnungen werden auf dem Server geprüft. Stufen können nicht übersprungen werden. |
| 💸 **Gamepässe (optional)** | 2x Münzen und VIP. Einfach die IDs in `Config.luau` eintragen. |

### Tastenkürzel
`B` Shop · `P` Pets · `T` Trails · `R` Rebirth · `Shift` Sprint · `Leertaste` 2x = Doppelsprung

## 🚀 So startest du das Spiel

1. **Rojo installieren**: https://rojo.space/docs/v7/getting-started/installation/
   (Rojo-CLI + das Rojo-Plugin für Roblox Studio)
2. In diesem Ordner im Terminal ausführen:
   ```bash
   rojo serve
   ```
3. Roblox Studio öffnen → neue **Baseplate** → im Rojo-Plugin auf **Connect** klicken.
4. **Play** drücken! 🎉 (Die Standard-`Baseplate` wird automatisch entfernt,
   weil das Spiel seine eigene Welt baut.)

**Alternative ohne Live-Sync:** `rojo build -o MegaObby.rbxl` und die Datei in Studio öffnen.

### 💾 Speichern aktivieren
Damit Fortschritt und Bestenliste funktionieren:
1. Spiel veröffentlichen (*Datei → Auf Roblox veröffentlichen*)
2. *Spieleinstellungen → Sicherheit → „Studio-Zugriff auf API-Dienste aktivieren“*

Ohne diese Schritte läuft das Spiel trotzdem, es speichert dann nur nichts.

## 🔧 Anpassen

Fast alles steht in **`src/ReplicatedStorage/Shared/Config.luau`**:
- Anzahl der Obby-Stufen, Belohnungen
- Preise der Upgrades, Eier, Trails, Rebirth
- Neue Pets (Name, Seltenheit, Multiplikator, Farbe) und Ei-Chancen
- Codes und tägliche Belohnungen
- Gamepass-IDs

## 📁 Projektstruktur

```
src/
├── ReplicatedStorage/Shared/
│   ├── Config.luau            Alle Spielwerte
│   └── Remotes.luau           Client↔Server-Kommunikation
├── ServerScriptService/
│   ├── Main.server.luau       Server-Start
│   └── Services/
│       ├── DataService        Speichern/Laden
│       ├── PlayerService      Währung, Multiplikator, Leaderstats, Gamepässe
│       ├── WorldBuilder       Baut Lobby, Obby, Eier, Bestenliste, Licht
│       ├── ObbyService        Checkpoints, Lava, bewegte Teile, Ziel
│       ├── CoinService        Münzen spawnen & einsammeln
│       ├── PetService         Eier, Pets, Ausrüsten
│       ├── ShopService        Alle Käufe & Aktionen
│       └── LeaderboardService Globale Bestenliste
└── StarterPlayer/StarterPlayerScripts/
    ├── Main.client.luau       Client-Start
    ├── UI.luau                Komplette Oberfläche
    ├── Effects.luau           Animationen, Pets folgen, Popups
    └── Movement.luau          Doppelsprung & Sprint
```
