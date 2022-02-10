resource_group=globetrotter-rg

# resource group
az group create --location francecentral --resource-group $resource_group

# acr
az acr create --name theglobetrottersliveregistry --resource-group $resource_group --sku Basic --admin-enabled true
az acr credential show --resource-group $resource_group --name theglobetrottersliveregistry
acr_pwd=$(az acr credential show --resource-group $resource_group --name theglobetrottersliveregistry --query passwords[0].value -o tsv)
docker login theglobetrottersliveregistry.azurecr.io --username theglobetrottersliveregistry --password $acr_pwd

# webap
az appservice plan create --name globetrotter-plan --resource-group $resource_group --is-linux --sku f1
az webapp create --resource-group $resource_group --plan globetrotter-plan --name theglobetrotterslive --deployment-container-image-name theglobetrottersliveregistry.azurecr.io/globetrotter-rails:latest
az webapp config appsettings set --resource-group $resource_group --name theglobetrotterslive --settings WEBSITES_PORT=3000
az webapp identity assign --resource-group $resource_group --name theglobetrotterslive --query principalId --output tsv
principalId=$(az webapp identity show --resource-group $resource_group --name theglobetrotterslive --query principalId --output tsv)
subscriptionId=$(az account show --query id --output tsv)
az role assignment create --assignee $principalId --scope /subscriptions/$subscriptionId/resourceGroups/$resource_group/providers/Microsoft.ContainerRegistry/registries/theglobetrottersliveregistry --role "AcrPull"
az webapp config container set --name theglobetrotterslive --resource-group $resource_group --docker-custom-image-name theglobetrottersliveregistry.azurecr.io/globetrotter-rails:latest --docker-registry-server-url https://theglobetrottersliveregistry.azurecr.io

az webapp config appsettings set --resource-group $resource_group --name theglobetrotterslive --settings DOCKER_POSTGRES_HOST=$DOCKER_POSTGRES_HOST
az webapp config appsettings set --resource-group $resource_group --name theglobetrotterslive --settings DOCKER_POSTGRES_PASSWORD=$DOCKER_POSTGRES_PASSWORD
az webapp config appsettings set --resource-group $resource_group --name theglobetrotterslive --settings RAILS_ENV=production
az webapp config appsettings set --resource-group $resource_group --name theglobetrotterslive --settings RAILS_SERVE_STATIC_FILES=0
az webapp config appsettings set --resource-group $resource_group --name theglobetrotterslive --settings RAILS_LOG_TO_STDOUT=1
az webapp config appsettings set --resource-group $resource_group --name theglobetrotterslive --settings RAILS_MASTER_KEY=$(cat config/master.key)
az webapp config appsettings set --resource-group $resource_group --name theglobetrotterslive --settings RAILS_HOST=theglobetrotterslive.azurewebsites.net

az webapp log config --name theglobetrotterslive --resource-group $resource_group --docker-container-logging filesystem
az webapp log tail --name theglobetrotterslive --resource-group $resource_group

# database
az postgres server create --resource-group globetrotter-rg --name globetrotter-db --sku-name B_Gen5_1 --storage 5120 --admin-user globetrotteradmin --version 11.0 --admin-password $DOCKER_POSTGRES_PASSWORD
# whitelist my freebox
az postgres server firewall-rule create -g globetrotter-rg -s globetrotter-db -n allowip --start-ip-address 78.226.237.105 --end-ip-address 78.226.237.105

# storage
az storage account create --resource-group $resource_group --name theglobetrotterslivesto --sku Standard_ZRS
account_key=$(az storage account keys list -g $resource_group -n theglobetrotterslivesto --query [0].value -o tsv)
az storage cors add --methods GET PUT OPTIONS --origins https://www.theglobetrotters.live --services b --allowed-headers '*' --account-name theglobetrotterslivesto --account-key $account_key 
# edit credentials to set the account_key
# export account_key
# EDITOR=vim rails credentials:edit # r!echo $account_key

# AKS
az aks create \
	-g $resource_group \
	-n theglobetrotterslive-aks \
	-s Standard_B2s \
	--node-count 1 \
	--ssh-key-value ~/.ssh/lio_rsa.pub \
	--attach-acr theglobetrottersliveregistry \
	--location francecentral \
	--network-plugin azure \
	--network-policy calico \
	--vm-set-type AvailabilitySet
	# AvailabilitySet only to save cost: idealy use scaleset
	# I had to manually change the type of disk attached to the scaleset to save cost (Premium => Standard)
	#--enable-cluster-autoscaler \
	#--min-count 1 \
	#--max-count 1 \
	#--node-osdisk-type Ephemeral \

# extract azure_credentials for github workflow
az ad sp create-for-rbac --name "GithubWorkflow" --role contributor \
	--scopes /subscriptions/$subscriptionId/resourceGroups/$resource_group \
	--sdk-auth

# once the cluster is deployed, the app can be installed with (upgrade can then be managed using github)
helm install theglobetrotterslive --namespace theglobetrotterslive charts/theglobetrotters --create-namespace
