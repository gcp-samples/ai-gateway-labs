# AI Gateway Tools Lab
![Gemini proxy debug](https://amalbagee.web.app/apigee/ai-tools-gov1.png)

---

In this lab you will add tool goverance & integration to the **AI Gateway** that you created in the first **Foundations Lab**.

Let's get started!

---

### Set Environment Variables

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
npm i apigee-templater -g
```

## Provision API Hub (if not already provisioned)

![API Hub](https://amalbagee.web.app/apigee/apihub1.png)

[Apigee API Hub](https://docs.cloud.google.com/apigee/docs/apihub/what-is-api-hub) is a universal repository for any type of API, and so will be used in this lab to manage and store the AI tools' metadata and schemas.

In case API Hub is not already provisioned in your **Google Cloud Project**, then you can easily provision it with this **Terraform** command:

```sh
cd tf/hub
terraform init
terraform apply -var "project_id=$GOOGLE_CLOUD_PROJECT" -var "region=$GOOGLE_CLOUD_LOCATION"
cd ../..
source ./sh/script_hub_init.sh
```

Provisioning usually takes 10-15 minutes.
