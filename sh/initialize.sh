if [ -f ".env" ]; then
  source .env
fi

if [ -z "$APIGEE_TYPE" ]; then
  APIGEE_TYPE=EVALUATION
fi

if [ -z "$GOOGLE_CLOUD_LOCATION" ]; then
  GOOGLE_CLOUD_LOCATION=europe-west1
fi

if [ -z "$UNIQUE_NAME" ]; then
  UNIQUE_NAME=$USER
fi

read -e -i "$GOOGLE_CLOUD_PROJECT" -p "Enter your Google Cloud Project Id: " project_id
read -e -i "$GOOGLE_CLOUD_LOCATION" -p "Enter your Google Cloud Region: " region
read -e -i "$APIGEE_TYPE" -p "Enter your Apigee deployment type (EVALUATION, PAYG, SUBSCRIPTION): " apigee_type
read -e -i "$UNIQUE_NAME" -p "Enter a unique prefix for your assets: " UNIQUE_NAME

echo "export GOOGLE_CLOUD_PROJECT=$project_id" > .env
echo "export GOOGLE_CLOUD_LOCATION=$region" >> .env
echo "export APIGEE_TYPE=$apigee_type" >> .env
echo >> .env;
echo "# Optional Variables" >> .env;
echo "export UNIQUE_NAME=\$UNIQUE_NAME" >> .env
echo "export APIGEE_VPC_NAME=" >> .env
echo "export APIGEE_SUBNET_NAME=" >> .env
echo "export APIGEE_DRZ_LOCATION=" >> .env

source .env

# create data collectors
curl -X POST "https://apigee.googleapis.com/v1/organizations/$GOOGLE_CLOUD_PROJECT/datacollectors" -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" -H 'Content-Type: application/json; charset=utf-8' \
-d '{"name": "dc_ai_model", "description": "Model name", "type": "STRING"}'
curl -X POST "https://apigee.googleapis.com/v1/organizations/$GOOGLE_CLOUD_PROJECT/datacollectors" -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" -H 'Content-Type: application/json; charset=utf-8' \
-d '{"name": "dc_ai_cost_center", "description": "Model cost center", "type": "STRING"}'
curl -X POST "https://apigee.googleapis.com/v1/organizations/$GOOGLE_CLOUD_PROJECT/datacollectors" -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" -H 'Content-Type: application/json; charset=utf-8' \
-d '{"name": "dc_ai_total_token_count", "description": "Total token count", "type": "INTEGER"}'
curl -X POST "https://apigee.googleapis.com/v1/organizations/$GOOGLE_CLOUD_PROJECT/datacollectors" -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" -H 'Content-Type: application/json; charset=utf-8' \
-d '{"name": "dc_ai_prompt_token_count", "description": "Prompt token count", "type": "INTEGER"}'
curl -X POST "https://apigee.googleapis.com/v1/organizations/$GOOGLE_CLOUD_PROJECT/datacollectors" -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" -H 'Content-Type: application/json; charset=utf-8' \
-d '{"name": "dc_ai_response_token_count", "description": "Response token count", "type": "INTEGER"}'
curl -X POST "https://apigee.googleapis.com/v1/organizations/$GOOGLE_CLOUD_PROJECT/datacollectors" -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" -H 'Content-Type: application/json; charset=utf-8' \
-d '{"name": "dc_ai_response_type", "description": "Model response type", "type": "STRING"}'
curl -X POST "https://apigee.googleapis.com/v1/organizations/$GOOGLE_CLOUD_PROJECT/datacollectors" -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" -H 'Content-Type: application/json; charset=utf-8' \
-d '{"name": "dc_ai_time_first_token", "description": "Time to first token (ms)", "type": "INTEGER"}'

# enable APIs and create AI service account
gcloud services enable aiplatform.googleapis.com --project $GOOGLE_CLOUD_PROJECT
gcloud services enable cloudaicompanion.googleapis.com --project $GOOGLE_CLOUD_PROJECT
gcloud services enable modelarmor.googleapis.com --project $GOOGLE_CLOUD_PROJECT
gcloud services enable dlp.googleapis.com --project $GOOGLE_CLOUD_PROJECT
gcloud iam service-accounts create "ai-service" --project="$GOOGLE_CLOUD_PROJECT" \
    --description="AI Service Account" \
    --display-name="AI Service Account"
sleep 10
# give permissions
gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT \
    --member="serviceAccount:ai-service@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com" \
    --role="roles/aiplatform.user"
gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT \
    --member="serviceAccount:ai-service@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com" \
    --role="roles/apigee.viewer"
gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT \
    --member="serviceAccount:ai-service@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com" \
    --role="roles/modelarmor.user"
gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT \
    --member="serviceAccount:ai-service@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com" \
    --role="roles/dlp.user"
gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT \
    --member="serviceAccount:ai-service@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com" \
    --role="roles/mcp.toolUser"
gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT \
    --member="serviceAccount:ai-service@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com" \
    --role="roles/bigquery.user"
gcloud iam service-accounts add-iam-policy-binding \
  ai-service@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com \
  --member="user:$(gcloud config get-value account 2>/dev/null)" \
  --role="roles/iam.serviceAccountTokenCreator" --project $GOOGLE_CLOUD_PROJECT
# give apigee actAs rights for service account
PROJECT_NUMBER=$(gcloud projects describe $GOOGLE_CLOUD_PROJECT --format="value(projectNumber)")
gcloud iam service-accounts add-iam-policy-binding \
  ai-service@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com \
  --member="serviceAccount:service-$PROJECT_NUMBER@gcp-sa-apigee.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountTokenCreator" --project $GOOGLE_CLOUD_PROJECT
