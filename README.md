# DB Index

MySQLのインデックス効果を検証するプロジェクト

## セットアップ

1. 環境変数ファイルをコピー
```bash
cp .env.example .env
```

2. MySQLコンテナを起動
```bash
docker-compose up -d
```

3. MySQLに接続
```bash
docker-compose exec mysql mysql -u dbuser -p
# パスワード: dbpassword
```

## コマンド

- コンテナ起動: `docker-compose up -d`
- コンテナ停止: `docker-compose down`
- ログ確認: `docker-compose logs -f mysql`
- MySQL接続: `docker-compose exec mysql mysql -u dbuser -p`

## テーブル構造

インデックスのパフォーマンステスト用に以下のテーブルを用意：

1. **users** - ユーザー情報（1,000件）
   - email, username, age, city など

2. **orders** - 注文情報（5,000件）
   - user_id, product_name, amount, status, order_date など

3. **access_logs** - アクセスログ（10,000件）
   - user_id, ip_address, status_code, response_time など

4. **products** - 商品情報（500件）
   - name, description, category, price など

## データ生成

より多くのデータを生成したい場合：

```sql
-- MySQLに接続後、以下を実行
USE db_index;

-- 10万件のユーザーを生成
CALL generate_users(100000);

-- 50万件の注文を生成
CALL generate_orders(500000);

-- 100万件のアクセスログを生成
CALL generate_access_logs(1000000);

-- 1万件の商品を生成
CALL generate_products(10000);
```

## インデックステスト

`sql/index_testing.sql` に以下のテストクエリを用意：

### 1. インデックスなしでの測定
```sql
-- 実行計画の確認
EXPLAIN SELECT * FROM users WHERE email = 'user500@example.com';

-- クエリ時間の測定
SELECT COUNT(*) FROM users WHERE age BETWEEN 25 AND 35;
```

### 2. インデックスの追加
```sql
-- 単一カラムインデックス
ALTER TABLE users ADD INDEX idx_email (email);
ALTER TABLE users ADD INDEX idx_age (age);

-- 複合インデックス
ALTER TABLE users ADD INDEX idx_age_city (age, city);
```

### 3. インデックスありでの測定
```sql
-- 同じクエリを再実行して比較
EXPLAIN SELECT * FROM users WHERE email = 'user500@example.com';
SELECT COUNT(*) FROM users WHERE age BETWEEN 25 AND 35;
```

### 4. インデックスの確認
```sql
-- インデックス一覧
SHOW INDEXES FROM users;

-- 統計情報
SELECT TABLE_NAME, INDEX_NAME, COLUMN_NAME, CARDINALITY
FROM information_schema.STATISTICS
WHERE TABLE_SCHEMA = 'db_index';
```

## テストファイルの実行

```bash
# index_testing.sqlを実行
docker-compose exec -T mysql mysql -u dbuser -pdbpassword db_index < sql/index_testing.sql
```

## 初期化スクリプト

`init/` ディレクトリに `.sql` ファイルを配置すると、初回起動時に自動的に実行されます。

## パフォーマンス比較のポイント

1. **EXPLAIN** で実行計画を確認
   - type: ALL（フルスキャン）→ ref/range（インデックス使用）
   - rows: スキャン行数が減少
   - key: 使用されたインデックス名

2. **カーディナリティ**（一意性）の影響
   - 高い：email（効果大）
   - 低い：city（効果限定的）

3. **複合インデックス**の順序
   - WHERE age = 30 AND city = 'Tokyo' → (age, city) が効果的

4. **インデックスが使われないケース**
   - 関数使用: `WHERE YEAR(created_at) = 2025`
   - LIKE前方一致以外: `WHERE name LIKE '%test%'`
