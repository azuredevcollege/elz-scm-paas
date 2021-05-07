@description('Name of landing zone resource group')
param landingZoneResourceGroupName string

@minLength(3)
@maxLength(8)
@description('Name of environment')
param env string = 'dev'

module azurewebsites 'azurewebsites.bicep' = {
  name: 'deployPrivateDNSZoneAzureWebSites'
  params: {
    env: env
    landingZoneResourceGroupName: landingZoneResourceGroupName
  }
}

module database 'databases.bicep' = {
  name: 'deployPrivateDNSZoneDatabases'
  params: {
    env: env
    landingZoneResourceGroupName: landingZoneResourceGroupName
  }
}
