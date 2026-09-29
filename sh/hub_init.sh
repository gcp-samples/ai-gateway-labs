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

# Attach project to API Hub instance for automatic API proxy syncronization
sleep 5
curl -X POST "https://apihub.googleapis.com/v1/projects/$GOOGLE_CLOUD_PROJECT/locations/$GOOGLE_CLOUD_LOCATION/runtimeProjectAttachments?runtimeProjectAttachmentId=$GOOGLE_CLOUD_PROJECT" \
  -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
  -H "Content-Type: application/json" -H "X-Google-GFE-Can-Retry: yes" \
  --data-binary @- << EOF

{
  "runtimeProject": "projects/$GOOGLE_CLOUD_PROJECT"
}
EOF
