#!/bin/bash
# Phase 6: CloudWatch + SNS
# Author: John

set -e

REGION="us-east-1"
PROJECT="john-security"
SNS_TOPIC_ARN="arn:aws:sns:us-east-1:506234426979:john-security-alerts"
INSTANCE_ID="i-0d12076192812f43a"

echo "[1/2] Creating CPU Alarm..."
aws cloudwatch put-metric-alarm \
  --alarm-name "$PROJECT-high-cpu" \
  --metric-name CPUUtilization \
  --namespace AWS/EC2 \
  --statistic Average \
  --dimensions Name=InstanceId,Value=$INSTANCE_ID \
  --period 300 \
  --evaluation-periods 2 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --alarm-actions $SNS_TOPIC_ARN \
  --region $REGION
echo "      ✅ CPU Alarm Created"

echo "[2/2] Creating Status Check Alarm..."
aws cloudwatch put-metric-alarm \
  --alarm-name "$PROJECT-instance-status-check" \
  --metric-name StatusCheckFailed \
  --namespace AWS/EC2 \
  --statistic Maximum \
  --dimensions Name=InstanceId,Value=$INSTANCE_ID \
  --period 60 \
  --evaluation-periods 2 \
  --threshold 1 \
  --comparison-operator GreaterThanOrEqualToThreshold \
  --alarm-actions $SNS_TOPIC_ARN \
  --region $REGION
echo "      ✅ Status Check Alarm Created"
echo "✅ CLOUDWATCH + SNS COMPLETE"
