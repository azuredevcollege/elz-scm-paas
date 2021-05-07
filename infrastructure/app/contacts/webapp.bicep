@description('Name of landing zone resource group')
param landingZoneResourceGroupName string

@minLength(3)
@maxLength(8)
@description('Name of environment')
param env string = 'dev'

@description('Resource tags object to use')
param resourceTag object

param sqlConnectionString string

// ContactsAPI WebApp
var webAppName = 'app-contactsapi-${env}-${uniqueString(resourceGroup().id)}'
// AppService Plan Windows
var planWindowsName = 'plan-scm-win-${env}-${uniqueString(resourceGroup().id)}'
// ApplicationInsights name
var appiName = 'appi-scm-${env}-${uniqueString(resourceGroup().id)}'
// ServiceBus names
var sbName = 'sb-scm-${env}-${uniqueString(resourceGroup().id)}'
var sbtContactsName = 'sbt-contacts'
// vnet
var vnetName = 'vnet-scm-${env}-${uniqueString(rgLandingZone.id)}'
var privateendpointSubnetName = 'snet-workload'
var privateEndpointName = 'pe-contactsapi-${env}-${uniqueString(resourceGroup().id)}'
var privateZoneName = 'privatelink.azurewebsites.net'
var integrationSubnetName = 'snet-appservice-integration'

var location = resourceGroup().location

resource rgLandingZone 'Microsoft.Resources/resourceGroups@2021-01-01' existing = {
  name: landingZoneResourceGroupName
  scope: subscription()
}

resource appi 'Microsoft.Insights/components@2015-05-01' existing = {
  name: appiName
}

resource sb 'Microsoft.ServiceBus/namespaces@2017-04-01' existing = {
  name: sbName
}

resource sbtContacts 'Microsoft.ServiceBus/namespaces/topics@2017-04-01' existing = {
  name: '${sb.name}/${sbtContactsName}'
}

resource sbtContactsSendRule 'Microsoft.ServiceBus/namespaces/topics/authorizationRules@2017-04-01' existing = {
  name: '${sbtContacts.name}/send'
}

resource appplan 'Microsoft.Web/serverfarms@2020-12-01' existing = {
  name: planWindowsName
}

resource vnet 'Microsoft.Network/virtualNetworks@2020-11-01' existing = {
  name: vnetName
  scope: resourceGroup(landingZoneResourceGroupName)
}

resource privateEndpointSubnet 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' existing = {
  name: '${vnet.name}/${privateendpointSubnetName}'
  scope: resourceGroup(landingZoneResourceGroupName)
}

resource integrationSubnet 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' existing = {
  name: '${vnet.name}/${integrationSubnetName}'
  scope: resourceGroup(landingZoneResourceGroupName)
}

resource privateZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: privateZoneName
}

resource webapp 'Microsoft.Web/sites@2020-12-01' = {
  name: webAppName
  location: location
  tags: resourceTag
  properties: {
    serverFarmId: appplan.id
    httpsOnly: true
    clientAffinityEnabled: false
    siteConfig: {
      alwaysOn: true
      use32BitWorkerProcess: false
      vnetName: integrationSubnetName
      cors: {
        allowedOrigins: [
          '*'
        ]
      }
      appSettings:[
        {
          name: 'WEBSITE_VNET_ROUTE_ALL'
          value: '1'
        }
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appi.properties.InstrumentationKey
        }
        {
          name: 'EventServiceOptions__ServiceBusConnectionString'
          value: listKeys(sbtContactsSendRule.id, sbtContactsSendRule.apiVersion).primaryConnectionString
        }
      ]
      connectionStrings:[
        {
          name: 'DefaultConnectionString'
          connectionString: sqlConnectionString
          type: 'SQLAzure'
        }
      ]
    }
  }

  resource vnetIntegration 'networkConfig@2020-10-01' = {
    name: 'virtualNetwork'
    properties: {
      subnetResourceId: integrationSubnet.id
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
          privateLinkServiceId: webapp.id
          groupIds:[
            'sites'
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

output contactsApiWebAppName string = webAppName
