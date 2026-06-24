# Operations Guide

## Protecting the Deployment from Accidental Deletion

Use more than one control. No single setting protects everything.

1. Enable deletion protection where the service supports it.
   - Terraform sets `disable_api_termination = true` for both Aruba EC2 nodes.
   - Terraform sets `enable_deletion_protection = true` for the public ALB.

2. Protect Terraform state.
   - Use S3 versioning on the backend bucket.
   - Enable S3 bucket encryption.
   - Restrict who can delete objects from the state bucket.
   - Use `use_lockfile = true` in the backend config.

3. Restrict destructive AWS permissions.
   - Deny `cloudformation:DeleteStack`, `ec2:TerminateInstances`, `ec2:DeleteTransitGateway`, `elasticloadbalancing:DeleteLoadBalancer`, and `s3:DeleteObject` for normal users.
   - Allow destructive actions only through a break-glass/admin role.

4. Add Terraform lifecycle guards for critical resources if needed.
   - For production, add `lifecycle { prevent_destroy = true }` to TGW, VPCs, Aruba EC2 nodes, and ALB.
   - Keep this off during lab iteration unless you are comfortable removing it before destroy.

## Drift and Console Change Control

Console changes create drift. Terraform will detect most drift when you run:

```powershell
terraform plan -detailed-exitcode
```

Exit code meanings:

- `0`: no changes
- `1`: error
- `2`: drift or planned changes detected

Recommended automation:

1. Run `terraform plan -detailed-exitcode` on a schedule in GitHub Actions.
2. If exit code is `2`, create an issue or pull request with the plan output.
3. Review the change:
   - If the console change is valid, import or codify it in Terraform.
   - If the console change is not approved, revert it through Terraform apply.

Manual one-time drift check:

```powershell
terraform init -backend-config=backend.hcl
terraform plan -detailed-exitcode
```

## Console Changes: Accept or Reject

Option 1: Reject console changes.

```powershell
terraform plan
terraform apply
```

This pushes the repo-defined state back into AWS.

Option 2: Accept console changes.

Update Terraform code to match the console change, or import the new resource:

```powershell
terraform import <resource_address> <aws_resource_id>
terraform plan
```

Then commit the updated Terraform code and state alignment.

## CloudFormation Stack Protection Notes

For the CloudFormation version, enable stack termination protection:

```powershell
aws cloudformation update-termination-protection `
  --stack-name <STACK_NAME> `
  --enable-termination-protection
```

Also use a stack policy to deny accidental replacement/deletion of critical resources such as VPCs, TGW, Aruba EC2 instances, EIPs, and ALB. IAM controls should deny normal users from deleting stacks directly.
