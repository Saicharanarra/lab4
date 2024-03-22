# Provider configuration for Google Cloud Platform
provider "google" {
  project = "premium-apex-300708"  # Provide the project ID as a string
  region  = "us-east1"             # Provide the region as a string
}

# Create a VPC network
resource "google_compute_network" "arra_vpc_network" {
  name = "my-vpc"
}

# Create a subnet for the private instances
resource "google_compute_subnetwork" "arra_subnet_private" {
  name          = "private-subnet"
  ip_cidr_range = "10.0.1.0/24"    # Provide the subnet CIDR range in CIDR notation
  region        = "us-east1"
  network       = google_compute_network.arra_vpc_network.self_link
}

# Create a subnet for the public instances
resource "google_compute_subnetwork" "arra_subnet_public" {
  name          = "public-subnet"
  ip_cidr_range = "10.0.2.0/24"    # Provide the subnet CIDR range in CIDR notation
  region        = "us-east1"
  network       = google_compute_network.arra_vpc_network.self_link
}

# Create a firewall rule to allow traffic on the application port
resource "google_compute_firewall" "arra_app_firewall" {
  name    = "allow-app-port"
  network = google_compute_network.arra_vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
}

# Create a Google Compute Engine instance
resource "google_compute_instance" "arra_vm_instance" {
  name         = "my-instance"
  machine_type = "n1-standard-1"
  zone         = "us-east1-zone1"  # Update the zone name as needed

  # Attach the instance to the public subnet
  network_interface {
    subnetwork = google_compute_subnetwork.arra_subnet_public.self_link
    access_config {
      // Assign a public IP address to the instance
    }
  }

  # Install Docker and run the container on instance startup
  metadata_startup_script = <<-EOF
    #!/bin/bash
    sudo apt-get update
    sudo apt-get install -y docker.io
    sudo docker run -d -p 80:80 gcr.io/${var.project_id}/flask-backend-image:latest
  EOF
}
