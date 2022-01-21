<#
.SYNOPSIS
  Code sample on how to update a deployments info on VMware vRA SaaS or On-Prem via REST
.DESCRIPTION
  Code sample on how to update a deployments info on VMware vRA SaaS or On-Prem via REST
  Like
  - Name [String]
  - Description [string]
  - IconId [string($uuid)]
.NOTES
  Website:        www.amikkelsen.com
  Author:         Anders Mikkelsen
  Creation Date:  2022-01-21

  Reworked from:
  https://api.mgmt.cloud.vmware.com/deployment/api/swagger/swagger-ui.html?urls.primaryName=2020-01-30#/Deployments/patchDeploymentUsingPATCH_1
#>

function Set-DeploymentInfo($vRAUrl, $apiUrl, $body, $token) {
  # Get BearerToken
  $bearerUrl = $vRAUrl + "/iaas/api/login"
  $bearerBody = "{`"refreshToken`": $token}"
  $bearerToken = Invoke-RestMethod $bearerUrl -ContentType "application/json" -Body $bearerBody -Method 'POST'

  $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
  $headers.Add("Authorization", "Bearer $($bearerToken.token)")
  $headers.Add("Content-Type", "application/json")

  $uri = $vRAUrl + $apiUrl
  $response = Invoke-RestMethod $uri -Headers $headers -Body $body -Method 'PATCH'
 
  Return $response
}

$token = "<vRA API token -- NOT bearer token>"
$vRAUrl = "https://api.mgmt.cloud.vmware.com"
$deploymentId = "1a9f02ae-b153-4092-ab78-f5094c7436e9"
$apiUrl = "/deployment/api/deployments/$deploymentId"
$json = [pscustomobject] @{
  "name" = "<New Deployment Name>";
  "description" = "<New Description>";
}
$body = $json | ConvertTo-Json

Set-DeploymentInfo -vRAUrl $vRAUrl -ApiUrl $apiUrl -body $body -token $token
