#!/usr/bin/env bash

echo "[Deploying mock app container locally]"
docker build -t mock-app:latest -f infra/docker/Dockerfile .
docker run -d -p 8000:8000 --name mock-app mock-app:latest
echo "App running at http://localhost:8000/health"