# FleetKanban

[English](./README.md) | [日本語](./README.ja.md) | [简体中文](./README.zh-CN.md) | [Русский](./README.ru.md) | **Español** | [Deutsch](./README.de.md) | [Português (BR)](./README.pt-BR.md)

<!-- TODO(phase1): replace with docs/screenshots/hero-kanban-board.png -->
<p align="center">
  <img src="docs/screenshots/coming-soon.png"
       alt="Tablero Kanban de FleetKanban con múltiples tareas de IA ejecutándose en paralelo (captura disponible en Phase 1)"
       width="880">
</p>

<p align="center">
  <b>Ejecutor autónomo multi-agente de tareas para tu escritorio Windows 11.</b><br>
  Describe lo que quieres. Él planifica, ejecuta tareas en paralelo sobre git worktrees aislados
  y te entrega cada diff para que tomes la decisión final.
</p>

<p align="center">
  <a href="#download"><img src="https://img.shields.io/badge/Download-Windows%2011-0078D4?logo=windows11&logoColor=white" alt="Descarga para Windows 11"></a>
  <img src="https://img.shields.io/badge/status-Early%20Preview-orange" alt="Early Preview">
  <img src="https://img.shields.io/badge/license-MIT-blue" alt="Licencia MIT">
  <img src="https://img.shields.io/badge/platform-Windows%2011%20only-blue" alt="Solo Windows 11">
</p>

---

## Por qué FleetKanban

- **Plan → ejecución en paralelo → tú apruebas.** La IA planifica la implementación, ejecuta hasta 12 tareas en paralelo sobre git worktrees aislados y deja la decisión final de **Keep / Merge / Discard** en tus manos.
- **Nunca escribe en tu remoto.** Nada de `git push`, nada de creación de PR, nada de auto-merge — las escrituras remotas solo ocurren cuando las haces tú mismo.
- **Sin telemetría. Segura para el entorno empresarial.** Sin analíticas de uso, sin informes de fallos, sin llamadas a casa. El único tráfico saliente son las llamadas a la API de Copilot que hacen tus agentes — segura para desplegarse tras el perímetro de un entorno empresarial.
- **Una aplicación Windows 11 de verdad.** Mica / Acrylic, Jump List, notificaciones Toast, progreso en la barra de tareas — construida con Flutter desktop, no con Electron.

## Download

