import pandas as pd
import plotly.express as px
from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler

from src.db.connection import engine

QUERY_FEATURES = """
WITH base AS (
    SELECT
        id_sistema_cliente,
        fuente,
        moneda,
        COALESCE(clase_activo, 'Sin clasificar') AS clase_activo,
        COALESCE(activo, nombre_activo, simbol, 'Sin nombre') AS nombre_posicion,
        valor_posicion,
        fecha_vencimiento,
        tasa_cupon
    FROM fact_inversiones_consolidada
    WHERE id_sistema_cliente IS NOT NULL
      AND valor_posicion IS NOT NULL
),
resumen AS (
    SELECT
        id_sistema_cliente,
        SUM(CASE WHEN moneda = 'COP' THEN valor_posicion ELSE 0 END) AS valor_total_cop,
        SUM(CASE WHEN moneda = 'USD' THEN valor_posicion ELSE 0 END) AS valor_total_usd,
        SUM(valor_posicion) AS valor_total_portafolio,
        COUNT(*) AS numero_posiciones,
        COUNT(DISTINCT nombre_posicion) AS numero_activos_distintos,
        MAX(valor_posicion) AS posicion_maxima,
        SUM(CASE WHEN clase_activo = 'Renta Variable' THEN valor_posicion ELSE 0 END) AS valor_renta_variable,
        SUM(CASE WHEN clase_activo = 'Renta Fija' THEN valor_posicion ELSE 0 END) AS valor_renta_fija,
        SUM(CASE WHEN clase_activo = 'FICs' THEN valor_posicion ELSE 0 END) AS valor_fics,
        AVG(CASE WHEN moneda = 'USD' THEN tasa_cupon END) AS tasa_cupon_promedio_usd,
        AVG(CASE
            WHEN moneda = 'USD' AND fecha_vencimiento IS NOT NULL
                THEN (fecha_vencimiento - CURRENT_DATE)
            END) AS dias_vencimiento_promedio_usd
    FROM base
    GROUP BY id_sistema_cliente
)
SELECT
    id_sistema_cliente,
    valor_total_cop,
    valor_total_usd,
    valor_total_portafolio,
    numero_posiciones,
    numero_activos_distintos,
    posicion_maxima,
    COALESCE(valor_total_usd / NULLIF(valor_total_portafolio, 0), 0) AS porcentaje_usd,
    COALESCE(valor_total_cop / NULLIF(valor_total_portafolio, 0), 0) AS porcentaje_cop,
    COALESCE(posicion_maxima / NULLIF(valor_total_portafolio, 0), 0) AS concentracion_top1,
    COALESCE(valor_renta_variable / NULLIF(valor_total_portafolio, 0), 0) AS porcentaje_renta_variable,
    COALESCE(valor_renta_fija / NULLIF(valor_total_portafolio, 0), 0) AS porcentaje_renta_fija,
    COALESCE(valor_fics / NULLIF(valor_total_portafolio, 0), 0) AS porcentaje_fics,
    COALESCE(tasa_cupon_promedio_usd, 0) AS tasa_cupon_promedio_usd,
    COALESCE(dias_vencimiento_promedio_usd, 0) AS dias_vencimiento_promedio_usd
FROM resumen
WHERE valor_total_portafolio > 0;
"""

FEATURE_COLUMNS = [
    "valor_total_cop",
    "valor_total_usd",
    "numero_posiciones",
    "numero_activos_distintos",
    "porcentaje_usd",
    "concentracion_top1",
    "porcentaje_renta_variable",
    "porcentaje_renta_fija",
    "porcentaje_fics",
    "tasa_cupon_promedio_usd",
    "dias_vencimiento_promedio_usd",
]

CLUSTER_LABELS = {
    0: "Local concentrado",
    1: "Mixto diversificado",
    2: "Internacional",
    3: "Fondos y conservador",
}


def load_feature_matrix() -> pd.DataFrame:
    return pd.read_sql(QUERY_FEATURES, engine)


def train_kmeans(n_clusters: int = 4) -> tuple[pd.DataFrame, pd.DataFrame]:
    df = load_feature_matrix()

    if df.empty:
        return df, pd.DataFrame()

    clusters = min(n_clusters, len(df))
    if clusters < 2:
        df["cluster"] = 0
        df["cluster_nombre"] = "Cluster unico"
        return df, summarize_clusters(df)

    scaler = StandardScaler()
    scaled = scaler.fit_transform(df[FEATURE_COLUMNS])

    model = KMeans(n_clusters=clusters, random_state=42, n_init=10)
    df["cluster"] = model.fit_predict(scaled)
    df["cluster_nombre"] = df["cluster"].map(CLUSTER_LABELS).fillna("Cluster")

    return df, summarize_clusters(df)


