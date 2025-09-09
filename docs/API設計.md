# API 設計

認証フローは完了している(./認証フロー.md を参照する)。
画面の機能要件から必要な API を検討していく。

## 設計指針

- フロントエンド側で算出できることはなるべくフロントエンド側にやらせる
- API は軽量な状態を保つ
- 日時は UTC で DB に保存し、フロントエンドで JST に変換
- RESTful な設計を基本とする
- 総負荷量など、集計に使用する値は DB に保存してパフォーマンスを確保

## 画面の機能要件

### ログイン

- Google ログインが可能

### ホーム

- 今日のワークアウトを新規入力・編集・削除ができる。
- 前回のワークアウトが見られる。1 ページ 10 件。
- ページングがある（Next/Prev）。
- ワークアウトを検索ができる。
- 日付範囲で検索が可能。

### レコード

- 種目別の最大挙上重量を一覧できる。
- 種目別のトレーニング強度の推移を Chart で見られる。

### 設定

- レコードをすべて削除ができる。
- 退会ができる。

## ドメイン

### 種目

- 種目名
- ダンベル種目判定
- 片方ずつやる種目判定

### WorkoutExercise（ワークアウト内の種目記録）

- 種目名（種目名マスタから参照）
- セットが複数登録が可能

### セット

Rails の単一テーブル継承（STI）を使用：

- StrengthSet（筋トレ用）
  - 重量（ダンベル種目の場合は片方の重量）
  - レップ数（片方ずつやる種目の場合は左右別）
- CardioSet（有酸素運動用）
  - 実施時間
  - 消費カロリー

### ワークアウト（その日にやったトレーニング）

- WorkoutExercise が複数登録が可能
- WorkoutExercise ごとに「総負荷量」を DB に保存
  - 総負荷量 = Σ(各セットの重量 × レップ数)
  - ダンベル種目の場合: 総負荷量 = Σ(片方の重量 × 2 × レップ数)
  - 片方ずつやる種目の場合: 総負荷量 = Σ(重量 × (左レップ数 + 右レップ数))

## ドメインモデル詳細

### Exercise

| フィールド    | 型       | 説明                       |
| ------------- | -------- | -------------------------- |
| id            | integer  | 主キー                     |
| name          | string   | 種目名                     |
| is_dumbbell   | boolean  | ダンベル種目フラグ         |
| is_unilateral | boolean  | 片方ずつ実施する種目フラグ |
| is_bodyweight | boolean  | 自重種目フラグ             |
| is_cardio     | boolean  | 有酸素運動フラグ           |
| memo          | text     | メモ                       |
| created_at    | datetime | 作成日時（UTC）            |
| updated_at    | datetime | 更新日時（UTC）            |

### Workout

| フィールド         | 型       | 説明                        |
| ------------------ | -------- | --------------------------- |
| id                 | integer  | 主キー                      |
| user_id            | integer  | ユーザー ID                 |
| performed_start_at | datetime | ワークアウト開始日時（UTC） |
| performed_end_at   | datetime | ワークアウト終了日時（UTC） |
| total_volume       | integer  | 総負荷量（グラム）          |
| memo               | text     | メモ                        |
| created_at         | datetime | 作成日時（UTC）             |
| updated_at         | datetime | 更新日時（UTC）             |

### WorkoutExercise

| フィールド   | 型       | 説明                                          |
| ------------ | -------- | --------------------------------------------- |
| id           | integer  | 主キー                                        |
| workout_id   | integer  | ワークアウト ID                               |
| exercise_id  | integer  | 種目 ID                                       |
| order        | integer  | 表示順（exercises 配列の index から自動設定） |
| total_volume | integer  | この種目の総負荷量（グラム）                  |
| created_at   | datetime | 作成日時（UTC）                               |
| updated_at   | datetime | 更新日時（UTC）                               |

### Set（単一テーブル継承）

| フィールド          | 型       | 説明                                          |
| ------------------- | -------- | --------------------------------------------- |
| id                  | integer  | 主キー                                        |
| workout_exercise_id | integer  | WorkoutExerciseID                             |
| type                | string   | STI 識別子（StrengthSet/CardioSet）           |
| weight              | integer  | 重量（グラム）※StrengthSet 用                 |
| reps                | integer  | レップ数（通常種目）※StrengthSet 用           |
| left_reps           | integer  | 左側レップ数（片方ずつの種目）※StrengthSet 用 |
| right_reps          | integer  | 右側レップ数（片方ずつの種目）※StrengthSet 用 |
| duration_seconds    | integer  | 実施時間（秒）※CardioSet 用                   |
| calories            | integer  | 消費カロリー（kcal）※CardioSet 用             |
| order               | integer  | セット順                                      |
| created_at          | datetime | 作成日時（UTC）                               |
| updated_at          | datetime | 更新日時（UTC）                               |

