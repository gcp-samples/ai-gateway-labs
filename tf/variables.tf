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

variable "project_id" {
  description = "Project id (also used for the Apigee Organization)."
  type        = string
}

variable "region" {
  description = "GCP region for the Apigee runtime & analytics data."
  type        = string
}

variable "network_name" {
  description = "Name of the VPC network to use for Apigee."
  type        = string
}

variable "subnet_name" {
  description = "Name of the subnet to use for Apigee."
  type        = string
}

variable "proxy_only_subnet_name" {
  description = "Name of the proxy-only subnet to use for Apigee."
  type        = string
}

variable "dns_name" {
  description = "The DNS name to use for the private DNS zone."
  type        = string
}

variable "drz_location" {
  description = "The DRZ location to use for deploying Apigee, either US (United States), EU (Europeean Union) or IN (India), or empty for global."
  type        = string
  default     = null
}

variable "apigee_type" {
  description = "The Apigee billing type, either EVALUATION, PAYG or SUBSCRIPTION."
  type        = string
  default     = "EVALUATION"
}

variable "unique_name" {
  description = "Unique name suffix for resources"
  type        = string
}

variable "apigee_environment" {
  description = "Apigee environment name"
  type        = string
  default     = "dev"
}

variable "developer" {
  type = object({
    email      = string
    first_name = string
    last_name  = string
    user_name  = string
  })
}

variable "rai_filters" {
  description = "List of RAI filters for Model Armor"
  type = list(object({
    filter_type      = string
    confidence_level = string
  }))
  default = [
    {
      filter_type      = "HATE_SPEECH"
      confidence_level = "MEDIUM_AND_ABOVE"
    },
    {
      filter_type      = "HARASSMENT"
      confidence_level = "MEDIUM_AND_ABOVE"
    },
    {
      filter_type      = "SEXUALLY_EXPLICIT"
      confidence_level = "MEDIUM_AND_ABOVE"
    },
    {
      filter_type      = "DANGEROUS"
      confidence_level = "MEDIUM_AND_ABOVE"
    }
  ]
}

variable "data_collectors" {
  description = "Map of Apigee Data Collectors"
  type = map(object({
    desc = string
    type = string
  }))
  default = {
    "dc_ai_model"                = { desc = "Model name", type = "STRING" }
    "dc_ai_cost_center"          = { desc = "Model cost center", type = "STRING" }
    "dc_ai_total_token_count"    = { desc = "Total token count", type = "INTEGER" }
    "dc_ai_prompt_token_count"   = { desc = "Prompt token count", type = "INTEGER" }
    "dc_ai_response_token_count" = { desc = "Response token count", type = "INTEGER" }
    "dc_ai_response_type"        = { desc = "Model response type", type = "STRING" }
    "dc_ai_time_first_token"     = { desc = "Time to first token (ms)", type = "INTEGER" }
  }
}

variable "api_products" {
  description = "Map of Apigee API Products"
  type = map(object({
    name       = string
    api_source = string
    quota = optional(object({
      limit     = string
      interval  = string
      time_unit = string
    }))
  }))
  default = {
    "bigquery" = {
      name       = "BigQuery"
      api_source = "MCP"
      quota = {
        limit     = "5"
        interval  = "1"
        time_unit = "minute"
      }
    }
    "gemini" = {
      name       = "Gemini"
      api_source = "AI"
    }
    "claude" = {
      name       = "Claude"
      api_source = "AI"
    }
    "deepseek" = {
      name       = "DeepSeek"
      api_source = "AI"
    }
    "qwen" = {
      name       = "Qwen"
      api_source = "AI"
    }
  }
}

variable "app_callback_url" {
  description = "The callback URL for Apigee Developer Apps"
  type        = string
  default     = "https://example.com/callback"
}