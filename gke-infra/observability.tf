resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
      "pod-security.kubernetes.io/audit"   = "privileged"
      "pod-security.kubernetes.io/warn"    = "privileged"
    }
  }
  depends_on = [google_container_cluster.gke_cluster_salus]
}

resource "kubernetes_namespace" "logging" {
  metadata {
    name = "logging"
    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
      "pod-security.kubernetes.io/audit"   = "privileged"
      "pod-security.kubernetes.io/warn"    = "privileged"
    }
  }
  depends_on = [google_container_cluster.gke_cluster_salus]
}

resource "helm_release" "kube_prometheus_stack" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "56.21.4"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  create_namespace = false
  wait             = true
  timeout          = 900

  values = [
    yamlencode({
      prometheus = {
        prometheusSpec = {
          retention = "${var.monitoring_retention_days}d"
          resources = {
            requests = {
              memory = "2Gi"
              cpu    = "1000m"
            }
            limits = {
              memory = "4Gi"
              cpu    = "2000m"
            }
          }
          storageSpec = {
            volumeClaimTemplate = {
              spec = {
                storageClassName = "standard-rwo"
                accessModes      = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = "50Gi"
                  }
                }
              }
            }
          }
          serviceMonitorSelectorNilUsesHelmValues = false
          podMonitorSelectorNilUsesHelmValues     = false
          ruleSelectorNilUsesHelmValues           = false
          replicas                                = 1
          shards                                  = 1
          securityContext = {
            runAsNonRoot = true
            runAsUser    = 65534
            fsGroup      = 65534
          }
        }
        service = {
          type = "ClusterIP"
        }
      }

      grafana = {
        enabled       = true
        adminPassword = "devsecops-demo-${random_password.grafana_password.result}"

        resources = {
          requests = {
            memory = "256Mi"
            cpu    = "200m"
          }
          limits = {
            memory = "512Mi"
            cpu    = "500m"
          }
        }

        persistence = {
          enabled          = true
          size             = "10Gi"
          storageClassName = "standard-rwo"
        }

        service = {
          type = "ClusterIP"
        }

        securityContext = {
          runAsNonRoot = true
          runAsUser    = 472
          fsGroup      = 472
        }

        initChownData = {
          enabled = true
          securityContext = {
            runAsNonRoot = false
            runAsUser    = 0
            capabilities = {
              add  = ["CHOWN"]
              drop = []
            }
          }
        }

        dashboardProviders = {
          "dashboardproviders.yaml" = {
            apiVersion = 1
            providers = [
              {
                name            = "default"
                orgId           = 1
                folder          = ""
                type            = "file"
                disableDeletion = false
                editable        = true
                options = {
                  path = "/var/lib/grafana/dashboards/default"
                }
              }
            ]
          }
        }

        dashboards = {
          default = {
            kubernetes-cluster = {
              gnetId     = 7249
              revision   = 1
              datasource = "Prometheus"
            }
            node-exporter-full = {
              gnetId     = 1860
              revision   = 31
              datasource = "Prometheus"
            }
            kubernetes-pods = {
              gnetId     = 6417
              revision   = 1
              datasource = "Prometheus"
            }
            argocd = {
              gnetId     = 14584
              revision   = 1
              datasource = "Prometheus"
            }
          }
        }

        additionalDataSources = [
          {
            name   = "Loki"
            type   = "loki"
            url    = "http://loki-gateway.logging.svc.cluster.local"
            access = "proxy"
          }
        ]
      }

      alertmanager = {
        alertmanagerSpec = {
          resources = {
            requests = {
              memory = "128Mi"
              cpu    = "100m"
            }
            limits = {
              memory = "256Mi"
              cpu    = "200m"
            }
          }
          storage = {
            volumeClaimTemplate = {
              spec = {
                storageClassName = "standard-rwo"
                accessModes      = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = "5Gi"
                  }
                }
              }
            }
          }
          replicas = 1
          securityContext = {
            runAsNonRoot = true
            runAsUser    = 65534
            fsGroup      = 65534
          }
        }
        config = {
          global = {
            smtp_smarthost = "localhost:587"
            smtp_from      = "alerts@devsecops-demo.com"
          }
          route = {
            group_by        = ["alertname", "cluster", "service"]
            group_wait      = "10s"
            group_interval  = "10s"
            repeat_interval = "12h"
            receiver        = "web.hook"
          }
          receivers = [
            {
              name = "web.hook"
              webhook_configs = [
                {
                  url = "http://localhost:5001/"
                }
              ]
            }
          ]
        }
      }

      nodeExporter = {
        enabled = true
        resources = {
          requests = {
            memory = "32Mi"
            cpu    = "50m"
          }
          limits = {
            memory = "64Mi"
            cpu    = "100m"
          }
        }
      }

      kubeStateMetrics = {
        enabled = true
        resources = {
          requests = {
            memory = "64Mi"
            cpu    = "50m"
          }
          limits = {
            memory = "128Mi"
            cpu    = "100m"
          }
        }
      }

      kubeApiServer = {
        enabled = true
      }
      kubelet = {
        enabled = true
      }
      kubeControllerManager = {
        enabled = true
      }
      coreDns = {
        enabled = true
      }
      kubeEtcd = {
        enabled = true
      }
      kubeScheduler = {
        enabled = true
      }
      kubeProxy = {
        enabled = true
      }
    })
  ]

  depends_on = [kubernetes_namespace.monitoring, google_container_node_pool.primary_nodes]
}

