# FleetKanban

[English](./README.md) | [日本語](./README.ja.md) | [简体中文](./README.zh-CN.md) | [Русский](./README.ru.md) | [Español](./README.es.md) | [Deutsch](./README.de.md) | **Português (BR)**

<!-- TODO(phase1): replace with docs/screenshots/hero-kanban-board.png -->
<p align="center">
  <img src="docs/screenshots/coming-soon.png"
       alt="Quadro Kanban do FleetKanban com várias tarefas de IA rodando em paralelo (screenshot prevista para a Phase 1)"
       width="880">
</p>

<p align="center">
  <b>Executor autônomo de tarefas multi-agente para o seu desktop Windows 11.</b><br>
  Descreva o que você quer. Ele planeja, executa tarefas em paralelo em git worktrees isolados
  e entrega cada diff de volta para você tomar a decisão final.
</p>

<p align="center">
  <a href="#download"><img src="https://img.shields.io/badge/Download-Windows%2011-0078D4?logo=windows11&logoColor=white" alt="Baixar para Windows 11"></a>
  <img src="https://img.shields.io/badge/status-Early%20Preview-orange" alt="Early Preview">
  <img src="https://img.shields.io/badge/license-MIT-blue" alt="Licença MIT">
  <img src="https://img.shields.io/badge/platform-Windows%2011%20only-blue" alt="Somente Windows 11">
</p>

---

## Por que o FleetKanban

- **Planeja → executa em paralelo → você aprova.** A IA planeja a implementação, executa até 12 tarefas em paralelo em git worktrees isolados e deixa a decisão final de **Keep / Merge / Discard** para você.
- **Nunca escreve no seu remote.** Sem `git push`, sem criação de PR, sem auto-merge — escritas no remote só acontecem quando você mesmo as faz.
- **Sem telemetria. Seguro para o ambiente corporativo.** Sem analytics de uso, sem relatórios de falhas, sem phone-home. O único tráfego de saída são as chamadas à API do Copilot que seus agentes fazem — seguro para implantar dentro do perímetro corporativo.
- **Um app Windows 11 de verdade.** Mica / Acrylic, Jump List, notificações Toast, progresso na barra de tarefas — construído com Flutter desktop, não Electron.

## Download

