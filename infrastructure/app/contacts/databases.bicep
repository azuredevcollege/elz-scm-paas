@description('Name of landing zone resource group')
param landingZoneResourceGroupName string

@minLength(3)
@maxLength(8)
@description('Name of environment')
param env string = 'dev'

@description('Sql server\'s admin login name')
param sqlUserName string

@secure()
@description('Sql server\'s admin password')
param sqlUserPwd string

@description('Resource tags object to use')
param resourceTag object

// SQL database server and DB names
var sqlServerName = 'sql-scm-${env}-${uniqueString(resourceGroup().id)}'
var sqlDbName = 'sqldb-scm-contacts-${env}-${uniqueString(resourceGroup().id)}'
// vnet
var vnetName = 'vnet-scm-${env}-${uniqueString(rgLandingZone.id)}'
var privateendpointSubnetName = 'snet-data'
var privateEndpointName = 'pe-sqldb-contacts-${env}-${uniqueString(resourceGroup().id)}'
var privateZoneName = 'privatelink.databases.windows.net'
// location and tags
var location = resourceGroup().location

resource rgLandingZone 'Microsoft.Resources/resourceGroups@2021-01-01' existing = {
  name: landingZoneResourceGroupName
  scope: subscription()
}

resource vnet 'Microsoft.Network/virtualNetworks@2020-11-01' existing = {
  name: vnetName
  scope: resourceGroup(landingZoneResourceGroupName)
}

resource privateEndpointSubnet 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' existing = {
  name: '${vnet.name}/${privateendpointSubnetName}'
  scope: resourceGroup(landingZoneResourceGroupName)
}

resource privateZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: privateZoneName
}

resource sqlServer 'Microsoft.Sql/servers@2020-11-01-preview' = {
  name: sqlServerName
  location: location
  tags: resourceTag
  properties: {
    administratorLogin: sqlUserName
    administratorLoginPassword: sqlUserPwd
    version: '12.0'
    publicNetworkAccess: 'Enabled'
  }
  resource contactsDb 'databases@2020-11-01-preview' = {
    name: sqlDbName
    location: location
    tags: resourceTag
    sku: {
      name: 'Basic'
      tier: 'Basic'
      capacity: 5
    }
  }
  resource fwRule 'firewallRules@2020-11-01-preview' = {
    name: 'AllowWindowsAzureIps'
    properties: {
      startIpAddress: '0.0.0.0'
      endIpAddress: '0.0.0.0'
    }
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2020-11-01' = {
  name: privateEndpointName
  location: location
  properties: {
    privateLinkServiceConnections:[
      {
        name: '${privateEndpointName}-${uniqueString(resourceGroup().id)}'
        properties: {
          privateLinkServiceId: sqlServer.id
          groupIds:[
            'sqlServer'
          ]
        }
      }
    ]
    subnet: {
      id: privateEndpointSubnet.id
    }
  }

  resource privateZoneGroups 'privateDnsZoneGroups@2020-11-01' = {
    name: 'default'
    properties: {
      privateDnsZoneConfigs: [
        {
          name: privateZoneName
          properties: {
            privateDnsZoneId: privateZone.id
          }
        }
      ]
    }
  }
}

resource dnsRecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  name: '${privateZone.name}/${sqlServer.name}'
  properties: {
    ttl: 10
    aRecords: [
      {
        ipv4Address: privateEndpoint.properties.customDnsConfigs[0].ipAddresses[0]
      }
    ]
  }
}

output connectionString string = 'Server=tcp:${sqlServer.properties.fullyQualifiedDomainName},1433;Initial Catalog=${sqlDbName};Persist Security Info=False;User ID=${sqlServer.properties.administratorLogin};Password=${sqlUserPwd};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
