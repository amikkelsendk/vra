<#
.SYNOPSIS
  Code to enable WINRM (HTTP & HTTPS) on target host
  Incl code to test from client
.DESCRIPTION
  Code to enable WINRM (HTTP & HTTPS) on target host
  Incl code to test from client

  .NOTES
  Website:        www.amikkelsen.com
  Author:         Anders Mikkelsen
  Creation Date:  2022-12-12
#>

#####  WinRM Target host #####

$certLocation   = "Cert:\LocalMachine\My"
$hostname       = "vra-horizon-01.dcdemo.dom"
$certExportPath = "C:\Users\Administrator\vra.cer"

# Create Self Signed Cert
$cert = New-SelfSignedCertificate -CertstoreLocation $certLocation -DnsName $hostname

# Get Cert list - verify if it's created
Get-ChildItem -Path $certLocation

# Get Cert
# 4B6B6EF2735E93F547155B4B55186AD32314649E == cert to export
#$cert = Get-ChildItem -Path "$certLocation\4B6B6EF2735E93F547155B4B55186AD32314649E"

# Enable PSRemoting
Enable-PSRemoting

# Export Cert
Export-Certificate -Cert $cert -FilePath $certExportPath


# Configure WinRM - vRA requirements
# https://docs.vmware.com/en/vRealize-Automation/8.4/Using-and-Managing-CodeStream/GUID-7957EC89-00DF-415F-BB65-FB4839DE4A20.html
winrm set winrm/config/winrs '@{MaxShellsPerUser="500"}'
winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="2048"}'

# https://docs.vmware.com/en/vRealize-Orchestrator/8.10/com.vmware.vrealize.orchestrator-use-plugins.doc/GUID-D4ACA4EF-D018-448A-866A-DECDDA5CC3C1.html
winrm set winrm/config/client/auth '@{Basic="true"}'
winrm set winrm/config/client '@{AllowUnencrypted="true"}'

winrm set winrm/config/service/auth '@{Basic="true"}'
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/service/auth '@{CbtHardeningLevel="relaxed"}'


# Set TrustedHosts - who can connect
$hosts = "192.168.1.30"                 # Single
#$hosts = "192.168.1.30,192.168.1.0/24" # Multiple
#$hosts = "*"                           # ALL
Set-Item wsman:\localhost\client\TrustedHosts -Value $hosts -Force
#winrm set winrm/config/client '@{TrustedHosts="host1, host2, host3"}'
#winrm set winrm/config/client '@{TrustedHosts="*"}'

# Create WinRM HTTPS listner
winrm create winrm/config/Listener?Address=*+Transport=HTTPS '@{Hostname="vra-horizon-01.dcdemo.dom"; CertificateThumbprint="4B6B6EF2735E93F547155B4B55186AD32314649E"}'

# Verify
Get-Item wsman:\localhost\client\TrustedHosts
winrm get winrm/config

# Create Firewall openings
# HTTP
#Set-NetFirewallRule -DisplayName "Windows Remote Management (HTTP-In)" -RemoteAddress 192.168.13.100
Set-NetFirewallRule -DisplayName "Windows Remote Management (HTTP-In)" -RemoteAddress ANY
Enable-NetFirewallRule -DisplayName "Windows Remote Management (HTTP-In)"
# HTTPS
#New-NetFirewallRule -Name "WINRM-HTTPS-In-TCP" -DisplayName "Windows Remote Management (HTTPS-In)" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 5986 -RemoteAddress 192.168.13.100
New-NetFirewallRule -Name "WINRM-HTTPS-In-TCP" -DisplayName "Windows Remote Management (HTTPS-In)" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 5986 -RemoteAddress ANY
Enable-NetFirewallRule -DisplayName "Windows Remote Management (HTTPS-In)"

##### WinRM Client #####
#Enable-PSRemoting
#Test-NetConnection $hostname –Port 5985   # HTTP
#Test-NetConnection $hostname –Port 5986   # HTTPS
#Test-WsMan $hostname

#https://cloudblogs.microsoft.com/industry-blog/en-gb/technetuk/2016/02/11/configuring-winrm-over-https-to-enable-powershell-remoting/
#$so = New-PsSessionOption –SkipCACheck -SkipCNCheck
#Enter-PSSession -ComputerName <ip_address_or_dns_name_of_server>  -Credential <local_admin_username> -UseSSL -SessionOption $so