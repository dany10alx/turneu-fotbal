"""
Logica fazei eliminatorii (knockout).

Reguli de calificare (după numărul de grupe):
  2 grupe -> semifinale -> finală      (tablou de 4)
  3 grupe -> sferturi -> ... -> finală (tablou de 8)
  4 grupe -> sferturi -> ... -> finală (tablou de 8)
  5-7 grupe -> optimi -> ... -> finală (tablou de 16)
  8 grupe -> optimi -> ... -> finală   (tablou de 16)

Din fiecare grupă se califică garantat locurile 1 și 2. Dacă tabloul are
locuri rămase libere, ele se completează cu cele mai bune echipe de pe
locul 3 (după puncte, apoi golaveraj, apoi goluri marcate), apoi cu cele
mai bune de pe locul 4 dacă tot mai e nevoie.
"""

from sqlalchemy.orm import Session

from .models import Match, MatchStatus, Team

ROUND_ORDER = ["round_of_16", "quarterfinal", "semifinal", "final"]

ROUND_DISPLAY_NAMES = {
    "round_of_16": "Optimi de finală",
    "quarterfinal": "Sferturi de finală",
    "semifinal": "Semifinale",
    "final": "Finală",
}

# Numărul de grupe -> mărimea tabloului (câte echipe intră în prima rundă).
BRACKET_SIZE_BY_GROUPS = {2: 4, 3: 8, 4: 8, 5: 16, 6: 16, 7: 16, 8: 16}


def _start_round_for_bracket_size(bracket_size: int) -> str:
    return {4: "semifinal", 8: "quarterfinal", 16: "round_of_16"}[bracket_size]


def _group_standings_with_id(db: Session, group_name: str) -> list[dict]:
    """Calculează clasamentul unei grupe, păstrând și obiectul Team (cu id),
    nu doar numele — necesar pentru a crea meciurile eliminatorii."""
    teams = db.query(Team).filter(Team.group_name == group_name).all()
    stats = {
        t.id: {"team": t, "played": 0, "won": 0, "drawn": 0, "lost": 0, "gf": 0, "ga": 0, "points": 0}
        for t in teams
    }

    matches = (
        db.query(Match)
        .filter(Match.group_name == group_name, Match.status == MatchStatus.FINISHED)
        .all()
    )
    for m in matches:
        home = stats.get(m.home_team_id)
        away = stats.get(m.away_team_id)
        if not home or not away:
            continue
        home["played"] += 1
        away["played"] += 1
        home["gf"] += m.home_score
        home["ga"] += m.away_score
        away["gf"] += m.away_score
        away["ga"] += m.home_score
        if m.home_score > m.away_score:
            home["won"] += 1
            home["points"] += 3
            away["lost"] += 1
        elif m.away_score > m.home_score:
            away["won"] += 1
            away["points"] += 3
            home["lost"] += 1
        else:
            home["drawn"] += 1
            away["drawn"] += 1
            home["points"] += 1
            away["points"] += 1

    return sorted(
        stats.values(),
        key=lambda s: (-s["points"], -(s["gf"] - s["ga"]), -s["gf"]),
    )


