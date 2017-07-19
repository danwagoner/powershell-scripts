#===========================
# Created on:   01/14/17
# Created by:   Dan Wagoner
# Organization: NBN
# Filename:     Update-AntiAffinityDRSRules.ps1
# Description:	Creates a DRS anti-affinity rule for VMs with matching name prefixes to ensure availability via distribution. (ie: appserver01, appserver02)
#==========================

[CmdletBinding()]
Param(
  [Parameter(Mandatory=$True)]
   [string]$vCenter,
  [Parameter(Mandatory=$True)]
   [string]$CredentialStoreFile,
  [Parameter(Mandatory=$False)]
   [string[]]$Clusters
)

$log_file = "C:\Scripts\logs\drs_antiaffinity_$(Get-Date -f MMddyy).log"

Add-PSSnapin VMware.VimAutomation.Core

$cred = Get-ViCredentialStoreItem -Host $vCenter -File $CredentialStoreFile #for more information on using the credential store feature: https://www.vmware.com/support/developer/windowstoolkit/wintk40u1/html/New-VICredentialStoreItem.html
Connect-ViServer $cred.Host -User $cred.User -Password $cred.Password

foreach ($cluster in $clusters){
	#create grouped list of VMs based on their name minus the 2 digit enumerator
	$vmgroups = Get-Cluster $cluster | Get-VM | ?{$_.PowerState -eq "PoweredOn"} | ?{$_.Name -notmatch "la1websol-cms\d{1,2}"} | Select Name, @{e={$_.Name -replace '\d{1,2}$'};l="Prefix"} | group prefix | ?{$_.Count -gt 1} | Select Name, @{e={$_.Group.Name};l="VM"}
	
	#check to see if drs group with name $vm.name exists, if so, check membership and update accordingly
	foreach ($vmgroup in $vmgroups){
		if ($drsrule = Get-DrsRule -Cluster $cluster -Name $vmgroup.Name -EA SilentlyContinue){
			#drs rule exists, check membership
			write-host "INFO: DRS rule $($drsrule.Name) exists, checking membership..."
			#"INFO: DRS rule $($drsrule.Name) exists, checking membership..." | Out-File $log_file -Append
			$vmgroup.VM | %{
				$drsrulevms = $drsrule | %{Get-VM -Id $_.VMIDs}
				if (!($drsrulevms.Name -contains "$($_)")){
					write-host "INFO: DRS rule $($drsrule.Name) does not contain $($_), adding now."
					"INFO: DRS rule $($drsrule.Name) does not contain $($_), adding now." | Out-File $log_file -Append
					#add new member
					$newvmlist = $drsrulevms += (Get-VM $_)
					write-host "INFO: DRS rule $($drsrule.Name) new membership list is $(($newvmlist) -join ", ")"
					"INFO: DRS rule $($drsrule.Name) new membership list is $(($newvmlist) -join ", ")" | Out-File $log_file -Append
					Set-DRSRule -Rule $drsrule -VM $newvmlist
				}
				else { write-host "INFO: DRS rule $($vmgroup.Name) already contains $($_)." }
			}
		}
		else {
			#if not, create drs group with necessary membership from $vm.VM
			write-warning "DRS rule $($vmgroup.Name) does not exist, creating with members $(($vmgroup.VM) -join ", ")"
			"INFO: DRS rule $($vmgroup.Name) does not exist, creating with members $(($vmgroup.VM) -join ", ")" | Out-File $log_file -Append
			$members = Get-VM $vmgroup.VM
			if (New-DrsRule -Name $vmgroup.Name -Cluster $cluster -Enabled:$true -KeepTogether:$false -VM $members){
				"INFO: New DRS rule created - $($vmgroup.Name)" | Out-File $log_file -Append
			}
		}
	}	
}