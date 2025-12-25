from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os

# =============================================================================
# DATABASE CONFIGURATION - TO BE CONFIGURED BY IT DEPARTMENT
# =============================================================================
# Set the DATABASE_URL environment variable with your database connection string
# 
# Supported formats:
#   PostgreSQL: postgresql://username:password@host:port/database_name
#   MySQL:      mysql+pymysql://username:password@host:port/database_name
#   SQL Server: mssql+pyodbc://username:password@host:port/database_name?driver=ODBC+Driver+17+for+SQL+Server
#   SQLite:     sqlite:///path/to/database.db
#
# Example for hospital data warehouse:
#   DATABASE_URL=postgresql://db_user:db_password@hospital-server:5432/medical_services
#
# IMPORTANT: Never commit credentials to version control!
# =============================================================================

DATABASE_URL = os.getenv("DATABASE_URL")

if not DATABASE_URL:
    raise ValueError(
        "\n" + "="*70 + "\n"
        "DATABASE_URL environment variable is not set!\n"
        "Please configure your database connection string.\n"
        "Example: DATABASE_URL=postgresql://user:pass@host:port/dbname\n"
        + "="*70
    )

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()