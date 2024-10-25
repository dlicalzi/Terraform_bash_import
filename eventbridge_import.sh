#!/bin/bash

# Function to sanitize resource names
sanitize_name() {
    local name="$1"
    echo "$name" | tr ' ' '_' | tr -cd '[:alnum:]_-'
}

# Specify the output file for EventBridge imports
OUTPUT_FILE="./terraform-imports/eventbridge_imports.tf"
mkdir -p "$(dirname "$OUTPUT_FILE")"
> "$OUTPUT_FILE"  # Clear the file if it exists

# Generate EventBridge rule import blocks
echo "Generating EventBridge rule import blocks..."
aws events list-rules --query "Rules[*].{Name:Name}" --output json | jq -c '.[]' | while read -r rule; do
    RULE_NAME=$(echo "$rule" | jq -r '.Name')
    SANITIZED_RULE_NAME=$(sanitize_name "$RULE_NAME")

    cat <<EOF >> "$OUTPUT_FILE"
import {
  to = aws_cloudwatch_event_rule.${SANITIZED_RULE_NAME}
  id = "${RULE_NAME}"
}
EOF

    # Generate EventBridge target import blocks for each rule
    echo "Generating targets for rule: $RULE_NAME..."
    aws events list-targets-by-rule --rule "$RULE_NAME" --query "Targets[*].{Id:Id}" --output json | jq -c '.[]' | while read -r target; do
        TARGET_ID=$(echo "$target" | jq -r '.Id')
        SANITIZED_TARGET_NAME=$(sanitize_name "$TARGET_ID")

        # The ID format for targets should be "rule-name/target-id"
        cat <<EOF >> "$OUTPUT_FILE"
import {
  to = aws_cloudwatch_event_target.${SANITIZED_TARGET_NAME}
  id = "${RULE_NAME}/${TARGET_ID}"
}
EOF
    done
done

echo "EventBridge import blocks written to $OUTPUT_FILE"
