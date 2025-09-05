# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

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
