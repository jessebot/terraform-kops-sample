# Getting Started
Before we can get started with our Kubernetes (k8s) cluster, we need to have a base enviornment deployed to AWS.
In this directory, I have what should be a working terraform enviornment to get started. You'll just need to make a few edits for your specific enviornment.

## Before we begin, you'll need...
* AWS account for you; You can start a free one [here](https://aws.amazon.com/free/)
* AWS credentials store locally, and I recommend [aws-vault](https://github.com/99designs/aws-vault)
* Terraform user in AWS and appropriate IAM role for it. You'll want a special IAM user and role for this, and you'll want it to have access to create and destroy all the following resources:
  * EC2 (To create EC2 instances and autoscaling policies)
  * S3 Buckets/Policies (To create buckets to store kops/terraform configs)
  * VPC (To Create a special VPC for your k8s cluster)
  * Route53 (To add k8s cluster DNS records)
  * EFS (Only used *if* you want persistent storage in your k8s cluster)
* Terraform backend, but you can learn more [here](https://www.terraform.io/docs/backends/types/s3.html)

## Copy the sample tfvars and json files to live version as seen below:
```
cp terraform_sample.tfvars terraform.tfvars
cp s3_bucket_policy_sample.json s3_bucket_policy.json
```

### Update the following values for your base cluster in `terraform.tfvars`:
* `vpc_cidr`             - Cidr for your VPC to use, e.g. `10.1.0.0/16`
* `aws_region`           - AWS region, e.g. `us-east-1`
* `aws_hosted_zone_name` - Name of your hosted zone in AWS, e.g. `example.com`
* `kops_bucket`          - Name of the AWS S3 bucket to store your kops config

*Only necessary if you want you to have persistent storage in your enviornment accross AWS regions using EFS:*
* `k8s_cluster`         - Name of the kubernetes cluster you want to create. This will be the same as $KOPS_CLUSTER_NAME later on
* `efs_cidr`            - Cidr for the subnet for your EFS file system, e.g. `10.1.1.0/24`
* `availability_zone`   - AWS availability zone within your region for your EFS file system mount, e.g. `us-east-1a`

### Update the following values in `s3_bucket_policy.json`:
* `AWS_ACCOUNT_ID`  - AWS account number you want to have kops deploy to.
* `TERRAFORM_USER`  - User name of the AWS account user you want to be able to modify your AWS infrastructure.
* `KOPS_BUCKET`     - Name of the bucket you want to store your kops configuration and state in.

## Run Terraform
_Note: To install Terraform, check out the docs [here](https://learn.hashicorp.com/collections/terraform/aws-get-started)._

Intialize, plan, and apply Terraform config:
```
# Initialize the new modules: There are two here default/main and efs
terraform init
# Plan, which is a terraform dry, run to make sure everything looks right
terraform plan
# Finally, we're ready to apply our base enviornment, this actually makes changes to your infrastructure! (you'll need to enter "yes")
terraform apply
```
Your base environment should be ready now! You should have seen the following outputs: AWS_AVAILABILITY_ZONE, KOPS_STATE_STORE, VPC_ID, but if you need them again, you can simply run:

`terraform output`

## Running kops (Kubernetes Ops)
*Note: To install kops, check out the docs [here](https://kops.sigs.k8s.io/getting_started/install/#github-releases)*

Export variables, kops create, and kops update:
```
# you'll need these exported, but you'll have to update these to your the values you actually want
export VPC_ID='aws-vpc-id'
export AWS_AVAILABILITY_ZONE='your-aws-availability-zone'

# You can add these to your bash.rc/bash.profile if you only have one cluster, as they'll be used for future management
export KOPS_CLUSTER_NAME='kops-s3-bucket-name'
export KOPS_STATE_STORE='s3://kops-cluster-name'

# Here's a test run of things! Kops won't apply anything when you run this, but it will create the config in your S3 bucket:
kops create cluster --name=$KOPS_CLUSTER_NAME \
                    --state=$KOPS_STATE_STORE \
                    --zones=$AWS_AVAILABILITY_ZONE \
                    --node-count=2 \
                    --vpc=$VPC_ID \
                    --node-size=t2.micro \
                    --master-size=t3.small

# To apply the configuration you just tested out, you can do this --yes
kops update cluster --yes
```

Now you should have a base cluster to move forward with!

## Persistent storage in AWS with EFS
*Note: You can also use EBS, but EBS is not cross availability zone/region.*

Uncomment the following module and data source in `main.tf`:

```
# this is for if you want to use persistent storage accross regions with Kubernetes in AWS, backed by EFS (AWS NFS)
# data "aws_security_group" "node_security_group" {
#   name = "nodes.${var.k8s_cluster}"
# }
#
# module "persistent-storage" {
#     source = "./modules/efs"
#
#     kops_node_security_group = data.aws_security_group.node_security_group.id
#     vpc_id                   = aws_vpc.web-vpc.id
#     availability_zone        = var.availability_zone
#     efs_cidr                 = var.efs_cidr
# }
```

Now run the following terraform commands:
```
# initialize the new module
terraform init
# plan out the new changes aka terraform dry run
terraform plan
# apply the new EFS module to your AWS environment
terraform apply
```

### Updating kops via CI/CD
* Learn more about manifests with kops [here](https://github.com/kubernetes/kops/blob/master/docs/manifests_and_customizing_via_api.md)

* Learn more about kops with GitLab CI [here](https://github.com/kubernetes/kops/blob/master/docs/continuous_integration.md)
