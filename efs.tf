variable "kops_node_security_group" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "availability_zone" {
  type = string
}

variable "efs_cidr" {
  type = string
}

# this is for django's postgres pod's persistent storage
# specifically this security group must be linked with your NODE security group
resource "aws_subnet" "efs-subnet" {
  vpc_id            = var.vpc_id 
  availability_zone = var.availability_zone 
  cidr_block        = var.efs_cidr
}

resource "aws_security_group" "k8s-efs" {
  name        = "k8s"
  description = "allow efs and node security group to be friends"
  vpc_id      = var.vpc_id 
}

resource "aws_security_group_rule" "all-node-to-efs" {
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.k8s-efs.id  
  source_security_group_id = var.kops_node_security_group
  to_port                  = 0
  type                     = "ingress"
}

resource "aws_efs_file_system" "django-postgres-storage" {
  creation_token = "django-postgres-storage"
  encrypted      = "true"

  tags = {
    Name = "django-postgres-storage"
  }
}

resource "aws_efs_mount_target" "django-postgres-mount-target" {
  file_system_id = aws_efs_file_system.django-postgres-storage.id
  subnet_id      = aws_subnet.efs-subnet.id
  security_groups = [aws_security_group.k8s-efs.id]
}

output "aws_efs_file_system" {
  value = aws_efs_file_system.django-postgres-storage.id
}
