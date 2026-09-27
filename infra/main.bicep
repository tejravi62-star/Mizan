targetScope = 'subscription'

@description('Short name of the workload / domain pack, e.g. mizan, hrbot')
@minLength(2)
@maxLength(10)
param workload string

@description('Environment')
@allowed([ 'dev', 'test', 'prod' ])
param env string = 'dev'

@description('Azure region')
param location string = 'uaenorth'

@description('Short region code used in names')
param regionCode string = 'uaen'

@description('Owner tag value')
param owner string

var baseTags = {
  project: workload
  env: env
  owner: owner
}

resource rgCore 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'rg-${workload}-${env}-${regionCode}'
  location: location
  tags: union(baseTags, { costmode: 'core' })
}

resource rgTemp 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'rg-${workload}-temp-${regionCode}'
  location: location
  tags: union(baseTags, { costmode: 'temp' })
}

output coreResourceGroup string = rgCore.name
output tempResourceGroup string = rgTemp.name
