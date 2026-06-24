resource "aws_route_table" "hub_public" {
  vpc_id = aws_vpc.hub.id
  tags   = { Name = "Hub-Public-RT" }
}

resource "aws_route" "hub_default" {
  route_table_id         = aws_route_table.hub_public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.hub.id
}

resource "aws_route_table_association" "hub_mgmt_az1" {
  route_table_id = aws_route_table.hub_public.id
  subnet_id      = aws_subnet.hub_mgmt_az1.id
}

resource "aws_route_table_association" "hub_mgmt_az2" {
  route_table_id = aws_route_table.hub_public.id
  subnet_id      = aws_subnet.hub_mgmt_az2.id
}

resource "aws_route_table_association" "hub_wan_az1" {
  route_table_id = aws_route_table.hub_public.id
  subnet_id      = aws_subnet.hub_wan_az1.id
}

resource "aws_route_table_association" "hub_wan_az2" {
  route_table_id = aws_route_table.hub_public.id
  subnet_id      = aws_subnet.hub_wan_az2.id
}

resource "aws_route_table_association" "hub_lan_az1" {
  route_table_id = aws_route_table.hub_public.id
  subnet_id      = aws_subnet.hub_lan_az1.id
}

resource "aws_route_table_association" "hub_lan_az2" {
  route_table_id = aws_route_table.hub_public.id
  subnet_id      = aws_subnet.hub_lan_az2.id
}

resource "aws_route_table" "egress_public" {
  vpc_id = aws_vpc.egress.id
  tags   = { Name = "Egress-Public-RT" }
}

resource "aws_route" "egress_public_default" {
  route_table_id         = aws_route_table.egress_public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.egress.id
}

resource "aws_route_table_association" "egress_public_az1" {
  route_table_id = aws_route_table.egress_public.id
  subnet_id      = aws_subnet.egress_public_az1.id
}

resource "aws_route_table_association" "egress_public_az2" {
  route_table_id = aws_route_table.egress_public.id
  subnet_id      = aws_subnet.egress_public_az2.id
}

resource "aws_route_table" "egress_tgw_az1" {
  vpc_id = aws_vpc.egress.id
  tags   = { Name = "Egress-TGW-RT-AZ1" }
}

resource "aws_route_table" "egress_tgw_az2" {
  vpc_id = aws_vpc.egress.id
  tags   = { Name = "Egress-TGW-RT-AZ2" }
}

resource "aws_route" "egress_tgw_default_az1" {
  route_table_id         = aws_route_table.egress_tgw_az1.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.az1.id
}

resource "aws_route" "egress_tgw_default_az2" {
  route_table_id         = aws_route_table.egress_tgw_az2.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.az2.id
}

resource "aws_route_table_association" "egress_tgw_az1" {
  route_table_id = aws_route_table.egress_tgw_az1.id
  subnet_id      = aws_subnet.egress_tgw_az1.id
}

resource "aws_route_table_association" "egress_tgw_az2" {
  route_table_id = aws_route_table.egress_tgw_az2.id
  subnet_id      = aws_subnet.egress_tgw_az2.id
}

resource "aws_ec2_transit_gateway" "main" {
  description                     = "SD-WAN TGW"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  tags                            = { Name = "SDWAN-TGW" }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "hub" {
  vpc_id                 = aws_vpc.hub.id
  transit_gateway_id     = aws_ec2_transit_gateway.main.id
  subnet_ids             = [aws_subnet.hub_lan_az1.id, aws_subnet.hub_lan_az2.id]
  appliance_mode_support = "enable"
  tags                   = { Name = "Hub-Attach" }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "compute" {
  vpc_id             = aws_vpc.compute.id
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  subnet_ids         = [aws_subnet.compute_az1.id, aws_subnet.compute_az2.id]
  tags               = { Name = "Compute-Attach" }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "dev" {
  vpc_id             = aws_vpc.dev.id
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  subnet_ids         = [aws_subnet.dev_az1.id, aws_subnet.dev_az2.id]
  tags               = { Name = "Dev-Attach" }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "egress" {
  vpc_id             = aws_vpc.egress.id
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  subnet_ids         = [aws_subnet.egress_tgw_az1.id, aws_subnet.egress_tgw_az2.id]
  tags               = { Name = "Egress-Attach" }
}

resource "aws_ec2_transit_gateway_route_table" "spoke" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  tags               = { Name = "Spoke-RT" }
}

resource "aws_ec2_transit_gateway_route_table" "hub" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  tags               = { Name = "Hub-RT" }
}

resource "aws_ec2_transit_gateway_route_table_association" "compute" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.compute.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke.id
}

resource "aws_ec2_transit_gateway_route_table_association" "dev" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.dev.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke.id
}

