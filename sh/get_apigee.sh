# get environment variables
source .env

echo "Your GOOGLE_CLOUD_PROJECT: $GOOGLE_CLOUD_PROJECT"

# install aft, if not already installed
if ! aft -v 2>/dev/null | grep -q "Apigee Feature Templater"; then
    curl -fsSL https://raw.githubusercontent.com/apigee/apigee-templater/main/install.sh | sh
fi

export APIGEE_CONFIG=$(aft describe --project $GOOGLE_CLOUD_PROJECT -f json)
export APIGEE_ENVIRONMENT=$(jq -r '.environmentGroups[0].attachments[0].environment' <<< "$APIGEE_CONFIG")
echo "Your APIGEE_ENVIRONMENT: $APIGEE_ENVIRONMENT"
export APIGEE_HOST=$(jq -r '.environmentGroups[0].hostnames[0]' <<< "$APIGEE_CONFIG")
echo "Your APIGEE_HOST: $APIGEE_HOST"
export PROXY_SA="ai-service@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com"
echo "Your Apigee proxy identity: $PROXY_SA"
export API_KEY=$(curl "https://apigee.googleapis.com/v1/organizations/$GOOGLE_CLOUD_PROJECT/developers/${UNIQUE_NAME,,}-test@example.com/apps/AI%20$UNIQUE_NAME%20App" -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" | jq --raw-output '.credentials[0].consumerKey')
echo "Your API key: $API_KEY"
