import pandas as pd
from sqlalchemy import create_engine

# conexión
engine = create_engine("postgresql://postgres:userbd@localhost:5432/bancolombia_prueba")  # 🔥 CAMBIO AQUÍ

# cargar tablas
df_macro = pd.read_sql("SELECT * FROM historico_aba_macroactivos", engine)
df_usd = pd.read_sql("SELECT * FROM historico_aba_usd_internacional", engine)

# ======================
# 📊 INFORMACIÓN GENERAL
# ======================

print("MACROACTIVOS INFO")
print(df_macro.info())

print("\nUSD INFO")
print(df_usd.info())

# ======================
# 🔍 NULOS
# ======================

print("\nNULOS MACROACTIVOS")
print(df_macro.isnull().sum())

print("\nNULOS USD")
print(df_usd.isnull().sum())

# ======================
# 🔍 CLIENTES (problema clave)
# ======================

print("\nCLIENTES MACROACTIVOS")
print(df_macro['id_sistema_cliente'].head(20))

# detectar valores raros
print("\nVALORES RAROS EN CLIENTE")
print(df_macro['id_sistema_cliente'].astype(str).str.contains('[A-Za-z]', regex=True).sum())

# ======================
# 📊 ESTADÍSTICAS
# ======================

print("\nESTADÍSTICAS ABA")
print(df_macro['aba'].describe())

print("\nESTADÍSTICAS USD")
print(df_usd['valor_mercado'].describe())

# ======================
# 📅 FECHAS
# ======================

df_macro['fecha'] = pd.to_datetime(
    df_macro['ingestion_year'].astype(int).astype(str) + '-' +
    df_macro['ingestion_month'].astype(int).astype(str) + '-' +
    df_macro['ingestion_day'].astype(int).astype(str)
)

print("\nRANGO FECHAS MACRO")
print(df_macro['fecha'].min(), df_macro['fecha'].max())