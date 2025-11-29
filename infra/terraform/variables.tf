variable "aws_access_key" {
  description = "AWS Access Key ID"
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS Secret Access Key"
  type        = string
  sensitive   = true
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "ssh_key_name" {
  description = "Name of SSH key pair in AWS"
  type        = string
  default     = "devops-ssh-key"
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "ssh_private_key_path" {
  description = "Path to SSH private key"
  type        = string
  default     = "~/.ssh/id_rsa"
}

variable "instance_name" {
  description = "Name of the EC2 instance"
  type        = string
  default     = "todo-app-server"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 30
}

variable "github_repo_url" {
  description = "GitHub repository URL"
  type        = string
}

variable "github_branch" {
  description = "Git branch to deploy"
  type        = string
  default     = "main"
}

variable "domain" {
  description = "Domain name for the application"
  type        = string
}

variable "jwt_secret" {
  description = "JWT secret for authentication"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default = {
    Environment = "production"
    Project     = "todo-app"
  }
}

variable "enable_monitoring" {
  description = "Enable detailed monitoring"
  type        = bool
  default     = true
}

variable "ansible_user" {
  description = "User for Ansible"
  type        = string
  default     = "ubuntu"
}

variable "run_ansible" {
  description = "Run Ansible after provisioning"
  type        = bool
  default     = true
}
