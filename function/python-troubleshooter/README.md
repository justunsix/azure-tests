# Python Troubleshooter Azure Function

Function to deploy in Azure to troubleshoot issues with the function like connectivity.

## Pre-requisites

- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
- [Python version supported by Azure Functions](https://learn.microsoft.com/en-us/azure/azure-functions/supported-languages#languages-by-runtime-version)
- [Azure Functions Core Tools](https://github.com/Azure/azure-functions-core-tools/blob/v4.x/README.md)
- Optional: [Azurite storage emulator](https://learn.microsoft.com/en-us/azure/storage/common/storage-use-azurite?tabs=npm#install-azurite)

## Set up and Run Locally

- Create and activate a Python virtual environment
- Run the function. If you experience an error like "No job functions found. Try making your job classes and methods public", see this set of troubleshooting steps: <https://stackoverflow.com/questions/78676628/azure-functions-no-job-found-python>
  - An issue with the func init seem to create an invalid
    python file and requires fixes
    `"AzureWebJobsFeatureFlags": "EnableWorkerIndexing",`
- Visit the function at <http://localhost:7071/api/HttpExample?name=yourname>

## Resources

- [Azure Functions Documentation - Create a Python function](https://learn.microsoft.com/en-us/azure/azure-functions/create-first-function-cli-python)
