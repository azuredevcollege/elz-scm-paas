@description('Name of landing zone resource group')
param landingZoneResourceGroupName string

@minLength(3)
@maxLength(8)
@description('Name of environment')
param env string = 'dev'

@description('Sql server\'s admin login name')
param sqlUserName string

@secure()
@description('Sql server\'s admin password')
param sqlUserPwd string

var resourceTag = {
  Environment: env
  Application: 'SCM'
  Component: 'SCM-Contacts'
}

module database 'databases.bicep' = {
  name: 'deployDatabaseContacts'
  params: {
    env: env
    resourceTag: resourceTag
    sqlUserName: sqlUserName
    sqlUserPwd: sqlUserPwd
    landingZoneResourceGroupName: landingZoneResourceGroupName
  }
}

module webapp 'webapp.bicep' = {
  name: 'deployWebAppContacts'
  params: {
    env: env
    resourceTag: resourceTag
    sqlConnectionString: database.outputs.connectionString
    landingZoneResourceGroupName: landingZoneResourceGroupName
  }
}

output contactsApiWebAppName string = webapp.outputs.contactsApiWebAppName
