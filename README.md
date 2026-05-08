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
                     ┌──────────────────┐
                     │   🌐 Internet    │
                     │  HTTP · HTTPS    │
                     └────────┬─────────┘
                              │
                     ┌────────▼─────────┐
                     │ Internet Gateway  │
                     │  VPC entry point  │
                     └────────┬─────────┘
                              │
     ┌────────────────────────▼─────────────────────────┐
     │                VPC — 10.0.0.0/16                  │
     │                                                    │
     │  ┌──────────────────────┐  ┌──────────────────┐   │
     │  │   Public Subnet      │  │  Private Subnet  │   │
     │  │   10.0.1.0/24        │  │  10.0.2.0/24     │   │
     │  │  ┌────────────────┐  │  │  ┌────────────┐  │   │
     │  │  │ EC2 Web Server │  │  │  │ Future DB  │  │   │
     │  │  │ Apache         │  │  │  │ No public  │  │   │
     │  │  │ Elastic IP     │  │  │  │ access     │  │   │
     │  │  │ IMDSv2         │  │  │  └────────────┘  │   │
     │  │  └───────┬────────┘  │  └──────────────────┘   │
     │  │  SG: 80, 443, 22     │                          │
     │  └──────────┼───────────┘                          │
     └─────────────┼────────────────────────────────────--┘
                   │
       ┌───────────┼──────────────────┐
       │           │                  │
  ┌────▼───┐  ┌────▼──────┐   ┌──────▼──────┐
  │  IAM   │  │CloudTrail │──▶│ S3 Audit    │
  │Least   │  │Multi-region│   │ Vault       │
  │Priv.   │  │Tamper-proof│   │ AES-256     │
  └────────┘  └────┬──────┘   └─────────────┘
                   │
             ┌─────▼──────┐
             │ CloudWatch  │
             │ 3 Alarms    │
             └─────┬───────┘
                   │
             ┌─────▼──────┐
             │    SNS      │
             │ Email Alert │
             └─────────────┘
