# =====================================================
# FastAPI Application Monitoring
# =====================================================

# ServiceMonitor for FastAPI app metrics
  
resource "kubernetes_manifest" "fastapi_service_monitor" {
  count = 0
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "fastapi-app"
      namespace = "default"
      labels = {
        app = "fastapi-app"
      }
    }
    spec = {
      selector = {
        matchLabels = {
          app = "fastapi-app"
        }
      }
      endpoints = [
        {
          port          = "http"
          path          = "/metrics"
          interval      = "30s"
          scrapeTimeout = "10s"
        }
      ]
    }
  }

  depends_on = [helm_release.kube_prometheus_stack]
}

# PrometheusRule for FastAPI SLI/SLO alerts
resource "kubernetes_manifest" "fastapi_prometheus_rules" {
  count = 0
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "PrometheusRule"
    metadata = {
      name      = "fastapi-slo-rules"
      namespace = "default"
      labels = {
        app        = "fastapi-app"
        prometheus = "kube-prometheus"
        role       = "alert-rules"
      }
    }
    spec = {
      groups = [
        {
          name = "fastapi.slo.rules"
          rules = [
            # SLI: Availability (Success Rate)
            {
              record = "fastapi:sli_availability"
              expr   = "rate(sli_requests_total{status=\"success\"}[5m]) / rate(sli_requests_total[5m])"
              labels = {
                service = "fastapi-app"
              }
            },
            # SLI: Latency (95th percentile)
            {
              record = "fastapi:sli_latency_p95"
              expr   = "histogram_quantile(0.95, rate(sli_request_duration_seconds_bucket[5m]))"
              labels = {
                service = "fastapi-app"
              }
            },
            # SLO Alert: Availability below 99%
            {
              alert = "FastAPIAvailabilitySLOViolation"
              expr  = "fastapi:sli_availability < 0.99"
              for   = "2m"
              labels = {
                severity = "critical"
                service  = "fastapi-app"
                slo      = "availability"
              }
              annotations = {
                summary     = "FastAPI availability SLO violation"
                description = "FastAPI availability is {{ $value | humanizePercentage }} (below 99% SLO)"
                runbook_url = "https://wiki.company.com/runbooks/fastapi-availability"
              }
            },
            # SLO Alert: Latency above 500ms
            {
              alert = "FastAPILatencySLOViolation"
              expr  = "fastapi:sli_latency_p95 > 0.5"
              for   = "2m"
              labels = {
                severity = "warning"
                service  = "fastapi-app"
                slo      = "latency"
              }
              annotations = {
                summary     = "FastAPI latency SLO violation"
                description = "FastAPI 95th percentile latency is {{ $value }}s (above 500ms SLO)"
                runbook_url = "https://wiki.company.com/runbooks/fastapi-latency"
              }
            },
            # Alert: High Error Rate
            {
              alert = "FastAPIHighErrorRate"
              expr  = "rate(application_errors_total[5m]) > 0.1"
              for   = "1m"
              labels = {
                severity = "warning"
                service  = "fastapi-app"
              }
              annotations = {
                summary     = "FastAPI application has high error rate"
                description = "Error rate is {{ $value }} errors/second"
              }
            },
            # Alert: Business Operations Failure
            {
              alert = "FastAPIBusinessOperationFailure"
              expr  = "rate(business_operations_total{status=\"error\"}[5m]) > 0.05"
              for   = "2m"
              labels = {
                severity = "warning"
                service  = "fastapi-app"
              }
              annotations = {
                summary     = "FastAPI business operations failing"
                description = "Business operation failure rate is {{ $value }} failures/second"
              }
            },
            # Alert: Service Down
            {
              alert = "FastAPIDown"
              expr  = "up{job=\"fastapi-app\"} == 0"
              for   = "1m"
              labels = {
                severity = "critical"
                service  = "fastapi-app"
              }
              annotations = {
                summary     = "FastAPI application is down"
                description = "FastAPI application has been down for more than 1 minute"
                runbook_url = "https://wiki.company.com/runbooks/fastapi-down"
              }
            }
          ]
        }
      ]
    }
  }

  depends_on = [helm_release.kube_prometheus_stack]
}