def summarize_clusters(df: pd.DataFrame) -> pd.DataFrame:
    if df.empty:
        return pd.DataFrame()

    resumen = (
        df.groupby(["cluster", "cluster_nombre"], as_index=False)
        .agg(
            clientes=("id_sistema_cliente", "count"),
            valor_promedio=("valor_total_portafolio", "mean"),
            porcentaje_usd_promedio=("porcentaje_usd", "mean"),
            posiciones_promedio=("numero_posiciones", "mean"),
            concentracion_promedio=("concentracion_top1", "mean"),
        )
        .sort_values("cluster")
    )
    return resumen


def cluster_for_client(cliente: int) -> pd.Series | None:
    df, _ = train_kmeans()
    if df.empty:
        return None

    row = df.loc[df["id_sistema_cliente"] == cliente]
    if row.empty:
        return None
    return row.iloc[0]


def build_cluster_figure(df: pd.DataFrame):
    if df.empty:
        return px.scatter(title="Sin informacion para clustering")

    plot_df = df.copy()
    plot_df["id_sistema_cliente"] = plot_df["id_sistema_cliente"].astype(str)

    fig = px.scatter(
        plot_df,
        x="porcentaje_usd",
        y="concentracion_top1",
        size="valor_total_portafolio",
        color="cluster_nombre",
        hover_name="id_sistema_cliente",
        title="Segmentacion de clientes con KMeans",
        labels={
            "porcentaje_usd": "Exposicion internacional",
            "concentracion_top1": "Concentracion Top 1",
            "valor_total_portafolio": "Valor total portafolio",
            "cluster_nombre": "Segmento",
        },
    )
    return fig


def build_client_insights(cluster_row: pd.Series | None, portfolio_df: pd.DataFrame) -> tuple[list[str], list[str], str]:
    if cluster_row is None:
        return (
            ["No fue posible asignar cluster al cliente seleccionado."],
            ["Validar que el cliente tenga informacion suficiente en la tabla consolidada."],
            "Sin clasificar",
        )

    insights: list[str] = []
    acciones: list[str] = []

    porcentaje_usd = float(cluster_row["porcentaje_usd"])
    concentracion = float(cluster_row["concentracion_top1"])
    posiciones = int(cluster_row["numero_posiciones"])
    activos = int(cluster_row["numero_activos_distintos"])
    valor_total = float(cluster_row["valor_total_portafolio"])
    pct_rv = float(cluster_row["porcentaje_renta_variable"])
    pct_rf = float(cluster_row["porcentaje_renta_fija"])
    pct_fics = float(cluster_row["porcentaje_fics"])

    if porcentaje_usd >= 0.6:
        insights.append("Alta exposicion internacional: mas del 60% del portafolio esta en USD.")
        acciones.append("Ofrecer coberturas cambiarias o alternativas locales para balancear riesgo de moneda.")
    elif porcentaje_usd <= 0.1:
        insights.append("Baja exposicion internacional: el portafolio esta concentrado principalmente en COP.")
        acciones.append("Explorar productos internacionales para diversificar geografica y sectorialmente.")
    else:
        insights.append("Portafolio mixto con exposicion combinada en COP y USD.")
        acciones.append("Evaluar rebalanceos tacticos segun perfil de riesgo y objetivo comercial.")

    if concentracion >= 0.5:
        insights.append("Alta concentracion: la posicion principal supera el 50% del portafolio.")
        acciones.append("Priorizar una estrategia de diversificacion para reducir riesgo especifico.")
    elif concentracion >= 0.3:
        insights.append("Concentracion moderada: la posicion principal tiene peso relevante en el portafolio.")
        acciones.append("Revisar limites internos de concentracion y alternativas complementarias.")
    else:
        insights.append("Concentracion controlada: no se observa una posicion dominante extrema.")

    if activos <= 3:
        insights.append("Diversificacion baja: el cliente tiene muy pocos activos distintos.")
        acciones.append("Proponer canasta complementaria de activos o fondos para ampliar diversificacion.")
    else:
        insights.append(f"Diversificacion aceptable con {activos} activos distintos y {posiciones} posiciones.")

    if pct_rv >= 0.7:
        insights.append("Sesgo accionario alto: la mayor parte del portafolio esta en renta variable.")
    elif pct_rf >= 0.5:
        insights.append("Predominio de renta fija: el portafolio favorece estabilidad y flujo.")
    elif pct_fics >= 0.4:
        insights.append("Peso relevante en FICs: el cliente usa vehiculos colectivos para exposicion.")

    if valor_total >= 1_000_000_000:
        acciones.append("Cliente de alto valor: considerar gestion comercial prioritaria y seguimiento personalizado.")

    if portfolio_df.empty:
        riesgo = "Sin datos"
    elif concentracion >= 0.5 or pct_rv >= 0.7:
        riesgo = "Alto"
    elif concentracion >= 0.3 or porcentaje_usd >= 0.6:
        riesgo = "Medio"
    else:
        riesgo = "Controlado"

    return insights, acciones, riesgo
