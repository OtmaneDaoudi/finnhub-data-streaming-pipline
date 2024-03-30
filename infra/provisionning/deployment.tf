# Declaration of variables for user and file configuration
variable "gcpUserID" {}
variable "project" {}
variable "region" {}
variable "zone" {}
variable "deployKeyName" {}
variable "workersVMSCount" {}
variable "mastersVMSCount" {}
variable "machineType" {}
variable "osImage" {}

# Generate a new SSH key
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Write the private key to a local file
resource "local_sensitive_file" "private_key" {
  content        = tls_private_key.ssh.private_key_pem
  filename       = "${path.module}/id_rsa"
  file_permission = "0600"
}

# Google Cloud provider configuration with project, region, and zone details
provider "google" {
  credentials = file(var.deployKeyName)
  project     = var.project
  region      = var.region
  zone        = var.zone
}

# Creation of a Google Compute Network without auto-creating subnetworks
resource "google_compute_network" "default" {
  name                    = "sdtd-network"
  auto_create_subnetworks = "false"
}

# Creation of a subnetwork within the defined network with a specific IP range
resource "google_compute_subnetwork" "default" {
  name          = "sdtd-sub-network"
  network       = google_compute_network.default.name
  ip_cidr_range = "192.168.7.0/24"
}

# Internal firewall rules allowing specific protocols and ports within the network
resource "google_compute_firewall" "internal" {
  name    = "allow-internal"
  network = google_compute_network.default.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "udp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22", "6443", "2379-2380", "10250", "10259", "10257", "30000-32767"]
  }

  source_ranges = ["192.168.7.0/24"]
}

# External firewall rules allowing access from any source to specific ports
resource "google_compute_firewall" "external" {
  name    = "allow-external"
  network = google_compute_network.default.name

  allow {
    protocol = "tcp"
    ports    = ["22", "443", "80", "8080", "8081", "8082"]
  }

  source_ranges = ["0.0.0.0/0"]
}

# Reserve a static external IP address in the specified region
resource "google_compute_address" "gateway-public-ip" {
  name   = "gateway-public-ip"
  region = var.region
}

# Gateway server instance configuration including network and provisioning details
resource "google_compute_instance" "gateway-server" {
  name         = "gateway-server"
  machine_type = var.machineType
  zone         = var.zone
  tags         = ["gateway"]

  boot_disk {
    initialize_params {
      image = var.osImage
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.default.name
    network_ip = "192.168.7.30"
    access_config {
      nat_ip = google_compute_address.gateway-public-ip.address
    }
  }

  # Remote script execution for server configuration
  provisioner "remote-exec" {
    inline = [
      "mkdir -p /tmp/configuration/",
      "mkdir -p /tmp/scripts/",
      "sudo apt-get update",
      "sudo apt-get install -y software-properties-common",
      "sudo add-apt-repository --yes --update ppa:ansible/ansible",
      "sudo apt-get install -y ansible",
      "sudo apt-get install jq -y"
    ]

    connection {
      type        = "ssh"
      user        = var.gcpUserID
      private_key = local_sensitive_file.private_key.content
      host        = self.network_interface[0].access_config[0].nat_ip
    }
  }

  # File provisioning for private key and script files
  provisioner "file" {
    source      = local_sensitive_file.private_key.filename
    destination = "/tmp/google_compute_engine"

    connection {
      type        = "ssh"
      user        = var.gcpUserID
      private_key = local_sensitive_file.private_key.content
      host        = self.network_interface[0].access_config[0].nat_ip
    }
  }

  provisioner "file" {
    source      = "../scripts/"
    destination = "/tmp/scripts/"

    connection {
      type        = "ssh"
      user        = var.gcpUserID
      private_key = local_sensitive_file.private_key.content
      host        = self.network_interface[0].access_config[0].nat_ip
    }
  }

  provisioner "file" {
    source      = "../configuration/"
    destination = "/tmp/configuration/"

    connection {
      type        = "ssh"
      user        = var.gcpUserID
      private_key = local_sensitive_file.private_key.content
      host        = self.network_interface[0].access_config[0].nat_ip
    }
  }

  # Final remote execution for server setup and configuration
  provisioner "remote-exec" {
    inline = [
      "chmod 600 /tmp/google_compute_engine",
      "chmod +x /tmp/scripts/configure.sh",
      "/tmp/scripts/configure.sh"
    ]

    connection {
      type        = "ssh"
      user        = var.gcpUserID
      private_key = local_sensitive_file.private_key.content
      host        = self.network_interface[0].access_config[0].nat_ip
    }
  }
}

# Creation of master compute instances with dynamic naming and network settings
resource "google_compute_instance" "master" {
  count        = var.mastersVMSCount
  name         = "master-${count.index}"
  machine_type = var.machineType
  zone         = var.zone
  tags         = ["master"]

  boot_disk {
    initialize_params {
      image = var.osImage
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.default.name
    network_ip = "192.168.7.1${count.index}"
  }
}

# Creation of worker compute instances with dynamic naming and network settings
resource "google_compute_instance" "worker" {
  count        = var.workersVMSCount
  name         = "worker-${count.index}"
  machine_type = var.machineType
  zone         = var.zone
  tags         = ["worker"]

  boot_disk {
    initialize_params {
      image = var.osImage
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.default.name
    network_ip = "192.168.7.2${count.index}"
  }
}

# Configuration of Cloud Router for NAT
resource "google_compute_router" "nat_router" {
  name    = "nat-router"
  network = google_compute_network.default.name
  region  = var.region

  bgp {
    asn = 64514
  }
}

# Configuration of Cloud NAT Gateway for internet access
resource "google_compute_router_nat" "nat_gateway" {
  name                               = "nat-gateway"
  router                             = google_compute_router.nat_router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# Add the generated public key to the project metadata
resource "google_compute_project_metadata" "default" {
  metadata = {
    ssh-keys = "${var.gcpUserID}:${tls_private_key.ssh.public_key_openssh}"
  }
}