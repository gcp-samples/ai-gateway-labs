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

# create products
curl -X POST "https://apigee.googleapis.com/v1/organizations/$GOOGLE_CLOUD_PROJECT/apiproducts" -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" -H 'Content-Type: application/json; charset=utf-8' \
--data-binary @- << EOF

{"name": "Gemini $UNIQUE_NAME Product", "displayName": "Gemini $UNIQUE_NAME Product", "approvalType": "auto", "attributes": [{"name": "access", "value": "public" } ], "environments": ["dev"], "createdAt": "1778486511834", "lastModifiedAt": "1778486511834", "operationGroup": {"operationConfigs": [{"apiSource": "AI-Analytics", "operations": [{"resource": "/" } ], "quota": {} } ], "operationConfigType": "proxy" }, "llmOperationGroup": {"operationConfigs": [{"apiSource": "AI-$UNIQUE_NAME-Gemini", "llmOperations": [{"resource": "/", "model": "gemini-flash-latest" } ], "llmTokenQuota": {"limit": "10000", "interval": "1", "timeUnit": "minute" } } ] } }
EOF

curl -X POST "https://apigee.googleapis.com/v1/organizations/$GOOGLE_CLOUD_PROJECT/apiproducts" -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" -H 'Content-Type: application/json; charset=utf-8' \
--data-binary @- << EOF

{"name": "Claude $UNIQUE_NAME Product", "displayName": "Claude $UNIQUE_NAME Product", "approvalType": "auto", "attributes": [{"name": "access", "value": "public" } ], "environments": ["dev"], "createdAt": "1778486511834", "lastModifiedAt": "1778486511834", "operationGroup": {"operationConfigs": [{"apiSource": "AI-Analytics", "operations": [{"resource": "/" } ], "quota": {} } ], "operationConfigType": "proxy" }, "llmOperationGroup": {"operationConfigs": [{"apiSource": "AI-$UNIQUE_NAME-Claude", "llmOperations": [{"resource": "/", "model": "claude-opus-4-7" } ], "llmTokenQuota": {"limit": "10000", "interval": "5", "timeUnit": "minute" } } ] } }
EOF

curl -X POST "https://apigee.googleapis.com/v1/organizations/$GOOGLE_CLOUD_PROJECT/apiproducts" -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" -H 'Content-Type: application/json; charset=utf-8' \
--data-binary @- << EOF

{"name": "DeepSeek $UNIQUE_NAME Product", "displayName": "DeepSeek $UNIQUE_NAME Product", "approvalType": "auto", "attributes": [{"name": "access", "value": "public" } ], "environments": ["dev"], "createdAt": "1778486511834", "lastModifiedAt": "1778486511834", "operationGroup": {"operationConfigs": [{"apiSource": "AI-Analytics", "operations": [{"resource": "/" } ], "quota": {} } ], "operationConfigType": "proxy" }, "llmOperationGroup": {"operationConfigs": [{"apiSource": "AI-$UNIQUE_NAME-DeepSeek", "llmOperations": [{"resource": "/", "model": "deepseek-v3.2-maas" } ] } ] } }
EOF

curl -X POST "https://apigee.googleapis.com/v1/organizations/$GOOGLE_CLOUD_PROJECT/apiproducts" -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" -H 'Content-Type: application/json; charset=utf-8' \
--data-binary @- << EOF

{"name": "Qwen $UNIQUE_NAME Product", "displayName": "Qwen $UNIQUE_NAME Product", "approvalType": "auto", "attributes": [{"name": "access", "value": "public" } ], "environments": ["dev"], "createdAt": "1778486511834", "lastModifiedAt": "1778486511834", "operationGroup": {"operationConfigs": [{"apiSource": "AI-Analytics", "operations": [{"resource": "/" } ], "quota": {} } ], "operationConfigType": "proxy" }, "llmOperationGroup": {"operationConfigs": [{"apiSource": "AI-$UNIQUE_NAME-Qwen", "llmOperations": [{"resource": "/", "model": "qwen3-next-80b-a3b-thinking-maas" } ] } ] } }
EOF

# create test developer
curl -X POST "https://apigee.googleapis.com/v1/organizations/$GOOGLE_CLOUD_PROJECT/developers" -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" -H 'Content-Type: application/json; charset=utf-8' \
--data-binary @- << EOF

{"email": "${UNIQUE_NAME,,}-test@example.com", "firstName": "$UNIQUE_NAME", "lastName": "User", "userName": "${UNIQUE_NAME,,}-test@example.com"}
EOF

# create app and get key
export API_KEY=$(curl -X POST "https://apigee.googleapis.com/v1/organizations/$GOOGLE_CLOUD_PROJECT/developers/${UNIQUE_NAME,,}-test@example.com/apps" -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" -H 'Content-Type: application/json; charset=utf-8' \
--data-binary @- << EOF | jq --raw-output '.credentials[0].consumerKey'

{"developerId": "${UNIQUE_NAME,,}-test@example.com", "name": "AI $UNIQUE_NAME App", "apiProducts": ["Gemini $UNIQUE_NAME Product","DeepSeek $UNIQUE_NAME Product","Qwen $UNIQUE_NAME Product","Claude $UNIQUE_NAME Product"]}
EOF
)

echo "Your API key to access the Gemini Product is: $API_KEY"
