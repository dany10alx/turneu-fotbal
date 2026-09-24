from fastapi import Depends, FastAPI, HTTPException, status
from sqlalchemy.orm import Session

from .database import Base, SessionLocal, engine
from .models import Match, Team
from .schemas import (
    MatchCreate,
    MatchResponse,
    MatchUpdateScore,
    TeamCreate,
    TeamResponse,
    TeamStanding,
)
from .standings import get_group_standings

Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Football Tournament API",
    description="API REST pentru gestionarea turneului de fotbal",
    version="1.0.0",
)


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@app.post("/teams/", response_model=TeamResponse, status_code=status.HTTP_201_CREATED, tags=["Echipe"])
def create_team(team: TeamCreate, db: Session = Depends(get_db)):
    db_team = Team(name=team.name, group_name=team.group_name)
    db.add(db_team)
    db.commit()
    db.refresh(db_team)
    return db_team


@app.get("/teams/", response_model=list[TeamResponse], tags=["Echipe"])
def get_teams(db: Session = Depends(get_db)):
    return db.query(Team).all()


@app.post("/matches/", response_model=MatchResponse, status_code=status.HTTP_201_CREATED, tags=["Meciuri"])
def create_match(match: MatchCreate, db: Session = Depends(get_db)):
    home_team = db.query(Team).filter(Team.id == match.home_team_id).first()
    away_team = db.query(Team).filter(Team.id == match.away_team_id).first()
    if not home_team or not away_team:
        raise HTTPException(status_code=404, detail="Echipa gazdă sau oaspete nu există.")

    db_match = Match(**match.model_dump())
    db.add(db_match)
    db.commit()
    db.refresh(db_match)
    return db_match


@app.get("/matches/", response_model=list[MatchResponse], tags=["Meciuri"])
def get_matches(db: Session = Depends(get_db)):
    return db.query(Match).all()


@app.put("/matches/{match_id}/score", response_model=MatchResponse, tags=["Meciuri"])
def update_match_score(match_id: str, score_data: MatchUpdateScore, db: Session = Depends(get_db)):
    db_match = db.query(Match).filter(Match.id == match_id).first()
    if not db_match:
        raise HTTPException(status_code=404, detail="Meciul nu a fost găsit.")

    db_match.home_score = score_data.home_score
    db_match.away_score = score_data.away_score
    db_match.status = score_data.status
    db.commit()
    db.refresh(db_match)
    return db_match


@app.get("/standings/{group_name}", response_model=list[TeamStanding], tags=["Clasament"])
def read_group_standings(group_name: str, db: Session = Depends(get_db)):
    return get_group_standings(db, group_name)
