resource "teleport_provision_token" "workload_id_demo_node_token" {
  version = "v2"
  metadata = {
    name        = "workload-id-demo-nodes"
    description = "Token for Workload ID Demo Nodes - web and backend"
  }

  spec = {
    roles = ["Node", "App"]
    join_method = "iam"
    allow = [
      {
        aws_account = var.aws_account_num
        aws_arn = "arn:aws:sts::${var.aws_account_num}:assumed-role/WorkloadIdDemoNodes/i-*"
      }
    ]
  }
}

resource "teleport_provision_token" "workload_id_demo_web_bot_token" {
  version = "v2"
  metadata = {
    name        = "workload-id-${var.web_workload_name}-bot"
    description = "Token for Workload ID Demo Web Bot"
  }

  spec = {
    roles = ["Bot"]
    bot_name = teleport_bot.workload_id_demo_web_bot.name
    join_method = "iam"
    allow = [
      {
        aws_account = var.aws_account_num
        aws_arn = "arn:aws:sts::${var.aws_account_num}:assumed-role/WorkloadIdDemoNodes/i-*"
      }
    ]
  }
}

resource "teleport_provision_token" "workload_id_demo_backend_1_bot_token" {
  version = "v2"
  metadata = {
    name        = "workload-id-${var.backend_one_workload_name}-bot"
    description = "Token for Workload ID Demo backend Bot"
  }

  spec = {
    roles = ["Bot"]
    bot_name = teleport_bot.workload_id_demo_backend_1_bot.name
    join_method = "iam"
    allow = [
      {
        aws_account = var.aws_account_num
        aws_arn = "arn:aws:sts::${var.aws_account_num}:assumed-role/WorkloadIdDemoNodes/i-*"
      }
    ]
  }
}

resource "teleport_provision_token" "workload_id_demo_backend_2_bot_token" {
  version = "v2"
  metadata = {
    name        = "workload-id-${var.backend_two_workload_name}-bot"
    description = "Token for Workload ID Demo backend Bot"
  }

  spec = {
    roles = ["Bot"]
    bot_name = teleport_bot.workload_id_demo_backend_2_bot.name
    join_method = "kubernetes"
    kubernetes = {
      type = "static_jwks"
      static_jwks = {
        jwks = jsonencode({
          keys = [
            {
              kty = "RSA"
              alg = "RS256"
              use = "sig"
              kid = "QRDItnlKGFnrqV6uxnDJM9s_COTCO-j_ETNCYyxfc_E"
              n = "p1QGhhSvP2T2hQ93yUFC1LDYXGt5gSW6VnOnlgiZd9xjrcllFVrZu6FfnpzTOSRn0iNzTYQJSkVOh6z_y8QFVOxvXlafMC9G0obG5aDLNyBKLvSua5ugnG183sORm1SkB_zOW6YYnmGeCJlVtpi_izq8-3KKr8-ISEQKJaL27vCgR6njV66v9xLdBp8_5Wlgv4ji30wfReQLubYsCLUO6H9xYaHlTNov-42xI5jxHCumSZU7FAODOACIlrq8F8YT7PiC_dArKEWNtlUHfZ-JsHbWewG0rv_uTM5gKVxvMDYuoENRBxqmE6bglbhN4XGCg5lefJkeonn3wb59aLf6kQ"
              e = "AQAB"
            }
          ]
        })
      }
      allow = [
        {
          service_account = "workload-id-demo:demo-backend-2-tbot"
        }
    ]
    }
  }
}

resource "teleport_provision_token" "workload_id_demo_k8s_attestation_bot_token" {
  version = "v2"
  metadata = {
    name        = "workload-id-demo-k8s-attestation-bot"
    description = "Token for Workload ID Demo k8s attestation backend Bot"
  }

  spec = {
    roles = ["Bot"]
    bot_name = teleport_bot.workload_id_demo_k8s_attestation_bot.name
    join_method = "kubernetes"
    kubernetes = {
      type = "static_jwks"
      static_jwks = {
        jwks = jsonencode({
          keys = [
            {
              kty = "RSA"
              alg = "RS256"
              use = "sig"
              kid = "QRDItnlKGFnrqV6uxnDJM9s_COTCO-j_ETNCYyxfc_E"
              n = "p1QGhhSvP2T2hQ93yUFC1LDYXGt5gSW6VnOnlgiZd9xjrcllFVrZu6FfnpzTOSRn0iNzTYQJSkVOh6z_y8QFVOxvXlafMC9G0obG5aDLNyBKLvSua5ugnG183sORm1SkB_zOW6YYnmGeCJlVtpi_izq8-3KKr8-ISEQKJaL27vCgR6njV66v9xLdBp8_5Wlgv4ji30wfReQLubYsCLUO6H9xYaHlTNov-42xI5jxHCumSZU7FAODOACIlrq8F8YT7PiC_dArKEWNtlUHfZ-JsHbWewG0rv_uTM5gKVxvMDYuoENRBxqmE6bglbhN4XGCg5lefJkeonn3wb59aLf6kQ"
              e = "AQAB"
            }
          ]
        })
      }
      allow = [
        {
          service_account = "tbot-attestation:tbot-attestation"
        }
    ]
    }
  }
}
