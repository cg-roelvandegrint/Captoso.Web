param appServiceName string
param customHostname string

resource customDomain 'Microsoft.Web/sites/hostNameBindings@2021-01-15' = {
  name: '${appServiceName}/${customHostname}'
}
