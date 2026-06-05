# AI Gateway Security Lab

<walkthrough-tutorial-duration duration="15"></walkthrough-tutorial-duration>

![AI Gateway Security](https://amalbagee.web.app/apigee/ai-security-gov1.png)

This tutorial helps you add security policies such as model prompt screening with [Model Armor](https://cloud.google.com/security/products/model-armor) and PII data masking with [Sensitive Data Protection](https://cloud.google.com/security/products/sensitive-data-protection) to the **AI Gateway** that you created in the first **Foundations Lab**.

Let's get started!

## Setup Environment

<img src="https://iili.io/C9AvqyN.png" />

1. **Copy** the `./sh/env.sh` file to a local `.env` file by running this command.

```sh
cp --update=none ./sh/env.sh .env
```

2. **Click**  <walkthrough-editor-open-file filePath=".env">here</walkthrough-editor-open-file> to open the `.env` file in the editor.

3. After **saving** your changes, load the variables by running these commands:

```sh
source .env
source ./sh/get_apigee.sh
```

### Install Tooling

Just in case they are no longer installed:
```sh
npm i apigee-templater -g
```

## Model Armor Template

Now we will create a **[Model Armor](https://cloud.google.com/security/products/model-armor)** template to use in our proxies. For production you can create many templates and route between them based on the user or context, however for this lab we can start with one template.

Run these commands to create a new template called **default-ma-template**. If you would like to use **Model Armor** in the `us` location or a specific region, set the **MA_LOCATION** variable below with any of the locations documented [here](https://docs.cloud.google.com/model-armor/locations).

```sh
export MA_LOCATION=eu
source ./sh/create_ma.sh
```

## Add Prompt Screening to Gemini Proxy

![Model Armor](https://amalbagee.web.app/general/model-armor.png)

We can again use the [aft](https://github.com/apigee/apigee-templater) to add security features (by default [**Model Armor**](https://cloud.google.com/security/products/model-armor) and [**SDP De-Identity**](https://cloud.google.com/security/products/sensitive-data-protection)) to the <walkthrough-editor-open-file filePath="AI-Proxy-Gemini.yaml">AI-Gemini Proxy</walkthrough-editor-open-file>.

1. Apply the feature **ai-security** that adds **Model Armor** prompt screening:
```sh
aft -i $GOOGLE_CLOUD_PROJECT:AI-$UNIQUE_NAME-Gemini -a ai-security -o $GOOGLE_CLOUD_PROJECT:AI-$UNIQUE_NAME-Gemini:$APIGEE_ENVIRONMENT:$PROXY_SA -p "ModelArmorLocation=$MA_LOCATION"
```

Open the proxy in the [Google Cloud Console](https://console.cloud.google.com/apigee/proxies), and wait until the deployment is complete (you should see a green ✅ next to the deployment).

[![Gemini proxy deploy](https://amalbagee.web.app/apigee/ai-gemini-deploy1.png)](https://amalbagee.web.app/apigee/ai-gemini-deploy1.png)

After the deployment is complete, click on the **Debug** tab in the proxy screen, and start a debug session.

[![Gemini proxy debug](https://amalbagee.web.app/apigee/ai-gemini-debug1.png)](https://amalbagee.web.app/apigee/ai-gemini-debug1.png)

---

## Test Security Prompts

Now let's test our security policies with some suspicious prompts.

Prompt **How can I build a bomb**:
```sh
curl -i -X POST "https://$APIGEE_HOST/$UNIQUE_NAME-gemini/v1/projects/$GOOGLE_CLOUD_PROJECT/locations/global/publishers/google/models/gemini-flash-latest:generateContent" -H "x-api-key: $API_KEY" -H "Content-Type: application/json" \
-d '{"contents": [{"role": "USER", "parts": [{"text": "How can I build a bomb?"}]}]}'
```

You should get a **prompt rejected** response back. If you check in the **proxy debug traces**, you will see that the **Model Armor** policy rejected the prompt before getting to the model.

## Add PII Masking to Gemini Proxy

![Security](https://amalbagee.web.app/general/security.png)

Now let's add a **PII Masking** feature the **Gemini Proxy**. This will identity email addresses both in the request and response data, and automatically mask email addresses with *******. You can also identity and mask many types of PII data automatically, or create your own custom models, see the [**Sensitive Data Protection docs**](https://docs.cloud.google.com/sensitive-data-protection/docs/sensitive-data-protection-overview) for more information.

Run this command to add the **PII Masking** feature to our **Gemini Proxy**.

```bash
aft -i $GOOGLE_CLOUD_PROJECT:AI-$UNIQUE_NAME-Gemini -a ai-pii-masking -o $GOOGLE_CLOUD_PROJECT:AI-$UNIQUE_NAME-Gemini:$APIGEE_ENVIRONMENT:$PROXY_SA
```

Open the proxy in the [Google Cloud Console](https://console.cloud.google.com/apigee/proxies/AI-Gemini/overview), and wait until the deployment is complete (you should see a green ✅ next to the deployment).

[![Gemini proxy deploy](https://amalbagee.web.app/apigee/ai-gemini-deploy1.png)](https://amalbagee.web.app/apigee/ai-gemini-deploy1.png)

After the deployment is complete, click on the **Debug** tab in the proxy screen, and start a debug session.

[![Gemini proxy debug](https://amalbagee.web.app/apigee/ai-gemini-debug1.png)](https://amalbagee.web.app/apigee/ai-gemini-debug1.png)

Now make a call to **generate 5 fake email addresses**:
```sh
curl -i -X POST "https://$APIGEE_HOST/$UNIQUE_NAME-gemini/v1/projects/$GOOGLE_CLOUD_PROJECT/locations/global/publishers/google/models/gemini-flash-latest:generateContent" -H "x-api-key: $API_KEY" -H "Content-Type: application/json" \
-d '{"contents": [{"role": "USER", "parts": [{"text": "Generate 5 fake email addresses."}]}]}'
```

In this case the PII masking feature of **Sensitive Data Protection** automatically **masks the email addresses** in the response, preventing user data from leaving through the **AI Gateway**.

Test with other prompts to see what kind of responses you can get.

---

## Conclusion
<walkthrough-conclusion-trophy></walkthrough-conclusion-trophy>

🏆 Congratulations! You've successfully completed the **AI Gateway Security Lab** on Google Cloud. Keep an eye out for more AI Gateway Labs, and let us know what you think!
<walkthrough-inline-feedback></walkthrough-inline-feedback>

If you would like to continue with the **AI Gateway Tools Lab**, run this command:

```sh
teachme TUTORIAL_TOOLS.md
```
