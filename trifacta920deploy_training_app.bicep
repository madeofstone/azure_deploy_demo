// Deployment Name is used to prefix all resources
param deploymentName string
param deploymentString  string = substring(guid(uniqueString(resourceGroup().id)), 0, 2)

// Parameters - If no default, then param is required.
@description('This is the object ID for the service princpal.')
@secure()
param servicePrincipalObjectId string
param location string = resourceGroup().location
param networkSecurityGroupName string = '${deploymentName}-${deploymentString}-nsg'
param subnetName string = 'default'
param virtualNetworkName string = '${deploymentName}-${deploymentString}-net'
param publicIpAddressName string = '${deploymentName}-${deploymentString}-pip'
param publicIpAddressType string = 'static'
param publicIpAddressSku string = 'Basic'
param virtualMachineName string = '${deploymentName}-${deploymentString}-vm'
param virtualMachineSize string = 'Standard_E8s_v3'
param adminUsername string
@secure()
param adminPassword string
@secure()
param appId string
@secure()
param appSecret string
param trifactaStorageAccountName string = 'trifacta${deploymentString}storage'
param databricksMRGID string = '${subscription().id}/resourceGroups/${deploymentName}-${deploymentString}-dbrg'
param containerName string = 'trifacta'
param keyVaultName string = '${deploymentName}-${deploymentString}-kv'

//Variables
var networkInterfaceName = '${deploymentName}-${deploymentString}-int'
var vnetId = resourceId(resourceGroup().name, 'Microsoft.Network/virtualNetworks', virtualNetworkName)
var subnetRef = '${vnetId}/subnets/${subnetName}'
var storageBlobContributor = '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/ba92f5b4-2d11-453d-a403-e96b0029c9fe'
var databricksWorkspaceName_var = '${deploymentName}-${deploymentString}-db'
var storageAccountRoleName_var = guid(uniqueString(trifactaStorageAccountName))

// Resources

// Network Interface
resource networkInterface 'Microsoft.Network/networkInterfaces@2021-08-01' = {
  name: networkInterfaceName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig2'
        properties: {
          subnet: {
            id: subnetRef
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIpAddressName_resource.id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: networkSecurityGroupName_resource.id
    }
  }
  dependsOn: [
    virtualNetworkName_resource
  ]
}

// Network Security Group
resource networkSecurityGroupName_resource 'Microsoft.Network/networkSecurityGroups@2019-02-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: [
      {
        name: 'SSH'
        properties: {
          priority: 300
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
      {
        name: 'Trifacta_Service'
        properties: {
          priority: 200
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRanges: [
            '3005'
            '80'
            '443'
          ]
        }
      }
    ]
  }
}

// Virtual Network for Trifacta node
resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2019-04-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.1.2.0/24'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.1.2.0/24'
          serviceEndpoints: [
            {
              service: 'Microsoft.KeyVault'
            }
          ]
        }
      }
    ]
  }
}

//Public IP address
resource publicIpAddressName_resource 'Microsoft.Network/publicIPAddresses@2021-08-01' = {
  name: publicIpAddressName
  location: location
  properties: {
    publicIPAllocationMethod: publicIpAddressType
    dnsSettings: {
      domainNameLabel: toLower('${deploymentName}${deploymentString}')
    }
  }
  sku: {
    name: publicIpAddressSku
  }
}

// Virtual Machine
resource virtualMachine 'Microsoft.Compute/virtualMachines@2021-11-01' = {
  name: virtualMachineName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: virtualMachineSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
      imageReference: {
        publisher: 'RedHat'
        offer: 'RHEL'
        sku: '8.1'
        version: 'latest'
    }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
        }
      ]
    }
    osProfile: {
      computerName: virtualMachineName
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              keyData: 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDGpkNZQp5eylXcrpUZKyW7alHzP0JKWrjmdmk0kS0NuFlKMBxH6Lxkw/M2rs14LWd8ZTOzCZvUDtLUcGs/Vql7MW52aT3P/yXifrjsjTYhZ4C4sXIZMgYrzkLet+w+4M4quPt1io/RBNDdPUoNBT3NAlEwt3MA6Am8ooUnRiz2JjdvLAci5HiNoN2D0LtPXb4xmbiNH4loh5aS3dttCXEUvznEKqxLwIcOaEmVfdyDwxFNKMHhAzFcp1xbzzATyAhry18R/jCB+BXqTdW63gZhCHlmZjV6t9oC909W8ZTkio8leJgGA1e4hCaB3emvGYiX1J8K6MFtu+JXDQWFHh/Sz6cNnrVtS+bICauvnQXNmghv1sAAca6ZOqckRvQU1eInr4Nba2ezzDJOWXA6+IHLd/Y67qsl9MNKNI3eJfVI2nihGmctMBtF9ZcrKBjxijzdBukYdYbPDEVIqXB8tfbUh4pMYnJ4pONDALPI2PuCStxrInRfA7Yil/TROPmBccc= travis.stone@AMB-4M49LM'
              path: '/home/${adminUsername}/.ssh/authorized_keys'
            }
          ]
        }
    }
    }
  }
}

// Storage Account (ADLSgen2)
resource trifactaStorageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: trifactaStorageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    encryption: {
      keySource: 'Microsoft.Storage'
      services: {
        blob: {
          enabled: true
        }
        file: {
          enabled: true
        }
      }
    }
    isHnsEnabled: true
    supportsHttpsTrafficOnly: true
  }
}

//Storage container
resource blobServiceContainerName 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-09-01' = {
  name: '${trifactaStorageAccount.name}/default/${containerName}'
}

// Storage Blob Data Contributor role for trifacta registered app SP
resource storageAccountRoleName 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: storageAccountRoleName_var
  scope: trifactaStorageAccount
  properties: {
    roleDefinitionId: storageBlobContributor
    principalId: servicePrincipalObjectId
    principalType: 'ServicePrincipal'
  }
}

// Key Vault
resource keyVaultName_resource 'Microsoft.KeyVault/vaults@2021-10-01' = {
  name: keyVaultName
  location: location
  properties: {
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: true
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: servicePrincipalObjectId
        permissions: {
          keys: [
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
          certificates: [
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
    tenantId: subscription().tenantId
    sku: {
      name: 'standard'
      family: 'A'
    }
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
      ipRules: []
      virtualNetworkRules: [
        {
          id: '${virtualNetworkName_resource.id}/subnets/default'
          ignoreMissingVnetServiceEndpoint: false
        }
      ]
    }
  }
}

// Databricks Workspace
resource databricksWorkspaceName 'Microsoft.Databricks/workspaces@2018-04-01' = {
  name: databricksWorkspaceName_var
  location: location
  properties: {
    managedResourceGroupId: databricksMRGID
  }
}

output adminUsername string = adminUsername
output trifactaInstanceName string = virtualMachineName
output trifactaURL string = publicIpAddressName_resource.properties.dnsSettings.fqdn
output keyvaultURI string = keyVaultName_resource.properties.vaultUri
output directoryid string = keyVaultName_resource.properties.tenantId
output databricksURL string = databricksWorkspaceName.properties.workspaceUrl
output storagecontainer string = containerName
output storageaccount string = trifactaStorageAccountName
output vmid string = virtualMachine.identity.principalId