## API エンドポイント詳細

### 認証

#### Google ログイン

```
POST /auth/google
```

**リクエスト**

```json
{
  "id_token": "Google OAuth2 ID Token"
}
```

**レスポンス**

```json
{
  "access_token": "JWT access token",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "name": "User Name"
  }
}
```

### ワークアウト

#### ワークアウト一覧取得

```
GET /workouts?start_date=2024-01-01&end_date=2024-01-31&page=1&per_page=10
```

**レスポンス**

```json
{
  "workouts": [
    {
      "id": 1,
      "performed_start_at": "2024-01-15T10:00:00Z",
      "performed_end_at": "2024-01-15T11:30:00Z",
      "total_volume": 1500000,
      "memo": "今日は調子が良かった",
      "exercises": [
        {
          "id": 1,
          "exercise": {
            "id": 1,
            "name": "ベンチプレス",
            "is_dumbbell": false,
            "is_unilateral": false,
            "is_bodyweight": false,
            "is_cardio": false,
            "memo": null
          },
          "total_volume": 1000000,
          "sets": [
            {
              "id": 1,
              "weight": 60000,
              "reps": 10,
              "order": 1,
              "type": "StrengthSet"
            }
          ]
        }
      ]
    }
  ],
  "meta": {
    "current_page": 1,
    "total_pages": 5,
    "total_count": 50
  }
}
```

#### 特定日のワークアウト取得

```
GET /workouts?date=2024-01-15
```

#### ワークアウト作成

```
POST /workouts
```

**リクエスト**

```json
{
  "performed_start_at": "2024-01-15T10:00:00Z",
  "performed_end_at": "2024-01-15T11:30:00Z",
  "memo": "今日は調子が良かった",
  "exercises": [
    {
      "exercise_id": 1,
      "sets": [
        {
          "type": "StrengthSet",
          "weight": 60000,
          "reps": 10
        }
      ]
    },
    {
      "exercise_id": 2,
      "sets": [
        {
          "type": "StrengthSet",
          "weight": 30000,
          "reps": 12
        }
      ]
    }
  ]
}
```

※ 配列の順序がそのまま WorkoutExercise.order として保存されます（0 番目 →order: 1, 1 番目 →order: 2）

```

#### ワークアウト更新

```

PUT /workouts/:id

```

#### ワークアウト削除

```

DELETE /workouts/:id

```

### レコード

#### 種目別最大挙上重量

```
GET /records/max-weights
```

**レスポンス**

```json
{
  "records": [
    {
      "exercise": {
        "id": 1,
        "name": "ベンチプレス"
      },
      "max_weight": 80000,
      "achieved_date": "2024-01-10"
    }
  ]
}
```

#### 種目別トレーニング推移

```
GET /records/exercise-trends/:exercise_id?start_date=2024-01-01&end_date=2024-01-31
```

**レスポンス**

```json
{
  "exercise": {
    "id": 1,
    "name": "ベンチプレス"
  },
  "trends": [
    {
      "performed_at": "2024-01-01T09:00:00Z",
      "total_volume": 1200000,
      "max_weight": 70000
    }
  ]
}
```

### 種目マスタ

#### 種目一覧取得

```
GET /exercises
```

### 設定

#### 全データ削除

```
DELETE /users/me/data
```

#### 退会

```
DELETE /users/me
```

## エラーレスポンス

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "入力値が不正です",
    "details": [
      {
        "field": "weight",
        "message": "重量は正の整数である必要があります"
      }
    ]
  }
}
```

## 共通仕様

- 認証が必要なエンドポイントは Authorization ヘッダーに Bearer トークンを付与
- 日付形式は ISO 8601 形式（日付：YYYY-MM-DD、日時：YYYY-MM-DDTHH:MM:SSZ）
- 日時は UTC で保存、レスポンスも UTC
- 重量はグラム単位の整数
- ページネーションは page/per_page パラメータで制御
