/*
 * Terraform Config to Bootstrap S3 Backend
 * https://developer.hashicorp.com/terraform/language/settings/backends/s3
 */

variable "aws_account_id" {
  type        = string
  description = "AWS account to use. [Mandatory]"
}

variable "aws_region" {
  type        = string
  default     = ""
  description = "AWS region to provision resources in. [Default: will use session region if not explicitly set]"
}

variable "s3_bucket_name_prefix" {
  type        = string
  default     = "terraform-state-"
  description = "Prefix for name of S3 bucket to store Terraform state. [Default: 'terraform-state-']"
}

variable "s3_key_prefix" {
  type        = string
  default     = null
  description = "Key prefix for Terraform state objects. [Default: no prefix ie state file is stored in root of state bucket.]"
}

variable "dynamodb_table_name" {
  type        = string
  default     = "terraform-lock-table"
  description = "Name of DynamoDB table to lock Terraform state. [Default: 'terraform-lock-table]"
}

variable "iam_policy_name" {
  type        = string
  default     = "terraform-s3-backend"
  description = "Name of IAM policy enabling access to the Terraform backend. [Default: 'terraform-s3-backend']"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.38.0"
    }
  }
}

provider "aws" {
  region              = var.aws_region
  allowed_account_ids = [var.aws_account_id]

  default_tags {
    tags = {
      Terraform = "true"
    }
  }
}

resource "aws_s3_bucket" "this" {
  bucket_prefix = can(var.s3_bucket_name_prefix) ? var.s3_bucket_name_prefix : null

  tags = {
    Name        = "Terraform S3 Backend - State"
    application = "Terraform S3 Backend"
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "this" {
  name     = var.dynamodb_table_name
  hash_key = "LockID"

  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "Terraform S3 Backend - State Lock"
    application = "Terraform S3 Backend"
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_iam_policy" "this" {
  name        = var.iam_policy_name
  description = "Terraform S3 Backend access."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Bucket"
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.this.arn
      },
      {
        Sid    = "StateAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = var.s3_key_prefix != null ? "${aws_s3_bucket.this.arn}/${var.s3_key_prefix}/*" : "${aws_s3_bucket.this.arn}/*"
      },
      {
        Sid    = "StateLock"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]
        Resource = aws_dynamodb_table.this.arn
      },
    ]
  })

  tags = {
    Name        = "Terraform S3 Backend - State Access"
    application = "Terraform S3 Backend"
  }
}

data "aws_region" "current" {}
output "aws_region" {
  description = "Region backend resources have been provisioned in"
  value       = data.aws_region.current.id
}

output "s3_bucket_name" {
  description = "Bucket name containing Terraform state file."
  value       = aws_s3_bucket.this.id
}

output "dynamodb_table_name" {
  description = "DynamoDB managing lock for state file access."
  value       = aws_dynamodb_table.this.id
}

output "s3_key_prefix" {
  description = "S3 key path prefix to Terraform state file."
  value       = var.s3_key_prefix
}

