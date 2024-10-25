#!/bin/bash

# Function to sanitize resource names
sanitize_name() {
    local name="$1"
    echo "$name" | tr ' ' '_' | tr -cd '[:alnum:]_-'
}

# Specify the output file for EC2 import blocks
OUTPUT_FILE="./terraform-imports/ec2_imports.tf"
mkdir -p "$(dirname "$OUTPUT_FILE")"
> "$OUTPUT_FILE"  # Clear the file if it exists

echo "Generating EC2 import blocks..."
aws ec2 describe-instances --query "Reservations[*].Instances[*].{ID:InstanceId, Name:Tags[?Key=='Name']|[0].Value}" --output json | jq -c '.[][]' | while read -r instance; do
    INSTANCE_ID=$(echo "$instance" | jq -r '.ID')
    INSTANCE_NAME=$(echo "$instance" | jq -r '.Name')

    # Use a default name if the instance has no "Name" tag
    RESOURCE_NAME=${INSTANCE_NAME:-"instance_${INSTANCE_ID}"}
    SANITIZED_NAME=$(sanitize_name "$RESOURCE_NAME")

    cat <<EOF >> "$OUTPUT_FILE"
import {
  to = aws_instance.${SANITIZED_NAME}
  id = "${INSTANCE_ID}"
}
EOF
done
echo "EC2 import blocks written to $OUTPUT_FILE"