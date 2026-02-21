# データベーステーブル概要

## データベース名
`db_index` - MySQLインデックス効果検証用データベース

---

## テーブル一覧

### 1. users（ユーザーテーブル）

**目的**: 基本的なインデックス効果の検証

**カラム構成**:
| カラム名 | 型 | 制約 | 説明 |
|---------|-----|------|------|
| id | INT | PRIMARY KEY, AUTO_INCREMENT | ユーザーID |
| email | VARCHAR(255) | NOT NULL | メールアドレス（カーディナリティ高） |
| username | VARCHAR(100) | NOT NULL | ユーザー名 |
| age | INT | | 年齢（18-80、カーディナリティ中） |
| city | VARCHAR(100) | | 都市名（10種類、カーディナリティ低） |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | 作成日時 |
| updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE | 更新日時 |

**初期データ件数**: 1,000件

**インデックス検証ポイント**:
- `email`: 一意性が高く、インデックス効果が顕著
- `age`: 範囲検索（BETWEEN）でのインデックス効果
- `city`: カーディナリティが低い場合のインデックス効果
- `(age, city)`: 複合インデックスの効果

**テスト用クエリ例**:
```sql
-- カーディナリティ高（効果大）
SELECT * FROM users WHERE email = 'user500@example.com';

-- 範囲検索
SELECT * FROM users WHERE age BETWEEN 25 AND 35;

-- カーディナリティ低（効果限定的）
SELECT * FROM users WHERE city = 'Tokyo';

-- 複合条件
SELECT * FROM users WHERE age = 30 AND city = 'Tokyo';
```

---

### 2. orders（注文テーブル）

**目的**: JOIN とインデックスの関係、複合インデックスの検証

**カラム構成**:
| カラム名 | 型 | 制約 | 説明 |
|---------|-----|------|------|
| id | INT | PRIMARY KEY, AUTO_INCREMENT | 注文ID |
| user_id | INT | NOT NULL | ユーザーID（外部キー想定） |
| product_name | VARCHAR(255) | NOT NULL | 商品名 |
| amount | DECIMAL(10, 2) | NOT NULL | 金額（100-10000円） |
| status | ENUM | DEFAULT 'pending' | ステータス（4種類） |
| order_date | DATE | NOT NULL | 注文日（過去1年間） |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | 作成日時 |

**status の値**: 'pending', 'processing', 'completed', 'cancelled'

**初期データ件数**: 5,000件

**インデックス検証ポイント**:
- `user_id`: JOIN 時のインデックス効果
- `(status, order_date)`: 複合インデックスでの絞り込み効果
- 複数テーブルの JOIN 時のパフォーマンス

**テスト用クエリ例**:
```sql
-- 特定ユーザーの注文
SELECT * FROM orders WHERE user_id = 100;

-- ステータスと日付での絞り込み
SELECT * FROM orders
WHERE status = 'completed' AND order_date > '2025-01-01';

-- JOIN でのパフォーマンス
SELECT u.username, COUNT(o.id) as order_count
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
GROUP BY u.id, u.username;
```

---

### 3. access_logs（アクセスログテーブル）

**目的**: 大量データでのインデックス効果の検証

**カラム構成**:
| カラム名 | 型 | 制約 | 説明 |
|---------|-----|------|------|
| id | BIGINT | PRIMARY KEY, AUTO_INCREMENT | ログID |
| user_id | INT | | ユーザーID |
| ip_address | VARCHAR(45) | | IPアドレス（IPv4/IPv6対応） |
| user_agent | VARCHAR(255) | | ユーザーエージェント |
| url | VARCHAR(500) | | アクセスURL |
| response_time | INT | | レスポンスタイム（10-2000ms） |
| status_code | INT | | HTTPステータスコード |
| accessed_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | アクセス日時 |

**status_code の値**: 200, 301, 404, 500（ランダム）

**初期データ件数**: 10,000件（最大100万件以上推奨）

**インデックス検証ポイント**:
- 大量データでのフルスキャンとインデックススキャンの速度差
- `status_code`: WHERE条件でのインデックス効果
- `accessed_at`: 日時範囲検索でのインデックス効果
- データ量が増えるほどインデックスの効果が顕著

**テスト用クエリ例**:
```sql
-- ステータスコードでの絞り込み
SELECT COUNT(*) FROM access_logs WHERE status_code = 404;

-- 日時範囲での絞り込み
SELECT COUNT(*) FROM access_logs
WHERE accessed_at > '2025-01-01';

-- 複合条件
SELECT * FROM access_logs
WHERE status_code = 200 AND response_time > 1000;

-- 集計クエリ
SELECT status_code, COUNT(*) as count, AVG(response_time) as avg_time
FROM access_logs
GROUP BY status_code;
```

---

### 4. products（商品テーブル）

**目的**: フルテキストインデックスの検証

