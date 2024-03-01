# Terraform

<img src="../images/chicken-egg.jpg" alt="picture of three chicks and two eggs" width="400"/>

## How to: Manage AWS Infrastructure using Terraform

### Setup [Terraform (🐔) S3 Backend](https://developer.hashicorp.com/terraform/language/settings/backends/s3) using Terraform (🥚)

The supplied Terraform [bootstrap template](./terraform-aws-bootstrap.tf) and these
accompanying instructions will help setup the required AWS resources:

- [S3](https://aws.amazon.com/s3/) bucket to store Terraform state file
- [DynamoDB](https://aws.amazon.com/dynamodb/) to manage concurrent access to Terraform state file
- [IAM](https://aws.amazon.com/iam/) policy to enable access to backend resources

### Installation Instructions

#### Prerequisites

- Install [Terraform CLI](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) for your platform
- Have an existing AWS account id (or [create a new account](https://portal.aws.amazon.com/gp/aws/developer/registration/index.html?nc2=h_ct&src=header_signup))
- Install [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) for your platform

#### Provision Resources

##### Initialise Terraform

```shell
terraform init
```

##### Apply Terraform

```shell
terraform apply
```

##### Input AWS Account Id

```shell
var.aws_account_id
  AWS account to use. [Mandatory]

  Enter a value: # TODO: enter your account id here when prompted
```

##### Review and Approve Plan

```shell
... <Terraform Plan omitted> ...

Plan: 5 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: # TODO: review the Terraform Plan output and type 'yes' if it looks good

... <Terraform Apply logs omitted> ...

Apply complete! Resources: 5 added, 0 changed, 0 destroyed.
```

##### Create Terraform Backend Config

```shell
./make-s3-backend-hcl.sh > terraform-backend.tf
```

##### Migrate Local Terraform State File to S3

```shell
terraform init -migrate-state # answer "yes" when prompted to copy state to new backend
```

### Uninstall instructions

#### Destroy Bootstrap Resources

- In order to cleanly remove all bootstrapped resources, the state file needs to be
  migrated from S3 to a local copy.
- This allows a terraform destroy to be issued to remove the bootstrapped resources.

##### Update Terraform Backend Config

```shell
cat << EOF > terraform-backend.tf
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
EOF
```

##### Migrate S3 State File to a Local Copy

```shell
terraform init -migrate-state # answer yes to prompt
```

##### Manually Remove State Files from S3 Bucket

If you are trying to destroy the bootstrapped resources, you will need
to MANUALLY REMOVE any state files (including any old versions)
left in the state bucket (either via AWS console or cli). This step has
been deliberately left manual, due to the severity of the action.

##### Destroy Resources

Once the state bucket is empty, you can safely destroy the bootstrap
resources using the command below:

```shell
terraform destroy
```
