#!/bin/bash
# ============================================================
#  AWS End-to-End Security Framework
#  TEARDOWN — Delete all resources
#  WARNING: This is irreversible!
# ============================================================

set -e
source ~/Documents/aws-end-to-end-security-framework/vpc-outputs.env
REGION="us-east-1"

echo "============================================================"
echo " WARNING: Deleting all AWS resources..."
echo "============================================================"

echo ""
echo "[1/8] Terminating EC2 instance..."
aws ec2 terminate-instances --instance-ids $INSTANCE_ID --region $REGION
aws ec2 wait instance-terminated --instance-ids $INSTANCE_ID
echo "      ✅ EC2 terminated"

echo ""
echo "[2/8] Releasing Elastic IP..."
aws ec2 release-address --allocation-id $ALLOCATION_ID --region $REGION
echo "      ✅ Elastic IP released"

echo ""
echo "[3/8] Deleting CloudWatch alarms..."
aws cloudwatch delete-alarms --alarm-names john-security-high-cpu john-security-instance-status-check john-security-iam-policy-change --region $REGION
echo "      ✅ CloudWatch alarms deleted"

echo ""
echo "[4/8] Deleting SNS topic..."
aws sns delete-topic --topic-arn arn:aws:sns:us-east-1:506234426979:john-security-alerts --region $REGION
echo "      ✅ SNS topic deleted"

echo ""
echo "[5/8] Stopping CloudTrail..."
aws cloudtrail stop-logging --name john-security-trail --region $REGION
aws cloudtrail delete-trail --name john-security-trail --region $REGION
echo "      ✅ CloudTrail deleted"

echo ""
echo "[6/8] Deleting Security Groups..."
aws ec2 delete-security-group --group-id $WEB_SG_ID --region $REGION
aws ec2 delete-security-group --group-id $BASTION_SG_ID --region $REGION
echo "      ✅ Security groups deleted"

echo ""
echo "[7/8] Deleting Subnets, IGW, Route Table, VPC..."
aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID --region $REGION
aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID --region $REGION
aws ec2 delete-subnet --subnet-id $PUBLIC_SUBNET_ID --region $REGION
aws ec2 delete-route-table --route-table-id $PUBLIC_RT_ID --region $REGION
aws ec2 delete-vpc --vpc-id $VPC_ID --region $REGION
echo "      ✅ VPC and networking deleted"

echo ""
echo "[8/8] Emptying and deleting S3 bucket..."
aws s3 rm s3://john-audit-logs-2026 --recursive
aws s3api delete-bucket --bucket john-audit-logs-2026 --region $REGION
echo "      ✅ S3 bucket deleted"

echo ""
echo "============================================================"
echo " ✅ ALL RESOURCES DELETED — No more charges!"
echo "============================================================"
