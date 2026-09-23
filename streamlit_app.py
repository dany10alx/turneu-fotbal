from datetime import datetime

import streamlit as st
from sqlalchemy import select

from app.database import Base, SessionLocal, engine
from app.models import Match, MatchStatus, Team
from app.standings import get_group_standings


Base.metadata.create_all(bind=engine)

st.set_page_config(
    page_title="Turneu fotbal",
    page_icon=":material/sports_soccer:",
    layout="wide",
)


def load_data() -> tuple[list[dict], list[dict], list[str]]:
    with SessionLocal() as session:
        teams = session.scalars(select(Team).order_by(Team.group_name, Team.name)).all()
        matches = session.scalars(select(Match).order_by(Match.scheduled_at.desc())).all()
        team_rows = [
            {"id": team.id, "name": team.name, "group_name": team.group_name or "Fără grupă"}
            for team in teams
        ]
        team_names = {team.id: team.name for team in teams}
        match_rows = [
            {
                "id": match.id,
                "Meci": f"{team_names.get(match.home_team_id, 'Necunoscut')} - "
                f"{team_names.get(match.away_team_id, 'Necunoscut')}",
                "Scor": f"{match.home_score} - {match.away_score}",
                "Status": match.status.value,
                "Grupă": match.group_name or "Fără grupă",
                "Programat": match.scheduled_at.strftime("%d.%m.%Y %H:%M"),
            }
            for match in matches
        ]
        groups = sorted({team["group_name"] for team in team_rows})
        return team_rows, match_rows, groups


def add_team(name: str, group_name: str) -> None:
    with SessionLocal() as session:
        session.add(Team(name=name.strip(), group_name=group_name.strip() or "Grupa A"))
        session.commit()


def add_match(home_id: str, away_id: str, group_name: str, scheduled_at: datetime) -> None:
    with SessionLocal() as session:
        session.add(
            Match(
                home_team_id=home_id,
                away_team_id=away_id,
                group_name=group_name,
                scheduled_at=scheduled_at,
            )
        )
        session.commit()


def update_match(match_id: str, home_score: int, away_score: int, status: MatchStatus) -> None:
    with SessionLocal() as session:
        match = session.get(Match, match_id)
        if match is None:
            return
        match.home_score = home_score
        match.away_score = away_score
        match.status = status
        session.commit()


st.title("Turneu fotbal")
st.caption("Clasamente, echipe și rezultate într-un singur loc")

teams, matches, groups = load_data()

if not groups:
    groups = ["Grupa A"]

with st.sidebar:
    st.header("Filtru")
    selected_group = st.selectbox("Grupă", groups)
    st.divider()
    st.caption("Datele sunt salvate în baza configurată prin `DATABASE_URL`.")

with SessionLocal() as session:
    selected_standings = get_group_standings(session, selected_group)

finished_matches = sum(match["Status"] == MatchStatus.FINISHED.value for match in matches)
live_matches = sum(match["Status"] == MatchStatus.LIVE.value for match in matches)

with st.container(horizontal=True):
    st.metric("Echipe", len(teams), border=True)
    st.metric("Meciuri", len(matches), border=True)
    st.metric("Finalizate", finished_matches, border=True)
    st.metric("În desfășurare", live_matches, border=True)

overview, teams_tab, matches_tab = st.tabs(["Clasament", "Echipe", "Meciuri"])

with overview:
    left, right = st.columns([1.6, 1], gap="large")
    with left:
        st.subheader(f"Clasament {selected_group}")
        st.dataframe(
            selected_standings,
            hide_index=True,
            width="stretch",
            column_config={
                "name": "Echipă",
                "played": "MJ",
                "won": "V",
                "drawn": "E",
                "lost": "Î",
                "gf": "GM",
                "ga": "GP",
                "gd": "GD",
                "points": "Puncte",
            },
        )
    with right:
        st.subheader("Ultimele rezultate")
        group_matches = [match for match in matches if match["Grupă"] == selected_group]
        if group_matches:
            st.dataframe(
                group_matches[:8],
                hide_index=True,
                width="stretch",
                column_config={"id": None},
            )
        else:
            st.info("Nu există încă meciuri în această grupă.")

with teams_tab:
    st.subheader("Echipe înscrise")
    st.dataframe(teams, hide_index=True, width="stretch", column_config={"id": None})
    with st.form("add_team_form", border=True):
        st.markdown("**Adaugă o echipă**")
        team_name = st.text_input("Numele echipei")
        team_group = st.text_input("Grupa", value=selected_group)
        if st.form_submit_button("Adaugă echipa", type="primary"):
            if not team_name.strip():
                st.error("Introdu numele echipei.")
            else:
                add_team(team_name, team_group)
                st.success("Echipa a fost adăugată.")
                st.rerun()

with matches_tab:
    st.subheader("Meciuri")
    st.dataframe(matches, hide_index=True, width="stretch", column_config={"id": None})

    if len(teams) >= 2:
        team_options = {team["name"]: team["id"] for team in teams}
        with st.form("add_match_form", border=True):
            st.markdown("**Programează un meci**")
            home_name = st.selectbox("Echipa gazdă", list(team_options))
            away_name = st.selectbox("Echipa oaspete", list(team_options), index=1)
            match_group = st.text_input("Grupa meciului", value=selected_group)
            match_date = st.date_input("Data meciului")
            match_time = st.time_input("Ora meciului")
            if st.form_submit_button("Programează meciul", type="primary"):
                if home_name == away_name:
                    st.error("Alege două echipe diferite.")
                else:
                    add_match(
                        team_options[home_name],
                        team_options[away_name],
                        match_group,
                        datetime.combine(match_date, match_time),
                    )
                    st.success("Meciul a fost programat.")
                    st.rerun()

    if matches:
        match_options = {match["Meci"]: match["id"] for match in matches}
        with st.form("update_match_form", border=True):
            st.markdown("**Actualizează scorul**")
            selected_match = st.selectbox("Meci", list(match_options))
            score_col1, score_col2, status_col = st.columns(3)
            with score_col1:
                home_score = st.number_input("Goluri gazdă", min_value=0, step=1)
            with score_col2:
                away_score = st.number_input("Goluri oaspete", min_value=0, step=1)
            with status_col:
                match_status = st.selectbox("Status", list(MatchStatus), format_func=lambda item: item.value)
            if st.form_submit_button("Salvează scorul", type="primary"):
                update_match(match_options[selected_match], home_score, away_score, match_status)
                st.success("Scorul a fost actualizat.")
                st.rerun()