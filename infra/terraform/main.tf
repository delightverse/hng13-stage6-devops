# Data source to get latest Ubuntu 22.04 AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Get default VPC
data "aws_vpc" "default" {
  default = true
}

# Create SSH key pair
resource "aws_key_pair" "deployer" {
  key_name   = var.ssh_key_name
  public_key = file(var.ssh_public_key_path)

  tags = {
    Name = var.ssh_key_name
  }
}

# Create Security Group
resource "aws_security_group" "app_sg" {
  name        = "${var.instance_name}-sg"
  description = "Security group for TODO app"
  vpc_id      = data.aws_vpc.default.id

  # SSH
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Traefik Dashboard
  ingress {
    description = "Traefik Dashboard"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.instance_name}-sg"
  }
}

# Create EC2 Instance
resource "aws_instance" "app_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.deployer.key_name

  vpc_security_group_ids = [aws_security_group.app_sg.id]

  associate_public_ip_address = true

  root_block_device {
    volume_size           = var.volume_size
    volume_type           = "gp3"
    delete_on_termination = true
  }

  user_data = templatefile("${path.module}/user-data.sh", {
    hostname = var.instance_name
  })

  monitoring = var.enable_monitoring

  tags = merge(
    {
      Name = var.instance_name
    },
    { for k, v in var.tags : k => v }
  )

  lifecycle {
    ignore_changes = [user_data, ami]
  }
}

# Generate Ansible Inventory
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tpl", {
    server_ip            = aws_instance.app_server.public_ip
    ansible_user         = var.ansible_user
    ssh_private_key_path = var.ssh_private_key_path
    github_repo_url      = var.github_repo_url
    github_branch        = var.github_branch
    domain               = var.domain
    jwt_secret           = var.jwt_secret
  })

  filename = "${path.module}/../ansible/inventory.ini"

  depends_on = [aws_instance.app_server]
}

# Wait for server to be ready
resource "null_resource" "wait_for_server" {
  triggers = {
    instance_id = aws_instance.app_server.id
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for server to be ready..."
      timeout=300
      elapsed=0
      while ! ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 \
            -i ${var.ssh_private_key_path} \
            ${var.ansible_user}@${aws_instance.app_server.public_ip} \
            'echo Server is ready'; do
        sleep 5
        elapsed=$((elapsed + 5))
        if [ $elapsed -ge $timeout ]; then
          echo "Timeout waiting for server"
          exit 1
        fi
        echo "Waiting... ($elapsed seconds)"
      done
      echo "Server is ready!"
    EOT
  }

  depends_on = [aws_instance.app_server]
}

# Run Ansible Playbook
resource "null_resource" "run_ansible" {
  count = var.run_ansible ? 1 : 0

  triggers = {
    inventory_content = local_file.ansible_inventory.content
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "Running Ansible playbook..."
      cd ${path.module}/../ansible && \
      ansible-playbook -i inventory.ini playbook.yml
    EOT
  }

  depends_on = [
    local_file.ansible_inventory,
    null_resource.wait_for_server
  ]
}

# Outputs
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.app_server.id
}

output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.app_server.public_ip
}

output "instance_public_dns" {
  description = "Public DNS of the EC2 instance"
  value       = aws_instance.app_server.public_dns
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.app_sg.id
}

output "access_url" {
  description = "Application URL"
  value       = "https://${var.domain}"
}

output "ssh_command" {
  description = "SSH command to connect to instance"
  value       = "ssh -i ${var.ssh_private_key_path} ${var.ansible_user}@${aws_instance.app_server.public_ip}"
}
