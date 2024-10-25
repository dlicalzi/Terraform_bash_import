#!/bin/bash

# Function to sanitize resource names
sanitize_name() {
    local name="$1"
    echo "$name" | tr ' ' '_' | tr -cd '[:alnum:]_-'
}

# Specify the output file for DynamoDB imports
OUTPUT_FILE="./terraform-imports/dynamodb_imports.tf"
mkdir -p "$(dirname "$OUTPUT_FILE")"
> "$OUTPUT_FILE"  # Clear the file if it exists

# Generate DynamoDB table import blocks
echo "Generating DynamoDB table import blocks..."
aws dynamodb list-tables --query "TableNames[]" --output json | jq -c '.[]' | while read -r table_name; do
    SANITIZED_TABLE_NAME=$(sanitize_name "$table_name")

    cat <<EOF >> "$OUTPUT_FILE"
import {
  to = aws_dynamodb_table.${SANITIZED_TABLE_NAME}
  id = "${table_name}"
}
EOF
done

echo "DynamoDB import blocks written to $OUTPUT_FILE"
