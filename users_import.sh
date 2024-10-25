#!/bin/bash

# Function to sanitize resource names
sanitize_name() {
    local name="$1"
    echo "$name" | tr ' ' '_' | tr -cd '[:alnum:]_-'
}

# Specify the output file for IAM user import blocks
OUTPUT_FILE="./terraform-imports/iam_users_imports.tf"
mkdir -p "$(dirname "$OUTPUT_FILE")"
> "$OUTPUT_FILE"  # Clear the file if it exists

echo "Generating IAM user import blocks..."
aws iam list-users --query "Users[*].{Name:UserName}" --output json | jq -c '.[]' | while read -r user; do
    USER_NAME=$(echo "$user" | jq -r '.Name')
    SANITIZED_NAME=$(sanitize_name "$USER_NAME")

    cat <<EOF >> "$OUTPUT_FILE"
import {
  to = aws_iam_user.${SANITIZED_NAME}
  id = "${USER_NAME}"
}
EOF
done
echo "IAM user import blocks written to $OUTPUT_FILE"
