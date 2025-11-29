# 📘 Complete Implementation Guide - AWS + FreeDNS

This guide walks you through deploying the TODO application from scratch using AWS and FreeDNS.

---

## 📋 What You're Deploying

```
Cloud:     AWS EC2 (t3.medium, ~$40/month)
Domain:    delightverse.mooo.com (FreeDNS subdomain)
SSL:       Let's Encrypt (HTTP Challenge - automatic)
Services:  5 microservices + Redis + Traefik
```

---

## ⏱️ Time Estimate

```
AWS Setup:              15 minutes
File Configuration:     10 minutes
Deployment:             15 minutes
DNS Configuration:      10 minutes
Testing:                10 minutes
Screenshots:            15 minutes
────────────────────────────────────
Total:                  ~75 minutes
```

---

## 🎯 PART 1: AWS Setup (15 minutes)

### Step 1.1: Create AWS Account

If you don't have an AWS account:
1. Go to: https://aws.amazon.com/
2. Click "Create an AWS Account"
3. Follow registration (requires credit card)
4. Complete verification

### Step 1.2: Create IAM User for Terraform

**Why?** Better security than using root account credentials.

1. **Log in to AWS Console**: https://console.aws.amazon.com/
2. **Search for "IAM"** in the search bar
3. **Click "Users"** in the left sidebar
4. **Click "Create user"**
   ```
   User name: terraform-user
   ```
5. **Click "Next"**

6. **Set Permissions**:
   - Select "Attach policies directly"
   - Search and check these policies:
     ```
     ☑ AmazonEC2FullAccess
     ☑ AmazonVPCFullAccess
     ☑ AmazonS3FullAccess
     ```
   - Click "Next"
   - Click "Create user"

7. **Create Access Keys**:
   - Click on the user you just created
   - Go to "Security credentials" tab
   - Scroll to "Access keys"
   - Click "Create access key"
   - Select "Command Line Interface (CLI)"
   - Check the confirmation box
   - Click "Next"
   - Click "Create access key"

8. **⚠️ CRITICAL: Save These Credentials**:
   ```
   Access Key ID:     AKIA...
   Secret Access Key: wJalrXUtnFEMI/...
   ```
   **Download CSV or copy immediately - you can't see them again!**

### Step 1.3: Create S3 Bucket for Terraform State

1. **Go to S3**: https://console.aws.amazon.com/s3/
2. **Click "Create bucket"**
3. **Configure bucket**:
   ```
   Bucket name: your-username-terraform-state
   Region: us-east-1
   
   Block Public Access: ☑ Block all public access (default)
   Bucket Versioning: ☑ Enable
   
   Leave other settings as default
   ```
4. **Click "Create bucket"**
5. **Note the bucket name** - you'll need it!

### Step 1.4: Generate SSH Keys

```bash
# Generate new SSH key pair
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""

# This creates:
# ~/.ssh/id_rsa      (private key - keep secret!)
# ~/.ssh/id_rsa.pub  (public key - can share)

# View your public key
cat ~/.ssh/id_rsa.pub
```

---

## 🗂️ PART 2: Repository Setup (10 minutes)

### Step 2.1: Place Files in Your Repository

You should have downloaded the solution zip. Extract it:

```bash
# Extract the solution
cd /path/to/downloads
unzip aws-freedns-solution.zip

# Navigate to your repository
cd /path/to/your/hng13-stage6-devops

# IMPORTANT: Backup your .env file if it exists
cp .env .env.backup

# Copy all solution files
cp -r /path/to/aws-freedns-solution/* .

# List what you have now
ls -la
```

