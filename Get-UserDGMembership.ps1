#===========================
# Created on:   09/10/2014
# Created by:   Dan Wagoner
# Organization: NBN
# Filename:     Get-UserDGMembership.ps1
# URL: http://www.nerdybynature.com/2012/10/09/list-distribution-groups-a-user-is-a-member-of/
# Usage: Get-DHCPUtilization.ps1
#==========================


$user = Read-Host "Please enter the name of a user"

if (Get-Mailbox $user){
	$dgs = Get-DistributionGroup -ResultSize unlimited
	write-host
	write-host "$user is a member of the following distribution groups (this may take a few minutes):"
	write-host

	$dgs | foreach {if ((Get-DistributionGroupMember $_.Name) -match $user){write-host $_.Name}}
}
else{
	write-host "User not found...run script again. Sober up first." -foregroundcolor red
	write-host
}
