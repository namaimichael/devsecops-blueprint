from fastapi.testclient import TestClient
from app import app

# Create TestClient instance
client = TestClient(app)


def test_health_check():
    """Test the health check endpoint"""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert "status" in data
    assert data["status"] == "ok"


def test_root_endpoint():
    """Test the root endpoint"""
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert "message" in data


def test_random_endpoint():
    """Test the random endpoint"""
    response = client.get("/random")
    assert response.status_code == 200
    data = response.json()
    assert "result" in data
    assert data["result"] in ["success", "warning"]


def test_error_endpoint():
    """Test the error endpoint"""
    response = client.get("/error")
    assert response.status_code == 200
    data = response.json()
    assert "error" in data