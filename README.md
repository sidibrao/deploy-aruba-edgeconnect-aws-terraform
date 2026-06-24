# Aruba EdgeConnect AWS Terraform Deployment

Terraform deployment for an Aruba EdgeConnect / EC-V SD-WAN lab on AWS.

This project is the Terraform version of the earlier CloudFormation-based SD-WAN
design. The topology image can be added later; for now the repository is set up
for repeatable deployment through GitHub Actions and an S3 Terraform state
backend.

## What This Builds

- Hub / SD-WAN VPC, Compute VPC, Dev VPC, and Egress VPC
- Two-AZ subnet layout in `us-east-2`
- Transit Gateway hub-spoke routing
- Centralized Egress VPC NAT path
- Two Aruba EdgeConnect / EC-V nodes
- Six Aruba ENIs and six Aruba public EIPs
- Public Application Load Balancer in the Hub VPC
- Compute Auto Scaling Group web targets
- Static Dev Linux web targets
- Lambda-based ALB target registration
- VPC Flow Logs
- S3 remote state backend support with native S3 lockfile

## Repository Structure

```text
.
├── .github/workflows/
│   ├── bootstrap-state.yml        # Creates/verifies S3 backend prerequisites
│   └── terraform.yml              # Terraform fmt, validate, plan, and apply
├── bootstrap/                     # Optional standalone Terraform state bootstrap
├── docs/
│   ├── architecture.md            # Current architecture notes
│   ├── bootstrap.md               # Manual backend bootstrap runbook
│   ├── github-actions.md          # GitHub Actions deployment setup
│   └── operations.md              # Drift and deletion-protection notes
├── lambda/
│   └── target_registration.py     # ALB target registration Lambda
├── prerequisites/
│   └── github-actions-oidc-role.yml
├── scripts/
│   ├── bootstrap-state.sh         # Idempotent S3 backend setup for CI
│   └── write-github-tfvars.sh     # Converts GitHub variables to auto.tfvars
├── backend.hcl.example            # Example S3 backend config
├── terraform.tfvars.example       # Example local deployment variables
├── versions.tf                    # Terraform/provider/backend settings
├── variables.tf
├── network.tf
├── security.tf
├── routing.tf
├── compute.tf
└── outputs.tf
```

## Recommended Deployment Path

Use GitHub Actions as the source of truth for the final deployment.

1. Configure the AWS IAM role trust policy so this repo can assume it through
   GitHub OIDC.
2. Add GitHub repository variables such as `AWS_ROLE_ARN`, `TF_STATE_BUCKET`,
   `TF_RESTRICTED_IP`, and `TF_KEY_PAIR_NAME`.
3. Run the `Bootstrap Terraform State` workflow.
4. Run the `Terraform SD-WAN` workflow with `apply = false`.
5. Review the plan.
6. Run the `Terraform SD-WAN` workflow again with `apply = true`.

See [docs/github-actions.md](docs/github-actions.md) for the complete GitHub
setup.

## Required GitHub Variables

Set these under:

```text
Settings -> Secrets and variables -> Actions -> Variables
```

| Variable | Example |
|---|---|
| `AWS_ROLE_ARN` | `arn:aws:iam::609330918629:role/<role-name>` |
| `TF_STATE_BUCKET` | `ec-sdwan-aws-s3` |
| `AWS_REGION` | `us-east-2` |
| `TF_STATE_KEY` | `sdwan/v4/terraform.tfstate` |
| `TF_NAME_PREFIX` | `sdwan-v4-lab` |
| `TF_KEY_PAIR_NAME` | `AWS-sid-EC-KP` |
| `TF_RESTRICTED_IP` | `x.x.x.x/32` |
| `TF_ARUBA_AMI_ID` | `ami-02907b22e4a6ce1bd` |

Optional variables:

```text
TF_ADMIN_EMAIL
TF_ALB_CERTIFICATE_ARN
TF_ARUBA_INSTANCE_TYPE
TF_COMPUTE_INSTANCE_TYPE
TF_DEV_INSTANCE_TYPE
TF_BACKEND_WEB_PORT
```

## Local Validation

Local commands are useful for validation and review. The final `apply` should
normally be run from GitHub Actions.

```bash
cp backend.hcl.example backend.hcl
cp terraform.tfvars.example terraform.tfvars
terraform init -backend-config=backend.hcl -reconfigure
terraform fmt -check -recursive
terraform validate
terraform plan -out sdwan.tfplan
```

Run local apply only if you intentionally want your local AWS profile to deploy:

```bash
terraform apply sdwan.tfplan
```

## State Backend

The configured state bucket for this deployment is:

```text
ec-sdwan-aws-s3
```

The default state key is:

```text
sdwan/v4/terraform.tfstate
```

Do not commit local backend or variable files:

```text
backend.hcl
terraform.tfvars
bootstrap/terraform.tfvars
.terraform/
*.tfplan
terraform.tfstate*
```

## Operations

For drift checks, deletion protection, and console-change guidance, see
[docs/operations.md](docs/operations.md).
