   # main.tf
   terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# a VPC
resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}
# Security Group for the EC2 instance
resource "aws_security_group" "web_sg" {
  name        = "web_security_group"
  description = "Allow HTTP and SSH access"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow access from anywhere (be careful with this in production)
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow SSH access
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }
}
# S3 Bucket
resource "aws_s3_bucket" "my_bucket" {
  bucket = "curalate-bucket"  
  tags = {
    Name        = "MyStaticAssetsBucket"
    Environment = "Dev"
  }
}
# S3 Bucket ACL
resource "aws_s3_bucket_acl" "my_bucket_acl" {
  bucket = aws_s3_bucket.my_bucket.bucket
  acl    = "public-read"
}
# EC2 instance
resource "aws_instance" "web_instance" {
  ami           = "ami-0c55b159cbfafe1f0"  
  instance_type = "t2.micro"  
  key_name      = "my-key-pair"  
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  # User data to install a web server and deploy files
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Hello from Terraform!</h1>" > /var/www/html/index.html
              EOF
  tags = {
    Name = "WebAppInstance"
  }
}