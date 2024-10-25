#!/bin/bash

# Function to sanitize resource names
sanitize_name() {
    local name="$1"
    echo "$name" | tr ' ' '_' | tr -cd '[:alnum:]_-'
}

# Specify the output file for IAM role import blocks
OUTPUT_FILE="./terraform-imports/iam_roles_imports.tf"
mkdir -p "$(dirname "$OUTPUT_FILE")"
> "$OUTPUT_FILE"  # Clear the file if it exists

echo "Generating IAM role import blocks..."
aws iam list-roles --query "Roles[*].{Name:RoleName}" --output json | jq -c '.[]' | while read -r role; do
    ROLE_NAME=$(echo "$role" | jq -r '.Name')
    SANITIZED_NAME=$(sanitize_name "$ROLE_NAME")

    cat <<EOF >> "$OUTPUT_FILE"
import {
  to = aws_iam_role.${SANITIZED_NAME}
  id = "${ROLE_NAME}"
}
EOF
done
echo "IAM role import blocks written to $OUTPUT_FILE"
