# Mock FastAPI Application

A sample FastAPI service instrumented with observability and CI/CD readiness.

---

## Purpose
- Demonstrate custom Prometheus metrics and structured logging  
- Validate CI/CD security scans and automated deployment

## Prerequisites
- Docker installed  
- Python 3.11+ (for local testing)  
- Dependencies defined in `requirements.txt`

## Usage

**Build and Run with Docker**
```bash
cd mock-app
docker build -t mock-app:latest .
docker run -d -p 8000:8000 --name mock-app mock-app:latest

cd mock-app
pip install -r requirements.txt
uvicorn app:app --host 0.0.0.0 --port 8000

cd mock-app
pytest --cov=.