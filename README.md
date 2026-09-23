# Turneu Fotbal

API REST pentru gestionarea echipelor, meciurilor și clasamentelor unui turneu de fotbal.

## Pornire locală

```powershell
python -m pip install -r requirements.txt
python -m uvicorn app.main:app --reload
```

Aplicația este organizată sub pachetul `app`, iar rularea trebuie făcută din rădăcina proiectului.

Documentația interactivă este disponibilă la `http://127.0.0.1:8000/docs`.

## Dashboard Streamlit

```powershell
streamlit run streamlit_app.py
```

Dashboard-ul este disponibil la `http://localhost:8501` și permite vizualizarea clasamentelor,
adăugarea echipelor, programarea meciurilor și actualizarea scorurilor.

## Publicare backend pe Railway

1. Publică repository-ul pe GitHub și creează un serviciu Railway din repository.
2. Railway va folosi automat `railway.toml` și comanda Uvicorn configurată pentru portul `$PORT`.
3. În Variables adaugă `DATABASE_URL` folosind URL-ul serviciului PostgreSQL Railway.
4. Generează un domeniu public din Settings > Networking.

Verificarea disponibilității se face la `/health`, iar documentația API la `/docs`.

## Structură

- `app/` - codul aplicației FastAPI
- `scripts/` - scripturi utilitare, inclusiv popularea bazei de date
- `tests/` - suite de teste automate
- `tournament.db` - baza SQLite locală pentru dezvoltare
- `.env.example` - exemplu de configurare a bazei de date
- `.venv/` - mediu virtual local, exclus din Git
