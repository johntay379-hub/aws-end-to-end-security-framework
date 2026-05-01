# AWS End-to-End Security Framework

A production-grade, security-first AWS infrastructure deployment built entirely via AWS CLI on Ubuntu Linux.

Live Demo: http://100.49.157.164

---

## Project Overview

| Layer | Service | Purpose |
|---|---|---|
| Identity | IAM | Least privilege, strong password policy |
| Storage | S3 | Encrypted, versioned audit log vault |
| Logging | CloudTrail | Immutable, multi-region API audit trail |
| Networking | VPC | Isolated network with layered defenses |
| Compute | EC2 | Hardened web server with Apache |
| Monitoring | CloudWatch + SNS | Real-time threat detection and alerts |

---

## Architecture



---

## Deployment - 6 Phases

### Phase 1 - IAM
Script: iam-setup.sh

Before building any infrastructure, I enforced strict identity controls across the AWS account.

- Strong password policy (14+ chars, symbols, numbers, upper/lowercase)
- 90-day password expiration
- Password reuse prevention (last 5 passwords blocked)
- EC2 instance profile with scoped CloudWatch + SSM permissions
- Principle of Least Privilege enforced on all roles

Why: IAM misconfigurations are the number one cause of AWS breaches.

---

### Phase 2 - S3 Audit Vault
Script: s3-setup.sh

- AES-256 server-side encryption at rest
- Versioning enabled - protects logs from deletion
- All public access blocked
- Resource-based bucket policy granting CloudTrail PutObject only
- SSE-C encryption type blocked for additional hardening

Why: Logs are only useful if they cannot be tampered with.

---

### Phase 3 - CloudTrail
Script: cloudtrail-setup.sh

- Multi-region trail - monitors ALL AWS regions
- Global service events enabled - captures IAM and STS activity
- Log file validation - digital signature on every log file
- Logs delivered to encrypted S3 vault

Why: Without CloudTrail you are blind. Multi-region coverage prevents attackers hiding in unused regions.

---

### Phase 4 - VPC
Script: vpc-setup.sh

- VPC CIDR: 10.0.0.0/16
- Public subnet 10.0.1.0/24 - web server
- Private subnet 10.0.2.0/24 - future database layer
- Internet Gateway for controlled internet access
- Web Server Security Group - ports 80, 443, 22
- Bastion Host Security Group - SSH only

Why: Network segmentation is a core Zero Trust principle.

---

### Phase 5 - EC2 Web Server
Script: ec2-setup.sh

- Instance type: t2.micro (free tier)
- Apache web server auto-installed via User Data script
- Elastic IP for static public addressing
- IAM instance profile - no hardcoded credentials
- IMDSv2 enforced - prevents SSRF attacks on metadata service
- Custom security-themed homepage deployed

Live: http://100.49.157.164

Why: IMDSv2 enforcement prevents attackers from reading AWS credentials via SSRF.

---

### Phase 6 - CloudWatch + SNS
Script: cloudwatch-sns-setup.sh

- SNS topic with confirmed email subscription
- CPU Alarm - triggers when EC2 CPU exceeds 80% for 10 minutes
- Status Check Alarm - triggers when EC2 fails health check
- IAM Policy Change Alarm - triggers on any IAM permission modification
- Email alerts delivered instantly

Why: Detection without alerting is useless. These alarms provide real-time visibility into threats.

---

## Cost Breakdown

| Service | Cost |
|---|---|
| EC2 t2.micro | Free tier |
| S3 | ~0.02 per month |
| CloudTrail | Free (first trail) |
| Elastic IP | Free (when attached) |
| CloudWatch | Free (under 10 alarms) |
| SNS | Free (under 1000 emails) |
| VPC | Always free |
| Total | ~0.02 per month |

---

## Security Decisions

| Decision | Reason |
|---|---|
| IAM before infrastructure | Identity is the perimeter in cloud |
| Multi-region CloudTrail | Attackers use unused regions to hide |
| Log file validation | Detects tampered logs |
| IMDSv2 enforcement | Prevents SSRF on metadata service |
| Versioning on S3 | Logs survive deletion attempts |
| Private subnet reserved | DB layer never public-facing |

---

## How to Deploy

    git clone https://github.com/johntay379-hub/aws-end-to-end-security-framework.git
    cd aws-end-to-end-security-framework
    aws configure
    bash iam-setup.sh
    bash s3-setup.sh
    bash cloudtrail-setup.sh
    bash vpc-setup.sh
    bash ec2-setup.sh
    bash cloudwatch-sns-setup.sh

Prerequisites: AWS CLI, IAM user with permissions, Ubuntu Linux

---

## Screenshots

All deployment screenshots are in the /screenshots folder showing live AWS console verification of every service.

---

## Author

John - AWS Cloud Security Engineer
Deployed: April 2026 | Region: us-east-1 | Method: AWS CLI

This project was built as a demonstration of real-world AWS security architecture - not a tutorial follow-along.
