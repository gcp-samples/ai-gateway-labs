# get environment variables
export APIGEE_CONFIG=$(aft -c $GOOGLE_CLOUD_PROJECT)
export APIGEE_ENVIRONMENT=$(jq -r '.environmentGroups[0].attachments[0].environment' <<< "$APIGEE_CONFIG")
export APIGEE_HOST=$(jq -r '.environmentGroups[0].hostnames[0]' <<< "$APIGEE_CONFIG")
export PROXY_ID="ai-service@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com"
export API_KEY=$(curl "https://apigee.googleapis.com/v1/organizations/$GOOGLE_CLOUD_PROJECT/developers/test@example.com/apps/AI%20App" -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" | jq --raw-output '.credentials[0].consumerKey')
