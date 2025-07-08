param cosmosAccountName string
param apiPrincipalId string

// Create a role assignment for the API's managed identity to access Cosmos DB
// Using the built-in "Cosmos DB Built-in Data Contributor" role
resource apiCosmosRoleAssignment 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2024-05-15' = {
  name: '${cosmosAccountName}/${guid(apiPrincipalId, cosmosAccountName, '00000000-0000-0000-0000-000000000002')}'
  properties: {
    roleDefinitionId: '${resourceGroup().id}/providers/Microsoft.DocumentDB/databaseAccounts/${cosmosAccountName}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002'
    principalId: apiPrincipalId
    scope: '${resourceGroup().id}/providers/Microsoft.DocumentDB/databaseAccounts/${cosmosAccountName}'
  }
}