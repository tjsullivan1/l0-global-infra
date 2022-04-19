param privatelinkServiceName string = 'myPLS'
param load_balancer_subnet_id string
param load_balancer_frontend_id string

@description('Location for all resources.')
param location string = resourceGroup().location

resource privatelinkService 'Microsoft.Network/privateLinkServices@2021-05-01' = {
  name: privatelinkServiceName
  location: location
  properties: {
    enableProxyProtocol: false
    loadBalancerFrontendIpConfigurations: [
      {
        id: load_balancer_frontend_id
      }
    ]
    ipConfigurations: [
      {
        name: 'snet-provider-default-1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          privateIPAddressVersion: 'IPv4'
          subnet: {
            id: load_balancer_subnet_id
          }
          primary: false
        }
      }
    ]
  }
}

output pls_id string = privatelinkService.id