**Your repository should now have**:
```
hng13-stage6-devops/
├── .github/workflows/
│   ├── infra-deploy.yml      ← CI/CD for infrastructure
│   └── app-deploy.yml         ← CI/CD for application
├── auth-api/
│   ├── Dockerfile             ← Provided (unchanged)
│   └── (your Go code)
├── todos-api/
│   ├── Dockerfile             ← Provided (unchanged)
│   └── (your Node.js code)
├── users-api/
│   ├── Dockerfile             ← Provided (unchanged)
│   └── (your Java code)
├── frontend/
│   ├── Dockerfile             ← Provided (unchanged)
│   ├── nginx.conf             ← Provided
│   └── (your Vue.js code)
├── log-message-processor/
│   ├── Dockerfile             ← Provided (unchanged)
│   └── (your Python code)
├── traefik/
│   ├── traefik.yml            ← HTTP challenge config
│   └── config.yml             ← Security settings
├── infra/
│   ├── terraform/
│   │   ├── provider.tf        ← AWS configuration
│   │   ├── main.tf            ← EC2, security groups
│   │   ├── variables.tf       ← Variable definitions
│   │   ├── terraform.tfvars.example
│   │   ├── inventory.tpl      ← Ansible inventory
│   │   └── user-data.sh       ← Server initialization
│   └── ansible/
│       ├── playbook.yml
│       └── roles/
│           ├── dependencies/   ← Install Docker
│           └── deploy/         ← Deploy app
├── docker-compose.yml         ← No Cloudflare vars
├── .env.example               ← Template
├── .gitignore
├── README.md                  ← You are here
└── IMPLEMENTATION.md          ← This file
```

### Step 2.2: Configure Environment File

```bash
# Create .env from example
cp .env.example .env
nano .env
```

**Update these values**:
```bash
# Your FreeDNS domain
DOMAIN=delightverse.mooo.com

# Keep other values as-is
JWT_SECRET=myfancysecret
PORT=8080
AUTH_API_ADDRESS=http://auth-api:8081
TODOS_API_ADDRESS=http://todos-api:8082
AUTH_API_PORT=8081
USERS_API_ADDRESS=http://users-api:8083
TODO_API_PORT=8082
REDIS_HOST=redis-queue
REDIS_PORT=6379
REDIS_CHANNEL=log_channel
SERVER_PORT=8083
```

### Step 2.3: Configure Terraform Variables

```bash
cd infra/terraform

# Create your terraform.tfvars
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
```

**Fill in YOUR values**:
```hcl
# ═══════════════════════════════════════
# AWS Credentials (from Step 1.2)
# ═══════════════════════════════════════
aws_access_key = "AKIA..."  # Your Access Key ID
aws_secret_key = "wJalrXUtnFEMI/..."  # Your Secret Key
aws_region     = "us-east-1"

# ═══════════════════════════════════════
# SSH Configuration (from Step 1.4)
# ═══════════════════════════════════════
ssh_key_name         = "devops-ssh-key"
ssh_public_key_path  = "~/.ssh/id_rsa.pub"
ssh_private_key_path = "~/.ssh/id_rsa"

# ═══════════════════════════════════════
# EC2 Instance
# ═══════════════════════════════════════
instance_name = "todo-app-server"
instance_type = "t3.medium"  # 2 vCPU, 4GB RAM
volume_size   = 30

# ═══════════════════════════════════════
# GitHub Repository
# ═══════════════════════════════════════
github_repo_url = "https://github.com/YOUR_USERNAME/hng13-stage6-devops.git"
github_branch   = "main"

# ═══════════════════════════════════════
# Domain (FreeDNS)
# ═══════════════════════════════════════
domain = "delightverse.mooo.com"

# ═══════════════════════════════════════
# Application Secrets
# ═══════════════════════════════════════
jwt_secret = "myfancysecret"

# ═══════════════════════════════════════
# Ansible Configuration
# ═══════════════════════════════════════
ansible_user = "ubuntu"  # ← AWS Ubuntu AMI default user
run_ansible  = true
```

**Save and close** (Ctrl+X, Y, Enter in nano)

---

## 🚀 PART 3: Deploy to AWS (15 minutes)

### Step 3.1: Initialize Terraform

```bash
cd infra/terraform

# Initialize Terraform with S3 backend
terraform init \
  -backend-config="bucket=your-username-terraform-state" \
  -backend-config="key=todo-app/terraform.tfstate" \
  -backend-config="region=us-east-1"
```

**Replace `your-username-terraform-state` with your bucket name from Step 1.3**

**Expected output**:
```
Initializing the backend...
Successfully configured the backend "s3"!

Terraform has been successfully initialized!
```

### Step 3.2: Preview Changes

```bash
terraform plan
```

**Review the output**. You should see:
```
Plan: 4 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + access_url          = "https://delightverse.mooo.com"
  + instance_id         = (known after apply)
  + instance_public_ip  = (known after apply)
  + security_group_id   = (known after apply)
  + ssh_command         = (known after apply)
```

