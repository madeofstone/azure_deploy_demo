
## pre-deploy
## Enter 'app name'. Then create app registration with required API scpoes and store the app ID
appName=$''
appId=$(az ad app create --display-name $appName --required-resource-accesses manifest.json --query "appId" --output tsv)

## Create a 'secret' for app
secret=$(az ad app credential reset --id $appId --query "password" --output tsv)

## Create service principal 
appSP=$(az ad sp create --id $appId --query "objectId" --output tsv)

## Enter admin username and password for virtual machine login
##"The supplied password must be between 6-72 characters long and must satisfy at least 3 of password complexity 
##requirements from the following:\r\n1) Contains an uppercase character\r\n2) 
##Contains a lowercase character\r\n3) Contains a numeric digit\r\n4) Contains a special character\r\n5) 
##Control characters are not allowed"
adminUsername=$''
adminPassword=$''

## Enter additional parameters
trifactaStorageAccountName=$''
deploymentName=$''
## SETeam<#>-rg
resourceGroup=$''

## Deployment group what-if
az deployment group what-if \
--name $deploymentName --resource-group $resourceGroup \
--template-file trifacta920deploy_training_app.bicep \
--parameters servicePrincipalObjectId=$appSP \
adminUsername=$adminUsername adminPassword=$adminPassword \
appId=$appId appSecret=$secret trifactaStorageAccountName=$trifactaStorageAccountName \
deploymentName=$deploymentName

## Deployment group create
az deployment group create \
--name $deploymentName --resource-group $resourceGroup \
--template-file trifacta920deploy_training_app.bicep \
--parameters servicePrincipalObjectId=$appSP \
adminUsername=$adminUsername adminPassword=$adminPassword \
appId=$appId appSecret=$secret trifactaStorageAccountName=$trifactaStorageAccountName \
deploymentName=$deploymentName

##Cleanup
az ad sp delete --id $appSP
#az ad app delete --id $appId

