#!/bin/bash
#./oocp-azure-deploy.sh 'Project Wright' INGAsiaXYZ
#export azPRJ_NAME=${1:-'Project Wright'}
export ARM_PRJNAME='Project Wright'
export ARM_RG=${1:-'DummyRG'}
export ARM_LOC=${2:-'southeastasia'}
export ARM_KEY=$(cat /dev/urandom | env LC_CTYPE=C tr -cd 'a-z' | head -c 12)
export ARM_PWD=$ARM_KEY$(cat /dev/urandom | env LC_CTYPE=C tr -cd 'A-Z' | head -c 2)$(cat /dev/urandom | env LC_CTYPE=C tr -cd '0-9' | head -c 2)
#export ARM_PWD=${3:-'Pass@word1'}
echo $ARM_PRJNAME "," $ARM_RG "," $ARM_LOC "," $ARM_PWD
###------------------------
export ARM_KV="$ARM_RG-kv"
export ARM_SECRET="$ARM_RG-secret"
azRG_PROP=$(az account list | jq '.[] | select(.name == env.ARM_PRJNAME)')
echo $azRG_PROP
export ARM_CLIENTID=$(az account list | jq '.[] | select(.name == env.ARM_PRJNAME)' | jq -r '.id')
export ARM_TENANTID=$(az account list | jq '.[] | select(.name == env.ARM_PRJNAME)' | jq -r '.tenantId')
echo $azKV "," $azSEC "," $ARM_TENANTID "," $ARM_CLIENTID
#az account list | jq '.[] | select(.name == 'Project Wright')' | jq -r '.id'
az account set --subscription=$ARM_CLIENTID
if [ "$(az group exists --name $ARM_RG)" == "true" ] ;
then
  echo "Oops, the $ARM_RG already exist"
  echo $(az ad sp list --display-name $ARM_RG-cloudprovider --query "[].appId" -o tsv)
  #$(az ad sp list --display-name $azRG-cloudprovider |grep objectId|awk -F\" '{ print $4 }')
else
  az group create -n $ARM_RG -l $ARM_LOC
  az keyvault create -n $ARM_KV -g $ARM_RG -l $ARM_LOC --enabled-for-template-deployment true
  az keyvault secret set --vault-name $ARM_KV -n $ARM_SECRET --file ~/.ssh/id_rsa
  ###------------------------
  sp_id=$(az ad sp list --display-name $ARM_RG-cloudprovider |grep objectId|awk -F\" '{ print $4 }')
  echo $sp_id
  if [ "$sp_id" != "" ]; then
    az ad sp delete --id $sp_id
  fi
  ###------------------------

  export ARM_APPID=$(az ad sp create-for-rbac -n $ARM_RG-cloudprovider --password $ARM_PWD --role contributor --scopes="/subscriptions/$ARM_CLIENTID/resourceGroups/$ARM_RG" | jq -r '.appId')
  echo $ARM_APPID

fi

if [ -n "$ARM_APPID" ]
then

  {
    jq '.parameters.keyVaultSecret.value=env.ARM_SECRET' | \
    jq '.parameters.keyVaultName.value=env.ARM_KV' | \
    jq '.parameters.keyVaultResourceGroup.value=env.ARM_RG' | \
    jq '.parameters.aadClientId.value=env.ARM_APPID' | \
    jq '.parameters.aadClientSecret.value=env.ARM_PWD'
  } < azuredeploy-template-parameters.json > azuredeploy-$ARM_RG.parameters.json

  cat azuredeploy-$ARM_RG.parameters.json
  az group deployment create --name $(echo "$ARM_RG" | awk '{print tolower($0)}')-deployment --template-file azuredeploy.json --parameters @azuredeploy-$ARM_RG.parameters.json --resource-group $ARM_RG --debug
else
  echo "Uh oh! Houston, we've got a  problem!"
fi
#az group deployment create --resource-group OSODEV --template-file azuredeploy.json --parameters @azuredeploy0.parameters.json --debug
#az group deployment create --name ocpdeployment --template-file azuredeploy.json --parameters @azuredeploy.parameters.wright-dev.json --resource-group OCPDEV --no-wait
#az group deployment create --name osodeployment --template-file azuredeploy.json --parameters @azuredeploy0.parameters.json --resource-group INGAsiaOSODev --debug
#az group deployment delete --name osodeployment --resource-group INGAsiaOSODev --debug

#Standard Dv3 Family vCPUs
#Standard_DS1_v2,Standard_DS2_v2,Standard_DS3_v2,Standard_DS4_v2,Standard_DS5_v2,Standard_DS11_v2,
#Standard_DS12_v2,Standard_DS13_v2,Standard_DS13-4_v2,Standard_DS13-2_v2,Standard_DS14_v2,
#Standard_DS14-8_v2,Standard_DS14-4_v2,Standard_DS15_v2,Standard_F1s,Standard_F2s,Standard_F4s,
#Standard_F8s,Standard_F16s,Standard_DS2_v2_Promo,Standard_DS3_v2_Promo,Standard_DS4_v2_Promo,
#Standard_DS5_v2_Promo,Standard_DS11_v2_Promo,Standard_DS12_v2_Promo,Standard_DS13_v2_Promo,Standard_DS14_v2_Promo,
#Standard_D2s_v3,Standard_D4s_v3,Standard_D8s_v3,Standard_D16s_v3,Standard_D32s_v3,Standard_D32-16s_v3,Standard_D32-8s_v3,
#Standard_B1s,Standard_B1ms,Standard_B2s,Standard_B2ms,Standard_B4ms,Standard_B8ms,Standard_DS11-1_v2,
# Standard_DS12-1_v2,Standard_DS12-2_v2.

#Standard A0-A7 Family vCPUs
#Standard Av2 Family vCPUs
#Standard BS Family vCPUs
#Standard D Family vCPUs
#Standard DS Family vCPUs
#echo $({jq '.parameters.aadClientSecret.value=pax' | jq '.parameters.aadClientId.value=123' } < azuredeploy0.parameters.json) | tee azuredeploy-ABC.parameters.json
