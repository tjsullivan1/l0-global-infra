param virtualNetworkName string
param location string = resourceGroup().location

param addressPrefix string = '10.0.0.0/16'

param subnets array = [
  {
    name: 'sub1'
    subnetPrefix: '10.0.0.0/24'
  }
]

param tags object = {}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [for subnet in subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.subnetPrefix
      }
    }]
  }
  tags: tags
}

output vnet_id string = virtualNetwork.id
output subnets array = [for (subnet, i) in subnets: {
  subnet_name: virtualNetwork.properties.subnets[i].name 
  subnet_id: virtualNetwork.properties.subnets[i].id 
  subnet_prefix: virtualNetwork.properties.subnets[i].properties.addressPrefix
}]
