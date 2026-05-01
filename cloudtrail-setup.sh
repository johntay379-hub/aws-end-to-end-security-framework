#!/bin/bash
# ============================================================
#  AWS End-to-End Security Framework
#  Phase 3: CloudTrail Setup
#  Author: John
#  Description: Creates multi-region tamper-proof audit trail
# ============================================================

set -e

BUCKET_NAME="john-audit-logs-2026"
TRAIL_NAME="john-security-trail"
ACCOUNT_ID="506234426979"

echo "[1/2] Creating CloudTrail..."
aws cloudtrail create-trail \ 
  --name $TRAIL_NAME   --s3-bucket-name $BUCKET_NAME   --s3-key-prefix cloudtrail   --include-global-service-events   --is-multi-region-trail   --enable-log-file-validation
echo "      ✅ Trail Created"

echo "[2/2] Starting logging..."
aws cloudtrail start-logging --name $TRAIL_NAME
echo "✅ CLOUDTRAIL SETUP COMPLETE"
