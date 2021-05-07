targetScope = 'subscription'

@description('Name of landing zone resource group')
param landingZoneResourceGroupName string

@description('Name of resource group where app is deployed to')
param resourceGroupName string

@minLength(3)
@maxLength(8)
@description('Name of environment')
param env string = 'dev'

@description('The SKU of Windows based App Service Plan, default is B1')
@allowed([
  'D1' 
  'F1' 
  'B1' 
  'B2' 
  'B3' 
  'S1' 
  'S2' 
  'S3' 
  'P1' 
  'P2' 
  'P3' 
  'P1V2' 
  'P2V2' 
  'P3V2'
])
param planWindowsSku string = 'P2V2'

@description('Sql server\'s admin login name')
param sqlUserName string

@secure()
@description('Sql server\'s admin password')
param sqlUserPwd string

@description('Name of SSL Certificate Secret in KeyVault')
param sslCertSecretName string

resource rgapp 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: resourceGroupName
  location: deployment().location
}

module common 'common/commonmain.bicep' = {
  name: 'deployCommon'
  scope: resourceGroup(rgapp.name)
  params: {
    env: env
    planWindowsSku: planWindowsSku
  }
}

module privateDNSZones 'dnszones/dnszonesmain.bicep' = {
  name: 'deployPrivateDNSZones'
  scope: resourceGroup(rgapp.name)
  params: {
    env:env
    landingZoneResourceGroupName: landingZoneResourceGroupName
  }
}

module contacts 'contacts/contactsmain.bicep' = {
  name: 'deployContacts'
  scope: resourceGroup(rgapp.name)
  params: {
    env: env
    sqlUserName: sqlUserName
    sqlUserPwd: sqlUserPwd
    landingZoneResourceGroupName: landingZoneResourceGroupName
  }
  dependsOn: [
    common
    privateDNSZones
  ]
}

module gateway 'gateway/appgateway.bicep' = {
  name: 'deployGateway'
  scope: resourceGroup(rgapp.name)
  params:{
    env: env
    sslCertSecretName: sslCertSecretName
    landingZoneResourceGroupName: landingZoneResourceGroupName
  }

  dependsOn: [
    contacts
  ]
}
