DROP TABLE IF EXISTS dim_perfil_riesgo;
CREATE TABLE dim_perfil_riesgo AS
SELECT DISTINCT
    NULLIF(BTRIM(cod_perfil_riesgo::TEXT), '')::INT AS cod_perfil_riesgo,
    NULLIF(NULLIF(BTRIM(perfil_riesgo::TEXT), ''), 'None') AS perfil_riesgo
FROM cat_perfil_riesgo
WHERE NULLIF(BTRIM(cod_perfil_riesgo::TEXT), '') IS NOT NULL;

ALTER TABLE dim_perfil_riesgo
ADD PRIMARY KEY (cod_perfil_riesgo);

DROP TABLE IF EXISTS dim_activos;
CREATE TABLE dim_activos AS
SELECT DISTINCT
    NULLIF(BTRIM(cod_activo::TEXT), '')::INT AS cod_activo,
    NULLIF(NULLIF(BTRIM(activo::TEXT), ''), 'None') AS activo
FROM catalogo_activos
WHERE NULLIF(BTRIM(cod_activo::TEXT), '') IS NOT NULL;

ALTER TABLE dim_activos
ADD PRIMARY KEY (cod_activo);

DROP TABLE IF EXISTS dim_banca;
CREATE TABLE dim_banca AS
SELECT DISTINCT
    NULLIF(BTRIM(cod_banca::TEXT), '') AS cod_banca,
    NULLIF(NULLIF(BTRIM(banca::TEXT), ''), 'None') AS banca
FROM catalogo_banca
WHERE NULLIF(BTRIM(cod_banca::TEXT), '') IS NOT NULL;

ALTER TABLE dim_banca
ADD PRIMARY KEY (cod_banca);

