<#
    .SYNOPSIS
    Expands vmware disk and host partition for single or multiple servers.
    .DESCRIPTION
    .
    .EXAMPLE
    .\resizeVmwareDisk.ps1 -vCenterServer myvcenter.local -newDiskSizeGB 50 -servers server1, server2, server3
    .INPUTS
    None.
    .OUTPUTS
    None
    .NOTES
    Author: Kevin Brinnehl
    Date:   2017.10.11 - Initial publish.
    
#>

Param
(
    [parameter(Mandatory=$true)]
    [String]
    $vCenterServer,

    [parameter(Mandatory=$true)]
    [String]
    $newDiskSizeGB,

    [parameter(Mandatory=$true)]
    [String[]]
    $servers
)

#Install PowerCLI if it doesn't exist already
If (!(Get-Module Vmware.PowerCli)) {
    Install-Module Vmware.PowerCli -AllowClobber -Force
}
 
# Connect to vCenter via PowerCLI
Connect-VIServer $vCenterServer
 

foreach ($server in $servers) {
    Write-Host "Modifying disk size for $server" -ForegroundColor Green
    $vm = Get-VM $server

    #Get all hardsisks for server
    $disks = $vm | Get-HardDisk

    #Construct menu to pick the hard disk you want to modify
    $menu = @{}
    [int]$ans = $null
	Write-Host "`nSelect the Disk You Want To Resize`n" -ForegroundColor:Magenta

	for ($i=1;$i -le $disks.count; $i++) 
		{
		Write-Host "`t$i. $($disks[$i-1].Name), $($disks[$i-1].CapacityGB)" -ForegroundColor:Cyan
		$menu.Add($i,($disks[$i-1].Name))
		}
 
    #force user to pick an acceptable value
    do
		{
		[int]$ans = Read-Host 'Enter selection'
		If (!($menu.ContainsKey($ans)))
			{
			Write-Host "Please choose a valid number from the list." -ForegroundColor:Red
			}
		}
	until
		($menu.ContainsKey($ans))
		
	$selection = $menu.Item($ans)

    #Resize vmware disk and expand host disk partition
    $vm | Get-HardDisk | Where-Object {$_.Name -eq $selection} | Set-HardDisk -CapacityGB $newDiskSizeGB -Confirm:$false -ResizeGuestPartition
    Write-Host "Disk sizing complete for $server" -ForegroundColor Green
}