@minLength(3)
@maxLength(8)
@description('Name of environment')
param env string = 'dev'

var vnetName = 'vnet-scm-${env}-${uniqueString(resourceGroup().id)}'
var location = resourceGroup().location

resource vnet 'Microsoft.Network/virtualNetworks@2020-11-01' existing = {
  name: vnetName
}

resource privateZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.azurewebsites.net'
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
}

resource privateZoneSoa 'Microsoft.Network/privateDnsZones/SOA@2020-01-01' = {
  name: '${privateZone.name}/@'
}
