# Security Policy

## サポート対象バージョン

FleetKanban は Phase 1 開発中のため、**現時点では最新の `main` のみ**がサポート対象です。
Phase 1 GA (v0.1.0) 以降は最新 minor の 1 つ前までをサポートする予定です。

| Version | Supported |
| --- | --- |
| `main` (pre-release) | ✅ |
| それ以外 | ❌ |

## 脆弱性の報告方法

**public な GitHub Issue で脆弱性を報告しないでください。**

以下のいずれかの経路で non-public に報告してください。報告内容は 72 時間以内に一次応答します。

1. **GitHub Security Advisories** (推奨)
   - リポジトリの [Security タブ](../../security/advisories/new) から "Report a vulnerability" を開き、内容を記入して送信
   - Private な議論 / 修正パッチのレビュー / CVE 発行まで一貫して行えます

2. **メール**
   - 件名冒頭に `[FleetKanban SECURITY]` を付与し、以下を含めてください:
     - 影響するコンポーネント (sidecar / ui / proto / build など)
     - 再現手順
     - 想定される影響範囲 (RCE / データ漏洩 / DoS など)
     - 参考リンク (該当 PoC / CVE / 過去事例)

## 報告者への対応

| 段階 | 期限 (目安) |
| --- | --- |
| 一次応答 (受領確認) | 72 時間以内 |
| 初期トリアージ (重大度判定) | 7 日以内 |
| 修正版リリース | 重大度に応じて 14〜90 日 |
| 公開 advisory 発行 | 修正リリース後すみやかに |

重大度は [CVSS 4.0](https://www.first.org/cvss/v4-0/) に基づき判定し、必要に応じて修正までの
日数を調整します。**responsible disclosure** を前提に、合意された日数が経過するまでは
詳細の公開を控えてください。

## スコープ外の報告

以下は脆弱性として扱いません:

- ソースコードをビルドした手元バイナリが Windows SmartScreen で警告される件
  (Phase 1 はコード署名なしで配布するため仕様)
- ローカル管理者権限を取得したユーザによる DPAPI 復号
  (DPAPI は同一ユーザスコープで動作する前提の設計)
- Copilot CLI 本体 / GitHub API / Windows OS 自体の脆弱性
  (該当する上流プロジェクトへ報告してください)

## 安全なデフォルト

FleetKanban が守っているセキュリティ上の設計原則を明記しておきます:

- **gRPC は 127.0.0.1 のみ bind、token 認証必須** (`sidecar/cmd/fleetkanban-sidecar/main.go`)
- **GitHub PAT は Windows DPAPI で暗号化** し、ユーザスコープに限定 (`sidecar/internal/app/secrets_dpapi.go`)
- **Copilot セッションは worktree の cwd 外へ書き込めない**
  (`sidecar/internal/copilot/permission.go` の `ResolvePath` で canonical path 比較)
- **Goal / ReviewFeedback はサニタイズ** してからプロンプトに埋め込む
  (`sidecar/internal/copilot/prompt.go`)
- **自動 push / 自動 PR / 自動 merge を恒久的に禁止**
