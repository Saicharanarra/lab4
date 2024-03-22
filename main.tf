provider "google" {
  project = "premium-apex-300708"  // Specify your project id
  region  = "us-central1"          // Specify region
}

resource "google_compute_network" "default" {
  name                    = "arra-vpc-network"        // Give the VPC name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "network-with-private-secondary-ip-ranges" {
  name          = "arra-subnetwork1"                 // Give the subnet name
  ip_cidr_range = "10.0.2.0/24"                      // Give the CIDR range
  region        = "us-central1"                      // Specify region

  network = google_compute_network.default.self_link // Specify VPC

  secondary_ip_range {
    range_name    = "tf-test-secondary-range-update1"
    ip_cidr_range = "10.0.3.0/24"
  }
}

resource "google_compute_instance" "default" {
  name         = "arra-terraform-test"               // Give the instance name
  machine_type = "f1-micro"                          // Choose machine_type
  zone         = "us-central1-a"                     // Specify zone
  tags         = ["foo", "bar"]                      // Give the tags

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"               // Choose image
    }
  }

  network_interface {
    network    = google_compute_network.default.self_link                // Specify VPC
    subnetwork = google_compute_subnetwork.network-with-private-secondary-ip-ranges.self_link // Specify subnet
    access_config {
    }
  }

  metadata = {
    foo = "bar"
  }

  // Install Docker and run the container on instance startup
  metadata_startup_script = <<-EOF
    #!/bin/bash
    sudo apt-get update
    sudo apt-get install -y docker.io
    sudo docker run -d -p 80:80 gcr.io/premium-apex-300708/arra-flask-backend-image:latest
  EOF
}

// Allow all firewall rule
resource "google_compute_firewall" "shubhi-firewall" {
  name        = "arra-firewall"                      // Give the name
  network     = google_compute_network.default.self_link    // Specify the VPC
  allow {
    protocol = "all"
  }
  source_ranges = [ "0.0.0.0/0" ]
}
