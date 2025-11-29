# HNG13 DevOps Stage6 Task

This Repo Contains the code for a microservice application comprising of several components communicating to each other. In other words, this is an example of microservice. These microservices are written in different languages.

The app itself is a simple TODO app that additionally authenticates users.

## Components

1. [Frontend](/frontend) part is a Javascript application, provides UI. Created with [VueJS](http://vuejs.org)
2. [Auth API](/auth-api) is written in Go and provides authorization functionality. Generates JWT tokens to be used with other APIs.
3. [TODOs API](/todos-api) is written with NodeJS, provides CRUD functionality ove user's todo records. Also, it logs "create" and "delete" operations to Redis queue, so they can be later processed by [Log Message Processor](/log-message-processor).
4. [Users API](/users-api) is a Spring Boot project written in Java. Provides user profiles. Does not provide full CRUD for simplicity, just getting a single user and all users.
5. [Log Message Processor](/log-message-processor) is a very short queue processor written in Python. It's sole purpose is to read messages from Redis queue and print them to stdout


The diagram describes the various components and their interactions.
![microservice-app-example](https://user-images.githubusercontent.com/1905821/34918427-a931d84e-f952-11e7-85a0-ace34a2e8edb.png)

Note: 3 different login details are provided in the .env file 

## License

MIT

---
---
---

# 🚀 TODO Microservices Application - AWS + FreeDNS Setup

Complete DevOps solution for containerized microservices with AWS infrastructure, FreeDNS domain, automated SSL certificates, and CI/CD pipelines with drift detection.

## 📋 Your Configuration

```
☁️  Cloud Provider:  AWS (Amazon Web Services)
🌐 Domain:          delightverse.mooo.com (FreeDNS subdomain)
🔒 SSL:             Let's Encrypt via HTTP Challenge
🐳 Containers:      Docker & Docker Compose
🚦 Reverse Proxy:   Traefik with automatic HTTPS
🏗️  Infrastructure:  Terraform (AWS EC2, Security Groups, S3)
🎭 Configuration:   Ansible (automated server setup)
🚀 CI/CD:           GitHub Actions with drift detection
```

---

## 🎯 Application Services

- **Frontend** - Vue.js SPA (Nginx)
- **Auth API** - Go authentication service
- **Todos API** - Node.js CRUD operations
- **Users API** - Java Spring Boot user management
- **Log Processor** - Python background worker
- **Redis Queue** - Message broker

---

## ⚡ Quick Start

### Prerequisites

1. **AWS Account** with:
   - IAM user with EC2/VPC/S3 permissions
   - Access Key ID and Secret Access Key
   - S3 bucket for Terraform state

2. **FreeDNS Account** with:
   - Subdomain configured (delightverse.mooo.com)

3. **Local Tools**:
   - Terraform >= 1.5.0
   - Ansible >= 2.15.0
   - SSH key pair
   - Git

4. **GitHub Repository**:
   - Fork of the application repository
   - GitHub Actions enabled

---

## 🚀 Deployment (3 Steps)

### Step 1: Configure Credentials

```bash
# 1. Create terraform.tfvars
cd infra/terraform
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
```

Fill in your values:
```hcl
aws_access_key = "AKIA..."
aws_secret_key = "wJalrXUtnFEMI/..."
aws_region     = "us-east-1"

domain = "delightverse.mooo.com"
jwt_secret = "myfancysecret"

github_repo_url = "https://github.com/delightverse/hng13-stage6-devops.git"
```

### Step 2: Deploy Infrastructure

```bash
# Initialize Terraform
terraform init \
  -backend-config="bucket=your-terraform-state-bucket" \
  -backend-config="key=todo-app/terraform.tfstate" \
  -backend-config="region=us-east-1"

# Deploy everything
terraform apply
```

**This ONE command will:**
1. ✅ Create EC2 instance on AWS
2. ✅ Configure security groups (ports 22, 80, 443, 8080)
3. ✅ Install Docker and all dependencies
4. ✅ Clone your GitHub repository
5. ✅ Build and start all containers
6. ✅ Configure Traefik with automatic HTTPS
7. ✅ Set up auto-start on boot

**Wait 5-10 minutes** for deployment to complete.

### Step 3: Update FreeDNS

```bash
# Get your EC2 public IP
terraform output instance_public_ip
# Example: 54.123.45.67

# Update FreeDNS:
# 1. Go to https://freedns.afraid.org/
# 2. Update A record for "delightverse" 
# 3. Set IP to your EC2 IP
# 4. Wait 5-10 minutes for DNS propagation
```

### Step 4: Verify Deployment

```bash
# Check DNS
dig delightverse.mooo.com
# Should show your EC2 IP

# Visit your application
# https://delightverse.mooo.com
```

**Login credentials**:
- Username: `admin` Password: `Admin123`
- Username: `hng` Password: `HngTech`
- Username: `user` Password: `Password`

---

## 🔧 Local Development

### Test Locally Before Deploying

```bash
# 1. Create environment file
cp .env.example .env
nano .env  # Add your domain

# 2. Create Docker networks
docker network create web
docker network create backend

# 3. Initialize Traefik
touch traefik/acme.json
chmod 600 traefik/acme.json

# 4. Start services
docker compose up -d

# 5. Check logs
docker compose logs -f

# 6. Visit http://localhost
```

---

## 🌐 Production Architecture

### Network Architecture:
```
Internet
    ↓
Traefik (ports 80/443/8080)
    ↓
┌─────────────────┐
│  Web Network    │
├─────────────────┤
│ - Frontend      │
│ - Auth API      │
│ - Todos API     │
│ - Users API     │
└─────────────────┘
         ↓
┌─────────────────┐
│ Backend Network │
├─────────────────┤
│ - Redis Queue   │
│ - Log Processor │
└─────────────────┘
```

### SSL Certificate Flow:
```
1. Traefik requests certificate from Let's Encrypt
2. Let's Encrypt: "Serve file at http://domain/.well-known/acme-challenge/xyz"
3. Traefik serves file automatically
4. Let's Encrypt verifies and issues certificate
5. Certificate saved to acme.json
6. Auto-renewal every 90 days
```

---

## 🎯 Infrastructure Components

### AWS Resources Created:
- **EC2 Instance**: t3.medium (2 vCPU, 4GB RAM)
- **Security Group**: Ports 22, 80, 443, 8080
- **EBS Volume**: 30GB gp3
- **Key Pair**: SSH access
- **Elastic IP**: (optional)

### Terraform State:
- **Backend**: AWS S3
- **State File**: `todo-app/terraform.tfstate`
- **Locking**: Enabled
- **Versioning**: Enabled

### Ansible Roles:
1. **dependencies**: Installs Docker, Docker Compose, Git
2. **deploy**: Clones repo, builds images, starts services

---

## 🔄 CI/CD Pipeline

### Infrastructure Pipeline (Drift Detection)

**Triggers**: Changes to `infra/` directory

**Workflow**:
```
1. terraform plan (check for drift)
2. If drift detected:
   ├─ Send email notification
   ├─ Pause for manual approval
   └─ Apply after approval
3. If no drift:
   └─ Apply automatically
4. Send success notification
```

### Application Pipeline

**Triggers**: Changes to service code

**Workflow**:
```
1. Detect changed services
2. Build Docker images
3. Deploy via Ansible (deploy role only)
4. Verify endpoints
5. Send notification
```

### Required GitHub Secrets:
```
AWS_ACCESS_KEY_ID       - Your AWS access key
AWS_SECRET_ACCESS_KEY   - Your AWS secret key
DOMAIN                  - delightverse.mooo.com
JWT_SECRET              - myfancysecret
TF_STATE_BUCKET         - Your S3 bucket name
SERVER_IP               - EC2 public IP (after first deployment)
SSH_PRIVATE_KEY         - Contents of ~/.ssh/id_rsa
EMAIL_USERNAME          - Gmail address
EMAIL_PASSWORD          - Gmail app password
NOTIFICATION_EMAIL      - Where to send alerts
```

---

## 🛠️ Common Commands

### Terraform Commands:
```bash
# View current state
terraform show

# View outputs
terraform output

# Plan changes
terraform plan

# Apply changes
terraform apply

# Destroy everything
terraform destroy
```

### Server Management:
```bash
# SSH to server
ssh -i ~/.ssh/id_rsa ubuntu@<EC2_IP>

# View containers
docker ps

# View logs
docker compose logs -f

# Restart services
docker compose restart

# Rebuild and restart
docker compose up -d --build

# Stop all services
docker compose down
```

### AWS CLI Commands:
```bash
# List EC2 instances
aws ec2 describe-instances --region us-east-1

# Stop instance (save costs)
aws ec2 stop-instances --instance-ids i-xxxxx

# Start instance
aws ec2 start-instances --instance-ids i-xxxxx

# Get public IP
aws ec2 describe-instances \
  --instance-ids i-xxxxx \
  --query 'Reservations[].Instances[].PublicIpAddress' \
  --output text
```

---

## 🎓 Key Features Explained

### ✅ Idempotency
Run `terraform apply` multiple times → "No changes"
- Safe to re-run deployments
- Won't create duplicate resources
- Predictable outcomes

**Proof**:
```bash
terraform apply  # Creates resources
terraform apply  # "No changes. Infrastructure is up-to-date."
```

### ✅ Drift Detection
Detects when actual infrastructure differs from code.

**How it works**:
```
Manual change on server
    ↓
CI/CD runs terraform plan
    ↓
Exit code 2 = drift detected
    ↓
Send email alert
    ↓
Wait for manual approval
    ↓
Apply changes
```

### ✅ Automatic SSL
- Let's Encrypt certificates
- HTTP challenge (no DNS API needed)
- Auto-renewal every 90 days
- Automatic HTTP → HTTPS redirect

### ✅ Security
- Non-root containers
- Security groups (firewall)
- SSH key authentication
- Environment variable secrets
- Network isolation

---

## 📸 Required Screenshots for Submission

1. **Login Page**: https://delightverse.mooo.com with HTTPS lock
2. **TODO Dashboard**: Logged in, showing todos
3. **Terraform Apply**: "Apply complete!" output
4. **Idempotency Proof**: "No changes" message
5. **Drift Detection Email**: Notification from CI/CD
6. **Ansible Output**: "PLAY RECAP" summary

---

## 🐛 Troubleshooting

### Issue: "UnauthorizedOperation" in Terraform
**Solution**: Check IAM user permissions (needs EC2FullAccess, VPCFullAccess, S3FullAccess)

### Issue: SSH connection refused
**Solution**: 
- Wait 2-3 minutes after instance creation
- Use correct user: `ubuntu` (not `root`)
- Check security group allows port 22

### Issue: SSL certificate not issued
**Solution**:
```bash
# On server, check Traefik logs
docker compose logs traefik | grep -i certificate

# Common causes:
- Ports 80/443 not open in security group
- DNS not pointing to server
- Wait 5-10 minutes after DNS update
```

### Issue: Services not accessible
**Solution**:
```bash
# Check if containers are running
docker ps

# Check Traefik routing
docker compose logs traefik

# Verify DNS
dig delightverse.mooo.com
```

### Issue: Terraform state lock
**Solution**:
```bash
terraform force-unlock <LOCK_ID>
```

---

## 💰 Cost Estimate

```
AWS EC2 t3.medium:      ~$30-35/month
EBS 30GB storage:       ~$3/month
Data transfer:          ~$5/month
S3 state storage:       ~$0.10/month
───────────────────────────────────────
Total:                  ~$40/month
```

**To minimize costs**:
- Stop instance when not in use: `aws ec2 stop-instances`
- Use t3.small instead: ~$15/month
- Delete after task completion: `terraform destroy`

---

## 📚 Documentation Structure

```
/
├── README.md                    ← You are here
├── IMPLEMENTATION.md            ← Step-by-step deployment guide
├── auth-api/Dockerfile          ← Go service container
├── todos-api/Dockerfile         ← Node.js service container
├── users-api/Dockerfile         ← Java Spring Boot container
├── frontend/Dockerfile          ← Vue.js + Nginx container
├── log-message-processor/       ← Python worker container
├── docker-compose.yml           ← Orchestration
├── traefik/                     ← Reverse proxy config
│   ├── traefik.yml             ← Static config (HTTP challenge)
│   └── config.yml              ← Dynamic config
├── infra/
│   ├── terraform/              ← AWS infrastructure
│   │   ├── provider.tf         ← AWS provider, S3 backend
│   │   ├── main.tf             ← EC2, security groups
│   │   ├── variables.tf        ← Variable definitions
│   │   ├── terraform.tfvars.example
│   │   └── user-data.sh        ← Server initialization
│   └── ansible/                ← Configuration management
│       ├── playbook.yml        ← Main playbook
│       └── roles/
│           ├── dependencies/   ← Install Docker, etc.
│           └── deploy/         ← Deploy application
└── .github/workflows/          ← CI/CD
    ├── infra-deploy.yml        ← Infrastructure with drift detection
    └── app-deploy.yml          ← Application deployment
```

---

## ✅ Success Criteria

Your deployment is successful when:
- ✅ `terraform apply` completes without errors
- ✅ All 7 containers running: `docker ps`
- ✅ HTTPS working: https://delightverse.mooo.com
- ✅ Login works with provided credentials
- ✅ Can create and view TODOs
- ✅ APIs respond correctly
- ✅ Second `terraform apply` shows "No changes"

---

## 🤝 Support

For issues or questions:
1. Check this README
2. Review IMPLEMENTATION.md
3. Check troubleshooting section
4. Review logs: `docker compose logs`
5. Verify configurations in `.env` and `terraform.tfvars`

---

## 📝 Important Notes

- ⚠️ **Default user on AWS Ubuntu**: `ubuntu` (not `root`)
- ⚠️ **Public IP changes**: After stop/start, update FreeDNS
- ⚠️ **Costs**: ~$40/month, destroy when done
- ⚠️ **Traefik setup**: Automated by Ansible (no manual steps)
- ⚠️ **DNS propagation**: Can take 5-10 minutes
- ⚠️ **First deployment**: Takes 10-15 minutes

---

**Built for HNG DevOps Stage 6 Task** 🚀

Complete production-ready solution following AWS best practices and DevOps principles.
