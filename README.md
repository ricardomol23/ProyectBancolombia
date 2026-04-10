# Proyecto Bancolombia - Analitica de Portafolios de Inversion

## Descripcion

Este proyecto construye una solucion analitica para integrar informacion de portafolios locales e internacionales, consolidarla en PostgreSQL y generar conocimiento del cliente, del portafolio y del negocio a partir de los datos.

La entrega incluye:

- proceso de carga y transformacion de datos
- modelo analitico de segmentacion de clientes con `KMeans`
- dashboard interactivo en `Dash` para visualizacion descriptiva, analitica y de negocio
- scripts SQL de creacion, carga, limpieza y consultas finales

Importante: este repositorio **no incluye** las bases de datos suministradas ni los archivos CSV originales.

## Objetivo del modelo

El modelo analitico implementado segmenta clientes de inversion a partir de caracteristicas del portafolio, por ejemplo:

- exposicion local vs internacional
- nivel de concentracion del portafolio
- numero de posiciones y diversificacion
- participacion por clase de activo
- variables asociadas a activos internacionales como cupon y vencimiento

Con esto se generan:

- perfiles de clientes
- insights automaticos del portafolio
- alertas de riesgo y concentracion
- oportunidades comerciales

## Estructura del proyecto

```text
ProyectBancolombia/
├── assets/
│   └── pipeline_analitico.svg
├── sql/
│   ├── create_tables.sql
│   ├── load_data.sql
│   ├── transformaciones.sql
│   ├── consultas_finales.sql
│   ├── analisis.sql
│   ├── exploracion.sql
│   └── limpieza.sql
├── src/
│   ├── analytics/
│   │   └── modelo.py
│   ├── app/
│   │   └── dashboard.py
│   ├── db/
│   │   └── connection.py
│   └── etl/
│       ├── eda.py
│       └── load_data.py
├── .gitignore
├── main.py
├── requirements.txt
└── README.md
```

## Requisitos

- Python 3.10 o superior
- PostgreSQL 14 o superior
- `psql` disponible en terminal
- Git

Dependencias Python:

- `dash`
- `pandas`
- `plotly`
- `sqlalchemy`
- `psycopg2-binary`
- `scikit-learn`

## Datos de entrada

Los archivos suministrados por la prueba deben ubicarse localmente en:

```text
data/raw/
```

Archivos esperados:

- `cat_perfil_riesgo.csv`
- `catalogo_activos.csv`
- `catalogo_banca.csv`
- `historico_aba_macroactivos.csv`
- `historico_aba_usd_internacional.csv`

Estos archivos no se suben al repositorio por restriccion de la tarea.

## Configuracion de base de datos

El proyecto esta configurado para conectarse a esta base:

```python
postgresql://postgres:userbd@localhost:5432/bancolombia_prueba
```

La conexion esta definida en:

- [src/db/connection.py](D:\Documents%20(D)\ProyectBancolombia\src\db\connection.py)

Si tu usuario, clave, host o nombre de base cambian, debes actualizar ese archivo antes de ejecutar el proyecto.

## Pasos para reproducir la ejecucion

### 1. Clonar el repositorio

```powershell
git clone <URL_DEL_REPOSITORIO>
cd ProyectBancolombia
```

### 2. Crear la base de datos

```powershell
createdb -U postgres bancolombia_prueba
```

Si `createdb` no esta disponible, puedes crearla desde `psql`:

```sql
CREATE DATABASE bancolombia_prueba;
```

### 3. Crear entorno virtual e instalar dependencias

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

### 4. Crear tablas base

```powershell
psql -U postgres -d bancolombia_prueba -f sql/create_tables.sql
```

### 5. Cargar los CSV

Hay dos alternativas.

#### Opcion A. Carga desde `psql` usando el script SQL

Esta opcion usa rutas locales absolutas ya definidas en el proyecto:

```powershell
psql -U postgres -d bancolombia_prueba -f sql/load_data.sql
```

#### Opcion B. Carga desde Python

```powershell
python src/etl/load_data.py
```

### 6. Ejecutar transformaciones y consolidacion

```powershell
psql -U postgres -d bancolombia_prueba -f sql/transformaciones.sql
```

Este paso genera la tabla final:

- `fact_inversiones_consolidada`

### 7. Validar resultados con consultas finales

```powershell
psql -U postgres -d bancolombia_prueba -f sql/consultas_finales.sql
```

Opcionalmente se pueden revisar:

- `sql/analisis.sql`
- `sql/exploracion.sql`
- `sql/limpieza.sql`

### 8. Levantar el dashboard

```powershell
python main.py
```

Luego abrir en el navegador:

```text
http://127.0.0.1:8050
```

## Que muestra el dashboard

El dashboard tiene tres capas:

### 1. Vista descriptiva

- composicion del portafolio local en COP
- composicion del portafolio internacional en USD
- consulta por cliente usando la ultima fecha disponible por fuente

### 2. Vista analitica

- clustering de clientes con `KMeans`
- resumen por cluster
- segmentacion segun exposicion, concentracion y composicion del portafolio

### 3. Vista de negocio

- insights automaticos por cliente
- alertas de riesgo
- oportunidades comerciales y de rebalanceo

## Video de demostracion

Agregar aqui el video solicitado por la entrega:

- Si el video queda dentro del repositorio: `assets/demo.mp4`
- Si el video se publica externamente: pegar aqui el enlace

Ejemplo:

```text
Video demo: https://drive.google.com/file/d/1Gk1m5K-Cj_YlZVKoN-F_jpEtu0O1QKon/view?usp=sharing
```

## Notas importantes

- No se incluyen los datos fuente en este repositorio.
- El proyecto fue preparado para ejecutarse en entorno local con PostgreSQL.
- La conexion a base de datos esta parametrizada manualmente en el codigo.
- Si `sql/load_data.sql` falla por ruta, ajusta las rutas absolutas al directorio local del proyecto.

## Autor

Ricardo Molina
Estudiante de Ingenieria en Analítica de datos.
