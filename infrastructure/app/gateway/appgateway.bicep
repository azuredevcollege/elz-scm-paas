@description('Name of landing zone resource group')
param landingZoneResourceGroupName string

@minLength(3)
@maxLength(8)
@description('Name of environment')
param env string = 'dev'

param sslCertSecretName string

var appGatewayName = 'appgw-scm-${env}-${uniqueString(resourceGroup().id)}'
var pipName = 'pip-scm-${env}-${uniqueString(rgLandingZone.id)}'
var vnetName = 'vnet-scm-${env}-${uniqueString(rgLandingZone.id)}'
var subnetName = 'snet-public'
var contactsAppFqdn = 'app-contactsapi-${env}-${uniqueString(resourceGroup().id)}.azurewebsites.net'
var identityName = 'identity-scm-${env}-${uniqueString(rgLandingZone.id)}'
var keyVaultName = 'kv-scm-${env}-${uniqueString(rgLandingZone.id)}'
var location = resourceGroup().location

resource rgLandingZone 'Microsoft.Resources/resourceGroups@2021-01-01' existing = {
  name: landingZoneResourceGroupName
  scope: subscription()
}

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing = {
  name: identityName
  scope: resourceGroup(landingZoneResourceGroupName)
}

resource kv 'Microsoft.KeyVault/vaults@2021-04-01-preview' existing = {
  name: keyVaultName
  scope: resourceGroup(landingZoneResourceGroupName)
}

resource vnet 'Microsoft.Network/virtualNetworks@2020-11-01' existing = {
  name: vnetName
  scope: resourceGroup(landingZoneResourceGroupName)
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' existing = {
  name: '${vnet.name}/${subnetName}'
  scope: resourceGroup(landingZoneResourceGroupName)
}

resource pip 'Microsoft.Network/publicIPAddresses@2020-11-01' existing = {
  name: pipName
  scope: resourceGroup(landingZoneResourceGroupName)
}

resource applicationGateway 'Microsoft.Network/applicationGateways@2020-11-01' = {
  name: appGatewayName
  location: location
  identity: {
    type:'UserAssigned'
    userAssignedIdentities: {
      '${identity.id}': {}
    }
  }
  properties: {
   sku:{
     name: 'WAF_v2'
     tier:'WAF_v2'
   }
   gatewayIPConfigurations: [
     {
       name: 'appGatewayIpConfig'
       properties:{
         subnet:{
           id: subnet.id
         }
       }
     }
   ]
   sslCertificates:[
     {
       name: 'publicsslcertificate'
       properties:{
         keyVaultSecretId: '${kv.properties.vaultUri}secrets/${sslCertSecretName}'
       }
     }
   ]
   frontendIPConfigurations: [
     {
       name: 'frontendip'
       properties:{
         privateIPAllocationMethod: 'Dynamic'
         publicIPAddress:{
           id: pip.id
         }
       }
     }
   ]
   frontendPorts:[
     {
       name: 'frontendport'
       properties:{
         port: 443
       }
     }
   ]
   probes:[
     {
       name: 'appserviceprobe'
       properties: {
         protocol:'Https'
         path: '/health'
         interval: 30
         timeout: 30
         unhealthyThreshold: 3
         pickHostNameFromBackendHttpSettings: true         
       }
     }
   ]
   backendAddressPools: [
     {
       name: 'scm-contacts'
       properties:{
         backendAddresses:[
           {
             fqdn: contactsAppFqdn
           }
         ]
       }
     }
   ]
   backendHttpSettingsCollection:[
     {
       name: 'appservicesettings'
       properties: {
         port: 443
         protocol: 'Https'
         cookieBasedAffinity: 'Disabled'
         pickHostNameFromBackendAddress: true
         requestTimeout: 20
         probe:{
           id: '${resourceId('Microsoft.Network/applicationGateways', appGatewayName)}/probes/appserviceprobe'
         }
       }
     }
   ]
   httpListeners:[
     {
       name: 'publiclistener'
       properties:{
         frontendIPConfiguration: {
          id: '${resourceId('Microsoft.Network/applicationGateways', appGatewayName)}/frontendIPConfigurations/frontendip'
         }
         frontendPort:{
           id : '${resourceId('Microsoft.Network/applicationGateways', appGatewayName)}/frontendPorts/frontendport'
         }
         protocol: 'Https'
         sslCertificate:{
           id: '${resourceId('Microsoft.Network/applicationGateways', appGatewayName)}/sslCertificates/publicsslcertificate'
         }
       }
     }
   ]
   requestRoutingRules:[
     {
       name: 'servicerouting'
       properties:{
         ruleType: 'PathBasedRouting'
         httpListener: {
          id: '${resourceId('Microsoft.Network/applicationGateways', appGatewayName)}/httpListeners/publiclistener'
         }
         urlPathMap:{
          id: '${resourceId('Microsoft.Network/applicationGateways', appGatewayName)}/urlPathMaps/servicepathmaps'
         }
       }
     }
   ]
   urlPathMaps:[
     {
       name: 'servicepathmaps'
       properties:{
         defaultBackendAddressPool:{
           id: '${resourceId('Microsoft.Network/applicationGateways', appGatewayName)}/backendAddressPools/scm-contacts'
         }
         defaultBackendHttpSettings: {
           id: '${resourceId('Microsoft.Network/applicationGateways', appGatewayName)}/backendHttpSettingsCollection/appservicesettings'
         }
         pathRules:[
           {
             name: 'scm-contacts'
             properties:{
               paths:[
                 '/api/contacts/*'
               ]
               backendAddressPool:{
                id: '${resourceId('Microsoft.Network/applicationGateways', appGatewayName)}/backendAddressPools/scm-contacts'
               }
               backendHttpSettings:{
                id: '${resourceId('Microsoft.Network/applicationGateways', appGatewayName)}/backendHttpSettingsCollection/appservicesettings'
               }
             }
           }
         ]
       }
     }
   ]
   enableHttp2: false
   autoscaleConfiguration:{
     minCapacity: 0
     maxCapacity: 3
   }
  }
}
