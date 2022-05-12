
param vnetName string
param remoteVnetName string
param remoteVnetId string
param allowVirtualNetworkAccess bool = true
param allowForwardedTraffic bool = false
param allowGatewayTransit bool = false
param useRemoteGateways bool = false

resource peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-02-01' = {
  name: '${vnetName}/${vnetName}-${remoteVnetName}'
  properties: {
    allowVirtualNetworkAccess: allowVirtualNetworkAccess
    allowForwardedTraffic: allowForwardedTraffic
    allowGatewayTransit: allowGatewayTransit
    useRemoteGateways: useRemoteGateways
    remoteVirtualNetwork: {
      id: remoteVnetId
    }
  }
}
