# Kamal を使ったデプロイ手順

## 1. 事前準備

### 環境変数ファイル（.env）の作成

```bash
# .env
DOCKER_HUB_USERNAME=your_username
KAMAL_REGISTRY_PASSWORD=your_docker_hub_token
RAILS_MASTER_KEY=your_rails_master_key
```

**重要**: `.env`ファイルは`.gitignore`に追加して git 管理から除外する

## 2. Kamal 設定ファイル

### config/deploy.yml

```yaml
<% require "dotenv"; Dotenv.load(".env") %>

service: your-app-name
image: <%= ENV["DOCKER_HUB_USERNAME"] %>/your-app-name

servers:
  web:
    - your-server-hostname

registry:
  username: <%= ENV["DOCKER_HUB_USERNAME"] %>
  password: <%= ENV["KAMAL_REGISTRY_PASSWORD"] %>

env:
  secret:
    - RAILS_MASTER_KEY
```

### .kamal/secrets

```bash
# .kamal/secrets
DOCKER_HUB_USERNAME=$DOCKER_HUB_USERNAME
KAMAL_REGISTRY_PASSWORD=$KAMAL_REGISTRY_PASSWORD
RAILS_MASTER_KEY=$(cat config/master.key)
```

## 3. デプロイ実行

```bash
# 依存関係をインストール
bundle install

# 設定確認
kamal secrets print

# デプロイ実行
kamal deploy
```

## 4. デプロイ後の運用

### ログの確認

```bash
# アプリケーションのログを確認
kamal app logs

# リアルタイムでログを監視
kamal app logs -f

# 特定のサーバーのログを確認
kamal app logs --hosts your-server-hostname

# エラーログのみ確認
kamal app logs --grep ERROR
```

### マイグレーションの実行

```bash
# データベースマイグレーション実行
kamal app exec "bin/rails db:migrate"

# 特定のサーバーでマイグレーション実行
kamal app exec --hosts your-server-hostname "bin/rails db:migrate"

# シードデータの投入
kamal app exec "bin/rails db:seed"
```

### その他の運用コマンド

```bash
# アプリケーションコンテナの状態確認
kamal app details

# Railsコンソールにアクセス
kamal app exec --interactive "bin/rails console"

# データベースコンソールにアクセス
kamal app exec --interactive "bin/rails dbconsole"

# アプリケーションの再起動
kamal app restart

# アプリケーションの停止
kamal app stop

# アプリケーションの開始
kamal app start
```

## 5. セキュリティのポイント

- `.env`ファイルは**絶対に git 管理しない**
- `KAMAL_REGISTRY_PASSWORD`は Docker Hub のアクセストークンを使用
- `.kamal/secrets`は git で管理（実際の値ではなく参照のみ記述）
- 環境変数は`<%= ENV["変数名"] %>`で ERB 形式で参照

## 6. トラブルシューティング

### 認証エラー

- Docker Hub のトークンとユーザー名を確認
- `.env`ファイルの環境変数名が正しいか確認

### 構文エラー

- ERB の記述方法を確認（`<%= %>`形式）
- YAML の構文が正しいか確認

### Secret not found エラー

- `.kamal/secrets`の変数名と deploy.yml の参照が一致しているか確認
- `kamal secrets print`で値が正しく読み込まれているか確認

## 7. 参考リンク

- [Kamal 公式ドキュメント](https://kamal-deploy.org/)
- [Secrets 設定](https://kamal-deploy.org/docs/commands/secrets/)
- [アップグレードガイド](https://kamal-deploy.org/docs/upgrading/secrets-changes/)
