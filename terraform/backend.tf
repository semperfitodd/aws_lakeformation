terraform {
  backend "s3" {
    bucket = "bsc.sandbox.terraform.state"
    key    = "aws_lakeformation"
    region = "us-east-2"
  }
}
