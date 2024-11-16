Comprehensive lab that combines hybrid networking, security, and automation in GCP

provider "google" {
  credentials = file("C:\\Users\\jibinb\\Downloads\\terraform-lab-441807-f2b04f4cb5e0.json")
  project     = "terraform-lab-441807"
  region      = "us-central1"
}

# Variables
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "Default region"
  default     = "us-central1"
}

# VPC Network
resource "google_compute_network" "vpc_network" {
  name                    = "hybrid-network"
  auto_create_subnetworks = false
}

# Cloud Subnets
resource "google_compute_subnetwork" "subnet_1" {
  name          = "subnet-1"
  ip_cidr_range = "10.0.1.0/24"
  network       = google_compute_network.vpc_network.id
  region        = var.region
}

resource "google_compute_subnetwork" "subnet_2" {
  name          = "subnet-2"
  ip_cidr_range = "10.0.2.0/24"
  network       = google_compute_network.vpc_network.id
  region        = var.region
}

# Cloud Router for Cloud Interconnect
resource "google_compute_router" "router" {
  name    = "hybrid-router"
  network = google_compute_network.vpc_network.id
  region  = var.region

  bgp {
    asn = 64514
  }
}

# Cloud Interconnect VLAN Attachment
resource "google_compute_interconnect_attachment" "on_prem" {
  name                     = "on-prem-attachment"
  router                   = google_compute_router.router.id
  type                     = "PARTNER"
  edge_availability_domain = "AVAILABILITY_DOMAIN_1"
}

# Cloud Armor Security Policy
resource "google_compute_security_policy" "policy" {
  name = "hybrid-security-policy"

  # Default rule (deny all)
  rule {
    action   = "deny(403)"
    priority = "2147483647"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
  }

  # Allow specific IP ranges (example)
  rule {
    action   = "allow"
    priority = "1000"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["192.168.1.0/24", "10.0.0.0/8"]
      }
    }
  }

  # Rate limiting rule
  rule {
    action   = "throttle"
    priority = "2000"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    rate_limit_options {
      conform_action = "allow"
      exceed_action  = "deny(429)"
      enforce_on_key = "IP"
      rate_limit_threshold {
        count        = 100
        interval_sec = 60
      }
    }
  }
}

# Cloud NAT
resource "google_compute_router_nat" "nat" {
  name                               = "hybrid-nat"
  router                            = google_compute_router.router.name
  region                            = var.region
  nat_ip_allocate_option            = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# Firewall Rules
resource "google_compute_firewall" "allow_internal" {
  name    = "allow-internal"
  network = google_compute_network.vpc_network.id

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "icmp"
  }

  source_ranges = ["10.0.0.0/8"]
}

# Load Balancer
resource "google_compute_global_address" "lb_ip" {
  name = "lb-ip"
}

resource "google_compute_global_forwarding_rule" "lb_rule" {
  name       = "lb-forwarding-rule"
  target     = google_compute_target_http_proxy.lb_proxy.id
  port_range = "80"
  ip_address = google_compute_global_address.lb_ip.address
}

resource "google_compute_target_http_proxy" "lb_proxy" {
  name    = "lb-proxy"
  url_map = google_compute_url_map.lb_url_map.id
}

resource "google_compute_url_map" "lb_url_map" {
  name            = "lb-url-map"
  default_service = google_compute_backend_service.lb_backend.id
}

resource "google_compute_backend_service" "lb_backend" {
  name        = "lb-backend"
  protocol    = "HTTP"
  timeout_sec = 10

  security_policy = google_compute_security_policy.policy.id

  health_checks = [google_compute_health_check.lb_health.id]
}

resource "google_compute_health_check" "lb_health" {
  name               = "lb-health"
  check_interval_sec = 5
  timeout_sec        = 5
  
  http_health_check {
    port = 80
  }
}

# Outputs
output "interconnect_attachment_id" {
  value = google_compute_interconnect_attachment.on_prem.id
}

output "load_balancer_ip" {
  value = google_compute_global_address.lb_ip.address
}
