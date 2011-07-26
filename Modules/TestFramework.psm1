<#
Copyright : Samir K Seth
License : Apache 2.0
Source : https://github.com/samirkseth/PSAdmin
#>


# This test cannot be run in a script because it prompts for missing parameter, as expected.
# Test.GetUsersInLocalGroupReturnsErrorOnNullGroup 

Function Assert-Throws([string]$regex, [scriptblock] $testblock)
{
	$ExceptionRaised = $false
	Write-Verbose "Starting Assert-Throws for $regex"
	try {
		& $testblock
	}
	catch [Exception] {
		$ExceptionRaised = $true
		Write-Verbose ("Assert-Throws got an exception {0}" -f $_.Exception.Message)
		if (!($_.Exception.Message -match $regex)) {
			throw ("Expected Error `"{0}`" but got `"{1}`"" -f $regex, $_.Exception.Message)
		}
	}
	
	if (!$ExceptionRaised) {
			throw ("Expected Error `"{0}`" but did not get it." -f $regex) 
	}
}

Function Run-Test ($module, [scriptblock] $testscript)
{
	$mod = Get-Module $module
	
	$mod.Invoke({
		& $testscript
	})
}

Function New-TestModule($funcnames)
{
	$modbody = "New-Module -ScriptBlock {"
	foreach ($funcname in $funcnames)
	{
		if ($funcname -match "^(.*):(.*)$") {
			$modulename = $matches[1]
			$funcname = $matches[2]
			$module = get-module -Name $modulename
			$func = & $module Get-Item function:$funcname		
		}
		else {
			$func = Get-Item function:$funcname		
		}
				
		$funcbody = "`nfunction " + $func.Name + " {" + $func.Definition + "}`n"
		
		$modbody += $funcbody
	}
	
	$modbody += "}"
	
	iex $modbody
}

Function With-TestModule([string[]]$funcnames, [scriptblock] $testcode)
{
	$mod = New-TestModule $funcnames
	
	& $mod $testcode
} 

# borrowed from psake
Function Assert
{
    [CmdletBinding()]
    param(
        [Parameter(Position=0,Mandatory=1)]$conditionToCheck,
        [Parameter(Position=1,Mandatory=1)]$failureMessage
    )
    if (!$conditionToCheck) { 
        throw ("Assert: " + $failureMessage) 
    }
}

Function Assert-Equals($firstval,$secondval,$message)
{
	Assert ($firstval -eq $secondval) ($message -f $firstval,$secondval)
}

Function Assert-ArrayEquals($firstarray,$secondarray,$message)
{
	$firststr = $firstarray -join ","
	$secondstr = $secondarray -join ","
	Assert ((Compare-Object -ReferenceObject $firstarray -DifferenceObject $secondarray) -eq $null) ($message -f $firststr,$secondstr)
}

Function Run-Test($TestFunctionName)
{	
	try {
		& $TestFunctionName
		Write-Host "$TestFunctionName OK" -foregroundcolor White
	}
	catch [Exception] {
		Write-Host "$TestFunctionName FAILED" -foregroundcolor Red
		Write-Host ("{0}" -f $_.Exception.Message) -foregroundcolor Red
	}
}

Function Run-Tests ([string]$msg, [string[]]$TestFunctionNames)
{
	Write-Host "`n`n--------- $msg ----------------" -foregroundcolor White

	foreach ($testfunctionname in $TestFunctionNames)
	{
		Run-Test $testfunctionname
	}

	Write-Host "--------- $msg END ------------" -foregroundcolor White
}

