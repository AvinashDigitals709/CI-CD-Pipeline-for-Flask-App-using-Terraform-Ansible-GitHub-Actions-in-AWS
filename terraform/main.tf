# ---------------------------
# Security Group
# ---------------------------
resource "aws_security_group" "flask_sg" {
  name        = "${var.project_name}-sg"
  description = "Security group for Flask app"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Get default VPC
data "aws_vpc" "default" {
  default = true
}

# Get default subnet
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ---------------------------
# EC2 Instance (Ubuntu)
# ---------------------------
resource "aws_instance" "flask_server" {
  ami           = "ami-0aa7d40eeae50c9a9" # Ubuntu 22.04 us-east-1
  instance_type = "t2.micro"
  key_name      = var.key_name

  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.flask_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "${var.project_name}-server"
  }
}
