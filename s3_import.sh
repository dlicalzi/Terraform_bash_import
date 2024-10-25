#!/bin/bash

# Function to sanitize resource names
sanitize_name() {
    local name="$1"
    echo "$name" | tr ' ' '_' | tr -cd '[:alnum:]_-'
}

# Specify the output file for S3 imports
OUTPUT_FILE="./terraform-imports/s3_imports.tf"
mkdir -p "$(dirname "$OUTPUT_FILE")"
> "$OUTPUT_FILE"  # Clear the file if it exists

# Generate S3 bucket import blocks
echo "Generating S3 bucket import blocks..."
aws s3api list-buckets --query "Buckets[*].{Name:Name}" --output json | jq -c '.[]' | while read -r bucket; do
    BUCKET_NAME=$(echo "$bucket" | jq -r '.Name')
    SANITIZED_BUCKET_NAME=$(sanitize_name "$BUCKET_NAME")

    cat <<EOF >> "$OUTPUT_FILE"
import {
  to = aws_s3_bucket.${SANITIZED_BUCKET_NAME}
  id = "${BUCKET_NAME}"
}
EOF

    # Generate S3 bucket policy import block
    POLICY=$(aws s3api get-bucket-policy --bucket "$BUCKET_NAME" --output json 2>/dev/null)
    if [ -n "$POLICY" ]; then
        cat <<EOF >> "$OUTPUT_FILE"
import {
  to = aws_s3_bucket_policy.${SANITIZED_BUCKET_NAME}_policy
  id = "${BUCKET_NAME}"
}
EOF
    fi

    # Generate S3 bucket lifecycle configuration import block
    LIFECYCLE=$(aws s3api get-bucket-lifecycle-configuration --bucket "$BUCKET_NAME" --output json 2>/dev/null)
    if [ -n "$LIFECYCLE" ]; then
        cat <<EOF >> "$OUTPUT_FILE"
import {
  to = aws_s3_bucket_lifecycle_configuration.${SANITIZED_BUCKET_NAME}_lifecycle
  id = "${BUCKET_NAME}"
}
EOF
    fi

    # Generate S3 bucket ACL import block
    ACL=$(aws s3api get-bucket-acl --bucket "$BUCKET_NAME" --output json 2>/dev/null)
    if [ -n "$ACL" ]; then
        cat <<EOF >> "$OUTPUT_FILE"
import {
  to = aws_s3_bucket_acl.${SANITIZED_BUCKET_NAME}_acl
  id = "${BUCKET_NAME}"
}
EOF
    fi
done

echo "S3 import blocks written to $OUTPUT_FILE"
