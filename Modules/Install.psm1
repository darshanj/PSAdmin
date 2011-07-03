# Copyright : Apache License 2.0

$ScriptDir =  Split-Path -Parent $myinvocation.mycommand.path

$SoftwareDir = "$ScriptDir/../../Software"
$EISODir = "$ScriptDir/../../Exploded/ISOs"
$EMSIDir = "$ScriptDir/../../Exploded/Installers"

$SETUPDIR = "C:\Setup"
$TEMPDIR = $env:TEMP


function Install-Git
{
	# 32-bit
	$installdir = "$SETUPDIR\pgit"
	UnzipFiles "$SoftwareDir\PortableGit\PortableGit-1.7.3.1-preview20101002.7z" $installdir -Clean
}

function Install-Mercurial($bits="32")
{
	$targetfolder = "Mercurial"
	$Pfilesdir = "Mercurial"

	if ($bits -eq "64") {
		$msidir = "Mercurial-1.8.4-x64"
	}
	else {
		$msidir = "Mercurial-1.8.4-x86"
	}

	SimpleXCopyInstall "$EMSIDIR\$msidir\PFiles\$Pfilesdir" $targetfolder
}

function Install-Terminals
{
	# only 32-bit
	$installdir = "$SETUPDIR\Terminals"
	UnzipFilesFlattened "$SoftwareDir\Terminals\Version 2 - RC 1 - Third Build.zip" $installdir -Clean
	Create-DevToolsShortcut "Terminals" "$installdir\Terminals.exe" 
}

function Install-OracleSQLDeveloper([string]$bits = "32")
{
	if ($bits -eq "64") {
		$installdir = "$SETUPDIR\sqldeveloper"
		CreateNewDirectory $installdir
		UnzipFiles "$SoftwareDir\Oracle SQL Developer\64-bit\sqldeveloper64-3.0.04.34-no-jre.zip" $SETUPDIR
		Create-DevToolsShortcut "Oracle SQL Developer" "$installdir\sqldeveloper.exe" 
	}
	else {
		Write-Host "32-bit SQL Developer not implemented"
	}
}

function Install-ODAC-Net4 ([string]$bits = "32")
{
	# Switch between 32 / 64-bit
	$unzipdir = "$TEMPDIR\ODAC{0}Setup" -f $bits
	$installdir = "$SETUPDIR\ODAC$bits"
	
	if($bits -eq "32") { $suffix = "32bit" } else {$suffix = "x64"}
	
	UnzipFiles "$SoftwareDir\Oracle ODAC\$bits-bit\ODAC112021Xcopy_$suffix.zip" $unzipdir -Clean
	
	CreateNewDirectory $installdir
	
	Push-Location $unzipdir
	iex "$unzipdir\install.bat ODP.NET4 $installdir odac$bits"
	Pop-Location
	
	Get-MachinePathItems | Remove-PathItems -regex "ODAC" | Add-PathItems -New "$installdir", "$installdir\bin" | Set-MachinePathItems
}

function Install-NotepadPlusPlus
{
	# Portable npp - 32-bit? 
	$installdir = "$SETUPDIR\npp"
	UnzipFiles "$SoftwareDir\notepad++\npp.5.9.bin.7z" "$installdir" -Clean
	Create-DevToolsShortcut "Notepad++" "$installdir\unicode\Notepad++.exe" 	
}

function Install-Putty
{
	# only 32-bit available from Putty.org. Works on 64-bit also
	$installdir = "$SETUPDIR\putty"
	UnzipFiles "$SoftwareDir\putty\32-bit\putty.zip" "$installdir" -Clean
	Create-DevToolsShortcut "Putty" "$installdir\putty.exe" 	
}

function Install-SysInternals
{
	# bit-independent
	$installdir = "$SETUPDIR\sysinternals"
	UnzipFiles "$SoftwareDir\Microsoft Sysinternals\SysInternalsSuite.zip" "$installdir" -Clean
	Create-DevToolsShortcut "SI Process Explorer" "$installdir\procexp.exe" 	
}

function Install-Console2
{
	# 32-bit only
	$installdir = "$SETUPDIR\Console2"
	CreateNewDirectory $installdir
	UnzipFiles "$SoftwareDir\Console2\Console-2.00b147-Beta_32bit.zip" "$setupdir" 
	Create-DevToolsShortcut "Console2" "$installdir\Console.exe" 	
}

function Install-Eclipse-Helios
{
	Write-Host "Eclipse Helios not implemented"	
}

