from pathlib import Path

import pandas as pd
from sqlalchemy import create_engine

DB_URL = "postgresql://postgres:userbd@localhost:5432/bancolombia_prueba"
BASE_DIR = Path(__file__).resolve().parents[2]
RAW_DIR = BASE_DIR / "data" / "raw"

ARCHIVOS = {
    "cat_perfil_riesgo.csv": "cat_perfil_riesgo",
    "catalogo_activos.csv": "catalogo_activos",
    "catalogo_banca.csv": "catalogo_banca",
    "historico_aba_macroactivos.csv": "historico_aba_macroactivos",
    "historico_aba_usd_internacional.csv": "historico_aba_usd_internacional",
}

engine = create_engine(DB_URL)

for archivo, tabla in ARCHIVOS.items():
    ruta = RAW_DIR / archivo
    print(f"Cargando {archivo} en {tabla} usando {DB_URL}...")
    df = pd.read_csv(ruta, encoding="latin1")
    df.to_sql(tabla, engine, if_exists="append", index=False)

print("Datos cargados correctamente.")
