# Gym Note API

ジム・筋トレ記録管理システムのバックエンド API

## 概要

Gym Note API は、筋力トレーニングの記録と管理を目的とした Rails API アプリケーションです。ワークアウトセッション、エクササイズ、セット数、重量などの詳細な記録を管理できます。

## 技術スタック

- **フレームワーク**: Ruby on Rails 8.0.2+
- **言語**: Ruby 3.4.5
- **データベース**: MariaDB 11.2

## 必要な環境

- Docker
- Docker Compose

## API開発ツール

- **Postmanワークスペース**: https://web.postman.co/workspace/gym-note-api~ade0227e-3921-4634-b24a-e04fdf90b54c/overview

## VSCode での開発

このプロジェクトは VSCode での開発に最適化されており、Dev Container と Ruby デバッグ環境が設定されています。

### Dev Container での開発

VSCode の Dev Container 機能を使用して、コンテナ内で直接開発できます。

#### 必要な拡張機能

- [Remote - Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

#### セットアップ手順

1. VSCode でプロジェクトフォルダを開く
2. コマンドパレット（`Cmd+Shift+P`）を開く
3. `Dev Containers: Reopen in Container` を選択
4. コンテナのビルドが完了するまで待機

#### インストールされる拡張機能

Dev Container 内で以下の拡張機能が自動的にインストールされます：

- **Ruby LSP** (`Shopify.ruby-lsp`): Ruby の言語サーバー
  - コード補完
  - シンタックスハイライト
  - エラー検出
  - フォーマッティング（RuboCop 使用）
- **VSCode rdbg** (`KoichiSasada.vscode-rdbg`): Ruby デバッガー

### Ruby デバッグ

#### デバッガーの使用方法

1. コード内にブレークポイントを設定
2. VSCode のデバッグパネルを開く（`Cmd+Shift+D`）
3. `Attach with rdbg` 設定を選択
4. デバッグセッションを開始

#### デバッグ用環境変数

`docker-compose.yml` で `RUBY_DEBUG_OPEN: true` が設定されているため、rdbg デバッガーが利用可能です。

### 推奨設定

#### Ruby コード設定

VSCode では以下の Ruby 固有の設定が適用されます：

- **フォーマッター**: RuboCop を使用
- **保存時フォーマット**: 有効
- **セマンティックハイライト**: 有効
- **入力時フォーマット**: 有効

#### テスト実行

VSCode のターミナルでテストを実行できます：

```bash
# 全テスト実行
rails test

# 特定のテストファイル実行
rails test test/models/user_test.rb

# 特定のテストメソッド実行
rails test test/models/user_test.rb::test_user_creation
```
