using '../main.bicep'

param workload = 'mizan'
param env = 'dev'
param location = 'uaenorth'
param regionCode = 'uaen'
param owner = 'heart'
param vnetAddressPrefix = '10.20.0.0/22'

param modelDeployments = [
  {
    name: 'chat-mini'
    model: 'gpt-5.4-mini'
    version: '2026-03-17'
    sku: 'GlobalStandard'
    capacity: 10
  }
  {
    name: 'embed-small'
    model: 'text-embedding-3-small'
    version: '1'
    sku: 'GlobalStandard'
    capacity: 30
  }
]

param aiPublicNetworkAccess = 'Enabled'
param devAllowedIp = readEnvironmentVariable('MIZAN_DEV_IP', '')

param deployJumpbox = true
param jumpboxSshPublicKey = readEnvironmentVariable('MIZAN_SSH_PUBKEY', '')

param aiUsers = [
  {
    principalId: 'ed9a2afa-9598-4158-a131-af58e7e38257'
    principalType: 'User'
  }
]
