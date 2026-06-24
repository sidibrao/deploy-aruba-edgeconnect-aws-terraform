resource "aws_vpc" "hub" {
  cidr_block           = var.hub_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "SDWAN-Hub-VPC" }
}

resource "aws_vpc" "compute" {
  cidr_block           = var.compute_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "VPC-Compute" }
}

resource "aws_vpc" "dev" {
  cidr_block           = var.dev_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "VPC-Dev"
    Environment = "Development"
  }
}

resource "aws_vpc" "egress" {
  cidr_block           = var.egress_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "VPC-Egress" }
}

resource "aws_subnet" "hub_mgmt_az1" {
  vpc_id                  = aws_vpc.hub.id
  cidr_block              = "10.160.10.16/28"
  availability_zone       = local.az1
  map_public_ip_on_launch = true
  tags                    = { Name = "EC1-mgmt-Subnet-AZ1" }
}

resource "aws_subnet" "hub_mgmt_az2" {
  vpc_id                  = aws_vpc.hub.id
  cidr_block              = "10.160.10.64/28"
  availability_zone       = local.az2
  map_public_ip_on_launch = true
  tags                    = { Name = "EC2-mgmt-Subnet-AZ2" }
}

resource "aws_subnet" "hub_wan_az1" {
  vpc_id                  = aws_vpc.hub.id
  cidr_block              = "10.160.10.32/28"
  availability_zone       = local.az1
  map_public_ip_on_launch = true
  tags                    = { Name = "EC1-wan-Subnet-AZ1" }
}

resource "aws_subnet" "hub_wan_az2" {
  vpc_id                  = aws_vpc.hub.id
  cidr_block              = "10.160.10.80/28"
  availability_zone       = local.az2
  map_public_ip_on_launch = true
  tags                    = { Name = "EC2-wan-Subnet-AZ2" }
}

resource "aws_subnet" "hub_lan_az1" {
  vpc_id                  = aws_vpc.hub.id
  cidr_block              = "10.160.10.48/28"
  availability_zone       = local.az1
  map_public_ip_on_launch = true
  tags                    = { Name = "EC1-lan-Subnet-AZ1" }
}

resource "aws_subnet" "hub_lan_az2" {
  vpc_id                  = aws_vpc.hub.id
  cidr_block              = "10.160.10.96/28"
  availability_zone       = local.az2
  map_public_ip_on_launch = true
  tags                    = { Name = "EC2-lan-Subnet-AZ2" }
}

resource "aws_subnet" "compute_az1" {
  vpc_id                  = aws_vpc.compute.id
  cidr_block              = "10.161.1.0/24"
  availability_zone       = local.az1
  map_public_ip_on_launch = false
  tags                    = { Name = "Compute_Sub-AZ1" }
}

resource "aws_subnet" "compute_az2" {
  vpc_id                  = aws_vpc.compute.id
  cidr_block              = "10.161.2.0/24"
  availability_zone       = local.az2
  map_public_ip_on_launch = false
  tags                    = { Name = "Compute_Sub-AZ2" }
}

resource "aws_subnet" "dev_az1" {
  vpc_id                  = aws_vpc.dev.id
  cidr_block              = "10.162.1.0/24"
  availability_zone       = local.az1
  map_public_ip_on_launch = false
  tags                    = { Name = "Dev_Sub-AZ1" }
}

resource "aws_subnet" "dev_az2" {
  vpc_id                  = aws_vpc.dev.id
  cidr_block              = "10.162.2.0/24"
  availability_zone       = local.az2
  map_public_ip_on_launch = false
  tags                    = { Name = "Dev_Sub-AZ2" }
}

resource "aws_subnet" "egress_public_az1" {
  vpc_id                  = aws_vpc.egress.id
  cidr_block              = "10.163.10.0/25"
  availability_zone       = local.az1
  map_public_ip_on_launch = true
  tags                    = { Name = "Egress-Public-AZ1" }
}

resource "aws_subnet" "egress_tgw_az1" {
  vpc_id                  = aws_vpc.egress.id
  cidr_block              = "10.163.10.128/25"
  availability_zone       = local.az1
  map_public_ip_on_launch = false
  tags                    = { Name = "Egress-TGW-AZ1" }
}

resource "aws_subnet" "egress_public_az2" {
  vpc_id                  = aws_vpc.egress.id
  cidr_block              = "10.163.11.0/25"
  availability_zone       = local.az2
  map_public_ip_on_launch = true
  tags                    = { Name = "Egress-Public-AZ2" }
}

resource "aws_subnet" "egress_tgw_az2" {
  vpc_id                  = aws_vpc.egress.id
  cidr_block              = "10.163.11.128/25"
  availability_zone       = local.az2
  map_public_ip_on_launch = false
  tags                    = { Name = "Egress-TGW-AZ2" }
}

resource "aws_iam_role" "flow_logs" {
  name_prefix = "${var.name_prefix}-flowlogs-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "vpc-flow-logs.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "flow_logs" {
  name = "CloudWatchLogPolicy"
  role = aws_iam_role.flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  for_each = {
    hub     = aws_vpc.hub.id
    compute = aws_vpc.compute.id
    dev     = aws_vpc.dev.id
    egress  = aws_vpc.egress.id
  }

  name              = "/aws/vpc/flowlogs/${var.name_prefix}/${each.key}"
  retention_in_days = 30
}

resource "aws_flow_log" "vpc" {
  for_each = aws_cloudwatch_log_group.vpc_flow_logs

  iam_role_arn         = aws_iam_role.flow_logs.arn
  log_destination      = each.value.arn
  log_destination_type = "cloud-watch-logs"
  traffic_type         = "ALL"
  vpc_id               = each.key == "hub" ? aws_vpc.hub.id : each.key == "compute" ? aws_vpc.compute.id : each.key == "dev" ? aws_vpc.dev.id : aws_vpc.egress.id

  tags = { Name = "${title(each.key)}-VPC-FlowLog" }
}

resource "aws_internet_gateway" "hub" {
  vpc_id = aws_vpc.hub.id
  tags   = { Name = "Hub-IGW" }
}

resource "aws_internet_gateway" "egress" {
  vpc_id = aws_vpc.egress.id
  tags   = { Name = "Egress-IGW" }
}

resource "aws_eip" "egress_nat_az1" {
  domain = "vpc"
  tags   = { Name = "Egress-NAT-EIP-AZ1" }
}

resource "aws_eip" "egress_nat_az2" {
  domain = "vpc"
  tags   = { Name = "Egress-NAT-EIP-AZ2" }
}

resource "aws_nat_gateway" "az1" {
  allocation_id = aws_eip.egress_nat_az1.id
  subnet_id     = aws_subnet.egress_public_az1.id
  tags          = { Name = "Egress-NAT-AZ1" }
}

resource "aws_nat_gateway" "az2" {
  allocation_id = aws_eip.egress_nat_az2.id
  subnet_id     = aws_subnet.egress_public_az2.id
  tags          = { Name = "Egress-NAT-AZ2" }
}
