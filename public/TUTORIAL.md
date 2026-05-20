# AI Gateway Foundations Lab
---
This tutorial helps you to provision an AI Gateway into your Google Cloud project, and create some AI proxies to add governance to tools like Gemini CLI and Claude Code.

Let's get started!

---

## Prerequisites

The only prerequisite for this lab is that you have a Google Cloud project to use.

These [Google Cloud roles](https://docs.cloud.google.com/iam/docs/roles-permissions) are needed by your user for the deployments:

* Apigee Organization Admin (roles/apigee.admin)
* API Hub Admin(roles/apihub.admin)
* Service Usage Admin (roles/serviceusage.serviceUsageAdmin)
* Service Account Admin (roles/iam.serviceAccountAdmin)
* Compute Admin (roles/compute.admin)
* Compute Network Admin (roles/compute.networkAdmin)
* Cloud KMS Admin (roles/cloudkms.admin)
* Agent Platform Admin (roles/ml.admin)
* Project IAM Admin (roles/resourcemanager.projectIamAdmin)

---

## Setup

You will need to set these environment variables to run this lab:

* **GOOGLE_CLOUD_PROJECT**: Your Google Cloud project id
* **GOOGLE_CLOUD_LOCATION**: Your Google Cloud region for the Apigee region
* **APIGEE_TYPE**: The type of Apigee deployment (either EVALUATION (valid for 60 days), PAYG (consumption pricing, path to production), or SUBSCRIPTION (fixed pricing)) |

Additionally these **optional** variables can be set if you want to use an existing VPC and subnet, or use a DRZ data residency location:

* **APIGEE_VPC_NAME**: The name of your existing VPC to use for Apigee
* **APIGEE_SUBNET_NAME**: The name of your existing VPC subnet to use for Apigee
* **APIGEE_DRZ_LOCATION**: The optional DRZ data residency location for Apigee data (US, EU or IN)

### Set environment variables
1. Copy the `env.sh` file to a local `.env` file by running this command.

```sh
cp env.sh .env
```

2. Click  <walkthrough-editor-open-file filePath=".env">here</walkthrough-editor-open-file> to open the `.env` file in the editor.

3. After saving your changes, load the variables.

```sh
source .env
```

### Install tooling

This lab uses two open source CLIs to automate Apigee, [apigeecli](https://github.com/apigee/apigeecli) and [aft](https://github.com/apigee/apigee-templater), run these commands to install:

```sh
curl -L https://raw.githubusercontent.com/apigee/apigeecli/main/downloadLatest.sh | sh -
npm i apigee-templater -g
```

---

## Provision Apigee (if needed)

You can provision your Apigee instance in any of the ways documented [here](https://docs.cloud.google.com/apigee/docs/api-platform/get-started/provisioning-options).

**If you already have Apigee provisioned, then you can skip this step.**

For a **simple, automated** deployment, run the [Terraform](https://developer.hashicorp.com/terraform) deployment in this lab, which provisions Apigee, a load balancer, certificate, and other needed services (all from the standard [Google provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)).

Take a look at the <walkthrough-editor-open-file filePath="tf/apigee/main.tf">main.tf</walkthrough-editor-open-file> file to see the resources created.

These **optional parameters** can be added to the `apply` command to customize the deployment.
* **--var "drz_location=$APIGEE_DRZ_LOCATION"**
* **--var "apigee_type=$APIGEE_TYPE"**
* **--var "network=$APIGEE_VPC_NAME"**
* **--var "subnet=$APIGEE_SUBNET_NAME"`**

Run these commands to provision:
```sh
cd tf/apigee
terraform init
terraform apply -var "project_id=$GOOGLE_CLOUD_PROJECT" -var "region=$GOOGLE_CLOUD_LOCATION" --var "apigee_type=$APIGEE_TYPE"
cd ../..
```

Provisioning takes around 20-30 minutes for all services to be enabled & deployed.

---

## Initialize environment

After provisioning is finished, let's initialize the Apigee environment, enable Model Garden and other services, and create a service account to access our AI models.

Take a look at the <walkthrough-editor-open-file filePath="script_initialize.sh">script_initialize.sh</walkthrough-editor-open-file> file to see the commands that are run.

Run this command to initialize the environment:
```sh
source script_initialize.sh
```

---

## Test Gemini API

Now let's make a direct call to the Gemini API on [Model Garden](https://cloud.google.com/model-garden), to verify that it is working.

<img src="https://iili.io/C9TPzEF.png" height=60 />

```sh
curl -i -X POST "https://aiplatform.googleapis.com/v1/projects/$GOOGLE_CLOUD_PROJECT/locations/global/publishers/google/models/gemini-flash-latest:generateContent" -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" -H "Content-Type: application/json" \
-d '{"contents": [{"role": "USER", "parts": [{"text": "why is the sky blue?"}]}]}'
```

You should get a response with an answer candidate with some text about **'Rayleigh scattering'**.

---

## Create Simple Gemini Proxy

Let's create a simple **AI-Gemini** proxy to add governance & analytics to more effectively manage our AI usage. This proxy will intercept all calls to the model, check usage & quotas, and record analytics data.

<img src="https://iili.io/C9TZOgt.png" height=60 />

We will use the **aft** command to create a proxy with the base path **/gemini** and directing traffic to the Google Cloud AI endpoint.

```sh
aft -b /gemini -u https://aiplatform.googleapis.com -o $GOOGLE_CLOUD_PROJECT:AI-Gemini:$APIGEE_ENVIRONMENT
```

Open the proxy in the [Google Cloud Console](https://console.cloud.google.com/apigee/proxies/AI-Gemini/overview), and wait until the deployment is complete (you should see a green ✅ next to the deployment).

After the deployment is complete, click on the **Debug** tab in the proxy screen, and start a debug session.

Let's now call the proxy URL with our same prompt, but this time see the request processing through our proxy in Apigee. Notice the **$APIGEE_HOST** parameter in the URL, which points the request to our Apigee endpoint.

```sh
curl -i -X POST "https://$APIGEE_HOST/gemini/v1/projects/$GOOGLE_CLOUD_PROJECT/locations/global/publishers/google/models/gemini-flash-latest:generateContent" -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" -H "Content-Type: application/json" \
-d '{"contents": [{"role": "USER", "parts": [{"text": "why is the sky blue?"}]}]}'
```

You should get a similar response again about **'Rayleigh scattering'**. 

Go back to the Debug panel, and see the processing steps, timings and variables that were done between the request and response.

✅ Now we have a proxy in place to add governance & analytics to the AI prompt requests.

---

## Add Model Authorization, Governance & Analytics

Now we will update the proxy for **Gemini**, and also add more proxies for further models. These proxies are based on YAML proxy templates (open <walkthrough-editor-open-file filePath="AI-Proxy-Gemini.yaml">AI-Proxy-Gemini.yaml</walkthrough-editor-open-file> for an example), and see the [aft documentation](https://github.com/apigee/apigee-templater) for more information.

```sh
aft AI-Proxy-Gemini.yaml -o $GOOGLE_CLOUD_PROJECT:AI-Gemini:$APIGEE_ENVIRONMENT:ai-service@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com
aft AI-Proxy-DeepSeek.yaml -o $GOOGLE_CLOUD_PROJECT:AI-DeepSeek:$APIGEE_ENVIRONMENT:ai-service@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com
aft AI-Proxy-Qwen.yaml -o $GOOGLE_CLOUD_PROJECT:AI-Qwen:$APIGEE_ENVIRONMENT:ai-service@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com
aft AI-Proxy-Claude.yaml -o $GOOGLE_CLOUD_PROJECT:AI-Claude:$APIGEE_ENVIRONMENT:ai-service@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com
aft -i AI-Analytics.yaml -o $GOOGLE_CLOUD_PROJECT:AI-Analytics:$APIGEE_ENVIRONMENT
```

Now let's create a **product** & **subscription** to the **AI-Gemini** proxy. [Products](https://docs.cloud.google.com/apigee/docs/api-platform/publish/what-api-product) and [Subscriptions](https://docs.cloud.google.com/apigee/docs/api-platform/publish/creating-apps-surface-your-api) allow user authorization and detailed quotas on things like number of tokens, calls or specific models, paths or operations.

Take a look at the <walkthrough-editor-open-file filePath="script_register_key.sh">script_register_key.sh</walkthrough-editor-open-file> file to see the commands that are run.

```sh
source script_register_key.sh
```

---

## Test Model Proxy Authorization & Failover

### Call Gemini Model
Now let's call our model proxy with an API key as credential, that has subscribed to the **AI-Gemini** product with certain LLM token quotas.

```sh
curl -i -X POST "https://$APIGEE_HOST/gemini/v1beta1/projects/$GOOGLE_CLOUD_PROJECT/locations/global/endpoints/openapi/chat/completions" -H "x-api-key: $API_KEY" -H "Content-Type: application/json; charset=utf-8" \
-d '{"model": "google/gemini-flash-latest", "stream": true, "messages":  [{"role": "user", "content": "Why is the sky blue?"}]}'
```

### Not Allowed Model
In our Gemini proxy deployment, we set a model allowed flag to **gemini**, meaning we will reject any model names that don't contain that word. Let's try to kall **kimi-k2-thinking-maas** on our **/gemini** endpoint.

```sh
curl -i -X POST "https://$APIGEE_HOST/gemini/v1beta1/projects/$GOOGLE_CLOUD_PROJECT/locations/global/endpoints/openapi/chat/completions" -H "x-api-key: $API_KEY" -H "Content-Type: application/json; charset=utf-8" \
-d '{"model": "moonshotai/kimi-k2-thinking-maas", "stream": true, "messages":  [{"role": "user", "content": "What does the Orion constellation look like?"}]}'
```

You should get a **Model not allowed** response.

### Model Failover
Now let's do a call to a non-existent model to force a model failver to the configured failover model in the proxy, **gemini-flash-latest**.

```sh
curl -i -X POST "https://$APIGEE_HOST/gemini/v1beta1/projects/$GOOGLE_CLOUD_PROJECT/locations/global/endpoints/openapi/chat/completions" -H "x-api-key: $API_KEY" -H "Content-Type: application/json; charset=utf-8" \
-d '{"model": "google/gemini-5.1-pro", "stream": true, "messages":  [{"role": "user", "content": "What does the Orion constellation look like?"}]}'
```

You should get a response from **google/gemini-flash-latest** since the requested model failed.

### Call some more models

Let's call some more models.

```sh
curl -i -X POST "https://$APIGEE_HOST/deepseek/v1beta1/projects/$GOOGLE_CLOUD_PROJECT/locations/global/endpoints/openapi/chat/completions" -H "x-api-key: $API_KEY" -H "Content-Type: application/json; charset=utf-8" \
-d '{"model": "deepseek-ai/deepseek-v3.2-maas", "stream": true, "messages":  [{"role": "user", "content": "What does the Orion constellation look like?"}]}'

curl -i -X POST "https://$APIGEE_HOST/qwen/v1beta1/projects/$GOOGLE_CLOUD_PROJECT/locations/global/endpoints/openapi/chat/completions" -H "x-api-key: $API_KEY" -H "Content-Type: application/json; charset=utf-8" \
-d '{"model": "qwen/qwen3-next-80b-a3b-thinking-maas", "stream": false, "messages":  [{"role": "user", "content": "What is a constellation in astronomy?"}]}'
```

Enable Anthropic models to call them through the **Claude** proxy.
* [Claude Haiku 4.5](https://console.cloud.google.com/agent-platform/publishers/anthropic/model-garden/claude-haiku-4-5)
* [Claude Sonnet 4.6](https://console.cloud.google.com/agent-platform/publishers/anthropic/model-garden/claude-sonnet-4-6)
* [Claude Opus 4.6](https://console.cloud.google.com/agent-platform/publishers/anthropic/model-garden/claude-opus-4-6)
* [Claude Opus 4.7](https://console.cloud.google.com/agent-platform/publishers/anthropic/model-garden/claude-opus-4-7)

Call Claude Sonnet 4.6 through the **Claude** proxy.

```sh
curl -i -X POST "https://$APIGEE_HOST/claude/v1/projects/$PROJECT_ID/locations/global/publishers/anthropic/models/claude-sonnet-4-6:streamRawPredict" -H "x-api-key: $API_KEY" -H "Content-Type: application/json; charset=utf-8" \
-d '{"stream": true, "anthropic_version": "vertex-2023-10-16", "max_tokens": 100, "messages": [{"role": "user", "content": "What does the constellation Cassiopeia look like?"}]}'
```

## Test Gemini CLI and Claude Code with Apigee Proxies

Show your **Apigee Host** and **API Key** to use in the CLI configurations.

```sh
echo $GOOGLE_CLOUD_PROJECT
echo $APIGEE_HOST
echo $API_KEY
```

Open your `~/.bashrc` and set these environment variables.

```sh
# Gemini
export GOOGLE_VERTEX_BASE_URL=https://YOUR_APIGEE_HOST/gemini
export GOOGLE_CLOUD_PROJECT=YOUR_GOOGLE_CLOUD_PROJECT
export GOOGLE_CLOUD_LOCATION=global
export GEMINI_CLI_CUSTOM_HEADERS="x-api-key: YOUR_API_KEY"

# Anthropic
export CLAUDE_CODE_USE_VERTEX=1
export CLOUD_ML_REGION=global
export ANTHROPIC_VERTEX_PROJECT_ID=YOUR_GOOGLE_CLOUD_PROJECT
export ANTHROPIC_DEFAULT_OPUS_MODEL='claude-opus-4-7'
export ANTHROPIC_DEFAULT_SONNET_MODEL='claude-sonnet-4-6'
export ANTHROPIC_VERTEX_BASE_URL=https://YOUR_APIGEE_HOST/claude/v1
export ANTHROPIC_CUSTOM_HEADERS="x-api-key: YOUR_API_KEY"
```

How use Gemini CLI and Claude Code (if installed) as you normally would, except now all of the model traffic is going through our Apigee proxies.

```sh
gemini -p "What does the constellation Leo look like? "
gemini -p "What does the constellation Scorpio look like? "
```

## View Analytics Data

Start a local analytics dashboard to see the usage data.

```sh
go run .
```

Take a look at the <walkthrough-editor-open-file filePath="main.go">main.go</walkthrough-editor-open-file> file to see the server code.

Click on the **[Web Preview 🖵](https://docs.cloud.google.com/shell/docs/using-web-preview)** button at the top of the **Cloud Shell** page to open the dashboard and see your analytics data. 

Click on the **Demo Mode** slider at the top to see what the dashboard looks like with more data from a longer timeframe.

---

## Conclusion
<walkthrough-conclusion-trophy></walkthrough-conclusion-trophy>

Congratulations! You've successfully completed the **AI Gateway Foundations Lab** on Google Cloud. Keep an eye out for more AI Gateway Labs, and let us know what you think!
<walkthrough-inline-feedback></walkthrough-inline-feedback>
