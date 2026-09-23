from sqlalchemy import select

from .models import Match, MatchStatus, Team


def get_group_standings(session, group_name: str):
    teams = session.scalars(select(Team).where(Team.group_name == group_name)).all()
    stats = {
        team.id: {
            "name": team.name,
            "played": 0,
            "won": 0,
            "drawn": 0,
            "lost": 0,
            "gf": 0,
            "ga": 0,
            "gd": 0,
            "points": 0,
        }
        for team in teams
    }

    finished_matches = session.scalars(
        select(Match).where(
            Match.group_name == group_name,
            Match.status == MatchStatus.FINISHED,
        )
    ).all()

    for match in finished_matches:
        home_stats = stats.get(match.home_team_id)
        away_stats = stats.get(match.away_team_id)
        if home_stats is None or away_stats is None:
            continue

        home_stats["played"] += 1
        away_stats["played"] += 1
        home_stats["gf"] += match.home_score
        home_stats["ga"] += match.away_score
        away_stats["gf"] += match.away_score
        away_stats["ga"] += match.home_score

        if match.home_score > match.away_score:
            home_stats["won"] += 1
            home_stats["points"] += 3
            away_stats["lost"] += 1
        elif match.away_score > match.home_score:
            away_stats["won"] += 1
            away_stats["points"] += 3
            home_stats["lost"] += 1
        else:
            home_stats["drawn"] += 1
            away_stats["drawn"] += 1
            home_stats["points"] += 1
            away_stats["points"] += 1

    for data in stats.values():
        data["gd"] = data["gf"] - data["ga"]

    return sorted(
        stats.values(),
        key=lambda item: (item["points"], item["gd"], item["gf"]),
        reverse=True,
    )
