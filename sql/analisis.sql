SELECT COUNT(*) FROM historico_aba_macroactivos;

SELECT
    COUNT(*) FILTER (WHERE id_sistema_cliente IS NULL) AS null_cliente,
    COUNT(*) FILTER (WHERE aba IS NULL) AS null_valor
FROM historico_aba_macroactivos;

SELECT DISTINCT id_sistema_cliente
FROM historico_aba_macroactivos
LIMIT 20;

SELECT DISTINCT ingestion_year, ingestion_month
FROM historico_aba_macroactivos
ORDER BY ingestion_year DESC, ingestion_month DESC;