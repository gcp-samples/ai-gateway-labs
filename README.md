# Apigee AI Gateway Lab
This lab guides the user through templating a complete AI Gateway to manage & govern the usage of models, tools & agents in the organization.

## Step 1: Prerequisites
You will need a **Google Cloud Project** with the project permissions to provision [Apigee]([url](https://cloud.google.com/apigee)) and a [Google Cloud Load Balancer]([url](https://cloud.google.com/load-balancing)) to ingest traffic.

To begin, open the [Google Cloud Shell](https://docs.cloud.google.com/shell), or another shell with the [gcloud](https://cloud.google.com/cli) and [Terraform](https://developer.hashicorp.com/terraform/install) CLIs installed.

Set your **Google Cloud Project** and **Region** as environment variables in your shell.

```sh
GOOGLE_CLOUD_PROJECT=YOUR_PROJECT_ID
GOOGLE_CLOUD_LOCATION=YOUR_REGION
```
Setting the variables in Google Cloud Shell:

![Google Cloud Shell Environment Variables](https://raw.githubusercontent.com/tyayers/public-files/refs/heads/main/apigee/apigee-aigw-shell1.png)

## Step 2: Provision Apigee in your Google Cloud project
Apigee X can easily be provisioned in Google Cloud either as a **Trial (60 days)**, **Pay-as-you-go**, or **Subscription** org. See [here](https://docs.cloud.google.com/apigee/docs/api-platform/get-started/provisioning-options) for more details. 

You will need a provisioned org before proceeding with this lab.

To provision Apigee with [Terraform](url) in your project:

```sh
BILLING_ID=YOUR_BILLING_ID
cd tf
terraform init
terraform apply -var "project_id=$GOOGLE_CLOUD_PROJECT" -var "billing_id=$BILLING_ID" \
--var-file=variables.tfvars
```

To provision with the wizard in the Google Cloud console:

![Apigee provisioning wizard](https://raw.githubusercontent.com/tyayers/public-files/refs/heads/main/apigee/apigee-aigw-provision.png)

## Step 3: Deploy AI model proxies
A **proxy** in Apigee transfers, secures & mediates any type of network API traffic, so to start we're going to secure our **AI model** access.
