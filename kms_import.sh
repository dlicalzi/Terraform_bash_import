#!/bin/bash

# Function to sanitize resource names
sanitize_name() {
    local name="$1"
    echo "$name" | tr ' ' '_' | tr -cd '[:alnum:]_-'
}

# Specify the output file for KMS imports
OUTPUT_FILE="./terraform-imports/kms_imports.tf"
mkdir -p "$(dirname "$OUTPUT_FILE")"
> "$OUTPUT_FILE"  # Clear the file if it exists

# Generate KMS key import blocks
echo "Generating KMS key import blocks..."
aws kms list-keys --query "Keys[*].KeyId" --output json | jq -c '.[]' | while read -r key_id; do
    SANITIZED_NAME=$(sanitize_name "$key_id")

    cat <<EOF >> "$OUTPUT_FILE"
import {
  to = aws_kms_key.${SANITIZED_NAME}
  id = "${key_id}"
}
EOF
done

# Generate KMS alias import blocks
echo "Generating KMS alias import blocks..."
aws kms list-aliases --query "Aliases[*].{AliasName:AliasName}" --output json | jq -c '.[]' | while read -r alias; do
    ALIAS_NAME=$(echo "$alias" | jq -r '.AliasName')
    SANITIZED_NAME=$(sanitize_name "$ALIAS_NAME")

    # The ID format for KMS aliases should include the prefix "alias/"
    cat <<EOF >> "$OUTPUT_FILE"
import {
  to = aws_kms_alias.${SANITIZED_NAME}
  id = "alias/${ALIAS_NAME}"
}
EOF
done

echo "KMS import blocks written to $OUTPUT_FILE"
