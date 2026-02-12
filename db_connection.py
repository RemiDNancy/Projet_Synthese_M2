# libraries to connect to database
# Using SQLAlchemy because it's better while using pandas

import pandas as pd
from sqlalchemy import create_engine
#MOTDEPASSE -> replace par vos mot de passe
DB_URL = "mysql+pymysql://root:MOTDEPASSE@localhost:3306/kickstarter?charset=utf8mb4"
engine = create_engine(DB_URL, pool_pre_ping=True)

""" Function that takes an sql query (string) and expected to return a panda dataframe """
def read_sql_df(sql: str, params=None) -> pd.DataFrame:
    return pd.read_sql(sql, con=engine, params=params)

