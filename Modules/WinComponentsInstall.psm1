<#
License : Apache 2.0
Source : https://github.com/samirkseth/PSAdmin
#>

Function SetWindowsSourcePaths($OSPATH)
{
	Set-ItemProperty "HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Setup" -Name "SourcePath" -Value "$OSPATH"
	Set-ItemProperty "HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Setup" -Name "ServicePackSourcePath" -Value  "$OSPATH"
}

Function Change-WindowsComponents($UnattendFile)
{
	Write-Host "Installing from $UnattendFile"
	$sysocinf = "{0}/inf/sysoc.inf" -f $env:windir
	sysocmgr /i:$sysocinf /u:$UnattendFile
}


Function Install-IIS6
{
	$IISInstall = @"
		[Components]
		iis_common = on
		iis_www = on
		iis_inetmgr = on
		iis_asp = on
		aspnet = on
		complusnetwork = on

		[InternetServer]
		PathFTPRoot = C:\Inetpub\Ftproot
		PathWWWRoot = C:\Inetpub\Wwwroot
"@

	$Unattendfilename = "{0}\IISUnattendInstall.txt" -f $env:TEMP
	$IISInstall | Out-File $Unattendfilename -Encoding "ASCII"

	Change-WindowsComponents $Unattendfilename
}

Function Install-MSMQOn2003
{
	$IISInstall = @"
		[Version]
			Signature = "$Windows NT$"
		[Global]
			FreshMode = Custom
			MaintenanceMode = RemoveAll
			UpgradeMode = UpgradeOnly
		[Components]
			MSMQ = on
			MSMQ_Core = on
			MSMQ_LocalStorage = on
			MSMQ_HTTPSupport = on
			MSMQ_TriggersService = on
			MSMQ_ADIntegrated = off
			MSMQ_MQDSService = off
		[Msmq]
			DisableAD = TRUE
"@

	$Unattendfilename = "{0}\MSMQUnattendInstall.txt" -f $env:TEMP
	$IISInstall | Out-File $Unattendfilename -Encoding "ASCII"

	Change-WindowsComponents $Unattendfilename

}

Export-ModuleMember -function *