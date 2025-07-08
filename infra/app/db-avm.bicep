param accountName string
param location string = resourceGroup().location
param tags object = {}
param databaseName string = ''
param principalId string = ''

@allowed([
  'Periodic'
  'Continuous'
])
@description('Optional. Default to Continuous. Describes the mode of backups. Periodic backup must be used if multiple write locations are used.')
param backupPolicyType string = 'Continuous'

var defaultDatabaseName = 'Todo'
var actualDatabaseName = !empty(databaseName) ? databaseName : defaultDatabaseName

module cosmos 'br/public:avm/res/document-db/database-account:0.6.0' = {
  name: 'cosmos-sql'
  params: {
    name: accountName
    location: location
    tags: tags
    backupPolicyType: backupPolicyType
    disableLocalAuth: true
    locations: [
      {
        failoverPriority: 0
        locationName: location
        isZoneRedundant: false
      }
    ]

    capabilitiesToAdd: [ 'EnableServerless' ] 
    automaticFailover: false
    sqlDatabases: [
      {
        name: actualDatabaseName
        containers: [
          {
            name: 'TodoList'
            paths: [ 'id' ]
          }
          {
            name: 'TodoItem'
            paths: [ 'id' ]
          }
        ]
      }
    ] 
    sqlRoleAssignmentsPrincipalIds: [ principalId ]
  }
}

output accountName string = cosmos.outputs.name
output databaseName string = actualDatabaseName
output endpoint string = cosmos.outputs.endpoint
