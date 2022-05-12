param zoneName string
param isPublic bool = false

resource private_dns 'Microsoft.Network/privateDnsZones@2020-06-01' = if (!(isPublic)) {
  name: zoneName
  location: 'global'
}

resource public_dns 'Microsoft.Network/dnsZones@2018-05-01' = if (isPublic) {
  name: zoneName
  location: 'global'
}

output zone_id string = isPublic ? public_dns.id : private_dns.id
