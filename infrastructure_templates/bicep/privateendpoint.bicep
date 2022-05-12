param name string
param endpoint_subnet_id string
param location string = resourceGroup().location
param private_link_service_id string 
param group_ids array = []

resource private_endpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: name
  location: location
  properties: {
    subnet: {
      id: endpoint_subnet_id
    }
    privateLinkServiceConnections: [
      {
        name: name
        properties: {
          privateLinkServiceId: private_link_service_id
          groupIds: group_ids
        }
      }
    ]
  }
}


output pe_id string = private_endpoint.id

