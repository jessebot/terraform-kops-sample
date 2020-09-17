# Getting Started
Before we can get started with our Kubernetes (k8s) cluster, we need to have a base enviornment deployed to AWS.
In this directory, I have what should be a working terraform enviornment to get started. You'll just need to make a few edits for your specific enviornment.

## Things I don't have here:
* An AWS account for you, but you can start one [here](https://aws.amazon.com/free/)
* Terraform user in AWS and appropriate IAM role for it. You'll want a special IAM user and role for this, and you'll want it to have access to create and destroy all the following resources:
  * EC2 (To create EC2 instances and autoscaling policies)
  * S3 Buckets/Policies (To create buckets to store kops/terraform configs)
  * VPC (To Create a special VPC for your k8s cluster)
  * Route53 (To add k8s cluster DNS records)
  * EFS (Only used *if* you want persistent storage in your k8s cluster)
* Terraform backend (You can learn more [here](https://www.terraform.io/docs/backends/types/s3.html).)

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
* `efs_cidr`            - Cidr for the subnet for your EFS file system, e.g. `10.1.1.0/24`
* `availability_zone`   - AWS availability zone within your region for your EFS file system mount, e.g. `us-east-1a`

### Update the following values in `s3_bucket_policy.json`:
* `YOUR_AWS_ACCOUNT`    - AWS account number you want to have kops deploy to.
* `YOUR_TERRAFORM_USER` - User name of the AWS account user you want to be able to modify your AWS infrastructure.
* `YOUR_KOPS_BUCKET`    - Name of the bucket you want to store your kops configuration and state in.

## Run Terraform
*Installing Terraform*
```
# If you're on a mac, this will do. 
brew install terraform
# if you have terraform installed on a mac and need to update it, you can do this
brew update && brew upgrade terraform
```
_Note: Learn more about brew [here](https://brew.sh/) and learn more about Terraform, including installation on other operating systems, [here](https://learn.hashicorp.com/collections/terraform/aws-get-started)._

*Assuming you have terraform installed and updated, here's the next step*
```
# initialize the new modules
terraform init
# plan and make sure everything looks right
terraform plan
# finally, we're ready to apply our base enviornment
terraform apply
```

## Running kops from cli in *nix
```
# you'll need these exported or you can manually edit them below
export K8S_CLUSTER_NAME='some-cluster-name'
export KOPS_BUCKET='some-bucket'
export VPC_ID='vpc-id'

# Here's a test run of things! Kops won't apply anything when you run this, but it will create the config in your S3 bucket:
kops create cluster --name=$K8S_CLUSTER_NAME \
                    --state=s3://$KOPS_BUCKET \
                    --zones=$AWS_REGION \
                    --node-count=2 \
                    --vpc=$VPC_ID \
                    --node-size=t2.micro \
                    --master-size=t3.small

# To apply the configuration you just tested out, you can do this --yes
kops update cluster --name=$K8S_CLUSTER_NAME \
                    --state=s3://$KOPS_BUCKET \
                    --yes
```

Now you should have a base cluster to move forward with!
