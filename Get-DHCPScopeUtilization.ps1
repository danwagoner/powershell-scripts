#===========================
# Created on:   09/10/2014
# Created by:   Dan Wagoner
# Organization: NBN
# Filename:     Get-DHCPUtilization.ps1
# URL: http://www.nerdybynature.com/2014/09/10/powershell-dhcp-utilization-monitor/
# Usage: Get-DHCPUtilization.ps1
#==========================

$threshold = 90
$email_to = "<name@domain.com>"
$email_from = "<name@domain.com>"
$email_server = "<smtp server name>"
$scopes = Get-DhcpServerv4ScopeStatistics

foreach ($scope in $scopes) {
	if($scope.PercentageInUse -gt $threshold){
		$email_body = "Scope: $($scope.ScopeId) - pool IPs in use is $([math]::round($scope.PercentageInUse, 0))%"
		Send-MailMessage -To $email_to -From $email_from -SmtpServer $email_server -Subject "scope threshold exceeded - $($scope.ScopeId)" -Body $email_body
	}
}
