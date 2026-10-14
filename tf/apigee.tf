# Copyright 2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

resource "google_compute_address" "internal_vip" {
  project      = var.project_id
  name         = "${var.unique_name}-internal-vip"
  subnetwork   = data.google_compute_subnetwork.subnet.id
  address_type = "INTERNAL"
  region       = var.region
}

resource "tls_private_key" "private_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "self_signed_cert" {
  private_key_pem = tls_private_key.private_key.private_key_pem

  subject {
    common_name  = "${var.unique_name}.${var.dns_name}"
    organization = "Apigee Internal"
  }

  validity_period_hours = 8760

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "google_compute_region_ssl_certificate" "internal_cert" {
  project     = var.project_id
  name        = "${var.unique_name}-internal-cert"
  region      = var.region
  private_key = tls_private_key.private_key.private_key_pem
  certificate = tls_self_signed_cert.self_signed_cert.cert_pem
}

/* DNS */

resource "google_dns_managed_zone" "nip_io_private_zone" {
  project     = var.project_id
  name        = "${var.unique_name}-nip-io-private-zone"
  dns_name    = "${var.dns_name}."
  description = "Private DNS zone for Apigee internal resolution"
  visibility  = "private"

  private_visibility_config {
    networks {
      network_url = data.google_compute_network.vpc.id
    }
  }
}

resource "google_dns_record_set" "nip_io_a_record" {
  project      = var.project_id
  name         = "${var.unique_name}.${var.dns_name}."
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.nip_io_private_zone.name
  rrdatas      = [google_compute_address.internal_vip.address]
}

/* Apigee */

resource "google_apigee_organization" "apigee_org" {
  project_id                 = var.project_id
  analytics_region           = var.region
  api_consumer_data_location = (var.apigee_type == "EVALUATION" || var.apigee_type == "") ? "" : var.region
  disable_vpc_peering        = true
  runtime_type               = "CLOUD"
  billing_type               = var.apigee_type
  lifecycle {
    precondition {
      condition     = !((var.drz_location != null && var.drz_location != "") && var.apigee_type == "EVALUATION")
      error_message = "Apigee EVALUATION type cannot be used when a DRZ location (drz_location) is specified. Please use PAYG or SUBSCRIPTION instead."
    }
    ignore_changes = [analytics_region]
  }
}

resource "google_apigee_instance" "apigee" {
  name                 = "${var.unique_name}-psc-instance"
  location             = var.region
  org_id               = google_apigee_organization.apigee_org.id
  consumer_accept_list = [var.project_id]
}

resource "google_compute_region_network_endpoint_group" "apigee_psc_neg" {
  project               = var.project_id
  name                  = "${var.unique_name}-psc-neg"
  region                = var.region
  network_endpoint_type = "PRIVATE_SERVICE_CONNECT"
  psc_target_service    = google_apigee_instance.apigee.service_attachment
  network               = data.google_compute_network.vpc.id
  subnetwork            = data.google_compute_subnetwork.subnet.id
}

resource "google_compute_region_backend_service" "apigee_backend" {
  project               = var.project_id
  name                  = "${var.unique_name}-psc-backend"
  region                = var.region
  load_balancing_scheme = "INTERNAL_MANAGED"
  protocol              = "HTTPS"
  timeout_sec           = 600

  backend {
    group = google_compute_region_network_endpoint_group.apigee_psc_neg.id
  }
}

resource "google_compute_region_url_map" "url_map" {
  project         = var.project_id
  name            = "${var.unique_name}-psc-url-map"
  region          = var.region
  default_service = google_compute_region_backend_service.apigee_backend.id
}

resource "google_compute_region_target_https_proxy" "https_proxy" {
  project          = var.project_id
  name             = "${var.unique_name}-psc-https-proxy"
  region           = var.region
  url_map          = google_compute_region_url_map.url_map.id
  ssl_certificates = [google_compute_region_ssl_certificate.internal_cert.id]
}

resource "google_compute_forwarding_rule" "https_forwarding_rule" {
  project               = var.project_id
  name                  = "${var.unique_name}-psc-forwarding-rule"
  region                = var.region
  ip_address            = google_compute_address.internal_vip.address
  target                = google_compute_region_target_https_proxy.https_proxy.id
  port_range            = "443"
  load_balancing_scheme = "INTERNAL_MANAGED"
  network               = data.google_compute_network.vpc.id
  subnetwork            = data.google_compute_subnetwork.subnet.id
  depends_on            = [data.google_compute_subnetwork.proxy_only_subnet]
}

resource "google_apigee_environment" "dev_env" {
  name         = "dev"
  org_id       = google_apigee_organization.apigee_org.id
  display_name = "Development Environment"
  description  = "Development environment for API proxy deployments"
}

resource "google_apigee_envgroup" "dev_envgroup" {
  name      = "dev"
  org_id    = google_apigee_organization.apigee_org.id
  hostnames = ["${var.unique_name}.${var.dns_name}"]
}

resource "google_apigee_envgroup_attachment" "dev_envgroup_attachment" {
  envgroup_id = google_apigee_envgroup.dev_envgroup.id
  environment = google_apigee_environment.dev_env.name
}

resource "google_apigee_instance_attachment" "dev_instance_attachment" {
  instance_id = google_apigee_instance.apigee.id
  environment = google_apigee_environment.dev_env.name
}

output "apigee_endpoint_url" {
  value       = "https://${var.unique_name}.${var.dns_name}"
  description = "Your private secure Apigee API endpoint."
}
