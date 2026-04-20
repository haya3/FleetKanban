## Summary

<!-- 何を変えるか・なぜ変えるかを 1-3 項目 -->

-
-

## 関連 Issue

<!-- Closes #<issue> / Refs #<issue> -->

## Test plan

<!-- レビュアーが検証できるチェックリスト -->

- [ ] `task lint` が green
- [ ] `task test` が green
- [ ] Flutter: `cd ui && flutter analyze` が green
- [ ] (proto 変更時) `task proto:gen:all` を実行し、`ProtocolVersion` を bump した
- [ ] (sidecar 変更時) `build/bin/fleetkanban-sidecar.exe` を再ビルドした
- [ ] 手元の Windows 11 で該当シナリオを手動確認した

## スクリーンショット / ログ

<!-- UI 変更がある場合はスクショ、挙動変更がある場合はログ -->

## チェックリスト

- [ ] 非自明な判断には **なぜ** を 1 行コメントで残した
- [ ] 仕様変更があれば `CHANGELOG.md` の Unreleased に追記した
- [ ] セキュリティに影響する変更は [SECURITY.md](../SECURITY.md) の原則に照らして確認した
