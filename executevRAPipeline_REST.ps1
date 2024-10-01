<#
.SYNOPSIS
    Execute specific VMware Automation Pipeline
.DESCRIPTION
    Execute specific VMware Automation Pipeline

.NOTES
    Website:        www.amikkelsen.com
    Author:         Anders Mikkelsen
    Creation Date:  2024-10-01
#>

###############
## Functions ##
###############
Function Get-vRARefreshToken {
    Param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$vraServer,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]$Credential 
    )

    # Get Credentials to build auth:
    $username = $Credential.UserName
    $pass = $Credential.Password
    $password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pass))
    $authBody  = @{
        "username" = $username
        "password" = $password
    }
    
    # Build Header:
    $header = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $header.Add("Accept","application/json")
    $header.Add("Content-Type","application/json")
    
    # Get Refresh Token:
    $uri = "https://" + $vraServer + "/csp/gateway/am/api/login?access_token"
    $thisRefreshToken = Invoke-RestMethod -uri $uri -Method POST -Headers $header -Body ($authBody | ConvertTo-Json) #-SkipCertificateCheck
    
    Return $thisRefreshToken.refresh_token
}

Function Get-vRABearerToken {
    Param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$vraServer,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$RefreshToken
    )
       
    # Build Header:
    $header = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $header.Add("Accept","application/json")
    $header.Add("Content-Type","application/json")
    
    # Build Body
    $refreshTokenBody = @{
        "refreshToken" = $RefreshToken
    }

    # Get Access Token:
    $uri = "https://" + $vraServer + "/iaas/api/login"
    $accessToken = Invoke-RestMethod -Uri $uri -Method POST -Headers $header -body ($refreshTokenBody | ConvertTo-JSON) #-SkipCertificateCheck
    $accessToken = "Bearer " + $accessToken.token
    
    Return $accessToken
}


###############
## Variables ##
###############
# BasicInfo:
$vraServer      = "< vra server FQDN or IP"
$vraPipelineId  = "< pipeline ID >"         # Example: e8339292-eecd-4dc7-81a8-b63ec459173a

# Get vRA Credentials
$Credential     = Get-Credential -Message "Credentials for vRA Server"


##################
## Script Logic ##
##################
# Credentials
$refreshToken = Get-vRARefreshToken -vraServer $vraServer -Credential $Credential
$accessToken = Get-vRABearerToken -vraServer $vraServer -RefreshToken $refreshToken

# Build Header:
$header = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$header.Add("Accept","application/json")
$header.Add("Content-Type","application/json")
$header.Add("Authorization",$accessToken)       # add access token to Header


# Execute pipeline
$json = [pscustomobject] @{
    "comments" = "Executed via API";
    "inputs" = [pscustomobject] @{
        "variable001" = "Pipeline Variable001 value";
    }
}
$body = $json | ConvertTo-Json
$uri = "https://" + $vraServer + "/codestream/api/pipelines/" + $vraPipelineId + "/executions"
$pipelineResult = Invoke-RestMethod -uri $uri -Method POST -Headers $header -Body $body

# Show result
$pipelineResult | convertto-json


# Wait for / check for executaion staus
$executionLink = $pipelineResult.executionLink
$uri = "https://" + $vraServer + $executionLink
$pipelineStatus = Invoke-RestMethod -uri $uri -Method GET -Headers $header
do {
    $pipelineStatus = Invoke-RestMethod -uri $uri -Method GET -Headers $header
    write-host $pipelineStatus.status
}
While (  $pipelineStatus.status -eq "NOT_STARTED" -or $pipelineStatus.status -eq "QUEUED" -or $pipelineStatus.status -eq "RUNNING" )

# Show pipeline execution
$pipelineStatus | convertto-json
$pipelineStatus.status
