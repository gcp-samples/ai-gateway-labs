# Attach project to API Hub instance for automatic API proxy syncronization
sleep 5
curl -X POST "https://apihub.googleapis.com/v1/projects/$GOOGLE_CLOUD_PROJECT/locations/$GOOGLE_CLOUD_LOCATION/runtimeProjectAttachments?runtimeProjectAttachmentId=$GOOGLE_CLOUD_PROJECT" \
  -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
  -H "Content-Type: application/json" -H "X-Google-GFE-Can-Retry: yes" \
  --data-binary @- << EOF

{
  "runtimeProject": "projects/$GOOGLE_CLOUD_PROJECT"
}
EOF
