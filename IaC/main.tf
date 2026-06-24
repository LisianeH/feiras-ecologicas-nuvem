terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "${local.name_prefix}-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${local.name_prefix}-igw"
  }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
  tags = {
    Name = "${local.name_prefix}-subnet-a"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true
  tags = {
    Name = "${local.name_prefix}-subnet-b"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${local.name_prefix}-public-rt"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "frontend" {
  name        = "${local.name_prefix}-frontend-sg"
  description = "Security group for frontend EC2"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "Allow HTTP to frontend"
    from_port        = 3000
    to_port          = 3000
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  dynamic "ingress" {
    for_each = var.allowed_ssh_cidr_blocks
    content {
      description = "Allow SSH access"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-frontend-sg"
  }
}

resource "aws_security_group" "backend" {
  name        = "${local.name_prefix}-backend-sg"
  description = "Security group for backend EC2"
  vpc_id      = aws_vpc.main.id

  ingress {
    description                = "Allow frontend to call backend API"
    from_port                  = 4000
    to_port                    = 4000
    protocol                   = "tcp"
    security_groups            = [aws_security_group.frontend.id]
  }

  dynamic "ingress" {
    for_each = var.allowed_ssh_cidr_blocks
    content {
      description = "Allow SSH access"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  ingress {
    description = "Allow backend to reach RDS MySQL"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.backend.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-backend-sg"
  }
}

resource "aws_security_group" "rds" {
  name        = "${local.name_prefix}-rds-sg"
  description = "Security group for RDS MySQL"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow backend EC2 to connect to MySQL"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.backend.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-rds-sg"
  }
}

resource "aws_db_subnet_group" "main" {
  name       = "${local.name_prefix}-db-subnet-group"
  subnet_ids = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  tags = {
    Name = "${local.name_prefix}-db-subnet-group"
  }
}

resource "aws_db_instance" "mysql" {
  identifier              = "${local.name_prefix}-db"
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = var.db_instance_class
  allocated_storage       = 20
  storage_type            = "gp2"
  name                    = var.db_name
  username                = var.db_username
  password                = var.db_password
  publicly_accessible     = false
  vpc_security_group_ids  = [aws_security_group.rds.id]
  db_subnet_group_name    = aws_db_subnet_group.main.name
  skip_final_snapshot     = true
  apply_immediately       = true
  deletion_protection     = false
  backup_retention_period = 7
  tags = {
    Name = "${local.name_prefix}-db"
  }
}

resource "aws_sqs_queue" "contact_queue" {
  name                      = "${local.name_prefix}-contact-queue"
  visibility_timeout_seconds = 30
  message_retention_seconds = 345600
  tags = {
    Name = "${local.name_prefix}-contact-queue"
  }
}

resource "aws_sns_topic" "notifications" {
  name = "${local.name_prefix}-notifications-topic"

  tags = {
    Name = "${local.name_prefix}-notifications-topic"
  }
}

resource "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_cloudwatch" {
  name               = "${local.name_prefix}-ec2-cloudwatch-role"
  assume_role_policy = aws_iam_policy_document.ec2_assume_role.json
  tags = {
    Name = "${local.name_prefix}-ec2-cloudwatch-role"
  }
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent_policy" {
  role       = aws_iam_role.ec2_cloudwatch.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${local.name_prefix}-ec2-profile"
  role = aws_iam_role.ec2_cloudwatch.name
}

resource "aws_instance" "frontend" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.frontend_instance_type
  subnet_id                   = aws_subnet.public_a.id
  vpc_security_group_ids      = [aws_security_group.frontend.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = true
  key_name                    = var.key_name != "" ? var.key_name : null
  user_data                   = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y git
              EOF

  tags = {
    Name = "${local.name_prefix}-frontend"
  }
}

resource "aws_instance" "backend" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.backend_instance_type
  subnet_id                   = aws_subnet.public_b.id
  vpc_security_group_ids      = [aws_security_group.backend.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = true
  key_name                    = var.key_name != "" ? var.key_name : null
  user_data                   = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y git
              EOF

  tags = {
    Name = "${local.name_prefix}-backend"
  }
}