function Install-OfficeProfessional($licensekey, $username = "TW", $userinitials = "TW")
{
	$CONFIGFILE = "$TEMPDIR\OfficeLiteConfig.xml"
	$licensekeynodashes = $licensekey -replace "-"

	$OfficeLiteConfig = @"
		<Configuration Product="ProPlusr">
			<Display Level="none" CompletionNotice="no" SuppressModal="yes" AcceptEula="yes" />
			<!-- <Logging Type="standard" Path="%temp%" Template="Microsoft Office Professional Plus Setup(*).txt" /> -->
			<USERNAME Value="" />
			<USERINITIALS Value="SKS" />
			<COMPANYNAME Value="Company" />
			<PIDKEY Value="$licensekeynodashes" />
			<!-- <<INSTALLLOCATION Value="%programfiles%\Microsoft Office" /> -->
			<!-- <LIS CACHEACTION="CacheOnly" /> -->
			<!-- <LIS SOURCELIST="\\server1\share\Office;\\server2\share\Office" /> -->
			<!-- <DistributionPoint Location="\\server\share\Office" /> -->
			<OptionState Id="ACCESSFiles" State="absent" Children="force" />
			<OptionState Id="XDOCSFiles" State="absent" Children="force" />
			<OptionState Id="OneNoteFiles" State="absent" Children="force" />
			<OptionState Id="OUTLOOKFiles" State="absent" Children="force" />
			<OptionState Id="PPTFiles" State="absent" Children="force" />
			<OptionState Id="PubPrimary" State="absent" Children="force" />
			<OptionState Id="GrooveFiles" State="absent" Children="force" />
			<OptionState Id="VisioPreviewerFiles" State="absent" Children="force" />
			<OptionState Id="LOBiMain" State="absent" Children="force" />
			<OptionState Id="CAGFiles" State="absent" Children="force" />
			<OptionState Id="ProofingTools_1036" State="absent" Children="force" />
			<OptionState Id="OISFiles" State="absent" Children="force" />
			<Setting Id="SETUP_REBOOT" Value="never" />
			<!-- <Command Path="%windir%\system32\msiexec.exe" Args="/i \\server\share\my.msi" QuietArg="/q" ChainPosition="after" Execute="install" /> -->
		</Configuration>
"@

	$OfficeLiteConfig | Out-File "$TEMPDIR\OfficeLiteConfig.xml"
	& "$EISODIR\en_office_professional_plus_2010_x86_x64_dvd_515529\Setup.exe" /config $CONFIGFILE
}

Function Install-Wireshark([string]$bits = "32")
{
	# check if WinPCap is installed, else install it (npf.sys)
	if ($bits -eq "64") {
		iex "$SoftwareDir\Wireshark\64-bit\wireshark-win64-1.6.0.exe /S"
	}
	else {
		Write-Host "32-bit Wireshark not implemented"
	}
}

Function Install-WinPCap
{
	$installerdir = "$SOFTWAREDIR\WinPCap"
	$installfilename = Get-UniqueFileName $installerdir -pattern "WinPCap*"
	"Installing WinPCap from $installfilename"
	iex "$installfilename"
}

Function Install-CollabnetSVN
{
	SimpleXCopyInstall "$EMSIDIR/CollabnetSVN/`$INSTDIR" "CollabnetSVN"
}

Function Install-Scala
{
	$installerdir = "$SOFTWAREDIR\Scala"
	$zipfilename = Get-UniqueFileName $installerdir -pattern "Scala*.zip"
	$zipfilename -match ".*\\(.*)\.zip"
	$subfoldertocopy = $matches[1]

	SimpleUnzipInstall "$zipfilename" "Scala" "$subfoldertocopy" "bin"
}

Function Install-SqlServer2005SP3($bits = "32")
{
	if ($bits -eq "64") {
		$suffix = "x64"
	}
	else {
		$suffix = "x86"
	}	
	
	& "$SoftwareDir\Microsoft SQL Server 2005 SP3\SQLServer2005SP3-KB955706-$suffix-ENU.exe" '/quiet' '/allinstances' | Out-Null
}

