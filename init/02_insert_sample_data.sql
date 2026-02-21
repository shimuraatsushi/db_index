-- サンプルデータ生成用のストアドプロシージャ

USE db_index;

DELIMITER //

-- ユーザーデータ生成プロシージャ
CREATE PROCEDURE IF NOT EXISTS generate_users(IN num_rows INT)
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE random_email VARCHAR(255);
    DECLARE random_username VARCHAR(100);
    DECLARE random_age INT;
    DECLARE random_city VARCHAR(100);

    WHILE i <= num_rows DO
        SET random_email = CONCAT('user', i, '@example.com');
        SET random_username = CONCAT('user', i);
        SET random_age = FLOOR(18 + (RAND() * 62)); -- 18-80歳
        SET random_city = ELT(FLOOR(1 + (RAND() * 10)),
            'Tokyo', 'Osaka', 'Nagoya', 'Sapporo', 'Fukuoka',
            'Yokohama', 'Kobe', 'Kyoto', 'Sendai', 'Hiroshima');

        INSERT INTO users (email, username, age, city)
        VALUES (random_email, random_username, random_age, random_city);

        SET i = i + 1;
    END WHILE;
END //

-- 注文データ生成プロシージャ
CREATE PROCEDURE IF NOT EXISTS generate_orders(IN num_rows INT)
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE random_user_id INT;
    DECLARE random_product VARCHAR(255);
    DECLARE random_amount DECIMAL(10, 2);
    DECLARE random_status VARCHAR(20);
    DECLARE random_date DATE;
    DECLARE max_user_id INT;

    SELECT MAX(id) INTO max_user_id FROM users;

    WHILE i <= num_rows DO
        SET random_user_id = FLOOR(1 + (RAND() * max_user_id));
        SET random_product = ELT(FLOOR(1 + (RAND() * 5)),
            'Product A', 'Product B', 'Product C', 'Product D', 'Product E');
        SET random_amount = ROUND(100 + (RAND() * 9900), 2);
        SET random_status = ELT(FLOOR(1 + (RAND() * 4)),
            'pending', 'processing', 'completed', 'cancelled');
        SET random_date = DATE_SUB(CURDATE(), INTERVAL FLOOR(RAND() * 365) DAY);

        INSERT INTO orders (user_id, product_name, amount, status, order_date)
        VALUES (random_user_id, random_product, random_amount, random_status, random_date);

        SET i = i + 1;
    END WHILE;
END //

-- アクセスログデータ生成プロシージャ
CREATE PROCEDURE IF NOT EXISTS generate_access_logs(IN num_rows INT)
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE random_user_id INT;
    DECLARE random_ip VARCHAR(45);
    DECLARE random_status INT;
    DECLARE random_response_time INT;
    DECLARE max_user_id INT;

    SELECT MAX(id) INTO max_user_id FROM users;

    WHILE i <= num_rows DO
        SET random_user_id = FLOOR(1 + (RAND() * max_user_id));
        SET random_ip = CONCAT(
            FLOOR(1 + (RAND() * 255)), '.',
            FLOOR(RAND() * 256), '.',
            FLOOR(RAND() * 256), '.',
            FLOOR(RAND() * 256)
        );
        SET random_status = ELT(FLOOR(1 + (RAND() * 5)), 200, 301, 404, 500, 200);
        SET random_response_time = FLOOR(10 + (RAND() * 2000)); -- 10-2000ms

        INSERT INTO access_logs (user_id, ip_address, user_agent, url, response_time, status_code)
        VALUES (
            random_user_id,
            random_ip,
            'Mozilla/5.0',
            CONCAT('/page/', FLOOR(RAND() * 100)),
            random_response_time,
            random_status
        );

        SET i = i + 1;
    END WHILE;
END //

-- 商品データ生成プロシージャ
CREATE PROCEDURE IF NOT EXISTS generate_products(IN num_rows INT)
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE random_category VARCHAR(100);
    DECLARE random_price DECIMAL(10, 2);
    DECLARE random_stock INT;

    WHILE i <= num_rows DO
        SET random_category = ELT(FLOOR(1 + (RAND() * 5)),
            'Electronics', 'Books', 'Clothing', 'Food', 'Sports');
        SET random_price = ROUND(500 + (RAND() * 49500), 2);
        SET random_stock = FLOOR(RAND() * 1000);

        INSERT INTO products (name, description, category, price, stock)
        VALUES (
            CONCAT('Product ', i),
            CONCAT('Description for product ', i, '. This is a great product in the ', random_category, ' category.'),
            random_category,
            random_price,
            random_stock
        );

        SET i = i + 1;
    END WHILE;
END //

DELIMITER ;

-- 初期データ生成（少量）
-- より多くのデータが必要な場合は、MySQLクライアントから直接CALLしてください
CALL generate_users(1000);
CALL generate_orders(5000);
CALL generate_access_logs(10000);
CALL generate_products(500);
