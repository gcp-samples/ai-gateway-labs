# AI Gateway Security Lab
---
This tutorial helps you add security policies such as model prompt screening with [Model Armor]() and PII data masking with [Sensitive Data Protection]() to the **AI Gateway** that you created in the first **Foundations Lab**

Let's get started!

---

## Prerequisites

First let's create some templates in Model Armor and Sensitive Data Protection to use from our AI Gateway.

```sh
gcloud model-armor templates create default-ma-template --project=$GOOGLE_CLOUD_PROJECT --location=$GOOGLE_CLOUD_LOCATION \
    --rai-settings-filters='[{ "filterType": "HATE_SPEECH", "confidenceLevel": "MEDIUM_AND_ABOVE" },{ "filterType": "HARASSMENT", "confidenceLevel": "MEDIUM_AND_ABOVE" },{ "filterType": "SEXUALLY_EXPLICIT", "confidenceLevel": "MEDIUM_AND_ABOVE" }]' \
    --basic-config-filter-enforcement=enabled  \
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
