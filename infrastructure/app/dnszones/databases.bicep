@description('Name of landing zone resource group')
param landingZoneResourceGroupName string

@minLength(3)
@maxLength(8)
@description('Name of environment')
param env string = 'dev'

var vnetName = 'vnet-scm-${env}-${uniqueString(rgLandingZone.id)}'
var privateZoneName = 'privatelink.databases.windows.net'
var location = resourceGroup().location

resource rgLandingZone 'Microsoft.Resources/resourceGroups@2021-01-01' existing = {
  name: landingZoneResourceGroupName
  scope: subscription()
}

resource vnet 'Microsoft.Network/virtualNetworks@2020-11-01' existing = {
  name: vnetName
  scope: resourceGroup(landingZoneResourceGroupName)
}

resource privateZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateZoneName
  location: 'global'

  resource vnetLinks 'virtualNetworkLinks@2020-06-01' = {
    name: '${uniqueString(resourceGroup().id)}'
    location: 'global'
    properties: {
      registrationEnabled: false
      virtualNetwork:{
        id: vnet.id
      }
    }
  }

  resource privateZoneSOA 'SOA@2020-06-01' = {
    name: '@'
  }
}
