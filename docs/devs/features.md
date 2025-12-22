# nvim-cmdlog features

## Table of content

  - [History-Qualität und -Kontrolle](#history-qualitt-und-kontrolle)
  - [Sicherheit und Fehlerminimierung](#sicherheit-und-fehlerminimierung)
  - [Picker-UX und Interaktion](#picker-ux-und-interaktion)
  - [Integration mit Neovim-Ökosystem](#integration-mit-neovim-kosystem)
  - [Export, Import, Automatisierung](#export-import-automatisierung)
  - [Technisch besonders gut passend zu deinem Plugin](#technisch-besonders-gut-passend-zu-deinem-plugin)

---

## History-Qualität und -Kontrolle

* **History-Quelle anzeigen**
  Anzeige einer Spalte oder eines Labels, ob ein Eintrag aus:
  * Neovim `:` history
  * Shell history
  * Favorites
    stammt.
    Sinnvoll bei gemischten Pickern wie `:Cmdlog`.

* **Session-lokale History**
  Optionaler Modus, der nur Befehle seit dem letzten Neovim-Start zeigt.
  Technisch umsetzbar durch Snapshot der initialen Cmdline-History.

* **Age-Filter**
  Filter nach Zeit:
  * letzte X Minuten
  * heute
  * letzte Sitzung
    Besonders hilfreich bei sehr großer Historie.

* **Frequency-Ranking**
  Sortierung nach Häufigkeit statt nur nach Zeit.
  Kombination aus:
  * recency
  * usage count
    Ähnlich wie „most used commands“.

---

## Sicherheit und Fehlerminimierung

* **Dangerous-Command Marking**
  Markierung potenziell gefährlicher Befehle, z. B.:
  * `:!rm -rf`
  * `:q!`
  * `:bwipeout`
  * `:lua vim.api.nvim_buf_delete(0, { force = true })`
    Nur visuell, keine Blockade.

* **Confirmation Overlay**
  Optionaler zusätzlicher Prompt vor dem Einfügen bestimmter Muster
  (regex-basiert).

* **Readonly-Mode**
  Modus, in dem keinerlei Einträge als Favoriten gespeichert werden
  (nützlich auf fremden Systemen).

---

## Picker-UX und Interaktion

* **Inline-Editing**
  Möglichkeit, einen History-Eintrag vor dem Einfügen kurz zu editieren
  (z. B. mit `<C-e>` → kleines Floating-Input-Fenster).

* **Multi-Select**
  Mehrere Einträge auswählen und:
  * in ein Scratch-Buffer einfügen
  * als Makro speichern
  * als Script exportieren

* **Pinned Commands**
  Ähnlich wie Favorites, aber:
  * immer oben
  * getrennt von normalen Favoriten
    Gut für „Daily Driver“-Commands.

* **Context-Aware Defaults**
  Automatische Vorauswahl:
  * `:edit` → wenn aktueller Buffer leer
  * `:grep` → wenn Projekt root erkannt wurde

---

## Integration mit Neovim-Ökosystem

* **which-key Integration**
  Dynamische which-key Anzeige:
  * letzte X Befehle
  * Favoriten
  * Pinned Commands

* **Command-Line Completion Source**
  nvim-cmp Source für:
  * History
  * Favorites
    Direkt während der `:`-Eingabe.

* **Statusline / Winbar Indicator**
  Anzeige:
  * letztes Kommando
  * Favoriten-Count
  * History-Größe

---

## Export, Import, Automatisierung

* **Export Commands**
  Export ausgewählter Einträge als:
  * `.vim` Script
  * `.lua` Config-Snippet
  * `.sh` Shell-Script

* **Command Templates**
  Platzhalterbasierte Commands, z. B.:

  ```
  :grep {{word}} {{root}}
  ```

  Beim Einfügen wird interaktiv nach Werten gefragt.

* **History Cleanup Tools**
  Interaktive Aktionen:
  * Duplikate entfernen
  * sehr alte Einträge löschen
  * Einträge nach Regex löschen

---

## Technisch besonders gut passend

 **Inline-Editing vor Insert**
 **Frequency-Ranking**
 **Session-lokale History**
 **nvim-cmp Source für `:`**
 **Command Templates**

---
