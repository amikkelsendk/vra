#########################################
# Kudos to: https://vkernel.nl/remove-cloud-config-from-existing-vra-8-deployments/?unapproved=257&moderation-hash=1b6c226aa9404814ec73d8c71729d487#comment-257
# 100% copied from vkernel.nl
# For personal reference....
#########################################

# Settings:
$vraServer = ""
$credential = Get-Credential
$username = $credential.UserName
$password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($credential.Password))
$removeCloudConfig = $false 

$header = @{
    "Accept" = "application/json"
    "Content-Type" = "application/json"
}

$authBody  = @{
    "username" = $username
    "password" = $password
} | ConvertTo-Json
 
# Get Refresh Token:
$uri = "https://" + $vraServer + "/csp/gateway/am/api/login?access_token"
$refreshToken = Invoke-RestMethod -uri $uri -Method POST -Headers $header -Body $authBody 
$refreshToken = $refreshToken.refresh_token
$refreshTokenBody = @{
    "refreshToken" = $refreshToken
} | ConvertTo-Json
 
# Get Access Token:
$uri = "https://" + $vraServer + "/iaas/api/login"
$accessToken = Invoke-RestMethod -Uri $uri -Method POST -Headers $header -body $refreshTokenBody 
$accessToken = "Bearer " + $accessToken.token
$header.Add("Authorization",$accessToken)

# Get all vRA deployments
# INFO: API return size is limited to 200.
$count = 0
$uri = "https://" + $vraServer + "/iaas/api/deployments"
$totalResources = (Invoke-RestMethod -Uri $uri -Method GET -Headers $header).totalElements
$arrayDeployments = @()
Write-Host "Requesting all deployments from VMware vRA..."
do{
    $uriNextPage = $uri + "?`$top=200&`$skip=$($count)"
    $deployments = Invoke-RestMethod -Uri $uriNextPage -Method GET -Headers $header
    $arrayDeployments += $deployments
    $count = $count + 200
}while($count -lt $totalResources)

Write-Host "Total resources collected:" $arrayDeployments.content.count -ForegroundColor Green

# Searching for deployments with cloud-config settings.
# If some resources are failing, it is most likely caused of a machine error in the vRA deployment
$cloudConfigResources = @()
foreach($d in $arrayDeployments.content){
    foreach($r in $d._links.resources.hrefs){
        if($r -like "/iaas/api/machines/*"){
            $uri = "https://" + $vraServer + $r
            $resource = Invoke-RestMethod -Uri $uri -Method GET -Headers $header 

            $resourceName = $resource.hostname
            Write-Host "Checking on resource: $resourceName" -ForegroundColor Yellow

            if($resource.bootConfig){
                $resourceID = $r.replace("/iaas/api/machines/",'')
                $hashtable = @{Name = $resourceName; ResourceID = $resourceID; BootConfig = $resource.bootConfig.content}  

                $cloudConfigResources += $hashtable
                Write-Host "Cloud-Config settings available!" -ForegroundColor Green

            }else{
                Write-Host "No cloud-config settings." 
            }
        }
    }
}

# Show all gathered resources with cloud-config.
if($cloudConfigResources){
    Write-Host "List of cloud-config enabled deployments:"
    $cloudConfigResources | %{[pscustomobject] $_} | Select-Object Name, ResourceID, Bootconfig
}else{
    Write-Host "No cloud-config enabled deployments."
}

# Removing the cloud-config settings from the custom properties
if($removeCloudConfig -eq $true){
    Write-Host "`$removeCloudConfig variable is enabled." 
    foreach($a in ($cloudConfigResources)){
        $resourceName = $a.Name
        $uri = "https://" + $vraServer + "/iaas/api/machines/" + $a.resourceID
        $body = @{
            "bootConfig" = @{}
        
            "customProperties" = @{
                "cloudConfig" = ""
            }
        } | ConvertTo-Json 
 
        Write-Host "Removing bootConfig and the cloud-config settings from the customProperties of resource:" $resourceName    
        $Patch = Invoke-RestMethod -Uri $uri -Method Patch -Body $body -Headers $header
    }
}else{
 Write-Host "`$removeCloudConfig variable not enabled."
}
