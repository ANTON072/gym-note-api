# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## コーディング規約

### テストの記述
- テストの記述（test名、アサーションメッセージなど）は日本語で書く
- 変数名やメソッド名は英語のまま

### エラーメッセージとI18n
- **エラーメッセージはハードコードしない**: カスタムバリデーションのエラーメッセージは直接文字列で指定せず、シンボルを使用してI18nで管理する
- **I18nファイルの活用**: `config/locales/ja.yml`にエラーメッセージを定義し、`errors.add(:field, :error_key)`の形式で使用する
- **テストの堅牢性**: テストではエラーメッセージの文字列ではなく、`errors.details`を使用してエラーの種類（シンボル）を検証する

### バリデーションエラーのテスト記法
- **assert_includes を使用**: バリデーションエラーの検証には必ず `assert_includes` と `errors.details` を組み合わせて使用する
  ```ruby
  # 基本的な記法
  assert_includes workout_exercise.errors.details[:workout], { error: :blank }
  
  # 値を含む場合
  assert_includes workout_exercise.errors.details[:order_index], { error: :greater_than_or_equal_to, value: 0, count: 1 }
  
  # ユニーク制約違反の場合
  assert_includes workout_exercise.errors.details[:exercise_id], { error: :taken, value: @exercise.id }
  ```
- **文字列での検証は避ける**: `assert_includes workout.errors[:field], "エラーメッセージ"` の形式は使用しない

### enumの定義とマジックナンバー回避
- **Rails 7以降のenum定義**: `enum :name, { key: value }` の形式を使用する（第一引数にシンボルを渡す）
  ```ruby
  # Rails 7以降の正しい記法
  enum :exercise_type, { strength: 0, cardio: 1 }
  
  # 古い記法（Rails 6以前）- 使用しない
  enum exercise_type: { strength: 0, cardio: 1 }
  ```
- **マジックナンバーの回避**: 数値を直接使用せず、enumのシンボルや定数を使用する
  ```ruby
  # 悪い例
  Exercise.where(exercise_type: 0)
  
  # 良い例
  Exercise.where(exercise_type: :strength)
  ```
- **マイグレーション内でのenum使用**: 一時モデルでenumを定義して可読性を向上
  ```ruby
  class TmpExercise < ApplicationRecord
    self.table_name = 'exercises'
    enum :exercise_type, { strength: 0, cardio: 1 }
  end
  
  TmpExercise.where(exercise_type: :strength).update_all(body_part: TmpExercise.body_parts[:chest])
  ```
- **テストでの動的enum参照**: ハードコードせずに`Model.enum_name.keys`を使用
  ```ruby
  Exercise.body_parts.keys.each do |body_part|
    # テスト実行
  end
  ```

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
- **実装は段階的に進める**: テストが失敗した場合は、必ずテストが通ることを確認してから次のモデルの実装に進む。勝手に次の実装を進めない

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
- [コードレビュー対応指針](./docs/コードレビュー対応指針.md)
- [テスト実装のベストプラクティス](./docs/テスト実装のベストプラクティス.md)
- [API 設計](./docs/API設計.md)
- [実装方針](./docs/実装方針.md)
- [データベース設計](./docs/データベース設計.md)
- [開発フロー](./docs/開発フロー.md)
- [エラーハンドリング規約](./docs/エラーハンドリング規約.md)
