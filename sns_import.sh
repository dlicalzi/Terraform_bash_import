#!/bin/bash

# Function to sanitize resource names
sanitize_name() {
    local name="$1"
    echo "$name" | tr ' ' '_' | tr -cd '[:alnum:]_-'
}

# Specify the output file for SNS imports
OUTPUT_FILE="./terraform-imports/sns_imports.tf"
mkdir -p "$(dirname "$OUTPUT_FILE")"
> "$OUTPUT_FILE"  # Clear the file if it exists

# Generate SNS topic import blocks
echo "Generating SNS topic import blocks..."
aws sns list-topics --query "Topics[*].{TopicArn:TopicArn}" --output json | jq -c '.[]' | while read -r topic; do
    TOPIC_ARN=$(echo "$topic" | jq -r '.TopicArn')
    TOPIC_NAME=$(basename "$TOPIC_ARN")  # Extract topic name from ARN
    SANITIZED_TOPIC_NAME=$(sanitize_name "$TOPIC_NAME")

    cat <<EOF >> "$OUTPUT_FILE"
import {
  to = aws_sns_topic.${SANITIZED_TOPIC_NAME}
  id = "${TOPIC_ARN}"
}
EOF
done

# Generate SNS subscription import blocks
echo "Generating SNS subscription import blocks..."
aws sns list-subscriptions --query "Subscriptions[*].{SubscriptionArn:SubscriptionArn, TopicArn:TopicArn}" --output json | jq -c '.[]' | while read -r subscription; do
    SUBSCRIPTION_ARN=$(echo "$subscription" | jq -r '.SubscriptionArn')
    TOPIC_ARN=$(echo "$subscription" | jq -r '.TopicArn')
    TOPIC_NAME=$(basename "$TOPIC_ARN")  # Extract topic name from ARN
    SANITIZED_SUBSCRIPTION_NAME=$(sanitize_name "${SUBSCRIPTION_ARN##*:}")  # Extract and sanitize the subscription ID

    # The ID format for subscriptions should be "topic_name/subscription_arn"
    cat <<EOF >> "$OUTPUT_FILE"
import {
  to = aws_sns_subscription.${SANITIZED_SUBSCRIPTION_NAME}
  id = "${SUBSCRIPTION_ARN}"
}
EOF
done

echo "SNS import blocks written to $OUTPUT_FILE"
