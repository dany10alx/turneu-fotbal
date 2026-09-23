import sys
from logging.config import fileConfig
from pathlib import Path

from dotenv import load_dotenv

from sqlalchemy import engine_from_config
from sqlalchemy import pool

from alembic import context

# Facem rădăcina proiectului disponibilă pentru importuri când Alembic este lansat din proiect.
PROJECT_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(PROJECT_ROOT))

load_dotenv(PROJECT_ROOT / ".env")

from app.database import Base, get_database_url
from app import models  # noqa: F401 - înregistrează modelele în metadata

# Obiectul de configurație Alembic
config = context.config

# Configurăm logging-ul
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# 3. Setăm Metadata-ul pentru detecția automată (autogenerate)
target_metadata = Base.metadata

# Folosim aceeași configurație de bază de date ca aplicația.
database_url = get_database_url()
config.set_main_option("sqlalchemy.url", str(database_url).replace("%", "%%"))


def run_migrations_offline() -> None:
    """Rulare migrări în mod offline."""
    url = config.get_main_option("sqlalchemy.url")
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )

    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    """Rulare migrări în mod online (conectat la DB)."""
    connectable = engine_from_config(
        config.get_section(config.config_ini_section, {}),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    with connectable.connect() as connection:
        context.configure(
            connection=connection, target_metadata=target_metadata
        )

        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()