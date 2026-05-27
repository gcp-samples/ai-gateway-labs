# AI Gateway Foundations Lab

<img src="https://iili.io/C9Al3Ol.jpg" />

---
This tutorial guides you through provisioning an **AI Gateway** in your Google Cloud project, and then creating AI proxies to add **governance & analytics** at the gateway level to agentic tools like **Gemini CLI**, **Claude Code**, or any other AI application.

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

<img src="https://iili.io/C9AvqyN.png" />

You will need to set these environment variables to run this lab:

* **GOOGLE_CLOUD_PROJECT**: Your Google Cloud project id
* **GOOGLE_CLOUD_LOCATION**: Your Google Cloud region for the Apigee region
* **APIGEE_TYPE**: The type of Apigee deployment (either EVALUATION (valid for 60 days), PAYG (consumption pricing, path to production), or SUBSCRIPTION (fixed pricing)) |

Additionally these **optional** variables can be set if you want to use an existing VPC and subnet, or use a DRZ data residency location:

* **APIGEE_VPC_NAME**: The name of your existing VPC to use for Apigee
* **APIGEE_SUBNET_NAME**: The name of your existing VPC subnet to use for Apigee
* **APIGEE_DRZ_LOCATION**: The optional DRZ data residency location for Apigee data (US, EU or IN)

### Set Environment Variables

1. **Copy** the `./sh/env.sh` file to a local `.env` file by running this command.

```sh
cp --update=none ./sh/env.sh .env
```

2. **Click**  <walkthrough-editor-open-file filePath=".env">here</walkthrough-editor-open-file> to open the `.env` file in the editor.

3. After **saving** your changes, load the variables by running this command:

```sh
source .env
```

### Install Tooling

<img src="https://iili.io/C9AvqyN.png" />

