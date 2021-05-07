targetScope = 'subscription'

@description('Name of resource group where LZ components are deployed to')
param resourceGroupName string

@minLength(3)
@maxLength(8)
@description('Name of environment')
param env string = 'dev'

@description('The principal id of the Azure AD\'s security proncipal to use (user, app or group)')
param securityPrincipalId string

// variables
var location = deployment().location

// create needed resource groups
resource rgLandingZone 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: resourceGroupName
  location: location
}

module network 'network/networkmain.bicep' = {
  name: 'deployNetwork'
  scope: resourceGroup(rgLandingZone.name)
  params:{
    env: env
  }
}

module security 'security/securitymain.bicep' = {
  name: 'deploySecurity'
  scope: resourceGroup(rgLandingZone.name)
  params:{
    env: env
    securityPrincipalId: securityPrincipalId
  }
}
