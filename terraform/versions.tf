provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Owner       = "Todd"
      Project     = "aws_lakeformation"
      Provisioner = "Terraform"
    }
  }
}
