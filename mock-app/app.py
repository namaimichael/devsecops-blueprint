from fastapi import FastAPI
import random
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Create FastAPI app
app = FastAPI(
    title="DevSecOps Blueprint API",
    description="Sample API for DevSecOps demonstration",
    version="1.0.0",
)


@app.get("/")
def root():
    """Root endpoint"""
    return {
        "message": "DevSecOps Blueprint API",
        "version": "1.0.0",
        "endpoints": {"health": "/health", "random": "/random", "error": "/error"},
    }


@app.get("/health")
def health_check():
    """Health check endpoint for Kubernetes"""
    return {"status": "ok", "service": "fastapi-app"}


@app.get("/error")
def generate_error():
    """Endpoint to simulate errors for testing"""
    logger.error("Simulated application error occurred!")
    return {"error": "Something went wrong!", "code": 500}


@app.get("/random")
def random_response():
    """Random response for testing"""
    if random.random() > 0.5:
        logger.info("Random success")
        return {"result": "success", "value": random.randint(1, 100)}
    else:
        logger.warning("Random warning triggered")
        return {"result": "warning", "message": "Random warning occurred"}


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
