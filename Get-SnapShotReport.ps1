#===========================
# Created on:   10/16/2014
# Created by:   Dan Wagoner
# Organization: NBN
# Filename:     Get-SnapShotReport.ps1
# Description:    This script generates an HTML report of outstanding
#                VMWare snapshots, and correlates them to a user via
#                VMWare events.
#
# Usage: Get-SnapShotReport.ps1 -Server <vCenter/ESXi Server Name>
#==========================

Param(
[Parameter(Mandatory=$True)]
[string]$Server
)

Add-PSSnapin VMware.VimAutomation.Core
Connect-ViServer $Server

$email_to = "email@domain.com"
$email_from = "email@domain.com"
$email_server = "server.domain.com"
$email_subject = "VMWare Snapshot Report"
$snaps = @()
$currsnaps = Get-VM | ?{$_.PowerState -eq "PoweredOn"} | Get-Snapshot | Select VM, Name, Created, SizeGB
$css = "<style>BODY{font-family: Arial; font-size: 10pt;}
TABLE{border: 1px solid black; border-collapse: collapse;}
TH{border: 1px solid black; background: #dddddd; padding: 5px;}
TD{border: 1px solid black; padding: 5px;}</style>
"

foreach ($snap in $currsnaps){
	$user = ($snap.VM | Get-ViEvent | ?{$_.CreatedTime -match $snap.Created} | ?{$_.FullFormattedMessage -match "snapshot"}).Username
	$builder = New-Object System.Object
	$builder | Add-Member -Type NoteProperty -Name VM -Value $snap.VM
	$builder | Add-Member -Type NoteProperty -Name SnapName -Value $snap.Name
	$builder | Add-Member -Type NoteProperty -Name TimeStamp -Value $snap.Created
	$builder | Add-Member -Type NoteProperty -Name SizeGB -Value $([math]::floor($snap.SizeGB))
	$builder | Add-Member -Type NoteProperty -Name CreatedBy -Value $user
	$snaps += $builder
}

if($snaps){
	Send-MailMessage -To $email_to -From $email_from -SmtpServer $email_server -Subject $email_subject -BodyAsHtml ($snaps | ConvertTo-Html -Head $css | Out-String)
}
