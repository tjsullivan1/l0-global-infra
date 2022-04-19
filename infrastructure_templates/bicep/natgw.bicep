@description('Name of the NAT gateway resource')
param natGatewayName string = 'myNATgateway'

@description('dns of the public ip address, leave blank for no dns')
param publicIpDns string = 'gw-${uniqueString(resourceGroup().id)}'

@description('Location of resources')
param location string = resourceGroup().location

var publicIpName = '${natGatewayName}-ip'
var publicIpAddresses = [
  {
    id: publicIp.id
  }
]

resource publicIp 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: publicIpName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    dnsSettings: {
      domainNameLabel: publicIpDns
    }
  }
}

resource natGateway 'Microsoft.Network/natGateways@2020-06-01' = {
  name: natGatewayName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    idleTimeoutInMinutes: 4
    publicIpAddresses: !empty(publicIpDns) ? publicIpAddresses : null
  }
}

output gw_id string = natGateway.id
