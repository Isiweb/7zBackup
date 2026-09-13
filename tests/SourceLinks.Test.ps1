# Test for the links from the root dir to the sources (New-SymLink).
# Local sources must get a junction, which needs no admin rights. Network sources
# (UNC paths, network drives) need a symbolic link: junctions can not point there.
#
# Usage: powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests\SourceLinks.Test.ps1

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

Write-Host "`n Case: network or local path"
# A missing function would skip each Assert line silently (SilentlyContinue)
Assert ($null -ne (Get-Command Test-NetworkPath)) "Test-NetworkPath exists"
Assert ((Test-NetworkPath "\\server\share\folder") -eq $True) "a UNC path is a network path"
Assert ((Test-NetworkPath $env:SystemRoot) -eq $False)        "the Windows folder is local"

Write-Host "`n Case: local source, no admin rights"
$work = Join-Path $env:TEMP ("7zb-test-" + [guid]::NewGuid().ToString("N").Substring(0, 8))
New-Item -ItemType Directory "$work\root", "$work\source" -Force | Out-Null
Set-Content -LiteralPath "$work\source\file.txt" -Value "x"
$link = "$work\root\Alias"

$linked = New-SymLink $link "$work\source"
Assert ($linked -eq $True)                                                  "the link is created [$linked]"
Assert ((Get-Item -LiteralPath $link -Force).LinkType -eq "Junction")       "the link is a junction [$((Get-Item -LiteralPath $link -Force).LinkType)]"
Assert (Test-Path -LiteralPath "$link\file.txt")                            "files are reachable through the link"

If(Test-Path -LiteralPath $link) { cmd /c "rd `"$link`"" }
Remove-Item -LiteralPath $work -Recurse -Force

Write-Host ""
If($Failures -gt 0) { Write-Host " $Failures assertion(s) failed" -ForegroundColor Red; exit 1 }
Write-Host " All assertions passed" -ForegroundColor Green
exit 0
