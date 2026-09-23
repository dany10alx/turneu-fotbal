import os
from pathlib import Path

from dotenv import load_dotenv
from sqlalchemy import URL, create_engine
from sqlalchemy.orm import DeclarativeBase, sessionmaker

load_dotenv(Path(__file__).resolve().parents[1] / ".env")


def get_database_url() -> str | URL:
    database_url = os.getenv("DATABASE_URL")
    if database_url:
        # Railway poate furniza URL-ul cu schema legacy postgres://.
        return database_url.replace("postgres://", "postgresql+psycopg2://", 1)

    database_name = os.getenv("DB_NAME")
    if database_name:
        return URL.create(
            drivername="postgresql+psycopg2",
            username=os.getenv("DB_USER"),
            password=os.getenv("DB_PASSWORD"),
            host=os.getenv("DB_HOST", "localhost"),
            port=int(os.getenv("DB_PORT", "5432")),
            database=database_name,
        )

    return "sqlite:///./tournament.db"


DATABASE_URL = get_database_url()
is_sqlite = (
    DATABASE_URL.drivername.startswith("sqlite")
    if isinstance(DATABASE_URL, URL)
    else DATABASE_URL.startswith("sqlite")
)

engine = create_engine(
    DATABASE_URL,
    connect_args={"check_same_thread": False} if is_sqlite else {},
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


class Base(DeclarativeBase):
    """Clasa de bază pentru modelele SQLAlchemy."""
