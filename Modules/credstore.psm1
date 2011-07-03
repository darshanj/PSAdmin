# CredStore
# Copyright (c) 2011 Samir Seth
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# Acknowledgement : This notice / structure Inspired by psake from James Kovacs
# Requires -Version 2.0
# Ensure that only one instance of the psake module is loaded 

###########################################################################
# Bare minimum for all scripts :
# Error Handling : Debug, Warn, Error
# Assert (use psake)
# Configuration
# Credential Management
#
##############################################################################

remove-module credstore -erroraction silentlycontinue

#-- Public Module Functions --#
# .ExternalHelp  credstore.psm1-help.xml

$key = @()
for ($i = 0; $i -lt 32; $i++) {
	$key += 6
}

$key.length


Function New-Credential ($role, $purpose) 
{
	$newcred = $host.ui.PromptForCredential("$role", "$purpose", "", "")	
	$newcred
	$newcred.GetNetworkCredential()

	$encpass = $newcred.Password | ConvertFrom-SecureString -key $key
	
	"Encrypted Pass : $encpass"
	
	$resecpass = $encpass | ConvertTo-SecureString -key $key
	
	$copycred = new-object System.Management.Automation.PSCredential "TWTTl\Brainline", $resecpass
	
	$copycred.GetNetworkCredential()
}

DATA msgs {
convertfrom-stringdata @'
    credential_location_invalid = Cannot find credential path
'@
} 

import-localizeddata -bindingvariable msgs -erroraction silentlycontinue

$script:credstore = @{}
$credstore.location = "~\credentials" # indicates that the current build was successful

export-modulemember -function invoke-psake, invoke-task, task, properties, include, formattaskname, tasksetup, taskteardown, assert, exec -variable credstore