#!/bin/bash
set -e

echo "=== HTTPS設定への切り替え開始 ==="

# 環境変数の確認
if [ -z "$DOMAIN_NAME" ]; then
  echo "エラー: DOMAIN_NAME環境変数が設定されていません"
  echo "使用方法: DOMAIN_NAME=example.com ./switch-to-https.sh"
  exit 1
fi

echo "ドメイン名: $DOMAIN_NAME"

# nginxコンテナ内で設定を切り替え
echo "HTTPS設定ファイルを生成中..."
docker compose -f docker-compose.prod.yml exec nginx sh -c "
  export DOMAIN_NAME=$DOMAIN_NAME
  envsubst '\$DOMAIN_NAME' < /tmp/nginx-templates/app-https.conf.template > /etc/nginx/conf.d/app.conf
  nginx -t
"

echo "Nginxを再読み込み中..."
docker compose -f docker-compose.prod.yml exec nginx nginx -s reload

echo "=== HTTPS設定への切り替え完了 ==="
echo "ブラウザで https://$DOMAIN_NAME にアクセスしてください"
