# Integration test for ProcessFolder.
# With nofollowjunctions, a skipped junction must not make the scan lose
# the folders enumerated after it.
#
# Usage: powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests\ProcessFolder.Test.ps1

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

# source\Parent holds AJunction (enumerated first, points outside), B and C
$work      = Join-Path $env:TEMP ("7zb-test-" + [guid]::NewGuid().ToString("N").Substring(0, 8))
$source    = Join-Path $work "source"
$BkRootDir = Join-Path $work "root"
New-Item -ItemType Directory "$source\Parent\B", "$source\Parent\C", "$work\elsewhere", $BkRootDir -Force | Out-Null
Set-Content -LiteralPath "$source\Parent\B\b.txt" -Value "b"
Set-Content -LiteralPath "$source\Parent\C\c.txt" -Value "c"
Set-Content -LiteralPath "$work\elsewhere\e.txt" -Value "e"
cmd /c "mklink /J `"$source\Parent\AJunction`" `"$work\elsewhere`"" | Out-Null
# 7zBackup.ps1 links each source into the root dir: a junction does the same without admin rights
cmd /c "mklink /J `"$BkRootDir\Alias`" `"$source`"" | Out-Null
Assert ([int]((Get-Item -LiteralPath "$source\Parent\AJunction" -Force).Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) "precondition, AJunction is a junction"

# State ProcessFolder reads from script scope
$BkType              = "full"
$BkNoFollowJunctions = $True
$BkSources           = @{ Alias = $source }
$Counters            = @{ Exclusions = 0; Exceptions = 0; FoldersDone = 0; FilesProcessed = 0; FilesSelected = 0; BytesSelected = [int64]0; PlaceHolders = @() }
$MyContext           = [hashtable]::Synchronized(@{ Cancelling = $False; Logger = (New-Object System.Text.StringBuilder); SelectionStart = (Get-Date) })
$inclusions          = Join-Path $work "Catalog-Include.txt"
$SWriters            = @{ Inclusions = (New-Object System.IO.StreamWriter($inclusions, $False, [System.Text.Encoding]::UTF8)) }
foreach ($name in "Exclusions", "Exceptions", "Stats") { $SWriters[$name] = New-Object System.IO.StreamWriter((Join-Path $work "$name.txt"), $False, [System.Text.Encoding]::ASCII) }

# Queue and scan loop as in the 7zBackup.ps1 script body
$catalogFolders      = New-Object System.Collections.ArrayList
$catalogFoldersIndex = 0
[void]$catalogFolders.Add(@{ Name = "Alias"; FullName = "$BkRootDir\Alias"; RelativeName = "Alias"; ContainerAlias = "Alias"; RealName = $source; Depth = 0 })
Set-Location -Path $BkRootDir
While ($True) {
	If(Check-CTRLCRequest) {break}
	ProcessFolder $catalogFolders[$catalogFoldersIndex] | Out-Null
	If (!(++$catalogFoldersIndex -le $catalogFolders.Count)) {break}
}
Set-Location -Path $env:TEMP
$SWriters.Values | ForEach-Object { $_.Close() }

$included = @(Get-Content -LiteralPath $inclusions -Encoding UTF8)
Assert ($included -contains "Alias\Parent\B\b.txt")    "file in B (after the skipped junction) is selected"
Assert ($included -contains "Alias\Parent\C\c.txt")    "file in C (after the skipped junction) is selected"
Assert (@($included -like "*e.txt").Count -eq 0)       "file behind the skipped junction is not selected"

# Remove junctions first, then the rest
cmd /c "rd `"$BkRootDir\Alias`""
cmd /c "rd `"$source\Parent\AJunction`""
Remove-Item -LiteralPath $work -Recurse -Force

Write-Host ""
If($Failures -gt 0) { Write-Host " $Failures assertion(s) failed" -ForegroundColor Red; exit 1 }
Write-Host " All assertions passed" -ForegroundColor Green
exit 0
