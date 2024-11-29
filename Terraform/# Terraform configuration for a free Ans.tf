# Terraform configuration for a free Ansible lab in GCP

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

# Variables
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP Zone"
  type        = string
  default     = "us-central1-a"
}

# Provider Configuration
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# VPC Network
resource "google_compute_network" "ansible_network" {
  name                    = "ansible-lab-network"
  auto_create_subnetworks = false
}

# Subnet
resource "google_compute_subnetwork" "ansible_subnet" {
  name          = "ansible-lab-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.ansible_network.id
}

# SSH Firewall Rule
resource "google_compute_firewall" "allow_ssh" {
  name    = "ansible-lab-allow-ssh"
  network = google_compute_network.ansible_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh-enabled"]
}

# Internal Network Firewall Rule
resource "google_compute_firewall" "allow_internal" {
  name    = "ansible-lab-allow-internal"
  network = google_compute_network.ansible_network.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  source_ranges = ["10.0.0.0/16"]
}

# SSH Key for Instance Access
resource "google_compute_project_metadata" "ssh_keys" {
  metadata = {
    ssh-keys = "SHA256:4Cfme4jAwy/bl6N2VbAOjkYJ5S0ga4BVh/8dbR5ffnY jibinbenny06@cs-424683024175-default"
  }
}

# Ansible Controller Instance
resource "google_compute_instance" "ansible_controller" {
  name         = "ansible-controller"
  machine_type = "f1-micro"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.ansible_subnet.name
    access_config {
      # Ephemeral IP
    }
  }

  tags = ["ssh-enabled"]

  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y software-properties-common
    apt-add-repository --yes --update ppa:ansible/ansible
    apt-get install -y ansible git python3-pip
    pip3 install ansible
    EOF
}

# Ansible Target Instances
resource "google_compute_instance" "ansible_targets" {
  count        = 2
  name         = "ansible-target-${count.index + 1}"
  machine_type = "f1-micro"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.ansible_subnet.name
    access_config {
      # Ephemeral IP
    }
  }

  tags = ["ssh-enabled"]
}

# Outputs
output "controller_ip" {
  value = google_compute_instance.ansible_controller.network_interface[0].access_config[0].nat_ip
}

output "target_ips" {
  value = google_compute_instance.ansible_targets[*].network_interface[0].access_config[0].nat_ip
}
