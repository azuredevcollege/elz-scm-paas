@minLength(3)
@maxLength(8)
@description('Name of environment')
param env string = 'dev'

@description('The principal id of the Azure AD\'s security proncipal to use (user, app or group)')
param securityPrincipalId string

module identity 'identity.bicep' = {
  name: 'deployIdentity'
  params: {
    env:env
  }
}

module keyvault 'keyvault.bicep' = {
  name: 'deployKeyVault'
  params:{
    env: env
    tenantId: identity.outputs.tenantId
    securityPrincipalId: securityPrincipalId
    managedIdentityPrincipalId: identity.outputs.principalId
  }
}
