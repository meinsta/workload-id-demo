resource "teleport_role" "workload_id_demo_issuer" {
  version = "v7"
  metadata = {
    name = "workload-id-demo-issuer"
  }

  spec = {
    allow = {
      workload_identity_labels = {
        application = "workload-id-demo"
      }
      rules = [
        {
          resources = ["workload_identity"]
        }
      ]
      verbs = [
        "list",
        "read"
      ]
    }
  }
}

resource "teleport_workload_identity" "workload_id_demo_web_wid" {
  version = "v1"
  metadata = {
    name = "workload-id-demo-${var.web_workload_name}"
    labels = {
      application = "workload-id-demo"
      component = "web"
    }
  }

  spec = {
    rules = {
      allow = [
        {
          conditions = [
            {
              attribute = "workload.unix.uid"
              eq = {
                value = 3001
              }
            }
          ]
        },
        {
          conditions = [
            {
              attribute = "workload.unix.gid"
              eq = {
                value = 3001
              }
            }
          ]
        }
      ]
    }
    spiffe = {
      id: "workload-id-demo/${var.web_workload_name}"
    }
  }
}

resource "teleport_workload_identity" "workload_id_demo_backend_1_wid" {
  version = "v1"
  metadata = {
    name = "workload-id-demo-${var.backend_1_workload_name}"
    labels = {
      application = "workload-id-demo"
    }
  }

  spec = {
    rules = {
      allow = [
        {
          conditions = [
            {
              attribute = "workload.unix.uid"
              eq = {
                value = 3000
              }
            }
          ]
        },
        {
          conditions = [
            {
              attribute = "workload.unix.gid"
              eq = {
                value = 3000
              }
            }
          ]
        }
      ]
    }
    spiffe = {
      id: "workload-id-demo/${var.backend_1_workload_name}"
    }
  }
}

resource "teleport_workload_identity" "workload_id_demo_backend_2_wid" {
  version = "v1"
  metadata = {
    name = "workload-id-demo-${var.backend_2_workload_name}"
    labels = {
      application = "workload-id-demo"
    }
  }

  spec = {
    rules = {
      allow = [
        {
          conditions = [
            {
              attribute = "workload.kubernetes.namespace"
              eq = {
                value = "workload-id-demo"
              }
            }
          ]
        },
        {
          conditions = [
            {
              attribute = "workload.kubernetes.service_account"
              eq = {
                value = "demo-backend-2"
              }
            }
          ]
        }
      ]
    }
    spiffe = {
      id: "workload-id-demo/${var.backend_2_workload_name}"
    }
  }
}

resource "teleport_bot" "workload_id_demo_web_bot" {
  name        = "workload-id-demo-web-bot"
  roles = [teleport_role.workload_id_demo_issuer.metadata.name]
}

resource "teleport_bot" "workload_id_demo_backend_1_bot" {
  name        = "workload-id-demo-backend-1-bot"
  roles = [teleport_role.workload_id_demo_issuer.metadata.name]
}

resource "teleport_bot" "workload_id_demo_backend_2_bot" {
  name        = "workload-id-demo-backend-2-bot"
  roles = [teleport_role.workload_id_demo_issuer.metadata.name]
}

resource "teleport_bot" "workload_id_demo_k8s_attestation_bot" {
  name        = "workload-id-demo-k8s-attestation-bot"
  roles = [teleport_role.workload_id_demo_issuer.metadata.name]
}