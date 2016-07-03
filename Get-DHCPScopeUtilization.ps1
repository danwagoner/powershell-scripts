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
