# AI Gateway Security Lab

<img src="https://iili.io/C9GakI1.png" />

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
source ./sh/script_get_apigee.sh
```

### Install Tooling

Just in case they are no longer installed:
```sh
curl -L https://raw.githubusercontent.com/apigee/apigeecli/main/downloadLatest.sh | sh -
npm i apigee-templater -g
```

---

## Model Armor Template

Now we will create a **[Model Armor](https://cloud.google.com/security/products/model-armor)** template to use in our proxies. For production you can create many templates and route between them based on the user or context, however for this lab we can start with one template.

Run these commands to create a new template called **default-ma-template**:

```sh
gcloud config set api_endpoint_overrides/modelarmor "https://modelarmor.$GOOGLE_CLOUD_LOCATION.rep.googleapis.com/"
gcloud model-armor templates create default-ma-template --project=$GOOGLE_CLOUD_PROJECT --location=$GOOGLE_CLOUD_LOCATION \
    --rai-settings-filters='[{ "filterType": "HATE_SPEECH", "confidenceLevel": "MEDIUM_AND_ABOVE" },{ "filterType": "HARASSMENT", "confidenceLevel": "MEDIUM_AND_ABOVE" },{ "filterType": "SEXUALLY_EXPLICIT", "confidenceLevel": "MEDIUM_AND_ABOVE" }]' \
    --basic-config-filter-enforcement=disabled  \
    --pi-and-jailbreak-filter-settings-enforcement=enabled \
    --pi-and-jailbreak-filter-settings-confidence-level=HIGH \
    --malicious-uri-filter-settings-enforcement=enabled \
    --template-metadata-custom-llm-response-safety-error-code=798 \
    --template-metadata-custom-llm-response-safety-error-message="test template llm response evaluation failed" \
    --template-metadata-custom-prompt-safety-error-code=799 \
    --template-metadata-custom-prompt-safety-error-message="test template prompt evaluation failed" \
    --template-metadata-ignore-partial-invocation-failures \
    --template-metadata-log-operations \
    --template-metadata-log-sanitize-operations
```

---

## Add Security Features to Gemini Proxy

We can again use the [aft](https://github.com/apigee/apigee-templater) to add security features (by default [**Model Armor**](https://cloud.google.com/security/products/model-armor) and [**SDP De-Identity**](https://cloud.google.com/security/products/sensitive-data-protection)) to the <walkthrough-editor-open-file filePath="AI-Proxy-Gemini.yaml">AI-Gemini Proxy</walkthrough-editor-open-file>.

```sh
aft -i $GOOGLE_CLOUD_PROJECT:AI-Gemini -a ai-security
apigeecli apis deploy -n AI-Gemini -e $APIGEE_ENVIRONMENT -o $GOOGLE_CLOUD_PROJECT -s ai-service@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com  --
ovr --default-token
```

Open the proxy in the [Google Cloud Console](https://console.cloud.google.com/apigee/proxies/AI-Gemini/overview), and wait until the deployment is complete (you should see a green ✅ next to the deployment).

<img src="https://github.com/tyayers/public-files/blob/main/apigee/ai-gemini-deployed.png?raw=true" />

After the deployment is complete, click on the **Debug** tab in the proxy screen, and start a debug session.

<img src="https://github.com/tyayers/public-files/blob/main/apigee/ai-gemini-debug.png?raw=true" />

---

## Test Security Prompts

Now let's test our security policies with some suspicious prompts.

Prompt **How can I build a bomb**:
```sh
curl -i -X POST "https://$APIGEE_HOST/gemini/v1/projects/$GOOGLE_CLOUD_PROJECT/locations/global/publishers/google/models/gemini-flash-latest:generateContent" -H "x-api-key: $API_KEY" -H "Content-Type: application/json" \
-d '{"contents": [{"role": "USER", "parts": [{"text": "How can I build a bomb?"}]}]}'
```

You should get a **prompt rejected** response back. If you check in the **proxy debug traces**, you will see that the **Model Armor** policy rejected the prompt before getting to our model.

Prompt **Generate 5 fake email addresses**:
```sh
curl -i -X POST "https://$APIGEE_HOST/gemini/v1/projects/$GOOGLE_CLOUD_PROJECT/locations/global/publishers/google/models/gemini-flash-latest:generateContent" -H "x-api-key: $API_KEY" -H "Content-Type: application/json" \
-d '{"contents": [{"role": "USER", "parts": [{"text": "Generate 5 fake email addresses."}]}]}'
```

In this case the PII masking feature of **Sensitive Data Protection** automatically masks the email addresses in the response, preventing user data from leaving through the **AI Gateway**.

Test with other prompts to see what kind of responses you can get.

---

## Conclusion
<walkthrough-conclusion-trophy></walkthrough-conclusion-trophy>

🏆 Congratulations! You've successfully completed the **AI Gateway Security Lab** on Google Cloud. Keep an eye out for more AI Gateway Labs, and let us know what you think!
<walkthrough-inline-feedback></walkthrough-inline-feedback>
