# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## コーディング規約

### テストの記述
- テストの記述（test名、アサーションメッセージなど）は日本語で書く
- 変数名やメソッド名は英語のまま

## アプリケーションアーキテクチャ

このプロジェクトは筋力トレーニングの記録管理を行う Rails 8.0.2 API サーバーです。

### 技術スタック

- Ruby 3.4.5
- Rails 8.0.2+ (API モード)
- MariaDB 11.2
- Docker/Docker Compose 構成

### アプリケーション構成

- Rails の solid_cache、solid_queue、solid_cable を活用した軽量な構成
- バックエンド API 専用（フロントエンドは別プロジェクト）
- ジム・筋トレ記録管理に特化したドメインモデル

## 開発用コマンド

### 環境セットアップ

```bash
docker-compose up --build
```

### 重要な注意事項

このプロジェクトは VSCode Dev Container で開発されています。そのため：

- **bundle install は手動実行が必要**: Gemfile を編集した後は、Dev Container 内のターミナルで `bundle install` を実行してください
- Claude Code から実行した bundle install は Dev Container 内に反映されません
- **テスト実行は手動で行う**: Claude Code はテスト実行を試行しない。テストは開発者が Dev Container 内で手動実行する

### テスト実行

このプロジェクトでは Minitest を使用してテストを記述します。

```bash
# 全テスト実行
rails test

# 特定のテストファイル実行
rails test test/models/user_test.rb

# 特定のテストメソッド実行
rails test test/models/user_test.rb::test_user_creation
```

### コード品質チェック

```bash
# Rubocop による静的解析（フォーマッティング）
bundle exec rubocop

# Brakeman によるセキュリティ脆弱性チェック
bundle exec brakeman
```

### Git Hooks セットアップ

このプロジェクトでは Lefthook を使用してコミット前の自動チェックを行います。

```bash
# 初回セットアップ時のみ実行
bundle exec lefthook install

# フック動作確認
bundle exec lefthook run pre-commit
```

Lefthook により以下が自動実行されます：

- コミット前：RuboCop チェック、trailing whitespace 修正、final newline 追加
- プッシュ前：テスト実行

### データベース操作

```bash
# マイグレーション実行
rails db:migrate

# シード実行
rails db:seed

# データベースリセット
rails db:reset
```

## 開発環境

### VSCode Dev Container

このプロジェクトは VSCode の Dev Container での開発に最適化されています：

- Ruby LSP による言語サーバー機能
- rdbg デバッガーサポート
- RuboCop による自動フォーマット

### デバッグ

環境変数 `RUBY_DEBUG_OPEN: true` が設定されており、VSCode の rdbg デバッガーが利用可能です。

## 重要な設定ファイル

- `config/routes.rb` - ルーティング設定（現在は基本ヘルスチェックのみ）
- `config/database.yml` - データベース設定
- `docker-compose.yml` - 開発環境のコンテナ構成
- `Gemfile` - 依存関係の管理

## ドキュメント

- [要件定義](./docs/要件定義.md)
- [認証フロー](./docs/認証フロー.md)
- [Firebase Emulator を利用した開発](./firebase_emulator/README.md)
- [API の実行テスト](./api.http)
- [コードレビュー対応指針](./docs/コードレビュー対応指針.md)
- [テスト実装のベストプラクティス](./docs/テスト実装のベストプラクティス.md)
- [API 設計](./docs/API設計.md)
- [実装方針](./docs/実装方針.md)
- [データベース設計](./docs/データベース設計.md)
- [開発フロー](./docs/開発フロー.md)
- [エラーハンドリング規約](./docs/エラーハンドリング規約.md)
