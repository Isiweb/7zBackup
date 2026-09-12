# Integration tests for ProcessFolder (selection scan).
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

# The script body loop that walks catalogFolders: the scan runs it, not a copy that could drift from it
$scanLoop = @($ast.EndBlock.Statements | Where-Object { $_ -is [System.Management.Automation.Language.WhileStatementAst] -and $_.Extent.Text.Contains('ProcessFolder $catalogFolders') })
Assert ($scanLoop.Count -eq 1) "precondition, scan loop found in the script body"

Function New-WorkDir {
	$work = Join-Path $env:TEMP ("7zb-test-" + [guid]::NewGuid().ToString("N").Substring(0, 8))
	New-Item -ItemType Directory $work -Force | Out-Null
	Write-Output $work
}

# Scans $source aliased as $aliasName the way the 7zBackup.ps1 script body does.
# Returns the lines written to the inclusion catalog; exclusions are left in $work\Exclusions.txt.
Function Invoke-Scan ([string]$work, [string]$source, [switch]$lowerCaseDrive, [string]$aliasName = "Alias") {
	$script:BkRootDir = Join-Path $work "root"
	# --workdrive accepts a lowercase letter: the root dir path then differs in case from paths PowerShell returns
	If($lowerCaseDrive) { $script:BkRootDir = $script:BkRootDir.Substring(0, 1).ToLower() + $script:BkRootDir.Substring(1) }
	New-Item -ItemType Directory $script:BkRootDir -Force | Out-Null
	# 7zBackup.ps1 links each source into the root dir: a junction does the same without admin rights
	cmd /c "mklink /J `"$script:BkRootDir\$aliasName`" `"$source`"" | Out-Null

	$script:BkSources = @{ $aliasName = $source }
	$script:Counters  = @{ Exclusions = 0; Exceptions = 0; FoldersDone = 0; FilesProcessed = 0; FilesSelected = 0; BytesSelected = [int64]0; PlaceHolders = @() }
	$script:MyContext = [hashtable]::Synchronized(@{ Cancelling = $False; Logger = (New-Object System.Text.StringBuilder); SelectionStart = (Get-Date) })
	$inclusions       = Join-Path $work "Catalog-Include.txt"
	$script:SWriters  = @{ Inclusions = (New-Object System.IO.StreamWriter($inclusions, $False, [System.Text.Encoding]::UTF8)) }
	foreach ($name in "Exclusions", "Exceptions", "Stats") { $script:SWriters[$name] = New-Object System.IO.StreamWriter((Join-Path $work "$name.txt"), $False, [System.Text.Encoding]::ASCII) }

	$script:catalogFolders      = New-Object System.Collections.ArrayList
	$script:catalogFoldersIndex = 0
	[void]$script:catalogFolders.Add(@{ Name = $aliasName; FullName = "$script:BkRootDir\$aliasName"; RelativeName = $aliasName; ContainerAlias = $aliasName; RealName = $source; Depth = 0 })
	Set-Location -Path $script:BkRootDir
	# Dot-sourced in this function, the loop increments a local copy of catalogFoldersIndex: it starts from 0 all the same
	. ([scriptblock]::Create($scanLoop[0].Extent.Text))
	Set-Location -Path $env:TEMP
	$script:SWriters.Values | ForEach-Object { $_.Close() }
	cmd /c "rd `"$script:BkRootDir\$aliasName`""
	Write-Output @(Get-Content -LiteralPath $inclusions -Encoding UTF8)
}

# -----------------------------------------------------------------------------
Write-Host "`n Case: nofollowjunctions must not drop folders enumerated after a skipped junction"
$work   = New-WorkDir
$source = Join-Path $work "source"
# source\Parent holds AJunction (enumerated first, points outside), B and C
New-Item -ItemType Directory "$source\Parent\B", "$source\Parent\C", "$work\elsewhere" -Force | Out-Null
Set-Content -LiteralPath "$source\Parent\B\b.txt" -Value "b"
Set-Content -LiteralPath "$source\Parent\C\c.txt" -Value "c"
Set-Content -LiteralPath "$work\elsewhere\e.txt" -Value "e"
cmd /c "mklink /J `"$source\Parent\AJunction`" `"$work\elsewhere`"" | Out-Null
Assert ([int]((Get-Item -LiteralPath "$source\Parent\AJunction" -Force).Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) "precondition, AJunction is a junction"

$BkType = "full"; $BkNoFollowJunctions = $True; $BkDryRun = $False; $matchcleanupfiles = $null
$included = @(Invoke-Scan $work $source)
$excluded = @(Get-Content -LiteralPath "$work\Exclusions.txt")
Assert ($included -contains "Alias\Parent\B\b.txt") "file in B (after the skipped junction) is selected"
Assert ($included -contains "Alias\Parent\C\c.txt") "file in C (after the skipped junction) is selected"
Assert (@($included -like "*e.txt").Count -eq 0)    "file behind the skipped junction is not selected"
Assert (@($excluded | Where-Object { $_.EndsWith("`tnofollowjunctions`tD`t$source\Parent\AJunction") }).Count -eq 1) "the skipped junction itself is named in the exclusion log"

cmd /c "rd `"$source\Parent\AJunction`""
Remove-Item -LiteralPath $work -Recurse -Force

# -----------------------------------------------------------------------------
foreach ($dryRun in $False, $True) {
	Write-Host "`n Case: matchcleanupfiles (dry run = $dryRun)"
	$work   = New-WorkDir
	$source = Join-Path $work "source"
	New-Item -ItemType Directory $source -Force | Out-Null
	Set-Content -LiteralPath "$source\junk.tmp" -Value "junk"
	Set-Content -LiteralPath "$source\keep.txt" -Value "keep"

	$BkType = "full"; $BkNoFollowJunctions = $False; $BkDryRun = $dryRun; $matchcleanupfiles = '\.tmp$'
	$included = @(Invoke-Scan $work $source)
	If($dryRun) {
		Assert (Test-Path -LiteralPath "$source\junk.tmp")  "dry run: matching file stays on disk"
	} Else {
		Assert (!(Test-Path -LiteralPath "$source\junk.tmp")) "matching file is deleted from source"
	}
	Assert (!($included -contains "Alias\junk.tmp"))  "matching file is not selected for the archive"
	Assert (Test-Path -LiteralPath "$source\keep.txt") "other file stays on disk"
	Assert ($included -contains "Alias\keep.txt")      "other file is selected"
	Assert ($Counters.FoldersDone -eq 1)               "the only folder is scanned once [$($Counters.FoldersDone)]"

	Remove-Item -LiteralPath $work -Recurse -Force
}

# -----------------------------------------------------------------------------
Write-Host "`n Case: root dir on a lowercase drive letter (--workdrive c)"
$work   = New-WorkDir
$source = Join-Path $work "source"
New-Item -ItemType Directory "$source\sub", "$source\skip" -Force | Out-Null
Set-Content -LiteralPath "$source\sub\deep.txt" -Value "deep"
Set-Content -LiteralPath "$source\skip\skipped.txt" -Value "skipped"

$BkType = "full"; $BkNoFollowJunctions = $False; $BkDryRun = $False; $matchcleanupfiles = $null; $matchexcludepath = '^Alias\\skip$'
$included = @(Invoke-Scan $work $source -lowerCaseDrive)
Assert ($included -contains "Alias\sub\deep.txt")      "file in a subfolder is selected with its path relative to the root dir"
Assert (@($included -like "*skipped.txt").Count -eq 0) "matchexcludepath anchored on the alias still excludes its folder"

Remove-Item -LiteralPath $work -Recurse -Force

# -----------------------------------------------------------------------------
Write-Host "`n Case: real path in the exclusion log when a folder name contains the alias (alias Docs, folder MyDocs)"
$work   = New-WorkDir
$source = Join-Path $work "source"
New-Item -ItemType Directory "$source\MyDocs\sub" -Force | Out-Null
Set-Content -LiteralPath "$source\MyDocs\sub\f.txt" -Value "f"

$BkType = "full"; $BkNoFollowJunctions = $False; $BkDryRun = $False; $matchcleanupfiles = $null; $matchexcludepath = '^Docs\\MyDocs\\sub$'
$included = @(Invoke-Scan $work $source -aliasName "Docs")
$excluded = @(Get-Content -LiteralPath "$work\Exclusions.txt")
Assert (@($excluded | Where-Object { $_.EndsWith("`tmatchexcludepath`tD`t$source\MyDocs\sub") }).Count -eq 1) "excluded folder is logged with its real path [$($excluded -join ' | ')]"

Remove-Item -LiteralPath $work -Recurse -Force

Write-Host ""
If($Failures -gt 0) { Write-Host " $Failures assertion(s) failed" -ForegroundColor Red; exit 1 }
Write-Host " All assertions passed" -ForegroundColor Green
exit 0
