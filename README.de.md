# FleetKanban

[English](./README.md) | [日本語](./README.ja.md) | [简体中文](./README.zh-CN.md) | [Русский](./README.ru.md) | [Español](./README.es.md) | **Deutsch** | [Português (BR)](./README.pt-BR.md)

<!-- TODO(phase1): replace with docs/screenshots/hero-kanban-board.png -->
<p align="center">
  <img src="docs/screenshots/coming-soon.png"
       alt="FleetKanban-Kanban-Board mit mehreren parallel laufenden KI-Tasks (Screenshot folgt in Phase 1)"
       width="880">
</p>

<p align="center">
  <b>Autonomer Multi-Agent-Task-Runner für Ihren Windows-11-Desktop.</b><br>
  Beschreiben Sie, was Sie möchten. FleetKanban plant, führt Tasks parallel auf isolierten git worktrees aus
  und übergibt Ihnen jeden Diff für die finale Entscheidung.
</p>

<p align="center">
  <a href="#download"><img src="https://img.shields.io/badge/Download-Windows%2011-0078D4?logo=windows11&logoColor=white" alt="Download für Windows 11"></a>
  <img src="https://img.shields.io/badge/status-Early%20Preview-orange" alt="Early Preview">
  <img src="https://img.shields.io/badge/license-MIT-blue" alt="MIT-Lizenz">
  <img src="https://img.shields.io/badge/platform-Windows%2011%20only-blue" alt="Nur Windows 11">
</p>

---

## Warum FleetKanban

- **Plan → parallele Ausführung → Sie entscheiden.** Die KI plant die Implementierung, führt bis zu 12 Tasks parallel auf isolierten git worktrees aus und überlässt die finale Entscheidung **Keep / Merge / Discard** Ihnen.
- **Schreibt niemals in Ihr Remote.** Kein `git push`, keine PR-Erzeugung, kein Auto-Merge — Remote-Schreibvorgänge geschehen nur, wenn Sie sie selbst ausführen.
- **Keine Telemetrie. Sicher für Unternehmen.** Keine Nutzungsanalyse, keine Absturzberichte, kein Phone-Home. Der einzige ausgehende Datenverkehr sind die Copilot-API-Aufrufe, die Ihre Agenten durchführen — sicher für den Rollout innerhalb einer Unternehmensumgebung.
- **Eine echte Windows-11-App.** Mica / Acrylic, Jump List, Toast-Benachrichtigungen, Taskleisten-Fortschritt — gebaut mit Flutter Desktop, nicht mit Electron.

## Download

