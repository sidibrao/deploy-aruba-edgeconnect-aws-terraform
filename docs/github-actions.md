# GitHub Actions Deployment

This repository is prepared to deploy through GitHub Actions using:

```yaml
uses: sidibrao/configure-aws-credentials-sid@main
```

That action configures AWS credentials for later `aws` and `terraform` steps.
The workflows use GitHub OIDC, so no long-lived AWS access key is stored in the
repository.

## Required AWS Prerequisite

Create a GitHub Actions OIDC role in AWS that trusts this repository. This repo
includes a ready CloudFormation prerequisite template:

```bash
aws cloudformation deploy \
  --stack-name sdwan-github-actions-oidc \
  --template-file prerequisites/github-actions-oidc-role.yml \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    GitHubOrganization=sidibrao \
    RepositoryName=deploy-aruba-edgeconnect-aws-treeaform \
    BranchName=main \
    RoleName=sdwan-terraform-github-actions \
    UseExistingProvider=no
```

If an OIDC provider for `token.actions.githubusercontent.com` already exists in
the AWS account, set `UseExistingProvider=yes`.

The linked credentials action also includes CloudFormation examples for this:

```text
https://github.com/sidibrao/configure-aws-credentials-sid/tree/main/examples/federated-setup
```

For this SD-WAN lab, the role needs enough permission to create the bootstrap S3
state bucket and the full SD-WAN stack. Start with a tightly controlled admin or
power-user role while validating the lab, then reduce permissions after the first
successful plan.

Recommended trust inputs for this repository:

```text
GitHubOrganization = sidibrao
RepositoryName     = deploy-aruba-edgeconnect-aws-treeaform
BranchName         = main
RoleName           = sdwan-terraform-github-actions
```

## Required Repository Variables

Set these in GitHub under `Settings -> Secrets and variables -> Actions -> Variables`.

| Variable | Required | Example |
|---|---:|---|
| `AWS_ROLE_ARN` | Yes | `arn:aws:iam::609330918629:role/sdwan-terraform-github-actions` |
| `TF_STATE_BUCKET` | Yes | `homeys3f1` |
| `AWS_REGION` | No | `us-east-2` |
| `TF_STATE_KEY` | No | `sdwan/v4/terraform.tfstate` |
| `TF_NAME_PREFIX` | No | `sdwan-v4-lab` |
| `TF_KEY_PAIR_NAME` | Recommended | `AWS-sid-EC-KP` |
| `TF_RESTRICTED_IP` | Recommended | `184.147.66.76/32` |
| `TF_ARUBA_AMI_ID` | Recommended | `ami-02907b22e4a6ce1bd` |
| `TF_ALB_CERTIFICATE_ARN` | Optional | ACM certificate ARN for HTTPS |

Other optional variables supported by the workflow:

```text
TF_ADMIN_EMAIL
TF_ARUBA_INSTANCE_TYPE
TF_COMPUTE_INSTANCE_TYPE
TF_DEV_INSTANCE_TYPE
TF_BACKEND_WEB_PORT
```

## Workflows

`Bootstrap Terraform State`

- Manual workflow.
- Creates or updates the S3 backend bucket prerequisites.
- Safe to run more than once.

`Terraform SD-WAN`

- Runs `fmt`, `validate`, and `plan` on pull requests and pushes to `main`.
- Also makes sure the backend bucket settings are present.
- Applies only when manually dispatched with `apply = true`.

## First Run

1. Create the AWS OIDC role.
2. Set the required GitHub repository variables.
3. Run `Bootstrap Terraform State`.
4. Run `Terraform SD-WAN` with `apply = false` and review the plan.
5. Run `Terraform SD-WAN` with `apply = true` when the plan looks correct.
