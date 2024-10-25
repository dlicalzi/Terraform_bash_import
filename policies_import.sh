#!/bin/bash

# Function to sanitize resource names
sanitize_name() {
    local name="$1"
    echo "$name" | tr ' ' '_' | tr -cd '[:alnum:]_-'
}

# Specify the output file for IAM policy import blocks
OUTPUT_FILE="./terraform-imports/iam_policies_imports.tf"
mkdir -p "$(dirname "$OUTPUT_FILE")"
> "$OUTPUT_FILE"  # Clear the file if it exists

echo "Generating IAM policy import blocks..."
aws iam list-policies --query "Policies[*].{Name:PolicyName, ARN:Arn}" --output json | jq -c '.[]' | while read -r policy; do
    POLICY_NAME=$(echo "$policy" | jq -r '.Name')
    POLICY_ARN=$(echo "$policy" | jq -r '.ARN')
    SANITIZED_NAME=$(sanitize_name "$POLICY_NAME")

    cat <<EOF >> "$OUTPUT_FILE"
import {
  to = aws_iam_policy.${SANITIZED_NAME}
  id = "${POLICY_ARN}"
}
EOF
done
echo "IAM policy import blocks written to $OUTPUT_FILE"