DROP TABLE IF EXISTS fact_macroactivos_limpia;
CREATE TABLE fact_macroactivos_limpia AS
WITH base AS (
    SELECT
        NULLIF(BTRIM(ingestion_year::TEXT), '') AS ingestion_year_raw,
        NULLIF(BTRIM(ingestion_month::TEXT), '') AS ingestion_month_raw,
        NULLIF(BTRIM(ingestion_day::TEXT), '') AS ingestion_day_raw,
        NULLIF(BTRIM(id_sistema_cliente::TEXT), '') AS id_cliente_raw,
        NULLIF(BTRIM(macroactivo::TEXT), '') AS macroactivo_raw,
        NULLIF(BTRIM(cod_activo::TEXT), '') AS cod_activo_raw,
        NULLIF(BTRIM(aba::TEXT), '') AS aba_raw,
        NULLIF(BTRIM(cod_perfil_riesgo::TEXT), '') AS cod_perfil_raw,
        NULLIF(BTRIM(cod_banca::TEXT), '') AS cod_banca_raw,
        NULLIF(BTRIM(year::TEXT), '') AS year_raw,
        NULLIF(BTRIM(month::TEXT), '') AS month_raw
    FROM historico_aba_macroactivos
),
reconstruido AS (
    SELECT
        ingestion_year_raw,
        ingestion_month_raw,
        CASE
            WHEN id_cliente_raw ~ '^100(FICs|Renta Fija|Renta Variable)$' THEN NULL
            ELSE ingestion_day_raw
        END AS ingestion_day_fix,
        CASE
            WHEN id_cliente_raw IS NULL
                 AND macroactivo_raw ~ '^\d+$'
                 AND cod_activo_raw IN ('FICs', 'Renta Fija', 'Renta Variable')
                THEN macroactivo_raw
            WHEN id_cliente_raw = '100'
                 AND macroactivo_raw ~ '^\d+$'
                 AND cod_activo_raw IN ('FICs', 'Renta Fija', 'Renta Variable')
                THEN id_cliente_raw || macroactivo_raw
            WHEN id_cliente_raw ~ '^100(FICs|Renta Fija|Renta Variable)$'
                THEN '100' || ingestion_day_raw
            ELSE id_cliente_raw
        END AS id_cliente_fix,
        CASE
            WHEN id_cliente_raw IS NULL
                 AND macroactivo_raw ~ '^\d+$'
                 AND cod_activo_raw IN ('FICs', 'Renta Fija', 'Renta Variable')
                THEN cod_activo_raw
            WHEN id_cliente_raw = '100'
                 AND macroactivo_raw ~ '^\d+$'
                 AND cod_activo_raw IN ('FICs', 'Renta Fija', 'Renta Variable')
                THEN cod_activo_raw
            WHEN id_cliente_raw ~ '^100(FICs|Renta Fija|Renta Variable)$'
                THEN SUBSTRING(id_cliente_raw FROM 4)
            WHEN macroactivo_raw IS NULL
                 AND cod_activo_raw IN ('FICs', 'Renta Fija', 'Renta Variable')
                THEN cod_activo_raw
            ELSE macroactivo_raw
        END AS macroactivo_fix,
        CASE
            WHEN id_cliente_raw IS NULL
                 AND macroactivo_raw ~ '^\d+$'
                 AND cod_activo_raw IN ('FICs', 'Renta Fija', 'Renta Variable')
                THEN aba_raw
            WHEN id_cliente_raw = '100'
                 AND macroactivo_raw ~ '^\d+$'
                 AND cod_activo_raw IN ('FICs', 'Renta Fija', 'Renta Variable')
                THEN aba_raw
            WHEN id_cliente_raw ~ '^100(FICs|Renta Fija|Renta Variable)$'
                THEN macroactivo_raw
            WHEN macroactivo_raw IS NULL
                 AND cod_activo_raw IN ('FICs', 'Renta Fija', 'Renta Variable')
                THEN aba_raw
            ELSE cod_activo_raw
        END AS cod_activo_fix,
        CASE
            WHEN id_cliente_raw IS NULL
                 AND macroactivo_raw ~ '^\d+$'
                 AND cod_activo_raw IN ('FICs', 'Renta Fija', 'Renta Variable')
                THEN cod_perfil_raw
            WHEN id_cliente_raw = '100'
                 AND macroactivo_raw ~ '^\d+$'
                 AND cod_activo_raw IN ('FICs', 'Renta Fija', 'Renta Variable')
                THEN cod_perfil_raw
            WHEN id_cliente_raw ~ '^100(FICs|Renta Fija|Renta Variable)$'
                THEN cod_activo_raw
            WHEN macroactivo_raw IS NULL
                 AND cod_activo_raw IN ('FICs', 'Renta Fija', 'Renta Variable')
                THEN cod_perfil_raw
            ELSE aba_raw
        END AS aba_fix,
        CASE
            WHEN id_cliente_raw IS NULL
                 AND macroactivo_raw ~ '^\d+$'
                 AND cod_activo_raw IN ('FICs', 'Renta Fija', 'Renta Variable')
                THEN cod_banca_raw
            WHEN id_cliente_raw = '100'
                 AND macroactivo_raw ~ '^\d+$'
                 AND cod_activo_raw IN ('FICs', 'Renta Fija', 'Renta Variable')
                THEN cod_banca_raw
            WHEN id_cliente_raw ~ '^100(FICs|Renta Fija|Renta Variable)$'
                THEN aba_raw
            WHEN macroactivo_raw IS NULL
                 AND cod_activo_raw IN ('FICs', 'Renta Fija', 'Renta Variable')
                THEN cod_banca_raw
            ELSE cod_perfil_raw
        END AS cod_perfil_fix,
        CASE
            WHEN id_cliente_raw IS NULL
                 AND macroactivo_raw ~ '^\d+$'
                 AND cod_activo_raw IN ('FICs', 'Renta Fija', 'Renta Variable')
                THEN year_raw
            WHEN id_cliente_raw = '100'
                 AND macroactivo_raw ~ '^\d+$'
                 AND cod_activo_raw IN ('FICs', 'Renta Fija', 'Renta Variable')
                THEN year_raw
            WHEN id_cliente_raw ~ '^100(FICs|Renta Fija|Renta Variable)$'
                THEN cod_perfil_raw
            WHEN macroactivo_raw IS NULL
                 AND cod_activo_raw IN ('FICs', 'Renta Fija', 'Renta Variable')
                THEN year_raw
            ELSE cod_banca_raw
        END AS cod_banca_fix,
        CASE
            WHEN id_cliente_raw IS NULL
                 AND macroactivo_raw ~ '^\d+$'
                 AND cod_activo_raw IN ('FICs', 'Renta Fija', 'Renta Variable')
                THEN month_raw
            WHEN id_cliente_raw = '100'
                 AND macroactivo_raw ~ '^\d+$'
                 AND cod_activo_raw IN ('FICs', 'Renta Fija', 'Renta Variable')
                THEN month_raw
            WHEN id_cliente_raw ~ '^100(FICs|Renta Fija|Renta Variable)$'
                THEN cod_banca_raw
            WHEN macroactivo_raw IS NULL
                 AND cod_activo_raw IN ('FICs', 'Renta Fija', 'Renta Variable')
                THEN month_raw
            ELSE year_raw
        END AS year_fix,
        CASE
            WHEN id_cliente_raw IS NULL
                 AND macroactivo_raw ~ '^\d+$'
                 AND cod_activo_raw IN ('FICs', 'Renta Fija', 'Renta Variable')
                THEN ingestion_month_raw
            WHEN id_cliente_raw = '100'
                 AND macroactivo_raw ~ '^\d+$'
                 AND cod_activo_raw IN ('FICs', 'Renta Fija', 'Renta Variable')
                THEN ingestion_month_raw
            WHEN id_cliente_raw ~ '^100(FICs|Renta Fija|Renta Variable)$'
                THEN year_raw
            WHEN macroactivo_raw IS NULL
                 AND cod_activo_raw IN ('FICs', 'Renta Fija', 'Renta Variable')
                THEN ingestion_month_raw
            ELSE month_raw
        END AS month_fix,
        CASE
            WHEN id_cliente_raw IS NULL
                 AND macroactivo_raw ~ '^\d+$'
                 AND cod_activo_raw IN ('FICs', 'Renta Fija', 'Renta Variable')
                THEN 'fila_corrida_sin_id'
            WHEN id_cliente_raw = '100'
                 AND macroactivo_raw ~ '^\d+$'
                 AND cod_activo_raw IN ('FICs', 'Renta Fija', 'Renta Variable')
                THEN 'id_partido_en_dos_columnas'
            WHEN id_cliente_raw ~ '^100(FICs|Renta Fija|Renta Variable)$'
                THEN 'id_y_macroactivo_concatenados'
            WHEN macroactivo_raw IS NULL
                 AND cod_activo_raw IN ('FICs', 'Renta Fija', 'Renta Variable')
                THEN 'macroactivo_desplazado'
            ELSE 'sin_ajuste'
        END AS regla_aplicada
    FROM base
),
tipado AS (
    SELECT
        CASE
            WHEN ingestion_year_raw ~ '^\d{4}(\.0+)?$' THEN ingestion_year_raw::NUMERIC::INT
            ELSE NULL
        END AS ingestion_year,
        CASE
            WHEN ingestion_month_raw ~ '^\d{1,2}(\.0+)?$' THEN ingestion_month_raw::NUMERIC::INT
            ELSE NULL
        END AS ingestion_month,
        CASE
            WHEN ingestion_day_fix ~ '^\d{1,2}(\.0+)?$' THEN ingestion_day_fix::NUMERIC::INT
            ELSE NULL
        END AS ingestion_day,
        CASE
            WHEN id_cliente_fix ~ '^[0-9]+(\.[0-9]+)?([Ee][+-]?[0-9]+)?$'
                THEN CAST(id_cliente_fix AS NUMERIC(20, 0))::BIGINT
            ELSE NULL
        END AS id_sistema_cliente,
        NULLIF(NULLIF(macroactivo_fix, ''), 'None') AS macroactivo,
        CASE
            WHEN cod_activo_fix ~ '^\d+$' THEN cod_activo_fix::INT
            ELSE NULL
        END AS cod_activo,
        CASE
            WHEN aba_fix ~ '^\d+(\.\d+)?$' THEN aba_fix::NUMERIC(18, 2)
            ELSE NULL
        END AS aba,
        CASE
            WHEN cod_perfil_fix ~ '^\d+$' THEN cod_perfil_fix::INT
            ELSE NULL
        END AS cod_perfil_riesgo,
        NULLIF(NULLIF(cod_banca_fix, ''), 'None') AS cod_banca,
        CASE
            WHEN year_fix ~ '^\d{4}(\.0+)?$' THEN year_fix::NUMERIC::INT
            ELSE NULL
        END AS year,
        CASE
            WHEN month_fix ~ '^\d{1,2}(\.0+)?$' THEN month_fix::NUMERIC::INT
            ELSE NULL
        END AS month,
        regla_aplicada
    FROM reconstruido
)
SELECT
    CASE
        WHEN ingestion_year BETWEEN 1900 AND 2100
         AND ingestion_month BETWEEN 1 AND 12
         AND ingestion_day BETWEEN 1 AND 31
            THEN MAKE_DATE(ingestion_year, ingestion_month, ingestion_day)
        ELSE NULL
    END AS fecha_ingestion,
    CASE
        WHEN year BETWEEN 1900 AND 2100
         AND month BETWEEN 1 AND 12
            THEN MAKE_DATE(year, month, 1)
        ELSE NULL
    END AS periodo_corte,
    id_sistema_cliente,
    macroactivo,
    cod_activo,
    aba,
    cod_perfil_riesgo,
    cod_banca,
    regla_aplicada