### Step 3.3: Deploy Everything

```bash
terraform apply
```

**Type `yes` when prompted**

**What happens now** (10-15 minutes):
```
✓ Creating SSH key pair in AWS
✓ Creating security group (firewall rules)
✓ Launching EC2 instance (t3.medium)
✓ Waiting for instance to boot
✓ Running initialization script
✓ Generating Ansible inventory
✓ Waiting for SSH to be ready
✓ Running Ansible playbook
  ├─ Installing Docker
  ├─ Installing Docker Compose
  ├─ Creating Docker networks
  ├─ Cloning your repository
  ├─ Creating .env file
  ├─ Setting up Traefik
  ├─ Building Docker images
  ├─ Starting all containers
  └─ Configuring auto-start
✓ Deployment complete!
```

### Step 3.4: Get Your Server IP

```bash
# View all outputs
terraform output

# Or just the IP
terraform output instance_public_ip
```

**Example output**:
```
instance_public_ip = "54.123.45.67"
```

**⚠️ SAVE THIS IP** - you'll need it for FreeDNS and GitHub!

---

## 🌐 PART 4: Configure FreeDNS (10 minutes)

### Step 4.1: Update DNS Record

1. **Log in to FreeDNS**: https://freedns.afraid.org/
2. **Go to your subdomains**: Click "Subdomains" in menu
3. **Find your subdomain**: delightverse.mooo.com
4. **Click "Edit"** (pencil icon)
5. **Update settings**:
   ```
   Type: A
   Subdomain: delightverse
   Domain: mooo.com
   Destination: 54.123.45.67  ← Your EC2 IP from Step 3.4
   TTL: 3600 (or default)
   ```
6. **Click "Save!"**

### Step 4.2: Wait for DNS Propagation

```bash
# Check DNS (may take 5-10 minutes)
dig delightverse.mooo.com

# Keep checking until you see your IP:
# delightverse.mooo.com. 3600 IN A 54.123.45.67
```

**While waiting**, continue to the next steps...

---

## ✅ PART 5: Verify Deployment (10 minutes)

### Step 5.1: SSH to Server

```bash
# Get SSH command
terraform output ssh_command

# Or manually:
ssh -i ~/.ssh/id_rsa ubuntu@54.123.45.67
```

**Note**: Use `ubuntu` user, NOT `root`!

### Step 5.2: Check Containers

```bash
# On the server:
docker ps

# You should see 7 containers:
# - traefik
# - frontend
# - auth-api
# - todos-api
# - users-api
# - redis-queue
# - log-processor
```

### Step 5.3: Check Traefik Logs

```bash
# View Traefik logs
docker compose logs traefik | grep -i certificate

# You should see (after DNS propagation):
# Obtained certificate for delightverse.mooo.com
```

**If you see errors**: DNS may not have propagated yet. Wait 5 more minutes.

### Step 5.4: Exit Server

```bash
exit  # Leave SSH session
```

### Step 5.5: Test Application

```bash
# Test HTTP redirect
curl -I http://delightverse.mooo.com
# Should return: 301 Moved Permanently

# Test HTTPS
curl -I https://delightverse.mooo.com
# Should return: HTTP/2 200
```

### Step 5.6: Visit in Browser

Open: **https://delightverse.mooo.com**

**You should see**:
- ✅ HTTPS padlock (secure)
- ✅ Login page
- ✅ No certificate warnings

**Login with**:
- Username: `admin`
- Password: `Admin123`

**You should see**:
- ✅ TODO dashboard
- ✅ Can create todos
- ✅ Can view todos

---

## 🎯 PART 6: Test Idempotency (5 minutes)

### Critical for Screenshots!

```bash
cd infra/terraform

# Run terraform apply again
terraform apply
```

**Expected output**:
```
No changes. Infrastructure is up-to-date.

This means that Terraform did not detect any differences between your
configuration and real physical resources that exist. As a result, no
actions need to be performed.
```

**📸 SCREENSHOT THIS!** This proves idempotency!

---

## 🔄 PART 7: Configure CI/CD (10 minutes)

### Step 7.1: Add GitHub Secrets

Go to your repository:
**Settings → Secrets and variables → Actions → New repository secret**

