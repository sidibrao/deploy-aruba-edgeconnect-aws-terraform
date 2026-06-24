#!/usr/bin/env bash
set -euo pipefail

out="${1:-github.auto.tfvars}"
: > "$out"

trim() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

escape_hcl_string() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  printf '%s' "$value"
}

write_string() {
  local name="$1"
  local value
  value="$(trim "$2")"

  if [ -n "$value" ]; then
    value="$(escape_hcl_string "$value")"
    printf '%s = "%s"\n' "$name" "$value" >> "$out"
  fi
}

write_number() {
  local name="$1"
  local value
  value="$(trim "$2")"

  if [ -n "$value" ]; then
    printf '%s = %s\n' "$name" "$value" >> "$out"
  fi
}

write_string "aws_region" "${TF_AWS_REGION:-}"
write_string "name_prefix" "${TF_NAME_PREFIX:-}"
write_string "key_pair_name" "${TF_KEY_PAIR_NAME:-}"
write_string "restricted_ip" "${TF_RESTRICTED_IP:-}"
write_string "admin_email" "${TF_ADMIN_EMAIL:-}"
write_string "aruba_instance_type" "${TF_ARUBA_INSTANCE_TYPE:-}"
write_string "compute_instance_type" "${TF_COMPUTE_INSTANCE_TYPE:-}"
write_string "dev_instance_type" "${TF_DEV_INSTANCE_TYPE:-}"
write_string "aruba_ami_id" "${TF_ARUBA_AMI_ID:-}"
write_string "alb_certificate_arn" "${TF_ALB_CERTIFICATE_ARN:-}"
write_number "backend_web_port" "${TF_BACKEND_WEB_PORT:-}"

echo "Wrote $out"
