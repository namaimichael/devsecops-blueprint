from fastapi import FastAPI
import random
import logging

app = FastAPI()

logging.basicConfig(level=logging.INFO)

@app.get("/health")
def health_check():
    return {"status": "ok"}

@app.get("/error")
def generate_error():
    logging.error("Simulated application error occurred!")
    return {"error": "Something went wrong!"}

@app.get("/random")
def random_response():
    if random.random() > 0.5:
        logging.info("Random success")
        return {"result": "success"}
    else:
        logging.warning("Random warning triggered")
        return {"result": "warning"}