resource "random_password" "grafana_password" {
  length  = 16
  special = true
}

resource "helm_release" "loki" {
  name       = "loki"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki"
  version    = "5.47.2"
  namespace  = kubernetes_namespace.logging.metadata[0].name

  create_namespace = false
  wait             = true
  timeout          = 600

  values = [
    yamlencode({
      deploymentMode = "SingleBinary"

      loki = {
        auth_enabled = false
        commonConfig = {
          replication_factor = 1
        }
        storage = {
          type = "filesystem"
        }
        schemaConfig = {
          configs = [
            {
              from         = "2024-01-01"
              store        = "tsdb"
              object_store = "filesystem"
              schema       = "v13"
              index = {
                prefix = "index_"
                period = "24h"
              }
            }
          ]
        }
        limits_config = {
          retention_period = "${var.monitoring_retention_days}d"
        }
      }

      singleBinary = {
        replicas = 1
        resources = {
          requests = {
            cpu    = "200m"
            memory = "256Mi"
          }
          limits = {
            cpu    = "500m"
            memory = "512Mi"
          }
        }
        persistence = {
          enabled      = true
          size         = "20Gi"
          storageClass = "standard-rwo"
        }
        securityContext = {
          runAsNonRoot = true
          runAsUser    = 10001
          fsGroup      = 10001
        }
      }

      monitoring = {
        serviceMonitor = {
          enabled = true
        }
      }

      gateway = {
        enabled  = true
        replicas = 1
        resources = {
          requests = {
            cpu    = "100m"
            memory = "128Mi"
          }
          limits = {
            cpu    = "200m"
            memory = "256Mi"
          }
        }
      }
    })
  ]

  depends_on = [helm_release.kube_prometheus_stack]
}

resource "helm_release" "fluent_bit" {
  name       = "fluent-bit"
  repository = "https://fluent.github.io/helm-charts"
  chart      = "fluent-bit"
  version    = "0.46.7"
  namespace  = kubernetes_namespace.logging.metadata[0].name

  wait    = true
  timeout = 300

  values = [
    yamlencode({
      config = {
        service = <<-EOF
          [SERVICE]
              Daemon Off
              Flush 1
              Log_Level info
              Parsers_File parsers.conf
              Plugins_File plugins.conf
              HTTP_Server On
              HTTP_Listen 0.0.0.0
              HTTP_Port 2020
              Health_Check On
              storage.metrics on
        EOF

        inputs = <<-EOF
          [INPUT]
              Name tail
              Path /var/log/containers/*.log
              multiline.parser docker, cri
              Tag kube.*
              Mem_Buf_Limit 50MB
              Skip_Long_Lines On
              Refresh_Interval 10
        EOF

        filters = <<-EOF
          [FILTER]
              Name kubernetes
              Match kube.*
              Kube_URL https://kubernetes.default.svc:443
              Kube_CA_File /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
              Kube_Token_File /var/run/secrets/kubernetes.io/serviceaccount/token
              Kube_Tag_Prefix kube.var.log.containers.
              Merge_Log On
              Keep_Log Off
              K8S-Logging.Parser On
              K8S-Logging.Exclude On
              Annotations Off
              Labels On
        EOF

        outputs = <<-EOF
          [OUTPUT]
              Name loki
              Match kube.*
              Host loki-gateway.logging.svc.cluster.local
              Port 80
              Labels job=fluent-bit
              Remove_keys kubernetes,stream
              Line_format json
              Retry_Limit 5
        EOF
      }

      resources = {
        requests = {
          cpu    = "100m"
          memory = "128Mi"
        }
        limits = {
          cpu    = "200m"
          memory = "256Mi"
        }
      }

      securityContext = {
        runAsNonRoot = true
        runAsUser    = 65534
      }

      tolerations = [
        {
          key      = "node-type"
          operator = "Equal"
          value    = "system"
          effect   = "NoSchedule"
        }
      ]
    })
  ]

  depends_on = [helm_release.loki]
}