# AI Gateway Foundations Lab

<walkthrough-tutorial-duration duration="30-60"></walkthrough-tutorial-duration>

<img src="https://iili.io/C9Al3Ol.jpg" />

This tutorial guides you through provisioning an **AI Gateway** in your Google Cloud project, and then creating AI proxies to add **governance & analytics** at the gateway level to agentic tools like **Gemini CLI**, **Claude Code**, or any other AI application.

### Definitions
We will be using several terms in these labs, so here are some definitions to get started:

* **Proxy**: An endpoint that receives and processes traffic before directing it to the actual **target** or backend service.
* **Target**: The actual target service behind the **proxy**, so for example an **AI model**, **REST or MCP tool**, or an **A2A agent**.
* More information on **proxies** and **targets** can be found [here](https://docs.cloud.google.com/apigee/docs/api-platform/fundamentals/understanding-apis-and-api-proxies#whatisanapiproxy).

Let's go!

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
* Cloud AI Companion User (roles/cloudaicompanion.user)
* Service Account User (roles/iam.serviceAccountUser)
* Model Armor Template Admin (roles/modelarmor.admin)

---

## Setup

<img src="https://iili.io/C9AvqyN.png" />

To begin you need to configure your environment with your Google Cloud Project, region, and other details. 

Run this script to collect the information and set the variables:

```sh
source ./sh/initialize.sh
```

> [!TIP]
> In case you want to set your own network, subnet or DRZ configuration, <walkthrough-editor-open-file filePath="./.env">edit</walkthrough-editor-open-file> the **.env** file and set the **Optional Variables** accordingly, and then run `source .env` to reload.

<walkthrough-footnote>Because you are logged in with the **[Google CLoud CLI (gcloud)](https://cloud.google.com/sdk)**, all of our tool calls will automatically be authenticated with **[Application Default Credentials](https://docs.cloud.google.com/docs/authentication/application-default-credentials)**.</walkthrough-footnote>

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
source ./sh/script_tf_clean.sh
cd tf/apigee
terraform init
terraform apply -var "project_id=$GOOGLE_CLOUD_PROJECT" -var "region=$GOOGLE_CLOUD_LOCATION" --var "apigee_type=$APIGEE_TYPE"
cd ../..
```

Provisioning takes around 20-30 minutes for all services to be enabled & deployed.

## Load Environment Information

<img src="https://iili.io/C9AvqyN.png" />

After provisioning is finished, let's initialize the Apigee environment, enable Model Garden and other services, and create a service account to access our AI models.

Take a look at the <walkthrough-editor-open-file filePath="./sh/script_initialize.sh">script_initialize.sh</walkthrough-editor-open-file> file to see the commands that are run.

Run this command to **load** the environment information:
```sh
source ./sh/get_apigee.sh
```

## Test Gemini API

Now let's make a direct call to the Gemini API on [Model Garden](https://cloud.google.com/model-garden), to verify that it is working.

<img src="https://iili.io/C9TPzEF.png" height=60 />

```sh
curl -s -X POST "https://aiplatform.googleapis.com/v1/projects/$GOOGLE_CLOUD_PROJECT/locations/global/publishers/google/models/gemini-flash-latest:generateContent" -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" -H "Content-Type: application/json" \
-d '{"contents": [{"role": "USER", "parts": [{"text": "Explain why the sky is blue in one sentence."}]}]}' | jq -r '"\n\u001b[1mModel response:\u001b[0m \u001b[32m\(.candidates[0].content.parts[0].text)\u001b[0m"'
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
curl -s -X POST "https://$APIGEE_HOST/${UNIQUE_NAME,,}-gemini/v1/projects/$GOOGLE_CLOUD_PROJECT/locations/global/publishers/google/models/gemini-flash-latest:generateContent" -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" -H "Content-Type: application/json" \
-d '{"contents": [{"role": "USER", "parts": [{"text": "Explain why the sky is blue in one sentence."}]}]}' | jq -r '"\n\u001b[1mModel response:\u001b[0m \u001b[32m\(.candidates[0].content.parts[0].text)\u001b[0m"'
```

You should get a similar response again about **'Rayleigh scattering'**. In case you get an **OpenSSL SSL_connect** error it means that the load balancer certificate is still provisioning, so just wait a few minutes and try again until it works (can take 5-10 minutes).

Go back to the Debug panel, and see the processing steps, timings and variables that were done between the request and response.

[![Gemini proxy debug result](https://amalbagee.web.app/apigee/ai-gemini-debug2.png)](https://amalbagee.web.app/apigee/ai-gemini-debug2.png)

✅ Now we have a proxy in place to add governance & analytics to the AI prompt requests.

## Add Model Authorization, Governance & Analytics

Now we will update the proxy with authorization, governance & analytics policies, as well as add proxies to more models.

![AI proxies governance](https://amalbagee.web.app/apigee/ai-proxies-gov1.png)

The proxy definitions are YAML templates (see <walkthrough-editor-open-file filePath="./templates/AI-Proxy-Gemini.yaml">AI-Proxy-Gemini.yaml</walkthrough-editor-open-file> for an example), and see the [aft documentation](https://github.com/apigee/apigee-templater) for more information.

Deploy the AI proxy templates:

```sh
aft ./templates/AI-Proxy-Gemini.yaml -o "$GOOGLE_CLOUD_PROJECT:AI-$UNIQUE_NAME-Gemini:$APIGEE_ENVIRONMENT:$PROXY_SA" -p "ModelBasePath=/${UNIQUE_NAME,,}-gemini"
aft ./templates/AI-Proxy-DeepSeek.yaml -o "$GOOGLE_CLOUD_PROJECT:AI-$UNIQUE_NAME-DeepSeek:$APIGEE_ENVIRONMENT:$PROXY_SA" -p "ModelBasePath=/${UNIQUE_NAME,,}-deepseek"
aft ./templates/AI-Proxy-Qwen.yaml -o "$GOOGLE_CLOUD_PROJECT:AI-$UNIQUE_NAME-Qwen:$APIGEE_ENVIRONMENT:$PROXY_SA" -p "ModelBasePath=/${UNIQUE_NAME,,}-qwen"
aft ./templates/AI-Proxy-Claude.yaml -o "$GOOGLE_CLOUD_PROJECT:AI-$UNIQUE_NAME-Claude:$APIGEE_ENVIRONMENT:$PROXY_SA" -p "ModelBasePath=/${UNIQUE_NAME,,}-claude"
aft -i ./templates/AI-Analytics.yaml -o $GOOGLE_CLOUD_PROJECT:AI-Analytics:$APIGEE_ENVIRONMENT
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
curl -s -X POST "https://$APIGEE_HOST/${UNIQUE_NAME,,}-gemini/v1beta1/projects/$GOOGLE_CLOUD_PROJECT/locations/global/endpoints/openapi/chat/completions" -H "x-api-key: $API_KEY" -H "Content-Type: application/json; charset=utf-8" \
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

Now update Gemini to use Google Cloud Agent Platform (formally Vertex AI, can be changed back afterwards), as well as setting the Apigee proxy URL and key:

```sh
source ./sh/set_gemini.sh
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
claude -p "Why is the sky blue?"
```

![Claude code](https://amalbagee.web.app/general/claude1.png)

All of the model communication goes through your **AI Gateway Claude Proxy** with access control through the **Claude Product**.

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

## Conclusion
<walkthrough-conclusion-trophy></walkthrough-conclusion-trophy>

🏆 Congratulations! You've successfully completed the **AI Gateway Foundations Lab** on Google Cloud. Keep an eye out for more AI Gateway Labs, and let us know what you think!
<walkthrough-inline-feedback></walkthrough-inline-feedback>

If you would like to continue with the **Security Lab**, just run this command:

```bash
teachme TUTORIAL_SECURITY.md
```
