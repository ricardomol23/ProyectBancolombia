from sqlalchemy import create_engine

DB_URL = "postgresql://postgres:userbd@localhost:5432/bancolombia_prueba"

engine = create_engine(DB_URL)