```

📐 [View Full Interactive Architecture Diagram](architecture.md)

---

## 🚀 Deployment Phases

### Phase 1 — IAM
**Script:** `iam-setup.sh`

Security starts with identity. Before building any infrastructure, strict account-wide access controls were enforced.

- Strong password policy — 14+ characters, symbols, numbers, upper/lowercase
- 90-day password expiration with reuse prevention (last 5 blocked)
- EC2 instance profile with scoped CloudWatch + SSM permissions only
- Principle of Least Privilege enforced on all roles

> IAM misconfigurations are the #1 cause of AWS breaches. Getting identity right first ensures everything built on top is protected.

---

### Phase 2 — S3 Audit Vault
**Script:** `s3-setup.sh`

A dedicated, hardened S3 bucket built exclusively to receive and protect security logs.

- AES-256 server-side encryption at rest
- Versioning enabled — protects logs from accidental or malicious deletion
- All public access blocked at bucket level
- Resource-based bucket policy granting CloudTrail `PutObject` only

> Logs are only useful if they cannot be tampered with.

---

### Phase 3 — CloudTrail
**Script:** `cloudtrail-setup.sh`

Account-wide API activity logging for forensic analysis, compliance, and threat detection.

- Multi-region trail — monitors ALL AWS regions
- Global service events — captures IAM and STS activity
- Log file validation — digital signature on every log file
- Logs delivered to the encrypted S3 vault

> Without CloudTrail, you are completely blind.

---

### Phase 4 — VPC
**Script:** `vpc-setup.sh`

A fully isolated, layered network built from scratch — nothing pre-configured, everything intentional.

- VPC CIDR: `10.0.0.0/16` — 65,536 available IPs
- Public subnet `10.0.1.0/24` — web server
- Private subnet `10.0.2.0/24` — future database layer
- Internet Gateway + custom route table
- Security Groups — ports 80, 443, 22 (web) · port 22 only (bastion)

> Network segmentation is a core Zero Trust principle.

---

### Phase 5 — EC2 Web Server
**Script:** `ec2-setup.sh`

A hardened compute instance running a live, production-style web server.

- Instance type: `t2.micro` (free tier)
- Apache auto-installed via User Data script on first boot
- Elastic IP — static public address, never changes on restart
- IAM instance profile — zero hardcoded credentials
- IMDSv2 enforced — blocks SSRF attacks on the metadata service

**Live:** http://100.49.157.164

> IMDSv2 enforcement prevents attackers from reading AWS credentials via SSRF.

---

### Phase 6 — CloudWatch + SNS
**Script:** `cloudwatch-sns-setup.sh`

Real-time monitoring and automated threat alerting.

- **CPU Alarm** — triggers when EC2 CPU exceeds 80% for 10 minutes
- **Status Check Alarm** — triggers when EC2 fails its health check
- **IAM Policy Change Alarm** — triggers on any IAM permission modification
- SNS email alerts delivered to security team instantly

> Detection without alerting is useless.

---

## 🛡️ Security Validation

Three real-world attack scenarios were tested against this deployment:

| Scenario | Result | Detected By |
|---|---|---|
| Unauthorized API Access | Blocked + Alerted | IAM · CloudTrail · CloudWatch · SNS |
| SSH Brute Force | Blocked | Key Pair Auth · Security Group |
| Log Tampering | Blocked + Preserved | S3 Policy · Versioning · CloudTrail |

📄 [View Full Security Validation Report](SECURITY_VALIDATION.md)

---

## 🔐 Security Decisions

| Decision | Justification |
|---|---|
| IAM before infrastructure | Identity is the perimeter in cloud |
| Multi-region CloudTrail | Attackers use unused regions to hide activity |
| Log file validation | Cryptographic proof logs haven't been modified |
| IMDSv2 enforced | Blocks SSRF attacks on instance metadata |
| S3 versioning | Logs survive even if deletion is attempted |
| Private subnet reserved | DB layer never directly reachable from internet |
| Resource-based bucket policy | CloudTrail gets PutObject permissions only |

---

## 💰 Cost Breakdown

| Service | Estimated Monthly Cost |
|---|---|
| EC2 t2.micro | $0.00 (free tier) |
| S3 Audit Vault | ~$0.02 |
| CloudTrail | $0.00 (first trail free) |
| Elastic IP | $0.00 (attached to running instance) |
| CloudWatch | $0.00 (under 10 alarms free) |
| SNS | $0.00 (under 1,000 emails free) |
| VPC / IGW / Subnets | $0.00 (always free) |
| **Total** | **~$0.02/month** |

---

## 🛠️ How to Deploy

```bash
git clone https://github.com/johntay379-hub/aws-end-to-end-security-framework.git
cd aws-end-to-end-security-framework
aws configure
bash iam-setup.sh
bash s3-setup.sh
bash cloudtrail-setup.sh
bash vpc-setup.sh
bash ec2-setup.sh
bash cloudwatch-sns-setup.sh
```

**Prerequisites:** AWS CLI · IAM user with permissions · Ubuntu Linux

---

## 📁 Repository Structure

```
aws-end-to-end-security-framework/
├── iam-setup.sh              # Phase 1 — IAM
├── s3-setup.sh               # Phase 2 — S3 audit vault
├── cloudtrail-setup.sh       # Phase 3 — CloudTrail
├── vpc-setup.sh              # Phase 4 — VPC & networking
├── ec2-setup.sh              # Phase 5 — EC2 web server
├── cloudwatch-sns-setup.sh   # Phase 6 — Monitoring & alerts
├── index.html                # Live web server homepage
├── architecture.md           # Interactive architecture diagram
├── SECURITY_VALIDATION.md    # Attack simulation scenarios
├── README.md                 # This file
└── screenshots/              # AWS console verification proof
```

---

## 📸 Screenshots

All deployment screenshots are in the `/screenshots` folder showing live AWS console verification of every service.

---

## 👨‍💻 Author

**John** — AWS Cloud Security Engineer
Deployed: April 2026 · Region: us-east-1 · Method: AWS CLI on Ubuntu Linux

> *This project was built as a demonstration of real-world AWS security architecture — not a tutorial follow-along. Every design decision was made with a security-first mindset.*
