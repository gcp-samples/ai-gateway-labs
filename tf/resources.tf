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


data "google_project" "project" {
  project_id = var.project_id
}

resource "google_service_account" "ai_service" {
  account_id   = "ai-service"
  display_name = "AI Service Account"
  project      = var.project_id
}

resource "google_project_iam_member" "ai_service_roles" {
  for_each = toset([
    "roles/aiplatform.user",
    "roles/apigee.viewer",
    "roles/modelarmor.user",
    "roles/dlp.user",
    "roles/mcp.toolUser",
    "roles/bigquery.user"
  ])
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.ai_service.email}"
}

resource "google_service_account_iam_member" "apigee_sa_token_creator" {
  service_account_id = google_service_account.ai_service.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-apigee.iam.gserviceaccount.com"
}

resource "google_apigee_data_collector" "dc" {
  data_collector_id = "dc_${each.key}"
  for_each          = var.data_collectors
  org_id            = "organizations/${var.project_id}"
  description       = each.value.desc
  type              = each.value.type
}

resource "google_model_armor_template" "model_armor_template" {
  project     = var.project_id
  location    = var.region
  template_id = "${var.unique_name}-ma-template"

  filter_config {
    rai_settings {
      dynamic "rai_filters" {
        for_each = var.rai_filters
        content {
          filter_type      = rai_filters.value.filter_type
          confidence_level = rai_filters.value.confidence_level
        }
      }
    }
    pi_and_jailbreak_filter_settings {
      filter_enforcement = "DISABLED"
      confidence_level   = "HIGH"
    }
    malicious_uri_filter_settings {
      filter_enforcement = "ENABLED"
    }
  }

  template_metadata {
    custom_llm_response_safety_error_code    = 798
    custom_llm_response_safety_error_message = "test template llm response evaluation failed"
    custom_prompt_safety_error_code          = 799
    custom_prompt_safety_error_message       = "test template prompt evaluation failed"
    ignore_partial_invocation_failures       = true
    log_template_operations                  = true
    log_sanitize_operations                  = true
  }
}

resource "google_apphub_service_project_attachment" "attachment" {
  project                       = var.project_id
  service_project_attachment_id = var.project_id
  service_project               = "projects/${var.project_id}"
}

resource "google_apigee_api_product" "products" {
  for_each = var.api_products

  org_id        = "organizations/${var.project_id}"
  name          = "${each.value.name} ${var.unique_name} Product"
  display_name  = "${each.value.name} ${var.unique_name} Product"
  approval_type = "auto"
  environments  = [var.apigee_environment]

  attributes {
    name  = "access"
    value = "public"
  }

  operation_group {
    operation_config_type = "proxy"
    operation_configs {
      api_source = "${each.value.api_source}-${var.unique_name}-${each.value.name}"
      operations {
        resource = "/"
      }
      dynamic "quota" {
        for_each = each.value.quota != null ? [each.value.quota] : []
        content {
          limit     = quota.value.limit
          interval  = quota.value.interval
          time_unit = quota.value.time_unit
        }
      }
    }
  }
}

resource "google_apigee_developer" "test_dev" {
  org_id     = "organizations/${var.project_id}"
  email      = var.developer.email
  first_name = var.developer.first_name
  last_name  = var.developer.last_name
  user_name  = var.developer.user_name
}

resource "google_apigee_developer_app" "bigquery_app" {
  org_id = "organizations/${var.project_id}"
  name            = "BigQuery ${var.unique_name} App"
  api_products    = [google_apigee_api_product.products["bigquery"].name]
  developer_email = google_apigee_developer.test_dev.email
  callback_url    = var.app_callback_url
}

resource "google_apigee_developer_app" "ai_app" {
  org_id = "organizations/${var.project_id}"
  name = "AI ${var.unique_name} App"
  api_products = [
    google_apigee_api_product.products["gemini"].name,
    google_apigee_api_product.products["claude"].name,
    google_apigee_api_product.products["deepseek"].name,
    google_apigee_api_product.products["qwen"].name
  ]
  developer_email = google_apigee_developer.test_dev.email
  callback_url    = var.app_callback_url
}

output "bigquery_api_key" {
  value     = google_apigee_developer_app.bigquery_app.credentials[0].consumer_key
  sensitive = true
}

output "ai_api_key" {
  value     = google_apigee_developer_app.ai_app.credentials[0].consumer_key
  sensitive = true
}
