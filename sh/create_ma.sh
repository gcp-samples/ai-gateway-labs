gcloud config set api_endpoint_overrides/modelarmor "https://modelarmor.$MA_LOCATION.rep.googleapis.com/"

gcloud model-armor templates create default-ma-template --project=$GOOGLE_CLOUD_PROJECT --location=$MA_LOCATION \
    --rai-settings-filters='[{ "filterType": "HATE_SPEECH", "confidenceLevel": "MEDIUM_AND_ABOVE" },{ "filterType": "HARASSMENT", "confidenceLevel": "MEDIUM_AND_ABOVE" },{ "filterType": "SEXUALLY_EXPLICIT", "confidenceLevel": "MEDIUM_AND_ABOVE" },{ "filterType": "DANGEROUS", "confidenceLevel": "MEDIUM_AND_ABOVE" }]' \
    --basic-config-filter-enforcement=disabled  \
    --pi-and-jailbreak-filter-settings-enforcement=disabled \
    --pi-and-jailbreak-filter-settings-confidence-level=HIGH \
    --malicious-uri-filter-settings-enforcement=enabled \
    --template-metadata-custom-llm-response-safety-error-code=798 \
    --template-metadata-custom-llm-response-safety-error-message="test template llm response evaluation failed" \
    --template-metadata-custom-prompt-safety-error-code=799 \
    --template-metadata-custom-prompt-safety-error-message="test template prompt evaluation failed" \
    --template-metadata-ignore-partial-invocation-failures \
    --template-metadata-log-operations \
    --template-metadata-log-sanitize-operations
