# Integration test for Send-Notification error reporting.
# When the SMTP server can not be reached, the message must say why.
#
# Usage: powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests\SendNotification.Test.ps1

$ErrorActionPreference = "SilentlyContinue"   # same as 7zBackup.ps1

# Load function definitions only: the script body is not executed
$scriptFile = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\7zBackup.ps1"))
$ast = [System.Management.Automation.Language.Parser]::ParseFile($scriptFile, [ref]$null, [ref]$null)
foreach ($fn in $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $False)) {
	. ([scriptblock]::Create($fn.Extent.Text))
}

$Failures = 0
Function Assert ([bool]$condition, [string]$message) {
	If($condition) { Write-Host " PASS : $message" -ForegroundColor Green }
	Else { Write-Host " FAIL : $message" -ForegroundColor Red; $script:Failures++ }
}

Write-Host "`n Case: SMTP server not reachable (127.0.0.1, port 1)"
$SWriters      = @{}
$Counters      = @{ Warnings = 0; Criticals = 0 }
$MyContext     = [hashtable]::Synchronized(@{ Logger = (New-Object System.Text.StringBuilder) })
$BkNotifyLog   = @("ops@example.com")
$BkSmtpFrom    = "backup@example.com"
$BkSmtpRelay   = "127.0.0.1"
$BkSmtpPort    = 1
$BkNotifyExtra = "none"

# Send-Notification writes to the console: capture the information stream
$output = (Send-Notification 6>&1 | Out-String)

Assert ($output.Contains("Unable to send notification email"))       "failure is reported"
Assert ($output -match 'Unable to send notification email : \S')     "the report names the reason [$($output.Trim() -replace '\s+', ' ')]"

Write-Host ""
If($Failures -gt 0) { Write-Host " $Failures assertion(s) failed" -ForegroundColor Red; exit 1 }
Write-Host " All assertions passed" -ForegroundColor Green
exit 0
