provider "google" {
  credentials = file("C:\\Users\\jilub\\Downloads\\terraform-lab-441807-f2b04f4cb5e0.json")
  project     = "terraform-lab-441807"
  region      = "us-central1"
}

# Instance Template
resource "google_compute_instance_template" "example_instance_template" {
  name = "example-instance-template"
  
  disk {
    auto_delete = true
    boot        = true
    source_image = "debian-cloud/debian-12" # Replace with the correct image
  }

  network_interface {
    network = "default"
  }

  machine_type = "e2-micro"
}

# Managed Instance Group
resource "google_compute_instance_group_manager" "example_instance_group" {
  name               = "example-instance-group"
  base_instance_name = "example-instance"
  target_size        = 2
  zone               = "us-central1-a"

  version {
    instance_template = google_compute_instance_template.example_instance_template.id
  }

  auto_healing_policies {
    health_check    = google_compute_health_check.example_health_check.id
    initial_delay_sec = 300
  }
}

# Health Check
resource "google_compute_health_check" "example_health_check" {
  name               = "example-health-check"
  check_interval_sec = 5
  timeout_sec        = 5

  http_health_check {
    request_path = "/"
    port         = 80
  }
}

# Backend Service
resource "google_compute_backend_service" "example_backend" {
  name = "example-backend"

  backend {
    group = google_compute_instance_group_manager.example_instance_group.instance_group
  }

  health_checks = [google_compute_health_check.example_health_check.id]
  port_name     = "http"
  protocol      = "HTTP"
  timeout_sec   = 10

  depends_on = [
    google_compute_health_check.example_health_check
  ]
}

# URL Map
resource "google_compute_url_map" "example_url_map" {
  name            = "example-url-map"
  default_service = google_compute_backend_service.example_backend.self_link

  depends_on = [
    google_compute_backend_service.example_backend
  ]
}

#proxy
resource "google_compute_target_http_proxy" "example_http_proxy" {
  name    = "example-http-proxy"
  url_map = google_compute_url_map.example_url_map.self_link

  depends_on = [
    google_compute_url_map.example_url_map
  ]
}

# Global Forwarding Rule
resource "google_compute_global_forwarding_rule" "example_http_forwarding_rule" {
  name       = "example-http-forwarding-rule"
  target     = google_compute_target_http_proxy.example_http_proxy.self_link
  port_range = "80"
  ip_address = google_compute_global_address.example_address.address
}

# Global IP Address
resource "google_compute_global_address" "example_address" {
  name = "example-ip-address"
}

# Assign IAM role to a user for managing the load balancer
resource "google_project_iam_member" "lb_admin" {
  project = "terraform-lab-441807"
  role    = "roles/compute.loadBalancerAdmin"
  member  = "serviceAccount:terraform@terraform-lab-441807.iam.gserviceaccount.com"
}

resource "google_compute_network" "custom_vpc" {
  name = "custom-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_firewall" "allow_lb_traffic" {
 name    = "allow-lb-traffic"
 network = google_compute_network.custom_vpc.name

 allow {
   protocol = "tcp"
   ports    = ["80"]
 }

 source_ranges = ["130.211.0.0/22", "35.191.0.0/16"] # IP ranges for GCP load balancers
 target_tags   = ["web-server"]
}



