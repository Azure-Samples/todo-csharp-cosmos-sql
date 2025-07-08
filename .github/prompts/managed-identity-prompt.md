# Converting Azure Templates from Cosmos DB Connection Strings to Managed Identity

This prompt provides step-by-step instructions for converting Azure Bicep templates from using Cosmos DB connection strings to managed identity authentication, ensuring compliance with Azure security policies that disallow local authentication methods.

## Problem Context

Azure security policies often require disabling local authentication methods for Cosmos DB, which means connection strings cannot be used. Templates must be updated to use managed identity authentication instead.

## Prerequisites

Before starting, ensure:
- The application code already supports managed identity (using `DefaultAzureCredential` and endpoint-based authentication)
- The template has system-assigned managed identity configured for the app service
- You understand the structure of your Bicep template files

## Step-by-Step Conversion Process

### 1. Remove Connection String Configuration

**In your Cosmos DB module (e.g., `infra/app/db-avm.bicep`):**

Remove the following parameters and configurations:
```bicep
// Remove these parameters
param connectionStringKey string = 'AZURE-COSMOS-CONNECTION-STRING'
param keyVaultResourceId string

// Remove this entire secretsExportConfiguration block
secretsExportConfiguration:{
  keyVaultResourceId: keyVaultResourceId
  primaryWriteConnectionStringSecretName: connectionStringKey
}

// Remove this output
output connectionStringKey string = connectionStringKey
```

**In your main template (e.g., `infra/main.bicep`):**

Remove connection string related configurations:
```bicep
// Remove from cosmos module parameters
keyVaultResourceId: keyVault.outputs.resourceId

// Remove from app settings
AZURE_COSMOS_CONNECTION_STRING_KEY: cosmos.outputs.connectionStringKey

// Remove from template outputs
output AZURE_COSMOS_CONNECTION_STRING_KEY string = cosmos.outputs.connectionStringKey
```

### 2. Enable Managed Identity Authentication

**Add `disableLocalAuth: true` to your Cosmos DB module:**
```bicep
module cosmos 'br/public:avm/res/document-db/database-account:0.6.0' = {
  name: 'cosmos-sql'
  params: {
    name: accountName
    location: location
    tags: tags
    disableLocalAuth: true  // ← Add this line
    // ... other parameters
  }
}
```

### 3. Handle Role Assignments Properly

**Critical:** Avoid duplicate Cosmos DB deployments that can override the `disableLocalAuth` setting.

**Create a separate role assignment module** (`infra/app/cosmos-role-assignment.bicep`):
```bicep
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
```

**In your main template, reference this module:**
```bicep
// Give the API access to Cosmos using a separate role assignment
module apiCosmosRoleAssignment './app/cosmos-role-assignment.bicep' = {
  name: 'api-cosmos-role'
  scope: rg
  params: {
    cosmosAccountName: cosmos.outputs.accountName
    apiPrincipalId: api.outputs.SERVICE_API_IDENTITY_PRINCIPAL_ID
  }
}
```

### 4. Important Role Assignment Details

**Use built-in role GUIDs, not custom role names:**
- Cosmos DB Built-in Data Reader: `00000000-0000-0000-0000-000000000001`
- Cosmos DB Built-in Data Contributor: `00000000-0000-0000-0000-000000000002`

**Avoid these common mistakes:**
- Using custom role definition names (like 'writer') instead of GUIDs
- Creating standalone role assignment resources at subscription scope
- Having circular dependencies between cosmos and API modules

### 5. Verify Required Components Remain

Ensure these components are preserved:
- ✅ System-assigned managed identity for the API app service
- ✅ `AZURE_COSMOS_ENDPOINT` environment variable for the API
- ✅ Key Vault access policies for the API's managed identity (if using Key Vault)
- ✅ Proper resource group scope for all resources

### 6. Testing and Validation

**Validate your changes:**
1. Run `bicep build` on your templates to check for compilation errors
2. Test deployment in a development environment
3. Verify the application can authenticate using managed identity
4. Confirm no connection string references remain in the template

## Common Issues and Solutions

### Issue: "Local authentication methods are not allowed"
**Solution:** Ensure `disableLocalAuth: true` is set and no duplicate Cosmos DB deployments exist.

### Issue: "Scope 'subscription' is not valid for this resource type"
**Solution:** Use a module approach instead of standalone role assignment resources.

### Issue: "SQL Role Definition name must be a GUID"
**Solution:** Use built-in role GUIDs (`00000000-0000-0000-0000-000000000002`) instead of custom names.

### Issue: Circular dependency errors
**Solution:** Separate role assignment into its own module to break dependency cycles.

## Final Checklist

- [ ] Removed all connection string configuration parameters
- [ ] Removed secretsExportConfiguration from Cosmos DB module
- [ ] Added `disableLocalAuth: true` to Cosmos DB account
- [ ] Created separate role assignment module using built-in role GUID
- [ ] Removed connection string references from app settings
- [ ] Verified no duplicate Cosmos DB module deployments exist
- [ ] Ensured managed identity and Key Vault access are preserved
- [ ] Tested template compilation and deployment

## Application Code Requirements

Your application code should already be using managed identity:

```csharp
var credential = new DefaultAzureCredential();
var cosmosClient = new CosmosClient(builder.Configuration["AZURE_COSMOS_ENDPOINT"], credential, ...);
```

This approach uses the `AZURE_COSMOS_ENDPOINT` environment variable and managed identity instead of connection strings.