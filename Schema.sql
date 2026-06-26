
CREATE TABLE companies (
company_id SERIAL PRIMARY KEY,
ticker VARCHAR(10) UNIQUE NOT NULL,
company_name VARCHAR(100) NOT NULL,
sector VARCHAR(100),
exchange VARCHAR(50)
);
CREATE TABLE stock_prices (
    price_id SERIAL PRIMARY KEY,
    company_id INT REFERENCES companies(company_id),
    price_date DATE NOT NULL,
    open_price NUMERIC(10, 2),
    high_price NUMERIC(10, 2),
    low_price NUMERIC(10, 2),
    close_price NUMERIC(10, 2),
    volume BIGINT,
    UNIQUE(company_id, price_date)
);
