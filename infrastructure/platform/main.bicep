@minLength(3)
@maxLength(8)
@description('Name of environment')
param env string = 'dev'

@description('The principal id of the Azure AD\'s security proncipal to use (user, app or group)')
param securityPrincipalId string

module network 'network/networkmain.bicep' = {
  name: 'deployNetwork'
  params:{
    env: env
  }
}

module security 'security/securitymain.bicep' = {
  name: 'deploySecurity'
  params:{
    env: env
    securityPrincipalId: securityPrincipalId
  }
}
