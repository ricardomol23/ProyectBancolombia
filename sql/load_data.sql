TRUNCATE TABLE cat_perfil_riesgo;
TRUNCATE TABLE catalogo_activos;
TRUNCATE TABLE catalogo_banca;
TRUNCATE TABLE historico_aba_macroactivos;
TRUNCATE TABLE historico_aba_usd_internacional;

\copy cat_perfil_riesgo
FROM 'D:/Documents (D)/ProyectBancolombia/data/raw/cat_perfil_riesgo.csv'
WITH (FORMAT csv, HEADER true, ENCODING 'LATIN1');

\copy catalogo_activos
FROM 'D:/Documents (D)/ProyectBancolombia/data/raw/catalogo_activos.csv'
WITH (FORMAT csv, HEADER true, ENCODING 'LATIN1');

\copy catalogo_banca
FROM 'D:/Documents (D)/ProyectBancolombia/data/raw/catalogo_banca.csv'
WITH (FORMAT csv, HEADER true, ENCODING 'LATIN1');

\copy historico_aba_macroactivos
FROM 'D:/Documents (D)/ProyectBancolombia/data/raw/historico_aba_macroactivos.csv'
WITH (FORMAT csv, HEADER true, ENCODING 'LATIN1');

\copy historico_aba_usd_internacional
FROM 'D:/Documents (D)/ProyectBancolombia/data/raw/historico_aba_usd_internacional.csv'
WITH (FORMAT csv, HEADER true, ENCODING 'LATIN1');
