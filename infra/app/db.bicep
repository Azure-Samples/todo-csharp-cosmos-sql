param environmentName string
param location string = resourceGroup().location

param containers array = [
  {
    name: 'TodoList'
    id: 'TodoList'
    partitionKey: '/id'
  }
  {
    name: 'TodoItem'
    id: 'TodoItem'
    partitionKey: '/id'
  }
]
param cosmosDatabaseName string = 'Todo'
param keyVaultName string
param principalIds array = []

module cosmos '../core/database/cosmos-sql-db.bicep' = {
  name: 'cosmos-sql-resources'
  params: {
    environmentName: environmentName
    location: location
    containers: containers
    cosmosDatabaseName: cosmosDatabaseName
    keyVaultName: keyVaultName
    principalIds: principalIds
  }
}

output cosmosConnectionStringKey string = cosmos.outputs.cosmosConnectionStringKey
output cosmosDatabaseName string = cosmosDatabaseName
output cosmosEndpoint string = cosmos.outputs.cosmosEndpoint
