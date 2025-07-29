"""
FastAPI application with simplified observability
- Prometheus metrics with custom business metrics
- Structured logging with correlation IDs
- Health checks and readiness probes
- Request tracking and error monitoring
"""

import logging
import time
import random
import uuid
import asyncio
from typing import Dict, Any, Optional
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from prometheus_client import (
    Counter,
    Histogram,
    Gauge,
    generate_latest,
    CONTENT_TYPE_LATEST,
    REGISTRY,
)
from prometheus_fastapi_instrumentator import Instrumentator
import structlog
import uvicorn


# =====================================================
# Observability Configuration
# =====================================================

# Clear any existing metrics to avoid conflicts
REGISTRY._collector_to_names.clear()
REGISTRY._names_to_collectors.clear()

# Structured Logging Setup
structlog.configure(
    processors=[
        structlog.stdlib.filter_by_level,
        structlog.stdlib.add_logger_name,
        structlog.stdlib.add_log_level,
        structlog.stdlib.PositionalArgumentsFormatter(),
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.StackInfoRenderer(),
        structlog.processors.format_exc_info,
        structlog.processors.UnicodeDecoder(),
        structlog.processors.JSONRenderer(),
    ],
    context_class=dict,
    logger_factory=structlog.stdlib.LoggerFactory(),
    wrapper_class=structlog.stdlib.BoundLogger,
    cache_logger_on_first_use=True,
)

logger = structlog.get_logger()

# Custom Prometheus Metrics
BUSINESS_OPERATIONS = Counter(
    "business_operations_total",
    "Total business operations performed",
    ["operation", "status", "user_type"],
)

API_REQUEST_DURATION = Histogram(
    "api_request_duration_seconds",
    "API request duration in seconds",
    ["method", "endpoint", "status_code"],
)

ACTIVE_CONNECTIONS = Gauge(
    "active_connections_current", "Current number of active connections"
)

ERROR_RATE = Counter(
    "application_errors_total",
    "Total application errors by type",
    ["error_type", "severity", "component"],
)

# SLI Metrics
SLI_REQUEST_SUCCESS = Counter(
    "sli_requests_total", "Total requests for SLI calculation", ["endpoint", "status"]
)

SLI_LATENCY_HISTOGRAM = Histogram(
    "sli_request_duration_seconds", "Request duration for SLI calculation", ["endpoint"]
)

# Application State
app_state = {
    "startup_time": time.time(),
    "total_requests": 0,
    "error_count": 0,
    "health_status": "healthy",
    "version": "1.0.0",
    "environment": "production",
}


# =====================================================
# Utility Functions
# =====================================================


def get_correlation_id() -> str:
    """Generate or retrieve correlation ID for request tracing"""
    return str(uuid.uuid4())


def get_request_context(request: Request) -> Dict[str, Any]:
    """Extract request context for logging"""
    return {
        "correlation_id": getattr(
            request.state, "correlation_id", get_correlation_id()
        ),
        "method": request.method,
        "path": request.url.path,
        "user_agent": request.headers.get("user-agent", "unknown"),
        "client_ip": request.client.host if request.client else "unknown",
    }


