param environmentName string
param location string = resourceGroup().location
param principalId string = ''

module appServicePlan './modules/appserviceplan-sites.bicep' = {
  name: 'appserviceplan-resources'
  params: {
    environmentName: environmentName
    location: location
  }
}

module web './modules/website-node.bicep' = {
  name: 'web-resources'
  params: {
    environmentName: environmentName
    location: location
    serviceName: 'web'
  }
  dependsOn: [
    applicationInsights
    appServicePlan
  ]
}

module api './modules/website-dotnet.bicep' = {
  name: 'api-resources'
  params: {
    environmentName: environmentName
    location: location
    serviceName: 'api'
    useKeyVault: true
  }
  dependsOn: [
    applicationInsights
    keyVault
    appServicePlan
  ]
}

module apiCosmosConfig './modules/website-config-cosmos.bicep' = {
  name: 'api-cosmos-config-resources'
  params: {
    resourceName: api.outputs.NAME
    serviceName: 'api'
    cosmosDatabaseName: cosmos.outputs.AZURE_COSMOS_DATABASE_NAME
    cosmosConnectionStringKey: cosmos.outputs.AZURE_COSMOS_CONNECTION_STRING_KEY
    cosmosEndpoint: cosmos.outputs.AZURE_COSMOS_ENDPOINT
  }
}

module keyVault './modules/keyvault.bicep' = {
  name: 'keyvault-resources'
  params: {
    environmentName: environmentName
    location: location
    principalId: principalId
  }
}

module cosmos './modules/cosmos-sql-db.bicep' = {
  name: 'cosmos-resources'
  params: {
    environmentName: environmentName
    location: location
    principalIds: [principalId, api.outputs.IDENTITY_PRINCIPAL_ID]
  }
  dependsOn: [
    keyVault
  ]
}

module logAnalytics './modules/loganalytics.bicep' = {
  name: 'loganalytics-resources'
  params: {
    environmentName: environmentName
    location: location
  }
}

module applicationInsights './modules/applicationinsights.bicep' = {
  name: 'applicationinsights-resources'
  params: {
    environmentName: environmentName
    location: location
    workspaceId: logAnalytics.outputs.AZURE_LOG_ANALYTICS_WORKSPACE_ID
  }
}

output AZURE_COSMOS_ENDPOINT string = cosmos.outputs.AZURE_COSMOS_ENDPOINT
output AZURE_COSMOS_CONNECTION_STRING_KEY string = cosmos.outputs.AZURE_COSMOS_CONNECTION_STRING_KEY
output AZURE_COSMOS_DATABASE_NAME string = cosmos.outputs.AZURE_COSMOS_DATABASE_NAME
output AZURE_KEY_VAULT_ENDPOINT string = keyVault.outputs.AZURE_KEY_VAULT_ENDPOINT
output APPLICATIONINSIGHTS_CONNECTION_STRING string = applicationInsights.outputs.APPLICATIONINSIGHTS_CONNECTION_STRING
output WEB_URI string = web.outputs.URI
output API_URI string = api.outputs.URI
