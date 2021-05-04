@minLength(3)
@maxLength(8)
@description('Name of environment')
param env string = 'dev'

var vnetName = 'vnet-scm-${env}-${uniqueString(resourceGroup().id)}'
var location = resourceGroup().location

resource vnet 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace:{
      addressPrefixes:[
        '10.0.0.0/16'
      ]
    }
    subnets:[
      {
        name: 'snet-data'
        properties:{
          addressPrefix: '10.0.1.0/24'
        }
      }
      {
        name: 'snet-workload'
        properties:{
          addressPrefix: '10.0.2.0/24'
        }
      }
      {
        name: 'snet-public'
        properties:{
          addressPrefix: '10.0.3.0/24'
        }
      }
      {
        name: 'snet-appservice-integration'
        properties: {
          addressPrefix: '10.0.4.0/24'
        }
      }
    ]
  }
}
