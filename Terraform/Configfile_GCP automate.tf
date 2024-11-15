# Terraform configuration file

# Define the provider
provider "google" {
  credentials = file("<path_to_your_service_account_key>.json")
  project = "<airy-adapter-439306-c6>"
  region  = "us-central1"
}

# Create a VPC network
resource "google_compute_network" "custom_vpc" {
  name                    = "custom-vpc"
  auto_create_subnetworks = false  # Disable auto mode to use custom subnets
}

# Create a subnet in the VPC
resource "google_compute_subnetwork" "subnet1" {
  name          = "subnet1"
  ip_cidr_range = "10.0.1.0/24"
  region        = "us-central1"
  network       = google_compute_network.custom_vpc.self_link
}

# Define firewall rule to allow SSH traffic
resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.custom_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]  # Be cautious with this rule; allow only necessary IPs in production
}