FROM tipado;

CREATE INDEX idx_macroactivos_cliente
ON fact_macroactivos_limpia (id_sistema_cliente);

CREATE INDEX idx_macroactivos_periodo
ON fact_macroactivos_limpia (periodo_corte);

DROP TABLE IF EXISTS fact_usd_internacional_limpia;
CREATE TABLE fact_usd_internacional_limpia AS
WITH base AS (
    SELECT
        NULLIF(BTRIM(ingestion_year::TEXT), '') AS ingestion_year_raw,
        NULLIF(BTRIM(ingestion_month::TEXT), '') AS ingestion_month_raw,
        NULLIF(BTRIM(ingestion_day::TEXT), '') AS ingestion_day_raw,
        NULLIF(BTRIM(id_sistema_cliente::TEXT), '') AS id_cliente_raw,
        NULLIF(BTRIM(simbol::TEXT), '') AS simbol_raw,
        NULLIF(BTRIM(cusip::TEXT), '') AS cusip_raw,
        NULLIF(BTRIM(isin::TEXT), '') AS isin_raw,
        NULLIF(BTRIM(nombre_activo::TEXT), '') AS nombre_activo_raw,
        NULLIF(BTRIM(cantidad::TEXT), '') AS cantidad_raw,
        NULLIF(BTRIM(valor_mercado::TEXT), '') AS valor_mercado_raw,
        NULLIF(BTRIM(fecha_vencimiento::TEXT), '') AS fecha_vencimiento_raw,
        NULLIF(BTRIM(tasa_cupon::TEXT), '') AS tasa_cupon_raw
    FROM historico_aba_usd_internacional
)
SELECT
    CASE
        WHEN ingestion_year_raw ~ '^\d{4}$'
         AND ingestion_month_raw ~ '^\d{1,2}$'
         AND ingestion_day_raw ~ '^\d{1,2}$'
            THEN MAKE_DATE(
                ingestion_year_raw::INT,
                ingestion_month_raw::INT,
                ingestion_day_raw::INT
            )
        ELSE NULL
    END AS fecha_ingestion,
    CASE
        WHEN id_cliente_raw ~ '^[0-9]+(\.[0-9]+)?([Ee][+-]?[0-9]+)?$'
            THEN CAST(id_cliente_raw AS NUMERIC(20, 0))::BIGINT
        ELSE NULL
    END AS id_sistema_cliente,
    NULLIF(NULLIF(simbol_raw, 'None'), '') AS simbol,
    NULLIF(NULLIF(cusip_raw, 'None'), '') AS cusip,
    NULLIF(NULLIF(isin_raw, 'None'), '') AS isin,
    NULLIF(NULLIF(nombre_activo_raw, 'None'), '') AS nombre_activo,
    CASE
        WHEN cantidad_raw ~ '^\d+(\.\d+)?$' THEN cantidad_raw::NUMERIC(18, 4)
        ELSE NULL
    END AS cantidad,
    CASE
        WHEN valor_mercado_raw ~ '^\d+(\.\d+)?$' THEN valor_mercado_raw::NUMERIC(18, 2)
        ELSE NULL
    END AS valor_mercado,
    CASE
        WHEN fecha_vencimiento_raw IN ('1/01/1900', '01/01/1900', 'None') THEN NULL
        WHEN fecha_vencimiento_raw IS NULL THEN NULL
        WHEN fecha_vencimiento_raw !~ '^\d{1,2}/\d{1,2}/\d{4}$' THEN NULL
        ELSE TO_DATE(fecha_vencimiento_raw, 'FMMM/FMDD/YYYY')
    END AS fecha_vencimiento,
    CASE
        WHEN tasa_cupon_raw IN ('', '1/01/1900', '01/01/1900', 'None') THEN NULL
        WHEN tasa_cupon_raw ~ '^\d+(\.\d+)?$' THEN tasa_cupon_raw::NUMERIC(10, 4)
        ELSE NULL
    END AS tasa_cupon
