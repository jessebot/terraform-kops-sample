# variables defined in terraform.tfvars
variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "aws_hosted_zone_name" {
  type    = string
}

variable "kops_bucket" {
  type    = string
}

variable "availability_zone" {
  type = string
}

variable "efs_cidr" {
  type = string
}

variable "k8s_cluster" {
  type = string
}

# these are outputs to be used with kops for cluster creation
output "VPC_ID" {
  value = aws_vpc.web-vpc.id
}

output "AWS_AVAILABILITY_ZONE" {
  value = var.availability_zone
}

output "KOPS_STATE_STORE" {
  value = "s3://${var.kops_bucket}"
}

# which cloud provider to use
provider "aws" {
  version = "~> 3.0"
  region  = var.aws_region 
}

# This is the virtual private cloud, "lets you provision a logically isolated section of the AWS Cloud"
resource "aws_vpc" "web-vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "web-vpc"
  }
}

# this gives internet access to your vpc and therefore your kops created cluster
resource "aws_internet_gateway" "kops-gw" {
  vpc_id = aws_vpc.web-vpc.id
  tags = {
    Name = "web gateway"
  }
}

# this is just the hosted zone in AWS for DNS purposes
resource "aws_route53_zone" "hosted-zone" {
  name = var.aws_hosted_zone_name
}

# need this for kops to persist state remotely
resource "aws_s3_bucket" "kops-bucket" {
  bucket = var.kops_bucket
  acl    = "private"

  tags = {
    Name       = "kops s3 bucket"
  }
}

# this allows kops to actually do things as a the special user it runs as
resource "aws_s3_bucket_policy" "kops-s3-policy" {
  bucket = aws_s3_bucket.kops-bucket.id

  policy = file("s3_bucket_policy.json")
}

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