Add these **11 secrets**:

#### AWS Credentials:
```
Name: AWS_ACCESS_KEY_ID
Value: AKIA...

Name: AWS_SECRET_ACCESS_KEY
Value: wJalrXUtnFEMI/...
```

#### Application Configuration:
```
Name: DOMAIN
Value: delightverse.mooo.com

Name: JWT_SECRET
Value: myfancysecret

Name: TF_STATE_BUCKET
Value: your-username-terraform-state
```

#### Server Access:
```
Name: SERVER_IP
Value: 54.123.45.67  (your EC2 IP)

Name: SSH_PRIVATE_KEY
Value: (paste contents of ~/.ssh/id_rsa)
```

**To get SSH private key**:
```bash
cat ~/.ssh/id_rsa

# Copy ENTIRE output including:
# -----BEGIN OPENSSH PRIVATE KEY-----
# ...all the lines...
# -----END OPENSSH PRIVATE KEY-----
```

#### Email Notifications:
```
Name: EMAIL_USERNAME
Value: your-email@gmail.com

Name: EMAIL_PASSWORD
Value: your-gmail-app-password

Name: NOTIFICATION_EMAIL
Value: your-email@gmail.com
```

**Gmail App Password** (if using Gmail):
1. Go to: https://myaccount.google.com/security
2. Enable 2-Factor Authentication
3. Go to "App passwords"
4. Create new app password for "Mail"
5. Use that 16-character password

### Step 7.2: Push Changes

```bash
# Add all files
git add .

# Commit
git commit -m "Add AWS + FreeDNS DevOps solution"

# Push
git push origin main
```

**CI/CD pipelines will run automatically!**

### Step 7.3: Verify Workflows

Go to: **Actions** tab in GitHub

You should see:
- ✅ Infrastructure Deployment workflow
- ✅ Application Deployment workflow

Both should complete successfully!

---

## 📸 PART 8: Capture Screenshots (15 minutes)

### Screenshot 1: Login Page (HTTPS)

**What to capture**:
- Full browser window
- URL bar showing: `https://delightverse.mooo.com`
- HTTPS padlock (green/secure)
- Login form visible

**How**:
```
1. Open https://delightverse.mooo.com in browser
2. Make sure URL bar is visible
3. Take full browser screenshot
```

### Screenshot 2: TODO Dashboard

**What to capture**:
- Logged in dashboard
- URL bar showing domain
- At least 1-2 TODO items created
- User info visible

**How**:
```
1. Login with admin/Admin123
2. Create a test TODO: "Test task for HNG submission"
3. Take screenshot of dashboard
```

### Screenshot 3: Terraform Apply Success

**What to capture**:
- Terminal showing `terraform apply` command
- "Apply complete!" message
- Resources created count
- Outputs displayed

**How**:
```bash
cd infra/terraform
terraform apply | tee terraform-apply.log

# Or screenshot your terminal after apply completes
```

### Screenshot 4: Idempotency Proof

**What to capture**:
- Terminal showing `terraform apply` command
- "No changes. Infrastructure is up-to-date." message

**How**:
```bash
terraform apply

# Screenshot the "No changes" output
```

### Screenshot 5: Drift Detection Email

**What to capture**:
- Email inbox showing drift notification
- Subject: "🚨 Terraform Drift Detected"
- Email body with details

**How to trigger**:
```bash
# Method 1: Make manual change on server
ssh -i ~/.ssh/id_rsa ubuntu@<SERVER_IP>
sudo touch /tmp/drift-test.txt
exit

# Method 2: Modify infra code
cd infra/terraform
# Add a comment to main.tf
git add .
git commit -m "test: trigger drift detection"
git push

# Check your email in 2-3 minutes
```

### Screenshot 6: Ansible Deployment Output

**What to capture**:
- Terminal showing ansible-playbook command
- "PLAY RECAP" section
- All tasks ok/changed status

**How**:
```bash
cd infra/ansible
ansible-playbook -i inventory.ini playbook.yml | tee ansible-output.log

# Or re-run: terraform apply
# Ansible runs automatically and you'll see output
```

---

## 🎤 PART 9: Interview Preparation

### Key Questions & Answers

