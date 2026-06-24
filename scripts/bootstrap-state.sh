#!/usr/bin/env bash
set -euo pipefail

trim() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

bucket="$(trim "${1:?Usage: bootstrap-state.sh <bucket> <region> [state-key]}")"
region="$(trim "${2:?Usage: bootstrap-state.sh <bucket> <region> [state-key]}")"
state_key="$(trim "${3:-sdwan/v4/terraform.tfstate}")"

if aws s3api head-bucket --bucket "$bucket" >/dev/null 2>&1; then
  echo "State bucket already exists: $bucket"
else
  echo "Creating state bucket: $bucket in $region"
  if [ "$region" = "us-east-1" ]; then
    aws s3api create-bucket --bucket "$bucket" --region "$region"
  else
    aws s3api create-bucket \
      --bucket "$bucket" \
      --region "$region" \
      --create-bucket-configuration LocationConstraint="$region"
  fi
fi

aws s3api put-public-access-block \
  --bucket "$bucket" \
  --public-access-block-configuration \
  "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

aws s3api put-bucket-ownership-controls \
  --bucket "$bucket" \
  --ownership-controls '{"Rules":[{"ObjectOwnership":"BucketOwnerEnforced"}]}'

aws s3api put-bucket-versioning \
  --bucket "$bucket" \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption \
  --bucket "$bucket" \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

cat > backend.hcl <<EOF
bucket       = "$bucket"
key          = "$state_key"
region       = "$region"
encrypt      = true
use_lockfile = true
EOF

echo "Wrote backend.hcl for s3://$bucket/$state_key"
