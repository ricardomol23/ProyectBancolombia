import pandas as pd
import plotly.express as px
from dash import Dash, Input, Output, dcc, html, dash_table

from src.analytics.modelo import build_client_insights, build_cluster_figure, train_kmeans
from src.db.connection import engine

QUERY_CLIENTES = """
SELECT DISTINCT id_sistema_cliente
FROM fact_inversiones_consolidada
WHERE id_sistema_cliente IS NOT NULL
ORDER BY id_sistema_cliente;
"""

QUERY_FECHAS = """
SELECT
    fuente,
    MAX(fecha_ingestion) AS ultima_fecha
FROM fact_inversiones_consolidada
WHERE fecha_ingestion IS NOT NULL
GROUP BY fuente;
"""

QUERY_PORTAFOLIO = """
WITH ultimas_fechas AS (
    SELECT
        fuente,
        id_sistema_cliente,
        MAX(fecha_ingestion) AS ultima_fecha
    FROM fact_inversiones_consolidada
    WHERE id_sistema_cliente = %(cliente)s
      AND fecha_ingestion IS NOT NULL
    GROUP BY fuente
        , id_sistema_cliente
)
SELECT
    f.fuente,
    f.fecha_ingestion,
    f.id_sistema_cliente,
    f.banca,
    f.perfil_riesgo,
    f.clase_activo,
    f.cod_activo,
    f.activo,
    f.simbol,
    f.nombre_activo,
    f.valor_posicion,
    f.moneda,
    f.fecha_vencimiento
FROM fact_inversiones_consolidada f
INNER JOIN ultimas_fechas u
    ON f.fuente = u.fuente
   AND f.id_sistema_cliente = u.id_sistema_cliente
   AND f.fecha_ingestion = u.ultima_fecha
WHERE f.id_sistema_cliente = %(cliente)s
ORDER BY f.fuente, f.valor_posicion DESC;
"""


def load_clientes() -> list[dict]:
    df = pd.read_sql(QUERY_CLIENTES, engine)
    return [{"label": str(cliente), "value": int(cliente)} for cliente in df["id_sistema_cliente"]]


def load_fechas() -> pd.DataFrame:
    return pd.read_sql(QUERY_FECHAS, engine)


def load_portafolio(cliente: int) -> pd.DataFrame:
    return pd.read_sql(QUERY_PORTAFOLIO, engine, params={"cliente": cliente})


