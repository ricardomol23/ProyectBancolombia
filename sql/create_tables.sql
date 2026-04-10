DROP TABLE IF EXISTS fact_inversiones_consolidada;
DROP TABLE IF EXISTS fact_usd_internacional_limpia;
DROP TABLE IF EXISTS fact_macroactivos_limpia;
DROP TABLE IF EXISTS dim_banca;
DROP TABLE IF EXISTS dim_activos;
DROP TABLE IF EXISTS dim_perfil_riesgo;

DROP TABLE IF EXISTS historico_aba_usd_internacional;
DROP TABLE IF EXISTS historico_aba_macroactivos;
DROP TABLE IF EXISTS catalogo_banca;
DROP TABLE IF EXISTS catalogo_activos;
DROP TABLE IF EXISTS cat_perfil_riesgo;

CREATE TABLE cat_perfil_riesgo (
    cod_perfil_riesgo TEXT,
    perfil_riesgo TEXT
);

CREATE TABLE catalogo_activos (
    activo TEXT,
    cod_activo TEXT
);

CREATE TABLE catalogo_banca (
    cod_banca TEXT,
    banca TEXT
);

CREATE TABLE historico_aba_macroactivos (
    ingestion_year TEXT,
    ingestion_month TEXT,
    ingestion_day TEXT,
    id_sistema_cliente TEXT,
    macroactivo TEXT,
    cod_activo TEXT,
    aba TEXT,
    cod_perfil_riesgo TEXT,
    cod_banca TEXT,
    year TEXT,
    month TEXT
);

CREATE TABLE historico_aba_usd_internacional (
    ingestion_year TEXT,
    ingestion_month TEXT,
    ingestion_day TEXT,
    id_sistema_cliente TEXT,
    simbol TEXT,
    cusip TEXT,
    isin TEXT,
    nombre_activo TEXT,
    cantidad TEXT,
    valor_mercado TEXT,
    fecha_vencimiento TEXT,
    tasa_cupon TEXT
);

