resource "aws_s3_bucket" "workload_id_demo_binaries_bucket" {
  bucket = "workload-id-demo-binaries"
  acl    = "private"

  tags = {
    Name        = "Workload ID Demo Binaries"
    Environment = "Dev"
    Owner = "Dave Sudia"
    Environment = "workload-id-demo"
  }
}
