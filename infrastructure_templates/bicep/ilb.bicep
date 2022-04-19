@description('Location for all resources.')
param location string = resourceGroup().location

@description('The resource ID for the subnet where the NIC will reside.')
param subnetId string

param loadBalancerName string = 'ilb'

param tcp_port int = 80
param static_ip string = ''

resource lb 'Microsoft.Network/loadBalancers@2020-06-01' = {
  name: loadBalancerName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    frontendIPConfigurations: [
      {
        properties: {
          subnet: {
            id: subnetId
          }
          privateIPAddress:  (!empty(static_ip)) ?  static_ip : json('null')
          privateIPAllocationMethod: 'Dynamic'
        }
        name: 'LoadBalancerFrontend'
      }
    ]
    backendAddressPools: [
      {
        name: 'BackendPool1'
      }
    ]
    loadBalancingRules: [
      {
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations', loadBalancerName, 'LoadBalancerFrontend')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerName, 'BackendPool1')
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', loadBalancerName, 'lbprobe')
          }
          protocol: 'Tcp'
          frontendPort: tcp_port
          backendPort: tcp_port
          idleTimeoutInMinutes: 15
          enableTcpReset: true
          disableOutboundSnat: false
          loadDistribution: 'Default'
          enableFloatingIP: false
        }
        name: 'lbrule'
      }
    ]
    probes: [
      {
        properties: {
          protocol: 'Tcp'
          port: tcp_port
          intervalInSeconds: 15
          numberOfProbes: 2
        }
        name: 'lbprobe'
      }
    ]
  }
}

output ilb_backend_pool_id string = resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerName, 'BackendPool1')
output ilb_frontend_pool_id string = resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations', loadBalancerName, 'LoadBalancerFrontend')
