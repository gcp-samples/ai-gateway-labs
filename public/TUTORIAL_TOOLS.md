# AI Gateway Tools Lab
![Gemini proxy debug](https://amalbagee.web.app/apigee/ai-tools-gov1.png)

---

In this lab you will add tool goverance & integration to the **AI Gateway** that you created in the first **Foundations Lab**.

Let's get started!

---

## Set Environment Variables

<img src="https://iili.io/C9AvqyN.png" />

1. **Copy** the `./sh/env.sh` file to a local `.env` file by running this command.

```sh
cp --update=none ./sh/env.sh .env
```

2. **Click**  <walkthrough-editor-open-file filePath=".env">here</walkthrough-editor-open-file> to open the `.env` file in the editor.

3. After **saving** your changes, install the [aft tool](https://github.com/apigee/apigee-templater) and load the variables by running these commands:

```sh
npm install apigee-templater -g
source .env
source ./sh/script_get_apigee.sh
```

## Provision API Hub (if not already provisioned)

[![API Hub](https://amalbagee.web.app/apigee/apihub1.png)](https://amalbagee.web.app/apigee/apihub1.png)

[Apigee API Hub](https://docs.cloud.google.com/apigee/docs/apihub/what-is-api-hub) is a universal repository for any type of API, and so will be used in this lab to manage and store the AI tools' metadata and schemas.

In case API Hub is not already provisioned in your **Google Cloud Project**, then you can easily provision it with this **Terraform** command and entering **yes** after reviewing the changes:

```sh
cd tf/hub
terraform init
terraform apply -var "project_id=$GOOGLE_CLOUD_PROJECT" -var "region=$GOOGLE_CLOUD_LOCATION"
cd ../..
source ./sh/script_hub_init.sh
```

Provisioning usually takes 10-15 minutes.

At the moment you also need to manually configure the attachment for Apigee X, so [open the console](https://console.cloud.google.com/apigee/api-hub/settings/project-associations) and make sure that **Apigee X and Hybrid** is configured under **Associated plugins**. If it's blank, click on **Edit settings** and click **Apigee X and Hybrid**, and then save.

![API Hub plugin configuration](https://amalbagee.web.app/apigee/apihub-plugins1.png)

## Deploy REST Proxy

Our first **target tool** will be a **REST service** running in **[Cloud Run](https://cloud.google.com/run).** You can view the **OpenAPI spec [here](https://aigw-test-service-323709580283.europe-west1.run.app/openapi)**.

[![API Hub plugin configuration](https://amalbagee.web.app/apigee/openapi1.png)](https://aigw-test-service-323709580283.europe-west1.run.app/openapi)

Let's deploy an **Apigee proxy** to the REST service that enforces the **OpenAPI** specification. The proxy is also a great place to add authorization & security policies in the future.

Run this command to deploy the **proxy** to your **Apigee environment**:

```sh
aft REST-Proxy.yaml -o "$GOOGLE_CLOUD_PROJECT:REST-$UNIQUE_NAME-Product:$APIGEE_ENVIRONMENT" -p "BasePath=/${UNIQUE_NAME,,}-catalog"
```

Open the **[Apigee proxies view](https://console.cloud.google.com/apigee/proxies)** and click on your proxy, wait for the deployment to complete, and then start a **Debug session**.

Run these commands to make a **valid** call to the REST API:

```sh
curl "https://$APIGEE_HOST/${UNIQUE_NAME,,}-catalog/products"
```

You should get product data back. Try making some **invalid calls** and see how the calls are rejected by the **proxy** validation logic, which you can see in the debug trace. 

## Add REST-to-MCP Tool

> [!IMPORTANT]
> If you are in a group, only one person should do the following steps to create the MCP discovery proxy.

If you [open the API Hub console](https://console.cloud.google.com/apigee/api-hub/apis), you should see the **AI model proxies** that we deployed in the **Foundations Lab**.

[![API Hub Catalog](https://amalbagee.web.app/apigee/apihub-catalog1.png)](https://amalbagee.web.app/apigee/apihub-catalog1.png)

You should also see the new **REST-** proxy that we just deployed. Let's now deploy this as an **MCP tool** using the built-in [**REST-to-MCP Translation Server**](https://docs.cloud.google.com/apigee/docs/api-platform/apigee-mcp/apigee-mcp-overview) in Apigee. 

Click on the **+ Configure MCP tools** button at the top of the screen, and select your project. Fill in your project, environment group, and use **MCP proxy name** `mcp-proxy`.

Now go to **Step 2: Manage tools**, and select your **REST-Products** API, Version, Deployment, Specification, and all tools.

[![MCP Tool Configuration](https://amalbagee.web.app/apigee/mcp-proxy1.png)](https://amalbagee.web.app/apigee/mcp-proxy1.png)

Now review the configuration, and click **Deploy** to deploy the MCP discovery proxy. The deployment can take 5-10 minutes.

After the deployment is complete, start a **debug session** in the **mcp-proxy** and either use the [MCP Inspector](https://github.com/modelcontextprotocol/inspector) to test your endpoint, or just run this command to do a sample tool call:

```sh
curl -X POST "https://$APIGEE_HOST/mcp" \
  -H "Content-Type: application/json" \
  -d '{
  "jsonrpc": "2.0", 
  "id":0,
  "method": "tools/call",
  "params": {
    "name": "getProducts",
    "arguments": {},
    "_meta": {
      "progressToken": 0
    }
  }
}'
```

You should get the product data back, which has been automatically transcribed from the REST target proxy that we deployed earlier.

```terminal
{"id":0,"jsonrpc":"2.0","result":{"content":[{"text":"[{\"id\":\"prod_1\",\"name\":\"Wireless Mouse\",\"description\":\"Ergonomic 2.4GHz wireless mouse\",\"category\":\"Electronics\",\"price\":29.99,\"stock\":150},{\"id\":\"prod_2\",\"name\":\"Mechanical Keyboard\",\"description\":\"RGB backlit mechanical keyboard\",\"category\":\"Electronics\",\"price\":89.99,\"stock\":75},{\"id\":\"prod_3\",\"name\":\"Desk Lamp\",\"description\":\"LED desk lamp with adjustable brightness\",\"category\":\"Office\",\"price\":45,\"stock\":200},{\"id\":\"prod_4\",\"name\":\"USB-C Hub\",\"description\":\"7-in-1 USB-C adapter with HDMI and Power Delivery\",\"category\":\"Electronics\",\"price\":59.99,\"stock\":120},{\"id\":\"prod_5\",\"name\":\"Notebook\",\"description\":\"Premium A5 ruled notebook\",\"category\":\"Stationery\",\"price\":12.5,\"stock\":500}]\n","type":"text"}],"isError":false}}
```

You should also see the **/mcp requests** in the debug trace of the proxy.

[![MCP debug](https://amalbagee.web.app/apigee/mcp-debug1.png)](https://amalbagee.web.app/apigee/mcp-debug1.png)

## Add BigQuery MCP Tool

Now let's deploy a **proxy** to the [BigQuery MCP target](https://docs.cloud.google.com/bigquery/docs/use-bigquery-mcp) to show how to add policies and governance to direct MCP proxies and targets.
