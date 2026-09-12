# Integration test for notification emails sent with MailKit (--mailkitpath).
# A local fake SMTP server records what each client sends. It offers only AUTH
# PLAIN, which System.Net.Mail.SmtpClient does not support: a PLAIN login in
# the transcript proves MailKit sent the message. Without --mailkitpath the
# SmtpClient path must still send.
#
# Downloads the MailKit packages from NuGet once (see MailKitCache.ps1);
# without network access the MailKit case is skipped.
#
# Usage: powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests\MailKitNotification.Test.ps1

$ErrorActionPreference = "SilentlyContinue"   # same as 7zBackup.ps1

# Load function definitions only: the script body is not executed
$scriptFile = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\7zBackup.ps1"))
$ast = [System.Management.Automation.Language.Parser]::ParseFile($scriptFile, [ref]$null, [ref]$null)
foreach ($fn in $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $False)) {
	. ([scriptblock]::Create($fn.Extent.Text))
}
. (Join-Path $PSScriptRoot "MailKitCache.ps1")

$Failures = 0
Function Assert ([bool]$condition, [string]$message) {
	If($condition) { Write-Host " PASS : $message" -ForegroundColor Green }
	Else { Write-Host " FAIL : $message" -ForegroundColor Red; $script:Failures++ }
}

# -----------------------------------------------------------------------------
Write-Host "`n Case: TLS mode for MailKit"
# A missing function would skip each Assert line silently (SilentlyContinue)
Assert ($null -ne (Get-Command Get-MailKitSocketOption)) "Get-MailKitSocketOption exists"
Assert ((Get-MailKitSocketOption 465 $False) -eq "SslOnConnect") "port 465 uses TLS on connect"
Assert ((Get-MailKitSocketOption 465 $True)  -eq "SslOnConnect") "port 465 with smtpssl uses TLS on connect"
Assert ((Get-MailKitSocketOption 587 $True)  -eq "StartTls")     "smtpssl on another port requires STARTTLS"
Assert ((Get-MailKitSocketOption 25 $False)  -eq "None")         "no smtpssl: no TLS, as with SmtpClient"

# -----------------------------------------------------------------------------
# Fake SMTP server: one session at a time, every received line goes to $transcript
$listener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Loopback, 0)
$listener.Start()
$transcript = [System.Collections.ArrayList]::Synchronized((New-Object System.Collections.ArrayList))
$server = [PowerShell]::Create().AddScript({
	param($listener, $transcript)
	while ($True) {
		Try { $client = $listener.AcceptTcpClient() } Catch { break }
		Try {
			$client.ReceiveTimeout = 5000   # SmtpClient keeps its connection open: do not wait for it forever
			$stream = $client.GetStream()
			$reader = New-Object System.IO.StreamReader($stream, (New-Object System.Text.UTF8Encoding $False))
			$writer = New-Object System.IO.StreamWriter($stream, (New-Object System.Text.UTF8Encoding $False))
			$writer.NewLine = "`r`n"; $writer.AutoFlush = $True
			$writer.WriteLine("220 fake ESMTP")
			$state = ""
			while ($null -ne ($line = $reader.ReadLine())) {
				[void]$transcript.Add($line)
				If($state -eq "data") { If($line -eq ".") { $state = ""; $writer.WriteLine("250 queued") }; continue }
				If($state -eq "auth") { $state = ""; $writer.WriteLine("235 authenticated"); continue }
				switch -regex ($line) {
					'^(EHLO|HELO)'   { $writer.WriteLine("250-fake"); $writer.WriteLine("250-AUTH PLAIN"); $writer.WriteLine("250 8BITMIME") }
					'^AUTH PLAIN \S' { $writer.WriteLine("235 authenticated") }
					'^AUTH PLAIN$'   { $state = "auth"; $writer.WriteLine("334 ") }
					'^DATA'          { $state = "data"; $writer.WriteLine("354 go") }
					'^QUIT'          { $writer.WriteLine("221 bye") }
					default          { $writer.WriteLine("250 ok") }
				}
				If($line -match '^QUIT') { break }
			}
		} Catch {} Finally { $client.Close() }
	}
}).AddArgument($listener).AddArgument($transcript)
[void]$server.BeginInvoke()

$work = Join-Path $env:TEMP ("7zb-test-" + [guid]::NewGuid().ToString("N").Substring(0, 8))
New-Item -ItemType Directory $work -Force | Out-Null
Set-Content -LiteralPath "$work\Catalog-Exclude.txt" -Value "excluded item"
Set-Content -LiteralPath "$work\stats.txt" -Value "not sent"
New-Item -ItemType File "$work\empty.txt" | Out-Null

# State Send-Notification reads from script scope, the same for both cases
$SWriters     = @{}
$BkSmtpFrom   = "backup@example.com"
$BkSmtpRelay  = "127.0.0.1"
$BkSmtpPort   = $listener.LocalEndpoint.Port
$BkRootDir    = $work

