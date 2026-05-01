#!/bin/bash
# ============================================================
#  AWS End-to-End Security Framework
#  Phase 5: EC2 Web Server Setup
#  Author: John
#  Description: Automates Key Pair, EC2, Apache, Elastic IP
# ============================================================

set -e  # Exit immediately if any command fails

# ─────────────────────────────────────────
# CONFIGURATION — Load VPC outputs from Phase 4
# ─────────────────────────────────────────
source ~/Documents/aws-end-to-end-security-framework/vpc-outputs.env

REGION="us-east-1"
PROJECT="john-security"
KEY_NAME="john-security-key"
INSTANCE_TYPE="t2.micro"  # Free tier eligible

# Latest Amazon Linux 2023 AMI in us-east-1
AMI_ID="ami-0c02fb55956c7d316"

echo "============================================================"
echo " AWS Security Framework — EC2 Setup Starting..."
echo "============================================================"

# ─────────────────────────────────────────
# STEP 1: Create Key Pair
# What it does: Generates an SSH key pair. The private key (.pem)
# is saved locally and is the ONLY way to SSH into your EC2.
# AWS stores the public key. Keep your .pem file safe — if lost,
# you lose access to the instance permanently.
# ─────────────────────────────────────────
echo ""
echo "[1/6] Creating Key Pair..."
aws ec2 create-key-pair \
  --key-name $KEY_NAME \
  --query 'KeyMaterial' \
  --output text > ~/$KEY_NAME.pem

# Set correct permissions — SSH refuses keys that are too open
chmod 400 ~/$KEY_NAME.pem
echo "      ✅ Key Pair Created: ~/$KEY_NAME.pem"
echo "      ✅ Permissions set to 400 (read-only by owner)"

# ─────────────────────────────────────────
# STEP 2: Create IAM Role for EC2
# What it does: Gives the EC2 instance permission to send logs
# to CloudWatch and access S3 — without hardcoding credentials.
# This is the secure, professional way to grant EC2 permissions.
# ─────────────────────────────────────────
echo ""
echo "[2/6] Creating IAM Role for EC2..."

# Trust policy — allows EC2 service to assume this role
cat > /tmp/ec2-trust-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# Create the role
aws iam create-role \
  --role-name $PROJECT-ec2-role \
  --assume-role-policy-document file:///tmp/ec2-trust-policy.json \
  --description "Least privilege role for EC2 web server" > /dev/null

# Attach CloudWatch agent policy — allows EC2 to send metrics & logs
aws iam attach-role-policy \
  --role-name $PROJECT-ec2-role \
  --policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy

# Attach SSM policy — allows secure remote access without SSH if needed
aws iam attach-role-policy \
  --role-name $PROJECT-ec2-role \
  --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore

echo "      ✅ IAM Role Created: $PROJECT-ec2-role"
echo "      ✅ CloudWatch Policy Attached"
echo "      ✅ SSM Policy Attached"

# Create instance profile — wraps the role so EC2 can use it
aws iam create-instance-profile \
  --instance-profile-name $PROJECT-ec2-profile > /dev/null

aws iam add-role-to-instance-profile \
  --instance-profile-name $PROJECT-ec2-profile \
  --role-name $PROJECT-ec2-role

echo "      ✅ Instance Profile Created & Role Attached"

# Wait for profile to propagate
echo "      ⏳ Waiting 10s for IAM profile to propagate..."
sleep 10

# ─────────────────────────────────────────
# STEP 3: Launch EC2 Web Server
# What it does: Launches a t2.micro EC2 instance (free tier)
# in the public subnet. The User Data script runs automatically
# on first boot — it installs and starts Apache web server,
# then creates a custom security-themed homepage.
# ─────────────────────────────────────────
echo ""
echo "[3/6] Launching EC2 Web Server..."

