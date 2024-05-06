data "aws_caller_identity" "current" {}

data "aws_iam_role" "terraform" {
  name = var.terraform_aws_iam_role
}

data "aws_iam_session_context" "current" {
  arn = data.aws_caller_identity.current.arn
}

data "aws_s3_bucket" "bucket" {
  bucket = var.bucket
}
