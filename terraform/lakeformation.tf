data "aws_iam_policy_document" "lakeformation_policy" {
  statement {
    actions = [
      "glue:CreateDatabase",
      "glue:GetDatabase",
      "glue:UpdateDatabase",
      "glue:DeleteDatabase",
      "glue:CreateTable",
      "glue:GetTable",
      "glue:UpdateTable",
      "glue:DeleteTable",
      "glue:BatchGetJobs",
      "glue:GetJob",
      "glue:StartJobRun",
      "glue:BatchStopJobRun",
      "glue:CreateCrawler",
      "glue:GetCrawler",
      "glue:UpdateCrawler",
      "glue:StartCrawler",
      "glue:StopCrawler"
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
    effect = "Allow"
    actions = [
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:PutObject",
    ]
    resources = [
      "${data.aws_s3_bucket.bucket.arn}/*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [data.aws_s3_bucket.bucket.arn]
  }
}

data "aws_iam_policy_document" "lakeformation_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      identifiers = ["lakeformation.amazonaws.com"]
      type        = "Service"
    }
  }
}

locals {
  environment = "${var.environment}_${random_string.this.result}"
}

resource "aws_iam_policy" "lakeformation_service_policy" {
  name        = "${local.environment}_policy"
  description = "Policy that allows sufficient permissions for the crawler"

  policy = data.aws_iam_policy_document.lakeformation_policy.json
}

resource "aws_iam_role" "lakeformation_service_role" {
  name = "${local.environment}_role"

  assume_role_policy = data.aws_iam_policy_document.lakeformation_role.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "lakeformation_service_policy_attachment" {
  role       = aws_iam_role.lakeformation_service_role.name
  policy_arn = aws_iam_policy.lakeformation_service_policy.arn
}

resource "aws_lakeformation_data_lake_settings" "this" {
  admins = [data.aws_iam_session_context.current.issuer_arn]
}

resource "aws_lakeformation_permissions" "caller_catalog_database_permissions" {
  principal   = data.aws_iam_role.terraform.arn
  permissions = ["ALL"]

  database {
    name = aws_glue_catalog_database.this.name
  }
}

resource "aws_lakeformation_permissions" "caller_catalog_table_permissions" {
  principal   = data.aws_iam_role.terraform.arn
  permissions = ["ALL"]

  table {
    database_name = aws_glue_catalog_database.this.name
    wildcard      = true
  }
}

resource "aws_lakeformation_permissions" "glue_catalog_database_permissions" {
  principal = aws_iam_role.glue_service_role.arn
  permissions = [
    "ALTER",
    "CREATE_TABLE",
    "DROP",
  ]

  database {
    name = aws_glue_catalog_database.this.name
  }
}

resource "aws_lakeformation_permissions" "glue_catalog_table_permissions" {
  principal   = aws_iam_role.glue_service_role.arn
  permissions = ["ALL"]

  table {
    database_name = aws_glue_catalog_database.this.name
    wildcard      = true
  }
}

resource "aws_lakeformation_permissions" "s3_data_location_permissions" {
  principal   = aws_iam_role.glue_service_role.arn
  permissions = ["DATA_LOCATION_ACCESS"]

  data_location {
    arn = data.aws_s3_bucket.bucket.arn
  }
}

resource "aws_lakeformation_resource" "this" {
  arn = data.aws_s3_bucket.bucket.arn

  role_arn = aws_iam_role.lakeformation_service_role.arn
}
