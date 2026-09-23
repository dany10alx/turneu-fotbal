from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict

from .models import MatchStatus


class TeamCreate(BaseModel):
    name: str
    group_name: Optional[str] = "Grupa A"


class TeamResponse(TeamCreate):
    id: str
    model_config = ConfigDict(from_attributes=True)


class MatchCreate(BaseModel):
    home_team_id: str
    away_team_id: str
    scheduled_at: Optional[datetime] = None
    group_name: str


class MatchUpdateScore(BaseModel):
    home_score: int
    away_score: int
    status: MatchStatus = MatchStatus.FINISHED


class MatchResponse(BaseModel):
    id: str
    home_team_id: str
    away_team_id: str
    home_score: int
    away_score: int
    status: MatchStatus
    group_name: Optional[str]
    model_config = ConfigDict(from_attributes=True)


class TeamStanding(BaseModel):
    name: str
    played: int
    won: int
    drawn: int
    lost: int
    gf: int
    ga: int
    gd: int
    points: int
