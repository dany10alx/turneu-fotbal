def test_group_standings_returns_sorted_rows(client):
    response = client.get("/standings/Grupa A")
    assert response.status_code == 200
    standings = response.json()
    assert isinstance(standings, list)
    assert standings == sorted(
        standings,
        key=lambda item: (-item["points"], -item["gd"], -item["gf"]),
    )
