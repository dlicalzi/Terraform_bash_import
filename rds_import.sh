#!/bin/bash

# Function to sanitize resource names
sanitize_name() {
    local name="$1"
    # Replace spaces with underscores, keep alphanumeric characters, underscores, and dashes
    echo "$name" | tr ' ' '_' | tr -cd '[:alnum:]_-'
}

# Specify the output file for RDS import blocks
OUTPUT_FILE="./terraform-imports/rds_imports.tf"
mkdir -p "$(dirname "$OUTPUT_FILE")"
> "$OUTPUT_FILE"  # Clear the file if it exists

echo "Generating RDS import blocks..."
aws rds describe-db-instances --query "DBInstances[*].{ID:DBInstanceIdentifier, Name:DBInstanceIdentifier}" --output text | while read -r DB_INSTANCE_ID; do
    # Use the DBInstanceIdentifier directly as the resource name
    SANITIZED_NAME=$(sanitize_name "$DB_INSTANCE_ID")

    cat <<EOF >> "$OUTPUT_FILE"
import {
  to = aws_db_instance.${SANITIZED_NAME}
  id = "${DB_INSTANCE_ID}"
}
EOF
done
echo "RDS import blocks written to $OUTPUT_FILE"