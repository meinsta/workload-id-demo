resource "kubernetes_namespace" "workload_id_demo" {
  metadata {
    name = "workload-id-demo"
  }
}

# resource "kubernetes_service_account" "tbot" {
#   metadata {
#     name = "demo-backend-2-tbot"
#     namespace = kubernetes_namespace.workload_id_demo.metadata.0.name
#   }
# }

# resource "kubernetes_config_map" "tbot" {
#   metadata {
#     name = "demo-backend-2-tbot"
#     namespace = kubernetes_namespace.workload_id_demo.metadata.0.name
#   }

#   data = {
#     "tbot.yaml" = yamlencode({
#     version = "v2"
#     onboarding = {
#       join_method = "kubernetes"
#       token = "workload-id-demo-backend-2-bot"
#     }
#     storage = {
#       type = "memory"
#     }
#     proxy_server = "teleport-16-ent.asteroid.earth:443"
#     outputs = [
#       {
#         type = "spiffe-svid"
#         destination = {
#           type = "directory"
#           path = "/tmp/tbot/spiffe/demo-backend-2"
#         }
#         svid = {
#           path = "/workload-id-demo/demo-backend-2"
#         }
#       }
#     ]
#     services = [
#       {
#         type = "spiffe-workload-api"
#         listen = "unix:///tmp/tbot/demo-backend-2.sock"
#         svids = [
#           {
#             path = "/workload-id-demo/demo-backend-2"
#           }
#         ]
#       }
#     ]
#     })
#   }
# }

# resource "kubernetes_persistent_volume_claim" "tbot" {
#   metadata {
#     name = "tbot"
#     namespace = kubernetes_namespace.workload_id_demo.metadata.0.name
#   }

#   spec {
#     access_modes = ["ReadWriteOnce"]
#     resources {
#       requests = {
#         storage = "1Gi"
#       }
#     }
#     storage_class_name = "premium-rwo"
#   }
# }

# resource "kubernetes_deployment" "demo-backend-2" {
#   metadata {
#     name = "demo-backend-2"
#     namespace = kubernetes_namespace.workload_id_demo.metadata.0.name
#   }

#   spec {
#     replicas = 1

#     selector {
#       match_labels = {
#         app = "demo-backend-2"
#       }
#     }

#     template {
#       metadata {
#         labels = {
#           app = "demo-backend-2"
#         }
#       }

#       spec {
#         service_account_name = kubernetes_service_account.tbot.metadata.0.name

#         container {
#           name = "demo-backend"
#           image = "thedevelopnik/workload-id-demo-backend:0.1.0"
#           image_pull_policy = "Always"

#           volume_mount {
#             name = "tbot-socket"
#             mount_path = "/tmp/tbot"
#           }

#           env {
#             name = "BACKEND_SOCKET_PATH"
#             value = "unix:///tmp/tbot/demo-backend-2.sock"
#           }
          
#           env {
#             name = "BACKEND_APPROVED_CLIENT_SPIFFEID"
#             value = "spiffe://teleport-16-ent.asteroid.earth/workload-id-demo/demo-web"
#           }

#           env {
#             name = "BACKEND_NAME"
#             value = "Backend 2"
#           }

#           env {
#             name = "BACKEND_INFRA"
#             value = "kubernetes"
#           }

#           env {
#             name = "BACKEND_PORT"
#             value = "3000"
#           }
#         }

#         init_container {
#           name = "tbot"
#           image = "public.ecr.aws/gravitational/tbot-distroless:16.0.4"
#           image_pull_policy = "Always"

#           args = [
#             "start",
#             "--config",
#             "/etc/tbot/tbot.yaml",
#           ]

#           env {
#             name = "KUBERNETES_TOKEN_PATH"
#             value = "/var/run/secrets/tokens/join-sa-token"
#           }

#           volume_mount {
#             name = "tbot"
#             mount_path = "/etc/tbot"
#           }

#           volume_mount {
#             name = "tbot-socket"
#             mount_path = "/tmp/tbot"
#           }

#           volume_mount {
#             name = "join-sa-token"
#             mount_path = "/var/run/secrets/tokens"
#           }
#         }

#         volume {
#           name = "tbot"
#           config_map {
#             name = kubernetes_config_map.tbot.metadata.0.name
#           }
#         }

#         volume {
#           name = "tbot-socket"
#           persistent_volume_claim {
#             claim_name = "tbot"
#           }
#         }

#         volume {
#           name = "join-sa-token"
#           projected {
#             sources {
#               service_account_token {
#                 path = "join-sa-token"
#                 expiration_seconds = 600
#                 audience = "teleport-16-ent.asteroid.earth"
#               }
#             }
#           }
#         }
#       }
#     }
#   }
# }

# resource "kubernetes_service" "demo-backend-2" {
#   metadata {
#     name = "demo-backend-2"
#     namespace = kubernetes_namespace.workload_id_demo.metadata.0.name
#   }

#   spec {
#     selector = {
#       app = "demo-backend-2"
#     }

#     port {
#       port = 443
#       target_port = 3000
#     }

#     type = "LoadBalancer"
#   }
# }
