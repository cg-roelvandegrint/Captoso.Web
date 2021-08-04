param location string = resourceGroup().location
param appServicePlanName string
param appServiceName string

resource appService 'Microsoft.Web/sites@2021-01-15' = {
  name: appServiceName
  location: location
  properties: {
    serverFarmId: resourceId('Microsoft.Web/serverFarms', appServicePlanName)
  }
}
