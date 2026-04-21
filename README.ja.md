# FleetKanban

[English](./README.md) | **日本語** | [简体中文](./README.zh-CN.md) | [Русский](./README.ru.md) | [Español](./README.es.md) | [Deutsch](./README.de.md) | [Português (BR)](./README.pt-BR.md)

<!-- TODO(phase1): replace with docs/screenshots/hero-kanban-board.png -->
<p align="center">
  <img src="docs/screenshots/coming-soon.png"
       alt="複数の AI タスクが並列実行される FleetKanban の Kanban ボード (スクリーンショットは Phase 1 で公開予定)"
       width="880">
</p>

<p align="center">
  <b>Windows 11 デスクトップのための自律型マルチエージェント タスクランナー。</b><br>
  やりたいことを記述するだけで、AI が計画を立て、隔離された git worktree 上でタスクを並列実行し、
  すべての diff の最終判断をユーザに委ねます。
</p>

<p align="center">
  <a href="#download"><img src="https://img.shields.io/badge/Download-Windows%2011-0078D4?logo=windows11&logoColor=white" alt="Download for Windows 11"></a>
  <img src="https://img.shields.io/badge/status-Early%20Preview-orange" alt="Early Preview">
  <img src="https://img.shields.io/badge/license-MIT-blue" alt="MIT License">
  <img src="https://img.shields.io/badge/platform-Windows%2011%20only-blue" alt="Windows 11 only">
</p>

---

## なぜ FleetKanban なのか

- **Plan → 並列実行 → ユーザ承認。** AI が実装を計画し、隔離された git worktree 上で最大 12 タスクを並列実行し、最終的な **Keep / Merge / Discard** の判断はユーザに委ねます。
- **自動リモート書き込みなし。** `git push`・PR 作成・自動マージは行いません — リモートへの書き込みはユーザ自身の手で行うときのみ発生します。
- **テレメトリなし。エンタープライズでも安全。** 利用アナリティクスもクラッシュレポートも phone-home もありません。アプリから外部へ出るトラフィックはエージェントが呼び出す Copilot API のみ — エンタープライズ境界の内側に安心して展開できます。
- **本物の Windows 11 アプリ。** Mica / Acrylic、Jump List、Toast 通知、タスクバープログレス — Electron ではなく Flutter デスクトップで構築されています。

## Download

