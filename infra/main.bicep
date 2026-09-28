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

@description('VNet address space for this workload. Must be a /22 and must not overlap other networks.')
param vnetAddressPrefix string

@description('Model deployments for this workload (from the domain pack)')
param modelDeployments array

@description('Foundry public network access. Disabled once private endpoint is verified.')
@allowed([ 'Enabled', 'Disabled' ])
param aiPublicNetworkAccess string = 'Enabled'

var baseTags = {
  project: workload
  env: env
  owner: owner
}
var coreTags = union(baseTags, { costmode: 'core' })
var tempTags = union(baseTags, { costmode: 'temp' })

resource rgCore 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'rg-${workload}-${env}-${regionCode}'
  location: location
  tags: coreTags
}

resource rgTemp 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'rg-${workload}-temp-${regionCode}'
  location: location
  tags: tempTags
}

module network 'modules/network.bicep' = {
  name: 'network-${workload}-${env}'
  scope: rgCore
  params: {
    workload: workload
    env: env
    location: location
    regionCode: regionCode
    addressPrefix: vnetAddressPrefix
    tags: coreTags
  }
}

module ai 'modules/ai.bicep' = {
  name: 'ai-${workload}-${env}'
  scope: rgCore
  params: {
    workload: workload
    env: env
    location: location
    regionCode: regionCode
    tags: coreTags
    modelDeployments: modelDeployments
    publicNetworkAccess: aiPublicNetworkAccess
  }
}

output coreResourceGroup string = rgCore.name
output tempResourceGroup string = rgTemp.name
output vnetName string = network.outputs.vnetName
output subnetIds object = network.outputs.subnetIds
output aiName string = ai.outputs.aifName
output aiEndpoint string = ai.outputs.aifEndpoint
