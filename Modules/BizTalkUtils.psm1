
try {
	[System.Reflection.Assembly]::LoadFrom("C:\Program Files\Microsoft BizTalk Server 2006\Developer Tools\Microsoft.BizTalk.ExplorerOM.dll") | Out-Null
}
catch {
	Write-Host "Could not load Biztalk Explorer Assembly"
}


# BizTalk Catalog Explorer Assembly
Function Invoke-BizTalkEOM
{	
	$BizTalkConnectionString = "SERVER=.;DATABASE=BizTalkMgmtDb;Integrated Security=SSPI"
	if ( ( Test-Path "HKLM:SOFTWARE\Microsoft\Biztalk Server\3.0\Administration" ) -eq $true )
	{
		$BizTalkMgmtDBServer = ( Get-ItemProperty "HKLM:SOFTWARE\Microsoft\Biztalk Server\3.0\Administration" ).MgmtDBServer
		$BizTalkMgmtDBName = ( Get-ItemProperty "HKLM:SOFTWARE\Microsoft\Biztalk Server\3.0\Administration" ).MgmtDBName
		$BizTalkConnectionString = "SERVER=$BizTalkMgmtDBServer;DATABASE=$BizTalkMgmtDBName;Integrated Security=SSPI"
	}
	$BizTalkCatalogExplorer = New-Object Microsoft.BizTalk.ExplorerOM.BtsCatalogExplorer
	$BizTalkCatalogExplorer.ConnectionString = $BizTalkConnectionString
	return $BizTalkCatalogExplorer
}

Function Get-Application([string] $Name)
{	
		$BizTalkCatalogExplorer = Invoke-BizTalkEOM
		$Application = $BizTalkCatalogExplorer.Applications  | Where-Object { $_.Name -match "$Name" }
		$Application
}

Function Check-Orchestrations([string] $Name)
{
	$BizTalkCatalogExplorer = Invoke-BizTalkEOM
	$BizTalkApplications = Get-Application
	
	Foreach($application in $BizTalkApplications)
	{
		Foreach ($orch in $application.Orchestrations  )
		{	
			$Status = if( $orch.Status -eq "Started") {"UP"} else {"DOWN"}
			if ($Status -eq "DOWN")
			{
				return $Status
			}
		}
	}
	return $Status
}

Function Check-SendPorts([string] $Name)
{
	$BizTalkCatalogExplorer = Invoke-BizTalkEOM
	$BizTalkApplications = Get-Application
	
	Foreach($application in $BizTalkApplications)
	{
		Foreach ($port in $application.SendPorts  )
		{	
			$Status = if( $port.Status -eq "Started") {"UP"} else {"DOWN"}
			if ($Status -eq "DOWN")
			{
				return $Status
			}
		}
	}
	return $Status
}

Function Check-Applications($Name)
{
	$BizTalkCatalogExplorer = Invoke-BizTalkEOM
	$BizTalkApplications = Get-Application
	$Status = ""
	Foreach($application in $BizTalkApplications)
	{
		$Status = if( $application.State -eq "Stopped") {"DOWN"} else {"UP"}
		if ($Status -eq "DOWN")
		{
			return $Status
		}
		
	}
	return $Status
}


Function Check-HostInstances($Name)
{
	$hostinstances = Get-WmiObject -Class "MSBTS_HostInstance" -Namespace 'root\MicrosoftBizTalkServer' -Filter "HostType='1'" 
	ForEach($instance in $hostinstances)
	{
		$Status = if( $instance.ServiceState -eq 4) {"UP"} else {"DOWN"}
		if ($Status -eq "DOWN")
		{
			return $Status
		}
		
	}
	return $Status
}