# =====================================================
# Application Lifecycle
# =====================================================


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan manager with observability"""
    # Startup
    startup_time = time.time()
    app_state["startup_time"] = startup_time

    logger.info(
        "FastAPI application starting up",
        app_name="devsecops-blueprint-api",
        version=app_state["version"],
        environment=app_state["environment"],
    )

    yield

    # Shutdown
    shutdown_time = time.time()
    uptime = shutdown_time - startup_time

    logger.info(
        "FastAPI application shutting down",
        uptime_seconds=uptime,
        total_requests=app_state["total_requests"],
        total_errors=app_state["error_count"],
    )


# =====================================================
# FastAPI Application Setup
# =====================================================

app = FastAPI(
    title="DevSecOps Blueprint API",
    description="Production-ready API with comprehensive observability",
    version="1.0.0",
    lifespan=lifespan,
)

# CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Prometheus Instrumentation
instrumentator = Instrumentator()
instrumentator.instrument(app).expose(app)


# =====================================================
# Middleware
# =====================================================


@app.middleware("http")
async def observability_middleware(request: Request, call_next):
    """Comprehensive observability middleware"""
    start_time = time.time()
    correlation_id = get_correlation_id()
    request.state.correlation_id = correlation_id

    # Increment active connections
    ACTIVE_CONNECTIONS.inc()
    app_state["total_requests"] += 1

    try:
        response = await call_next(request)

        # Calculate duration
        duration = time.time() - start_time

        # Record metrics
        API_REQUEST_DURATION.labels(
            method=request.method,
            endpoint=request.url.path,
            status_code=response.status_code,
        ).observe(duration)

        # SLI Metrics
        status = "success" if response.status_code < 400 else "error"
        SLI_REQUEST_SUCCESS.labels(endpoint=request.url.path, status=status).inc()

        SLI_LATENCY_HISTOGRAM.labels(endpoint=request.url.path).observe(duration)

        # Structured logging
        log_data = {
            **get_request_context(request),
            "status_code": response.status_code,
            "duration_ms": round(duration * 1000, 2),
            "response_size": response.headers.get("content-length", 0),
        }

        if response.status_code >= 400:
            logger.warning("HTTP request completed with error", **log_data)
            ERROR_RATE.labels(
                error_type="http_error",
                severity="warning" if response.status_code < 500 else "error",
                component="api",
            ).inc()
            app_state["error_count"] += 1
        else:
            logger.info("HTTP request completed successfully", **log_data)

        return response

    except Exception as e:
        duration = time.time() - start_time

        # Record error metrics
        ERROR_RATE.labels(
            error_type="exception", severity="error", component="api"
        ).inc()
        app_state["error_count"] += 1

        # Log error with context
        logger.error(
            "HTTP request failed with exception",
            **get_request_context(request),
            duration_ms=round(duration * 1000, 2),
            error=str(e),
            error_type=type(e).__name__,
        )

        raise

    finally:
        # Decrement active connections
        ACTIVE_CONNECTIONS.dec()


# =====================================================
# Health & Monitoring Endpoints
# =====================================================


@app.get("/health")
async def health_check(request: Request):
    """Kubernetes health check with detailed status"""
    context = get_request_context(request)

    health_data = {
        "status": app_state["health_status"],
        "timestamp": time.time(),
        "uptime_seconds": time.time() - app_state["startup_time"],
        "version": app_state["version"],
        "environment": app_state["environment"],
        "correlation_id": context["correlation_id"],
    }

    logger.info("Health check performed", **context, **health_data)
    return health_data


@app.get("/ready")
async def readiness_check(request: Request):
    """Kubernetes readiness check with dependency validation"""
    context = get_request_context(request)

    # Simulate dependency checks
    checks = {
        "database": "healthy",
        "external_apis": "healthy",
        "memory": "healthy",
        "disk": "healthy",
    }

    is_ready = all(status == "healthy" for status in checks.values())

    if not is_ready:
        logger.warning("Readiness check failed", **context, checks=checks)
        raise HTTPException(status_code=503, detail="Service not ready")

    readiness_data = {
        "status": "ready",
        "timestamp": time.time(),
        "checks": checks,
        "correlation_id": context["correlation_id"],
    }

    logger.info("Readiness check passed", **context, **readiness_data)
    return readiness_data


@app.get("/metrics")
async def metrics_endpoint():
    """Prometheus metrics endpoint"""
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)


@app.get("/info")
async def app_info(request: Request):
    """Application information with observability details"""
    context = get_request_context(request)

    info_data = {
        "application": "DevSecOps Blueprint API",
        "version": app_state["version"],
        "environment": app_state["environment"],
        "startup_time": app_state["startup_time"],
        "uptime_seconds": time.time() - app_state["startup_time"],
        "total_requests": app_state["total_requests"],
        "error_count": app_state["error_count"],
        "observability": {
            "metrics": "/metrics",
            "health": "/health",
            "readiness": "/ready",
            "logging": "structured",
            "correlation_tracking": "enabled",
        },
        "correlation_id": context["correlation_id"],
    }

    logger.info("Application info requested", **context, **info_data)
    return info_data


# =====================================================
# Business Logic Endpoints with Observability
# =====================================================


@app.get("/")
async def root(request: Request):
    """Root endpoint with comprehensive observability"""
    context = get_request_context(request)

    BUSINESS_OPERATIONS.labels(
        operation="root_access", status="success", user_type="anonymous"
    ).inc()

    response_data = {
        "message": "DevSecOps Blueprint API",
        "version": app_state["version"],
        "endpoints": {
            "health": "/health",
            "readiness": "/ready",
            "metrics": "/metrics",
            "info": "/info",
            "data": "/api/v1/data",
            "process": "/api/v1/process",
        },
        "observability": {
            "metrics_enabled": True,
            "structured_logging": True,
            "correlation_tracking": True,
        },
        "correlation_id": context["correlation_id"],
    }

    logger.info("Root endpoint accessed", **context, **response_data)
    return response_data


@app.get("/api/v1/data")
async def get_data(request: Request, user_type: str = "anonymous"):
    """Enhanced data endpoint with business metrics"""
    context = get_request_context(request)

    # Simulate processing time
    processing_time = random.uniform(0.1, 0.5)
    await asyncio.sleep(processing_time)

    # Simulate occasional errors (5% chance)
    if random.random() < 0.05:
        ERROR_RATE.labels(
            error_type="data_fetch_error", severity="error", component="business_logic"
        ).inc()

        BUSINESS_OPERATIONS.labels(
            operation="data_fetch", status="error", user_type=user_type
        ).inc()

        logger.error(
            "Data fetch error occurred",
            **context,
            operation="get_data",
            processing_time_ms=processing_time * 1000,
            user_type=user_type,
            error_rate=0.05,
        )

        raise HTTPException(
            status_code=500, detail="Internal server error during data fetch"
        )

    # Success case
    BUSINESS_OPERATIONS.labels(
        operation="data_fetch", status="success", user_type=user_type
    ).inc()

    data_id = random.randint(1, 1000)
    data_value = round(random.uniform(10, 100), 2)

    response_data = {
        "id": data_id,
        "value": data_value,
        "timestamp": time.time(),
        "processing_time_ms": round(processing_time * 1000, 2),
        "status": "success",
        "user_type": user_type,
        "correlation_id": context["correlation_id"],
    }

    logger.info("Data retrieved successfully", **context, **response_data)

    return response_data


@app.post("/api/v1/process")
async def process_data(data: Dict[str, Any], request: Request):
    """Data processing endpoint with comprehensive observability"""
    context = get_request_context(request)

    # Simulate processing
    processing_time = random.uniform(0.2, 1.0)
    await asyncio.sleep(processing_time)

    # Simulate different processing outcomes
    outcome = random.choices(
        ["success", "warning", "error"], weights=[0.85, 0.10, 0.05], k=1
    )[0]

    if outcome == "error":
        ERROR_RATE.labels(
            error_type="processing_error", severity="error", component="business_logic"
        ).inc()

        BUSINESS_OPERATIONS.labels(
            operation="data_process", status="error", user_type="authenticated"
        ).inc()

        logger.error(
            "Data processing failed",
            **context,
            operation="process_data",
            input_data=data,
            processing_time_ms=processing_time * 1000,
            outcome=outcome,
        )

        raise HTTPException(status_code=422, detail="Data processing failed")

    # Success/Warning cases
    BUSINESS_OPERATIONS.labels(
        operation="data_process", status=outcome, user_type="authenticated"
    ).inc()

    warnings = ["Processing completed with warnings"] if outcome == "warning" else []

    result = {
        "processed_data": data,
        "outcome": outcome,
        "processing_time_ms": round(processing_time * 1000, 2),
        "timestamp": time.time(),
        "warnings": warnings,
        "correlation_id": context["correlation_id"],
    }

    log_level = logger.warning if outcome == "warning" else logger.info
    log_level("Data processed successfully", **context, **result)

    return result


# =====================================================
# Admin/Debug Endpoints
# =====================================================


@app.post("/admin/health/{status}")
async def set_health_status(status: str, request: Request):
    """Admin endpoint to control health status"""
    context = get_request_context(request)

    if status not in ["healthy", "unhealthy"]:
        raise HTTPException(status_code=400, detail="Invalid status")

    old_status = app_state["health_status"]
    app_state["health_status"] = status

    logger.info(
        "Health status changed",
        **context,
        old_status=old_status,
        new_status=status,
        admin_action=True,
    )

    return {
        "message": f"Health status changed from {old_status} to {status}",
        "correlation_id": context["correlation_id"],
    }


@app.get("/debug/error")
async def trigger_error(request: Request):
    """Debug endpoint to trigger an error for testing"""
    context = get_request_context(request)

    ERROR_RATE.labels(
        error_type="debug_error", severity="error", component="debug"
    ).inc()

    logger.error("Debug error triggered intentionally", **context, debug_action=True)
    raise HTTPException(status_code=500, detail="Debug error triggered")


# =====================================================
# Application Runner
# =====================================================

if __name__ == "__main__":
    uvicorn.run("app:app", host="0.0.0.0", port=8000, log_level="info")
