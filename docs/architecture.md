# Architecture

This Terraform project mirrors the working CloudFormation v4 design.

## VPCs

| VPC | CIDR | Purpose |
|---|---|---|
| Hub / SD-WAN | `10.160.0.0/16` | Aruba EdgeConnect nodes, public ALB, TGW hub attachment |
| Compute | `10.161.0.0/16` | Auto Scaling Linux web tier |
| Dev | `10.162.0.0/16` | Static Linux web servers |
| Egress | `10.163.0.0/16` | Centralized NAT egress VPC |

## Traffic Paths

Ingress:

```text
Internet -> Public ALB in Hub VPC -> TGW -> Compute / Dev private IP targets
```

Current egress:

```text
Compute / Dev -> TGW -> Egress VPC -> NAT Gateway -> Internet Gateway -> Internet
```

Important note: the Aruba EdgeConnect nodes are deployed in the Hub VPC with six total ENIs and six total public IPs. The current routing keeps the centralized NAT path through the Egress VPC. If you want all traffic inspected or forwarded inline through Aruba, add the Aruba/TGW Connect, VPN, or BGP design that makes the Aruba appliances the active next hop.

## Aruba EdgeConnect Interfaces

| Node | Interface | Subnet | Security Group | Public IP |
|---|---|---|---|---|
| Aruba 1 | Mgmt | Hub Mgmt AZ1 | Management SG | Yes |
| Aruba 1 | WAN | Hub WAN AZ1 | WAN SG | Yes |
| Aruba 1 | LAN | Hub LAN AZ1 | LAN SG | Yes |
| Aruba 2 | Mgmt | Hub Mgmt AZ2 | Management SG | Yes |
| Aruba 2 | WAN | Hub WAN AZ2 | WAN SG | Yes |
| Aruba 2 | LAN | Hub LAN AZ2 | LAN SG | Yes |

## ALB Target Registration

Compute ASG targets are registered by Lambda through ASG lifecycle hooks.

Dev EC2 targets are registered by the same Lambda through EventBridge EC2 state-change events. The Lambda checks the instance `Name` tag and registers only `Dev-Srv-AZ1` and `Dev-Srv-AZ2`.
