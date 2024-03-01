resource "teleport_role" "workload_id_demo_web_bot_role" {
  version = "v7"
  metadata = {
    name = "workload-id-demo-web-spiffe-bot"
  }

  spec = {
    allow = {
      spiffe = [{
          path = "/demo-web"
          ip_sans = ["0.0.0.0/0"]
          dns_sans = ["*"]
      }]
    }
  }
}

resource "teleport_role" "workload_id_demo_backend_1_bot_role" {
  version = "v7"
  metadata = {
    name = "workload-id-demo-backend-1-spiffe-bot"
  }

  spec = {
    allow = {
      spiffe = [{
          path = "/demo-backend-1"
          ip_sans = ["0.0.0.0/0"]
          dns_sans = ["*"]
      }]
    }
  }
}

resource "teleport_provision_token" "workload_id_demo_node_token" {
  version = "v2"
  metadata = {
    name        = "workload-id-demo-nodes"
    description = "Token for Workload ID Demo Nodes - web and backend"
  }

  spec = {
    roles = ["Node"]
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
    name        = "workload-id-demo-web-bot"
    description = "Token for Workload ID Demo Web Bot"
  }

  spec = {
    roles = ["Bot"]
    bot_name: "workload-id-demo-web-bot"
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
    name        = "workload-id-demo-backend-bot"
    description = "Token for Workload ID Demo backend Bot"
  }

  spec = {
    roles = ["Bot"]
    bot_name: "workload-id-demo-backend-1-bot"
    join_method = "iam"
    allow = [
      {
        aws_account = var.aws_account_num
        aws_arn = "arn:aws:sts::${var.aws_account_num}:assumed-role/WorkloadIdDemoNodes/i-*"
      }
    ]
  }
}

# resource "teleport_bot" "workload_id_demo_web_bot" {
#   name        = "workload-id-demo-web-bot"
#   token_id = teleport_provision_token.workload_id_demo_web_bot_token.metadata.name

#   roles = [teleport_role.workload_id_demo_web_bot_role.metadata.name]
# }

# resource "teleport_bot" "workload_id_demo_backend_1_bot" {
#   name        = "workload-id-demo-web-bot"
#   token_id = teleport_provision_token.workload_id_demo_backend_1_bot_token.metadata.name

#   roles = [teleport_role.workload_id_demo_backend_1_bot_role.metadata.name]
# }
