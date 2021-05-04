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
param planWindowsSku string = 'B1'

@description('The SKU of Linux based App Service Plan, default is B1')
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
param planLinuxSku string = 'B1'

@description('Sql server\'s admin login name')
param sqlUserName string

@secure()
@description('Sql server\'s admin password')
param sqlUserPwd string

@description('Name of SSL Certificate Secret in KeyVault')
param sslCertSecretName string

module gateway 'gateway/appgateway.bicep' = {
  name: 'deployGateway'
  params:{
    env: env
    sslCertSecretName: sslCertSecretName
  }
}

module common 'common/commonmain.bicep' = {
  name: 'deployCommon'
  params: {
    env: env
    planLinuxSku: planLinuxSku
    planWindowsSku: planWindowsSku
  }
}

module contacts 'contacts/contactsmain.bicep' = {
  name: 'deployContacts'
  params: {
    env: env
    sqlUserName: sqlUserName
    sqlUserPwd: sqlUserPwd
  }
  dependsOn: [
    common
  ]
}