- Última build: [GitHub Releases](https://github.com/haya3/FleetKanban/releases/latest) → `com.fleetkanban.FleetKanban-win-Setup.exe`
- Necesitas: **Windows 11 de 64 bits** · **Suscripción a GitHub Copilot** · **Git for Windows**
- Tras la instalación, la app **se actualiza sola con un clic** desde un InfoBar dentro de la propia aplicación.

> **Early Preview.** FleetKanban está en desarrollo de Phase 1. Hasta que llegue el primer release etiquetado, consulta [CONTRIBUTING.md](./CONTRIBUTING.md) para compilarlo desde el código fuente hoy mismo.

> **SmartScreen.** Phase 1 se distribuye sin firma, por lo que Windows SmartScreen mostrará «Windows protegió su equipo» en el primer arranque. Pulsa «Más información» → «Ejecutar de todas formas» para continuar. La firma EV / Azure Trusted Signing está planificada para Phase 2.

## Cómo funciona

1. **Describe tu tarea en lenguaje natural**
   Por ejemplo: *«Actualiza la barra lateral para que soporte modo oscuro».*
   <!-- TODO(phase1): replace with docs/screenshots/how-1-new-task.png -->
   <img src="docs/screenshots/coming-soon.png" alt="Diálogo de nueva tarea en el tablero Kanban" width="720">

2. **La IA planifica y lo divide en un DAG de subtareas**
   La etapa Plan produce un plan de ejecución y descompone el trabajo en subtareas paralelas / seriales, visualizadas con un layout Sugiyama.
   <!-- TODO(phase1): replace with docs/screenshots/how-2-subtask-dag.png -->
   <img src="docs/screenshots/coming-soon.png" alt="Visualización del DAG de subtareas mostrando dependencias paralelas y seriales" width="720">

3. **Ejecución paralela sobre git worktrees aislados**
   4 tareas en paralelo por defecto, hasta 12. Cada subtarea corre en su propio git worktree — tu rama `main` permanece limpia y las tareas nunca colisionan.
   <!-- TODO(phase1): replace with docs/screenshots/how-3-parallel-running.png -->
   <img src="docs/screenshots/coming-soon.png" alt="Múltiples tareas de IA ejecutándose en paralelo en el tablero Kanban" width="720">

4. **AI Review → Human Review**
   Después de la auto-revisión de la IA, tú lees el diff y eliges **Keep / Merge / Discard**. Nada se mergea automáticamente.
   <!-- TODO(phase1): replace with docs/screenshots/how-4-diff-review.png -->
   <img src="docs/screenshots/coming-soon.png" alt="Panel de revisión de diff con las acciones Keep, Merge y Discard" width="720">

## Qué hace diferente a FleetKanban

FleetKanban toma un camino deliberadamente distinto al de Claude Code, Cursor y GitHub Copilot Workspace:

- **Escritorio Windows 11 nativo.** No es un IDE web, ni un fork de VS Code. Fluent Design, Mica, Jump List y el progreso en la barra de tareas son ciudadanos de primera clase.
- **Muchas tareas en paralelo, totalmente aisladas.** Ejecuta varias tareas independientes contra el mismo repositorio a la vez — ramas y árboles de trabajo nunca colisionan.
- **Totalmente local.** El estado de tareas, los logs y la base de conocimiento del repositorio viven en SQLite bajo `%APPDATA%`. Tu código no se envía a un servicio en la nube (el tráfico de la API de Copilot es el mismo que el de cualquier otro cliente Copilot).
- **Un runtime de agente diseñable (IHR).** El Intelligent Harness Runtime conduce las transiciones de etapa Plan / Code / Review desde un charter YAML que puedes hot-editar desde la UI. El comportamiento está diseñado, no oculto.
- **Grafo de propiedades + FTS5 + embeddings.** FleetKanban indexa tu repo como una Context / Graph Memory e inyecta solo el contexto relevante en cada sesión del agente, en tres capas (Passive / Reactive / Active) fusionadas con RRF.

## Requisitos

- Windows 11 de 64 bits
- Suscripción a GitHub Copilot (Individual, Business o Enterprise)
- Git for Windows 2.45+
- PowerShell 7 (la app ofrece instalación de un clic en el primer arranque si no está presente)

Los prerrequisitos completos y los flags de skip para CI viven en [CONTRIBUTING.md](./CONTRIBUTING.md#environment-setup).

## FAQ

- **¿Se envía mi código a la nube?** El estado de tareas, los logs y el índice de conocimiento se almacenan localmente en SQLite. Cuando el agente se ejecuta, el SDK Copilot habla con la API de GitHub Copilot igual que cualquier otro cliente Copilot — nada más sale de tu máquina.
- **¿FleetKanban recopila telemetría?** No. No hay analíticas de uso, ni reportes de fallos, ni endpoint de llamada a casa. El único tráfico saliente de la aplicación son las llamadas a la API de Copilot que el agente realiza durante la ejecución de tareas (lo mismo que cualquier otro cliente Copilot) más la comprobación de versión que el aviso de actualización integrado realiza contra GitHub Releases. Esto hace que FleetKanban sea segura para desplegarse en entornos empresariales — combínala con una suscripción Copilot Business o Enterprise y tu código permanece dentro del perímetro del entorno empresarial.
- **¿Hará push a mi remoto por sí solo?** No. `git push`, la creación de PR y el auto-merge simplemente no están implementados. El push y la apertura de PRs son algo que haces tú explícitamente, usando Git CLI, GitHub Desktop o tu IDE.
- **¿Funciona en macOS / Linux?** No. FleetKanban es solo Windows 11 de 64 bits — de forma permanente.

## Documentación y enlaces

- [docs/architecture.md](./docs/architecture.md) — arquitectura interna
- [docs/roadmap.md](./docs/roadmap.md) — planes de Phase 2 / 3
- [CHANGELOG.md](./CHANGELOG.md) — historial de versiones
- [CONTRIBUTING.md](./CONTRIBUTING.md) — flujo de build y desarrollo (para desarrolladores que quieran probarlo desde el código fuente)
- [CODE_OF_CONDUCT.md](./CODE_OF_CONDUCT.md)

## Seguridad

Si encuentras una vulnerabilidad, **no abras un Issue público.** Sigue el procedimiento de [SECURITY.md](./SECURITY.md) e informa de forma no pública a través de GitHub Security Advisories (la pestaña Security del repositorio).

## Licencia

MIT — consulta [LICENSE](./LICENSE).