This lab uses the [aft](https://github.com/apigee/apigee-templater) tool to automate proxy deployment, install with this command:

```sh
npm i apigee-templater -g
```

---

## Provision Apigee (if not already provisioned)

<img src="https://iili.io/C9A7ZD7.png" />

You can provision your Apigee instance in any of the ways documented [here](https://docs.cloud.google.com/apigee/docs/api-platform/get-started/provisioning-options).

**If you already have Apigee provisioned, then you can skip this step.**

For a **simple, automated** deployment, run the [Terraform](https://developer.hashicorp.com/terraform) deployment in this lab, which provisions Apigee, a load balancer, certificate, and other needed services (all from the standard [Google provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)).

Take a look at the <walkthrough-editor-open-file filePath="tf/apigee/main.tf">main.tf</walkthrough-editor-open-file> file to see the resources created.

These **optional parameters** can be added to the `apply` command to customize the deployment.
* **--var "drz_location=$APIGEE_DRZ_LOCATION"**
* **--var "apigee_type=$APIGEE_TYPE"**
* **--var "network=$APIGEE_VPC_NAME"**
* **--var "subnet=$APIGEE_SUBNET_NAME"`**

Run these commands to provision, and type **yes** after reviewing the changes:
```sh
cd tf/apigee
terraform init
terraform apply -var "project_id=$GOOGLE_CLOUD_PROJECT" -var "region=$GOOGLE_CLOUD_LOCATION" --var "apigee_type=$APIGEE_TYPE"
cd ../..
```

Provisioning takes around 20-30 minutes for all services to be enabled & deployed.

---

## Initialize Environment

<img src="https://iili.io/C9AvqyN.png" />

After provisioning is finished, let's initialize the Apigee environment, enable Model Garden and other services, and create a service account to access our AI models.

Take a look at the <walkthrough-editor-open-file filePath="./sh/script_initialize.sh">script_initialize.sh</walkthrough-editor-open-file> file to see the commands that are run.

Run this command to initialize the environment:
```sh
source ./sh/script_initialize.sh
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

We will use the **aft** command to create a proxy with the base path **/gemini** (plus your unique name), and proxying traffic to the Google Cloud AI endpoint.

```sh
aft -b "/${UNIQUE_NAME,,}-gemini" -u https://aiplatform.googleapis.com -o "$GOOGLE_CLOUD_PROJECT:AI-$UNIQUE_NAME-Gemini:$APIGEE_ENVIRONMENT"
```

Open the proxy in the [Google Cloud Console](https://console.cloud.google.com/apigee/proxies), click on your **proxy**, and wait until the deployment is complete (you should see a green ✅ next to the deployment).

[![Gemini proxy deploy](https://amalbagee.web.app/apigee/ai-gemini-deploy1.png)](https://amalbagee.web.app/apigee/ai-gemini-deploy1.png)

After the deployment is complete, click on the **Debug** tab in the proxy screen, and start a debug session.

[![Gemini proxy debug](https://amalbagee.web.app/apigee/ai-gemini-debug1.png)](https://amalbagee.web.app/apigee/ai-gemini-debug1.png)

Let's now call the proxy URL with our same prompt, but this time see the request processing through our proxy in Apigee. Notice the **$APIGEE_HOST** parameter in the URL, which points the request to our Apigee endpoint.

```sh
curl -i -X POST "https://$APIGEE_HOST/${UNIQUE_NAME,,}-gemini/v1/projects/$GOOGLE_CLOUD_PROJECT/locations/global/publishers/google/models/gemini-flash-latest:generateContent" -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" -H "Content-Type: application/json" \
-d '{"contents": [{"role": "USER", "parts": [{"text": "why is the sky blue?"}]}]}'
```

You should get a similar response again about **'Rayleigh scattering'**. In case you get an **OpenSSL SSL_connect** error it means that the load balancer certificate is still provisioning, so just wait a few minutes and try again until it works (can take 5-10 minutes).

Go back to the Debug panel, and see the processing steps, timings and variables that were done between the request and response.

[![Gemini proxy debug result](https://amalbagee.web.app/apigee/ai-gemini-debug2.png)](https://amalbagee.web.app/apigee/ai-gemini-debug2.png)

✅ Now we have a proxy in place to add governance & analytics to the AI prompt requests.

## Add Model Authorization, Governance & Analytics

Now we will update the proxy with authorization, governance & analytics policies, as well as add proxies to more models.

![AI proxies governance](https://amalbagee.web.app/apigee/ai-proxies-gov1.png)

The proxy definitions are YAML templates (see <walkthrough-editor-open-file filePath="AI-Proxy-Gemini.yaml">AI-Proxy-Gemini.yaml</walkthrough-editor-open-file> for an example), and see the [aft documentation](https://github.com/apigee/apigee-templater) for more information.

Deploy the AI proxy templates:

```sh
aft AI-Proxy-Gemini.yaml -o "$GOOGLE_CLOUD_PROJECT:AI-$UNIQUE_NAME-Gemini:$APIGEE_ENVIRONMENT:$PROXY_SA" -p "ModelBasePath=/${UNIQUE_NAME,,}-gemini"
aft AI-Proxy-DeepSeek.yaml -o "$GOOGLE_CLOUD_PROJECT:AI-$UNIQUE_NAME-DeepSeek:$APIGEE_ENVIRONMENT:$PROXY_SA" -p "ModelBasePath=/${UNIQUE_NAME,,}-deepseek"
aft AI-Proxy-Qwen.yaml -o "$GOOGLE_CLOUD_PROJECT:AI-$UNIQUE_NAME-Qwen:$APIGEE_ENVIRONMENT:$PROXY_SA" -p "ModelBasePath=/${UNIQUE_NAME,,}-qwen"
aft AI-Proxy-Claude.yaml -o "$GOOGLE_CLOUD_PROJECT:AI-$UNIQUE_NAME-Claude:$APIGEE_ENVIRONMENT:$PROXY_SA" -p "ModelBasePath=/${UNIQUE_NAME,,}-claude"
aft -i AI-Analytics.yaml -o $GOOGLE_CLOUD_PROJECT:AI-Analytics:$APIGEE_ENVIRONMENT
```

Now let's create a **product** & **subscription** to the **AI-Gemini** proxy. [Products](https://docs.cloud.google.com/apigee/docs/api-platform/publish/what-api-product) and [Subscriptions](https://docs.cloud.google.com/apigee/docs/api-platform/publish/creating-apps-surface-your-api) allow user authorization and detailed quotas on things like number of tokens, calls or specific models, paths or operations.

Take a look at the <walkthrough-editor-open-file filePath="./sh/script_register_key.sh">script_register_key.sh</walkthrough-editor-open-file> file, and then run the commands:

```sh
source ./sh/script_register_key.sh
```

---

## Test Model Proxy Authorization & Failover

### Call Gemini Model

<img src="https://iili.io/C9ATbmF.png" />

Now let's call our model proxy with an API key as credential, that has subscribed to the **AI-Gemini** product with certain LLM token quotas. You can start a debug session again in the Apigee console if you wish to see the processing steps.

```sh
curl -i -X POST "https://$APIGEE_HOST/${UNIQUE_NAME,,}-gemini/v1beta1/projects/$GOOGLE_CLOUD_PROJECT/locations/global/endpoints/openapi/chat/completions" -H "x-api-key: $API_KEY" -H "Content-Type: application/json; charset=utf-8" \
-d '{"model": "google/gemini-flash-latest", "stream": true, "messages":  [{"role": "user", "content": "Why is the sky blue?"}]}'
```

### Not Allowed Model

<img src="https://iili.io/C9ujkXf.png" />
  
In our Gemini proxy deployment, we set a model allowed flag to **gemini**, so let's try calling another model on our endpoint, and see if it's rejected:

```sh
curl -i -X POST "https://$APIGEE_HOST/${UNIQUE_NAME,,}-gemini/v1beta1/projects/$GOOGLE_CLOUD_PROJECT/locations/global/endpoints/openapi/chat/completions" -H "x-api-key: $API_KEY" -H "Content-Type: application/json; charset=utf-8" \
-d '{"model": "hackernews/cool-0.1-model", "stream": true, "messages":  [{"role": "user", "content": "What does the Orion constellation look like?"}]}'
```

You should get a **Model not allowed** response.

### Model Failover

<img src="https://iili.io/C9ujvs4.png" />

Now let's do a call to a non-existent Gemini model, and force a model failver to the configured failover model in the proxy, **gemini-flash-latest**.

```sh
curl -i -X POST "https://$APIGEE_HOST/${UNIQUE_NAME,,}-gemini/v1beta1/projects/$GOOGLE_CLOUD_PROJECT/locations/global/endpoints/openapi/chat/completions" -H "x-api-key: $API_KEY" -H "Content-Type: application/json; charset=utf-8" \
-d '{"model": "google/gemini-5.1-pro", "stream": false, "messages":  [{"role": "user", "content": "What does the Orion constellation look like?"}]}'
```

You should get a response from **google/gemini-flash-latest** since the requested model failed.

### Call More Models

<img src="https://iili.io/C9ujNbs.png" />

Let's call some more models.

```sh
curl -i -X POST "https://$APIGEE_HOST/${UNIQUE_NAME,,}-deepseek/v1beta1/projects/$GOOGLE_CLOUD_PROJECT/locations/global/endpoints/openapi/chat/completions" -H "x-api-key: $API_KEY" -H "Content-Type: application/json; charset=utf-8" \
-d '{"model": "deepseek-ai/deepseek-v3.2-maas", "stream": true, "messages":  [{"role": "user", "content": "What does the Orion constellation look like?"}]}'

curl -i -X POST "https://$APIGEE_HOST/${UNIQUE_NAME,,}-qwen/v1beta1/projects/$GOOGLE_CLOUD_PROJECT/locations/global/endpoints/openapi/chat/completions" -H "x-api-key: $API_KEY" -H "Content-Type: application/json; charset=utf-8" \
-d '{"model": "qwen/qwen3-next-80b-a3b-thinking-maas", "stream": false, "messages":  [{"role": "user", "content": "What is a constellation in astronomy?"}]}'
```

### Optional 
Enable Anthropic models to call them through the **Claude** proxy.
* [Claude Haiku 4.5](https://console.cloud.google.com/agent-platform/publishers/anthropic/model-garden/claude-haiku-4-5)
* [Claude Sonnet 4.6](https://console.cloud.google.com/agent-platform/publishers/anthropic/model-garden/claude-sonnet-4-6)
* [Claude Opus 4.6](https://console.cloud.google.com/agent-platform/publishers/anthropic/model-garden/claude-opus-4-6)
* [Claude Opus 4.7](https://console.cloud.google.com/agent-platform/publishers/anthropic/model-garden/claude-opus-4-7)

Call Claude Sonnet 4.6 through the **Claude** proxy.

```sh
curl -i -X POST "https://$APIGEE_HOST/${UNIQUE_NAME,,}-claude/v1/projects/$PROJECT_ID/locations/global/publishers/anthropic/models/claude-sonnet-4-6:streamRawPredict" -H "x-api-key: $API_KEY" -H "Content-Type: application/json; charset=utf-8" \
-d '{"stream": true, "anthropic_version": "vertex-2023-10-16", "max_tokens": 100, "messages": [{"role": "user", "content": "What does the constellation Cassiopeia look like?"}]}'
```

---

## Test Gemini CLI and Claude Code with Apigee Proxies

![AI proxies governance](https://amalbagee.web.app/apigee/ai-proxies-gov1.png)

Now let's update our terminal session with our new **Gemini Proxy** information by setting these variables:

```sh
export GOOGLE_VERTEX_BASE_URL="https://$APIGEE_HOST/${UNIQUE_NAME,,}-gemini"
export GEMINI_CLI_CUSTOM_HEADERS="x-api-key: $API_KEY"
```

Start a **debug session** in the Apigee console again, and use **Gemini CLI** to answer some questions. Feel free to ask additional prompts, or start the full tool.

![Gemini CLI](https://amalbagee.web.app/gemini/gemini-cli1.png)

```sh
gemini -p "What does the constellation Leo look like? "
```

```sh
gemini -p "What does the constellation Scorpio look like? "
```

You should see debug traces of the conversations in Apigee, with each step of the policy & logic checks, as well as each frame of the SSE streaming responses to the CLI client.

[![Gemini CLI debug](https://amalbagee.web.app/apigee/ai-gemini-debug3.png)](https://amalbagee.web.app/apigee/ai-gemini-debug3.png)

🎉 You now have a full **AI Gateway** running in front of your **Gemini** (and many other) models!

### Optional

Try configuring and using **[Claude Code](https://claude.com/product/claude-code)** with our Claude proxy by setting these variables:

```sh
export CLAUDE_CODE_USE_VERTEX=1
export CLOUD_ML_REGION=global
export ANTHROPIC_VERTEX_PROJECT_ID=$GOOGLE_CLOUD_PROJECT
export ANTHROPIC_VERTEX_BASE_URL="https://$APIGEE_HOST/${UNIQUE_NAME,,}-claude/v1"
export ANTHROPIC_CUSTOM_HEADERS="x-api-key: $API_KEY"
```

Now call **claude** with prompts and watch the debug traces for the governance policy execution.

```sh
claude -p "What are the most common constellations that are visible in the night sky in different parts of the world?"
```

## View Analytics Data

<img src="https://iili.io/C9AFb2a.png" />

Now that we have some AI traffic flowing, let's start a local analytics dashboard (hosted in Go) to view the token & usage metrics. 

```sh
go run .
```

Take a look at the <walkthrough-editor-open-file filePath="main.go">main.go</walkthrough-editor-open-file> file to see the server code.

Click on the **[Web Preview 🖵](https://docs.cloud.google.com/shell/docs/using-web-preview)** button at the top of the **Cloud Shell** page, and then on **Preview on port 8080** link,  to open the dashboard and see your analytics data. 

[![AI Gateway Analytics](https://amalbagee.web.app/apigee/ai-analytics1.png)](https://amalbagee.web.app/apigee/ai-analytics1.png)

Click on the **Demo Mode** slider at the top to see what the dashboard looks like with more **demo data** from a longer timeframe.

🎉 You now have a full **AI Gateway** analytics dashboard running in your lab environment! Make some more calls and watch as the data & usage grow 📈.

### Optional

[![Google Data Studio](https://amalbagee.web.app/general/data-studio.png)](https://datastudio.google.com)

You can also use [Google Data Studio](https://datastudio.google.com), as well as many other BI tools, to design Apigee AI dashboards. Take a look at this [template](https://datastudio.google.com/s/nqey8Stz8rs), and as a bonus try copying it and creating your own using the [Apigee Data Source](https://docs.cloud.google.com/apigee/docs/api-platform/analytics/data-studio).

---

## Conclusion
<walkthrough-conclusion-trophy></walkthrough-conclusion-trophy>

🏆 Congratulations! You've successfully completed the **AI Gateway Foundations Lab** on Google Cloud. Keep an eye out for more AI Gateway Labs, and let us know what you think!
<walkthrough-inline-feedback></walkthrough-inline-feedback>

If you would like to continue with the **Security Lab**, just run this command:

```bash
teachme ./public/TUTORIAL_SECURITY.md
```
