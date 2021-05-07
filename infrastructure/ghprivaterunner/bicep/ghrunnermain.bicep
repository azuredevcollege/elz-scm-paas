
targetScope = 'subscription'

@description('Name of landing zone resource group')
param landingZoneResourceGroupName string

@minLength(3)
@maxLength(8)
@description('Name of environment')
param env string = 'dev'

@description('Name of GitHub runner image to use')
param ghRunnerImageName string

@description('Name of resource group where GitHub runner image is stored')
param ghRunnerImageResourceGroupName string

@description('Admin user name for GitHub runner VM')
param adminUserName string

@secure()
@description('GitHub token to register runner')
param adminUserPwd string

@description('GitHub repository url')
param gitHubRepoUrl string

@secure()
param gitHubToken string
param gitHubRunnerName string
var rgRunnerName = 'rg-scm-ghrunner-${env}'

resource rg 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: rgRunnerName
  location: deployment().location
}

module ghrunner 'ghrunner.bicep' = {
  name: 'deployGHRunnerVM'
  scope: resourceGroup(rg.name)
  params: {
    adminUserName: adminUserName
    adminUserPwd: adminUserPwd
    env: env
    ghRunnerImageName: ghRunnerImageName
    ghRunnerImageResourceGroupName: ghRunnerImageResourceGroupName
    gitHubRepoUrl: gitHubRepoUrl
    gitHubToken: gitHubToken
    landingZoneResourceGroupName: landingZoneResourceGroupName
    gitHubRunnerName: gitHubRunnerName
  }
}
