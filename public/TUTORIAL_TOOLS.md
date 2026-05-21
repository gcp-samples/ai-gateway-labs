# AI Gateway Tools Lab
---
This tutorial helps you add security policies such as model prompt screening with [Model Armor](https://cloud.google.com/security/products/model-armor) and PII data masking with [Sensitive Data Protection](https://cloud.google.com/security/products/sensitive-data-protection) to the **AI Gateway** that you created in the first **Foundations Lab**.

Let's get started!

---

### Set Environment Variables

<img src="https://iili.io/C9AvqyN.png" />

1. **Copy** the `./sh/env.sh` file to a local `.env` file by running this command.

```sh
cp ./sh/env.sh .env
```

2. **Click**  <walkthrough-editor-open-file filePath=".env">here</walkthrough-editor-open-file> to open the `.env` file in the editor.

3. After **saving** your changes, load the variables by running these commands:

```sh
source .env
source ./sh/script_get_apigee.sh
```

---
