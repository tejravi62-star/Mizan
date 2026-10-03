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

@description('Foundry public network access. With no allowed IPs this is effectively private-only.')
@allowed([ 'Enabled', 'Disabled' ])
param aiPublicNetworkAccess string = 'Disabled'

@description('Developer public IP allowed to reach Foundry (dev only, read from environment). Empty = none.')
param devAllowedIp string = ''

@description('Deploy the admin jumpbox into the temp RG')
param deployJumpbox bool = false

@description('SSH public key for the jumpbox (read from environment, never committed)')
param jumpboxSshPublicKey string = ''

var baseTags = {
  project: workload
  env: env
  owner: owner
}
var coreTags = union(baseTags, { costmode: 'core' })
var tempTags = union(baseTags, { costmode: 'temp' })

var aiDnsZones = [
  'privatelink.cognitiveservices.azure.com'
  'privatelink.openai.azure.com'
  'privatelink.services.ai.azure.com'
]

var aiAllowedIps = empty(devAllowedIp) ? [] : [ devAllowedIp ]

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
    allowedIpRanges: aiAllowedIps
    roleAssignments: aiRoleAssignments
  }
}

module dnsAi 'modules/dns.bicep' = {
  name: 'dns-ai-${workload}-${env}'
  scope: rgCore
  params: {
    zoneNames: aiDnsZones
    vnetId: network.outputs.vnetId
    tags: coreTags
  }
}

module peAi 'modules/private-endpoint.bicep' = {
  name: 'pe-ai-${workload}-${env}'
  scope: rgCore
  params: {
    name: 'pe-${workload}-aif-${env}-${regionCode}'
    location: location
    subnetId: network.outputs.subnetIds.pe
    targetResourceId: ai.outputs.aifId
    groupId: 'account'
    dnsZoneIds: dnsAi.outputs.zoneIds
    tags: coreTags
  }
}

module jumpbox 'modules/jumpbox.bicep' = if (deployJumpbox) {
  name: 'jumpbox-${workload}-${env}'
  scope: rgTemp
  params: {
    workload: workload
    env: env
    location: location
    regionCode: regionCode
    tags: tempTags
    subnetId: network.outputs.subnetIds.jump
    sshPublicKey: jumpboxSshPublicKey
  }
}

output coreResourceGroup string = rgCore.name
output tempResourceGroup string = rgTemp.name
output vnetName string = network.outputs.vnetName
output subnetIds object = network.outputs.subnetIds
output aiName string = ai.outputs.aifName
output aiEndpoint string = ai.outputs.aifEndpoint
output aiPrivateEndpoint string = peAi.outputs.peName

module coreLock 'modules/lock.bicep' = {
  name: 'lock-${workload}-${env}'
  scope: rgCore
  params: {
    name: 'lock-${workload}-core'
  }
}

@description('Principals who can call Foundry models: [{ principalId, principalType }]. Users today, groups when the identity team provides them.')
param aiUsers array = []

var roleIdOpenAiUser = '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'

var aiRoleAssignments = map(aiAllPrincipals, p => {
  principalId: p.principalId
  principalType: p.principalType
  roleDefinitionId: roleIdOpenAiUser
})

module appIdentity 'modules/identity.bicep' = {
  name: 'identity-${workload}-${env}'
  scope: rgCore
  params: {
    workload: workload
    env: env
    location: location
    regionCode: regionCode
    tags: coreTags
  }
}

var aiAllPrincipals = concat(aiUsers, [
  {
    principalId: appIdentity.outputs.principalId
    principalType: 'ServicePrincipal'
  }
])

output appIdentityClientId string = appIdentity.outputs.clientId
