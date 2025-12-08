variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "todo-app"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key (optional, use ssh_public_key instead in CI/CD)"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key content (use this in CI/CD instead of file path)"
  type        = string
}

variable "ssh_private_key_path" {
  description = "Path to SSH private key"
  type        = string
}

variable "domain" {
  description = "The home domain"
  type        = string
}

variable "acme_email" {
  description = "Acme email"
  type        = string
}

variable "jwt_secret" {
  description = "JWT secret"
  type        = string
  default     = "myfancysecret"
}

variable "github_repo" {
  description = "The github repo that holds the codebase"
  type        = string
}
