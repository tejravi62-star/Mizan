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
]

param deployJumpbox = true
param jumpboxSshPublicKey = readEnvironmentVariable('MIZAN_SSH_PUBKEY', '')
param aiPublicNetworkAccess = 'Disabled'
