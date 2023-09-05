

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


####################################################


# BasicInfo:
$vraServer = "< vra server FQDN or IP"

# Get vRA Credentials
$Credential = Get-Credential -Message "Credentials for vRA Server"

$refreshToken = Get-vRARefreshToken -vraServer $vraServer -Credential $Credential
$accessToken = Get-vRABearerToken -vraServer $vraServer -RefreshToken $refreshToken

# Build Header:
$header = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$header.Add("Accept","application/json")
$header.Add("Content-Type","application/json")
$header.Add("Authorization",$accessToken)       # add access token to Header


# Query API
$uri = "https://" + $vraServer + "/abx/api/resources/actions"
$abxResult = Invoke-WebRequest -uri $uri -Method GET -Headers $header
$arrABX = ( $abxResult | ConvertFrom-Json ).Content





###################   EXTRA #####################
#For PS5.1 fixing error
# Invoke-RestMethod : The underlying connection was closed: Could not establish trust relationship for
# the SSL/TLS secure channel.
<#
$code= @"
        using System.Net;
        using System.Security.Cryptography.X509Certificates;
        public class TrustAllCertsPolicy : ICertificatePolicy {
            public bool CheckValidationResult(ServicePoint srvPoint, X509Certificate certificate, WebRequest request, int certificateProblem) {
                return true;
            }
        }
"@
Add-Type -TypeDefinition $code -Language CSharp
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
#>