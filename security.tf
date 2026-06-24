resource "aws_security_group" "aruba_mgmt" {
  name        = "${var.name_prefix}-aruba-mgmt"
  description = "Aruba management - restricted admin access"
  vpc_id      = aws_vpc.hub.id

  ingress {
    description = "SSH from admin"
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = [var.restricted_ip]
  }

  ingress {
    description = "HTTP from admin"
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = [var.restricted_ip]
  }

  ingress {
    description = "HTTPS from admin"
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = [var.restricted_ip]
  }

  egress {
    description = "Allow all outbound"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "Aruba-mgmt-SG" }
}

resource "aws_security_group" "aruba_wan" {
  name        = "${var.name_prefix}-aruba-wan"
  description = "Aruba WAN - IPsec underlay"
  vpc_id      = aws_vpc.hub.id

  ingress {
    description = "IKEv2"
    protocol    = "udp"
    from_port   = 500
    to_port     = 500
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "IPsec NAT-T"
    protocol    = "udp"
    from_port   = 4500
    to_port     = 4500
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "Aruba-wan-SG" }
}

resource "aws_security_group" "aruba_lan" {
  name        = "${var.name_prefix}-aruba-lan"
  description = "Aruba LAN - lab east-west traffic"
  vpc_id      = aws_vpc.hub.id

  ingress {
    description = "Lab east-west traffic from SD-WAN VPCs"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = [var.hub_vpc_cidr, var.compute_vpc_cidr, var.dev_vpc_cidr, var.egress_vpc_cidr]
  }

  egress {
    description = "Allow all outbound"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "Aruba-lan-SG" }
}

resource "aws_security_group" "alb" {
  name        = "${var.name_prefix}-alb"
  description = "Public ALB in Hub"
  vpc_id      = aws_vpc.hub.id

  ingress {
    description = "HTTP from internet"
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from internet"
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "ALB-SG" }
}

resource "aws_security_group" "web_compute" {
  name        = "${var.name_prefix}-web-compute"
  description = "Web tier in Compute, reachable from Hub ALB subnets"
  vpc_id      = aws_vpc.compute.id

  ingress {
    description = "HTTP from ALB AZ1"
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["10.160.10.16/28"]
  }

  ingress {
    description = "HTTP from ALB AZ2"
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["10.160.10.64/28"]
  }

  ingress {
    description = "HTTPS from ALB AZ1"
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["10.160.10.16/28"]
  }

  ingress {
    description = "HTTPS from ALB AZ2"
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["10.160.10.64/28"]
  }

  egress {
    description = "Allow all outbound"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "Web-Compute-SG" }
}

resource "aws_security_group" "web_dev" {
  name        = "${var.name_prefix}-web-dev"
  description = "Web tier in Dev, reachable from Hub ALB subnets"
  vpc_id      = aws_vpc.dev.id

  ingress {
    description = "HTTP from ALB AZ1"
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["10.160.10.16/28"]
  }

  ingress {
    description = "HTTP from ALB AZ2"
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["10.160.10.64/28"]
  }

  ingress {
    description = "HTTPS from ALB AZ1"
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["10.160.10.16/28"]
  }

  ingress {
    description = "HTTPS from ALB AZ2"
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["10.160.10.64/28"]
  }

  egress {
    description = "Allow all outbound"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "Web-Dev-SG" }
}
