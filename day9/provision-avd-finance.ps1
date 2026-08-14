$ErrorActionPreference = 'Stop'

$az = 'C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd'
$subscriptionId = '56f6d861-2ab0-4b14-a0e8-9e6d6192b3ad'
$resourceGroup = 'dwpai-lab-rg'
$location = 'eastus'
$hostPoolName = 'POOL-FIN-01'
$appGroupName = 'POOL-FIN-01-DAG'
$workspaceName = 'FinBridge-Workspace'
$vmName = 'fin-avd-sh01'
$vmSize = 'Standard_B2ms'
$vmImage = 'MicrosoftWindowsDesktop:windows-11:win11-24h2-avd:latest'
$adminUser = 'localavdadmin'
$vnetName = 'dwpai-avd-vnet'
$subnetName = 'dwpai-avd-subnet'
$nsgName = 'dwpai-avd-nsg'

& $az account set --subscription $subscriptionId

$registrationExpiration = (Get-Date).ToUniversalTime().AddHours(24).ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ')
& $az desktopvirtualization hostpool update -g $resourceGroup -n $hostPoolName --registration-info expiration-time=$registrationExpiration registration-token-operation=Update -o none
$registrationToken = & $az desktopvirtualization hostpool retrieve-registration-token -g $resourceGroup -n $hostPoolName --query token -o tsv

& $az desktopvirtualization hostpool create -g $resourceGroup -n $hostPoolName -l $location --host-pool-type Pooled --load-balancer-type BreadthFirst --max-session-limit 5 --preferred-app-group-type Desktop --validation-environment false --friendly-name $hostPoolName --description 'Finance pooled host pool' -o none

$hostPoolArmPath = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.DesktopVirtualization/hostPools/$hostPoolName"
& $az desktopvirtualization applicationgroup create -g $resourceGroup -n $appGroupName -l $location --application-group-type Desktop --host-pool-arm-path $hostPoolArmPath --friendly-name $appGroupName --description 'Desktop app group for finance pool' -o none

& $az desktopvirtualization workspace create -g $resourceGroup -n $workspaceName -l $location --friendly-name $workspaceName --description 'Finance bridge workspace' -o none

$appGroupArmPath = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.DesktopVirtualization/applicationGroups/$appGroupName"
& $az desktopvirtualization workspace update -g $resourceGroup -n $workspaceName --application-group-references $appGroupArmPath -o none

& $az vm create -g $resourceGroup -n $vmName -l $location --image $vmImage --size $vmSize --admin-username $adminUser --security-type TrustedLaunch --enable-secure-boot true --enable-vtpm true --assign-identity --vnet-name $vnetName --subnet $subnetName --nsg $nsgName --public-ip-sku Standard --storage-sku StandardSSD_LRS -o none

& $az vm extension set -g $resourceGroup --vm-name $vmName --publisher Microsoft.Azure.ActiveDirectory --name AADLoginForWindows --output none

$agentInstallScript = @'
param([string]$registrationToken)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$agentUri = 'https://go.microsoft.com/fwlink/?linkid=2310011'
$bootUri = 'https://go.microsoft.com/fwlink/?linkid=2311028'
$agentMsi = 'C:\Windows\Temp\avd-agent.msi'
$bootMsi = 'C:\Windows\Temp\avd-bootloader.msi'
Invoke-WebRequest -Uri $agentUri -OutFile $agentMsi
Invoke-WebRequest -Uri $bootUri -OutFile $bootMsi
Start-Process msiexec.exe -ArgumentList "/i `"$agentMsi`" /quiet /qn /norestart REGISTRATIONTOKEN=$registrationToken" -Wait -NoNewWindow
Start-Process msiexec.exe -ArgumentList "/i `"$bootMsi`" /quiet /qn /norestart" -Wait -NoNewWindow
'@

& $az vm run-command invoke -g $resourceGroup -n $vmName --command-id RunPowerShellScript --scripts $agentInstallScript --parameters "registrationToken=$registrationToken" -o none

$vmId = & $az vm show -g $resourceGroup -n $vmName --query id -o tsv
$userObjectId = & $az ad user show --id p40@zippyops.in --query id -o tsv

& $az role assignment create --assignee-object-id $userObjectId --assignee-principal-type User --role 'Virtual Machine User Login' --scope $vmId -o none
& $az role assignment create --assignee-object-id $userObjectId --assignee-principal-type User --role 'Desktop Virtualization User' --scope $appGroupArmPath -o none

& $az rest --method get --url "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.DesktopVirtualization/hostPools/$hostPoolName/sessionHosts?api-version=2024-04-03" -o table