# Runs Send-Notification and returns its console output and the lines the server received
Function Invoke-Send {
	$start = $transcript.Count
	$output = (Send-Notification 6>&1 | Out-String)
	Write-Output @{ Output = $output; Lines = @($transcript.GetRange($start, $transcript.Count - $start)) }
}

# -----------------------------------------------------------------------------
Write-Host "`n Case: MailKit path"
$mailKitLib = Get-MailKitLib
If(!$mailKitLib) {
	Write-Host " SKIP : MailKit packages not available (offline?)" -ForegroundColor Yellow
} Else {
	Assert ($null -eq (Import-MailKit $mailKitLib)) "precondition: MailKit loads"
	$BkMailKitPath  = $mailKitLib
	$BkNotifyLog    = @("ops@example.com", "dev@example.com")
	$BkNotifyLogCc  = "cc@example.com"
	$BkNotifyLogBcc = "bcc@example.com"
	$BkSmtpUser     = "backup"
	$BkSmtpPass     = "secret"
	$BkMailSubject  = "MailKit case"
	$BkNotifyExtra  = "attach"
	$Counters       = @{ Warnings = 1; Criticals = 0 }
	$MyContext      = [hashtable]::Synchronized(@{ Logger = (New-Object System.Text.StringBuilder("log line one")) })

	$sent = Invoke-Send
	$lines = $sent.Lines
	$headers = @($lines | Select-Object -Skip ([array]::IndexOf($lines, "DATA") + 1) | ForEach-Object -Begin { $inHeaders = $True } -Process { If($_ -eq "") { $inHeaders = $False }; If($inHeaders) { $_ } })
	$authLine = @($lines | Where-Object { $_ -match '^AUTH PLAIN' })[0]
	$authData = If($authLine -match '^AUTH PLAIN (\S+)$') { $Matches[1] } Else { $lines[[array]::IndexOf($lines, $authLine) + 1] }
	$credentials = $(Try { [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($authData)) } Catch { "" })

	Assert ($sent.Output -match "Done")                                              "Send-Notification reports Done [$($sent.Output.Trim())]"
	Assert ($credentials -eq "`0backup`0secret")                                     "logged in with AUTH PLAIN as backup / secret (MailKit, not SmtpClient)"
	Assert (@($lines | Where-Object { $_ -match '^MAIL FROM:<backup@example\.com>' }).Count -eq 1) "sender is backup@example.com"
	$rcpt = @($lines | Where-Object { $_ -match '^RCPT TO:<(.+)>' } | ForEach-Object { $_ -replace '^RCPT TO:<(.+)>.*$', '$1' } | Sort-Object)
	Assert (($rcpt -join ",") -eq "bcc@example.com,cc@example.com,dev@example.com,ops@example.com") "To, Cc and Bcc recipients [$($rcpt -join ',')]"
	Assert (@($headers | Where-Object { $_ -match 'bcc@example\.com' }).Count -eq 0)  "Bcc address is not in the headers"
	Assert (@($headers | Where-Object { $_ -eq "Subject: MailKit case" }).Count -eq 1) "subject"
	Assert (@($headers | Where-Object { $_ -match '^Priority: urgent' }).Count -eq 1) "urgent priority when there are warnings [$(@($headers | Where-Object { $_ -match 'priority' }) -join ' | ')]"
	Assert (@($lines | Where-Object { $_ -eq "log line one" }).Count -eq 1)          "body holds the log"
	Assert (@($lines | Where-Object { $_ -match 'filename="?Catalog-Exclude\.txt' }).Count -ge 1) "Catalog-Exclude.txt is attached"
	Assert (@($lines | Where-Object { $_ -match 'stats\.txt|empty\.txt' }).Count -eq 0) "stats and empty files are not attached"
	Remove-Variable -Name BkMailKitPath, BkNotifyLogCc, BkNotifyLogBcc, BkSmtpUser, BkSmtpPass
}

# -----------------------------------------------------------------------------
Write-Host "`n Case: SmtpClient path (no --mailkitpath)"
$BkNotifyLog   = "ops@example.com"
$BkMailSubject = "SmtpClient case"
$BkNotifyExtra = "none"
$Counters      = @{ Warnings = 0; Criticals = 0 }
$MyContext     = [hashtable]::Synchronized(@{ Logger = (New-Object System.Text.StringBuilder("log line two")) })

$sent = Invoke-Send
Assert ($sent.Output -match "Done")                                                   "Send-Notification reports Done [$($sent.Output.Trim())]"
Assert (@($sent.Lines | Where-Object { $_ -eq "Subject: SmtpClient case" }).Count -eq 1) "subject"
Assert (@($sent.Lines | Where-Object { $_ -eq "log line two" }).Count -eq 1)          "body holds the log"

$listener.Stop()
Remove-Item -LiteralPath $work -Recurse -Force

# [Environment]::Exit: a plain exit waits for the server runspace, which may still read a SmtpClient connection
Write-Host ""
If($Failures -gt 0) { Write-Host " $Failures assertion(s) failed" -ForegroundColor Red; [Environment]::Exit(1) }
Write-Host " All assertions passed" -ForegroundColor Green
[Environment]::Exit(0)
