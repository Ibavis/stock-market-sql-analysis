CREATE DATABASE IF NOT EXISTS stocks_db
CHARACTER SET utf8mb4
COLLATE utf8mb4_polish_ci;
DROP TABLE IF EXISTS stock_prices;
DROP TABLE IF EXISTS companies;
#Tworzymy tabele z nazwami
CREATE TABLE companies (
    company_id INT AUTO_INCREMENT PRIMARY KEY,
    ticker VARCHAR(20) NOT NULL UNIQUE,
    company_name VARCHAR(100) NOT NULL,
    sector VARCHAR(100),
    exchange_name VARCHAR(50)
) ENGINE = InnoDB;

#Importujemy potrzebne dane
CREATE TABLE stock_prices (
    price_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    company_id INT NOT NULL,
    price_date DATE NOT NULL,

    open_price DECIMAL(18, 8),
    high_price DECIMAL(18, 8),
    low_price DECIMAL(18, 8),
    close_price DECIMAL(18, 8),
    volume DECIMAL(24, 8),

    CONSTRAINT fk_stock_prices_company
        FOREIGN KEY (company_id)
        REFERENCES companies(company_id)
        ON DELETE CASCADE,

    CONSTRAINT uq_stock_prices_company_date
        UNIQUE (company_id, price_date)
) ENGINE = InnoDB;

INSERT INTO companies (
    ticker,
    company_name,
    sector,
    exchange_name
)
VALUES (
    'KTY',
    'Grupa Kęty S.A.',
    'Przemysł metalowy',
    'GPW'
)
ON DUPLICATE KEY UPDATE
    company_name = 'Grupa Kęty S.A.',
    sector = 'Przemysł metalowy',
    exchange_name = 'GPW';
    
USE stocks_db;

DROP TABLE IF EXISTS stooq_import;

CREATE TABLE stooq_import (
    price_date DATE,
    open_price DECIMAL(18, 8),
    high_price DECIMAL(18, 8),
    low_price DECIMAL(18, 8),
    close_price DECIMAL(18, 8),
    volume DECIMAL(24, 8)
) ENGINE = InnoDB;

#import danych
LOAD DATA LOCAL INFILE 'C:/Users/Grzegorz/Desktop/kty_d (1).csv'
INTO TABLE stooq_import
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
    @data,
    @otwarcie,
    @najwyzszy,
    @najnizszy,
    @zamkniecie,
    @wolumen
)
SET
    price_date = STR_TO_DATE(TRIM(@data), '%Y-%m-%d'),

    open_price = NULLIF(
        REPLACE(TRIM(@otwarcie), ',', '.'),
        ''
    ),

    high_price = NULLIF(
        REPLACE(TRIM(@najwyzszy), ',', '.'),
        ''
    ),

    low_price = NULLIF(
        REPLACE(TRIM(@najnizszy), ',', '.'),
        ''
    ),

    close_price = NULLIF(
        REPLACE(TRIM(@zamkniecie), ',', '.'),
        ''
    ),

    volume = NULLIF(
        REPLACE(
            TRIM(TRAILING '\r' FROM @wolumen),
            ',',
            '.'
        ),
        ''
    );
    
INSERT INTO stock_prices (
    company_id,
    price_date,
    open_price,
    high_price,
    low_price,
    close_price,
    volume
)
SELECT
    c.company_id,
    s.price_date,
    s.open_price,
    s.high_price,
    s.low_price,
    s.close_price,
    s.volume
FROM stooq_import AS s
JOIN companies AS c
    ON c.ticker = 'KTY'
WHERE s.price_date IS NOT NULL
ON DUPLICATE KEY UPDATE
    open_price = VALUES(open_price),
    high_price = VALUES(high_price),
    low_price = VALUES(low_price),
    close_price = VALUES(close_price),
    volume = VALUES(volume);
