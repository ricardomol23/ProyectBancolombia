SELECT
    fuente,
    COUNT(*) AS registros,
    COUNT(*) FILTER (WHERE id_sistema_cliente IS NULL) AS clientes_nulos,
    COUNT(*) FILTER (WHERE valor_posicion IS NULL) AS valor_nulo
FROM fact_inversiones_consolidada
GROUP BY fuente
ORDER BY fuente;

SELECT
    regla_aplicada,
    COUNT(*) AS registros_ajustados
FROM fact_macroactivos_limpia
GROUP BY regla_aplicada
ORDER BY registros_ajustados DESC;

SELECT
    periodo_corte,
    fuente,
    moneda,
    ROUND(SUM(valor_posicion), 2) AS valor_total
FROM fact_inversiones_consolidada
GROUP BY periodo_corte, fuente, moneda
ORDER BY periodo_corte, fuente, moneda;

SELECT
    id_sistema_cliente,
    fuente,
    moneda,
    ROUND(SUM(valor_posicion), 2) AS valor_total
FROM fact_inversiones_consolidada
WHERE id_sistema_cliente IS NOT NULL
GROUP BY id_sistema_cliente, fuente, moneda
ORDER BY valor_total DESC
LIMIT 20;

SELECT
    id_sistema_cliente,
    COUNT(*) AS posiciones,
    ROUND(SUM(valor_posicion), 2) AS valor_total
FROM fact_inversiones_consolidada
WHERE fuente = 'usd_internacional'
  AND fecha_vencimiento IS NOT NULL
GROUP BY id_sistema_cliente
ORDER BY valor_total DESC
LIMIT 20;

 SELECT
      fuente,
      id_sistema_cliente,
      banca,
      perfil_riesgo,
      clase_activo,
      cod_activo,
      activo,
      valor_posicion,
      moneda
  FROM fact_inversiones_consolidada
  WHERE fuente = 'macroactivos'
  LIMIT 10;