# FleetKanban — UI (Flutter Windows desktop)

このディレクトリは FleetKanban の Flutter 製 UI (`fleetkanban_ui.exe`) のソースです。起動時に `../sidecar/` をビルドしてできる `fleetkanban-sidecar.exe` を子プロセス起動し、loopback gRPC で通信します。

プロジェクト全体の概要・アーキテクチャはリポジトリルートの [README.md](../README.md) と [docs/architecture.md](../docs/architecture.md) を参照してください。

## このディレクトリの構成

```
ui/
├── pubspec.yaml               # Flutter パッケージ定義（fluent_ui / grpc / riverpod 等）
├── analysis_options.yaml
├── lib/
│   ├── main.dart              # エントリポイント
│   ├── app/                   # アプリシェル・ルーティング・テーマ
│   ├── domain/                # UI 側 domain モデル
│   ├── features/              # 画面単位（kanban / terminal / review / settings）
│   ├── infra/
│   │   └── ipc/               # gRPC クライアント + sidecar supervisor + 生成 proto
│   └── theme/
└── windows/                   # flutter create windows/ テンプレート
```

## よく使うコマンド（ルートから実行）

| コマンド | 何をするか |
|---|---|
| `task flutter:pub` | `flutter pub get` |
| `task flutter:run` | sidecar をビルド後、`flutter run -d windows` |
| `task flutter:build` | Windows リリースビルド + sidecar 同梱 |
| `task build:msix` | MSIX パッケージ生成 |
| `task proto:gen:dart` | Dart gRPC スタブを `lib/infra/ipc/generated/` に再生成 |

## ライセンス

MIT — リポジトリルートの [LICENSE](../LICENSE) を参照。
