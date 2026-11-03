import pytest

from app.api.endpoints import locations as locations_module
from app.external_apis.google_places import GooglePlacesClient


def test_distance_is_haversine_metres():
    # KLCC to KL Sentral: 2.62 km north-south and 2.78 km east-west, about 3.8 km apart
    assert 3780 < locations_module.distance_m(3.1579, 101.7116, 3.1343, 101.6866) < 3860
    assert locations_module.distance_m(3.0, 101.0, 3.0, 101.0) == 0


def test_nearby_sorts_by_distance(client, monkeypatch):
    async def fake_nearby(lat, lon, radius):
        return [
            {"id": "far", "name": "Far", "location": {"lat": 3.20, "lng": 101.70}},
            {"id": "near", "name": "Near", "location": {"lat": 3.1580, "lng": 101.7117}},
            {"id": "nowhere", "name": "No geometry"},
        ]

    monkeypatch.setattr(locations_module.location_service, "get_nearby_places", fake_nearby)
    body = client.get("/api/v1/locations/nearby?lat=3.1579&lon=101.7116").json()
    assert [p["id"] for p in body["places"]] == ["near", "far", "nowhere"]
    assert body["places"][0]["distance_m"] < 50


def test_nearby_reports_provider_outage_without_fabricating(client, monkeypatch):
    async def boom(*_):
        raise RuntimeError("quota")

    monkeypatch.setattr(locations_module.location_service, "get_nearby_places", boom)
    body = client.get("/api/v1/locations/nearby?lat=3.15&lon=101.71").json()
    assert body["places"] == [] and body["error"] == "provider_unavailable"


def test_nearby_validates_coordinates(client):
    assert client.get("/api/v1/locations/nearby?lat=95&lon=101").status_code == 422


@pytest.mark.parametrize("error,status", [("Place details not found", 404), ("Rate limit exceeded", 503)])
def test_place_details_errors(client, monkeypatch, error, status):
    async def fake(place_id):
        return {"error": error}

    monkeypatch.setattr(locations_module.location_service, "get_place_details", fake)
    assert client.get("/api/v1/locations/places/abc").status_code == status


def test_place_details_never_leak_the_api_key():
    client = GooglePlacesClient.__new__(GooglePlacesClient)
    client.api_key = "SECRET-KEY"
    details = client._process_place_details({
        "name": "Atelier", "photos": [{"photo_reference": "r1"}], "opening_hours": {"weekday_text": ["Monday: Closed"]},
    })
    assert "SECRET-KEY" not in repr(details)
    assert details["photo_count"] == 1 and details["opening_hours"] == ["Monday: Closed"]
