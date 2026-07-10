SELECT * FROM stock_prices;

USE stocks_db;

DROP VIEW IF EXISTS stock_moving_average_signals;

CREATE VIEW stock_moving_average_signals AS
WITH srednie AS (
    SELECT
        sp.price_id,
        sp.company_id,
        c.ticker,
        c.company_name,
        sp.price_date,
        sp.close_price,
        sp.volume,

        COUNT(sp.close_price) OVER (
            PARTITION BY sp.company_id
            ORDER BY sp.price_date
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) AS liczba_dni_sma7,

        AVG(sp.close_price) OVER (
            PARTITION BY sp.company_id
            ORDER BY sp.price_date
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) AS sma7,

        COUNT(sp.close_price) OVER (
            PARTITION BY sp.company_id
            ORDER BY sp.price_date
            ROWS BETWEEN 49 PRECEDING AND CURRENT ROW
        ) AS liczba_dni_sma50,

        AVG(sp.close_price) OVER (
            PARTITION BY sp.company_id
            ORDER BY sp.price_date
            ROWS BETWEEN 49 PRECEDING AND CURRENT ROW
        ) AS sma50

    FROM stock_prices AS sp
    JOIN companies AS c
        ON c.company_id = sp.company_id
),

poprzednie_srednie AS (
    SELECT
        price_id,
        company_id,
        ticker,
        company_name,
        price_date,
        close_price,
        volume,
        liczba_dni_sma7,
        liczba_dni_sma50,
        sma7,
        sma50,

        LAG(sma7) OVER (
            PARTITION BY company_id
            ORDER BY price_date
        ) AS poprzednia_sma7,

        LAG(sma50) OVER (
            PARTITION BY company_id
            ORDER BY price_date
        ) AS poprzednia_sma50

    FROM srednie
)

SELECT
    price_id,
    company_id,
    ticker,
    company_name,
    price_date,

    ROUND(close_price, 2) AS cena_zamkniecia,

    CASE
        WHEN liczba_dni_sma7 = 7
        THEN ROUND(sma7, 2)
        ELSE NULL
    END AS sma7,

    CASE
        WHEN liczba_dni_sma50 = 50
        THEN ROUND(sma50, 2)
        ELSE NULL
    END AS sma50,

    volume,

    CASE
        WHEN liczba_dni_sma50 < 50 THEN NULL

        WHEN poprzednia_sma7 <= poprzednia_sma50
             AND sma7 > sma50
        THEN 'KUP'

        WHEN poprzednia_sma7 >= poprzednia_sma50
             AND sma7 < sma50
        THEN 'SPRZEDAJ'

        ELSE 'BRAK SYGNAŁU'
    END AS sygnal

FROM poprzednie_srednie;


SELECT
    price_date,
    cena_zamkniecia,
    sma7,
    sma50,
    sygnal
FROM stock_moving_average_signals
WHERE ticker = 'KTY'
  AND sygnal IN ('KUP', 'SPRZEDAJ')
ORDER BY price_date;
