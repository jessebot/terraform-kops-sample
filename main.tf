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

provider "aws" {
  version = "~> 3.0"
  region  = var.aws_region 
}

resource "aws_vpc" "web-vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "web-vpc"
  }
}

resource "aws_internet_gateway" "kops-gw" {
  vpc_id = aws_vpc.web-vpc.id
  tags = {
    Name = "web gateway"
  }
}

resource "aws_route53_zone" "hosted-zone" {
  name = var.aws_hosted_zone_name
}

# need this for kops to persist state
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

# these are outputs to be used with kops for cluster creation
output "route-name-servers" {
  value = aws_route53_zone.hosted-zone.name_servers
}

output "VPC-ID" {
  value = aws_vpc.web-vpc.id
}
