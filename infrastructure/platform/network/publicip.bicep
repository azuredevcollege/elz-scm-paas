@minLength(3)
@maxLength(8)
@description('Name of environment')
param env string = 'dev'

var pipName = 'pip-scm-${env}-${uniqueString(resourceGroup().id)}'
var domainLabelName = 'scm-elz-${env}'
var location = resourceGroup().location


resource pip 'Microsoft.Network/publicIPAddresses@2020-11-01' = {
  name: pipName
  location: location
  sku: {
    name:'Standard'
    tier:'Regional'
  }
  properties:{
    publicIPAllocationMethod:'Static'
    dnsSettings:{
      domainNameLabel: domainLabelName
    }
  }
}
