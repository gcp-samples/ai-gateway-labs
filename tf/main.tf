/**
 * Copyright 2023 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

locals {
  psc_subnet_region_name = { for subnet in var.psc_ingress_subnets :
    subnet.region => "${subnet.region}/${subnet.name}"
  }
}

module "project" {
  source          = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/project?ref=v15.0.0"
  name            = var.project_id
  parent          = var.project_parent
  billing_account = var.billing_id
  project_create  = var.project_create
  services = [
    "apigee.googleapis.com",
    "cloudkms.googleapis.com",
    "compute.googleapis.com",
    "servicenetworking.googleapis.com"
  ]
  policy_boolean = {
    "constraints/compute.requireOsLogin" = false
    "constraints/compute.requireShieldedVm" = false
  }
  policy_list = {
    "constraints/iam.allowedPolicyMemberDomains" = {
        inherit_from_parent: false
        status: true
        suggested_value: null
        values: [],
        allow: {
          all=true
        }
    },
    "constraints/compute.vmExternalIpAccess" = {
        inherit_from_parent: false
        status: true
        suggested_value: null
        values: [],
        allow: {
          all=true
        }
    }
  }
}

module "vpc" {
  source     = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/net-vpc?ref=v28.0.0"
  project_id = module.project.project_id
  name       = var.network
  psa_config = {
    ranges = {
      apigee-range         = var.peering_range
      apigee-support-range = var.support_range
    }
  }
}

module "nip-development-hostname" {
  source             = "github.com/apigee/terraform-modules/modules/nip-development-hostname"
  project_id         = module.project.project_id
  address_name       = "apigee-external"
  subdomain_prefixes = [for name, _ in var.apigee_envgroups : name]
}

/**
billing_type = PAYG, EVALUATION, SUBSCRIPTION
*/

module "apigee-x-core" {
  source              = "github.com/apigee/terraform-modules/modules/apigee-x-core"
  billing_type        = var.apigee_billing_type
  project_id          = module.project.project_id
  ax_region           = var.region
  apigee_environments = var.apigee_environments
  apigee_envgroups = {
    for name, env_group in var.apigee_envgroups : name => {
      hostnames = concat(env_group.hostnames, ["${name}.${module.nip-development-hostname.hostname}"])
    }
  }
  apigee_instances = var.apigee_instances
  network          = module.vpc.network.id
}

module "psc-ingress-vpc" {
  source                  = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/net-vpc?ref=v28.0.0"
  project_id              = module.project.project_id
  name                    = var.psc_ingress_network
  auto_create_subnetworks = false
  subnets                 = var.psc_ingress_subnets
}

resource "google_compute_region_network_endpoint_group" "psc_neg" {
  project               = var.project_id
  for_each              = var.apigee_instances
  name                  = "psc-neg-${each.value.region}"
  region                = each.value.region
  network               = module.psc-ingress-vpc.network.id
  subnetwork            = module.psc-ingress-vpc.subnet_self_links[local.psc_subnet_region_name[each.value.region]]
  network_endpoint_type = "PRIVATE_SERVICE_CONNECT"
  psc_target_service    = module.apigee-x-core.instance_service_attachments[each.value.region]
  lifecycle {
    create_before_destroy = true
  }
}

module "nb-psc-l7xlb" {
  source          = "github.com/apigee/terraform-modules/modules/nb-psc-l7xlb"
  project_id      = module.project.project_id
  name            = "apigee-xlb-psc"
  ssl_certificate = [module.nip-development-hostname.ssl_certificate]
  external_ip     = module.nip-development-hostname.ip_address
  psc_negs        = [for _, psc_neg in google_compute_region_network_endpoint_group.psc_neg : psc_neg.id]
}

# This was necessary to give the project time to apply the 
# resource "time_sleep" "wait" {
#   depends_on = [module.project]

#   create_duration = "120s"
# }

# resource "google_project_iam_member" "member-role" {
#   for_each = toset([
#     "roles/editor",
#     "roles/apigee.admin"
#   ])
#   role = each.key
#   member = "user:${var.apigee_admin}"
#   project = module.project.project_id
#   depends_on = [ module.apigee-x-core ]
# }