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

# Required Variables:
# GOOGLE_CLOUD_PROJECT needs to be the Google Cloud project ID of a project that you can use or deploy the lab services in.
export GOOGLE_CLOUD_PROJECT=YOUR_PROJECT_ID
# GOOGLE_CLOUD_LOCATION must be set to a supported Apigee region (https://docs.cloud.google.com/apigee/docs/locations).
export GOOGLE_CLOUD_LOCATION=YOUR_REGION
# APIGEE_TYPE can be EVALUATION, PAYG or SUBSCRIPTION
export APIGEE_TYPE=EVALUATION

# Optional Variables:
# UNIQUE_NAME is used if you are working in a lab with others, this will be added as a suffix to your resources so that nothing is overwritten. By default your username is used, however you can change it if needed.
export UNIQUE_NAME=$USER
# APIGEE_VPC_NAME can be used if you want Apigee to use an existing VPC in the project for the PSC network configuration.
export APIGEE_VPC_NAME=
# APIGEE_SUBNET_NAME can be used for the subnet name in the APIGEE_VPC_NAME VPC.
export APIGEE_SUBNET_NAME=
# APIGEE_DRZ_LOCATION can be used if you want, or must due to org policies, use the Apigee control plane in the regional locations of eu, us, or in.
export APIGEE_DRZ_LOCATION=
