# Implementierungspahsen des `notes`-Features

## Table of content

  - [Phase 1 umsetzen: Config + Typen](#phase-1-umsetzen-config-typen)
  - [Danach: Phase 2 vorbereiten (ohne UI)](#danach-phase-2-vorbereiten-ohne-ui)
  - [Empfohlene Reihenfolge der Dateien](#empfohlene-reihenfolge-der-dateien)

---

## Phase 1 umsetzen: Config + Typen

1. `lua/cmdlog/config.lua` erweitern
   * Defaults ergänzen
   * Merge-Logik unverändert lassen

Beispiel-Struktur (inhaltlich, noch ohne Code-Änderung an UI/Core):

* notes.enabled: boolean
* notes.format: "markdown" | "text"
* notes.dir: string (Standard unter `stdpath("data")/cmdlog/notes`)
* notes.autosave: boolean (Default true)

---

2. `lua/cmdlog/@types/config.lua` anpassen

   * EmmyLua-Typ `CmdlogNotesConfig`
   * Feld `notes?: CmdlogNotesConfig`

---

3. Validierungsregeln festlegen

   * Wenn `enabled == false` → Notes-Code wird nie geladen
   * Wenn `dir` leer oder ungültig → Fallback auf Default
   * `format` beeinflusst nur `filetype`, sonst nichts

---

## Danach: Phase 2 vorbereiten (ohne UI)

* `cmdlog.core.notes`
  * nur:
    * Pfadauflösung
    * Key-Normalisierung
    * Buffer-Erstellung
    * Save/Load
  * keinerlei Picker- oder Preview-Abhängigkeit

---

## Empfohlene Reihenfolge der Dateien

1. `@types/config.lua`
2. `config.lua`
3. `core/notes.lua`
4. Mini-Test: `:lua require("cmdlog.core.notes")`

---

Wenn diese Phase steht, kann im nächsten Schritt gezielt:

* `telescope_previewer.lua` erweitert werden
* ohne Risiko für Regressionen in den Pickern

---
