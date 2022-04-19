// TODO: Add max length, etc. 
@description('Specifies a name for generating resource names.')
param vmName string

@description('Specifies the location for all resources.')
param location string = resourceGroup().location

@description('The resource ID for the subnet where the NIC will reside.')
param subnetId string

@description('Specifies a username for the Virtual Machine.')
param adminUsername string

@description('Specifies the SSH rsa public key file as a string. Use "ssh-keygen -t rsa -b 2048" to generate your SSH key pairs.')
@secure()
param adminPublicKey string // = loadTextContent('.ssh/id_rsa.pub') <- this would be my current suggestion, but this relies on relative paths...

@description('description')
param vmSize string = 'Standard_D2s_v3'

param customData string = '''
#!/bin/bash

#Run updates
sudo apt update
sudo apt upgrade -y

'''

// TODO: Update these allowed versions
@description('The Ubuntu version for the VM. This will pick a fully patched image of this given Ubuntu version.')
@allowed([
  '18.04-LTS'
  '18_04-lts-gen2'
  '20_04-lts-gen2'
])
param ubuntuOSVersion string = '18_04-lts-gen2'
param load_balancer_pool_id string = ''

// TODO: Add description and allowed values
param privateIPAllocationMethod string = 'Dynamic'

var networkInterfaceName_var = 'nic-${vmName}'


resource vm_nic 'Microsoft.Network/networkInterfaces@2020-05-01' = {
  name: networkInterfaceName_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: privateIPAllocationMethod
          subnet: {
            id: subnetId
          }
          loadBalancerBackendAddressPools: (!empty(load_balancer_pool_id)) ? [
            {
              id: load_balancer_pool_id
            }
          ] : json('null')
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2021-11-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      customData: base64(customData)
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: adminPublicKey
            }
          ]
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: ubuntuOSVersion
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vm_nic.id
        }
      ]
    }
  }
}

output adminUsername string = adminUsername
