# ─────────────────────────────────────────────
# SSH Key Pair for Jenkins VM
# ─────────────────────────────────────────────
resource "tls_private_key" "jenkins" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save private key to local file
resource "local_file" "jenkins_private_key" {
  content         = tls_private_key.jenkins.private_key_pem
  filename        = "${path.root}/jenkins_key.pem"
  file_permission = "0600"
}

# ─────────────────────────────────────────────
# Public IP for Jenkins VM
# ─────────────────────────────────────────────
resource "azurerm_public_ip" "jenkins" {
  name                = "jenkins-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    project    = "portfolio"
    managed_by = "terraform"
  }
}

# ─────────────────────────────────────────────
# Network Security Group for Jenkins
# ─────────────────────────────────────────────
resource "azurerm_network_security_group" "jenkins" {
  name                = "jenkins-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Allow SSH (for setup and debugging)
  security_rule {
    name                       = "AllowSSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow Jenkins UI
  security_rule {
    name                       = "AllowJenkins"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow Jenkins JNLP agent port
  security_rule {
    name                       = "AllowJNLP"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "50000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    project    = "portfolio"
    managed_by = "terraform"
  }
}

# ─────────────────────────────────────────────
# Network Interface Card
# ─────────────────────────────────────────────
resource "azurerm_network_interface" "jenkins" {
  name                = "jenkins-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "jenkins-ipconfig"
    subnet_id                     = var.jenkins_subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.jenkins.id
  }

  tags = {
    project    = "portfolio"
    managed_by = "terraform"
  }
}

resource "azurerm_network_interface_security_group_association" "jenkins" {
  network_interface_id      = azurerm_network_interface.jenkins.id
  network_security_group_id = azurerm_network_security_group.jenkins.id
}

# ─────────────────────────────────────────────
# Jenkins Virtual Machine
# ─────────────────────────────────────────────
resource "azurerm_linux_virtual_machine" "jenkins" {
  name                = "jenkins-vm"
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.vm_size
  admin_username      = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.jenkins.id
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = tls_private_key.jenkins.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 50
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  # Cloud-init script to auto-install Jenkins, Docker, Trivy, Azure CLI
  custom_data = base64encode(<<-EOF
    #!/bin/bash
    set -e
    echo "===== Starting Jenkins setup ====="

    # Update packages
    apt-get update -y
    apt-get upgrade -y

    # ── Install Java (Jenkins dependency) ──────────────────────────
    apt-get install -y openjdk-17-jdk

    # ── Install Docker ─────────────────────────────────────────────
    apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io

    # ── Install Jenkins ────────────────────────────────────────────
    wget -q -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
    echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" > /etc/apt/sources.list.d/jenkins.list
    apt-get update -y
    apt-get install -y jenkins

    # Add jenkins user to docker group (so Jenkins can run docker commands)
    usermod -aG docker jenkins
    usermod -aG docker ${var.admin_username}

    # ── Install Trivy (security scanner) ──────────────────────────
    wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor -o /usr/share/keyrings/trivy.gpg
    echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" > /etc/apt/sources.list.d/trivy.list
    apt-get update -y
    apt-get install -y trivy

    # ── Install Azure CLI ──────────────────────────────────────────
    curl -sL https://aka.ms/InstallAzureCLIDeb | bash

    # ── Install Git ────────────────────────────────────────────────
    apt-get install -y git

    # ── Install kubectl ────────────────────────────────────────────
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

    # ── Start and enable services ──────────────────────────────────
    systemctl enable docker
    systemctl start docker
    systemctl enable jenkins
    systemctl start jenkins

    echo "===== Jenkins setup complete ====="
    echo "Access Jenkins at: http://$(curl -s ifconfig.me):8080"
    echo "Initial admin password:"
    cat /var/lib/jenkins/secrets/initialAdminPassword || echo "Jenkins still starting..."
  EOF
  )

  tags = {
    project    = "portfolio"
    managed_by = "terraform"
  }
}

# ─────────────────────────────────────────────
# Outputs
# ─────────────────────────────────────────────
output "public_ip" {
  value = azurerm_public_ip.jenkins.ip_address
}

output "private_ip" {
  value = azurerm_network_interface.jenkins.private_ip_address
}