FROM base;

CREATE INDEX idx_usd_cliente
ON fact_usd_internacional_limpia (id_sistema_cliente);

CREATE INDEX idx_usd_fecha_ingestion
ON fact_usd_internacional_limpia (fecha_ingestion);

DROP TABLE IF EXISTS fact_inversiones_consolidada;
CREATE TABLE fact_inversiones_consolidada AS
SELECT
    'macroactivos'::TEXT AS fuente,
    m.fecha_ingestion,
    m.periodo_corte,
    m.id_sistema_cliente,
    b.banca,
    p.perfil_riesgo,
    m.macroactivo AS clase_activo,
    m.cod_activo,
    a.activo,
    NULL::TEXT AS simbol,
    NULL::TEXT AS cusip,
    NULL::TEXT AS isin,
    NULL::TEXT AS nombre_activo,
    NULL::NUMERIC(18, 4) AS cantidad,
    m.aba AS valor_posicion,
    'COP'::TEXT AS moneda,
    NULL::DATE AS fecha_vencimiento,
    NULL::NUMERIC(10, 4) AS tasa_cupon,
    m.regla_aplicada
FROM fact_macroactivos_limpia m
LEFT JOIN dim_activos a
    ON m.cod_activo = a.cod_activo
LEFT JOIN dim_perfil_riesgo p
    ON m.cod_perfil_riesgo = p.cod_perfil_riesgo
LEFT JOIN dim_banca b
    ON m.cod_banca = b.cod_banca

UNION ALL

SELECT
    'usd_internacional'::TEXT AS fuente,
    u.fecha_ingestion,
    DATE_TRUNC('month', u.fecha_ingestion)::DATE AS periodo_corte,
    u.id_sistema_cliente,
    NULL::TEXT AS banca,
    NULL::TEXT AS perfil_riesgo,
    'Internacional USD'::TEXT AS clase_activo,
    NULL::INT AS cod_activo,
    NULL::TEXT AS activo,
    u.simbol,
    u.cusip,
    u.isin,
    u.nombre_activo,
    u.cantidad,
    u.valor_mercado AS valor_posicion,
    'USD'::TEXT AS moneda,
    u.fecha_vencimiento,
    u.tasa_cupon,
    'sin_ajuste'::TEXT AS regla_aplicada
FROM fact_usd_internacional_limpia u;

CREATE INDEX idx_consolidada_fuente_periodo
ON fact_inversiones_consolidada (fuente, periodo_corte);

CREATE INDEX idx_consolidada_cliente
ON fact_inversiones_consolidada (id_sistema_cliente);
