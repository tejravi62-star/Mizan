targetScope = 'subscription'

param location string = 'uaenorth'
param env string = 'dev'
param owner string = 'heart'

var baseTags = {
  project: 'mizan'
  env: env
  owner: owner
}

resource rgCore 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'rg-mizan-${env}-uaen'
  location: location
  tags: union(baseTags, { costmode: 'core' })
}

resource rgTemp 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'rg-mizan-temp-uaen'
  location: location
  tags: union(baseTags, { costmode: 'temp' })
}

output coreResourceGroup string = rgCore.name
output tempResourceGroup string = rgTemp.name
