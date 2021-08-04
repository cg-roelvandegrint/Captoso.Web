param location string = resourceGroup().location
param appServicePlanName string
param appServiceName string

resource appServicePlan 'Microsoft.Web/serverfarms@2021-01-15' = {
  name: appServicePlanName
  location: location
  sku: {
    name: 'B1'
  }
}

resource appService 'Microsoft.Web/sites@2021-01-15' = {
  name: appServiceName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
  }
}
