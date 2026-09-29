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

resource "google_apigee_organization" "apigee_org" {
  analytics_region   = "us-central1"
  project_id         = google_project.project.project_id
  authorized_network = google_compute_network.apigee_network.id
  depends_on = [
    google_service_networking_connection.apigee_vpc_connection,
    google_project_service.apigee,
  ]
}

resource "google_apigee_environment" "apigee_environment" {
  org_id       = google_apigee_organization.apigee_org.id
  name         = "apigee-env"
  description  = "Apigee Environment"
  display_name = "environment-1"
}

data "archive_file" "bundle" {
  type             = "zip"
  source_dir       = "${path.module}/bundle"
  output_path      = "${path.module}/bundle.zip"
  output_file_mode = "0644"
}


resource "google_apigee_api" "test_apigee_api" {
  name          = "apigee-proxy"
  org_id        = google_project.project.project_id
  config_bundle = data.archive_file.bundle.output_path
  depends_on    = [google_apigee_organization.apigee_org]
}

resource "google_apigee_api_deployment" "test_apigee_api_deployment" {
  environment = google_apigee_environment.apigee_environment.name
  org_id      = google_apigee_api.test_apigee_api.org_id
  revision    = google_apigee_api.test_apigee_api.latest_revision_id
  proxy_id    = google_apigee_api.test_apigee_api.name
}
