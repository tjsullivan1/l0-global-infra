param name string = 'identity-aks-tjs-test'
param location string = resourceGroup().location

resource azidentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: name
  location: location
}

output identity_resource_id string = azidentity.id
output identity_principal_id string = azidentity.properties.principalId