def build_app() -> Dash:
    clientes = load_clientes()
    fechas = load_fechas()
    cluster_df, cluster_summary = train_kmeans()
    cluster_fig = build_cluster_figure(cluster_df)

    app = Dash(__name__)
    app.title = "Portafolio de Clientes"

    app.layout = html.Div(
        style={
            "fontFamily": "Segoe UI, sans-serif",
            "backgroundColor": "#f6f4ef",
            "minHeight": "100vh",
            "padding": "24px",
            "color": "#1f2937",
        },
        children=[
            html.H1("Portafolio Local e Internacional"),
            html.P("Visualizacion del portafolio por cliente usando la ultima fecha disponible por fuente."),
            html.Div(
                style={
                    "display": "grid",
                    "gridTemplateColumns": "2fr 1fr 1fr 1fr",
                    "gap": "16px",
                    "marginBottom": "24px",
                    "alignItems": "end",
                },
                children=[
                    html.Div(
                        children=[
                            html.Label("Cliente"),
                            dcc.Dropdown(
                                id="cliente-dropdown",
                                options=clientes,
                                value=clientes[0]["value"] if clientes else None,
                                placeholder="Seleccione un cliente",
                            ),
                        ]
                    ),
                    html.Div(
                        style={"backgroundColor": "#ffffff", "padding": "12px", "borderRadius": "10px"},
                        children=[
                            html.Div("Ultima fecha local", style={"fontSize": "12px", "color": "#6b7280"}),
                            html.Strong(
                                str(
                                    fechas.loc[fechas["fuente"] == "macroactivos", "ultima_fecha"].iloc[0]
                                ) if not fechas.loc[fechas["fuente"] == "macroactivos"].empty else "N/D"
                            ),
                        ],
                    ),
                    html.Div(
                        style={"backgroundColor": "#ffffff", "padding": "12px", "borderRadius": "10px"},
                        children=[
                            html.Div("Ultima fecha internacional", style={"fontSize": "12px", "color": "#6b7280"}),
                            html.Strong(
                                str(
                                    fechas.loc[fechas["fuente"] == "usd_internacional", "ultima_fecha"].iloc[0]
                                ) if not fechas.loc[fechas["fuente"] == "usd_internacional"].empty else "N/D"
                            ),
                        ],
                    ),
                    html.Div(
                        id="tarjeta-cluster",
                        style={"backgroundColor": "#ffffff", "padding": "12px", "borderRadius": "10px"},
                    ),
                ],
            ),
            html.Div(
                style={"marginBottom": "12px", "marginTop": "8px"},
                children=[
                    html.H2("Capa 1. Vista Descriptiva", style={"marginBottom": "4px"}),
                    html.P("Muestra el portafolio local e internacional del cliente seleccionado."),
                ],
            ),
            html.Div(
                style={
                    "display": "grid",
                    "gridTemplateColumns": "1fr 1fr",
                    "gap": "16px",
                    "marginBottom": "24px",
                },
                children=[
                    dcc.Graph(id="grafico-local"),
                    dcc.Graph(id="grafico-internacional"),
                ],
            ),
            html.Div(
                style={"marginBottom": "12px"},
                children=[
                    html.H2("Capa 2. Vista Analitica", style={"marginBottom": "4px"}),
                    html.P("Segmentacion de clientes con KMeans y resumen comparativo de clusters."),
                ],
            ),
            html.Div(
                style={"backgroundColor": "#ffffff", "padding": "16px", "borderRadius": "10px", "marginBottom": "24px"},
                children=[
                    dcc.Graph(id="grafico-clusters", figure=cluster_fig),
                ],
            ),
            html.Div(
                style={"backgroundColor": "#ffffff", "padding": "16px", "borderRadius": "10px", "marginBottom": "24px"},
                children=[
                    html.H3("Resumen de clusters"),
                    dash_table.DataTable(
                        data=cluster_summary.round(4).to_dict("records"),
                        columns=[{"name": col, "id": col} for col in cluster_summary.columns],
                        page_size=10,
                        style_table={"overflowX": "auto"},
                        style_cell={"textAlign": "left", "padding": "8px"},
                        style_header={"fontWeight": "bold"},
                    ),
                ],
            ),
            html.Div(
                style={"marginBottom": "12px"},
                children=[
                    html.H2("Capa 3. Vista de Negocio", style={"marginBottom": "4px"}),
                    html.P("Insights automaticos, alertas y oportunidades comerciales para el cliente."),
                ],
            ),
            html.Div(
                style={
                    "display": "grid",
                    "gridTemplateColumns": "1fr 1fr",
                    "gap": "16px",
                    "marginBottom": "24px",
                },
                children=[
                    html.Div(
                        style={"backgroundColor": "#ffffff", "padding": "16px", "borderRadius": "10px"},
                        children=[
                            html.H3("Insights del cliente"),
                            html.Div(id="insights-cliente"),
                        ],
                    ),
                    html.Div(
                        style={"backgroundColor": "#ffffff", "padding": "16px", "borderRadius": "10px"},
                        children=[
                            html.H3("Oportunidades comerciales"),
                            html.Div(id="acciones-cliente"),
                        ],
                    ),
                ],
            ),
        ],
    )

    @app.callback(
        Output("grafico-local", "figure"),
        Output("grafico-internacional", "figure"),
        Output("tarjeta-cluster", "children"),
        Output("insights-cliente", "children"),
        Output("acciones-cliente", "children"),
        Input("cliente-dropdown", "value"),
    )
    def update_dashboard(cliente):
        if cliente is None:
            cliente = clientes[0]["value"] if clientes else None

        df = load_portafolio(cliente)
        cluster_match = cluster_df.loc[cluster_df["id_sistema_cliente"] == cliente]
        cluster_row = None if cluster_match.empty else cluster_match.iloc[0]

        local_df = df[df["moneda"] == "COP"].copy()
        internacional_df = df[df["moneda"] == "USD"].copy()

        if local_df.empty:
            fig_local = px.bar(title="Sin posiciones locales para el cliente seleccionado")
        else:
            local_df["etiqueta"] = local_df["activo"].fillna(local_df["clase_activo"])
            resumen_local = (
                local_df.groupby("etiqueta", as_index=False)["valor_posicion"]
                .sum()
                .sort_values("valor_posicion", ascending=False)
            )
            fig_local = px.bar(
                resumen_local,
                x="etiqueta",
                y="valor_posicion",
                color="valor_posicion",
                title="Portafolio local (COP)",
                labels={"etiqueta": "Activo", "valor_posicion": "Valor"},
            )

        if internacional_df.empty:
            fig_int = px.bar(title="Sin posiciones internacionales para el cliente seleccionado")
        else:
            internacional_df["etiqueta"] = internacional_df["nombre_activo"].fillna(internacional_df["simbol"])
            resumen_int = (
                internacional_df.groupby("etiqueta", as_index=False)["valor_posicion"]
                .sum()
                .sort_values("valor_posicion", ascending=False)
            )
            fig_int = px.bar(
                resumen_int,
                x="etiqueta",
                y="valor_posicion",
                color="valor_posicion",
                title="Portafolio internacional (USD)",
                labels={"etiqueta": "Activo", "valor_posicion": "Valor"},
            )

        if cluster_row is None:
            cluster_card = [html.Div("Cluster del cliente"), html.Strong("Sin cluster disponible")]
        else:
            insights, acciones, riesgo = build_client_insights(cluster_row, df)
            cluster_card = [
                html.Div("Cluster del cliente", style={"fontSize": "12px", "color": "#6b7280"}),
                html.Strong(cluster_row["cluster_nombre"]),
                html.Div(
                    f"Exposicion USD: {cluster_row['porcentaje_usd']:.2%} | "
                    f"Concentracion Top 1: {cluster_row['concentracion_top1']:.2%} | Riesgo: {riesgo}",
                    style={"marginTop": "6px"},
                ),
            ]
        if cluster_row is None:
            insights = ["Sin insights disponibles para el cliente."]
            acciones = ["Sin acciones sugeridas."]

        insights_component = html.Ul([html.Li(texto) for texto in insights])
        acciones_component = html.Ul([html.Li(texto) for texto in acciones])

        return (
            fig_local,
            fig_int,
            cluster_card,
            insights_component,
            acciones_component,
        )

    return app
