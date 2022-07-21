@description('The name of the Managed Cluster resource.')
param resourceName string

@description('The location of AKS resource.')
param location string = resourceGroup().location

@description('The tenant ID of the Azure Active Directory.')
param tenantId string = subscription().tenantId

@description('Whether we want Standard or Premium SKU.')
@allowed(['standard', 'premium'])
param skuName string = 'standard'

param enableRBAC bool = false
param enableSoftDelete bool = true
param enableForDeployment bool = true
param enableForTemplateDeployment bool = true
param enableForDiskEncryption bool = true
param enablePurgeProtection bool = true

@description('The object ID for someone who will have full permissions. Ideally, may want this to become a full access policy object.')
param ownerObjectId string = '36a895ff-8e24-4b03-bf63-574a9b24ad8f'

param tags object = {}

resource keyvault 'Microsoft.KeyVault/vaults@2021-10-01' = {
  name: resourceName
  location: location
  tags: tags
  properties:{
    accessPolicies: [
      {
        objectId: ownerObjectId
        permissions: {
          certificates: [
            'all'
          ]
          keys: [
            'all'
          ]
          secrets: [
            'all'
          ]
          storage: [
            'all'
          ]
        }
        tenantId: tenantId
      }
    ]
    enabledForDeployment: enableForDeployment
    enabledForDiskEncryption: enableForDiskEncryption
    enabledForTemplateDeployment: enableForTemplateDeployment
    enablePurgeProtection: enablePurgeProtection
    enableRbacAuthorization: enableRBAC
    enableSoftDelete: enableSoftDelete
    sku: {
      family: 'A'
      name: skuName
    }
    tenantId: tenantId
  }
}
