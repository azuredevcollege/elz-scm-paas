@description('Name of landing zone resource group')
param landingZoneResourceGroupName string

@minLength(3)
@maxLength(8)
@description('Name of environment')
param env string = 'dev'

param ghRunnerImageName string
param ghRunnerImageResourceGroupName string
param adminUserName string
@secure()
param adminUserPwd string
param gitHubRepoUrl string
@secure()
param gitHubToken string
param gitHubRunnerName string

var rgRunner = 'rg-scm-ghrunner-dev'
var vmName = 'vm-ghrunner-${env}-${uniqueString(resourceGroup().id)}'
var nicName = 'nic-vm-ghrunner-${env}-${uniqueString(resourceGroup().id)}'
var vnetName = 'vnet-scm-${env}-${uniqueString(rgLandingZone.id)}'
var subnetName = 'snet-jumpbox'
var location = resourceGroup().location

var installGitHubRunnerCommand = 'bash configure.sh -r "${gitHubRepoUrl}" -t "${gitHubToken}" -u "${adminUserName}" -n "${gitHubRunnerName}"'

resource rgLandingZone 'Microsoft.Resources/resourceGroups@2021-01-01' existing = {
  name: landingZoneResourceGroupName
  scope: subscription()
}

resource vnet 'Microsoft.Network/virtualNetworks@2020-11-01' existing = {
  name: vnetName
  scope: resourceGroup(landingZoneResourceGroupName)
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' existing = {
  name: '${vnet.name}/${subnetName}'
  scope: resourceGroup(landingZoneResourceGroupName)
}

resource rgImage 'Microsoft.Resources/resourceGroups@2021-01-01' existing = {
  name: ghRunnerImageResourceGroupName
  scope: subscription()
}

resource image 'Microsoft.Compute/images@2020-12-01' existing = {
  name: ghRunnerImageName
  scope: resourceGroup(ghRunnerImageResourceGroupName)
}

resource nic 'Microsoft.Network/networkInterfaces@2020-11-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAddress: '10.0.0.10'
          privateIPAllocationMethod: 'Dynamic'
          subnet:{
            id: subnet.id
          }
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: vmName
  location: location
  zones: [
    '1'
  ]
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D2s_v3'
    }
    storageProfile: {
      imageReference: {
        id: image.id
      }
      osDisk: {
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
        diskSizeGB: 30
      }
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUserName
      adminPassword: adminUserPwd
      linuxConfiguration: {
        disablePasswordAuthentication: false
        provisionVMAgent: true
        patchSettings: {
          patchMode: 'ImageDefault'
        }
      }
      allowExtensionOperations: true
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }

  resource extension 'extensions@2020-12-01' = {
    name: 'CustomScript'
    location: location
    properties:{
      autoUpgradeMinorVersion: true
      publisher: 'Microsoft.Azure.Extensions'
      type: 'CustomScript'
      typeHandlerVersion: '2.0'
      settings: {
        fileUris: [
          'https://anmockutils.blob.core.windows.net/deployment/configure.sh'
        ]
      }
      protectedSettings: {
        commandToExecute: installGitHubRunnerCommand
      }
    }
  }
}


