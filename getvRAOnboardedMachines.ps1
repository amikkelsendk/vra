<#
.SYNOPSIS
  Code sample on how to get res resources from VMware vRA SaaS or On-Prem via REST
.DESCRIPTION
  Code sample on how to get deployed resources from VMware vRA SaaS or On-Prem via REST
.NOTES
  Website:        www.amikkelsen.com
  Author:         Anders Mikkelsen
  Creation Date:  2022-01-21
#>

function Get-vRARestData($vRAUrl, $apiUrl, $token) {
    # Get BearerToken
    $bearerUrl = $vRAUrl + "/iaas/api/login"
    $body = "{`"refreshToken`": $token}"
    $bearerToken = Invoke-RestMethod $bearerUrl -ContentType "application/json" -Body $body -Method 'POST'

    # Get data
    $uri = $vRAUrl + $apiUrl
    $response = Invoke-RestMethod $uri -Headers @{'Authorization' = "Bearer $($bearerToken.token)" } -Method 'GET'
   
    Return $response
}


$vRAUrl = "https://api.mgmt.cloud.vmware.com"
$apiUrl = "/deployment/api/resources"
$token = "<vRA API token -- NOT bearer token>"

$result = Get-vRARestData -vRAUrl $vRAUrl -ApiUrl $apiUrl -token $token

$onboardedResources =  $result.content |  Where-Object{$_.origin -eq "ONBOARDED"} 

#$result | ConvertTo-Json
#$onboardedResources | ConvertTo-Json