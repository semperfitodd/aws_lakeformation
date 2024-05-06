data "aws_iam_policy_document" "glue_policy" {
  statement {
    actions = [
      "glue:BatchGetJobs",
      "glue:BatchGetPartition",
      "glue:BatchStopJobRun",
      "glue:CreateCrawler",
      "glue:CreateDatabase",
      "glue:BatchCreatePartition",
      "glue:CreateTable",
      "glue:DeleteDatabase",
      "glue:DeleteTable",
      "glue:GetCrawler",
      "glue:GetDatabase",
      "glue:GetJob",
      "glue:GetTable",
      "glue:StartCrawler",
      "glue:StartJobRun",
      "glue:StopCrawler",
      "glue:UpdateCrawler",
      "glue:UpdateDatabase",
      "glue:UpdatePartition",
      "glue:UpdateTable",
    ]
    resources = [
      "arn:aws:glue:${var.region}:${data.aws_caller_identity.current.account_id}:catalog",
      "arn:aws:glue:${var.region}:${data.aws_caller_identity.current.account_id}:crawler/${local.environment}",
      "arn:aws:glue:${var.region}:${data.aws_caller_identity.current.account_id}:database/${local.environment}",
      "arn:aws:glue:${var.region}:${data.aws_caller_identity.current.account_id}:job/${local.environment}",
      "arn:aws:glue:${var.region}:${data.aws_caller_identity.current.account_id}:table/${local.environment}/*",
    ]
    effect = "Allow"
  }
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws-glue/*"
    ]
    effect = "Allow"
  }
  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket"
    ]
    resources = [
      data.aws_s3_bucket.bucket.arn,
      "${data.aws_s3_bucket.bucket.arn}/*"
    ]
    effect = "Allow"
  }
}

data "aws_iam_policy_document" "glue_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      identifiers = ["glue.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_glue_catalog_database" "this" {
  name = local.environment
}

resource "aws_glue_crawler" "crawler" {
  name        = local.environment
  description = "${local.environment} crawler for shared S3 bucket data"

  role          = aws_iam_role.glue_service_role.arn
  database_name = aws_glue_catalog_database.this.name

  s3_target {
    path = "s3://${data.aws_s3_bucket.bucket.bucket}/"
  }

  schema_change_policy {
    delete_behavior = "LOG"
    update_behavior = "UPDATE_IN_DATABASE"
  }

  schedule = "cron(0 3 1 * ? *)"
}

resource "aws_iam_policy" "glue_service_policy" {
  name        = "glue_service_policy"
  description = "Policy that allows sufficient permissions for the crawler"

  policy = data.aws_iam_policy_document.glue_policy.json
}

resource "aws_iam_role" "glue_service_role" {
  name = "glue_service_role"

  assume_role_policy = data.aws_iam_policy_document.glue_role.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "glue_service_policy_attachment" {
  role       = aws_iam_role.glue_service_role.name
  policy_arn = aws_iam_policy.glue_service_policy.arn
}
