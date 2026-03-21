# libraries to connect to database
# Using SQLAlchemy for pandas (read_sql_df)
# Using pymysql native connection for cursor-based operations (data_to_dwh)

import pandas as pd
import pymysql
from sqlalchemy import create_engine

# ── Credentials ────────────────────────────────────────────────────────────────
DB_HOST     = "localhost"
DB_USER     = "root"
DB_PASSWORD = "snow1998"
DB_PORT     = 3306

# ── SQLAlchemy engine (pandas) ─────────────────────────────────────────────────

DB_URL = f"mysql+pymysql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/kickstarter?charset=utf8mb4"
engine = create_engine(DB_URL, pool_pre_ping=True)

# Function that takes an sql query (string) and expected to return a panda dataframe
def read_sql_df(sql: str, params=None) -> pd.DataFrame:
    return pd.read_sql(sql, con=engine, params=params)

# ── Native connection for cursor-based operations ─────────────────────────────────────────────────
def get_connection(db: str = "kickstarter") -> pymysql.connections.Connection:
    """
    Args:
        db: database name — "kickstarter" or "base_traitee"
    Returns:
        pymysql.Connection (caller is responsible for conn.close())
    """
    return pymysql.connect(
        host     = DB_HOST,
        user     = DB_USER,
        password = DB_PASSWORD,
        port     = DB_PORT,
        database = db,
        charset  = "utf8mb4",
        autocommit = False,
    )
 