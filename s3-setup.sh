#!/bin/bash
# ============================================================
#  AWS End-to-End Security Framework
#  Phase 2: S3 Audit Vault Setup
#  Author: John
#  Description: Creates encrypted, versioned, private S3 bucket
# ============================================================

set -e

BUCKET_NAME="john-audit-logs-2026"
REGION="us-east-1"

echo "============================================================"
echo " AWS Security Framework — S3 Audit Vault Setup Starting..."
echo "============================================================"

echo ""
echo "[1/4] Creating S3 Bucket..."
aws s3api create-bucket \
  --bucket $BUCKET_NAME \
  --region $REGION
echo "      ✅ Bucket Created: $BUCKET_NAME"

echo ""
echo "[2/4] Blocking all public access..."
aws s3api put-public-access-block \
  --bucket $BUCKET_NAME \
  --public-access-block-configuration \
  "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
echo "      ✅ Public Access Blocked"

echo ""
echo "[3/4] Enabling versioning..."
aws s3api put-bucket-versioning \
  --bucket $BUCKET_NAME \
  --versioning-configuration Status=Enabled
echo "      ✅ Versioning Enabled — logs protected from deletion"

echo ""
echo "[4/4] Enabling AES-256 encryption..."
aws s3api put-bucket-encryption \
  --bucket $BUCKET_NAME \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'
echo "      ✅ Encryption Enabled — AES-256 at rest"

echo ""
echo "============================================================"
echo " ✅ S3 AUDIT VAULT COMPLETE"
echo "============================================================"
echo " Bucket:      $BUCKET_NAME"
echo " Encryption:  AES-256"
echo " Versioning:  Enabled"
echo " Public Access: Fully Blocked"
echo "============================================================"
