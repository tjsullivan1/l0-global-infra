@description('Resource ID of trhe vnet in which Azure Bastion should be deployed')
param subnet_id string

@description('Name of Azure Bastion resource')
param bastionHostName string

@description('Azure region for Bastion and virtual network')
param location string = resourceGroup().location

var publicIpAddressName = 'pip-${bastionHostName}'

resource publicIp 'Microsoft.Network/publicIpAddresses@2020-05-01' = {
  name: publicIpAddressName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource bastionHost 'Microsoft.Network/bastionHosts@2021-05-01' = {
  name: bastionHostName
  location: location
  sku: {
     name: 'Standard'
  }
  properties: {
    enableTunneling: true
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          subnet: {
            id: subnet_id
          }
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
  }
}
