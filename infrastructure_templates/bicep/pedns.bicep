param privateDnsZoneName string 
param a_record string
param pe_ip string


resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: privateDnsZoneName
}

resource privateDnsZoneARecord 'Microsoft.Network/privateDnsZones/A@2020-01-01' = {
  parent: privateDnsZone
  name: a_record
  properties: {
    ttl: 3600
    aRecords: [
      {
        // first(first(privateEndpoint.properties.customDnsConfigs).ipAddresses)
        ipv4Address: pe_ip
      }
    ]
  }
}