**Q: "Walk me through your architecture"**
```
"I deployed a microservices TODO application on AWS EC2 with 5 services:
Frontend (Vue.js), Auth API (Go), Todos API (Node.js), Users API (Java),
and a Python log processor. All containerized with Docker, orchestrated
with Docker Compose, exposed via Traefik reverse proxy with automatic
HTTPS from Let's Encrypt. Infrastructure is managed with Terraform,
configured with Ansible, and deployed via GitHub Actions CI/CD with
drift detection."
```

**Q: "How does drift detection work?"**
```
"In our CI/CD pipeline, whenever infrastructure code changes, we run
'terraform plan' which compares desired state (our code) with actual
state (AWS resources). If they differ, plan exits with code 2. Our
workflow detects this, sends an email notification, and pauses for
manual approval. Only after approval does terraform apply run. This
prevents unauthorized manual changes from breaking our automation."
```

**Q: "What is idempotency?"**
```
"Idempotency means running the same operation multiple times produces
the same result. In my setup, running 'terraform apply' the first time
creates resources. Running it again shows 'No changes' - it doesn't
recreate anything. This is safe for automation because I can retry
failed deployments without side effects."
```

**Q: "Why AWS over DigitalOcean?"**
```
"AWS is the industry-leading cloud provider with the most comprehensive
services, better for learning enterprise-grade cloud infrastructure.
I used EC2 for compute, Security Groups for firewall, S3 for Terraform
state, and followed AWS IAM best practices for credentials management."
```

**Q: "Why HTTP challenge instead of DNS challenge?"**
```
"My domain is a FreeDNS subdomain (delightverse.mooo.com), so I don't
own the root domain. HTTP challenge works perfectly for this - Traefik
automatically serves the validation file, Let's Encrypt verifies it,
and issues the certificate. It's simpler and requires no API tokens."
```

---

## ✅ Final Checklist

### Configuration:
- [ ] AWS IAM user created with correct permissions
- [ ] Access keys saved securely
- [ ] S3 bucket created for Terraform state
- [ ] SSH keys generated
- [ ] terraform.tfvars configured with your values
- [ ] .env configured with your domain

### Deployment:
- [ ] Terraform initialized
- [ ] Terraform apply completed successfully
- [ ] EC2 instance running
- [ ] All 7 containers running
- [ ] FreeDNS A record updated
- [ ] DNS propagation complete (dig shows your IP)

### Verification:
- [ ] HTTPS working on domain
- [ ] Login works (admin/Admin123)
- [ ] Can create and view TODOs
- [ ] APIs respond correctly
- [ ] Idempotency verified (terraform apply shows "No changes")

### GitHub:
- [ ] All 11 secrets configured
- [ ] Code pushed to repository
- [ ] CI/CD workflows running successfully

### Screenshots:
- [ ] Login page with HTTPS
- [ ] TODO dashboard
- [ ] Terraform apply success
- [ ] Idempotency proof
- [ ] Drift detection email
- [ ] Ansible output

### Submission:
- [ ] Repository URL ready
- [ ] Screenshots organized
- [ ] Application URL accessible
- [ ] Interview preparation done

---

## 🆘 Getting Help

If you encounter issues:

1. **Check logs**:
   ```bash
   docker compose logs -f
   ```

2. **Verify configurations**:
   ```bash
   cat .env
   cat infra/terraform/terraform.tfvars
   ```

3. **Check AWS resources**:
   ```bash
   aws ec2 describe-instances --region us-east-1
   ```

4. **Review documentation**:
   - README.md - Overview
   - This file - Step-by-step guide
   - Troubleshooting section in README

5. **Common issues**:
   - DNS not propagated → Wait 5-10 more minutes
   - Certificate not issued → Check ports 80/443 in security group
   - SSH refused → Use 'ubuntu' user, not 'root'
   - Terraform errors → Check AWS credentials

---

## 🎉 Congratulations!

You've successfully deployed a production-ready microservices application with:
- ✅ AWS EC2 infrastructure
- ✅ Automated SSL certificates
- ✅ Docker containerization
- ✅ Infrastructure as Code
- ✅ Configuration management
- ✅ CI/CD with drift detection
- ✅ Production security practices

**Time to submit and ace that interview!** 🚀

---

**Questions? Review the README.md for additional details and troubleshooting.**
