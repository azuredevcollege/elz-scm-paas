@minLength(3)
@maxLength(8)
@description('Name of environment')
param env string = 'dev'

param tenantId string
param securityPrincipalId string
param managedIdentityPrincipalId string

var keyVaultName = 'kv-scm-${env}-${uniqueString(resourceGroup().id)}'
var location = resourceGroup().location

resource kv 'Microsoft.KeyVault/vaults@2021-04-01-preview' = {
  name: keyVaultName
  location: location
  properties:{
    sku:{
      family: 'A'
      name: 'standard'
    }
    tenantId: tenantId
    accessPolicies:[
      {
        tenantId: tenantId
        objectId: securityPrincipalId
        permissions: {
          keys:[
            'get'
            'list'
            'update'
            'create'
            'import'
            'delete'
            'recover'
            'backup'
            'restore'
          ]
          secrets: [
            'get'
            'list'
            'set'
            'delete'
            'recover'
            'backup'
            'restore'
          ]
          certificates:[
            'get'
            'list'
            'update'
            'create'
            'import'
            'delete'
            'recover'
            'backup'
            'restore'
            'managecontacts'
            'manageissuers'
            'getissuers'
            'listissuers'
            'setissuers'
            'deleteissuers'
          ]
        }
      }
      {
        tenantId: tenantId
        objectId: managedIdentityPrincipalId
        permissions: {
          keys:[
            'get'
            'list'
            'update'
            'create'
            'import'
            'delete'
            'recover'
            'backup'
            'restore'
          ]
          secrets: [
            'get'
            'list'
            'set'
            'delete'
            'recover'
            'backup'
            'restore'
          ]
          certificates:[
            'get'
            'list'
            'update'
            'create'
            'import'
            'delete'
            'recover'
            'backup'
            'restore'
            'managecontacts'
            'manageissuers'
            'getissuers'
            'listissuers'
            'setissuers'
            'deleteissuers'
          ]
        }
      }
    ]
  }
}
