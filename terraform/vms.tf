data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-arm64-server-20240228"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# role and policy
resource "aws_iam_role" "workload_id_demo_nodes_role" {
  name = "WorkloadIdDemoNodes"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Owner = "Dave Sudia"
    Environment = "workload-id-demo"
  }
}

resource "aws_iam_role_policy" "workload_id_demo_nodes_policy" {
  name = "WorkloadIdDemoNodes"
  role = aws_iam_role.workload_id_demo_nodes_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:GetCallerIdentity",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "s3:ListBucket",
          "s3:GetObject"
        ]
        Sid = ""
        Effect = "Allow"
        Resource = "arn:aws:s3:::${aws_s3_bucket.workload_id_demo_binaries_bucket.bucket}/*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "workload_id_demo_nodes_profile" {
  name = "WorkloadIdDemoNodes"
  role = aws_iam_role.workload_id_demo_nodes_role.name
}

# networking
resource "aws_security_group" "workload_id_demo_nodes_sg" {
  name        = "WorkloadIdDemoNodes"
  description = "Allow TLS and SSH inbound traffic"

  ingress {
    description      = "TLS from anywhere"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "SSH from anywhere"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "EC2 Instance Connect from anywhere"
    from_port        = 65535
    to_port          = 65535
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "workload-id-demo-nodes"
    Owner = "Dave Sudia"
    Environment = "workload-id-demo"
    Service = "Workload ID Demo Web"
  }
}

#cloud init
resource "cloudinit_config" "workload_id_demo_web_cloud_init" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "create_tbot_config.sh"
    content_type = "text/x-shellscript"

    content = templatefile("${path.module}/create_tbot_config.sh.tftpl", {
      teleport_addr = var.teleport_addr,
      token_name = teleport_provision_token.workload_id_demo_web_bot_token.metadata.name,
      workload_name = "demo-web"
    })
  }

  part {
    filename     = "create_teleport_config.sh"
    content_type = "text/x-shellscript"

    content = templatefile("${path.module}/create_teleport_config.sh.tftpl", {
      teleport_addr = var.teleport_addr,
      token_name = teleport_provision_token.workload_id_demo_node_token.metadata.name,
      nodename = "workload-id-demo-web"
    })
  }

  part {
    filename     = "install_ghostunnel.sh"
    content_type = "text/x-shellscript"

    content = file("${path.module}/install_ghostunnel.sh")
  }

  part {
    filename     = "install_teleport.sh"
    content_type = "text/x-shellscript"

    content = file("${path.module}/install_teleport.sh")
  }
}

resource "cloudinit_config" "workload_id_demo_backend_1_cloud_init" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "create_tbot_config.sh"
    content_type = "text/x-shellscript"

    content = templatefile("${path.module}/create_tbot_config.sh.tftpl", {
      teleport_addr = var.teleport_addr,
      token_name = teleport_provision_token.workload_id_demo_backend_1_bot_token.metadata.name,
      workload_name = "demo-backend-1"
    })
  }

  part {
    filename     = "create_teleport_config.sh"
    content_type = "text/x-shellscript"

    content = templatefile("${path.module}/create_teleport_config.sh.tftpl", {
      teleport_addr = var.teleport_addr,
      token_name = teleport_provision_token.workload_id_demo_node_token.metadata.name,
      nodename = "workload-id-demo-backend-1"
    })
  }

  part {
    filename     = "install_teleport.sh"
    content_type = "text/x-shellscript"

    content = file("${path.module}/install_teleport.sh")
  }
}

# vms
resource "aws_instance" "workload_id_demo_web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t4g.small"
  associate_public_ip_address = true

  root_block_device {
    volume_size = 20
  }
  
  tags = {
    Name = "workload-id-demo-web"
    Owner = "Dave Sudia"
    Environment = "workload-id-demo"
    Service = "Workload ID Demo Web"
  }

  metadata_options {
    http_tokens = "required"
  }

  iam_instance_profile = aws_iam_instance_profile.workload_id_demo_nodes_profile.name
  security_groups = [aws_security_group.workload_id_demo_nodes_sg.name]

  user_data = cloudinit_config.workload_id_demo_web_cloud_init.rendered
}

resource "aws_instance" "workload_id_demo_backend_1" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t4g.small"
  associate_public_ip_address = true

  root_block_device {
    volume_size = 20
  }
  
  tags = {
    Name = "workload-id-demo-backend-1"
    Owner = "Dave Sudia"
    Environment = "workload-id-demo"
    Service = "Workload ID Demo Backend 1"
  }

  metadata_options {
    http_tokens = "required"
  }

  iam_instance_profile = aws_iam_instance_profile.workload_id_demo_nodes_profile.name
  security_groups = [aws_security_group.workload_id_demo_nodes_sg.name]

  user_data = cloudinit_config.workload_id_demo_backend_1_cloud_init.rendered
}

# ip addresses
resource "aws_eip" "workload_id_demo_web_eip" {
  instance = aws_instance.workload_id_demo_web.id

  tags = {
    Name = "workload-id-demo-web"
    Owner = "Dave Sudia"
    Environment = "workload-id-demo"
    Service = "Workload ID Demo Web"
  }
}

resource "aws_eip" "workload_id_demo_backend_1_eip" {
  instance = aws_instance.workload_id_demo_backend_1.id

  tags = {
    Name = "workload-id-demo-backend-1"
    Owner = "Dave Sudia"
    Environment = "workload-id-demo"
    Service = "Workload ID Demo Backend 1"
  }
}