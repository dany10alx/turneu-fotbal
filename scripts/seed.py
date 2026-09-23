from app.database import Base, SessionLocal, engine
from app.models import Match, MatchStatus, Team
from app.standings import get_group_standings


def main() -> None:
    Base.metadata.create_all(engine)

    with SessionLocal() as session:
        home_team = Team(name="FC Victoria", group_name="Grupa A")
        away_team = Team(name="CS Real", group_name="Grupa A")
        session.add_all([home_team, away_team])
        session.flush()

        session.add(
            Match(
                home_team_id=home_team.id,
                away_team_id=away_team.id,
                home_score=3,
                away_score=1,
                status=MatchStatus.FINISHED,
                group_name="Grupa A",
            )
        )
        session.commit()

        standings = get_group_standings(session, "Grupa A")
        print(f"{'Echipă':<15} | MJ | V | E | Î | GM | GP | GD | PCT")
        print("-" * 50)
        for row in standings:
            print(
                f"{row['name']:<15} | {row['played']}  | {row['won']} | "
                f"{row['drawn']} | {row['lost']} | {row['gf']}  | "
                f"{row['ga']}  | {row['gd']:<2} | {row['points']}"
            )


if __name__ == "__main__":
    main()
