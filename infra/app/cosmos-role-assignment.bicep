param cosmosAccountName string
param apiPrincipalId string

// Create a role assignment for the API's managed identity to access Cosmos DB
resource apiCosmosRoleAssignment 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2024-05-15' = {
  name: '${cosmosAccountName}/${guid(apiPrincipalId, cosmosAccountName, 'writer')}'
  properties: {
    roleDefinitionId: '${resourceGroup().id}/providers/Microsoft.DocumentDB/databaseAccounts/${cosmosAccountName}/sqlRoleDefinitions/writer'
    principalId: apiPrincipalId
    scope: '${resourceGroup().id}/providers/Microsoft.DocumentDB/databaseAccounts/${cosmosAccountName}'
  }
}