def generate_bracket(db: Session) -> list[Match]:
    """Generează prima rundă a fazei eliminatorii, pe baza clasamentelor
    curente din grupe. Ridică ValueError cu un mesaj clar dacă numărul de
    grupe nu e suportat sau nu sunt suficiente echipe."""

    all_teams = db.query(Team).all()
    group_names = sorted({t.group_name for t in all_teams if t.group_name})
    num_groups = len(group_names)

    if num_groups not in BRACKET_SIZE_BY_GROUPS:
        raise ValueError(
            f"Faza eliminatorie e definită doar pentru 2-8 grupe (ai {num_groups} grupe)."
        )

    bracket_size = BRACKET_SIZE_BY_GROUPS[num_groups]
    start_round = _start_round_for_bracket_size(bracket_size)

    # Dacă a mai fost generată o dată, nu suprapunem peste ea.
    existing = db.query(Match).filter(Match.round.isnot(None)).first()
    if existing:
        raise ValueError(
            "Faza eliminatorie a fost deja generată. Șterge-o mai întâi dacă vrei să o regenerezi."
        )

    rankings = {g: _group_standings_with_id(db, g) for g in group_names}

    winners = [ranked[0] for ranked in rankings.values() if len(ranked) > 0]
    runners_up = [ranked[1] for ranked in rankings.values() if len(ranked) > 1]

    def sort_key(entry):
        return (-entry["points"], -(entry["gf"] - entry["ga"]), -entry["gf"])

    winners.sort(key=sort_key)
    runners_up.sort(key=sort_key)
    guaranteed = winners + runners_up

    # Pool de rezervă: locurile 3, 4, 5... din fiecare grupă, ca să
    # completăm eventualele locuri rămase libere în tablou.
    pool = []
    for ranked in rankings.values():
        for idx, entry in enumerate(ranked):
            if idx >= 2:
                pool.append((idx, entry))
    pool.sort(key=lambda pair: (pair[0], *sort_key(pair[1])))

    needed_extra = bracket_size - len(guaranteed)
    if needed_extra < 0:
        raise ValueError("Prea multe echipe calificate direct pentru mărimea tabloului.")
    if needed_extra > len(pool):
        raise ValueError(
            "Nu sunt suficiente echipe în total pentru a completa tabloul eliminatoriu "
            f"({bracket_size} necesare)."
        )

    wildcards = [entry for _, entry in pool[:needed_extra]]
    seed_order = guaranteed + wildcards  # cel mai bun -> cel mai slab

    # Aranjăm perechile: cel mai bun contra celui mai slab (sămânța 1 vs
    # ultima sămânță, sămânța 2 vs penultima etc.), o metodă standard care
    # ține echipele puternice separate cât mai mult timp posibil.
    new_matches = []
    num_matches = bracket_size // 2
    for i in range(num_matches):
        home_entry = seed_order[i]
        away_entry = seed_order[bracket_size - 1 - i]
        new_matches.append(
            Match(
                home_team_id=home_entry["team"].id,
                away_team_id=away_entry["team"].id,
                group_name=None,
                status=MatchStatus.SCHEDULED,
                round=start_round,
                bracket_slot=i,
            )
        )

    db.add_all(new_matches)
    db.commit()
    for m in new_matches:
        db.refresh(m)
    return new_matches


def advance_bracket(db: Session, finished_match: Match) -> Match | None:
    """Apelată după ce se salvează scorul unui meci din faza eliminatorie.
    Dacă și meciul-pereche din aceeași rundă s-a încheiat, creează automat
    meciul din runda următoare cu cei doi câștigători. Returnează meciul
    nou creat, sau None dacă nu e încă momentul."""

    if not finished_match.round:
        return None  # meci de grupă, nu ne privește aici

    current_round = finished_match.round
    if current_round == "final":
        return None  # nu mai există rundă următoare

    next_round = ROUND_ORDER[ROUND_ORDER.index(current_round) + 1]

    sibling_slot = finished_match.bracket_slot ^ 1  # perechea: 0<->1, 2<->3...
    sibling = (
        db.query(Match)
        .filter(Match.round == current_round, Match.bracket_slot == sibling_slot)
        .first()
    )
    if not sibling or sibling.status != MatchStatus.FINISHED:
        return None  # așteptăm și celălalt meci din pereche

    def winner_id(m: Match) -> str | None:
        if m.home_score > m.away_score:
            return m.home_team_id
        if m.away_score > m.home_score:
            return m.away_team_id
        return None  # egalitate — faza eliminatorie are nevoie de un câștigător

    lower = finished_match if finished_match.bracket_slot % 2 == 0 else sibling
    higher = sibling if finished_match.bracket_slot % 2 == 0 else finished_match

    home_winner = winner_id(lower)
    away_winner = winner_id(higher)
    if home_winner is None or away_winner is None:
        # Egalitate nedecisă (fără penalty-uri implementate) — nu putem
        # avansa automat. Meciul rămâne cu scorul de egalitate până e
        # corectat manual cu un rezultat decisiv.
        return None

    next_slot = finished_match.bracket_slot // 2
    already_exists = (
        db.query(Match)
        .filter(Match.round == next_round, Match.bracket_slot == next_slot)
        .first()
    )
    if already_exists:
        return None

    next_match = Match(
        home_team_id=home_winner,
        away_team_id=away_winner,
        group_name=None,
        status=MatchStatus.SCHEDULED,
        round=next_round,
        bracket_slot=next_slot,
    )
    db.add(next_match)
    db.commit()
    db.refresh(next_match)
    return next_match