- Último build: [GitHub Releases](https://github.com/haya3/FleetKanban/releases/latest) → `com.fleetkanban.FleetKanban-win-Setup.exe`
- Você precisa de: **Windows 11 64 bits** · **Assinatura do GitHub Copilot** · **Git for Windows**
- Após a instalação, o app **se atualiza sozinho com um clique** a partir de um InfoBar dentro do próprio app.

> **Early Preview.** O FleetKanban está em desenvolvimento na Phase 1. Até o primeiro release marcado por tag sair, consulte [CONTRIBUTING.md](./CONTRIBUTING.md) para compilar a partir do código-fonte hoje.

> **SmartScreen.** A Phase 1 é distribuída sem assinatura, então o Windows SmartScreen exibirá "O Windows protegeu seu PC" no primeiro lançamento. Clique em "Mais informações" → "Executar mesmo assim" para continuar. Assinatura EV / Azure Trusted Signing está prevista para a Phase 2.

## Como funciona

1. **Descreva sua tarefa em linguagem natural**
   Por exemplo: *"Atualizar a barra lateral para suportar o modo escuro."*
   <!-- TODO(phase1): replace with docs/screenshots/how-1-new-task.png -->
   <img src="docs/screenshots/coming-soon.png" alt="Diálogo de nova tarefa no quadro Kanban" width="720">

2. **A IA planeja e divide em um DAG de subtarefas**
   O estágio Plan produz um plano de execução e decompõe o trabalho em subtarefas paralelas / seriais, visualizadas com um layout Sugiyama.
   <!-- TODO(phase1): replace with docs/screenshots/how-2-subtask-dag.png -->
   <img src="docs/screenshots/coming-soon.png" alt="Visualização do Subtask DAG mostrando dependências paralelas e seriais" width="720">

3. **Execução paralela em git worktrees isolados**
   4 tarefas em paralelo por padrão, até 12. Cada subtarefa roda em seu próprio git worktree — seu branch `main` permanece limpo e as tarefas nunca colidem.
   <!-- TODO(phase1): replace with docs/screenshots/how-3-parallel-running.png -->
   <img src="docs/screenshots/coming-soon.png" alt="Várias tarefas de IA rodando em paralelo no quadro Kanban" width="720">

4. **Revisão da IA → Revisão humana**
   Depois da auto-revisão da IA, você lê o diff e escolhe **Keep / Merge / Discard**. Nada é mesclado automaticamente.
   <!-- TODO(phase1): replace with docs/screenshots/how-4-diff-review.png -->
   <img src="docs/screenshots/coming-soon.png" alt="Painel de revisão de diff com ações Keep, Merge e Discard" width="720">

## O que torna o FleetKanban diferente

O FleetKanban segue um caminho deliberadamente distinto do Claude Code, Cursor e GitHub Copilot Workspace:

- **Desktop Windows 11 nativo.** Não é uma IDE web, não é um fork do VS Code. Fluent Design, Mica, Jump List e progresso na barra de tarefas são todos de primeira classe.
- **Muitas tarefas em paralelo, totalmente isoladas.** Execute várias tarefas independentes contra o mesmo repositório ao mesmo tempo — branches e working trees nunca colidem.
- **Totalmente local.** Estado de tarefas, logs e a base de conhecimento do repositório vivem em SQLite sob `%APPDATA%`. Seu código não é enviado para um serviço em nuvem (o tráfego da API do Copilot é o mesmo de qualquer outro cliente Copilot).
- **Um runtime de agente desenhável (IHR).** O Intelligent Harness Runtime guia as transições dos estágios Plan / Code / Review a partir de um charter YAML que você pode editar a quente na UI. O comportamento é desenhado, não escondido.
- **Grafo de propriedades + FTS5 + embeddings.** O FleetKanban indexa seu repo como uma Context / Graph Memory e injeta apenas o contexto relevante em cada sessão do agente, em três camadas (Passive / Reactive / Active) fundidas via RRF.

## Requisitos

- Windows 11 64 bits
- Assinatura do GitHub Copilot (Individual, Business ou Enterprise)
- Git for Windows 2.45+
- PowerShell 7 (o app oferece instalação de um clique no primeiro lançamento, caso não esteja presente)

Pré-requisitos completos e flags para pular em CI ficam em [CONTRIBUTING.md](./CONTRIBUTING.md#environment-setup).

## FAQ

- **Meu código é enviado para a nuvem?** Estado de tarefas, logs e o índice de conhecimento são todos armazenados localmente em SQLite. Quando o agente roda, o SDK Copilot fala com a API do GitHub Copilot exatamente como qualquer outro cliente Copilot — nada mais sai da sua máquina.
- **O FleetKanban coleta telemetria?** Não. Não há analytics de uso, não há relatórios de falhas e não há endpoint de phone-home. O único tráfego de saída do app são as chamadas à API do Copilot que o agente faz durante a execução das tarefas (o mesmo que qualquer outro cliente Copilot) mais a verificação de versão que o prompt de atualização dentro do app executa contra o GitHub Releases. Isso torna o FleetKanban seguro para implantar em ambientes corporativos — combine-o com uma assinatura Copilot Business ou Enterprise e seu código permanece dentro do perímetro corporativo.
- **Ele vai fazer push para o meu remote sozinho?** Não. `git push`, criação de PR e auto-merge simplesmente não estão implementados. Fazer push e abrir PRs é algo que você faz explicitamente, usando o Git CLI, o GitHub Desktop ou sua IDE.
- **Funciona no macOS / Linux?** Não. O FleetKanban é somente Windows 11 64 bits — permanentemente.

## Documentação e links

- [docs/architecture.md](./docs/architecture.md) — arquitetura interna
- [docs/roadmap.md](./docs/roadmap.md) — planos das Phase 2 / 3
- [CHANGELOG.md](./CHANGELOG.md) — histórico de versões
- [CONTRIBUTING.md](./CONTRIBUTING.md) — fluxo de build e desenvolvimento (para desenvolvedores que queiram experimentar a partir do código-fonte)
- [CODE_OF_CONDUCT.md](./CODE_OF_CONDUCT.md)

## Segurança

Se você encontrar uma vulnerabilidade, **não abra uma Issue pública.** Siga o procedimento em [SECURITY.md](./SECURITY.md) e reporte de forma não pública via GitHub Security Advisories (aba Security do repositório).

## Licença

MIT — veja [LICENSE](./LICENSE).
