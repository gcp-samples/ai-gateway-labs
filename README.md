# AI Gateway Labs on Google Cloud
These labs guide you through creating an AI Gateway on Google Cloud leveraging [Apigee AI Gateway](https://cloud.google.com/solutions/apigee-ai). In these labs the AI Gateway will be using models from the [Gemini Enterprise Model Garden](https://cloud.google.com/model-garden), but can also proxy / integrate models from any provider.

![AI Gateway Overview](https://iili.io/Bm91xHB.png)

## Resources Used
* The [Apigee Emulator](https://docs.cloud.google.com/apigee/docs/api-platform/local-development/vscode/manage-apigee-emulator) will be used, running in a [Google Cloud Run](https://cloud.google.com/run) container. You can deploy your own emulator and lab environment for testing using this [guide](https://discuss.google.dev/t/tutorial-automated-testing-of-apigee-proxies-and-deployments-with-the-apigee-emulator).
* [Apigee Templates](https://github.com/gcp-samples/apigee-template-repository) are used for AI proxy deployments.
* [Apigee Feature Templater (aft)](https://github.com/apigee/apigee-templater) is used as deployment tool.

## Prerequisites
* None! The labs run completely in the browser using the Apigee Emulator.

## Notes For Instructors
If you are running this lab, you can deploy all of the proxies, products & assets to your own Apigee X org with this command, which can be useful to demonstrate the proxies in a production-like environment. If you are a Googler, then you can access a production deployment [here](https://console.cloud.google.com?project=bap-emea-apigee-7).

```sh
aft https://raw.githubusercontent.com/gcp-samples/ai-gateway-labs/refs/heads/main/apigee-deployment.yaml --project YOUR_PROJECT_ID --env YOUR_APIGEE_ENV --sa YOUR_SA_ACCOUNT
```

## Labs
1. Open the labs here: https://apigee-emulator-ghfontasua-ew.a.run.app/labs.
2. Register with your name, and test & trace the model APIs **Interactions API**, **Completions API**, **Generate Content API**, **Messages API** and the **Embeddings API**.
3. Test **Model Security** using [Google Cloud Model Armor]().
4. Test **Model Failover** using [Apigee Fault Rules]().
5. Test **Smart Model** routing using [Apigee Evals]().
6. Test **MCP Authorization** on a demo MCP server using [Apigee MCP Support]().
7. Visualize **AI Analytics** using [Apigee Analytics]().
