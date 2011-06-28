
$script:CRUISEUID="samir"
$script:CRUISEPWD="badger"

#needs to be set as a parameter
$script:CRUISEADMINURL="http://localhost:8153/go/api/admin"
$script:PIPELINEGROUP="VM"
$script:CRUISECONFIG=""
$script:CRUISECONFIGHASH=""

Add-Type -AssemblyName System.Web

Function Start-CruiseConfig
{
	$web = New-Object Net.WebClient
	$web.Credentials = New-Object System.Net.NetworkCredential($CRUISEUID, $CRUISEPWD)
	
	[xml]$script:CRUISECONFIG = $web.DownloadString("$CRUISEADMINURL/config.xml")
		
	$script:CRUISECONFIGHASH = $web.ResponseHeaders["X-CRUISE-CONFIG-MD5"]
	
	Write-Host $script:CRUISECONFIGHASH
}

Function Show-CruiseConfig
{
	Write-Host $script:CRUISECONFIG.get_OuterXml()
}

Function Save-CruiseConfig
{
	$commiturl = "http://SAMIR-PC:8153/go/admin/configuration/file.xml"
	
	$result = $null
	$xmlContent = [System.Web.HttpUtility]::UrlEncode($script:CRUISECONFIG.get_OuterXml())
	$md5 = [System.Web.HttpUtility]::UrlEncode($CRUISECONFIGHASH)

	# Set up request
	[System.Net.HttpWebRequest] $request = [System.Net.HttpWebRequest] [System.Net.WebRequest]::Create($commiturl)
	
	$request.Method = "POST"
	$request.PreAuthenticate = $true;
	$request.ServicePoint.Expect100Continue = $false
	$request.ContentType = "application/x-www-form-urlencoded"
	$buffer = "xmlFile={0}&md5={1}" -f $xmlContent, $md5
	$request.ContentLength = $buffer.Length
	$Credential = new-object System.Net.NetworkCredential("samir", "password")
	$request.Credentials = $Credential
	$request.Headers.Add("Authorization", "Basic " + [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("samir:badger")));
	
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

Function New-Pipeline([String] $Group, [String] $Name )
{	
	$pipeline = $script:CRUISECONFIG.CreateElement("pipeline")
	$pipeline.SetAttribute("name", "$Name")
	$pipeline.SetAttribute("labeltemplate", "$Name-`${COUNT}")
	$pipeline.SetAttribute("isLocked", "false")

    $pipelineInnerXML = @"
<materials>
	<svn url="https://samir-pc.corporate.thoughtworks.com/svn/GoPS/" username="samir" encryptedPassword="ruRUF0mi2ia/BWpWMISbjQ==" autoUpdate="false" />
</materials>	
"@
	$pipeline.set_InnerXml($pipelineInnerXML)
	
	$pipelinegroup = @($CRUISECONFIG.SelectNodes("/cruise/pipelines[@group='$Group']"))[0]
	# TBD - Check if pipeline group is missing - then add
	$pipelinegroup.AppendChild($pipeline)
}

Function New-Stage($Pipeline, [String] $Name )
{	
	$stage = $script:CRUISECONFIG.CreateElement("stage")
	$stage.SetAttribute("name", "$Name");
	$stage.SetAttribute("fetchMaterials", "false");

	$stageInnerXML = @"
<jobs>
</jobs>
"@
	$stage.set_InnerXML($stageInnerXML)
	
	# TBD - Check if pipeline group is missing - then add
	$Pipeline.AppendChild($stage)
}

Function New-Job($Stage, [String] $Name, [String] $Command, [String] $Cmdargs )
{	
	$job = $script:CRUISECONFIG.CreateElement("job")
	$job.SetAttribute("name", "$Name");

	$jobInnerXML = @"
<tasks>
  <exec command="$Command" args="$Cmdargs">
	<runif status="any" />
  </exec>
</tasks>
"@

	$job.set_InnerXML($jobInnerXML)
	# TBD - Check if pipeline group is missing - then add
	$Stage.jobs.AppendChild($job)
}

$pipelineexample = @"
  <pipelines group="VM">
    <pipeline name="test2" labeltemplate="Test2-${COUNT}" isLocked="false">
      <materials>
        <svn url="https://samir-pc.corporate.thoughtworks.com/svn/GoPS/" username="samir" encryptedPassword="ruRUF0mi2ia/BWpWMISbjQ==" autoUpdate="false" />
      </materials>
      <stage name="Stage1" fetchMaterials="false">
        <jobs>
          <job name="Job1" runOnAllAgents="true">
            <tasks>
              <exec command="powershell" args="C:\TLSETUP\Test.ps1">
                <runif status="any" />
              </exec>
            </tasks>
          </job>
        </jobs>
      </stage>
    </pipeline>
  </pipelines>
"@

Function Create-EnvironmentPipeline($envname)
{
    $envconffile = "{0}\$envname.conf" -f $script:CONF
	[xml] $env = Get-Content $envconffile
	
	Start-CruiseConfig
	
	$pipeline = New-Pipeline -Group "VM" -Name "Create_$envname"
	
	$stg_createfolder = New-Stage -Pipeline $pipeline -Name "Initialize_VMWare"	
	New-Job -Stage $stg_createfolder -Name "Create_Environment_Folder" -Command "Powershell" -Cmdargs "C:\TLSETUP\CreateVMWareFolder.ps1 '$envname'"
	
	$stg_createvms = New-Stage -Pipeline $pipeline -Name "Create_VMs"
	
	foreach ($machinetypeentry in $env.Environment.Machines.Machine)
	{
		$machinetype = $machinetypeentry.Type
		$qty = $machinetypeentry.Quantity
			
		for ($i = 1; $i -le $qty; $i++) 
		{
			$machinename = "{0}{1:0#}.{2}" -f $machinetypeentry.BaseName, $i, $env.Environment.name
			New-Job -Stage $stg_createvms  -Name "Create_$machinename" -Command "Powershell" -Cmdargs "C:\TLSETUP\CreateVM.ps1 $machinename $env.Environment.name" | Out-Null
		}
	}
	
	Show-CruiseConfig
	Save-CruiseConfig
}


Export-ModuleMember -function * -variable CRUISECONFIG, CRUISECONFIGHASH


