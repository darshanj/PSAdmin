$script:BASEENVLOCATION="Template Experiment"

$script:BASEENVLOCATION="Template Experiment"
$script:VMHOST="sifyvmw05.thoughtworks.com"
$script:BASETEMPLATE="W2003-DotNetTemplate"
$script:DATASTORE="tliscsi18"
$script:OSCUSTOMIZATIONSPEC="Windows 2003"


Function Create-Machine([String]$MachineName, [String] $Location)
{
	Write-Host "Creating Machine - $MachineName"

	New-Vm  -vmhost $VMHOST	`
	        -Name $MachineName `
			-Location $Location `
			-Template $BASETEMPLATE	`
			-Datastore $DATASTORE	`
			-OSCustomizationSpec $OSCUSTOMIZATIONSPEC

}

Function Create-Environment($envconfstr)
{
	[xml] $env = $envconfstr
	
	New-Folder -Name $env.Environment.name -Location $script:BASEENVLOCATION 
	
	foreach ($machinetypeentry in $env.Environment.Machines.Machine)
	{
		$machinetype = $machinetypeentry.Type
		$qty = $machinetypeentry.Quantity
			
		for ($i = 1; $i -le $qty; $i++) 
		{
			$machinename = "{0}{1:0#}.{2}" -f $machinetypeentry.BaseName, $i, $env.Environment.name
			Create-Machine $machinename $env.Environment.name
		}
	}
}

Function Delete-Environment($envname)
{
    $envconffile = "{0}\$envname.conf" -f $script:CONF
	[xml] $env = Get-Content $envconffile
	
	Remove-Folder -Folder $env.Environment.name -DeletePermanently
}