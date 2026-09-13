# Integration test for the pre-Vista junction helpers (New-Junction, Remove-Junction).
# Junction.exe (Sysinternals) is replaced by a small .cmd stand-in that creates
# and removes a real junction with mklink /J and rd, receiving the same arguments.
#
# Usage: powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests\Junction.Test.ps1

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

$work = Join-Path $env:TEMP ("7zb-test-" + [guid]::NewGuid().ToString("N").Substring(0, 8))
New-Item -ItemType Directory "$work\data" -Force | Out-Null
Set-Content -LiteralPath "$work\data\precious.txt" -Value "data"

# Stand-in for: junction.exe /accepteula <link> <target>   and   junction.exe /accepteula -d <link>
$BkJunctionBin = Join-Path $work "junction.cmd"
Set-Content -LiteralPath $BkJunctionBin -Encoding Ascii -Value @(
	'@echo off',
	'if /i "%~2"=="-d" (rd "%~3") else (mklink /J "%~2" "%~3" >nul)'
)

$link = Join-Path $work "link"

Write-Host "`n Case: New-Junction"
Assert ($null -eq (Get-Variable -Name Target -ErrorAction SilentlyContinue)) "precondition, no `$Target variable the function could pick up by accident"
$made = New-Junction $link "$work\data"
Assert ($made -eq $True)                                  "New-Junction reports success"
Assert (Test-Path -LiteralPath "$link\precious.txt")      "the junction points to the given target"

Write-Host "`n Case: Remove-Junction"
# Own junction, so this case does not depend on New-Junction
$link2 = Join-Path $work "link2"
cmd /c "mklink /J `"$link2`" `"$work\data`"" | Out-Null
Assert (Test-Path -LiteralPath "$link2\precious.txt")     "precondition, junction created"
$Error.Clear()
$removed = Remove-Junction $link2
Assert ($removed -eq $True)                               "Remove-Junction reports success"
Assert (!(Test-Path -LiteralPath $link2))                 "the junction is removed"
Assert (Test-Path -LiteralPath "$work\data\precious.txt") "data behind the junction is untouched"
Assert (@($Error | Where-Object { $_.FullyQualifiedErrorId -match 'StartSleepCommand' }).Count -eq 0) "no Start-Sleep error"

foreach ($l in $link, $link2) { If(Test-Path -LiteralPath $l) { cmd /c "rd `"$l`"" } }
Remove-Item -LiteralPath $work -Recurse -Force

Write-Host ""
If($Failures -gt 0) { Write-Host " $Failures assertion(s) failed" -ForegroundColor Red; exit 1 }
Write-Host " All assertions passed" -ForegroundColor Green
exit 0
