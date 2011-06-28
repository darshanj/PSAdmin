param([string] $env, [string]$machine, [string] $machinetype)
$ScriptDir = Split-Path $MyInvocation.MyCommand.Path -Parent
Import-Module "$ScriptDir\Modules\Probes.psm1" -DisableNameChecking -Force
$global:machine = $machine
$global:machinetype = $machinetype.ToUpper()
$global:env = $env.ToUpper()


function CheckFreeDiskUsage
{
	$disks = Get-PSDrive | Where {$_.Provider -match 'FileSystem' -and $_.Used -gt 0} 
	
	foreach ($disk in $disks)
	{
		$paramname = "{0} - Disk Space" -f $disk.Name
		$used = $disk.Used / (1024*1024*1024)
		$free = $disk.Free / (1024*1024*1024)
		$paramvalue = "Used - {0:0} GB, Free - {1:0} GB" -f $used, $free
		addParameter $paramname $paramvalue 2
	}
}

function CheckIP
{
	$ipconfigs = gwmi -Class win32_networkadapterconfiguration 
	$ips = @()

	foreach ($ipconfig in @($ipconfigs))
	{
		$ips += $ipconfig.IPAddress
	}

	addParameter "Machine IP" $ips 2
}

function RunProbes
{
	Probe-Services "vpnagent"
}

Write-Host "Starting health check for Machine:$machine Environment:$env MachineType:$machinetype"
Init-Probes
RunProbes
CheckFreeDiskUsage
CheckIP
#Post-Probe
