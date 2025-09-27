# DB設計メモ

## 基本の流れ
User → Workout（トレーニング日） → WorkoutExercise（その日やった種目） → WorkoutSet（各セット記録）

## 重要な設計判断
- 重量はグラム単位（小数点回避のため）
- STIでStrength/Cardioを分離
- order_indexで順序管理

## よく使うクエリパターン
- 特定日のワークアウト全体取得
- ユーザーの直近N回の記録

```marmaid
graph TD
    A[workouts] --> B[workout_exercises]
    B --> C[exercises]
    B --> D[workout_sets]
    D --> E[StrengthSet]
    D --> F[CardioSet]
    
    A2[具体例: 今日の胸トレ] --> B2[1. ベンチプレス<br/>2. ダンベルフライ]
    B2 --> C2[種目マスター情報]
    B2 --> D2[各種目のセット記録]
```

## 1. ワークアウト（今日の胸トレ）

```sql
workouts
id: 1, user_id: 100, performed_start_at: '2025-09-27 10:00'
```

## 2. このワークアウトで行った種目

```sql
workout_exercises
id: 1, workout_id: 1, exercise_id: 10, order_index: 1  -- ベンチプレス
id: 2, workout_id: 1, exercise_id: 20, order_index: 2  -- ダンベルフライ
```

## 3. 各種目のセット記録

```sql
-- ベンチプレスのセット
workout_sets
id: 1, workout_exercise_id: 1, type: 'StrengthSet', order_index: 1
id: 2, workout_exercise_id: 1, type: 'StrengthSet', order_index: 2

-- ダンベルフライのセット  
workout_sets
id: 3, workout_exercise_id: 2, type: 'StrengthSet', order_index: 1
```

## なぜこの構造が複雑なのか

中間テーブルが2つある

1. `workout_exercises` ワークアウトと種目を繋ぐ
2. `workout_sets` 種目の実施とセット記録を繋ぐ


```sql
-- 特定のワークアウトの全記録を取得
SELECT w.*, we.order_index, e.name, ws.*, ss.weight, ss.reps
FROM workouts w
JOIN workout_exercises we ON w.id = we.workout_id
JOIN exercises e ON we.exercise_id = e.id  
JOIN workout_sets ws ON we.id = ws.workout_exercise_id
LEFT JOIN StrengthSet ss ON ws.id = ss.id AND ws.type = 'StrengthSet'
ORDER BY we.order_index, ws.order_index
```

## この構造のメリット

- 柔軟性: 同じ種目を1回のワークアウトで複数回実施可能
- 拡張性: 新しいセットタイプ（時間制、ドロップセットなど）を追加しやすい
- 正規化: データの重複がない