Function Install-SqlServer2005($instancename, $ACCOUNT, $PASSWORD, $SAPWD, [switch] $Server, [switch] $Client, [switch] $NotificationServices, $bits = "32")
{
	$Features = @()
	# Server is included
	if ($Server) {
		$Features += "SQL_Engine"  
	}
	
	if ($Client) {
		$Features += "Client_Components","Connectivity","SQL_Tools90"
	}
	
	if ($NotificationServices) {
		$Features += "Notification_Services","NS_Engine","NS_Client"
	}
	
	$AddLocal = [string]::join(",", $Features)
	
	Write-Host "Installing SQL Server 2005 Features $AddLocal"

	if ($bits -eq "64") {
		$suffix = "x64"
	}
	else {
		$suffix = "x86"
	}	
	
	Write-Host "Suffix is $suffix"	
	
	& "$EISODIR\SQL_2005_dev_all_dvd\SQL Server $suffix\Servers\Setup.exe" '/qb' `
	"INSTANCENAME=$instancename" `
	"ADDLOCAL=$AddLocal" `
	"REMOVE=SQL_FullText"  `
	"SECURITYMODE=SQL" `
	"DISABLENETWORKPROTOCOLS=0" `
	"SAPWD=$SAPWD" `
	"SQLBROWSERACCOUNT=$ACCOUNT" `
	"SQLBROWSERPASSWORD=$PASSWORD" `
	"SQLASACCOUNT=$ACCOUNT" `
	"SQLASPASSWORD=$PASSWORD" `
	"SQLACCOUNT=$ACCOUNT" `
	"SQLPASSWORD=$PASSWORD" `
	"AGTACCOUNT=$ACCOUNT" `
	"AGTPASSWORD=$PASSWORD" | Out-Null
	
	Install-SqlServer2005SP3 $bits | Out-Null
}

Function Install-BiztalkConfig ($SQLServer, $servicecred, $EntSSOBackupSecretPwd)
{
	$insecurecred = $servicecred.GetNetworkCredentials()
	$params = @{
		HOSTNAME = (hostname)
		SQLSERVER = $SqlServer;
		DOMAIN = $insecurecred.Domain;
		USERNAME = $insecurecred.UserName;
		PASSWORD = $insecurecred.Password;
		ENTSSOBACKUPSECRETPWD = $EntSSOBackupSecretPwd
	}
	
	$biztemplatefile = "$ScriptDir\biztalktemplate.xml"
	$bizconfigfile = "$TEMPDIR\biztalkconfig.xml"
	
	Get-Content $biztemplatefile | Replace-Template -params $params | Out-File $bizconfigfile
}

#################################### UTILITY FUNCTIONS ##################################
set-alias sz 7za


Function SimpleUnzipInstall($zipfile, $targetfolder, $subfoldertocopy, $foldertoaddtopath )
{
	$unzipfolder = "$TEMPDIR\$targetfolder"
	UnzipFiles "$zipfile" "$TEMPDIR\$targetfolder" -Clean
	
	if ($subfoldertocopy) { 
		$srcfolder = "$unzipfolder\$subfoldertocopy"
	}
	else {
		$srcfolder = "$unzipfolder"
	}
	
	SimpleXCopyInstall $srcfolder $targetfolder $foldertoaddtopath
}

Function SimpleXCopyInstall($srcdir, $targetfolder, $foldertoaddtopath)
{
	$installdir = "$SETUPDIR\$targetfolder"
	CreateNewDirectory $installdir
	cp "$srcdir\*" "$installdir" -recurse
	
	$installdirstr = "$installdir" -replace "\\","\\"
	
	if ($foldertoaddtopath) {
		$pathdir = "$installdir\$foldertoaddtopath"
	}
	else {
		$pathdir = "$installdir"
	}
		
	Get-MachinePathItems | Remove-PathItems -regex "$installdir" | Add-PathItems -New "$pathdir" | Set-MachinePathItems	
}

Function CreateNewDirectory($createpath)
{
	if (Test-Path $createpath) {
		Remove-Item $createpath -force -recurse
	}

	New-Item $createpath -Type Directory | out-null
}

Function CheckCreateDirectory($createpath)
{
	if (!(Test-Path $createpath)) {
		New-Item $createpath -Type Directory | out-null
	}
}

Function UnzipFiles($Zipfile, $TargetDir, [switch] $Clean)
{
	if ($Clean) {
		CreateNewDirectory $TargetDir
	}
	
	Write-Host "Unzipping files from $Zipfile to $TargetDir"
	
	iex "sz x '$Zipfile' -o$TargetDir -y"
}

Function UnzipFilesFlattened($Zipfile, $TargetDir, [switch] $Clean)
{
	if ($Clean) {
		CreateNewDirectory $TargetDir
	}
	
	Write-Host "Unzipping files from $Zipfile to $TargetDir"
	
	iex "sz e '$Zipfile' -o$TargetDir -y"
}


