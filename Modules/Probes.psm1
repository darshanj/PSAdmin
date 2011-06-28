$ScriptDir = Split-Path $MyInvocation.MyCommand.Path -Parent
Import-Module "$PSScriptRoot\WindowsUtils.psm1" -DisableNameChecking -Force
Import-Module "$PSScriptRoot\DBUtils.psm1" -DisableNameChecking -Force
Import-Module "$PSScriptRoot\BizTalkUtils.psm1" -DisableNameChecking -Force
$STATUS_UP = "UP"
$STATUS_DOWN = "DOWN"
$ENVMONITOR_URL = "http://envmonitor.tw.testttl.com/Health/New"

$TraCSInstallDir = "C:\TraCSdotnet"
Add-Type -AssemblyName System.Web

function Probe-BizTalkApplications
{
	$Private:TimeStamp = Get-Date -format "yyyy-MM-hhTHH:mm:sszzz"
	$Private:Note = ""
	$Private:Status = $STATUS_DOWN
	Try { 
			
			$Status = Check-Applications
			
			Write-Verbose "Generating report for BizTalk Applications" 
            			
		} 
	Catch { 
			$Note = "Error $_.message"
		}
    Finally {
		$report = @{ 
			ProbeName = "BizTalk Applications"
			Status = $Status
			Note = $Note
			TimeStamp = $TimeStamp
    	}  
		addProbe $report
	}
}
function Probe-BizTalkOrchestrations
{
	$Private:TimeStamp = Get-Date -format "yyyy-MM-hhTHH:mm:sszzz"
	$Private:Note = ""
	$Private:Status = $STATUS_DOWN
	Try { 
			
			$Status = Check-Orchestrations
			
			Write-Verbose "Generating report for BizTalk Orchestrations" 
            			
		} 
	Catch { 
			$Note = "Error $_.message"
		}
    Finally {
		$report = @{ 
			ProbeName = "BizTalk Orchestrations"
			Status = $Status
			Note = $Note
			TimeStamp = $TimeStamp
    	}  
		addProbe $report
	}
}

function Probe-BizTalkSendPorts
{	
	$Private:TimeStamp = Get-Date -format "yyyy-MM-hhTHH:mm:sszzz" 
	$Private:Note = ""
	$Private:Status = $STATUS_DOWN
	Try { 
			
			$Status = Check-SendPorts
			
			Write-Verbose "Generating report for BizTalk SendPorts" 
            			
		} 
	Catch { 
			$Note = "Error $_.message"
		}
    Finally {
		$report = @{ 
			ProbeName = "BizTalk SendPorts"
			Status = $Status
			Note = $Note
			TimeStamp = $TimeStamp
    	}  
		addProbe $report
	}
}

function Probe-BizTalkHostInstances
{
	$Private:TimeStamp = Get-Date -format "yyyy-MM-hhTHH:mm:sszzz" 
	$Private:Note = ""
	$Private:Status = $STATUS_DOWN
	Try { 
			
			$Status = Check-HostInstances
			
			Write-Verbose "Generating report for BizTalk Host-Instances" 
            			
		} 
	Catch { 
			$Note = "Error $_.message"
		}
    Finally {
		$report = @{ 
			ProbeName = "BizTalk Host-Instances"
			Status = $Status
			Note = $Note
			TimeStamp = $TimeStamp
    	}  
		addProbe $report
	}
}

function Probe-Services($services)
{
	foreach ($service in @($services))
	{
		Probe-Service-Running $service
	}
}

function Probe-Processes($processes)
{
	foreach ($process in @($processes))
	{
		Probe-Process-Running $process
	}
}

function Init-Probes()
{
	Write-Host "Init-Probes : Starting health check for Machine:$machine Environment:$env MachineType:$machinetype"

	$Private:TimeStamp = Get-Date -format "yyyy-MM-hhTHH:mm:sszzz"
	[xml]$script:probes = "<MachineHealth><ID><EnvName>$env</EnvName><MachineName>$machine</MachineName></ID><Health><TimeStamp>$Timestamp</TimeStamp><Status>UP</Status></Health><Probes></Probes><Parameters></Parameters></MachineHealth>"
	
	
}

function addProbe($report)
{
    $newprobe = $script:probes.CreateElement("Probe")
	$Name = $report.ProbeName
	$Status = $report.Status
	$Note = $report.Note
	$Timestamp = $report.TimeStamp
	$innerXML="<Name>$Name</Name><Health><Status>$Status</Status><TimeStamp>$Timestamp</TimeStamp></Health><Note>$Note</Note>"
	$newprobe.set_InnerXml($innerXML)
	$parent = @($script:probes.SelectNodes("//Probes"))[0]
	$parent.AppendChild($newprobe)
}


