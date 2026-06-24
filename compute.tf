locals {
  dev_instance_names = ["Dev-Srv-AZ1", "Dev-Srv-AZ2"]
}

data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_lb" "public" {
  name               = "${var.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.hub_mgmt_az1.id, aws_subnet.hub_mgmt_az2.id]

  enable_deletion_protection = true

  tags = { Name = "Public-ALB" }
}

resource "aws_lb_target_group" "web" {
  name        = "${var.name_prefix}-web-tg"
  vpc_id      = aws_vpc.hub.id
  protocol    = "HTTP"
  port        = var.backend_web_port
  target_type = "ip"

  health_check {
    path                = "/index.html"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
    matcher             = "200-399"
  }

  tags = { Name = "ALB-TG" }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.public.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

resource "aws_lb_listener" "https" {
  count             = var.alb_certificate_arn == "" ? 0 : 1
  load_balancer_arn = aws_lb.public.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = var.alb_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

resource "aws_network_interface" "aruba1_wan" {
  subnet_id         = aws_subnet.hub_wan_az1.id
  security_groups   = [aws_security_group.aruba_wan.id]
  source_dest_check = false
  description       = "Aruba Node1 wan"
  tags              = { Name = "Aruba1-wan-ENI" }
}

resource "aws_network_interface" "aruba1_mgmt" {
  subnet_id         = aws_subnet.hub_mgmt_az1.id
  security_groups   = [aws_security_group.aruba_mgmt.id]
  source_dest_check = false
  description       = "Aruba Node1 mgmt"
  tags              = { Name = "Aruba1-mgmt-ENI" }
}

resource "aws_network_interface" "aruba1_lan" {
  subnet_id         = aws_subnet.hub_lan_az1.id
  security_groups   = [aws_security_group.aruba_lan.id]
  source_dest_check = false
  description       = "Aruba Node1 lan"
  tags              = { Name = "Aruba1-lan-ENI" }
}

resource "aws_network_interface" "aruba2_wan" {
  subnet_id         = aws_subnet.hub_wan_az2.id
  security_groups   = [aws_security_group.aruba_wan.id]
  source_dest_check = false
  description       = "Aruba Node2 wan"
  tags              = { Name = "Aruba2-wan-ENI" }
}

resource "aws_network_interface" "aruba2_mgmt" {
  subnet_id         = aws_subnet.hub_mgmt_az2.id
  security_groups   = [aws_security_group.aruba_mgmt.id]
  source_dest_check = false
  description       = "Aruba Node2 mgmt"
  tags              = { Name = "Aruba2-mgmt-ENI" }
}

resource "aws_network_interface" "aruba2_lan" {
  subnet_id         = aws_subnet.hub_lan_az2.id
  security_groups   = [aws_security_group.aruba_lan.id]
  source_dest_check = false
  description       = "Aruba Node2 lan"
  tags              = { Name = "Aruba2-lan-ENI" }
}

resource "aws_eip" "aruba1_mgmt" {
  domain = "vpc"
  tags   = { Name = "Aruba1-mgmt-EIP" }
}

resource "aws_eip" "aruba2_mgmt" {
  domain = "vpc"
  tags   = { Name = "Aruba2-mgmt-EIP" }
}

resource "aws_eip" "aruba1_wan" {
  domain = "vpc"
  tags   = { Name = "Aruba1-wan-EIP" }
}

resource "aws_eip" "aruba2_wan" {
  domain = "vpc"
  tags   = { Name = "Aruba2-wan-EIP" }
}

resource "aws_eip" "aruba1_lan" {
  domain = "vpc"
  tags   = { Name = "Aruba1-lan-EIP" }
}

resource "aws_eip" "aruba2_lan" {
  domain = "vpc"
  tags   = { Name = "Aruba2-lan-EIP" }
}

resource "aws_eip_association" "aruba1_mgmt" {
  allocation_id        = aws_eip.aruba1_mgmt.id
  network_interface_id = aws_network_interface.aruba1_mgmt.id
}

resource "aws_eip_association" "aruba2_mgmt" {
  allocation_id        = aws_eip.aruba2_mgmt.id
  network_interface_id = aws_network_interface.aruba2_mgmt.id
}

resource "aws_instance" "aruba1" {
  ami                     = var.aruba_ami_id
  instance_type           = var.aruba_instance_type
  key_name                = var.key_pair_name
  monitoring              = true
  disable_api_termination = true

  metadata_options {
    http_tokens                 = "optional"
    http_put_response_hop_limit = 1
  }

  network_interface {
    network_interface_id = aws_network_interface.aruba1_mgmt.id
    device_index         = 0
  }

  root_block_device {
    volume_size           = 60
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  depends_on = [aws_eip_association.aruba1_mgmt]

  tags = {
    Name = "Aruba-Node-AZ1"
    Role = "SD-WAN-Hub"
  }
}

resource "aws_instance" "aruba2" {
  ami                     = var.aruba_ami_id
  instance_type           = var.aruba_instance_type
  key_name                = var.key_pair_name
  monitoring              = true
  disable_api_termination = true

  metadata_options {
    http_tokens                 = "optional"
    http_put_response_hop_limit = 1
  }

  network_interface {
    network_interface_id = aws_network_interface.aruba2_mgmt.id
    device_index         = 0
  }

  root_block_device {
    volume_size           = 60
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  depends_on = [aws_eip_association.aruba2_mgmt]

  tags = {
    Name = "Aruba-Node-AZ2"
    Role = "SD-WAN-Hub"
  }
}

resource "aws_network_interface_attachment" "aruba1_wan" {
  instance_id          = aws_instance.aruba1.id
  network_interface_id = aws_network_interface.aruba1_wan.id
  device_index         = 1
}

resource "aws_network_interface_attachment" "aruba1_lan" {
  instance_id          = aws_instance.aruba1.id
  network_interface_id = aws_network_interface.aruba1_lan.id
  device_index         = 2
}

resource "aws_network_interface_attachment" "aruba2_wan" {
  instance_id          = aws_instance.aruba2.id
  network_interface_id = aws_network_interface.aruba2_wan.id
  device_index         = 1
}

resource "aws_network_interface_attachment" "aruba2_lan" {
  instance_id          = aws_instance.aruba2.id
  network_interface_id = aws_network_interface.aruba2_lan.id
  device_index         = 2
}

resource "aws_eip_association" "aruba1_wan" {
  allocation_id        = aws_eip.aruba1_wan.id
  network_interface_id = aws_network_interface.aruba1_wan.id
  depends_on           = [aws_network_interface_attachment.aruba1_wan]
}

resource "aws_eip_association" "aruba1_lan" {
  allocation_id        = aws_eip.aruba1_lan.id
  network_interface_id = aws_network_interface.aruba1_lan.id
  depends_on           = [aws_network_interface_attachment.aruba1_lan]
}

resource "aws_eip_association" "aruba2_wan" {
  allocation_id        = aws_eip.aruba2_wan.id
  network_interface_id = aws_network_interface.aruba2_wan.id
  depends_on           = [aws_network_interface_attachment.aruba2_wan]
}

resource "aws_eip_association" "aruba2_lan" {
  allocation_id        = aws_eip.aruba2_lan.id
  network_interface_id = aws_network_interface.aruba2_lan.id
  depends_on           = [aws_network_interface_attachment.aruba2_lan]
}

locals {
  web_page = <<-EOT
#!/bin/bash
set -e
dnf install -y httpd
systemctl enable --now httpd
TOKEN=$$(curl -sS -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
META="curl -sS -H X-aws-ec2-metadata-token:$$TOKEN http://169.254.169.254/latest/meta-data"
INSTANCE_ID=$$($$META/instance-id)
HOSTNAME=$$($$META/local-hostname)
LOCAL_IP=$$($$META/local-ipv4)
PUBLIC_IP=$$($$META/public-ipv4 || echo "Not assigned")
AZ=$$($$META/placement/availability-zone)
SUBNET_ID=$$($$META/network/interfaces/macs/$$($$META/mac)/subnet-id)
SG_NAMES=$$($$META/security-groups | paste -sd ", " -)
cat > /var/www/html/index.html <<EOF
<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>SD-WAN Web Target</title>
<style>body{margin:0;background:#eef2f6;color:#14213d;font-family:Arial,Helvetica,sans-serif}.shell{max-width:980px;margin:48px auto;padding:0 22px}.hero{background:#fff;border:1px solid #d8e0ea;border-radius:8px;box-shadow:0 12px 32px rgba(20,33,61,.12);overflow:hidden}.bar{height:8px;background:linear-gradient(90deg,#0073bb,#00a88e,#f2a900)}.content{padding:30px}h1{margin:0 0 8px;font-size:30px}.subtitle{margin:0 0 24px;color:#526275}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(230px,1fr));gap:14px}.tile{border:1px solid #d8e0ea;border-radius:8px;padding:16px;background:#f9fbfd}.label{display:block;font-size:12px;color:#66788d;text-transform:uppercase;letter-spacing:.04em;margin-bottom:6px}.value{font-size:17px;font-weight:700;overflow-wrap:anywhere}.path{margin-top:22px;padding:16px;border-radius:8px;background:#14213d;color:#fff;font-weight:700}.note{margin-top:18px;color:#526275;font-size:14px}</style>
</head><body><main class="shell"><section class="hero"><div class="bar"></div><div class="content">
<h1>SD-WAN Web Target</h1><p class="subtitle">Traffic reached this Linux web server through the Hub ALB and Transit Gateway routing.</p>
<div class="grid">
<div class="tile"><span class="label">Instance ID</span><span class="value">$$INSTANCE_ID</span></div>
<div class="tile"><span class="label">Hostname</span><span class="value">$$HOSTNAME</span></div>
<div class="tile"><span class="label">Local IP</span><span class="value">$$LOCAL_IP</span></div>
<div class="tile"><span class="label">Public IP</span><span class="value">$$PUBLIC_IP</span></div>
<div class="tile"><span class="label">Region</span><span class="value">${var.aws_region}</span></div>
<div class="tile"><span class="label">Availability Zone</span><span class="value">$$AZ</span></div>
<div class="tile"><span class="label">Subnet</span><span class="value">$$SUBNET_ID</span></div>
<div class="tile"><span class="label">Security Group Access</span><span class="value">HTTP/HTTPS from Hub ALB subnets only</span></div>
</div><div class="path">Path: Internet -> Hub ALB -> TGW -> workload VPC -> this instance</div>
<p class="note">Security groups attached: $$SG_NAMES. Apache httpd is installed from Amazon Linux 2023 repositories at deployment time.</p>
</div></section></main></body></html>
EOF
EOT
}

resource "aws_instance" "dev1" {
  ami                    = data.aws_ssm_parameter.al2023.value
  instance_type          = var.dev_instance_type
  key_name               = var.key_pair_name
  subnet_id              = aws_subnet.dev_az1.id
  vpc_security_group_ids = [aws_security_group.web_dev.id]
  monitoring             = true
  user_data              = local.web_page

  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name        = "Dev-Srv-AZ1"
    Environment = "Development"
  }
}

resource "aws_instance" "dev2" {
  ami                    = data.aws_ssm_parameter.al2023.value
  instance_type          = var.dev_instance_type
  key_name               = var.key_pair_name
  subnet_id              = aws_subnet.dev_az2.id
  vpc_security_group_ids = [aws_security_group.web_dev.id]
  monitoring             = true
  user_data              = local.web_page

  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name        = "Dev-Srv-AZ2"
    Environment = "Development"
  }
}

data "archive_file" "target_registration" {
  type        = "zip"
  source_file = "${path.module}/lambda/target_registration.py"
  output_path = "${path.module}/lambda/target_registration.zip"
}

resource "aws_iam_role" "target_registration_lambda" {
  count       = var.target_registration_lambda_role_arn == "" ? 1 : 0
  name_prefix = "${var.name_prefix}-target-reg-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "target_registration_lambda" {
  count = var.target_registration_lambda_role_arn == "" ? 1 : 0
  role  = aws_iam_role.target_registration_lambda[0].id
  name  = "TargetRegistrationPolicy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["elasticloadbalancing:RegisterTargets", "elasticloadbalancing:DeregisterTargets"]
        Resource = aws_lb_target_group.web.arn
      },
      {
        Effect   = "Allow"
        Action   = ["ec2:DescribeInstances"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["autoscaling:CompleteLifecycleAction"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_lambda_function" "target_registration" {
  function_name    = "${var.name_prefix}-target-registration"
  role             = var.target_registration_lambda_role_arn == "" ? aws_iam_role.target_registration_lambda[0].arn : var.target_registration_lambda_role_arn
  handler          = "target_registration.handler"
  runtime          = "python3.12"
  filename         = data.archive_file.target_registration.output_path
  source_code_hash = data.archive_file.target_registration.output_base64sha256
  timeout          = 60

  environment {
    variables = {
      TARGET_GROUP_ARN   = aws_lb_target_group.web.arn
      TARGET_PORT        = tostring(var.backend_web_port)
      DEV_INSTANCE_NAMES = join(",", local.dev_instance_names)
    }
  }
}

resource "aws_sns_topic" "asg_hook" {
  name = "${var.name_prefix}-asg-lifecycle-hooks"
}

resource "aws_iam_role" "asg_hook" {
  name_prefix = "${var.name_prefix}-asg-hook-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "autoscaling.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "asg_hook" {
  role = aws_iam_role.asg_hook.id
  name = "AllowSNSPublish"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "sns:Publish"
      Resource = aws_sns_topic.asg_hook.arn
    }]
  })
}

resource "aws_launch_template" "compute" {
  name_prefix   = "${var.name_prefix}-compute-"
  image_id      = data.aws_ssm_parameter.al2023.value
  instance_type = var.compute_instance_type
  key_name      = var.key_pair_name
  user_data     = base64encode(local.web_page)

  vpc_security_group_ids = [aws_security_group.web_compute.id]

  monitoring { enabled = true }

  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 8
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "Compute-ASG-Node"
      Environment = "Production"
    }
  }
}

resource "aws_autoscaling_group" "compute" {
  name                      = "${var.name_prefix}-compute-asg"
  vpc_zone_identifier       = [aws_subnet.compute_az1.id, aws_subnet.compute_az2.id]
  min_size                  = 2
  desired_capacity          = 2
  max_size                  = 4
  health_check_type         = "EC2"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.compute.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "Compute-ASG-Node"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_lifecycle_hook" "launch" {
  name                    = "${var.name_prefix}-launch"
  autoscaling_group_name  = aws_autoscaling_group.compute.name
  lifecycle_transition    = "autoscaling:EC2_INSTANCE_LAUNCHING"
  heartbeat_timeout       = 300
  default_result          = "CONTINUE"
  notification_target_arn = aws_sns_topic.asg_hook.arn
  role_arn                = aws_iam_role.asg_hook.arn
}

resource "aws_autoscaling_lifecycle_hook" "terminate" {
  name                    = "${var.name_prefix}-terminate"
  autoscaling_group_name  = aws_autoscaling_group.compute.name
  lifecycle_transition    = "autoscaling:EC2_INSTANCE_TERMINATING"
  heartbeat_timeout       = 300
  default_result          = "CONTINUE"
  notification_target_arn = aws_sns_topic.asg_hook.arn
  role_arn                = aws_iam_role.asg_hook.arn
}

resource "aws_sns_topic_subscription" "lambda" {
  topic_arn = aws_sns_topic.asg_hook.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.target_registration.arn
}

resource "aws_lambda_permission" "allow_sns" {
  statement_id  = "AllowSNSInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.target_registration.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.asg_hook.arn
}

resource "aws_cloudwatch_event_rule" "dev_instance_state" {
  name        = "${var.name_prefix}-dev-instance-state"
  description = "Register and deregister Dev web targets through Lambda."

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Instance State-change Notification"]
    detail = {
      state = ["running", "stopping", "stopped", "shutting-down", "terminated"]
    }
  })
}

resource "aws_cloudwatch_event_target" "dev_instance_state" {
  rule      = aws_cloudwatch_event_rule.dev_instance_state.name
  target_id = "TargetRegistrationLambda"
  arn       = aws_lambda_function.target_registration.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.target_registration.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.dev_instance_state.arn
}
