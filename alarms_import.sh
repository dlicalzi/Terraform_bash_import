#!/bin/bash

# Function to sanitize resource names
sanitize_name() {
    local name="$1"
    echo "$name" | tr ' ' '_' | tr -cd '[:alnum:]_-'
}

# Specify the output file for CloudWatch alarm imports
OUTPUT_FILE="./terraform-imports/cloudwatch_alarms_imports.tf"
mkdir -p "$(dirname "$OUTPUT_FILE")"
> "$OUTPUT_FILE"  # Clear the file if it exists

# Generate CloudWatch alarm import blocks, excluding those with "TargetTracking"
echo "Generating CloudWatch alarm import blocks..."
aws cloudwatch describe-alarms --query "MetricAlarms[?contains(AlarmName, 'TargetTracking') == \`false\`].{Name:AlarmName}" --output json | jq -c '.[]' | while read -r alarm; do
    ALARM_NAME=$(echo "$alarm" | jq -r '.Name')
    SANITIZED_NAME=$(sanitize_name "$ALARM_NAME")

    cat <<EOF >> "$OUTPUT_FILE"
import {
  to = aws_cloudwatch_metric_alarm.${SANITIZED_NAME}
  id = "${ALARM_NAME}"
}
EOF
done

echo "CloudWatch alarm import blocks written to $OUTPUT_FILE"
