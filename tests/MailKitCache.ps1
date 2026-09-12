# Test helper, not a test: downloads MailKit 4.17.0 and its dependencies from
# NuGet into %TEMP% once and returns the folder with their .NET Framework DLLs.
# Returns $null when the packages can not be downloaded (e.g. offline).
#
# Usage: . (Join-Path $PSScriptRoot "MailKitCache.ps1"); $mailKitLib = Get-MailKitLib

Function Get-MailKitLib {
	# Package|version|lib folder for .NET Framework, from the MailKit 4.17.0 dependency tree
	$packages = @(
		"BouncyCastle.Cryptography|2.6.2|net461",
		"MailKit|4.17.0|net48",
		"MimeKit|4.17.0|net48",
		"System.Buffers|4.6.1|net462",
		"System.Formats.Asn1|8.0.1|net462",
		"System.Memory|4.6.3|net462",
		"System.Numerics.Vectors|4.6.1|net462",
		"System.Runtime.CompilerServices.Unsafe|6.1.2|net462",
		"System.Threading.Tasks.Extensions|4.6.3|net462",
		"System.ValueTuple|4.5.0|net47"
	)
	$lib = Join-Path $env:TEMP "7zb-mailkit-cache\4.17.0"
	If(@($packages | Where-Object { !(Test-Path -LiteralPath (Join-Path $lib ($_.Split("|")[0] + ".dll"))) }).Count -eq 0) { Return $lib }

	Try {
		New-Item -ItemType Directory $lib -Force | Out-Null
		[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
		Add-Type -AssemblyName System.IO.Compression.FileSystem
		foreach ($package in $packages) {
			$id, $version, $tfm = $package.Split("|")
			$nupkg = Join-Path $lib "$id.$version.nupkg"
			(New-Object System.Net.WebClient).DownloadFile(("https://api.nuget.org/v3-flatcontainer/{0}/{1}/{0}.{1}.nupkg" -f $id.ToLower(), $version), $nupkg)
			$zip = [System.IO.Compression.ZipFile]::OpenRead($nupkg)
			Try {
				$zip.Entries | Where-Object { $_.FullName -eq "lib/$tfm/$id.dll" } | ForEach-Object { [System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, (Join-Path $lib "$id.dll"), $True) }
			} Finally { $zip.Dispose() }
			Remove-Item -LiteralPath $nupkg
		}
		Return $lib
	} Catch {
		Write-Host (" Could not download MailKit packages: {0}" -f $_.Exception.GetBaseException().Message)
		Return $null
	}
}
