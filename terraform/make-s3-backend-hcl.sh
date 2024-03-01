#!/usr/bin/env bash

terraform output -json | jq -r \
'"
# Note: If you need to migrate the Terraform state file back to being local
#       e.g. if you want to remove the Terraform S3 Backend bootstrap resources,
#       then remove the terraform backend s3 block below and uncomment the terraform
#       backend local block below. Then run:
#
#       $> terraform init -migrate-state # answer yes to prompt
#
#       If you are trying to destroy the bootstrapped resources, you will need 
#       to MANUALLY REMOVE any state files (including any old versions)
#       left in the state bucket (either via AWS console or cli). This step has
#       been deliberately left manual, due to the severity of the action.
#       Once the state bucket is empty, you can safely destroy the bootstrap 
#       resources using the command below:
#
#       $> terraform destroy # answer yes to prompt
#       
# terraform {
#   backend \"local\" {
#     path = \"terraform.tfstate\"
#   }
# }

terraform {
    backend \"s3\" {
      profile        = \"default\"
      region         = \"\(.aws_region.value)\"
      bucket         = \"\(.s3_bucket_name.value)\"
      key            = \"\(if .s3_key_prefix.value then .s3_key_prefix.value + "/terraform.tfstate" else "terraform.tfstate" end)\"
      dynamodb_table = \"\(.dynamodb_table_name.value)\"
      encrypt        = true
  }
}
"'

