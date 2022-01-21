<#
.SYNOPSIS
  Code sample on how to update/add Custom Properties to a deployed object on VMware vRA SaaS or On-Prem via REST
.DESCRIPTION
  Replace/modify parameters with your own.
.NOTES
  Website:        www.amikkelsen.com
  Author:         Anders Mikkelsen
  Creation Date:  2022-01-21

  Reworked from:
  https://developer.vmware.com/docs/12597/vrealize-automation-8-2-api-programming-guide/GUID-F6338150-20FB-4B26-AC08-FDFE55074304.html
#>

function Set-ComputeCustomProperties($vRAUrl, $apiUrl, $body, $token) {
    # Get BearerToken
    $bearerUrl = $vRAUrl + "/iaas/api/login"
    $body = "{`"refreshToken`": $token}"
    $bearerToken = Invoke-RestMethod $bearerUrl -ContentType "application/json" -Body $body -Method 'POST'

    $uri = $vRAUrl + $apiUrl
    $response = Invoke-RestMethod $uri -Headers @{'Authorization' = "Bearer $($bearerToken.token)" } -ContentType "application/json" -Body $body -Method 'PATCH'
   
    Return $response
}


$vRAUrl = "https://api.mgmt.cloud.vmware.com"
$computeObjectId = "f79071c3-1846-37ca-95a8-06b25f26d4ee"
$apiUrl = "/iaas/api/machines/$computeObjectId"
$json = [pscustomobject] @{
    "customProperties" = @{
        "MyName" = "Anders Mikkelsen";
        "MyLocation" = "Denmark";
    }
}
$body = $json | ConvertTo-Json
$token = "<vRA API token -- NOT bearer token>"

Set-ComputeCustomProperties -vRAUrl $vRAUrl -ApiUrl $apiUrl -body $body -token $token
