# 🛡️ Security Validation

> Real-world attack scenarios tested against this deployment to validate every security control works as expected.

---

## 1. Unauthorized API Access

**Scenario:** An attacker gains access to a low-privilege IAM user and attempts to attach an admin policy to escalate their permissions.

**Attack:**
```bash
aws iam attach-user-policy \
  --user-name compromised-user \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
```

**Outcome:**
- ❌ Action blocked — IAM least privilege policy denies the request
- 📋 CloudTrail logs the AttachUserPolicy event immediately
- 🔔 CloudWatch IAM alarm fires and SNS delivers an email alert within 5 minutes

---

## 2. SSH Brute Force Attempt

**Scenario:** An attacker attempts to brute force SSH access to the EC2 web server from the public internet.

**Attack:**
```bash
hydra -l ec2-user -P wordlist.txt ssh://100.49.157.164
```

**Outcome:**
- ❌ Attack fails — only RSA key pair authentication is accepted, passwords are disabled
- 🔒 Security group restricts SSH to port 22 only — all other ports silently dropped
- 📋 All failed connection attempts captured in CloudTrail logs for forensic review

---

## 3. Log Tampering Attempt

**Scenario:** An attacker with partial AWS access attempts to delete audit logs from the S3 vault to cover their tracks.

**Attack:**
```bash
aws s3 rm s3://john-audit-logs-2026 --recursive
```

**Outcome:**
- ❌ Deletion blocked — bucket policy denies all access except CloudTrail service
- 🔄 Even if deletion partially succeeds, S3 versioning preserves every log version
- 📋 The deletion attempt itself is logged by CloudTrail — the attacker leaves a trail trying to erase the trail

---

## ✅ Validation Summary

| Scenario | Result | Detected By |
|---|---|---|
| Unauthorized API Access | Blocked + Alerted | IAM · CloudTrail · CloudWatch · SNS |
| SSH Brute Force | Blocked | Key Pair Auth · Security Group |
| Log Tampering | Blocked + Preserved | S3 Policy · Versioning · CloudTrail |

> *Every layer of this framework was designed so that a failed attack still leaves evidence. Attackers cannot act without being logged, and cannot delete logs without being logged doing so.*
