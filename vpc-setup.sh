#!/bin/bash
# ============================================================
#  AWS End-to-End Security Framework
#  Phase 4: VPC Networking Setup
#  Author: John
#  Description: Automates VPC, Subnets, IGW, Route Tables & SGs
# ============================================================

set -e  # Exit immediately if any command fails

# ─────────────────────────────────────────
# CONFIGURATION — Edit these if needed
# ─────────────────────────────────────────
REGION="us-east-1"
VPC_CIDR="10.0.0.0/16"
PUBLIC_SUBNET_CIDR="10.0.1.0/24"
PRIVATE_SUBNET_CIDR="10.0.2.0/24"
PROJECT="john-security"

echo "============================================================"
echo " AWS Security Framework — VPC Setup Starting..."
echo "============================================================"

# ─────────────────────────────────────────
# STEP 1: Create the VPC
# What it does: Creates your isolated private network in AWS
# with a /16 CIDR giving you 65,536 IP addresses to work with
# ─────────────────────────────────────────
echo ""
echo "[1/8] Creating VPC..."
VPC_ID=$(aws ec2 create-vpc \
  --cidr-block $VPC_CIDR \
  --region $REGION \
  --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=$PROJECT-vpc}]" \
  --query 'Vpc.VpcId' \
  --output text)
echo "      ✅ VPC Created: $VPC_ID"

# Enable DNS hostnames — required for EC2 to get public DNS names
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-support
echo "      ✅ DNS Hostnames & Support Enabled"

# ─────────────────────────────────────────
# STEP 2: Create Public Subnet
# What it does: This is where your web server & bastion host live.
# Resources here can be assigned public IPs and reach the internet.
# ─────────────────────────────────────────
echo ""
echo "[2/8] Creating Public Subnet..."
PUBLIC_SUBNET_ID=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block $PUBLIC_SUBNET_CIDR \
  --availability-zone ${REGION}a \
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=$PROJECT-public-subnet}]" \
  --query 'Subnet.SubnetId' \
  --output text)
echo "      ✅ Public Subnet Created: $PUBLIC_SUBNET_ID"

# Auto-assign public IPs to instances launched in this subnet
aws ec2 modify-subnet-attribute \
  --subnet-id $PUBLIC_SUBNET_ID \
  --map-public-ip-on-launch
echo "      ✅ Auto-assign Public IP Enabled"

# ─────────────────────────────────────────
# STEP 3: Create Private Subnet
# What it does: Isolated subnet with no direct internet access.
# Reserved for databases or internal services in future phases.
# ─────────────────────────────────────────
echo ""
echo "[3/8] Creating Private Subnet..."
PRIVATE_SUBNET_ID=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block $PRIVATE_SUBNET_CIDR \
  --availability-zone ${REGION}b \
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=$PROJECT-private-subnet}]" \
  --query 'Subnet.SubnetId' \
  --output text)
echo "      ✅ Private Subnet Created: $PRIVATE_SUBNET_ID"

# ─────────────────────────────────────────
# STEP 4: Create Internet Gateway
# What it does: Acts as the door between your VPC and the internet.
# Without this, nothing in your VPC can reach the outside world.
# ─────────────────────────────────────────
echo ""
echo "[4/8] Creating & Attaching Internet Gateway..."
IGW_ID=$(aws ec2 create-internet-gateway \
  --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=$PROJECT-igw}]" \
  --query 'InternetGateway.InternetGatewayId' \
  --output text)
echo "      ✅ Internet Gateway Created: $IGW_ID"

aws ec2 attach-internet-gateway \
  --internet-gateway-id $IGW_ID \
  --vpc-id $VPC_ID
echo "      ✅ Internet Gateway Attached to VPC"

# ─────────────────────────────────────────
# STEP 5: Create Public Route Table
# What it does: A routing table that directs internet-bound traffic
# (0.0.0.0/0) through the Internet Gateway. Only the public subnet
# uses this table — private subnet stays isolated.
# ─────────────────────────────────────────
echo ""
echo "[5/8] Creating Public Route Table..."
PUBLIC_RT_ID=$(aws ec2 create-route-table \
  --vpc-id $VPC_ID \
  --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=$PROJECT-public-rt}]" \
  --query 'RouteTable.RouteTableId' \
  --output text)
echo "      ✅ Public Route Table Created: $PUBLIC_RT_ID"