# User Data script — runs on first boot as root
USER_DATA=$(cat << 'USERDATA'
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd

# Create a security-themed homepage
cat > /var/www/html/index.html << 'HTML'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>AWS Security Framework</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: 'Courier New', monospace;
      background: #0a0a0a;
      color: #00ff41;
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
    }
    .container {
      text-align: center;
      padding: 40px;
      border: 1px solid #00ff41;
      max-width: 700px;
      box-shadow: 0 0 30px #00ff4144;
    }
    h1 { font-size: 2rem; margin-bottom: 10px; }
    .subtitle { color: #888; margin-bottom: 30px; font-size: 0.9rem; }
    .status { 
      background: #111; 
      padding: 20px; 
      border-left: 3px solid #00ff41;
      text-align: left;
      margin: 10px 0;
    }
    .badge { color: #00ff41; margin-right: 10px; }
    footer { margin-top: 30px; color: #555; font-size: 0.8rem; }
  </style>
</head>
<body>
  <div class="container">
    <h1>🔒 AWS Security Framework</h1>
    <p class="subtitle">End-to-End Security Deployment — Built by John</p>
    <div class="status"><span class="badge">✅</span> IAM — Least Privilege Enforced</div>
    <div class="status"><span class="badge">✅</span> S3 — Encrypted Audit Vault Active</div>
    <div class="status"><span class="badge">✅</span> CloudTrail — All API Events Logged</div>
    <div class="status"><span class="badge">✅</span> VPC — Network Isolated & Secured</div>
    <div class="status"><span class="badge">✅</span> EC2 — Hardened Web Server Running</div>
    <div class="status"><span class="badge">✅</span> CloudWatch + SNS — Monitoring Active</div>
    <footer>Deployed via AWS CLI | Region: us-east-1 | Architecture: Security-First</footer>
  </div>
</body>
</html>
HTML
USERDATA
)

INSTANCE_ID=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --instance-type $INSTANCE_TYPE \
  --key-name $KEY_NAME \
  --subnet-id $PUBLIC_SUBNET_ID \
  --security-group-ids $WEB_SG_ID \
  --iam-instance-profile Name=$PROJECT-ec2-profile \
  --user-data "$USER_DATA" \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$PROJECT-web-server}]" \
  --metadata-options "HttpTokens=required,HttpEndpoint=enabled" \
  --query 'Instances[0].InstanceId' \
  --output text)

echo "      ✅ EC2 Instance Launched: $INSTANCE_ID"
echo "      ⏳ Waiting for instance to be running..."

aws ec2 wait instance-running --instance-ids $INSTANCE_ID
echo "      ✅ Instance is running!"

# ─────────────────────────────────────────
# STEP 4: Allocate & Attach Elastic IP
# What it does: Assigns a static public IP to your EC2.
# Without this, the IP changes every time you restart the instance.
# An Elastic IP stays the same — essential for a web server.
# ─────────────────────────────────────────
echo ""
echo "[4/6] Allocating Elastic IP..."
ALLOCATION_ID=$(aws ec2 allocate-address \
  --domain vpc \
  --tag-specifications "ResourceType=elastic-ip,Tags=[{Key=Name,Value=$PROJECT-eip}]" \
  --query 'AllocationId' \
  --output text)
echo "      ✅ Elastic IP Allocated: $ALLOCATION_ID"

aws ec2 associate-address \
  --instance-id $INSTANCE_ID \
  --allocation-id $ALLOCATION_ID > /dev/null

PUBLIC_IP=$(aws ec2 describe-addresses \
  --allocation-ids $ALLOCATION_ID \
  --query 'Addresses[0].PublicIp' \
  --output text)

echo "      ✅ Elastic IP Attached: $PUBLIC_IP"

# ─────────────────────────────────────────
# STEP 5: Save outputs for Phase 6
# ─────────────────────────────────────────
echo ""
echo "[5/6] Saving outputs..."
cat >> ~/Documents/aws-end-to-end-security-framework/vpc-outputs.env << EOF
INSTANCE_ID=$INSTANCE_ID
ALLOCATION_ID=$ALLOCATION_ID
PUBLIC_IP=$PUBLIC_IP
KEY_NAME=$KEY_NAME
EOF
echo "      ✅ Outputs saved to vpc-outputs.env"

# ─────────────────────────────────────────
# STEP 6: Print Summary
# ─────────────────────────────────────────
echo ""
echo "============================================================"
echo " ✅ EC2 SETUP COMPLETE — SUMMARY"
echo "============================================================"
echo " Instance ID:     $INSTANCE_ID"
echo " Instance Type:   $INSTANCE_TYPE (Free Tier)"
echo " Public IP:       $PUBLIC_IP"
echo " Key Pair:        ~/$KEY_NAME.pem"
echo " IAM Role:        $PROJECT-ec2-role"
echo "============================================================"
echo ""
echo " 🌐 Your web server will be live in ~2 minutes at:"
echo "    http://$PUBLIC_IP"
echo ""
echo " 🔑 SSH into your server:"
echo "    ssh -i ~/$KEY_NAME.pem ec2-user@$PUBLIC_IP"
echo ""
echo " ⚠️  Remember to STOP the instance when not in use!"
echo "    aws ec2 stop-instances --instance-ids $INSTANCE_ID"
echo "============================================================"
