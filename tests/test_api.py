def test_create_team(client):
    response = client.post(
        "/teams/",
        json={"name": "FC Test", "group_name": "Grupa A"},
    )
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "FC Test"
    assert "id" in data


def test_read_standings(client):
    response = client.get("/standings/Grupa A")
    assert response.status_code == 200
    assert isinstance(response.json(), list)