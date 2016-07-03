#===========================
# Created on:   03/27/2013
# Created by:   Dan Wagoner
# Organization: NBN
# Filename:     Get-PrinterEvents.ps1
# URL: http://www.nerdybynature.com/2013/06/07/powershell-printer-events/
#==========================

Param(
	[parameter(Mandatory=$true)]
    [alias("s")]
    $startdate,
	[parameter(Mandatory=$true)]
    [alias("e")]
    $enddate)

Add-PSSnapin Quest.ActiveRoles.ADManagement

$PrintServer = "LOCALHOST" # Enter the name of your print server here
$PrintJobs = @()

Get-EventLog -ComputerName $PrintServer -Source "Print" -LogName System -After $startdate -Before $enddate | Sort-Object TimeGenerated | %{
	$Message = $_.Message
	
	If ($Message.StartsWith("Documen") -and ($Message.Contains("was printed on"))){
		
		$TimeDateStamp = $_.TimeGenerated
		$DocumentNumber = $Message.Remove(0, 9).Substring(0, $Message.Remove(0, 9).LastIndexOf(", "))
		$DocumentName = $Message.Substring($Message.IndexOf(", ") +2, ($Message.IndexOf(" owned by") - ($Message.IndexOf(", ") +2)))
		$DocumentOwner = $Message.Substring(($Message.Indexof(" owned by") + 9), ($Message.IndexOf(" was printed on ") - ($Message.LastIndexof(" owned by") + 9))).Trim()
		$PrinterUsed = $Message.Substring(($Message.Indexof(" printed on ") + 12), ($Message.IndexOf(" via ") - ($Message.Indexof(" printed on ") + 12)))
		$SizeInBytes = $Message.Substring(($Message.Indexof(" bytes: ") + 8), ($Message.IndexOf("; ") - ($Message.Indexof(" bytes: ") + 8)))
		$PagesPrinted = $Message.Substring(($Message.Indexof(" pages printed: ") + 16), ($Message.Length) - ($Message.Indexof(" pages printed: ") + 16))
		$UserADInfo = Get-QADUser $DocumentOwner
		
		$Builder = New-Object System.Object
		$Builder | Add-Member -Type NoteProperty -Name TimeDateStamp -Value $TimeDateStamp
		$Builder | Add-Member -Type NoteProperty -Name DocumentNumber -Value $DocumentNumber
		$Builder | Add-Member -Type NoteProperty -Name DocumentName -Value $DocumentName
		$Builder | Add-Member -Type NoteProperty -Name DocumentOwner -Value $DocumentOwner
		$Builder | Add-Member -Type NoteProperty -Name OwnerDept -Value $UserADInfo.Department
		$Builder | Add-Member -Type NoteProperty -Name PrinterUsed -Value $PrinterUsed
		$Builder | Add-Member -Type NoteProperty -Name SizeInBytes -Value $SizeInBytes
		$Builder | Add-Member -Type NoteProperty -Name PagesPrinted -Value $PagesPrinted
		$PrintJobs += $Builder
		$PrintJobs
	}
}