function addParameter($name, $value, $level)
{
	Write-Host "Adding Parameter $name, $value, $level"

    $newparam = $script:probes.CreateElement("Parameter")
	$innerXML="<Name>$name</Name><Value>$value</Value><Level>$level</Level>"
	$newparam.set_InnerXml($innerXML)
	$parent = @($script:probes.SelectNodes("//Parameters"))[0]
	$parent.AppendChild($newparam)
}

function Save-ProbesXML($filename)
{
	
	$script:probes.get_outerXml() | Out-File "$filename"
}


function Probe-Service-Running ($servicename)
{
	$Private:ProbeName = "$servicename Service"
    $Private:TimeStamp = Get-Date -format "yyyy-MM-hhTHH:mm:sszzz" 
    $Private:Status = $STATUS_DOWN
	$Private:Note =""
	Try { 
			
			$service = Get-Service $servicename
			$Status = if ( $service.status -eq "Running" ) {$STATUS_UP} else {$STATUS_DOWN}
			
			Write-Verbose "Generating report for service $servicename" 
            			
		} 
	Catch { 
			$Note = "Error $_.message"
		}
    Finally {
		$report = @{ 
			ProbeName = $ProbeName
			Status = $Status
			Note = $Note
			TimeStamp = $TimeStamp
    	}  
		addProbe $report
	}
} 



function Probe-Process-Running ($processname)
{
	$Private:ProbeName = "$processname Process"
    $Private:TimeStamp = Get-Date -format "yyyy-MM-hhTHH:mm:sszzz" 
    $Private:Status = $STATUS_DOWN
	$Private:Note =""
	Try { 
			$process = Get-Process | Where-Object {$_.ProcessName -eq $processname}
			if($process)
			{
				$Status = $STATUS_UP 
			}
			Write-Verbose "Generating report for process $processname" 
            			
		} 
	Catch { 
			$Note = "Error $_.message"
		}
    Finally {
		$report = @{ 
			ProbeName = $ProbeName
			Status = $Status
			Note = $Note
			TimeStamp = $TimeStamp
    	}  
		addProbe $report
	}
} 



function Probe-ConnectionToPort ($server,$port)
{
	$Private:ProbeName = "Connection to $server : $port"
    $Private:TimeStamp = Get-Date -format "yyyy-MM-hhTHH:mm:sszzz" 
    $Private:Status = $STATUS_DOWN
	$Private:Note =""
	Try { 
			$Status = if (QuickPing $server $port) {$STATUS_UP}
		
			Write-Verbose "Generating report for Connection to $server : $port" 
		} 
	Catch { 
			$Note = "Error $_.message"
		}
    Finally {
		$report = @{ 
			ProbeName = $ProbeName
			Status = $Status
			Note = $Note
			TimeStamp = $TimeStamp
    	}  
		addProbe $report
	}
} 

function Probe-CheckIPTIS()
{
	[xml] $jascfg = Get-Content "$TraCSInstallDir\JourneyAvailabilityService\Web.config"
	$ConnectionString = $jascfg.configuration.TraCS.Infrastructure.DATABASE_CONNECTION
	$Query = "select PARAMETER_VALUE from parameters where PARAMETER_NAME in ('IPTIS_REQUEST','IPTIS_RESPONSE') and ENV_ID=1"
	$result= Execute-Oracle-Sql $ConnectionString $Query
	$iptis =Split-Path $result[1].PARAMETER_VALUE
	Probe-ConnectionToPort "$iptis.tw.testttl.com" 80 
}

function Probe-CheckNRS()
{
	[xml] $jascfg = Get-Content "$TraCSInstallDir\JourneyAvailabilityService\Web.config"
	$NRSUrl = $jascfg.configuration.TraCS.NRS.URL 
	Probe-ConnectionToPort $NRSUrl 80 
	
}



Function Post-Probe
{
	
	
	$result = $null
	$xmldoc = $script:probes.get_outerXml() 
	$probexml = [System.Web.HttpUtility]::UrlEncode($xmldoc)

	# Set up request
	[System.Net.HttpWebRequest] $request = [System.Net.HttpWebRequest] [System.Net.WebRequest]::Create($ENVMONITOR_URL)
	
	$request.Method = "POST"
	$request.PreAuthenticate = $true;
	$request.ServicePoint.Expect100Continue = $false
	$request.ContentType = "application/x-www-form-urlencoded"
	$buffer = "probeXML={0}" -f $probexml
	$request.ContentLength = $buffer.Length
    $request.Credentials = [System.Net.CredentialCache]::DefaultCredentials;

	
	# Send the request
	[System.IO.StreamWriter] $stOut = new-object System.IO.StreamWriter($request.GetRequestStream(), [System.Text.Encoding]::ASCII)
	$stOut.Write($buffer)
	$stOut.Close()
	
	[System.Net.HttpWebResponse] $response = [System.Net.HttpWebResponse] $request.GetResponse()

    if ($response.StatusCode -ne 200)
	{
        $result = "Error : " + $response.StatusCode + " : " + $response.StatusDescription
    }
	else {
		Write-Host "Post Successful"
	}
}