- Aktueller Build: [GitHub Releases](https://github.com/haya3/fleetkanban/releases/latest) → `com.fleetkanban.FleetKanban-win-Setup.exe`
- Sie benötigen: **Windows 11 64-Bit** · **GitHub-Copilot-Abo** · **Git for Windows**
- Nach der Installation aktualisiert sich die App **per Klick aus einer In-App-InfoBar** selbst.

> **Early Preview.** FleetKanban befindet sich in der Phase-1-Entwicklung. Bis das erste getaggte Release erscheint, siehe [CONTRIBUTING.md](./CONTRIBUTING.md), um schon heute aus dem Quellcode zu bauen.

> **SmartScreen.** Phase 1 wird ohne Code-Signatur ausgeliefert, daher zeigt Windows SmartScreen beim ersten Start „Der Computer wurde durch Windows geschützt". Klicken Sie „Weitere Informationen" → „Trotzdem ausführen", um fortzufahren. EV-Signatur / Azure Trusted Signing ist für Phase 2 geplant.

## So funktioniert es

1. **Beschreiben Sie Ihren Task in natürlicher Sprache**
   Zum Beispiel: *„Erweitere die Sidebar um Unterstützung für den Dark Mode."*
   <!-- TODO(phase1): replace with docs/screenshots/how-1-new-task.png -->
   <img src="docs/screenshots/coming-soon.png" alt="Dialog „Neuer Task" auf dem Kanban-Board" width="720">

2. **Die KI plant und zerlegt den Task in einen Subtask-DAG**
   Die Plan-Stufe erzeugt einen Ausführungsplan und teilt die Arbeit in parallele / serielle Subtasks auf, visualisiert mit einem Sugiyama-Layout.
   <!-- TODO(phase1): replace with docs/screenshots/how-2-subtask-dag.png -->
   <img src="docs/screenshots/coming-soon.png" alt="Subtask-DAG-Visualisierung mit parallelen und seriellen Abhängigkeiten" width="720">

3. **Parallele Ausführung auf isolierten git worktrees**
   Standardmäßig 4 Tasks parallel, bis zu 12. Jeder Subtask läuft in seinem eigenen git worktree — Ihr `main`-Branch bleibt sauber und Tasks kollidieren nie.
   <!-- TODO(phase1): replace with docs/screenshots/how-3-parallel-running.png -->
   <img src="docs/screenshots/coming-soon.png" alt="Mehrere parallel laufende KI-Tasks auf dem Kanban-Board" width="720">

4. **KI-Review → Human Review**
   Nachdem die KI ihr Ergebnis selbst reviewed hat, lesen Sie den Diff und wählen **Keep / Merge / Discard**. Nichts wird automatisch gemergt.
   <!-- TODO(phase1): replace with docs/screenshots/how-4-diff-review.png -->
   <img src="docs/screenshots/coming-soon.png" alt="Diff-Review-Bereich mit den Aktionen Keep, Merge und Discard" width="720">

## Was FleetKanban anders macht

FleetKanban geht bewusst einen anderen Weg als Claude Code, Cursor und GitHub Copilot Workspace:

- **Nativer Windows-11-Desktop.** Keine Web-IDE, kein VS-Code-Fork. Fluent Design, Mica, Jump List und Taskleisten-Fortschritt sind erstklassig unterstützt.
- **Viele Tasks parallel, vollständig isoliert.** Führen Sie mehrere unabhängige Tasks gleichzeitig gegen dasselbe Repository aus — Branches und Arbeitsverzeichnisse kollidieren nie.
- **Vollständig lokal.** Task-Status, Logs und die Wissensbasis des Repositorys liegen in SQLite unter `%APPDATA%`. Ihr Code wird nicht an einen Cloud-Dienst geschickt (der Copilot-API-Traffic ist derselbe wie bei jedem anderen Copilot-Client).
- **Eine designbare Agenten-Runtime (IHR).** Die Intelligent Harness Runtime steuert die Plan- / Code- / Review-Stage-Übergänge anhand einer YAML-Charter, die Sie live aus der UI heraus bearbeiten können. Verhalten wird designt, nicht versteckt.
- **Property Graph + FTS5 + Embeddings.** FleetKanban indexiert Ihr Repo als Context / Graph Memory und speist nur den relevanten Kontext in jede Agenten-Session ein, in drei Schichten (Passive / Reactive / Active), über RRF fusioniert.

## Voraussetzungen

- Windows 11 64-Bit
- GitHub-Copilot-Abo (Individual, Business oder Enterprise)
- Git for Windows 2.45+
- PowerShell 7 (die App bietet beim ersten Start eine Ein-Klick-Installation an, falls es fehlt)

Die vollständigen Voraussetzungen und CI-Skip-Flags finden Sie in [CONTRIBUTING.md](./CONTRIBUTING.md#environment-setup).

## FAQ

- **Wird mein Code in die Cloud geschickt?** Task-Status, Logs und der Wissensindex werden allesamt lokal in SQLite gespeichert. Wenn der Agent läuft, spricht das Copilot-SDK mit der GitHub-Copilot-API wie jeder andere Copilot-Client — sonst verlässt nichts Ihre Maschine.
- **Erfasst FleetKanban Telemetrie?** Nein. Es gibt keine Nutzungsanalyse, keine Absturzberichte und keinen Phone-Home-Endpoint. Der einzige ausgehende Datenverkehr der App sind die Copilot-API-Aufrufe, die der Agent während der Task-Ausführung durchführt (genau wie bei jedem anderen Copilot-Client), plus die Versionsprüfung, die die In-App-Update-Anzeige gegen GitHub Releases ausführt. Dadurch lässt sich FleetKanban sicher in Unternehmensumgebungen einsetzen — in Kombination mit einem Copilot-Business- oder -Enterprise-Abonnement bleibt Ihr Code innerhalb der Unternehmensgrenze.
- **Pusht es von sich aus in mein Remote?** Nein. `git push`, PR-Erzeugung und Auto-Merge sind schlicht nicht implementiert. Pushen und PRs öffnen tun Sie explizit selbst, mit der Git-CLI, GitHub Desktop oder Ihrer IDE.
- **Funktioniert es unter macOS / Linux?** Nein. FleetKanban ist ausschließlich Windows-11-64-Bit — dauerhaft.

## Dokumentation & Links

- [docs/architecture.md](./docs/architecture.md) — interne Architektur
- [docs/roadmap.md](./docs/roadmap.md) — Phase-2- / Phase-3-Pläne
- [CHANGELOG.md](./CHANGELOG.md) — Versionshistorie
- [CONTRIBUTING.md](./CONTRIBUTING.md) — Build- & Entwicklungsflow (für Entwickler, die aus dem Quellcode bauen möchten)
- [CODE_OF_CONDUCT.md](./CODE_OF_CONDUCT.md)

## Sicherheit

Wenn Sie eine Schwachstelle finden, **eröffnen Sie bitte kein öffentliches Issue.** Folgen Sie dem Verfahren in [SECURITY.md](./SECURITY.md) und melden Sie die Schwachstelle nicht-öffentlich über GitHub Security Advisories (Security-Tab des Repositorys).

## Lizenz

MIT — siehe [LICENSE](./LICENSE).
