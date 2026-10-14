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

locals {
  gcp_services = [
    "apigee.googleapis.com",
    "apihub.googleapis.com",
    "iamcredentials.googleapis.com",
    "cloudkms.googleapis.com",
    "compute.googleapis.com",
    "servicenetworking.googleapis.com",
    "aiplatform.googleapis.com",
    "cloudaicompanion.googleapis.com",
    "modelarmor.googleapis.com",
    "dlp.googleapis.com",
    "dns.googleapis.com"
  ]
}

provider "google" {
  apigee_custom_endpoint = var.drz_location != "" && var.drz_location != null ? "https://${var.drz_location}-apigee.googleapis.com/v1/" : "https://apigee.googleapis.com/v1/"
}

resource "google_project_service" "enabled_apis" {
  for_each           = toset(local.gcp_services)
  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

resource "google_compute_network" "vpc" {
  project      = var.project_id
  name         = "${var.unique_name}-vpc"
  routing_mode = "REGIONAL"
}

resource "google_compute_subnetwork" "subnet" {
  project       = var.project_id
  name          = "${var.unique_name}-subnet"
  ip_cidr_range = "10.0.0.0/24"
  network       = google_compute_network.vpc.id
  region        = var.region
  purpose       = "PRIVATE"
}

resource "google_compute_subnetwork" "proxy_only_subnet" {
  project       = var.project_id
  name          = "${var.unique_name}-proxy-only-subnet"
  ip_cidr_range = "10.0.1.0/24"
  network       = google_compute_network.vpc.id
  region        = var.region
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
}

data "google_compute_network" "vpc" {
  project      = var.project_id
  name         = var.network_name
}

data "google_compute_subnetwork" "subnet" {
  project       = var.project_id
  name          = var.subnet_name
  region        = var.region
}

data "google_compute_subnetwork" "proxy_only_subnet" {
  project       = var.project_id
  name          = var.proxy_only_subnet_name
  region        = var.region
}