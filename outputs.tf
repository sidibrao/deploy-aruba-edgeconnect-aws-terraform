output "alb_dns_name" {
  description = "Public ALB DNS name."
  value       = aws_lb.public.dns_name
}

output "transit_gateway_id" {
  description = "Transit Gateway ID."
  value       = aws_ec2_transit_gateway.main.id
}

output "tgw_vpn_connection_ids" {
  description = "Terraform-managed TGW VPN connection IDs."
  value       = { for name, vpn in aws_vpn_connection.tgw : name => vpn.id }
}

output "tgw_vpn_attachment_ids" {
  description = "Terraform-managed TGW VPN attachment IDs."
  value       = { for name, vpn in aws_vpn_connection.tgw : name => vpn.transit_gateway_attachment_id }
}

output "tgw_vpn_tunnel_addresses" {
  description = "Terraform-managed VPN tunnel outside addresses."
  value = {
    for name, vpn in aws_vpn_connection.tgw : name => {
      tunnel1_address = vpn.tunnel1_address
      tunnel2_address = vpn.tunnel2_address
    }
  }
}

output "aruba_node_1_mgmt_eip" {
  description = "Aruba Node 1 management public IP."
  value       = aws_eip.aruba1_mgmt.public_ip
}

output "aruba_node_2_mgmt_eip" {
  description = "Aruba Node 2 management public IP."
  value       = aws_eip.aruba2_mgmt.public_ip
}

output "aruba_node_1_wan_eip" {
  description = "Aruba Node 1 WAN public IP."
  value       = aws_eip.aruba1_wan.public_ip
}

output "aruba_node_2_wan_eip" {
  description = "Aruba Node 2 WAN public IP."
  value       = aws_eip.aruba2_wan.public_ip
}

output "aruba_node_1_lan_eip" {
  description = "Aruba Node 1 LAN public IP."
  value       = aws_eip.aruba1_lan.public_ip
}

output "aruba_node_2_lan_eip" {
  description = "Aruba Node 2 LAN public IP."
  value       = aws_eip.aruba2_lan.public_ip
}

output "egress_nat_az1_eip" {
  description = "Egress NAT Gateway AZ1 public IP."
  value       = aws_eip.egress_nat_az1.public_ip
}

output "egress_nat_az2_eip" {
  description = "Egress NAT Gateway AZ2 public IP."
  value       = aws_eip.egress_nat_az2.public_ip
}

output "target_registration_lambda_name" {
  description = "Lambda function used for ALB target registration."
  value       = aws_lambda_function.target_registration.function_name
}
