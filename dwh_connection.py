import pandas as pd
from sqlalchemy import create_engine, text

DWH_URL = "mysql+pymysql://root:snow1998@localhost:3306/base_traitee?charset=utf8mb4"
dwh_engine = create_engine(DWH_URL, pool_pre_ping=True)

def read_dwh_df(sql: str, params=None) -> pd.DataFrame:
    return pd.read_sql(sql, con=dwh_engine, params=params)

def write_dwh_df(df: pd.DataFrame, table: str, if_exists: str = "append", index: bool = False):
    """Insère un DataFrame dans une table du DWH."""
    df.to_sql(table, con=dwh_engine, if_exists=if_exists, index=index)

def execute_dwh(sql: str, params=None):
    """Exécute une requête sans retour (UPDATE, DELETE, etc.)."""
    with dwh_engine.connect() as conn:
        conn.execute(text(sql), params or {})
        conn.commit()