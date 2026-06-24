#!/usr/bin/env bash
set -euo pipefail

config_file="${1:-config/deployment.env}"

if [ ! -f "$config_file" ]; then
  echo "Missing deployment config: $config_file" >&2
  exit 1
fi

while IFS='=' read -r key value; do
  case "$key" in
    ''|\#*) continue ;;
  esac

  value="${value%$'\r'}"
  if [ -n "${GITHUB_ENV:-}" ]; then
    echo "$key=$value" >> "$GITHUB_ENV"
  else
    echo "export $key='$value'"
  fi

  if [ -n "${GITHUB_OUTPUT:-}" ]; then
    case "$key" in
      AWS_REGION) echo "aws_region=$value" >> "$GITHUB_OUTPUT" ;;
      TF_STATE_BUCKET) echo "tf_state_bucket=$value" >> "$GITHUB_OUTPUT" ;;
      TF_STATE_KEY) echo "tf_state_key=$value" >> "$GITHUB_OUTPUT" ;;
    esac
  fi
done < "$config_file"
