-- インデックスのパフォーマンステストSQL

USE db_index;

-- ==========================================
-- 1. インデックスなしでのクエリパフォーマンス測定
-- ==========================================

-- 実行計画の確認
EXPLAIN SELECT * FROM users WHERE email = 'user500@example.com';
EXPLAIN SELECT * FROM users WHERE age > 30 AND city = 'Tokyo';
EXPLAIN SELECT * FROM orders WHERE user_id = 100;
EXPLAIN SELECT * FROM access_logs WHERE status_code = 404 AND accessed_at > '2025-01-01';

-- クエリ時間の測定例
SELECT SQL_NO_CACHE COUNT(*) FROM users WHERE age BETWEEN 25 AND 35;
SELECT SQL_NO_CACHE COUNT(*) FROM orders WHERE status = 'completed' AND order_date > '2025-01-01';
SELECT SQL_NO_CACHE COUNT(*) FROM access_logs WHERE status_code = 200;

-- ==========================================
-- 2. インデックスの追加
-- ==========================================

-- 単一カラムインデックス
ALTER TABLE users ADD INDEX idx_email (email);
ALTER TABLE users ADD INDEX idx_age (age);
ALTER TABLE users ADD INDEX idx_city (city);

-- 複合インデックス
ALTER TABLE users ADD INDEX idx_age_city (age, city);
ALTER TABLE orders ADD INDEX idx_user_id (user_id);
ALTER TABLE orders ADD INDEX idx_status_date (status, order_date);

-- アクセスログのインデックス
ALTER TABLE access_logs ADD INDEX idx_user_id (user_id);
ALTER TABLE access_logs ADD INDEX idx_status_code (status_code);
ALTER TABLE access_logs ADD INDEX idx_accessed_at (accessed_at);

-- 商品のインデックス
ALTER TABLE products ADD INDEX idx_category (category);
ALTER TABLE products ADD INDEX idx_price (price);

-- フルテキストインデックス（MySQL 8.0+）
ALTER TABLE products ADD FULLTEXT INDEX ft_name_desc (name, description);

-- ==========================================
-- 3. インデックスありでのクエリパフォーマンス測定
-- ==========================================

-- 同じクエリを再実行して比較
EXPLAIN SELECT * FROM users WHERE email = 'user500@example.com';
EXPLAIN SELECT * FROM users WHERE age > 30 AND city = 'Tokyo';
EXPLAIN SELECT * FROM orders WHERE user_id = 100;

SELECT SQL_NO_CACHE COUNT(*) FROM users WHERE age BETWEEN 25 AND 35;
SELECT SQL_NO_CACHE COUNT(*) FROM orders WHERE status = 'completed' AND order_date > '2025-01-01';
SELECT SQL_NO_CACHE COUNT(*) FROM access_logs WHERE status_code = 200;

-- ==========================================
-- 4. インデックスの確認
-- ==========================================

-- テーブルのインデックス一覧
SHOW INDEXES FROM users;
SHOW INDEXES FROM orders;
SHOW INDEXES FROM access_logs;

-- インデックスの統計情報
SELECT
    TABLE_NAME,
    INDEX_NAME,
    SEQ_IN_INDEX,
    COLUMN_NAME,
    CARDINALITY
FROM information_schema.STATISTICS
WHERE TABLE_SCHEMA = 'db_index'
ORDER BY TABLE_NAME, INDEX_NAME, SEQ_IN_INDEX;

-- ==========================================
-- 5. パフォーマンス比較クエリ例
-- ==========================================

-- カーディナリティが高いカラム（効果的）
SELECT COUNT(*) FROM users WHERE email = 'user1000@example.com';

-- カーディナリティが低いカラム（効果が限定的）
SELECT COUNT(*) FROM users WHERE city = 'Tokyo';

-- 複合インデックスの利用
SELECT * FROM users WHERE age = 30 AND city = 'Tokyo';

-- インデックスが使われない例（関数使用）
SELECT * FROM users WHERE YEAR(created_at) = 2025;

-- インデックスが使われる例
SELECT * FROM users WHERE created_at >= '2025-01-01' AND created_at < '2026-01-01';

-- JOIN のパフォーマンス
SELECT u.username, COUNT(o.id) as order_count
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
GROUP BY u.id, u.username;

-- フルテキスト検索
SELECT * FROM products
WHERE MATCH(name, description) AGAINST('product electronics' IN NATURAL LANGUAGE MODE);

-- ==========================================
-- 6. インデックスの削除（テスト用）
-- ==========================================

-- インデックスを削除して再度比較したい場合
-- ALTER TABLE users DROP INDEX idx_email;
-- ALTER TABLE users DROP INDEX idx_age;
-- ALTER TABLE users DROP INDEX idx_city;
-- ALTER TABLE users DROP INDEX idx_age_city;