# Add route: all internet traffic (0.0.0.0/0) goes via IGW
aws ec2 create-route \
  --route-table-id $PUBLIC_RT_ID \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id $IGW_ID
echo "      ✅ Internet Route Added (0.0.0.0/0 → IGW)"

# Associate public route table with public subnet
aws ec2 associate-route-table \
  --route-table-id $PUBLIC_RT_ID \
  --subnet-id $PUBLIC_SUBNET_ID
echo "      ✅ Route Table Associated with Public Subnet"

# ─────────────────────────────────────────
# STEP 6: Security Group — Web Server
# What it does: Acts as a virtual firewall for your EC2 web server.
# Only allows HTTP (80), HTTPS (443), and SSH (22) inbound.
# All other ports are denied by default.
# ─────────────────────────────────────────
echo ""
echo "[6/8] Creating Web Server Security Group..."
WEB_SG_ID=$(aws ec2 create-security-group \
  --group-name "$PROJECT-web-sg" \
  --description "Security group for web server - allows HTTP, HTTPS, SSH" \
  --vpc-id $VPC_ID \
  --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=$PROJECT-web-sg}]" \
  --query 'GroupId' \
  --output text)
echo "      ✅ Web Security Group Created: $WEB_SG_ID"

# Allow HTTP from anywhere
aws ec2 authorize-security-group-ingress \
  --group-id $WEB_SG_ID \
  --protocol tcp --port 80 --cidr 0.0.0.0/0
echo "      ✅ HTTP (port 80) Allowed"

# Allow HTTPS from anywhere
aws ec2 authorize-security-group-ingress \
  --group-id $WEB_SG_ID \
  --protocol tcp --port 443 --cidr 0.0.0.0/0
echo "      ✅ HTTPS (port 443) Allowed"

# Allow SSH from anywhere (restrict to your IP in production)
aws ec2 authorize-security-group-ingress \
  --group-id $WEB_SG_ID \
  --protocol tcp --port 22 --cidr 0.0.0.0/0
echo "      ✅ SSH (port 22) Allowed"

# ─────────────────────────────────────────
# STEP 7: Security Group — Bastion Host
# What it does: A dedicated SG for the bastion host (jump server).
# Only allows SSH. The bastion is the ONLY way to SSH into
# private resources — never expose private EC2s directly.
# ─────────────────────────────────────────
echo ""
echo "[7/8] Creating Bastion Host Security Group..."
BASTION_SG_ID=$(aws ec2 create-security-group \
  --group-name "$PROJECT-bastion-sg" \
  --description "Security group for bastion host - SSH only" \
  --vpc-id $VPC_ID \
  --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=$PROJECT-bastion-sg}]" \
  --query 'GroupId' \
  --output text)
echo "      ✅ Bastion Security Group Created: $BASTION_SG_ID"

aws ec2 authorize-security-group-ingress \
  --group-id $BASTION_SG_ID \
  --protocol tcp --port 22 --cidr 0.0.0.0/0
echo "      ✅ SSH (port 22) Allowed on Bastion"

# ─────────────────────────────────────────
# STEP 8: Print Summary
# ─────────────────────────────────────────
echo ""
echo "============================================================"
echo " ✅ VPC SETUP COMPLETE — SUMMARY"
echo "============================================================"
echo " VPC ID:              $VPC_ID"
echo " Public Subnet:       $PUBLIC_SUBNET_ID  (10.0.1.0/24)"
echo " Private Subnet:      $PRIVATE_SUBNET_ID (10.0.2.0/24)"
echo " Internet Gateway:    $IGW_ID"
echo " Public Route Table:  $PUBLIC_RT_ID"
echo " Web Server SG:       $WEB_SG_ID"
echo " Bastion SG:          $BASTION_SG_ID"
echo "============================================================"
echo ""
echo " 📋 SAVE THESE IDs — needed for EC2 setup in Phase 5!"
echo ""

# Save IDs to a file for use in next phases
cat > vpc-outputs.env << EOF
VPC_ID=$VPC_ID
PUBLIC_SUBNET_ID=$PUBLIC_SUBNET_ID
PRIVATE_SUBNET_ID=$PRIVATE_SUBNET_ID
IGW_ID=$IGW_ID
PUBLIC_RT_ID=$PUBLIC_RT_ID
WEB_SG_ID=$WEB_SG_ID
BASTION_SG_ID=$BASTION_SG_ID
EOF

echo " 💾 IDs saved to vpc-outputs.env for next phases"
echo "============================================================"
