# Firebase Emulator

このディレクトリは Firebase Authentication Emulator の設定と起動を管理します。

## 概要

Rails API の開発環境で Firebase Authentication をローカルでエミュレートするための設定です。実際の Firebase プロジェクトに接続することなく、認証機能のテストが可能です。

## セットアップ

```bash
# 依存関係のインストール
npm install
```

## 使用方法

```bash
# エミュレーターを起動
npm run emulators:start

# エミュレーターのデータをエクスポート（テストデータの保存）
npm run emulators:export
```

## アクセス URL

- **Emulator UI**: http://127.0.0.1:4100/
- **Auth Emulator**: http://127.0.0.1:9199/

## テストユーザーの作成

1. Emulator UI (http://127.0.0.1:4100/) にアクセス
2. Authentication タブを選択
3. "Add user" ボタンからテストユーザーを作成
   - Email/Password 認証でユーザーを作成可能
   - 作成したユーザーの ID トークンを使用して API のテストを実行

## 開発用 ID トークンの取得方法

### Using HTTPie

```bash
http POST "127.0.0.1:9199/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=fake-api-key" \
  email="test@example.com" \
  password="password123" \
  returnSecureToken:=true
```

レスポンス例:

```json
{
  "email": "ougi@strobe-scope.net",
  "expiresIn": "3600",
  "idToken": "eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJuYW1lIjoiYW50b24wNzIiLCJwaWN0dXJlIjoiIiwiZW1haWwiOiJvdWdpQHN0cm9iZS1zY29wZS5uZXQiLCJlbWFpbF92ZXJpZmllZCI6ZmFsc2UsImF1dGhfdGltZSI6MTc1NzA1NjQ4NSwidXNlcl9pZCI6InpIUGFYd0RYVmFMOTljRjFaOWdETVdqT3J4NTUiLCJmaXJlYmFzZSI6eyJpZGVudGl0aWVzIjp7ImVtYWlsIjpbIm91Z2lAc3Ryb2JlLXNjb3BlLm5ldCJdfSwic2lnbl9pbl9wcm92aWRlciI6InBhc3N3b3JkIn0sImlhdCI6MTc1NzA1NjQ4NSwiZXhwIjoxNzU3MDYwMDg1LCJhdWQiOiJneW0tbm90ZS1hcHAiLCJpc3MiOiJodHRwczovL3NlY3VyZXRva2VuLmdvb2dsZS5jb20vZ3ltLW5vdGUtYXBwIiwic3ViIjoiekhQYVh3RFhWYUw5OWNGMVo5Z0RNV2pPcng1NSJ9.",
  "kind": "identitytoolkit#VerifyPasswordResponse",
  "localId": "zHPaXwDXVaL99cF1Z9gDMWjOrx55",
  "refreshToken": "eyJfQXV0aEVtdWxhdG9yUmVmcmVzaFRva2VuIjoiRE8gTk9UIE1PRElGWSIsImxvY2FsSWQiOiJ6SFBhWHdEWFZhTDk5Y0YxWjlnRE1Xak9yeDU1IiwicHJvdmlkZXIiOiJwYXNzd29yZCIsImV4dHJhQ2xhaW1zIjp7fSwicHJvamVjdElkIjoiZ3ltLW5vdGUtYXBwIn0=",
  "registered": true
}
```

この `idToken` を利用する。

### Rails API での使用例

```bash
# 取得した ID トークンを使って API をテスト
curl -H "Authorization: Bearer <ID_TOKEN>" \
  http://localhost:3000/api/v1/some-endpoint
```

## 注意事項

- 本番環境では Google ログインを使用しますが、エミュレーターでは Email/Password ユーザーでテスト可能です
- API 側では認証プロバイダーの種類に関係なく、Firebase ID トークンの検証のみ行うため問題ありません

## 設定ファイル

- `firebase.json`: エミュレーターの設定（ポート番号など）
- `package.json`: npm スクリプトの定義
