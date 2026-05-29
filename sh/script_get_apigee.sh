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

# get environment variables
echo "Your GOOGLE_CLOUD_PROJECT: $GOOGLE_CLOUD_PROJECT"
export APIGEE_CONFIG=$(aft -c $GOOGLE_CLOUD_PROJECT)
export APIGEE_ENVIRONMENT=$(jq -r '.environmentGroups[0].attachments[0].environment' <<< "$APIGEE_CONFIG")
echo "Your APIGEE_ENVIRONMENT: $APIGEE_ENVIRONMENT"
export APIGEE_HOST=$(jq -r '.environmentGroups[0].hostnames[0]' <<< "$APIGEE_CONFIG")
echo "Your APIGEE_HOST: $APIGEE_HOST"
export PROXY_SA="ai-service@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com"
echo "Your Apigee proxy identity: $PROXY_SA"
export API_KEY=$(curl "https://apigee.googleapis.com/v1/organizations/$GOOGLE_CLOUD_PROJECT/developers/$UNIQUE_NAME-test@example.com/apps/AI%20$UNIQUE_NAME%20App" -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" | jq --raw-output '.credentials[0].consumerKey')
echo "Your API key: $API_KEY"