Function Get-MachinePathItems
{
	# Replaces windows path slashes by double slash to use in regex
	$currentpath = [Environment]::GetEnvironmentVariable("Path","Machine")
	$currentpath -split ";"
}

Function Set-MachinePathItems ([Parameter(ValueFromPipeline = $true)]$pathitems)
{
	Begin {
		$joined = @()
	}
	Process {
		foreach ($pathitem in $pathitems) {
			$joined += $pathitem 
		}
	}
	End {
		$newpath = [string]::join(";", $joined)	
		Write-Host "Setting Machine Path : $newpath"
		[Environment]::SetEnvironmentVariable("Path", $newpath, "Machine")
	}
}

Function Remove-PathItems ([Parameter(ValueFromPipeline = $true)]$pathitems, $regex)
{
	Process {
		foreach ($pathitem in $pathitems) {
			if (!($pathitem -match $regex)) { $pathitem }
		}
	}
}

Function Add-PathItems ( [Parameter(ValueFromPipeline = $true)] $pathitems, $New)
{
	Process {
		foreach ($pathitem in $pathitems) {
			$pathitem
		}
	}
	End {
		$New
	}
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

Function Create-DevToolsShortcut($LinkName, $TargetPath, $Arguments)
{
	$DevToolsDir = "{0}\DevTools" -f [System.Environment]::GetFolderPath("StartMenu")
	CheckCreateDirectory $DevToolsDir	
	$objShell = New-Object -com "Wscript.Shell"
	$objShortcut = $objShell.CreateShortcut($DevToolsDir + "\$LinkName.lnk")
	$objShortcut.TargetPath = "$TargetPath"
	$objShortcut.Arguments = "$Arguments"	
	$objShortcut.Save()
}


Function Set-MachineInfo
{
	$Win32_OS = gwmi Win32_OperatingSystem 

	## Get the OS build
	switch ($Win32_OS.BuildNumber) {
		## the break statement will stop at the first match
		2600 {$OS = "XP"; break}
		3790 { if ($Win32_OS.caption -match "XP") { $OS = "XP" } else { $OS = "W2003" }; break }
		6000 {$OS = "Vista"; break}
		6001 { if ($Win32_OS.caption -match "Vista" ) { $os = "Vista" } else { $OS = "W2008"}; break }
		7600 {$OS = "Win7"}
	}

	$OS_SP = $Win32_OS.ServicePackMajorVersion
	
	$proc = gwmi Win32_Processor
	
	switch ($proc.Architecture)
	{
	  0 {$CPU_ARCH = "x86"}
	  1 {$CPU_ARCH = "MIPS"}
	  2 {$CPU_ARCH = "Alpha"}
	  3 {$CPU_ARCH = "PowerPC"}
	  6 {$CPU_ARCH = "Itanium"}
	  9 {$CPU_ARCH = "x64"}
	}
	
	switch ($proc.AddressWidth)
	{
	  32 {$OS_BITS = "32-bit"}
	  64 {$OS_BITS = "64-bit"}
	}
	
	Write-Host "Machine : $OS Service Pack $OS_SP $OS_BITS on $CPU_ARCH"
}

Function Get-UniqueFileName($dir, $pattern)
{
	$files = @(dir $dir -filter $pattern)
	
	if ($files.count -eq 1) {
		$files[0].FullName
	}
	else {
		throw "Error : Could not file unique file matching $pattern in directory $dir"
	}
		
}

Function Install-MSI($msifilename)
{
	Write-Host "Installing from $msifilename"
	msiexec /qb /i $msifilename
}


Function List-TemplateParams ( $filename )
{
	Get-Content $filename | Select-String "%%(.*?)%%" | foreach { $_.Matches[0].Groups[1].Value} | Sort | Get-Unique
}

Function Replace-Template ( [Parameter(ValueFromPipeline = $true)]$instrs, $params )
{
	Process {
		foreach ($instr in $instrs) {
			$parts = [regex]::split($instr, '(%%.*?%%)')
			$cparts = $parts.length
		
			for($i = 0; $i -lt $cparts; $i++) {
				$part = $parts[$i]
				if ($part -match "^%%(.*)%%$") {
					$key = $matches[1] 
					# TBD - ADD WARNING IF KEY NOT PRESENT
					$parts[$i] = $params[$key]
				}
			}
			$parts -join ""
		}
	}
}
