$ScriptDir =  Split-Path -Parent $myinvocation.mycommand.path

remove-module psake -ea SilentlyContinue
import-module "$ScriptDir\Modules\psake.psm1"
import-module "$ScriptDir\Modules\Install.psm1"

invoke-psake "$ScriptDir\machinebuild.ps1" WebBuild  -parameters @{"p_env"="U01E2E"}
