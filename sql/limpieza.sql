SELECT
    CAST(id_sistema_cliente AS NUMERIC) AS BIGINT
FROM historico_aba_macroactivos
LIMIT 10;

SELECT
    CAST(valor_mercado AS NUMERIC) AS valor
FROM historico_aba_usd_internacional
LIMIT 10;

SELECT
    MAKE_DATE(
        ingestion_year::INT,
        ingestion_month::INT,
        ingestion_day::INT
    ) AS fecha
FROM historico_aba_macroactivos
LIMIT 10;

