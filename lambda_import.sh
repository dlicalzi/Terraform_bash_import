#!/bin/bash

# Function to sanitize resource names
sanitize_name() {
    local name="$1"
    echo "$name" | tr ' ' '_' | tr -cd '[:alnum:]_-'
}

# Specify the output file for Lambda imports
OUTPUT_FILE="./terraform-imports/lambda_imports.tf"
mkdir -p "$(dirname "$OUTPUT_FILE")"
> "$OUTPUT_FILE"  # Clear the file if it exists

# Generate Lambda function import blocks
echo "Generating Lambda function import blocks..."
aws lambda list-functions --query "Functions[*].{FunctionName:FunctionName}" --output json | jq -c '.[]' | while read -r function; do
    FUNCTION_NAME=$(echo "$function" | jq -r '.FunctionName')
    SANITIZED_FUNCTION_NAME=$(sanitize_name "$FUNCTION_NAME")

    cat <<EOF >> "$OUTPUT_FILE"
import {
  to = aws_lambda_function.${SANITIZED_FUNCTION_NAME}
  id = "${FUNCTION_NAME}"
}
EOF
done

echo "Lambda import blocks written to $OUTPUT_FILE"
