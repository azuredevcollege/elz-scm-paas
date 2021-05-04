@minLength(3)
@maxLength(8)
@description('Name of environment')
param env string = 'dev'

module pip 'publicip.bicep' = {
  name: 'deployAppGwPiP'
  params: {
    env: env
  }
}

module vnet 'vnet.bicep' = {
  name: 'deployVent'
  params: {
    env:env
  }
}
