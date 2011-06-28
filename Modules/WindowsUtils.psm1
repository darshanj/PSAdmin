

Function CreateNewDirectory($createpath)
{
	if (Test-Path $createpath) {
		Remove-Item $createpath -force -recurse
	}

	New-Item $createpath -Type Directory | out-null
}


Function UnzipFilesShell($Zipfile, $TargetDir)
{
	Write-Host "Unzipping files from $Zipfile to $TargetDir"

	$shell_app=new-object -com shell.application 
	$filename = "test.zip" 
	$zip_file = $shell_app.namespace($Zipfile) 	
	$destination = $shell_app.namespace($TargetDir) 
	$destination.Copyhere($zip_file.items())
}

##################################################
# IIS Reset of an environment

Function IISReset
{
	(Get-WmiObject Win32_Service -ComputerName ServerA -Filter "Name='iisadmin'").InvokeMethod("StopService", $null) 

	OR

	Restart-Service W3SVC,WAS -force
}

Function Create-Shortcut($StdFolder, $LinkName, $TargetPath, $Arguments)
{
	$strDesktopFolder = [System.Environment]::GetFolderPath($StdFolder)
	$objShell = New-Object -com "Wscript.Shell"
	$objShortcut = $objShell.CreateShortcut($strDesktopFolder + "\$LinkName.lnk")
	$objShortcut.TargetPath = "$TargetPath"
	$objShortcut.Arguments = "$Arguments"	
	$objShortcut.Save()
}


# http://forums.techarena.in/software-development/1118216.htm
Function ElevationCheck
{
	$identity = [Security.Principal.WindowsIdentity]::GetCurrent()  
	$principal = new-object Security.Principal.WindowsPrincipal $identity 
	$elevated = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)  

	if (-not $elevated) {  
		$error = "Sorry, you need to run this script" 
		
		if ([System.Environment]::OSVersion.Version.Major -gt 5) {  
			# Vista, Longhorn
			$error += " in an elevated shell." 
		} else {  
			# Older (W2003, ...)
			$error += " as Administrator." 
		}  
		throw $error 
	}  
}


Function FirewallOff
{
	netsh firewall set opmode mode = DISABLE
}


Function Setup-AdministratorPassword ($newpassword)
{
	# Change administrator password

	$admin=[adsi]("WinNT://" + $strComputer + "/administrator, user")

	$admin.psbase.invoke("SetPassword", $newpassword)

	#$admin.psbase.CommitChanges() - apparently not needed
}

Function QuickPing($name, $port)
{
	$success = $false
	
	if (Test-Connection -ComputerName $name -Count 1) {
	
		# if the ping works, try opening a socket to the SMTP port
		if ($port) {
		     write-host "trying port $port"
			$socket = new-object System.Net.Sockets.TcpClient($name, $port)
			if ($socket –eq $null) {
				write-host "couldn’t open socket to port $port"
			}
			else {
				write-host "Got socket to port $port"
				$socket = $null
				$success = $true
			}
		}
	}
	else {
		write-host “$name is not reachable”
	}
	
	return $success
}

Function Get-IIS-Status
{
	$server = "localhost"
	$objWMI = [WmiSearcher] "Select * From IISWebServerSetting"
	$objWMI.Scope.Path = "\\" + $server + "\root\microsoftiisv2" 
	$objWMI.Scope.Options.Authentication = 6 
	$sites = $objWMI.Get() 
	foreach ($site in $sites)
	{
		$site
	}	
}

function Test-Port{
    Param([string]$srv,$port=135,$timeout=3000)
    $ErrorActionPreference = "SilentlyContinue"
    $tcpclient = new-Object system.Net.Sockets.TcpClient
	
	try {
		$iar = $tcpclient.BeginConnect($srv,$port,$null,$null)
		$wait = $iar.AsyncWaitHandle.WaitOne($timeout,$false)
	}
	catch [Exception $ex] {
        Write-Host "Error in Connection"
		$ex
	}
	
    if(!$wait)
    {
        $tcpclient.Close()
        Write-Host "Connection Timeout"
        $failed = $true
    }
    else
    {
        $error.Clear()
        $tcpclient.EndConnect($iar) | out-Null
        if($error[0]){write-host $error[0];$failed = $true}
        $tcpclient.Close()
    }
	
	Write-Host "Test-Port $failed"
    if($failed){return $false}else{return $true}
}

#####################################################
# Delete all files older than x days
Function DeleteFilesOlderThanXDays
{
	dir $env:temp –r | ?{$_.LastWriteTime -le (Get-Date).AddDays(-10)} | del
	## Delete all files except the 50 most recent ones
	dir $env:temp | sort lastwritetime -des | select -skip 50 | del
}


Function Setup-PerLocaleSettings
{
	# Set Per-user Locale Settings

	Set-ItemProperty "HKCU:\Control Panel\International" -Name iCountry -Value 44
	Set-ItemProperty "HKCU:\Control Panel\International" -Name iDate -Value 1
	Set-ItemProperty "HKCU:\Control Panel\International" -Name iMeasure -Value 0
	Set-ItemProperty "HKCU:\Control Panel\International" -Name Locale -Value 00000809
	Set-ItemProperty "HKCU:\Control Panel\International" -Name sCountry -Value "United Kingdom"
	Set-ItemProperty "HKCU:\Control Panel\International" -Name sCurrency -Value 
	Set-ItemProperty "HKCU:\Control Panel\International" -Name sLanguage -Value "ENG"
	Set-ItemProperty "HKCU:\Control Panel\International" -Name sLongDate -Value "dd MMMM, yyyy"
	Set-ItemProperty "HKCU:\Control Panel\International" -Name sShortDate -Value "dd/MM/yyyy"
	
	# Changing Time Zone
	# Windows Server 2003
	Control.exe TIMEDATE.CPL,,/Z Pacific Standard Time 
	# Windows Server 2009
	%windir%\system32\tzutil /s "Eastern Standard Time"
}

Function Add-Path-Machine ($NewPath)
{
	# Replaces windows path slashes by double slash to use in regex
	$currentpath = [Environment]::GetEnvironmentVariable("Path","Machine")
	$testpath = "$NewPath" -replace "\\", "\\" 
	
	Write-Host $testpath
	
	if (!($currentpath -imatch "(^|;)(\s)*$testpath(\s)*(;|`$)"))
	{
		Write-Host "Adding Path $NewPath to Machine Path"
		$currentpath += ";$NewPath"
		[Environment]::SetEnvironmentVariable("Path",$currentpath, "Machine")
	}
	else 
	{
		Write-Host "Did Not Add Path $NewPath to Machine Path as it already exists"
	}
	
}

Export-ModuleMember -function *