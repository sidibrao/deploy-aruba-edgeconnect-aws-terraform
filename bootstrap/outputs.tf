output "backend_hcl" {
  description = "Copy this into ../backend.hcl before running terraform init for the main deployment."
  value       = <<-EOT
bucket       = "${aws_s3_bucket.terraform_state.bucket}"
key          = "${var.state_key}"
region       = "${var.aws_region}"
encrypt      = true
use_lockfile = true
EOT
}

output "state_bucket_name" {
  description = "Terraform state bucket name."
  value       = aws_s3_bucket.terraform_state.bucket
}
