#!/bin/bash
# ============================================================
#  AWS End-to-End Security Framework
#  Phase 1: IAM Setup
#  Author: John
#  Description: Enforces strong account password policy
# ============================================================

set -e

echo "[1/2] Applying strong password policy..."
aws iam update-account-password-policy   --minimum-password-length 14   --require-symbols   --require-numbers   --require-uppercase-characters   --require-lowercase-characters   --allow-users-to-change-password   --max-password-age 90   --password-reuse-prevention 5
echo "      ✅ Password Policy Applied"

echo "[2/2] Verifying policy..."
aws iam get-account-password-policy
echo "✅ IAM SETUP COMPLETE"