resource "aws_ec2_transit_gateway_route_table_association" "hub" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.hub.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub.id
}

resource "aws_ec2_transit_gateway_route_table_association" "egress" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.egress.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub.id
}

resource "aws_ec2_transit_gateway_route" "spoke_default_to_egress" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.egress.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke.id
}

resource "aws_ec2_transit_gateway_route" "spoke_to_hub" {
  destination_cidr_block         = var.hub_vpc_cidr
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.hub.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke.id
}

resource "aws_ec2_transit_gateway_route" "hub_to_compute" {
  destination_cidr_block         = var.compute_vpc_cidr
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.compute.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub.id
}

resource "aws_ec2_transit_gateway_route" "hub_to_dev" {
  destination_cidr_block         = var.dev_vpc_cidr
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.dev.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub.id
}

resource "aws_route_table" "compute" {
  vpc_id = aws_vpc.compute.id
  tags   = { Name = "Compute-RT" }
}

resource "aws_route" "compute_default_to_tgw" {
  route_table_id         = aws_route_table.compute.id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = aws_ec2_transit_gateway.main.id
  depends_on             = [aws_ec2_transit_gateway_vpc_attachment.compute]
}

resource "aws_route_table_association" "compute_az1" {
  route_table_id = aws_route_table.compute.id
  subnet_id      = aws_subnet.compute_az1.id
}

resource "aws_route_table_association" "compute_az2" {
  route_table_id = aws_route_table.compute.id
  subnet_id      = aws_subnet.compute_az2.id
}

resource "aws_route_table" "dev" {
  vpc_id = aws_vpc.dev.id
  tags   = { Name = "Dev-RT" }
}

resource "aws_route" "dev_default_to_tgw" {
  route_table_id         = aws_route_table.dev.id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = aws_ec2_transit_gateway.main.id
  depends_on             = [aws_ec2_transit_gateway_vpc_attachment.dev]
}

resource "aws_route_table_association" "dev_az1" {
  route_table_id = aws_route_table.dev.id
  subnet_id      = aws_subnet.dev_az1.id
}

resource "aws_route_table_association" "dev_az2" {
  route_table_id = aws_route_table.dev.id
  subnet_id      = aws_subnet.dev_az2.id
}

resource "aws_route" "hub_to_compute_vpc" {
  route_table_id         = aws_route_table.hub_public.id
  destination_cidr_block = var.compute_vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.main.id
  depends_on             = [aws_ec2_transit_gateway_vpc_attachment.hub]
}

resource "aws_route" "hub_to_dev_vpc" {
  route_table_id         = aws_route_table.hub_public.id
  destination_cidr_block = var.dev_vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.main.id
  depends_on             = [aws_ec2_transit_gateway_vpc_attachment.hub]
}

locals {
  egress_return_routes = {
    hub     = var.hub_vpc_cidr
    compute = var.compute_vpc_cidr
    dev     = var.dev_vpc_cidr
  }
}

resource "aws_route" "egress_public_return" {
  for_each               = local.egress_return_routes
  route_table_id         = aws_route_table.egress_public.id
  destination_cidr_block = each.value
  transit_gateway_id     = aws_ec2_transit_gateway.main.id
  depends_on             = [aws_ec2_transit_gateway_vpc_attachment.egress]
}

resource "aws_route" "egress_tgw_az1_return" {
  for_each               = local.egress_return_routes
  route_table_id         = aws_route_table.egress_tgw_az1.id
  destination_cidr_block = each.value
  transit_gateway_id     = aws_ec2_transit_gateway.main.id
  depends_on             = [aws_ec2_transit_gateway_vpc_attachment.egress]
}

resource "aws_route" "egress_tgw_az2_return" {
  for_each               = local.egress_return_routes
  route_table_id         = aws_route_table.egress_tgw_az2.id
  destination_cidr_block = each.value
  transit_gateway_id     = aws_ec2_transit_gateway.main.id
  depends_on             = [aws_ec2_transit_gateway_vpc_attachment.egress]
}
