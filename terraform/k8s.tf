resource "kubernetes_namespace" "tbot_attestation" {
  metadata {
    name = "tbot-attestation"
  }
}

resource "kubernetes_service_account" "tbot_attestation" {
  metadata {
    name = "tbot-attestation"
    namespace = kubernetes_namespace.tbot_attestation.metadata.0.name
  }
}

resource "kubernetes_cluster_role" "tbot_attestation" {
  metadata {
    name = "tbot-attestation"
  }

  rule {
    api_groups = [""]
    resources = ["pods", "nodes", "nodes/proxy"]
    verbs = ["get"]
  }
}

resource "kubernetes_cluster_role_binding" "workload_id_demo" {
  metadata {
    name = "tbot-attestation"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind = "ClusterRole"
    name = kubernetes_cluster_role.tbot_attestation.metadata.0.name
  }

  subject {
    kind = "ServiceAccount"
    name = kubernetes_service_account.tbot_attestation.metadata.0.name
    namespace = kubernetes_namespace.tbot_attestation.metadata.0.name
  }
}

resource "kubernetes_config_map" "tbot_attestation" {
  metadata {
    name = "tbot-attestation"
    namespace = kubernetes_namespace.tbot_attestation.metadata.0.name
  }

  data = {
    "tbot.yaml" = yamlencode({
    version = "v2"
    onboarding = {
      join_method = "kubernetes"
      token = "workload-id-demo-k8s-attestation-bot"
    }
    storage = {
      type = "memory"
    }
    proxy_server = "teleport-17-ent.asteroid.earth:443"
    services = [
      {
        type = "spiffe-workload-api"
        listen = "unix:///run/tbot/sockets/demo-backend-2.sock"
        attestors = {
          kubernetes = {
            enabled = true
            kubelet = {
              skip_verify = true
            }
          }
        }
        svids = [
          {
            path = "/workload-id-demo/demo-backend-2"
            rules = [{
              kubernetes = {
                namespace = "workload-id-demo"
                service_account = "demo-backend-2"
              }
            }]
          }
        ]
      }
    ]
    })
  }
}

resource "kubernetes_daemonset" "tbot_attestation" {
  metadata {
    name = "tbot-attestation"
    namespace = kubernetes_namespace.tbot_attestation.metadata.0.name
  }

  depends_on = [ teleport_provision_token.workload_id_demo_k8s_attestation_bot_token ]

  spec {
    selector {
      match_labels = {
        app = "tbot-attestation"
      }
    }

    template {
      metadata {
        labels = {
          app = "tbot-attestation"
        }
      }
      spec {
        security_context {
          run_as_user = 0
          run_as_group = 0
        }

        host_pid = true

        service_account_name = kubernetes_service_account.tbot_attestation.metadata.0.name

        volume {
          name = "config"
          config_map {
            name = kubernetes_config_map.tbot_attestation.metadata.0.name
          }
        }
        volume {
          name = "tbot-sockets"
          host_path {
            path = "/run/tbot/sockets"
            type = "DirectoryOrCreate" 
          }
        }
        volume {
          name = "join-sa-token"
          projected {
            sources {
              service_account_token {
                path = "join-sa-token"
                expiration_seconds = 600
                audience = "teleport-17-ent.asteroid.earth"
              }
            }
          }
        }
        
        container {
          name = "tbot-attestation"
          image = "public.ecr.aws/gravitational/tbot-distroless:17.0.1"
          image_pull_policy = "Always"
          security_context {
            privileged = true
          }
          args = ["start", "-c", "/config/tbot.yaml", "--log-format", "json"]
          volume_mount {
            name = "config"
            mount_path = "/config"
          }
          volume_mount {
            name = "tbot-sockets"
            mount_path = "/run/tbot/sockets"
            read_only = false
          }
          volume_mount {
            name = "join-sa-token"
            mount_path = "/var/run/secrets/tokens"
          }
          env {
            name = "TELEPORT_NODE_NAME"
            value_from {
              field_ref {
                field_path = "spec.nodeName"
              }
            }
          }
          env {
            name = "KUBERNETES_TOKEN_PATH"
            value = "/var/run/secrets/tokens/join-sa-token"
          }
        }
      }
    }
  }
}

resource "kubernetes_service_account" "demo_backend_2" {
  metadata {
    name = "demo-backend-2"
    namespace = kubernetes_namespace.workload_id_demo.metadata.0.name
  }
}

resource "kubernetes_deployment" "demo_backend_2" {
  metadata {
    name = "demo-backend-2-attestation"
    namespace = kubernetes_namespace.workload_id_demo.metadata.0.name
  }

  depends_on = [ kubernetes_daemonset.tbot_attestation ]

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "demo-backend-2-attestation"
      }
    }

    template {
      metadata {
        labels = {
          app = "demo-backend-2-attestation"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.demo_backend_2.metadata.0.name

        container {
          name = "demo-backend"
          image = "thedevelopnik/workload-id-demo-backend:0.1.0"
          image_pull_policy = "Always"

          volume_mount {
            name = "tbot-sockets"
            mount_path = "/run/tbot/sockets"
            read_only = true 
          }

          env {
            name = "BACKEND_SOCKET_PATH"
            value = "unix:///run/tbot/sockets/demo-backend-2.sock"
          }
          env {
            name = "BACKEND_APPROVED_CLIENT_SPIFFEID"
            value = "spiffe://teleport-17-ent.asteroid.earth/workload-id-demo/demo-web"
          }
          env {
            name = "BACKEND_NAME"
            value = "Backend 2"
          }
          env {
            name = "BACKEND_INFRA"
            value = "kubernetes"
          }
          env {
            name = "BACKEND_PORT"
            value = "3000"
          }
        }

        volume {
          name = "tbot-sockets"
          host_path {
            path = "/run/tbot/sockets"
            type = "Directory"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "demo-backend-2-attestation" {
  metadata {
    name = "demo-backend-2-attestation"
    namespace = kubernetes_namespace.workload_id_demo.metadata.0.name
  }

  spec {
    selector = {
      app = "demo-backend-2-attestation"
    }

    port {
      port = 443
      target_port = 3000
    }

    type = "LoadBalancer"
  }
}