**カラム構成**:
| カラム名 | 型 | 制約 | 説明 |
|---------|-----|------|------|
| id | INT | PRIMARY KEY, AUTO_INCREMENT | 商品ID |
| name | VARCHAR(255) | NOT NULL | 商品名 |
| description | TEXT | | 商品説明 |
| category | VARCHAR(100) | | カテゴリ（5種類） |
| price | DECIMAL(10, 2) | | 価格（500-50000円） |
| stock | INT | DEFAULT 0 | 在庫数（0-1000） |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | 作成日時 |

**category の値**: 'Electronics', 'Books', 'Clothing', 'Food', 'Sports'

**初期データ件数**: 500件

**インデックス検証ポイント**:
- `category`: カテゴリでの絞り込み
- `price`: 範囲検索でのインデックス効果
- `(name, description)`: フルテキストインデックスの効果

**テスト用クエリ例**:
```sql
-- カテゴリでの絞り込み
SELECT * FROM products WHERE category = 'Electronics';

-- 価格範囲での絞り込み
SELECT * FROM products WHERE price BETWEEN 1000 AND 5000;

-- フルテキスト検索（インデックス追加後）
SELECT * FROM products
WHERE MATCH(name, description) AGAINST('product electronics' IN NATURAL LANGUAGE MODE);
```

---

## ストアドプロシージャ

### 1. generate_users(num_rows INT)
**機能**: 指定件数のユーザーデータを生成
**パラメータ**:
- `num_rows`: 生成する件数

**使用例**:
```sql
CALL generate_users(100000);  -- 10万件生成
```

---

### 2. generate_orders(num_rows INT)
**機能**: 指定件数の注文データを生成（既存ユーザーに紐付け）
**パラメータ**:
- `num_rows`: 生成する件数

**注意**: users テーブルにデータが存在している必要があります

**使用例**:
```sql
CALL generate_orders(500000);  -- 50万件生成
```

---

### 3. generate_access_logs(num_rows INT)
**機能**: 指定件数のアクセスログデータを生成
**パラメータ**:
- `num_rows`: 生成する件数

**注意**:
- users テーブルにデータが存在している必要があります
- 大量データ（100万件以上）生成時は時間がかかります（5-10分程度）

**使用例**:
```sql
CALL generate_access_logs(1000000);  -- 100万件生成
```

---

### 4. generate_products(num_rows INT)
**機能**: 指定件数の商品データを生成
**パラメータ**:
- `num_rows`: 生成する件数

**使用例**:
```sql
CALL generate_products(10000);  -- 1万件生成
```

---

## インデックス戦略

### 推奨インデックス

#### users テーブル
```sql
ALTER TABLE users ADD INDEX idx_email (email);
ALTER TABLE users ADD INDEX idx_age (age);
ALTER TABLE users ADD INDEX idx_city (city);
ALTER TABLE users ADD INDEX idx_age_city (age, city);  -- 複合
```

#### orders テーブル
```sql
ALTER TABLE orders ADD INDEX idx_user_id (user_id);
ALTER TABLE orders ADD INDEX idx_status_date (status, order_date);  -- 複合
```

#### access_logs テーブル
```sql
ALTER TABLE access_logs ADD INDEX idx_user_id (user_id);
ALTER TABLE access_logs ADD INDEX idx_status_code (status_code);
ALTER TABLE access_logs ADD INDEX idx_accessed_at (accessed_at);
```

#### products テーブル
```sql
ALTER TABLE products ADD INDEX idx_category (category);
ALTER TABLE products ADD INDEX idx_price (price);
ALTER TABLE products ADD FULLTEXT INDEX ft_name_desc (name, description);
```

---

## パフォーマンステストの手順

### 1. インデックスなしで測定
```sql
EXPLAIN SELECT * FROM access_logs WHERE status_code = 404;
-- type: ALL（フルスキャン）を確認
```

### 2. インデックスを追加
```sql
ALTER TABLE access_logs ADD INDEX idx_status_code (status_code);
```

### 3. インデックスありで測定
```sql
EXPLAIN SELECT * FROM access_logs WHERE status_code = 404;
-- type: ref（インデックス使用）を確認
-- rows: スキャン行数の減少を確認
```

### 4. パフォーマンス比較
- EXPLAINの `type` が `ALL` から `ref`/`range` に変化
- `rows` の値が大幅に減少
- `key` に使用されたインデックス名が表示される

---

## カーディナリティとインデックス効果

| カーディナリティ | 例 | インデックス効果 |
|----------------|-----|-----------------|
| 高 | email（ほぼ一意） | 非常に効果的 |
| 中 | age（60種類程度） | 効果的 |
| 低 | city（10種類）、status（4種類） | 効果は限定的 |

---

## 注意事項

1. **データ量**: インデックスの効果は大量データで顕著になります（10万件以上推奨）
2. **関数使用**: WHERE句で関数を使用するとインデックスが使われません
   - NG: `WHERE YEAR(created_at) = 2025`
   - OK: `WHERE created_at >= '2025-01-01' AND created_at < '2026-01-01'`
3. **LIKE検索**: 前方一致以外はインデックスが使われません
   - OK: `WHERE name LIKE 'product%'`
   - NG: `WHERE name LIKE '%product%'`
4. **複合インデックス**: カラムの順序が重要（選択性の高い順）
