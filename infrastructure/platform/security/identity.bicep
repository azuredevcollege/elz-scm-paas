@minLength(3)
@maxLength(8)
@description('Name of environment')
param env string = 'dev'

var identityName = 'identity-scm-${env}-${uniqueString(resourceGroup().id)}'
var location = resourceGroup().location

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: identityName
  location: location
}

output tenantId string = identity.properties.tenantId
output clientId string = identity.properties.clientId
output principalId string = identity.properties.principalId
