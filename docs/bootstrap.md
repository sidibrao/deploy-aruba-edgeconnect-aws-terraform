# Bootstrap Terraform State

The main SD-WAN deployment uses an S3 backend, so the state bucket must exist before
you run `terraform init` in the repository root.

## What Bootstrap Creates

- S3 bucket for Terraform state
- S3 versioning
- S3-managed encryption
- Public access block
- Bucket-owner-enforced object ownership
- Native S3 state locking support through `use_lockfile = true`
- `prevent_destroy` on the state bucket

## Run Bootstrap

From the repository root:

```bash
cd bootstrap
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and set a globally unique `state_bucket_name`.

Then run:

```bash
terraform init
terraform validate
terraform plan -out bootstrap.tfplan
terraform apply bootstrap.tfplan
terraform output -raw backend_hcl > ../backend.hcl
cd ..
```

Now initialize the main deployment:

```bash
terraform init -backend-config=backend.hcl
terraform validate
terraform plan -out sdwan.tfplan
terraform apply sdwan.tfplan
```

## Notes

The bootstrap module intentionally uses local state at first. After it creates the
remote state bucket, you can leave the small bootstrap state local or migrate it to
a separate backend key such as `sdwan/bootstrap/terraform.tfstate`.
