# 🔒 AWS End-to-End Security Framework

![AWS](https://img.shields.io/badge/AWS-Cloud-orange?style=for-the-badge&logo=amazon-aws)
![CLI](https://img.shields.io/badge/Deployed-AWS%20CLI-blue?style=for-the-badge&logo=gnubash)
![Ubuntu](https://img.shields.io/badge/OS-Ubuntu%20Linux-E95420?style=for-the-badge&logo=ubuntu)
![Status](https://img.shields.io/badge/Status-Live-brightgreen?style=for-the-badge)
![Region](https://img.shields.io/badge/Region-us--east--1-yellow?style=for-the-badge&logo=amazon-aws)

> A production-grade, security-first AWS infrastructure deployment built entirely from scratch using the AWS CLI on Ubuntu Linux. Every layer — identity, storage, logging, networking, compute, and monitoring — was designed with enterprise security best practices in mind.

---

## 🌐 Live Demo

**👉 http://100.49.157.164**

The live web server is running on a hardened EC2 instance with a custom security-themed homepage showing the full deployment status of all 6 services.

---

## 📌 Project Overview

This project demonstrates a complete end-to-end AWS security framework covering every critical layer of cloud security:

| Layer | Service | Purpose |
|---|---|---|
| 🔐 Identity & Access | IAM | Least privilege roles, strong password policy |
| 🪣 Storage & Audit | S3 | Encrypted, versioned, private audit log vault |
| 🔍 Logging | CloudTrail | Immutable, multi-region API audit trail |
| 🌐 Networking | VPC | Isolated network with layered defenses |
| 🖥️ Compute | EC2 | Hardened Apache web server with Elastic IP |
| 📊 Monitoring & Alerting | CloudWatch + SNS | Real-time threat detection and email alerts |

---

## 🏗️ Architecture

```
                        ┌─────────────────┐
                        │    🌐 Internet   │
                        │  HTTP · HTTPS   │
                        └────────┬────────┘
                                 │
                        ┌────────▼────────┐
                        │ Internet Gateway │
                        │  VPC entry point │
                        └────────┬────────┘
                                 │
        ┌────────────────────────▼──────────────────────────┐
        │              VPC — 10.0.0.0/16                    │
        │                                                    │
        │  ┌─────────────────────┐  ┌────────────────────┐  │
        │  │   Public Subnet     │  │   Private Subnet   │  │
        │  │   10.0.1.0/24       │  │   10.0.2.0/24      │  │
        │  │                     │  │                    │  │
        │  │  ┌───────────────┐  │  │  ┌──────────────┐ │  │
        │  │  │ EC2 Web Server│  │  │  │ Future DB    │ │  │
        │  │  │ Apache        │  │  │  │ No public    │ │  │
        │  │  │ Elastic IP    │  │  │  │ access       │ │  │
        │  │  │ IMDSv2        │  │  │  └──────────────┘ │  │
        │  │  └───────┬───────┘  │  │                    │  │
        │  │          │          │  │                    │  │
        │  │  SG: 80,443,22      │  │                    │  │
        │  └──────────┼──────────┘  └────────────────────┘  │
        └─────────────┼──────────────────────────────────────┘
                      │
          ┌───────────┼────────────────────┐
          │           │                    │
   ┌──────▼──┐  ┌─────▼──────┐    ┌───────▼──────┐
   │   IAM   │  │ CloudTrail │───▶│  S3 Audit    │
   │ Least   │  │ Multi-region│    │  Vault       │
   │Privilege│  │ Tamper-proof│    │  AES-256     │
   └─────────┘  └─────┬──────┘    │  Versioned   │
                       │           └──────────────┘
                ┌──────▼──────┐
                │ CloudWatch  │
                │ CPU · Status│
                │ IAM Alarms  │
                └──────┬──────┘
                       │
                ┌──────▼──────┐
                │     SNS     │
                │ Email Alerts│
                │  Confirmed  │
                └─────────────┘
```

---

## 🚀 Deployment Phases

### Phase 1 — IAM (Identity & Access Management)
**Script:** `iam-setup.sh`

Security starts with identity. Before building any infrastructure, strict account-wide access controls were enforced.

**What was built:**
- Strong password policy — 14+ characters, symbols, numbers, upper/lowercase
- 90-day password expiration with reuse prevention (last 5 blocked)
- EC2 instance profile with scoped CloudWatch + SSM permissions only
- Principle of Least Privilege enforced on all roles — no over-permissioned users

**Why first:** IAM misconfigurations are the #1 cause of AWS breaches. Getting identity right before anything else ensures everything built on top is protected.

---

### Phase 2 — S3 Audit Vault
**Script:** `s3-setup.sh`

A dedicated, hardened S3 bucket built exclusively to receive and protect security logs.

**What was built:**
- Globally unique bucket: `john-audit-logs-2026`
- AES-256 server-side encryption at rest
- Versioning enabled — protects logs from accidental or malicious deletion
- All public access blocked at bucket level
- Resource-based bucket policy granting CloudTrail `PutObject` permissions only
- SSE-C encryption type explicitly blocked for additional hardening

**Why:** Logs are only useful if they cannot be tampered with. Versioning + encryption ensures an immutable audit trail even if credentials are compromised.

---

### Phase 3 — CloudTrail
**Script:** `cloudtrail-setup.sh`

Account-wide API activity logging for forensic analysis, compliance, and threat detection.

**What was built:**
- Multi-region trail — monitors ALL AWS regions, not just us-east-1
- Global service events enabled — captures IAM and STS activity
- Log file validation — every log gets a digital signature to detect tampering
- Logs delivered to the encrypted S3 vault
- `IsLogging: true` verified via CLI

**Why:** Without CloudTrail, you are completely blind. Multi-region coverage prevents attackers from spinning up resources in unused regions to avoid detection.

---

### Phase 4 — VPC (Virtual Private Cloud)
**Script:** `vpc-setup.sh`

A fully isolated, layered network built from scratch — nothing pre-configured, everything intentional.

**What was built:**
- VPC CIDR: `10.0.0.0/16` — 65,536 available IP addresses
- Public subnet `10.0.1.0/24` — web server lives here
- Private subnet `10.0.2.0/24` — reserved for future database layer
- Internet Gateway for controlled internet access
- Custom route table directing internet traffic through IGW only
- Web Server Security Group — ports 80 (HTTP), 443 (HTTPS), 22 (SSH)
- Bastion Host Security Group — SSH port 22 only
- DNS hostnames and DNS support enabled

**Why:** Network segmentation is a core Zero Trust principle. Public resources are isolated from private ones. Nothing enters or leaves without an explicit rule.

---

### Phase 5 — EC2 Web Server
**Script:** `ec2-setup.sh`

A hardened compute instance running a live, production-style web server.

**What was built:**
- Instance type: `t2.micro` (free tier eligible)
- AMI: Amazon Linux 2023
- Apache web server auto-installed via User Data script on first boot
- Elastic IP for static public addressing — IP never changes on restart
- IAM instance profile attached — zero hardcoded credentials
- IMDSv2 enforced — blocks SSRF attacks on the instance metadata service
- Custom security-themed homepage deployed
- SSH key pair with 400 permissions (read-only by owner)

**Live:** http://100.49.157.164

**Why:** IMDSv2 enforcement is a critical security control — it prevents a class of attacks where a compromised application reads AWS credentials directly from the metadata endpoint.

---

### Phase 6 — CloudWatch + SNS
**Script:** `cloudwatch-sns-setup.sh`

Real-time monitoring and automated threat alerting — the eyes and ears of the deployment.

**What was built:**
- SNS topic: `john-security-alerts` with confirmed email subscription
- **CPU Alarm** — triggers when EC2 CPU exceeds 80% for 10 consecutive minutes
  - Detects: crypto miners, DDoS, runaway processes
- **Status Check Alarm** — triggers when EC2 fails its health check
  - Detects: hardware failures, OS crashes, network issues
- **IAM Policy Change Alarm** — triggers on any IAM permission modification
  - Detects: privilege escalation attacks

**Why:** Detection without alerting is useless. These alarms provide real-time visibility into both operational issues and active security threats the moment they happen.

---

## 💰 Cost Breakdown

| Service | Usage | Estimated Monthly Cost |
|---|---|---|
| EC2 t2.micro | 750 hrs/month free tier | $0.00 |
| S3 Audit Vault | < 1GB log storage | ~$0.02 |
| CloudTrail | First trail is free | $0.00 |
| Elastic IP | Attached to running instance | $0.00 |
| CloudWatch | 3 alarms (10 free per month) | $0.00 |
| SNS | < 1,000 emails (free tier) | $0.00 |
| VPC / IGW / Subnets | Always free | $0.00 |
| **Total** | | **~$0.02/month** |

---

## 🔐 Security Decisions

| Decision | Justification |
|---|---|
| IAM configured before any infrastructure | Identity is the perimeter in cloud — everything else inherits its security posture |
| Multi-region CloudTrail | Attackers commonly spin up resources in unused regions to avoid detection |
| Log file validation enabled | Provides cryptographic proof that logs haven't been modified after delivery |
| IMDSv2 enforced on EC2 | Prevents SSRF attacks from reading the instance metadata and stealing credentials |
| S3 versioning enabled | Logs survive even if an attacker with S3 access attempts deletion |
| Private subnet reserved | Defense in depth — database layer is never directly reachable from the internet |
| Resource-based bucket policy | CloudTrail gets only the minimum permissions needed — PutObject only |
| SNS email confirmation required | Prevents unauthorized subscriptions to the alert channel |

---

## 🛠️ How to Deploy

**Prerequisites:**
- AWS CLI installed and configured
- IAM user with appropriate permissions
- Ubuntu Linux (or any Linux distro)

**Clone and run phases in order:**

```bash
git clone https://github.com/johntay379-hub/aws-end-to-end-security-framework.git
cd aws-end-to-end-security-framework

# Configure your AWS credentials
aws configure

# Run each phase in order
bash iam-setup.sh
bash s3-setup.sh
bash cloudtrail-setup.sh
bash vpc-setup.sh
bash ec2-setup.sh
bash cloudwatch-sns-setup.sh
```

> Each script is fully commented explaining what every command does and why — designed to be readable, not just runnable.

---

## 📁 Repository Structure

```
aws-end-to-end-security-framework/
├── iam-setup.sh              # Phase 1 — IAM password policy & roles
├── s3-setup.sh               # Phase 2 — S3 audit vault
├── cloudtrail-setup.sh       # Phase 3 — CloudTrail multi-region logging
├── vpc-setup.sh              # Phase 4 — VPC, subnets, IGW, route tables, SGs
├── ec2-setup.sh              # Phase 5 — EC2 web server + Elastic IP
├── cloudwatch-sns-setup.sh   # Phase 6 — CloudWatch alarms + SNS alerts
├── index.html                # Live web server homepage
├── architecture.md           # Architecture diagram
├── README.md                 # This file
└── screenshots/              # AWS console verification screenshots
```

---

## 📸 Screenshots

All deployment screenshots are in the `/screenshots` folder — showing live AWS console verification of every service including IAM, S3, CloudTrail, VPC, EC2, CloudWatch, and SNS.

---

## 👨‍💻 Author

**John** — AWS Cloud Security Engineer

Deployed: April 2026 | Region: us-east-1 | Method: AWS CLI on Ubuntu Linux

---

> *This project was built as a demonstration of real-world AWS security architecture — not a tutorial follow-along. Every design decision was made with a security-first mindset, following enterprise best practices used in production environments.*
