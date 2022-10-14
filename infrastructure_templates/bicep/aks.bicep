@description('The name of the Managed Cluster resource.')
param resourceName string

@description('The location of AKS resource.')
param location string = resourceGroup().location

@description('Optional DNS prefix to use with hosted Kubernetes API server FQDN.')
param dnsPrefix string

@description('The name for the Azure Container Registry that we are going to connect Kubernetes to.')
param acrName string

@description('Disk size (in GiB) to provision for each of the agent pool nodes. This value ranges from 0 to 1023. Specifying 0 will apply the default disk size for that agentVMSize.')
@minValue(0)
@maxValue(1023)
param osDiskSizeGB int = 0

@minValue(1)
param node_default_count int = 3

@minValue(1)
param node_minimum_count int = 1

param node_maximum_count int = 5

param node_sku string = 'Standard_DS2_v2'

param max_pods int = 110

@description('The resource ID for the log analytics workspace')
param logAnalyticsWorkspaceId string = ''

@description('The version of Kubernetes.')
param kubernetesVersion string = '1.24.6'
@description('Network plugin used for building Kubernetes network.')
@allowed([
  'azure'
  'kubenet'
])
param networkPlugin string

@description('Boolean flag to turn on and off of RBAC.')
param enableRBAC bool = true

@description('Enable private network access to the Kubernetes cluster.')
param enablePrivateCluster bool = false

@description('Boolean flag to turn on and off http application routing.')
param enableHttpApplicationRouting bool = true

@description('Boolean flag to turn on and off Azure Policy addon.')
param enableAzurePolicy bool = false

@description('Boolean flag to turn on and off secret store CSI driver.')
param enableSecretStoreCSIDriver bool = false

@description('Boolean flag to turn on and off omsagent addon.')
param enableOmsAgent bool = false

@description('Resource ID of virtual network subnet used for nodes and/or pods IP assignment.')
param vnetSubnetID string

@description('A CIDR notation IP range from which to assign service cluster IPs.')
param serviceCidr string

@description('Containers DNS server IP address.')
param dnsServiceIP string

@description('A CIDR notation IP for Docker bridge.')
param dockerBridgeCidr string

param availability_zones array = [
  '1'
  '2'
  '3'
]

param userIdentity string = ''
param miPrincipalId string = ''
param authorizedIPRanges array = []

@description('Which network policy are you applying to the network.')
@allowed([
  'calico'
  'azure'
  ''
])
param networkPolicy string = ''

var isUserIdentityNull = empty(userIdentity)
// var calculatedUserIdentity = '${userIdentity}' : {}
var privateDNSZone = '${dnsPrefix}.privatelink.${location}.azmk8s.io'
var identity = isUserIdentityNull ? {
  type: 'SystemAssigned'
} : { 
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userIdentity}' : {}
    } 
}

resource private_dns 'Microsoft.Network/privateDnsZones@2020-06-01' = if (enablePrivateCluster) {
  name: privateDNSZone
  location: 'global'
}

resource role_assignment_private_dns_contributor 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = if (enablePrivateCluster) {
  name: guid(subscription().id, 'principalIdtjsPrivDns', miPrincipalId)
  properties: {
    principalId: miPrincipalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'b12aa53e-6015-4669-85d0-8515ebb3ae7f')
  }
}

resource role_assignment_net_contributor 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = if (enablePrivateCluster) {
  name: guid(subscription().id, 'principalIdtjsNetCont', miPrincipalId)
  properties: {
    principalId: miPrincipalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '4d97b98b-1d4f-4787-a291-c67834d212e7')
  }
}

resource acr 'Microsoft.ContainerRegistry/registries@2021-12-01-preview' existing = {
  name: acrName
}

resource acrPullRole 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  name: '7f951dda-4ed3-4680-a7ca-43fe172d538d'
  scope: subscription()
}

resource aks_mc 'Microsoft.ContainerService/managedClusters@2021-07-01' = {
  location: location
  name: resourceName
  properties: {
    
    kubernetesVersion: kubernetesVersion
    enableRBAC: enableRBAC
    dnsPrefix: dnsPrefix
    agentPoolProfiles: [
      {
        name: 'agentpool'
        osDiskSizeGB: osDiskSizeGB
        count: node_default_count
        enableAutoScaling: true
        minCount: node_minimum_count
        maxCount: node_maximum_count
        vmSize: node_sku
        osType: 'Linux'
        type: 'VirtualMachineScaleSets'
        mode: 'System'
        maxPods: max_pods
        availabilityZones: availability_zones
        enableNodePublicIP: false
        tags: {}
        vnetSubnetID: vnetSubnetID
      }
    ]
    networkProfile: {
      loadBalancerSku: 'standard'
      networkPlugin: networkPlugin
      serviceCidr: serviceCidr
      networkPolicy: networkPolicy
      dnsServiceIP: dnsServiceIP
      dockerBridgeCidr: dockerBridgeCidr
    }
    apiServerAccessProfile: {
      enablePrivateCluster: enablePrivateCluster
      privateDNSZone: enablePrivateCluster ? private_dns.id : null
      authorizedIPRanges: authorizedIPRanges
    }
    addonProfiles: {
      httpApplicationRouting: {
        enabled: enableHttpApplicationRouting
      }
      azurepolicy: {
        enabled: enableAzurePolicy
      }
      azureKeyvaultSecretsProvider: {
        enabled: enableSecretStoreCSIDriver
      }
      omsAgent: {
        enabled: enableOmsAgent
        config:  enableOmsAgent ? {
          logAnalyticsWorkspaceResourceID: logAnalyticsWorkspaceId
        } : null
      }
    }
  }
  tags: {}
  sku: {
    name: 'Basic'
    tier: 'Paid'
  }
  identity: identity
  dependsOn: []
}

resource acrKubeletAcrPullRole_roleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  scope: acr
  name: guid(aks_mc.id, acrPullRole.id)
  properties: {
    roleDefinitionId: acrPullRole.id
    description: 'Allows AKS to pull container images from this ACR instance.'
    principalId: aks_mc.properties.identityProfile.kubeletidentity.objectId
    principalType: 'ServicePrincipal'
  }
  dependsOn: []
}


output controlPlaneFQDN string = aks_mc.properties.fqdn
output controlPlanePrivateFQDN string = enablePrivateCluster ? aks_mc.properties.privateFQDN : ''
output aksResourceId string = aks_mc.id
output kvIdentityClientId string = aks_mc.properties.addonProfiles.azureKeyvaultSecretsProvider.identity.clientId