- 最新ビルド: [GitHub Releases](https://github.com/FleetKanban/fleetkanban/releases/latest) → `com.fleetkanban.FleetKanban-win-Setup.exe`
- 必要環境: **Windows 11 64-bit** ・ **GitHub Copilot サブスクリプション** ・ **Git for Windows**
- インストール後は、アプリ内 InfoBar から **ワンクリックで自己更新** します。

> **Early Preview。** FleetKanban は Phase 1 開発中です。初回タグ付きリリースが到着するまでは、[CONTRIBUTING.md](./CONTRIBUTING.md) を参照してソースからビルドしてください。

> **SmartScreen。** Phase 1 は未署名で出荷されるため、Windows SmartScreen が初回起動時に「Windows によって PC が保護されました」を表示します。「詳細情報」→「実行」を選択して続行してください。EV 署名 / Azure Trusted Signing は Phase 2 で導入予定です。

## 仕組み

1. **自然言語でタスクを記述する**
   例: *「サイドバーをダークモード対応にする。」*
   <!-- TODO(phase1): replace with docs/screenshots/how-1-new-task.png -->
   <img src="docs/screenshots/coming-soon.png" alt="Kanban ボード上の新規タスクダイアログ" width="720">

2. **AI が計画し Subtask DAG に分解する**
   Plan ステージが実行計画を生成し、作業を並列/直列の Subtask に分解して Sugiyama レイアウトで可視化します。
   <!-- TODO(phase1): replace with docs/screenshots/how-2-subtask-dag.png -->
   <img src="docs/screenshots/coming-soon.png" alt="並列/直列の依存関係を示す Subtask DAG の可視化" width="720">

3. **隔離された git worktree 上での並列実行**
   既定で 4 タスク並列、最大 12 タスクまで。各 Subtask は専用の git worktree で実行されるため、`main` ブランチはクリーンなままで、タスク同士が衝突することもありません。
   <!-- TODO(phase1): replace with docs/screenshots/how-3-parallel-running.png -->
   <img src="docs/screenshots/coming-soon.png" alt="Kanban ボード上で並列実行される複数の AI タスク" width="720">

4. **AI Review → Human Review**
   AI がセルフレビューを行ったのち、ユーザが diff を確認して **Keep / Merge / Discard** を選択します。自動マージは一切ありません。
   <!-- TODO(phase1): replace with docs/screenshots/how-4-diff-review.png -->
   <img src="docs/screenshots/coming-soon.png" alt="Keep / Merge / Discard アクションを備えた diff レビューペイン" width="720">

## FleetKanban の何が違うのか

FleetKanban は Claude Code、Cursor、GitHub Copilot Workspace とは意図的に異なる道を選んでいます。

- **ネイティブ Windows 11 デスクトップ。** Web IDE でも VS Code フォークでもありません。Fluent Design、Mica、Jump List、タスクバープログレスはすべて第一級の機能です。
- **多数のタスクを完全隔離で並列実行。** 同じリポジトリに対して複数の独立したタスクを同時に走らせられます — ブランチや作業ツリーが衝突することはありません。
- **完全ローカル。** タスク状態・ログ・リポジトリ知識ベースは `%APPDATA%` 配下の SQLite に保存されます。ユーザのコードがクラウドサービスに送信されることはありません (Copilot API のトラフィックは他の Copilot クライアントと同等です)。
- **設計可能なエージェントランタイム (IHR)。** Intelligent Harness Runtime は Plan / Code / Review のステージ遷移を、UI からホット編集できる YAML charter で駆動します。挙動は隠されるのではなく、設計されるものです。
- **プロパティグラフ + FTS5 + 埋め込み。** FleetKanban はリポジトリを Context / Graph Memory としてインデックス化し、関連する文脈のみを 3 段 (Passive / Reactive / Active) で RRF により融合して各エージェントセッションへ注入します。

## 必要環境

- Windows 11 64-bit
- GitHub Copilot サブスクリプション (Individual / Business / Enterprise)
- Git for Windows 2.45+
- PowerShell 7 (未インストールの場合は初回起動時にワンクリックでのインストールを提案します)

すべての前提条件と CI スキップフラグは [CONTRIBUTING.md](./CONTRIBUTING.md#environment-setup) に記載しています。

## FAQ

- **自分のコードはクラウドに送信されますか?** タスク状態・ログ・知識インデックスはすべて SQLite にローカル保存されます。エージェント実行時に Copilot SDK が GitHub Copilot API と通信するのは他の Copilot クライアントと同等で、それ以外のデータがマシンを離れることはありません。
- **FleetKanban はテレメトリを収集しますか?** いいえ。利用アナリティクス・クラッシュレポート・phone-home エンドポイントのいずれも存在しません。アプリから外部へ出るトラフィックは、タスク実行中にエージェントが呼び出す Copilot API (他の Copilot クライアントと同等) と、アプリ内アップデートプロンプトが GitHub Releases に対して行うバージョン確認のみです。これにより FleetKanban はエンタープライズ環境でも安全にデプロイでき、Copilot Business / Enterprise サブスクリプションと組み合わせればコードはエンタープライズ境界の内側にとどまります。
- **アプリが自分でリモートへ push しますか?** いいえ。`git push`・PR 作成・自動マージは実装されていません。push や PR のオープンはユーザが明示的に Git CLI / GitHub Desktop / IDE から行います。
- **macOS / Linux で動きますか?** いいえ。FleetKanban は Windows 11 64-bit 専用です — 恒久的に。

## ドキュメント & リンク

- [docs/architecture.md](./docs/architecture.md) — 内部アーキテクチャ
- [docs/roadmap.md](./docs/roadmap.md) — Phase 2 / 3 の計画
- [CHANGELOG.md](./CHANGELOG.md) — バージョン履歴
- [CONTRIBUTING.md](./CONTRIBUTING.md) — ビルドと開発フロー (ソースから試したい開発者向け)
- [CODE_OF_CONDUCT.md](./CODE_OF_CONDUCT.md)

## セキュリティ

脆弱性を発見した場合、**公開 Issue を作成しないでください。** [SECURITY.md](./SECURITY.md) の手順に従い、GitHub Security Advisories (リポジトリの Security タブ) から非公開で報告してください。

## ライセンス

MIT — [LICENSE](./LICENSE) を参照してください。
