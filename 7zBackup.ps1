# ********************************************************************
# IMPORTANT: This script is not Officially supported in any way !
#            Use it at your own risk !!!
# ********************************************************************
# NAME			: 7zBackup.ps1
# DESCRIPTION	: This script will help you automate the backup process
#				  of your data using 7zip compression program.
#				  When job is done a detailed report is produced.
# OS			: Microsoft Windows 2000 	(NOT tested)
#				  Microsoft Windows XP 		(tested)
#				  Microsoft Windows 2003	(tested)
#				  Microsoft Windows Vista	(tested)
#				  Microsoft Windows 7    	(tested)
#				  Microsoft Windows 2008	(tested)
#				  Microsoft Windows 8    	(tested)
# REQUIREMENTS	: 7zip (http://www.7-Zip.org/download.html)
#				  Junction v1.05 (http://technet.microsoft.com/en-us/sysinternals/bb896768.aspx)
#				  NTFS File System with support for junctions or 
#                 symbolic links
# --------------------------------------------------------------------
# Give credit to the following contributors:
# (please do not remove - add your name if you contribute)
#
#  * Andrea Lanfranchi - Anlan (http://www.anlan.com)
#
# -- Version History –
#            X.XXX         YYYYMMDD Author   Description
#          -------------   -------- -------- --------------------------------------------------
$version = "01.000-beta" # 20091104 Anlan    First release
$version = "01.001-beta" # 20091208 Anlan    Minor Fixes
$version = "01.002-beta" # 20091224 Anlan    Clear Archive Bit now uses Set-ItemProperty
#                                            ProcessFolder now implements -force switch to discover hidden files
#
$version = "1.5-Stable"  # 20091229 Anlan    --workdir switch has been dismissed 
#                                            To prevent the occurrence of PathTooLong Exception as much
#                                            as possible now the script will generate a short
#                                            randomly named directory in the root of the drive
#                                            specified by the --workdrive switch which has now
#                                            become mandatory
#                                            Complete rewrite of the selection process to speed it up
#                                            and new directives to stop recursion and to honour (or not)
#                                            junctions during scanning process
#
$version = "1.5.1-Stable" # 20091229 Anlan   Minor Fixes : $totalBytes strongly typed to [int64]
#                                            Get-ChildItem in ProcessFolder now with -ErrorAction Stop
#
$version = "1.5.2-Stable" # 20091231 Anlan   Minor : Revised error handling in ProcessFolder Function
#                                            Minor : ProcessFolder now Silently Continues
#                                            New   : Added support for matchincludefiles directive
#                                            New   : Detailed catch of 7-Zip exit codes
#                                            New   : Added control --rotate does not pass a negative number
#                                            Ui    : More detailed output log with performance indicator
#                                            Speed : Adjusted default 7-Zip switches to a less aggressive
#                                                    compression rate in favour of processing speed.
#
$version = "1.5.3-Stable" # 20100101 Anlan   Speed : Removed "late" addition of info files to archive as this
#                                                    causes a sensible delay on huge archives.
#                                            Ui    : Log file now includes exceptions from 7-Zip (e.g file not found)
#                                            Speed : Get-Content of selection file is now in one single pass
#                                            Feat  : Added support for --maxfileage and --minfileafe directives
#                                                    in selection file
#                                            Feat  : New argument --clearbit to enforce clearing of 
#                                                    "Archive" attribute on archived files
#
$version = "1.5.4-Stable" # 20100111 Anlan   Bug   : The clearing of archive bit did not work.
$version = "1.5.5-Stable" # 20100111 Anlan   Bug   : Late clearing of archive bit after compression
#                                                    may fail if the file does not exist anymore.
#                                                    In addition the list of selected files has
#                                                    been encoded in UTF8 to allow selection of
#                                                    file names with accented letters.
#
$version = "1.5.6-Stable" # 20100113 Anlan   Bug   : Incorrect assumption on Clear Archive Bit logic
#                                                    The clearing of archive bit is executed on FULL or INCR backups. 
#                                                    This is not correct. *It should be on FULL or DIFF backups*
#
$version = "1.5.7-Stable" # 20100114 Anlan   Bug   : Wrong encoding in 7-Zip output causes incorrect 
#                                                    translation on file names therefore making impossible
#                                                    for the script to go and clear "A" attribute on it.
#                                                    Solved by encoding in UTF8 output from 7-Zip
#                                            Ui    : Statistics on selection now include Absolute and Increasing
#                                                    percent of overall file sizes
#
$version = "1.6.0-Stable" # 20100117 Anlan   Code  : Complete rewrite of the main code
#                                            Feat  : Added some more sophisticated error handling
#                                            Feat  : All formal errors within the command line are now dropped
#                                                    in a single shot.
#                                            Feat  : All sensitive variables are now in a separated file
#                                                    so you can replace the script with new version/relase
#                                                    without the need to re-edit hardcoded values
#                                            Feat  : Exceptions on selection are now included in log file
#                                            Feat  : Sending of notification email now implements Try/Catch
#                                            Feat  : Information about sender/recipient address for notification email 
#                                                    with the addition of the host to use as smtp relay can now 
#                                                    be passed by cli using new arguments. 
#                                            Feat  : You can specify location of either 7z.exe and Junction.exe
#                                                    by cli using proper arguments
#
$version = "1.6.1-Stable" # 20100118 Anlan   Bug   : Clearing of archive bit did not catch errors properly
#                                            Bug   : Try function does not work on PWS 2.0 as it's a statement
#                                                    changed name to DoTry so we can run on both 1.0 and 2.0
#                                            Bug   : Log file was not created correctly with .log extension
#                                            Feat  : Now implements a VERY rudimental lock system to prevent
#                                                    more than one instance of the script.
#
$version = "1.7.0-Stable" # 20100118 Anlan   Bug   : Test-Path-Writable fails on root of system drive on Windows 7
#                                                    Therefore the function now accepts an optional parameter
#                                                    to specify if the write test has to be performed with
#                                                    a directory or a file.
#                                            Feat  : Now you can specify "move" as backup type. It will remove
#                                                    source files after successful archiving.
#                                            Feat  : Added new directive matchcleanupfiles into selections file
#                                                    This will allow the deletion of unuseful/unwanted files
#                                                    during the selection phase.
#                                            Feat  : CTRL+C is now intercepted by the script to allow a smooth
#                                                    close of the procedure avoiding the ugly case to leave
#                                                    unwanted junctions on disk.
#
$version = "1.7.1-Stable" # 20100426 Anlan   Bug   : Presence of junction.exe is wrongly referred to 7z.exe
#
$version = "1.7.2-Stable" # 20101206 Anlan   Bug   : Routine Clear-FileAttribute rewritten due to errors by
#                                                    by cmdlet Get-Item while handling long paths with 
#                                                    many escape chars (like brackets and so on ...)
#                                            Bug   : If lock file detected then script aborts leaving root
#                                                    backup directory in place.
#
$version = "1.7.3-Stable" # 20101207 Anlan   Bug   : Reading back compressed files from 7zip standard output
#                                                    caused non ASCII chars to be mismatched. Fixed
#                                                    Changed the population of $BkCompressDetails with a 
#                                                    stdout redirection in UTF8 following Igor Pavolv suggestion
#
$version = "1.7.4-Stable" # 20110609 Anlan   Code  : Inserted by default /accepteula switch for junction.exe
#
$version = "1.7.5-Stable" # 20110830 Anlan   Code  : Implemented support for smtpUser and smtpPass switches
#                                                    to allow smtp authentication against relay server.
#                                                    Credit to marek vita (http://www.codeplex.com/site/users/view/marek_vita)
#
$version = "1.7.6-Stable" # 20110908 Anlan   Code  : Changed IsValidIp function so it can properly handle IpV6 and IpV4 
#                                                    addresses type.
#                                            Code  : Added datetimeStamp to autogenerated logfile name so it will
#                                                    not mess with other logs working
#
$version = "1.7.7-Stable" # 20111129 Anlan   Code  : Correct assumption of rotation criteria
#                                            Code  : Email messages are sent even if backup is locked by previous
#                                                    operation.
#                                            Code  : Email priority and Suffix changed on Critical Conditions
#                                            Bug   : Log file does not get deleted if operation fails
#
$version = "1.8.0-Stable" # 20120419 Anlan   Code  : Added support for Symbolic Links (MKLINK) for
#                                                    Windows Vista / 7 / 2008 +.
#                                                    Now it supports remote UNC paths as source for backups
#
$version = "1.8.1-Stable" # 20120819 Anlan   Code  : New work switch maxrecursionlevel to limit recursion depth
#                                                    in searching files.
#                                            Code  : rotate argument switch can now be set in selection file too
#                                            Code  : prefix argument switch can now be set in selection file too
#                                            Code  : prefix argument switch is checked against invalid file name chars
#
$version = "1.8.2-Stable" # 20120825 Anlan   Code  : Email report now has Exceptions Include and Exlude lists as
#                                                    attachments.
#
$version = "1.8.3-Stable" # 20121018 Anlan   Code  : new smtpssl to enable Ssl over smtp transport
#
$version = "1.8.4-Stable" # 20130107 Anlan   Code  : Removed DoTry function in favour of native Try-Catch-Finally Statement
#                                            Bug   : Function SendNotificationMail do not properly dispose objects so
#                                                    root directory can not be safely deleted
#
$version = "1.9.0-Stable" # 20130112 Anlan   Feat  : Rewritten the launcher of 7zip with Start-Process. Now you can monitor
#                                                    the progress of 7zip's job.
#                                            Code  : Improved the effectiveness of interception of CTRL+C so you can
#                                                    safely interrupt the execution of the script even while 7zip is running.
#                                            Code  : Workdrive is checked for NTFS filesystem
#
$version = "1.9.5-Stable" # 20131018 Anlan   Feat  : Rewritten the launcher of 7zip with *old* fashioned batch. Better
#                                                    monitoring of exit codes. Now works ok with PWS 2.0
#                                            Feat  : New argument --notifyextra to drive the way extra information is
#                                                    delivered with the notification log
#                                            Bug   : NoFollowJunctions switch was inverted
#                                            Feat  : Added new directive maxfilesize and minfilesize to enhance file selection
#                                                    based upon their size
$version = "1.9.6-Stable" # 20131126 Anlan   Bug   : Typo in variable naming smtpPass which caused authenticated SMTP to fail
$version = "1.9.7-Stable" # 20140205 Anlan   Bug   : Get-ChildItem in ProcessFolder routine now uses -LiteralPath to allow
#                                                    processing of folder names with square brackets in it.
#
$version = "1.9.8-Stable" # 20140814 Anlan   Feat  : Now lock file holds process id and RootDir
#                                                    Subsequent launches of script will check if "old" process is still
#                                                    running and responding or if it is stuck.
#
$version = "1.9.9-Stable" # 20141114 Anlan   Bug   : Parameter --7zbin should be --7zipbin. Added both for backwards
#                                                    compatibility.
#                                            Bug   : includeSource directives should not be processed if in wrong format
#                                            Feat  : try to include empty directories (if writable)
#
$version = "1.9.10-Stable" # 20150217 Anlan   Bug  : Argument --notifyextra incorrectly values variable BkArchiveType
#
$version = "1.9.11-Stable" # 20151022 Anlan   Bug  : For Windows 10 the statement $Host.UI.RawUI.FlushInputBuffer
#                                                    should be $Host.UI.RawUI.FlushInputBuffer() 
$version = "1.10.0-Stable" # 20151122 Anlan   Feat  : Added support for 7zip 15.x
#                                             Code  : Some code refactoring
$version = "1.10.1-Stable" # 20151130 Anlan   Bug   : Wrong parsing of output files
#                                             Code  : Some code refactoring
$version = "1.10.2-Stable" # 20151210 Anlan   Code  : Some code refactoring to improve speed
#                                             


# !! For a new version entry, copy the last entry down and modify Date, Author and Description
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA
#
# Those who do not know how to use snail mail: The GPL is here:
# http://www.gnu.org/licenses/gpl.html

# --------------------------------------------------------------------           --------------------------------------------------------------------
# DO NOT CHANGE ANYTHING BELOW THIS POINT UNLESS YOU'RE A DEVELOPER    I Repeat  DO NOT CHANGE ANYTHING BELOW THIS POINT UNLESS YOU'RE A DEVELOPER
# AND EXACTLY KNOW WHAT YOU'RE DOING                                   I Repeat  AND EXACTLY KNOW WHAT YOU'RE DOING
# --------------------------------------------------------------------           --------------------------------------------------------------------

# --------------------------------------------------------------------
# Init Some Vars to be used globally in the script
# --------------------------------------------------------------------
$Error.Clear()
$ErrorActionPreference = "SilentlyContinue"

$MyContext = @{}
$MyContext.Name       = $MyInvocation.MyCommand.Name
$MyContext.Definition = $MyInvocation.MyCommand.Definition
$MyContext.Directory  = (Split-Path (Resolve-Path $MyInvocation.MyCommand.Definition) -Parent)
$MyContext.StartDir   = (Get-Location -PSProvider FileSystem).ProviderPath
$MyContext.WinVer     = (Get-WmiObject Win32_OperatingSystem).Version.Split(".")
$MyContext.PSVer      = [int]$PSVersionTable.PSVersion.Major

$headerText = @"

 ------------------------------------------------------------------------------
 
  7zBackup.ps1 ver. $version (http://7zbackup.codeplex.com)
  
 ------------------------------------------------------------------------------
 
"@

$helpText = @"
 Usage : .\7zBackup.ps1 --type < full | incr | diff | copy | move >
                        --selection < full path to file name >
                        --destpath < destination path >
                       [--workdrive < working drive letter >]
                       [--rotate < number >]
                       [--maxdepth < number > ]
                       [--prefix < string >]
                       [--clearbit < True | False >]
                       [--emptydirs < True | False >]
                       [--archivetype < 7z | zip | tar >]
                       [--password < string >]
                       [--workdir < working directory > OBSOLETE]
                       [--7zipbin < path to 7z.exe > ]
                       [--jbin < path to Junction.exe > ]
                       [--logfile < filename >]
                       [--notifyto < email1@domain,email2@domain >]
                       [--notifyfrom < sender@domain >]
                       [--notifyextra < none | inline | attach >]					   
                       [--smtpserver < host or ip address >]
                       [--smtpport < default 25 >]					  
                       [--smtpuser < SMTPAuth's user >]					  
                       [--smtppass < SMTPAuth's password >]					  
                       [--smtpssl < True | False >]	

 ------------------------------------------------------------------------------

 --type        Type of backup to perform:
               full : All files and archive bit cleared after archiving
               diff : Files with archive bit set.
                      Archive bit left unchanged after backup.
               incr : Files with archive bit set.
                      Archive bit cleared after backup.					 
               copy : Same as FULL but leave archive bits unchanged
               move : All files matching selection criteria regardless
                      their Archive bit status. After succesful operation
                      archived files are deleted from their original
                      location. Use with great care.

 --selection   Full path to file containing the selection criteria

 --destpath    Full path to destination media which will contain the archive.
               Ensure it will be on a drive with sufficient space to
               contain all the data. Can be a UNC path.
                  
 --workdrive   Drive letter to use for creation of root junction point.
               If not set the script will use the drive associated to
               the TEMP environment variable. It MUST be a valid
               drive letter with the exclusion of A and B. Drive associated
               to this letter must have NTFS file system and it`'s root
               must be writable.

 --archivetype The type of archive you want to create.
               7z   : default format with better compression
               zip  : very compatible with other programs
               tar  : Unix and linux compatible but only archiving (no compression)

 --rotate      This value must be a number and indicates the number of
               archives that should remain on disk after successful
               archiving. For example if you set --rotation 3 on a 
               full archiving operation it means that the newest 3 full
               archives will be kept on disk while the oldest (if any)
               will be deleted. If this value is NOT set then ALL the
               generated archives will be kept on disk. Please be advised
               that in such case your target media will be likely get
               out of space soon. It can be specified either as command argument,
               or in the hardcoded vars file, or in the selection file. 

 --maxdepth    This value si a zero-based index limiting the depth of recursion
               while scanning in search of files to backup. Valid values are
               in range 0 (which means only the first level) to 100 which
               is the maximum value assumed by default. It can be specified
               either as command argument, or in the hardcoded vars file, or
               in the selection file.

 --clearbit    In backup operations of type FULL or DIFF the Archive attribute
               of backupped files is cleared. If you do not want the script
               to do this simply pass --clearbit False. On the other hand
               if you do want to clear the attribute even in other backup
               types then pass --clearbit True

 --emptydirs   By design an archive will hold only files, not directories.
               Therefore the script will simply not find anything to backup
               in an empty directory. If you wish the archive to have the
               indication of empty directories also simply enable this switch.
               It will drop a dummy placeholder file in the empty dir therefore
               allowing the compressor to select it.
               By default is set to false.
 
 --password    Use this switch if you want to password protect your
               archive. No spaces in passwords please.

 --prefix      The prefix to use to generate the archive name.

 --workdir     SUPERSEDED (will be simply ignored)
               Directory which will be used as working area. 
               Must be on an NTFS file system. If none is given then
               the procedure will try to use the one in environment's
               TEMP variable.

 --7zipbin     Specify full path to 7z.exe. 
               If the argument is not provided the script will try to
               locate 7z.exe in :
               $Env:ProgramFiles\7-Zip\7z.exe
			  
 --jbin        Specify full path to Junction.exe. 
               If the argument is not provided the script will try to
               locate Junction.exe in :
               $Env:ProgramFiles\SysInternalsSuite\Junction.exe
               This parameter is optional when the script is invoked
               on Windows Vista / 7 / 2008 which support MKLINK.
			  
 --logfile     Where to log backup operations. If empty will be
               generated automatically.

 --notifyto    Use this argument to set a list of email addresses who
               will receive an email with a copy of the logfile.
               You can specify multiple addresses separated by commas.
               If you set this switch be sure to edit the script and
               insert propervalues in variables `$smtpFrom `$smtpRelay and `$smtpPort

 --notifyfrom  Use this argument to set the proper address to use as 
               sender address when sending out email notifications

 --notifyextra Use this argument to set the way this script will include
               extra informations in the notification message.
               none   : no extra informations
               inline : extra informations in the body of the message
               attach : extra informations attached to the message

 --smtpserver  Host name or IP address of the server to use

 --smtpport    Port number of the smtp server (Default is 25)

 --smtpuser    Smtp's authenticated user (if smtpauth required)

 --smtppass    Smtp's authenticated password (if smtpauth required)

 --smtpssl     whether or not smtp transport requires ssl
 
 -----------------------------------------------------------------------
 
"@


# ====================================================================
# Start Functions Library
# ====================================================================

# Legend for Attributes bits
# - Normal ....... (n) ==> 0
# - Hidden ....... (h) ==> 2
# - ReadOnly ..... (r) ==> 1
# - System ....... (s) ==> 4
# - Directory .... (d) ==> 16
# - Archive ...... (a) ==> 32
# - ReparsePoint . (j) ==> 1024

# Load Attributes Names in array for usage in functions
#$attrNames = [enum]::getNames([System.IO.FileAttributes]);

# -----------------------------------------------------------------------------
# Function 		: CheckVars
# -----------------------------------------------------------------------------
# Description	: This function is used to check variables needed to execute
#				  the script.
# Parameters    : None
# Returns       : An array of error messages (if any)
# -----------------------------------------------------------------------------
Function CheckVars {

	# Init Error Messages array
	$errCheckVars = @()

	# Check we're on Powershell 3.x. If not early exit.
	If(!($MyContext.PSVer -ge 2)) {
		$errCheckVars += ("You must be on PowerShell 2.x (or better) to run this script. You're on {0}" -f $MyContext.PSVer)
		Return $errCheckVars
	}

	# Clear Archive bit policy
	If(((IsVarDefined "BkClearBit") -eq $True)) {
		Set-Variable -name b -value $True -scope Local
		If(([system.boolean]::tryparse($BkClearBit,[ref]$b))) {
			Set-Variable -name BkClearBit -value $b -scope Script
		} Else {
			$errCheckVars += "Provided value for --clearbit argument is not valid. Must be $True or $False."
			Remove-Variable -name BkClearBit -scope Script
		}
		Remove-Variable -name b -scope Local
	}

	# Keep Empty Dirs policy
	If(((IsVarDefined "BkKeepEmptyDirs") -eq $True)) {
		Set-Variable -name b -value $True -scope Local
		If(([system.boolean]::tryparse($BkKeepEmptyDirs,[ref]$b))) {
			Set-Variable -name BkKeepEmptyDirs -value $b -scope Script
		} Else {
			$errCheckVars += "Provided value for --emptydirs argument is not valid. Must be $True or $False."
			Remove-Variable -name BkKeepEmptyDirs -scope Script
		}
		Remove-Variable -name b -scope Local
	}
	
	# Backup Type must be present and within "full", "incr", "diff", "copy"
	If(!(IsVarDefined "BkType")) {
		$errCheckVars += "You must provide a valid value for argument --type."
	} Else {
		Switch ($BkType) {
			"full" { $BkType = "full"; If(!(IsVarDefined "BkClearBit")) { Set-Variable -name BkClearBit -value $True -scope Script } }
			"incr" { $BkType = "incr"; If(!(IsVarDefined "BkClearBit")) { Set-Variable -name BkClearBit -value $True -scope Script } }
			"diff" { $BkType = "diff"; If(!(IsVarDefined "BkClearBit")) { Set-Variable -name BkClearBit -value $False -scope Script } }
			"copy" { $BkType = "copy"; If(!(IsVarDefined "BkClearBit")) { Set-Variable -name BkClearBit -value $False -scope Script } }
			"move" { $BkType = "move"; If(!(IsVarDefined "BkClearBit")) { Set-Variable -name BkClearBit -value $False -scope Script } }
			Default { $errCheckVars += "You must provide a valid value for argument --type." }
		}	
	}

	# Work Drive 
	# If missing or set to "auto" we will assume drive letter for TEMP path.
	# If passed from command line arguments we have to check is a valid drive letter
	# and path is writable and, of course, is NTFS filesystem
	If(!(IsVarDefined "BkWorkDrive")) { Set-Variable -name BkWorkDrive -value "auto" -scope Script }
	If(($BkWorkDrive -ieq "auto")) { Set-Variable -name BkWorkDrive -value ($Env:Temp).Substring(0,1) -scope Script }
	If($BkWorkDrive -ieq "") { 
		$errCheckVars += "Empty value for --workdrive is not supported."
	} Else {
		If(($BkWorkDrive -is [array])) 	{ 
			$errCheckVars += "Value for --workdrive must be a valid drive letter." 
		} Else {
			If(!($BkWorkDrive -imatch "^[C-Z]{1}")) { 
				$errCheckVars += "Value for --workdrive must be a valid drive letter." 
			} Else {
				If(!(Test-Path ($BkWorkDrive + ":\"))) { 
					$errCheckVars += ("Can't access --workdrive " + (($BkWorkDrive + ":\"))) 
				} Else { 
					If(!((Test-Path-Writable ($BkWorkDrive + ":\") "Directory") -eq $True) ) { 
						$errCheckVars += ("Can't write on --workdrive " + (($BkWorkDrive + ":\")))  
					} Else {
						If(!((New-Object System.Io.DriveInfo($BkWorkDrive)).DriveFormat -ieq "NTFS")) { $errCheckVars += ("Workdrive " + (($BkWorkDrive + ":\")) + " is not NTFS") }
					}
				} 
			}
		}
	}

	# Selection file
	If(!(IsVarDefined "BkSelection")) { 
		$errCheckVars += "You must supply a valid selection file in --selection argument"
	} Else {
		If($BkSelection -ieq "") { 
			$errCheckVars += "You must supply a valid selection file in --selection argument"
		} Else {
			If(!(Test-Path $BkSelection -pathType Leaf)) { 
				$errCheckVars += "File provided for --selection does not exist"
			} Else {
				# Check it's NOT a directory
				If((CheckFSAttribute $BkSelection "Directory")) {
					$errCheckVars += "File provided for --selection is a directory"
				} Else {
					# Check there are some file contents into it
					If((Get-ChildItem $BkSelection).Length -eq 0) { 
						$errCheckVars += "File provided for --selection is empty" 
					} Else {
					
						# Resolve full name to file
						Set-Variable -name BkSelection -value ((Get-Item $BkSelection).FullName) -Scope Script
						
						# Try to load Selection Directives (if any)
						# Load all rows except comments and empty lines.
						Remove-Variable -name BkSelectionContents -scope Script 
						Get-Content $BkSelection | Where-Object { ($_ -notmatch "^#|^\s*$") } | Set-Variable -name BkSelectionContents -scope Script
						
						# If we have no directive from selection then handle the error
						If(!(IsVarDefined "BkSelectionContents")) {
							$errCheckVars += "File provided for --selection does not contain any directive" 
						} Else {
							If( ! (($BkSelectionContents | Where-Object {$_ -match "^includesource=*"}).Length -gt 0) ) {
								$errCheckVars += "File provided for --selection does not contain any includesource directive" 
							} Else {
								
								# Look whether selection contents holds specific 7zip switches to use.
								$BkSelectionContents | Where-Object {$_ -match "^useswitches=*"} | ForEach-Object {
									Set-Variable -name "Bk7ZipSwitches" -value ($_.Substring($_.IndexOf("=") + 1)) -scope Script
								}

								# Look whether selection contents holds specific maxdepth value to use.
								$BkSelectionContents | Where-Object {$_ -match "^maxdepth=[0-9]"} | ForEach-Object {
									Set-Variable -name "BkMaxDepth" -value ($_.Substring($_.IndexOf("=") + 1)) -scope Script
								}
								
								# Look whether selection contents holds specific rotate value to use.
								$BkSelectionContents | Where-Object {$_ -match "^rotate=[0-9]"} | ForEach-Object {
									Set-Variable -name "BkRotate" -value ($_.Substring($_.IndexOf("=") + 1)) -scope Script
								}
								
								# Look whether selection contents holds specific prefix value to use.
								$BkSelectionContents | Where-Object {$_ -match "^prefix=*"} | ForEach-Object {
									Set-Variable -name "BkArchivePrefix" -value ($_.Substring($_.IndexOf("=") + 1)) -scope Script
								}

								# Look whether selection contents sets the keeping of empty dirs.
								$BkSelectionContents | Where-Object {$_ -match "^emptydirs$"} | ForEach-Object {
									Set-Variable -name "BkKeepEmptyDirs" -value $True -scope Script
								}

								# Look whether selection contents sets following of junctions
								$BkSelectionContents | Where-Object {$_ -match "^nofollowjunctions$"} | ForEach-Object {
									Set-Variable -name "nofollowjunctions" -value $True -scope Script
								}
								
							}
						}
					}
				}
			}
		}
	}

	# Destination path given and existent
	If(!(IsVarDefined "BkDestPath")) { 
		$errCheckVars += "You must supply a valid destination for --destpath argument"
	} Else {
		If($BkDestPath -ieq "") { 
			$errCheckVars += "You must supply a valid destination for --destpath argument"
		} Else {
			# Is it accessible ?
			If(!(Test-Path $BkDestPath -pathType Container)) {
				$errCheckVars += "Can't access --destpath $BkDestPath as a directory/container"
			} Else { 
				# Is it a Directory ?
				If(!(CheckFSAttribute $BkDestPath "Directory")) {
					$errCheckVars += "Path for --destpath is not a directory"
				} Else {
					# Is it writable ?
					If(!((Test-Path-Writable $BkDestPath "File") -eq $True)) { $errCheckVars += "Can't write on --destpath $BkDestPath" } 
				}
			}
		}
	}

	# Archive Prefix
	# Check Archive Prefix does not contain unallowed chars
	If(!(IsVarDefined "BkArchivePrefix")) { 
		Set-Variable -name BkArchivePrefix -value $Env:Computername -scope Script
	} Else {
		If($BkArchivePrefix -ieq "") { 
			$errCheckVars += "You must provide a value for --prefix argument"
		} Else { 
			If(HasInvalidFileNameChars($BkArchivePrefix)) { $errCheckVars += "Given value for archive prefix contains unallowed chars. You must provide a value for --prefix argument" }
		}
	}

	# Archive Type
	If(!(IsVarDefined "BkArchiveType")) { 
		# Default to 7-Zip format if not defined
		Set-Variable -name BkArchiveType -value "7z" -scope Script
	} Else { 
		Switch ($BkArchiveType) {
			"7z"  { Set-Variable -name BkArchiveType -value "7z"  -scope Script }
			"zip" { Set-Variable -name BkArchiveType -value "zip" -scope Script }
			"tar" { Set-Variable -name BkArchiveType -value "tar" -scope Script }
			Default { $errCheckVars += "Provided value for --archivetype argument is not valid" }
		}
	}

	# Archive Rotation Policy
	If((IsVarDefined "BkRotate")) {
		Set-Variable -name i -value ([int]0) -scope Local
		If(([system.int64]::tryparse($BkRotate,[ref]$i))) {
			Set-Variable -name BkRotate -value $i -scope Script
			If(!($BkRotate -gt 0)) {
				$errCheckVars += "Provided value for --rotate argument is not valid. Must be a positive number."
				Remove-Variable -name BkRotate -scope Script
			}
		} Else {
			$errCheckVars += "Provided value for --rotate argument is not valid. Must be a positive number."
			Remove-Variable -name BkRotate -scope Script
		}
		Remove-Variable -name i -scope Local
	}
	
	# Max depth to honour while scanning - if not defined let's assume a maxdepth of 100
	If((IsVarDefined "BkMaxDepth")) {
		Set-Variable -name i -value ([int]0) -scope Local
		If(([system.int64]::tryparse($BkmaxDepth,[ref]$i))) {
			Set-Variable -name BkMaxDepth -value $i -scope Script
			If(($BkMaxDepth -lt 0)) {
				$errCheckVars += "Provided value for --maxdepth argument is not valid. Must be a positive number."
				Remove-Variable -name BkMaxdepth -scope Script
			} Else {
				If(($BkMaxDepth -gt 100)) { Set-Variable -name BkmaxDepth -value ([int]100) -scope Script }
			}
		} Else {
			$errCheckVars += "Provided value for --maxdepth argument is not valid. Must be a positive number."
			Remove-Variable -name BkMaxDepth -scope Script
		}
		Remove-Variable -name i -scope Local
	} Else {
		Set-Variable -name BkmaxDepth -value ([int]100) -scope Script
	}
	
	# Backup Log File
	If(!(IsVarDefined "BkLogFile")) { 
		Set-Variable -name BkLogFile -value (Join-Path $Env:Temp ($MyContext.Name.Substring(0, ($MyContext.Name.LastIndexOf("."))) + (Get-Date -format "yyyyMMdd-HHmmss") + ".log")) -scope Script
	} 
	If($BkLogFile -ieq "") { 
		$errCheckVars += "You must provide a valid path for --logfile argument"
	} Else {
	
		If((CheckFSAttribute $BkLogFile "Directory")) {
			$errCheckVars += "Log file can't be a directory"
		} Else { 
			# Try Delete previous backup log file (if any)
			If((Test-Path $BkLogFile -pathType Leaf)) {
				Remove-Item ($BkLogFile) -ErrorAction "SilentlyContinue" | Out-Null
				if (!$?) { $errCheckVars += "Unable to delete previous log file" }
			}

			# Try to initialize backup log file
			New-Item ($BkLogFile) -type file -ErrorAction "SilentlyContinue" | Out-Null
			if (!$?) { $errCheckVars += "Unable to write to log file" }
		}
	}
	

	# Email notification policy
	If((IsVarDefined "BkNotifyLog")) {
		
		# Check valid email address(es) 
		If(($BkNotifyLog -is [array])) {
			For ($x=0; $x -lt $BkNotifyLog.Length; $x++) { 
				If(!((IsValidEmailAddress $BkNotifyLog[$x]) -eq $True)) {
					$errCheckVars += ("Provided value for --notify argument " + $BkNotifyLog[$x] + " is not an email address.")
				}
			}
		} Else { 
			If(!((IsValidEmailAddress $BkNotifyLog) -eq $True)) { 
				$errCheckVars += ("Provided value for --notify argument " + $BkNotifyLog + " is not an email address.")
			}
		}
		
		# If we have a request to notify by email we have to be sure $smtpFrom $smtpRelay $smtpPort are defined
		# and are valid.
		
		# Sender Address
		If(!(IsVarDefined "smtpFrom"))  { 
			$errCheckVars += "Missing value for --notifyfrom argument" 
		} Else {
			If(($smtpFrom -is [array])) { 
				$errCheckVars += ("Provided value for --notifyfrom is an array. That's not supported")
			} Else {
				If(!((IsValidEmailAddress $smtpFrom) -eq $True)) { 
					$errCheckVars += ("Provided value for --notifyfrom argument " + $smtpFrom + " is not an email address.")
				}
			}
		}

		# Extra notification infos
		If(!(IsVarDefined "BkNotifyExtra")) { 
			# Defaults to none
			Set-Variable -name BkNotifyExtra -value "none" -scope Script
		} Else { 
			Switch ($BkNotifyExtra) {
				"none"   { Set-Variable -name BkNotifyExtra -value "none"  -scope Script }
				"inline" { Set-Variable -name BkNotifyExtra -value "inline" -scope Script }
				"attach" { Set-Variable -name BkNotifyExtra -value "attach" -scope Script }
				Default { $errCheckVars += "Provided value for --notifyextra argument is not valid" }
			}
		}
		
		# Relay server and authentication (if needed)
		If(!(IsVarDefined "smtpRelay")) { 
			$errCheckVars += "Missing value for --smtpserver argument" 
		} Else {
			If(($smtpRelay -is [array])) { 
				$errCheckVars += ("Provided value for --smtpserver is an array. That's not supported")
			} Else {
				If( !((IsValidHostName $smtpRelay) -eq $True) -and !((IsValidIPAddress $smtpRelay) -eq $True) ) { 
					$errCheckVars += ("Provided value for --smtpserver argument " + $smtpRelay + " is neither an Ip nor a Host.")
				} Else {
					if (((IsVarDefined "smtpUser") -bXor (IsVarDefined "smtpPass")) -eq 1) {
						$errCheckVars += ("Both --smtpuser and --smtppass need a value on SMTP Authentication. Otherwise leave both null.")
					}
				}
			}
		}
		
		# Relay server port
		If(!(IsVarDefined "smtpPort"))  { 
			Set-Variable -name smtpPort -value ([int]25) -scope Script
		} Else {
			Set-Variable -name i -value ([int]0) -scope Local
			If(([system.int64]::tryparse($smtpPort,[ref]$i))) {
				Set-Variable -name smtpPort -value $i -scope Script
				If(($smtpPort -le 0) -or ($smtpPort -gt 65535)) {
					$errCheckVars += "Provided value for --smtpPort argument is not valid. Must be a number [1-65535]."
					Remove-Variable -name smtpPort -scope Script
				}
			} Else {
				$errCheckVars += "Provided value for --smtpPort argument is not valid. Must be a number [1-65535]."
				Remove-Variable -name smtpPort -scope Script
			}
			Remove-Variable -name i -scope Local
		}
		
		# Ssl policy
		If(((IsVarDefined "smtpSsl") -eq $True)) {
			Set-Variable -name b -value $True -scope Local
			If(([system.boolean]::tryparse($smtpSsl,[ref]$b))) {
				Set-Variable -name smtpSsl -value $b -scope Script
			} Else {
				$errCheckVars += "Provided value for --smtpssl argument is not valid. Must be $True or $False."
				Remove-Variable -name smtpSsl -scope Script
			}
			Remove-Variable -name b -scope Local
		}
		
	}

	# Presence of 7z.exe
	If(!(IsVarDefined "Bk7ZipBin")) { 
		If (Test-Path -Path (Join-Path -Path ${env.ProgramFiles} -ChildPath "\7-Zip\7z.exe") -PathType Leaf) {
			Set-Variable -Name Bk7ZipBin -value  (Join-Path -Path ${env.ProgramFiles} -ChildPath "\7-Zip\7z.exe") -scope Script
		} ElseIf (Test-Path -Path (Join-Path -Path ${env.ProgramFiles(x86)} -ChildPath "\7-Zip\7z.exe") -PathType Leaf) {
			Set-Variable -Name Bk7ZipBin -value  (Join-Path -Path ${env.ProgramFiles(x86)} -ChildPath "\7-Zip\7z.exe") -scope Script
		}
	} 
	If(!(IsVarDefined "Bk7ZipBin")) { 
		$errCheckVars += "You must provide a valid path for --7zipbin argument"
	} Else {
		# Try to see if 7z.exe exist on given location
		If(!(Test-Path $Bk7ZipBin -pathType Leaf)) {
			$errCheckVars += "Can't find 7z.exe in $Bk7zipBin"
		} Else {
			$MyContext.SevenZBinVersionInfo = @{}
			Get-Item -Path $Bk7ZipBin | ForEach-Object {
				$MyContext.SevenZBinVersionInfo.ProductVersion = $_.VersionInfo.ProductVersion.ToString()
				$MyContext.SevenZBinVersionInfo.Major = $_.VersionInfo.ProductVersion.ToString().Split(".")[0]
				$MyContext.SevenZBinVersionInfo.Minor = $_.VersionInfo.ProductVersion.ToString().Split(".")[1]
			}
		}
	}
	
	# Presence of Junction.exe - This step is skipped in case we're
	# on Vista / 7 / 2008 as MKLINK is used instead
	If([int]$MyContext.WinVer[0] -lt 6) {
		If(!(IsVarDefined "BkJunctionBin")) { 
			Set-Variable -name BkJunctionBin -value (Join-Path $Env:ProgramFiles "\SysInternalsSuite\junction.exe") -scope Script
		} 
		If($BkJunctionBin -ieq "") { 
			$errCheckVars += "You must provide a valid path for --jbin argument"
		} Else {
			# Try to see if junction.exe exist on given location
			If(!(Test-Path $BkJunctionBin -pathType Leaf)) {
				$errCheckVars += "Can't find Junction.exe in $BkJunctionBin"
			} Else {
				Set-Alias -name Junction -value $BkJunctionBin -scope Script
			}
		}
	}
	
	# Return
	Return $errCheckVars
	
}

# -----------------------------------------------------------------------------
# Function 		: Check-UserCancelRequest
# -----------------------------------------------------------------------------
# Description	: Checks whether or not the user hit CTRL + C to request
#                 script cancel
# Parameters    : 
# Returns       : $True / $False
# Credits       : 
# -----------------------------------------------------------------------------
Function Check-UserCancelRequest {

	If(!($UserCancelRequest -eq $True)) {
	
		If(($Host.UI.RawUI.KeyAvailable)) {
			If (3 -eq [int]$Host.UI.RawUI.ReadKey("AllowCtrlC,IncludeKeyUp,NoEcho").Character) {
				$Host.UI.RawUI.FlushInputBuffer()
				Set-Variable -name UserCancelRequest -value $True -scope Script
				Trace " " $Bklogfile
				Trace " User requested to abort ... "
				Trace " " $Bklogfile
				$True
			} Else {
				$Host.UI.RawUI.FlushInputBuffer()
				$False
			}
		} Else {
			$False
		}

	} Else {
		$Host.UI.RawUI.FlushInputBuffer()
		$True
	}
	
}

# -----------------------------------------------------------------------------
# Function 		: CleanUp
# -----------------------------------------------------------------------------
# Description	: Cleans all files created by the script and leaves the system
#                 in a state which allows another go.
# Parameters    : -
# Returns       : Nothing
# -----------------------------------------------------------------------------
Function CleanUp {

    If ((IsVarDefined "cmdLineBatch")) {if ((Test-Path ($cmdLineBatch))) { Remove-Item -literalpath $cmdLineBatch | Out-Null }}
	If ((IsVarDefined "BkLogFile")) {if ((Test-Path ($BkLogFile))) { Remove-Item -literalpath $BkLogFile | Out-Null }}
	If ((IsVarDefined "BkLockFile")) {if ((Test-Path ($BkLockFile))) { Remove-Item -literalpath $BkLockFile | Out-Null }}
	Set-Location ($MyContext.StartDir)
	If ((Test-Path -Path ($BkRootDir) -PathType Container)) { DeleteRootDir $BkRootDir | Out-Null }
	[console]::TreatControlCAsInput = $False
	
}

# -----------------------------------------------------------------------------
# Function 		: Clear-FileAttribute
# -----------------------------------------------------------------------------
# Description	: Lowers an attribute on a file
# Parameters    : [string]fileFullName - The name of the File to work on
#				  [string]attrName - The name of the attribute to lower
# Returns       : $True / $False
# Credits       : http://scriptolog.blogspot.com/2007/10/file-attributes-helper-functions.html
# -----------------------------------------------------------------------------
Function Clear-FileAttribute {
    param([string]$fileFullName = $(throw "You must provide a file name"),
	      [string]$attrName = $(throw "You must provide an attribute name"))

	If(([System.IO.File]::Exists($fileFullName))) {
		
		Try {
			
			If((([System.IO.File]::GetAttributes($fileFullName)) -band ([System.IO.FileAttributes]::$attrName))) { 
			[System.IO.File]::SetAttributes($fileFullName, (([System.IO.File]::GetAttributes($fileFullName)) -bxor ([System.IO.FileAttributes]::$attrName)))
			}
			$true
			
		} 
		
		Catch {
			
			Trace $( " FAILED Clear-FileAttribute : " + $fileFullName) $BkLogFile
			$false
		
		}
	
	} Else {
	
		Trace $( " FAILED Get-Item : " + $fileFullName) $BkLogFile
		$false
	}
	
} 

# -----------------------------------------------------------------------------
# Function 		: CheckFSAttribute
# -----------------------------------------------------------------------------
# Description	: Checks for the presence of an attribute on a FileSystem object
# Parameters    : [string]itemFullName - The name of the item to check
#				  [string]attrName     - The name of the attribute to look for
# Returns       : $True / $False
# Credits       : http://scriptolog.blogspot.com/2007/10/file-attributes-helper-functions.html
# -----------------------------------------------------------------------------
Function CheckFSAttribute {
    param([string]$itemFullName = $(throw "You must provide an item name"),
	      [string]$attrName = $(throw "You must provide an attribute name"))

	$item = (Get-Item -literalPath $itemFullName -force )
	If(($item)){
		If(($item.Attributes -band [System.IO.FileAttributes]::$attrName)) { 
			$True
		} Else {
			$False
		}
	} Else {
		$False
	}
} 

# -----------------------------------------------------------------------------
# Function 		: DeleteRootDir
# -----------------------------------------------------------------------------
# Description	: This function safely removes the Root Directory generated for
#				  the purpouse of holding junction points to included sources.
#				  Before it deletes the directory itself, each reparse point
#				  is removed using Junction with the -d switch.
# Parameters    : [string]rootPath - The name of the directory to remove
# Returns       : $True / $False
# -----------------------------------------------------------------------------
Function DeleteRootDir {
	param([string]$rootPath = $(throw "You must provide a path to the directory")) 
	
	if ((Test-Path $rootPath -PathType Container)) {
		Get-ChildItem $rootPath | where { $_.Attributes -band 1024 } | ForEach-Object {
			If([int]$MyContext.WinVer[0] -lt 6) {
				If(!(Remove-Junction (Join-Path $rootPath $_.Name))) { $False; Return }
			} Else {
				If(!(Remove-SymLink (Join-Path $rootPath $_.Name))) { $False; Return }
			}
		}
		Remove-Item -Path (Join-Path -Path $rootPath -ChildPath "*.txt") | Out-Null
		Remove-Item -Path $rootPath | Out-Null
		If(!$?) { Return $False } Else { Return $True }
	} Else { Return $False }
	
}

# -----------------------------------------------------------------------------
# Function 		: HasInvalidFileNameChars
# -----------------------------------------------------------------------------
# Description	: This function checks within a string to find the presence
#                 of any char which is not allowed in file naming.
# Parameters    : [string]theString - The string to search into
# Returns       : $True / $False
# -----------------------------------------------------------------------------
Function HasInvalidFileNameChars {
	param([string]$theString = $(throw "You must provide a string to search into")) 
	
	$([System.IO.Path]::GetInvalidFileNameChars()) | ForEach-Object {
		If($theString.Contains("$_")) { return $True }
	}
	return $False
}

# -----------------------------------------------------------------------------
# Function 		: IsVarDefined
# -----------------------------------------------------------------------------
# Description	: This function is used to check if a variables name exist
#				  in the Variables scope
# Parameters    : [string]varName - The name of the Variable to test for
# Returns       : $True / $False
# -----------------------------------------------------------------------------
Function IsVarDefined { 
	param([string]$varName = $(throw "You must provide a variable name"))
	Get-Variable -name $varName -scope Script | Out-Null
	If(!$?) { $False } Else { $True	}
}

# -----------------------------------------------------------------------------
# Function 		: IsValidEmailAddress
# -----------------------------------------------------------------------------
# Description	: This function is used to check if a given string is an email
#                 address.
# Parameters    : [string]emailAddress - The string to check
# Returns       : $True / $False
# -----------------------------------------------------------------------------
Function IsValidEmailAddress { 
	param([string]$emailAddress = $(throw "You must provide an address"))
	If(( $emailAddress -match "^[a-zA-Z][\w\.-]*[a-zA-Z0-9]@[a-zA-Z0-9][\w\.-]*[a-zA-Z0-9]\.[a-zA-Z][a-zA-Z\.]*[a-zA-Z]$" )) {
		$True
	} Else {
		$False
	}
}	

# -----------------------------------------------------------------------------
# Function 		: IsValidHostName
# -----------------------------------------------------------------------------
# Description	: This function is used to check if a given string is a
#                 valid host name.
# Parameters    : [string]hostName - The string to check
# Returns       : $True / $False
# -----------------------------------------------------------------------------
Function IsValidHostName { 
	param([string]$hostName = $(throw "You must provide an host name"))
	If(( $hostName -match "^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z]|[A-Za-z][A-Za-z0-9\-]*[A-Za-z0-9])$" )) {
		$True
	} Else {
		$False
	}
}	

# -----------------------------------------------------------------------------
# Function 		: IsValidIPAddress
# -----------------------------------------------------------------------------
# Description	: This function is used to check if a given string is an IP
#                 address.
# Parameters    : [string]ipAddress - The string to check
# Returns       : $True / $False
# -----------------------------------------------------------------------------
Function IsValidIPAddress { 
	param([string]$ipAddress = $(throw "You must provide an address"))
	
	Set-Variable -name Ip -value ([System.Net.IPAddress]::Parse("127.0.0.1")) -scope Local
	If ([System.Net.IPAddress]::TryParse($ipAddress, [ref]$Ip)) { $True } Else { $False }
	
	# Method prone to errors especially with IpV6
	#If(( $ipAddress -match "\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b" )) {
	#	$True
	#} Else {
	#	$False
	#}
}	

# -----------------------------------------------------------------------------
# Function 		: Make-Junction
# -----------------------------------------------------------------------------
# Description	: Creates a Junction by the means of SysInternals' Junction.exe
# Parameters    : [string]jPath    - Full path to the name of the junction
#				  [string]jTarget  - Full path to the target 
# Returns       : $True / $False
# -----------------------------------------------------------------------------
Function Make-Junction {
	param(
		[string]$jPath = $(throw "You must provide a path where to create the Junction"), 
		[string]$jTarget = $(throw "You must provide a path to target")
	)
	
	# Before we make any junction we have to test target
	# path exist
	If((Test-Path $jTarget)) {
	
		# Now we have to check if source and or target contains spaces
		If(($jPath.Contains(" "))) { $jPath = """$jPath""" }
		If(($jTarget.Contains(" "))) { $jTarget = """$jTarget""" }
		
		# Junction it
		Junction "/accepteula" $jPath $jTarget | Out-Null
		#If((test-path $jPath)) { $True } Else { $False }
		If(($LASTEXITCODE -eq 0)) { $True } Else { $False }
		
	} Else { $False }
}

# -----------------------------------------------------------------------------
# Function 		: Make-SymLink
# -----------------------------------------------------------------------------
# Description	: Creates a Symbolic Link to Target (only available for WinVer 6+)
# Parameters    : [string]jPath    - Full path to the name of the junction
#				  [string]jTarget  - Full path to the target 
# Returns       : $True / $False
# -----------------------------------------------------------------------------
Function Make-SymLink {
	param(
		[string]$jPath = $(throw "You must provide a path where to create the Link"), 
		[string]$jTarget = $(throw "You must provide a path to target")
	)
	
	# Before we make any junction we have to test target
	# path exist
	If((Test-Path $jTarget)) {
	
		# Now we have to check if source and or target contains spaces
		If(($jPath.Contains(" "))) { $jPath = """$jPath""" }
		If(($jTarget.Contains(" "))) { $jTarget = """$jTarget""" }
		
		# Create Link
		cmd /c MKLINK /D $jPath $jTarget | Out-Null
		If(($LASTEXITCODE -eq 0)) { $True } Else { $False }
		
	} Else { $False }
}

# -----------------------------------------------------------------------------
# Function 		: Remove-Junction
# -----------------------------------------------------------------------------
# Description	: Removes a Junction by the means of SysInternals' Junction.exe
# Parameters    : [string]jPath    - Full path to the name of the junction
# Returns       : $True / $False
# -----------------------------------------------------------------------------
Function Remove-Junction  {
	param([string]$jPath = $(throw "You must provide a path to the junction")) 

	# Check Junction Path exist otherwise we have nothing to unJunction
	If((Test-Path $jPath)) {
		
		# Now we have to check if source contains spaces
		If(($jPath.Contains(" "))) { $jPath = """$jPath""" }

		# UnJunction it
		Junction "/accepteula" -d $jPath | Out-Null
		If(($LASTEXITCODE -eq 0)) { $True } Else { $False }
		
	} Else { $False }
}

# -----------------------------------------------------------------------------
# Function 		: Remove-SymLink
# -----------------------------------------------------------------------------
# Description	: Removes a Symbolic Link
# Parameters    : [string]jPath    - Full path to the name of the Link
# Returns       : $True / $False
# -----------------------------------------------------------------------------
Function Remove-SymLink  {
	param([string]$jPath = $(throw "You must provide a path to the Link")) 

	# Check Junction Path exist otherwise we have nothing to delete
	If((Test-Path $jPath)) {
		
		# Now we have to check if source contains spaces
		If(($jPath.Contains(" "))) { $jPath = """$jPath""" }

		# Remove the Link
		cmd /c RD $jPath
		If(($LASTEXITCODE -eq 0)) { $True } Else { $False }
		
	} Else { $False }
}


# -----------------------------------------------------------------------------
# Function 		: PostArchiving
# -----------------------------------------------------------------------------
# Description	: This routine reprocess succesfully archived files
# Parameters    : 
# Returns       : 
# -----------------------------------------------------------------------------
Function PostArchiving {

	# Remove created placeholders if any
	if ($gP.PlaceHolders.count -gt 0) {
		$i     = 0 
		$count = $gP.PlaceHolders.count
		$gP.PlaceHolders | ForEach-Object {
			$i++ ; $percentCompleted = ( $i / $count * 100 ) ; If(($percentCompleted -gt 100)) { $percentCompleted = 100 }
			Write-Progress -Activity "Removing Placeholders for Empty Directories" -PercentComplete $percentCompleted -Status "Please wait ..." -CurrentOperation ($_.fileName)
			Remove-Item $_ # | Out-Null
		}
	}

	# Load compress details data with respect of different log formats for different 7zip versions
	If(IsVarDefined "BkCompressDetailItems") { Remove-Variable -Name BkCompressDetailItems}
	If ([int]$MyContext.SevenZBinVersionInfo.Major -gt 9) {	
		Get-Content -Path $BkCompressDetail -Encoding UTF8 | Where-Object {$_ -match "^\+"} | Select @{Name="File";Expression={($_.Substring(2))}} | Set-Variable -Name BkCompressDetailItems
	} Else {
		Get-Content -Path $BkCompressDetail -Encoding UTF8 | Where-Object {$_ -match "^Compressing\ \ "} | Select @{Name="File";Expression={($_.Substring(13))}} | Set-Variable -Name BkCompressDetailItems
	}
	
	# Clear archive bits as needed or remove source files from their location
	# in case of a "move" backup type.
	If(!($bkType -ieq "move")) {

		If(($BkClearBit -eq $True)) {
			$clearBitsStart = Get-Date
			Trace " Clearing Archive Bit From Archived Files" $BkLogFile
			Trace " ----------------------------------------" $BkLogFile
			$i = 0
			$BkCompressDetailItems | ForEach-Object {
				If((Check-UserCancelRequest -eq $True)) { return; }
				$i++ ; $percentCompleted = ( $i / $gP.FilesSelected * 100 ) ; If(($percentCompleted -gt 100)) { $percentCompleted = 100 }
				Write-Progress -Activity "Clearing Archive Bit" -PercentComplete $percentCompleted -Status "Please wait ..." -CurrentOperation ($_.File)
				If(!(Clear-FileAttribute (Join-Path $BkRootDir $_.File) Archive)) { $gP.WarningsCount += 1 }
			}
			$elapsed = New-TimeSpan $clearBitsStart $(Get-Date)
			Trace (" Completed in {0,0:n0} days, {1,0:n0} hours, {2,0:n0} minutes, {3,0:n0} seconds" -f $elapsed.Days, $elapsed.Hours, $elapsed.Minutes, $elapsed.Seconds ) $BkLogFile
			Trace " " $BkLogFile
		}
		
	} Else {
	
		$removeFilesStart = Get-Date
		Trace " Deleting Source Files" $BkLogFile
		Trace " ----------------------------------------" $BkLogFile
		$i = 0
		$BkCompressDetailItems | ForEach-Object {
			If((Check-UserCancelRequest -eq $True)) { return; }
			$i++ ; $percentCompleted = ( $i / $gP.FilesSelected * 100 ) ; If(($percentCompleted -gt 100)) { $percentCompleted = 100 }
			Write-Progress -Activity "Deleting files" -PercentComplete $percentCompleted -Status ($_.File) -CurrentOperation "Please Wait ..."
			Remove-Item (Join-Path $BkRootDir $_.File) | Out-Null
			if (!($?)) { Trace (" WARNING Failed to remove : {0}" -f $_.File) $BkLogFile; $gP.WarningsCount += 1 }
		}
		$elapsed = New-TimeSpan $removeFilesStart $(Get-Date)
		Trace (" Completed in {0,0:n0} days, {1,0:n0} hours, {2,0:n0} minutes, {3,0:n0} seconds" -f $elapsed.Days, $elapsed.Hours, $elapsed.Minutes, $elapsed.Seconds ) $BkLogFile
		Trace " " $BkLogFile
		
	}

}
# -----------------------------------------------------------------------------
# Function 		: ProcessFolder
# -----------------------------------------------------------------------------
# Description	: This is the main scanning/selection routine.
#				  It's purpouse is to recurse all the folders below the 
#                 given root in search of files to backup
# Parameters    : [string]$folderPath - The name of the directory to scan
#                 [int]$depth - Depth level reached
# Returns       : $True / $False
# -----------------------------------------------------------------------------
Function ProcessFolder ([string]$folderPath, [int]$depth) {

	# Test we're quitting
	If((Check-UserCancelRequest -eq $True)) { return; }
	
	# Increment the counter of "Done" folders if $depth is greater
	# than 1 which means we're below $BkRootDir
	If(($depth -gt 0)) { $gP.FoldersDone++ }

	# Check $folderPath.Length is less or equal to 248 chars
	# or we'll fall into PathTooLong Exception
	# MAX_PATH is 260 chars i.e. 248 chars for path + 12 chars for item name (8 dot 3)
	If(($folderPath.Length -gt 248)) { 
	    Trace " WARNING Path Too Long " $BkLogFile; $gP.WarningsCount += 1
		" PathTooLongException ==> $folderPath" | Out-File $BkSelectionExcpt -encoding ASCII -append
		Return
	}
	
	# Transform thisPath into a path relative to $BkRootDir
	If(($folderPath -ieq $BkRootDir)) {
		$thisRelativePath = "\"
	} Else {
		$thisRelativePath = $folderPath.Substring(($BkRootDir.Length + 1))
	}

	# Status
	Write-Progress -Activity "Folder $thisRelativePath" -Status "Scanning ... " -CurrentOperation ("Selected {0,0:n0} out of {1,0:n0} files in {2,0:n0} folders. {3,0:n2} MBytes to backup" -f  $gP.FilesSelected, $gP.FilesProcessed, $gP.FoldersDone, ($gP.BytesSelected / 1MB ))
	
	# Check if we have to process files in this folder
	# or if we have to skip due to a $matchecludepath
	# directive
	$scanThisPath = $True
	If(($matchexcludepath)) {
		If(($thisRelativePath -match $matchexcludepath)) { 
			$scanThisPath = $False 
			" matchexcludepath ==> $thisRelativePath" | Out-File $BkCatalogExclude -encoding ASCII -append
		}
	}

	# Get the number of elements in the container
	# Thanks to Jonas Azunis for reporting wrong counting on Powershell 2.0
	$childItems = @(Get-ChildItem -LiteralPath ("$folderPath") -Force)
	if ($childItems.count -lt 1 -and $BkKeepEmptyDirs -eq $True) {
		
		# Try to drop a placeholder file and reload child items
		# New-Item will report no blocking errors
		$gP.PlaceHolders += New-Item (Join-Path $folderPath $PlaceHoldersExt) -type File
		If($?) {
			$childItems = @(Get-ChildItem -LiteralPath ("$folderPath") -Force)
		}
	
	}

	# Early exit if we do not have anything to scan
	if($childItems.count -lt 1) { return }
	
	# Process only folders in this path
	$childItems | ?{ $_.PSIscontainer } | ForEach-Object {

		# Test we're quitting
		If((Check-UserCancelRequest -eq $True)) { return; }
	
		# Check subdir against regular expression which
		# may stop recursion
		$recurseSubDirs = $True
		$noRecurseReason = ""
		
		# Check subdir against matchstoprecurse directive
		If((IsVarDefined "matchstoprecurse") -and !($thisRelativePath -ieq "\")) {
			If(( ($thisRelativePath + "\" + $_.Name) -match $matchstoprecurse)) {
				" matchstoprecurse ==> {0}\{1}" -f $thisRelativePath, $_.Name | Out-File $BkCatalogExclude -encoding ASCII -append
				return # Excluded by directive
			}
		}
		
		# Check subdir against recursion in junctions
		If(($nofollowjunctions) -and !($thisRelativePath -ieq "\")) {
			If(($_.Attributes -band 1024)) {
				" nofollowjunctions ==> {0}\{1}" -f $thisRelativePath, $_.Name | Out-File $BkCatalogExclude -encoding ASCII -append
				return # Excluded by directive
			}
		}
		
		# Check subdir against maxdepth in recursion
		If(($depth + 1) -gt $BkMaxDepth) {
			" maxdepthlimit({2}) ==> {0}\{1}" -f $thisRelativePath, $_.Name, $BkMaxDepth | Out-File $BkCatalogExclude -encoding ASCII -append
			return # Excluded by directive
		}
		
		# Recurse SubFolders avoiding the error to get in stack overflow 
		# maxdepth maximum value is 100 in any case.
		ProcessFolder (Join-Path $folderPath $_.Name) ($depth + 1)
		
	}

	# Process only files in this path if not in root dir
	If($thisRelativePath -eq "\" -or $scanThisPath -ne $true) { 
		Write-Progress -Activity "Folder $thisRelativePath" -Status "Path Skip " -CurrentOperation ("Selected {0,0:n0} out of {1,0:n0} files in {2,0:n0} folders. {3,0:n2} MBytes to backup" -f  $gP.FilesSelected, $gP.FilesProcessed, $gP.FoldersDone, ($gP.BytesSelected / 1MB ))
		return 
	}
	$childItems | ?{ !$_.PSIscontainer } | ForEach-Object {
	
		# Increment the number of processed files
		$gP.FilesProcessed++
		$gP.BytesProcessed += $_.Length
		
		# Status
		Write-Progress -Activity "Folder $thisRelativePath" -Status ("File : {0} " -f $_.Name) -CurrentOperation ("Selected {0,0:n0} out of {1,0:n0} files in {2,0:n0} folders. {3,0:n2} MBytes to backup" -f  $gP.FilesSelected, $gP.FilesProcessed, $gP.FoldersDone, ($gP.BytesSelected / 1MB ))

		# >>> Clean up files ?
		If((IsVarDefined "matchcleanupfiles") -and ($_.Name -imatch $matchcleanupfiles)) {
			Write-Progress -Activity "Folder $thisRelativePath" -Status "File Delete : $_.Name" -CurrentOperation ("Selected {0,0:n0} out of {1,0:n0} files in {2,0:n0} folders. {3,0:n2} MBytes to backup" -f  $gP.FilesSelected, $gP.FilesProcessed, $gP.FoldersDone, ($gP.BytesSelected / 1MB ))
			Remove-Item -literalpath (Join-Path $folderPath $_.Name) -Force | Out-Null
			If(!$?) {
				Trace (" Warning : {0}" -f $Error[0].ToString()) $BkLogFile
				$gP.WarningsCount++
			} Else {
				Trace (" Removed file : {0}" -f (Join-Path $thisRelativePath $_.Name)) $BkLogFile
			}
			Return # Should be a file to delete not to backup
		}
		# <<<
		
		# Archive Attribute : is it set as we need it ?
		If((($BkType -ieq "incr") -or ($BkType -ieq "diff")) -and !($_.Attributes -band 32) ) { 
			return # Attribute bit is not set
		}

		# Match Include ?
		If( (IsVarDefined "matchincludefiles") -and ($_.Name -NotMatch $matchincludefiles) ) { 
			" matchincludefiles ==> not matches {0}" -f $_.Name | Out-File $BkCatalogExclude -encoding ASCII -append
			return # Excluded by directive
		}
				
		# Match Exclude ?
		If( (IsVarDefined "matchexcludefiles") -and ($_.Name -Match $matchexcludefiles) ) { 
			" matchexcludefile ==> matches {0}" -f $_.Name | Out-File $BkCatalogExclude -encoding ASCII -append
			return # Excluded by directive
		}
		
		# Check the file falls into MaxFileAge
		If( (IsVarDefined "MaxFileAge") -and ((New-Timespan $_.LastWriteTime $selectStart) -gt $MaxFileAge) ) {
			" maxfileage{0} ==> excludes {1} [{2}]" -f $MaxFileAge, $_.Name, $_.LasWriteTime | Out-File $BkCatalogExclude -encoding ASCII -append
			return # Excluded by directive
		}
		
		# Check the file falls into MinFileAge
		If( (IsVarDefined "MinFileAge") -and ((New-Timespan $_.LastWriteTime $selectStart) -lt $MinFileAge) ) {
			" minfileage{0} ==> excludes {1} [{2}]" -f $MinFileAge, $_.Name, $_.LasWriteTime | Out-File $BkCatalogExclude -encoding ASCII -append
			return # Excluded by directive
		}

		# Check the file falls into MaxFileSize
		If( (IsVarDefined "MaxFileSize") -and ($_.Length -gt $MaxFileSize) ) {
			" maxfilesize{0} ==> excludes {1} [{2} bytes]" -f $MaxFileSize, $_.Name, $_.Length | Out-File $BkCatalogExclude -encoding ASCII -append
			return # Excluded by directive
		}

		# Check the file falls into MaxFileSize
		If( (IsVarDefined "MinFileSize") -and ($_.Length -lt $MinFileSize) ) {
			" minfilesize{0} ==> excludes {1} [{2} bytes]" -f $MinFileSize, $_.Name, $_.Length | Out-File $BkCatalogExclude -encoding ASCII -append
			return # Excluded by directive
		}

		# Update counters
		$gP.FilesSelected++ ; 
		$gP.BytesSelected += $_.Length ; 
		"{0}\{1}" -f $thisRelativePath, $_.Name | Out-File $BkCatalogInclude -encoding UTF8 -append 
		# Save Catalog Stats
		( "{0},{1},{2}" -f $_.Extension,[string]$gP.FilesSelected,[string]$_.Length ) | Out-File $BkCatalogStats -encoding ASCII -append 
		# Display progress
		Write-Progress -Activity "Folder $thisRelativePath" -Status "File Select : $_" -CurrentOperation ("Selected {0,0:n0} out of {1,0:n0} files in {2,0:n0} folders. {3,0:n2} MBytes to backup" -f  $gP.FilesSelected, $gP.FilesProcessed, $gP.FoldersDone, ($gP.BytesSelected / 1MB ))
		
		
	}
	
	# If we have errors then output them
	If($Error.Count -gt 0) {
		For ($x = ($Error.Count - 1); $x -lt 0; $x--) {
			"Error in {0} : {1}" -f $thisRelativePath, $Error[$x].ToString() | Out-File $BkSelectionExcpt -encoding ASCII -append
		}
		$Error.Clear()
	}

}

# -----------------------------------------------------------------------------
# Function 		: SendNotificationEmail
# -----------------------------------------------------------------------------
# Description	: Sends the notification email to given adressee
# Parameters    : None
# Returns       : $True / $False 
# -----------------------------------------------------------------------------
Function SendNotificationEmail {

		Write-Host " "
		Write-Host " Sending notification email ..."

		$SmtpClient = [Object]
		$MailMessage = [Object]
		
		Try {
		
			If(!(IsVarDefined "mailSubject")) { Set-Variable -name "mailSubject" -value ("7zBackup Report Host $Env:ComputerName") -scope Script }
			$SmtpClient = New-Object system.net.mail.smtpClient
			$MailMessage = New-Object system.net.mail.mailmessage
			
			$SmtpClient.Host = $smtpRelay
			$SmtpClient.Port = $smtpPort
			If(((IsVarDefined "smtpSsl") -eq $True)) { $SmtpClient.EnableSsl = $smtpSsl }

			# If we have both smtpuser and smtppass then we need to authenticate
			if ((IsVarDefined "smtpUser") -and (IsVarDefined "smtpPass")) {
				$SmtpUserInfo = New-Object System.Net.NetworkCredential($smtpUser, $smtpPass)
				$SmtpClient.UseDefaultCredentials = $False
				$SmtpClient.Credentials = $SmtpUserInfo
			}

			If(($gP.WarningsCount -gt 0)) { $MailMessage.Priority = [System.Net.Mail.MailPriority]::High }
			If(($gP.CriticalCount -gt 0)) { $MailMessage.Priority = [System.Net.Mail.MailPriority]::High; $mailSubject = "Critical ! $MailSubject" }
			$MailMessage.From = $smtpFrom
			If(($BkNotifyLog -is [array])) {
				For ($x=0; $x -lt $BkNotifyLog.Length; $x++) { $MailMessage.To.Add($BkNotifyLog[$x]) }
			} Else { 
				$MailMessage.To.Add($BkNotifyLog) 
			}

			$MailMessage.Subject = $mailSubject
			$MailMessage.Body = [string]::join([environment]::newline, (Get-Content -path $BkLogFile -encoding ASCII)) 
			
			If (!($BkNotifyExtra -ieq "none")) {
				If ($BkNotifyExtra -ieq "attach") {
	
					# Attach selection directives
					If((Get-Item $BkSelectionInfo).Length -gt 0) {
						$MailAttachment = New-Object System.Net.Mail.Attachment($BkSelectionInfo)
						$MailAttachment.Name = "Directives.txt"
						$MailMessage.Attachments.Add($MailAttachment)
					}			

					# Attach inclusions if any
					If((Get-Item $BkCatalogInclude).Length -gt 0) {
						$MailAttachment = New-Object System.Net.Mail.Attachment($BkCatalogInclude)
						$MailAttachment.Name = "Inclusions.txt"
						$MailMessage.Attachments.Add($MailAttachment)
					}			

					# Attach exclusions if any
					If((Get-Item $BkCatalogExclude).Length -gt 0) {
						$MailAttachment = New-Object System.Net.Mail.Attachment($BkCatalogExclude)
						$MailAttachment.Name = "Exclusions.txt"
						$MailMessage.Attachments.Add($MailAttachment)
					}			
					
					# Attach exceptions if any
					If((Get-Item $BkSelectionExcpt).Length -gt 0) {
						$MailAttachment = New-Object System.Net.Mail.Attachment($BkSelectionExcpt)
						$MailAttachment.Name = "Exceptions.txt"
						$MailMessage.Attachments.Add($MailAttachment)
					}
					
					# Attach Compression detail
					If((Get-Item $BkCompressDetail).Length -gt 0) {
						$MailAttachment = New-Object System.Net.Mail.Attachment($BkCompressDetail)
						$MailAttachment.Name = "Compression-Detail.txt"
						$MailMessage.Attachments.Add($MailAttachment)
					}
					
				} Else {
				
					# Insert in body selection directives
					$MailMessage.Body += ([environment]::newline + "Selection Directives detail " + [environment]::newline + (Get-Content $BkSelectionInfo))
					
					# Insert inclusions if any
					If((Get-Item $BkCatalogInclude).Length -gt 0) {
						$MailMessage.Body += ([environment]::newline + "Inclusions detail " + [environment]::newline + (Get-Content $BkCatalogInclude))
					}			

					# Attach exclusions if any
					If((Get-Item $BkCatalogExclude).Length -gt 0) {
						$MailMessage.Body += ([environment]::newline + "Exclusions detail " + [environment]::newline + (Get-Content $BkCatalogExclude))
					}			
					
					# Attach exceptions if any
					If((Get-Item $BkSelectionExcpt).Length -gt 0) {
						$MailMessage.Body += ([environment]::newline + "Exceptions detail " + [environment]::newline + (Get-Content $BkSelectionExcpt))
					}
					
					# Attach compression detail
					If((Get-Item $BkCompressDetail).Length -gt 0) {
						$MailMessage.Body += ([environment]::newline + "7zip compress detail " + [environment]::newline + (Get-Content $BkCompressDetail))
					}
					
				
				}
			}
			
			$SmtpClient.Send($MailMessage) 
			Write-Host " Done" -ForeGroundColor Green
			Write-Host " "
			
			} 
			
		Catch {
			Write-Host " Unable to send notification email. " -ForeGroundColor Red
			Write-Host " "
			}
			
		Finally {
			If ($MailMessage.GetType().Name -ieq "MailMessage") { $MailMessage.Dispose() }
		}

}

# -----------------------------------------------------------------------------
# Function 		: Test-Path-Writable
# -----------------------------------------------------------------------------
# Description	: Checks a given path is writable
# Parameters    : [string]targetPath - Full path to the directory to test
# Returns       : $True / $False 
# -----------------------------------------------------------------------------
Function Test-Path-Writable {
	param([string]$testPath = $(throw "You must provide a path to test"),
	      [string]$testType = $(throw "You must provide a test item type")) 

	# Check Path Exist
	If((Test-Path -Path $testPath -PathType Container)) {
	
		# Generate a dummy file name with a Guid
		$dummyItem = Join-Path $testPath ( [System.Guid]::NewGuid().ToString() )
		
		# Try to create new file in tested path
		if (( $testType -ieq "file" )) {
			New-Item $dummyItem -type File -force -value "This is only a test file. You can delete it safely." | Out-Null
		} Else {
			New-Item $dummyItem -type Directory -force | Out-Null
		}
		If (($?)) {
			Remove-Item $dummyItem | Out-Null
			if (!($?)) { $False } Else { $True }
		} Else { 
			$False 
		}
		
	} Else { $False }
}

# -----------------------------------------------------------------------------
# Function 		: Trace
# -----------------------------------------------------------------------------
# Description	: Outputs message to console and to file(s)
# Parameters    : [string]$message  - The message to output
#               : [string]$outfile1 - A file where to append message
#               : [string]$outfile2 - A file where to append message
# Returns       : --
# -----------------------------------------------------------------------------
Function Trace ($message, $outfile1, $outfile2) {
	Write-Host $message
	if (($outfile1)) { $message | out-file $outfile1 -encoding ASCII -append }
	if (($outfile2)) { $message | out-file $outfile2 -encoding ASCII -append }
}

# -----------------------------------------------------------------------------
# Function 		: Pause
# -----------------------------------------------------------------------------
# Description	: Outputs message to console and waits for any key
# Parameters    : [string]$message  - The message to output
# Returns       : --
# -----------------------------------------------------------------------------
Function Pause ($Message="Press any key to continue...") {
	Write-Host -NoNewLine $Message
	$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
	Write-Host ""
}

# ====================================================================
# End Functions Library
# ====================================================================

# --------------------------------------------------------------------
# Check For the presence of "--help" argument switch
# --------------------------------------------------------------------
If($args.length -ne 0) { 
	switch -wildcard ($args) { "*--help*" {Write-Host $headerText; Write-Host $helpText ; return} }
} Else {
	Write-Host $headerText ; " Wrong number of parameters. Try " + $MyContext.Name + " --help"; Write-Host " " ; return 
}
# --------------------------------------------------------------------
# Check arguments and values are passed as pairs
# --------------------------------------------------------------------
$Test = 0
[void][Math]::DivRem($args.length,2,[ref]$Test)
If(!($Test -eq 0)){ Write-Host $headerText ; " Wrong number of parameters. Try " + $MyContext.Name + " --help"; Write-Host " " ; return }

# --------------------------------------------------------------------
# Test the presence of a script in same directory holding 
# default variable values
# --------------------------------------------------------------------
$BkKeepEmptyDirs = $False
$importCmd = (Join-Path $MyContext.Directory $MyContext.Name.Replace(".ps1", "-vars.ps1"))
If((Test-Path $importCmd -pathType Leaf )) { & $importCmd }

# --------------------------------------------------------------------
# Loop through command line arguments and assign variables proper
# values. Preloaded vars die against ones passed by cli
# --------------------------------------------------------------------
$i = 0
do {
	switch ($args[$i]) 	{ 
		"--type"            { Set-Variable -name BkType -value $args[$i + 1] -scope Script }
		"--workdir"         { Set-Variable -name BkWorkDir -value $args[$i + 1] -scope Script }
		"--workdrive"       { Set-Variable -name BkWorkDrive -value $args[$i + 1] -scope Script }
		"--selection"       { Set-Variable -name BkSelection -value $args[$i + 1] -scope Script }
		"--destpath"        { Set-Variable -name BkDestPath -value $args[$i + 1] -scope Script }
		"--archiveprefix"   { Set-Variable -name BkArchivePrefix -value $args[$i + 1] -scope Script }
		"--prefix"          { Set-Variable -name BkArchivePrefix -value $args[$i + 1] -scope Script }
		"--archivetype"     { Set-Variable -name BkArchiveType -value $args[$i + 1] -scope Script }
		"--archivepassword" { Set-Variable -name BkArchivePassword -value $args[$i + 1] -scope Script }
		"--password"        { Set-Variable -name BkArchivePassword -value $args[$i + 1] -scope Script }
		"--rotate"          { Set-Variable -name BkRotate -value $args[$i + 1] -scope Script }
		"--maxdepth"        { Set-Variable -name BkMaxDepth -value $args[$i + 1] -scope Script }
		"--clearbit"        { Set-Variable -name BkClearBit -value $args[$i + 1] -scope Script }
		"--emptydirs"       { Set-Variable -name BkKeepEmptyDirs -value $args[$i + 1] -scope Script }
		"--logfile"         { Set-Variable -name BkLogFile -value $args[$i + 1] -scope Script }
		"--notify"          { Set-Variable -name BkNotifyLog -value $args[$i + 1] -scope Script }
		"--notifyto"        { Set-Variable -name BkNotifyLog -value $args[$i + 1] -scope Script }
		"--notifyfrom"      { Set-Variable -name smtpFrom -value $args[$i + 1] -scope Script }
		"--notifyextra"     { Set-Variable -name BkNotifyExtra -value $args[$i + 1] -scope Script }		
		"--smtpserver"      { Set-Variable -name smtpRelay -value $args[$i + 1] -scope Script }
		"--smtpport"        { Set-Variable -name smtpPort -value $args[$i + 1] -scope Script }
		"--smtpuser"        { Set-Variable -name smtpUser -value $args[$i + 1] -scope Script }
		"--smtppass"        { Set-Variable -name smtpPass -value $args[$i + 1] -scope Script }
		"--smtpssl"         { Set-Variable -name smtpSsl -value $args[$i + 1] -scope Script }
		"--7zbin"           { Set-Variable -name Bk7ZipBin -value $args[$i + 1] -scope Script }
		"--7zipbin"         { Set-Variable -name Bk7ZipBin -value $args[$i + 1] -scope Script }
		"--jbin"            { Set-Variable -name BkJunctionBin -value $args[$i + 1] -scope Script }
		Default { Write-Host $headerText ; " Unknown argument " + $args[$i] + " Try " + $MyContext.Name + " --help"; Write-Host " " ; return }
	}
	$i++; $i++
}
while ($i -lt $args.length)

# --------------------------------------------------------------------
# Initialize hash for global progress info
# --------------------------------------------------------------------
$gP = @{}
$gP.WarningsCount = 0
$gP.CriticalCount = 0
$gP.FoldersDone = 0
$gP.FilesProcessed = 0
$gP.FilesSelected = 0
$gP.FilesSkipped = 0
$gP.BytesProcessed = 0
$gP.BytesSelected = 0
$gP.BytesSkipped = 0
$gP.PlaceHolders = @()
$PlaceHoldersExt = ".7zdir"


# --------------------------------------------------------------------
# Check Variables Values 
# --------------------------------------------------------------------
$errMsgs = CheckVars
If(($errMsgs.Length) -gt 0) {
	$errMsgs | ForEach-Object { " Err : $_" } -begin { Write-Host $headerText } -end { Write-Host " "; Write-Host (" Try " + $MyInvocation.MyCommand.Name + " --help") ; Write-Host " " }
	Return
}

# --------------------------------------------------------------------
# This will prevent unhandled exit from the script
# --------------------------------------------------------------------
[console]::TreatControlCAsInput = $true
Set-Variable -name UserCancelRequest -value $False -scope Script

# --------------------------------------------------------------------
# Compose Backup Archive Name
# --------------------------------------------------------------------
$BkArchiveName = ($BkArchivePrefix + "-" + $BkType + "-" + (Get-Date -format "yyyyMMdd-HHmm") + "." + $BkArchiveType)

# Create the name of the directory which will hold all the
# junctions to included sources.
$BkRootDir = ($BkWorkDrive + ":\~" + ([System.Guid]::NewGuid().ToString().Split("-")[1]))

# Create Root Directory and place a huge README.TXT
New-Item $BkRootDir -type Directory | Out-Null
If(!$?) { 
	Write-Host $headerText
	Write-Host "Unable to create directory $BkRootDir. Check permissions on drive $BkWorkDrive."
	Write-Host " " 
	Return
} Else {
	If([int]$MyContext.WinVer[0] -lt 6 ) {
		New-Item (Join-Path $BkRootDir "__README__PLEASE__README__.txt") -type File -value "This directory contains Junctions.`nDO NOT DELETE THIS DIRECTORY AND IT'S CONTENTS USING WINDOWS EXPLORER.`nUse Junction -d to delete junctions and then safely delete the directory." | Out-Null
	} Else {
		New-Item (Join-Path $BkRootDir "__README__PLEASE__README__.txt") -type File -value "This directory contains Symbolic Links.`nDO NOT DELETE THIS DIRECTORY AND IT'S CONTENTS USING WINDOWS EXPLORER.`nUse RD command delete symbolic links and then safely delete the directory." | Out-Null
	}
	If(!$?) {
		Write-Host $headerText
		Write-Host "Can't write into $BkRootDir. Check permissions on drive $BkWorkDrive."
		Write-Host " " 
		Return
	}
}

# Initalize Operations
Trace $headerText $BkLogFile
Trace " Started         :  $(Get-Date)" $BkLogFile
Trace " Backup Type     :  $BkType" $BkLogFile
Trace " Archive Name    :  $BkArchiveName" $BkLogFile
Trace " Archive Type    :  $BkArchiveType" $BkLogFile
Trace " Destination     :  $BkDestPath" $BkLogFile
Trace " Selection       :  $BkSelection" $BkLogFile
Trace " Recursion Depth :  $BkMaxDepth" $BkLogFile
If(($BkClearBit -eq $True)) { Trace " Archive Attrs   :  Will be cleared" $BkLogFile } Else { Trace " Archive Attrs   :  Will stay unchanged" $BkLogFile }
If((IsVarDefined "BkRotate")) { Trace " Rotate          :  Keep last $BkRotate archive(s) " $BkLogFile } Else { Trace " Rotate          :  Keep all archives " $BkLogFile }
Trace (" 7Zip Binary     :  {0} (ver. {1}) " -f $Bk7zipBin,$MyContext.SevenZBinVersionInfo.ProductVersion) $BkLogFile
Trace (" 7Zip Switches   :  {0} " -f $Bk7ZipSwitches) $BkLogFile
Trace " " $BkLogFile
Trace " ------------------------------------------------------------------------------" $BkLogFile


# --------------------------------------------------------------------
# Check for the presence of a previous lock file which means 
# a previous operation was interrupted abnormally or it's still
# running
# --------------------------------------------------------------------

Set-Variable -name BkLockFile -value (Join-Path $Env:Temp ($MyContext.Name.Substring(0, ($MyContext.Name.LastIndexOf("."))) + ".lock")) -scope Script
If((Test-Path $BkLockFile -pathType Leaf)) {

    # A previously executed script has left it's lock file
	# Look whether file contents has previous process id and old root
    Get-Content $BkLockFile -Encoding Ascii | Where-Object {$_ -imatch "^PID="} | ForEach-Object {
	    Set-Variable -name "OldPid" -value ($_.Substring($_.IndexOf("=") + 1)) -scope Script
	}
    Get-Content $BkLockFile -Encoding Ascii | Where-Object {$_ -imatch "^Root="} | ForEach-Object {
	    Set-Variable -name "OldRoot" -value ($_.Substring($_.IndexOf("=") + 1)) -scope Script
	}

    If ((IsVarDefined "OldPid")) {
        $OldProcess = Get-Process -Id $OldPid 
        If ($OldProcess) {
			If ($OldPid -eq [System.Diagnostics.Process]::GetCurrentProcess().Id) {

                   If ((IsVarDefined "OldRoot")) { 
                        If(Test-Path $OldRoot -PathType Container ) { DeleteRootDir $OldRoot }
                    }
                   Remove-Item $BkLockFile
				   
			} ElseIf ($OldProcess.Responding) {
			
		        Trace " " $BkLogFile
		        Trace " A previous operation is running with process id $OldPid"  $BkLogFile
		        Trace " Check lock file" $BkLogFile
		        Trace " $BkLockFile" $BkLogFile
		        if ((Test-Path ($BkRootDir))) { DeleteRootDir $BkRootDir | Out-Null }
		        $gP.CriticalCount += 1
		        # If is set a list of notification addresses then proceed with email here
		        if ((IsVarDefined "BkNotifyLog")) { SendNotificationEmail } 
		        if ((IsVarDefined "BkLogFile")) {if ((Test-Path ($BkLogFile))) { Remove-Item -literalpath $BkLogFile | Out-Null }}
		        return

            } Else {

                Try {
                    # Stops the non-responding process
                    Stop-Process -Id $OldPid -Force - | Out-Null
                    }

                Catch {

                    # Unable to stop process therefore abort
		            Trace " " $BkLogFile
		            Trace " A previous operation is non responding with process id $OldPid"  $BkLogFile
		            Trace " Check lock file" $BkLogFile
		            Trace " $BkLockFile" $BkLogFile
		            if ((Test-Path ($BkRootDir))) { DeleteRootDir $BkRootDir | Out-Null }
		            $gP.CriticalCount += 1
		            # If is set a list of notification addresses then proceed with email here
		            if ((IsVarDefined "BkNotifyLog")) { SendNotificationEmail } 
		            if ((IsVarDefined "BkLogFile")) {if ((Test-Path ($BkLogFile))) { Remove-Item -literalpath $BkLogFile | Out-Null }}
		            return
                }

                   If ((IsVarDefined "OldRoot")) { 
                        If(Test-Path $OldRoot -PathType Container ) { DeleteRootDir $OldRoot }
                    }
                   Remove-Item $BkLockFile

            }
        } Else {

            If ((IsVarDefined "OldRoot")) { 
                If(Test-Path $OldRoot -PathType Container ) { DeleteRootDir $OldRoot }
            }
            Remove-Item $BkLockFile
            
        }
    } Else {
	
	    If ((New-TimeSpan -End (Get-Date) -Start (Get-ChildItem $BkLockFile).LastWriteTime).Hours -gt 72) { 
		    Remove-Item $BkLockFile; New-Item $BkLockFile -ItemType File -Force | Out-Null  
	    } Else {
	
		    Trace " " $BkLogFile
		    Trace " A previous operation is running or has stopped abnormally" $BkLogFile
		    Trace " Check lock file" $BkLogFile
		    Trace " $BkLockFile" $BkLogFile
		    if ((Test-Path ($BkRootDir))) { DeleteRootDir $BkRootDir | Out-Null }
		    $gP.CriticalCount += 1
		    # If is set a list of notification addresses then proceed with email here
		    if ((IsVarDefined "BkNotifyLog")) { SendNotificationEmail } 
		    if ((IsVarDefined "BkLogFile")) {if ((Test-Path ($BkLogFile))) { Remove-Item -literalpath $BkLogFile | Out-Null }}
		    return
		
		    }
    }

} Else {
	New-Item $BkLockFile -ItemType File -Force | Out-Null
    "PID=" + [System.Diagnostics.Process]::GetCurrentProcess().Id | Out-File $BkLockFile -encoding ASCII -append
    "Root=" + $BkRootDir | Out-File $BkLockFile -encoding ASCII -append
}

Trace " Backup from sources   " $BkLogFile
Trace " ------------------------------- " $BkLogFile

# --------------------------------------------------------------------
# Read the contents of selection file and create a junction for each one 
# --------------------------------------------------------------------
$includedSources = 0
$BkSelectionContents | Where-Object {$_ -imatch "^includesource=(.*)\|alias=(.*)"} | ForEach-Object {
	
	$directiveLine=[string]$_
	$directiveParts = $directiveLine.split("|", [System.StringSplitOptions]::RemoveEmptyEntries)
	$target = $directiveParts[0].Split("=")[1]
	$alias  = $directiveParts[1].Split("=")[1]
	
	# Trace the selection
	Trace " - $alias <== $Target" $BkLogFile
	
	# Check target exist
	If(!(Test-Path $target -pathType Container)) { 
		Trace "   Selection directory $target does not exist. Skipping " $BkLogFile
	} Else {
		
		# Check alias is not already in use
		If((Test-Path (Join-Path $BkRootDir $alias))) {
			Trace "   Alias $alias already in use. Skipping selection of $target" $BkLogFile
		} Else {
			
			If([int]$MyContext.WinVer[0] -lt 6 ) { 
				# Create the new junction for Windows previous to vista
				If(!(Make-Junction (Join-Path $BkRootDir $alias) $target)) { Trace "   Failed to create Junction [$alias] to [$target]" $BkLogFile} Else { $includedSources++ }
			} Else {
				# Create the new symbolic link for Windows Vista or newer
				If(!(Make-SymLink (Join-Path $BkRootDir $alias) $target)) { Trace "   Failed to create Symbolic Link [$alias] to [$target]" $BkLogFile} Else { $includedSources++ }
			}
			
		}
		
	}
}

# --------------------------------------------------------------------
# Check we have at least one directory alias to backup 
# --------------------------------------------------------------------
If(( $includedSources -eq 0 )) {
	Trace "   There are no selectable sources to backup. Quitting" $BkLogFile
	
	If ((Test-Path ($BkRootDir) -PathType Container)) { DeleteRootDir $BkRootDir | Out-Null }
	if ((IsVarDefined "BkLockFile")) {if ((Test-Path ($BkLockFile) -PathType Leaf)) { Remove-Item -literalpath $BkLockFile | Out-Null }}
	Return
	
}  Else {
	Trace " " $BkLogFile
}

# --------------------------------------------------------------------
# Check we have an cleanup criteria on file names
# --------------------------------------------------------------------
Trace " Cleanup Files Criteria " $BkLogFile
Trace " ------------------------------- " $BkLogFile
$BkSelectionContents | Where-Object {$_ -match "^matchcleanupfiles="} | ForEach-Object {
	$line = $_.Substring($_.IndexOf("=") + 1)
	If(($line)) {
		Trace " $line" $BkLogFile
		If(!($matchcleanupfiles)) { $matchcleanupfiles = $line } Else { $matchcleanupfiles += ("|" + $line) }
	}
}
If(!($matchcleanupfiles)) { Trace " None " $BkLogFile; Trace " " $BkLogFile } Else { Trace " " $BkLogFile; Trace " These files will be deleted during the Scan !" $BkLogFile; Trace " " $BkLogFile }

# --------------------------------------------------------------------
# Check we have an exclude criteria on file names
# --------------------------------------------------------------------
Trace " Include Files Criteria " $BkLogFile
Trace " ------------------------------- " $BkLogFile
$BkSelectionContents | Where-Object {$_ -match "^matchincludefiles="} | ForEach-Object {
	$line = $_.Substring($_.IndexOf("=") + 1)
	If(($line)) {
		Trace " $line" $BkLogFile
		If(!($matchincludefiles)) { $matchincludefiles = $line } Else { $matchincludefiles += ("|" + $line) }
	}
}
If(!($matchincludefiles)) { Trace " All files " $BkLogFile; Trace " " $BkLogFile } Else { Trace " " $BkLogFile }

# --------------------------------------------------------------------
# Check we have a maxfileage to honour
# --------------------------------------------------------------------
$BkSelectionContents | Where-Object {$_ -match "^maxfileage=[0-9]"} | ForEach-Object {
	If(!($MaxFileAge)) { $MaxFileAge = [int64]0 }
	If(([system.int64]::tryparse($_.Substring($_.IndexOf("=") + 1),[ref]$MaxFileAge))) { $MaxFileAge = [Math]::Abs($MaxFileAge) }
	If(!($MaxFileAge -gt 0)) { Remove-Variable MaxFileAge }
}
If(($MaxFileAge)) {
Trace " Max File Age : $MaxFileAge days" $BkLogFile
Trace " " $BkLogFile
}

# --------------------------------------------------------------------
# Check we have a minfileage to honour
# --------------------------------------------------------------------
$BkSelectionContents | Where-Object {$_ -match "^minfileage=[0-9]"} | ForEach-Object {
	If(!($MinFileAge)) { $MinFileAge = [int64]0 }
	If(([system.int64]::tryparse($_.Substring($_.IndexOf("=") + 1),[ref]$MinFileAge))) { $MinFileAge = [Math]::Abs($MinFileAge) }
	If(!($MinFileAge -gt 0)) { Remove-Variable MinFileAge }
}
If(($MinFileAge)) {
Trace " Min File Age : $MinFileAge days" $BkLogFile
Trace " " $BkLogFile
}

# --------------------------------------------------------------------
# Check we have a maxfilesize to honour
# --------------------------------------------------------------------
$BkSelectionContents | Where-Object {$_ -match "^maxfilesize=[0-9]"} | ForEach-Object {
	If(!($MaxFileSize)) { $MaxFileSize = [int64]0 }
	If(([system.int64]::tryparse($_.Substring($_.IndexOf("=") + 1),[ref]$MaxFileSize))) { $MaxFileSize = [Math]::Abs($MaxFileSize) }
}
If(($MaxFileSize)) {
Trace " Max File Size : $MaxFileSize bytes" $BkLogFile
Trace " " $BkLogFile
}

# --------------------------------------------------------------------
# Check we have a minfileage to honour
# --------------------------------------------------------------------
$BkSelectionContents | Where-Object {$_ -match "^minfilesize=[0-9]"} | ForEach-Object {
	If(!($MinFileSize)) { $MinFileSize = [int64]0 }
	If(([system.int64]::tryparse($_.Substring($_.IndexOf("=") + 1),[ref]$MinFileSize))) { $MinFileSize = [Math]::Abs($MinFileSize) }
	If(!($MinFileSize -gt 0)) { Remove-Variable MinFileSize }
}
If(($MinFileSize)) {
Trace " Min File Size : $MinFileSize bytes" $BkLogFile
Trace " " $BkLogFile
}

# --------------------------------------------------------------------
# Check we have an exclude criteria on file names
# --------------------------------------------------------------------
Trace " Exclude Files Criteria " $BkLogFile
Trace " ------------------------------- " $BkLogFile
$BkSelectionContents | Where-Object {$_ -match "^matchexcludefiles=*"} | ForEach-Object {
	$line = $_.Substring($_.IndexOf("=") + 1)
	If(($line)) {
		Trace " $line" $BkLogFile
		If(!($matchexcludefiles)) { $matchexcludefiles = $line } Else { $matchexcludefiles += ("|" + $line) }
	}
}
If(!($matchexcludefiles)) { Trace " None " $BkLogFile; Trace " " $BkLogFile } Else { Trace " " $BkLogFile }

# --------------------------------------------------------------------
# Check we have an exclude criteria on paths
# --------------------------------------------------------------------
Trace " Exclude Paths Criteria " $BkLogFile
Trace " ------------------------------- " $BkLogFile
$BkSelectionContents | Where-Object {$_ -match "^matchexcludepath=*"} | ForEach-Object {
	$line = $_.Substring($_.IndexOf("=") + 1)
	If(($line)) {
		Trace " $line" $BkLogFile
		If(!($matchexcludepath)) { $matchexcludepath = $line } Else { $matchexcludepath += ("|" + $line) }
	}
}
If(!($matchexcludepath))  { Trace " None " $BkLogFile; Trace " " $BkLogFile } Else { Trace " " $BkLogFile }

# --------------------------------------------------------------------
# Check we have any rule to stop digging into directories
# --------------------------------------------------------------------
Trace " Stop Recursion Criteria " $BkLogFile
Trace " ------------------------------- " $BkLogFile
$BkSelectionContents | Where-Object {$_ -match "^matchstoprecurse=*"} | ForEach-Object {
	$line = $_.Substring($_.IndexOf("=") + 1)
	If(($line)) {
		Trace " $line" $BkLogFile
		If(!($matchstoprecurse)) { $matchstoprecurse = $line } Else { $matchstoprecurse += ("|" + $line) }
	}
}
If(!($matchstoprecurse))  { Trace " None " $BkLogFile; Trace " " $BkLogFile } Else { Trace " " $BkLogFile }

# --------------------------------------------------------------------
# Check we have to honour junctions or not
# --------------------------------------------------------------------
if (($nofollowjunctions)) {
	Trace " Junctions will NOT be followed " $BkLogFile
	Trace " " $BkLogFile
}

# --------------------------------------------------------------------
# Move to the $BkRootDir and make it current
# --------------------------------------------------------------------
Set-Location -path $BkRootDir 

# --------------------------------------------------------------------
# Let's drop into $BkRootDir a few files which will contain useful 
# information in case you want to examine the contents of an archive
# and how it's been generated.
# --------------------------------------------------------------------
$BkSelectionInfo  = Join-Path $BkRootDir "Selection-Info.txt" ; New-Item $BkSelectionInfo  -type File -Force -value ([string]::join([environment]::newline, (Get-Content -path $BkSelection -encoding ASCII))) | Out-Null
$BkSelectionExcpt = Join-Path $BkRootDir "Selection-Excpt.txt"; New-Item $BkSelectionExcpt -type File -Force | Out-Null
$BkCatalogInclude = Join-Path $BkRootDir "Catalog-Include.txt"; New-Item $BkCatalogInclude -type File -Force | Out-Null
$BkCatalogExclude = Join-Path $BkRootDir "Catalog-Exclude.txt"; New-Item $BkCatalogExclude -type File -Force | Out-Null
$BkCatalogStats   = Join-Path $BkRootDir "Catalog-Stats.txt"  ; New-Item $BkCatalogStats   -type File -Force | Out-Null; "Extension,FileNum,Size" | Out-File $BkCatalogStats -encoding ASCII -append
$BkCompressDetail = Join-Path $BkRootDir "Compress-Detail.txt"; New-Item $BkCompressDetail -type File -Force | Out-Null

Trace " ------------------------------------------------------------------------------" $BkLogFile
Trace " Scanning ..." $BkLogFile

# Begin the processing of the root folder to build up the catalogs and start counting elapsed time
$selectStart = Get-Date

# Test we're quitting and start processing the RootFolder
# Note !! The very first loop is performed against the Root Directory where
# junction points are placed. Therefore the first recursion level of "0" will
# be performed on 2nd pass or, in other words, while entering the very first
# junction points.
If(!(Check-UserCancelRequest -eq $True)) { ProcessFolder $BkRootDir -1 }
Write-Progress -Activity "Searching Files ..." -Completed -Status ("Selected {0,0:n0} files in {1,0:n0} folders. {2,0:n2} MBytes to backup" -f  $gP.FilesSelected, $gP.FoldersDone, ($gP.BytesSelected / 1Mb))

# Calc of elapsed time for selection process
$selectEnd = Get-Date
$elapsed = New-TimeSpan $selectStart $selectEnd

# Early exit from the process if user cancel or there is nothingto backup
If(($gP.FilesSelected -lt 1) -or (Check-UserCancelRequest -eq $True)) {

	# Trace we have not selected anything to backup
	Trace " " $BkLogFile
	Trace " There are no files matching the selection criteria. Possible reasons: " $BkLogFile
	Trace " - All source directories are empty" $BkLogFile
	Trace " - No file match selection criteria" $BkLogFile
	Trace " - User Cancel Request" $BkLogFile
	Trace " " $BkLogFile

	# If is set a list of notification addresses then proceed with email here
	if (!(Check-UserCancelRequest -eq $True)) { if ((IsVarDefined "BkNotifyLog")) { SendNotificationEmail } }

	# Clean Up and Exit
	CleanUp
	return
}

	# Adjust at least 1byte selected (in case all files are zero length)
	# This will prevent division by zero errors
	If(($gP.BytesSelected -lt 1)) { $gP.BytesSelected = 1 }

	# Trace informations about what is selected
	Trace " " $BkLogFile
	Trace (" Selected {0,0:n0} out of {1,0:n0} files in {2,0:n0} folders. {3,0:n2} MBytes to backup" -f  $gP.FilesSelected, $gP.FilesProcessed, $gP.FoldersDone, ($gP.BytesSelected/1mb)) $BkLogFile
	Trace (" Completed in {0,0:n0} days, {1,0:n0} hours, {2,0:n0} minutes, {3,0:n0} seconds" -f $elapsed.Days, $elapsed.Hours, $elapsed.Minutes, $elapsed.Seconds ) $BkLogFile
	

	# Maybe there has been some exceptions during the selection progress. 
	# If this is the case output them here.
	If((Get-Item $BkSelectionExcpt).Length -gt 0) {
		Trace " " $BkLogFile
		Trace " Exceptions during selection process" $BkLogFile
		Trace " ------------------------------------------------------------------------------" $BkLogFile
		Get-Content $BkSelectionExcpt | ForEach-Object {
		Trace (" {0} " -f $_) $BkLogFile; $gP.WarningsCount += 1
		}
	}
	
	If(!(Check-UserCancelRequest -eq $True)) {
		# Do some stats (many thanks to http://www.hanselman.com/blog/ParsingCSVsAndPoorMansWebLogAnalysisWithPowerShell.aspx)
		Write-Progress -Activity "Calculating Stats on Selection" -Status "Running ..." -CurrentOperation "Please Wait ..."
		$statsByExtension = Import-Csv $BkCatalogStats | Select-Object Extension, Size | group Extension | select Name, @{Name="Count";Expression={($_.Count)}}, @{Name="Size";Expression={($_.Group | Measure-Object -Sum Size).Sum }} | Sort Size -desc
		
		# Replace $BkCatalogStats with summarized data
		If((Test-Path $BkCatalogStats)) { Remove-Item $BkCatalogStats | Out-Null }
		
		# Output summarized data
		Trace " " $BkLogFile
		Trace " Selection Details" $BkLogFile $BkCatalogStats
		Trace " ------------------------------------------------------------------------------" $BkLogFile
		Trace " Extension                              Count          Total MB  Abs %   Inc % " $BkLogFile $BkCatalogStats
		Trace " -------------------------------  ----------- ----------------- ------- -------" $BkLogFile $BkCatalogStats
		$totalCount = 0; [int64]$totalBytes = 0
		$statsByExtension | ForEach-Object {
		$totalCount += $_.Count ; $totalBytes += $_.Size
		Trace (" {0,-31} {1,11:n0} {2,17:n2}  {3,6:n2}  {4,6:n2}" -f $_.Name, $_.Count, ($_.Size/1MB), ($_.Size/ $gP.BytesSelected * 100), ($totalBytes / $gP.BytesSelected * 100)) $BkLogFile $BkCatalogStats
		}
		Trace "                                  ----------- ----------------- " $BkLogFile $BkCatalogStats
		Trace (" {0,-31} {1,11:n0} {2,17:n2} " -f "Total", $totalCount, ($totalBytes/1MB)) $BkLogFile $BkCatalogStats
		Trace "                                  =========== ================= " $BkLogFile $BkCatalogStats
		Trace " " $BkLogFile
	}
	
	Write-Progress -Activity "Archiving into $BkDestFile" -Status "Please wait ..." -CurrentOperation "Initializing ..."	
	
	# Add info files to catalog so we do not have to perform a late addition
	# which causes a great delay on huge archives
	$BkSelectionInfo.Substring( $BkSelectionInfo.LastIndexOf("\") + 1 )  | Out-File $BkCatalogInclude -encoding UTF8 -append
	$BkSelectionExcpt.Substring( $BkSelectionExcpt.LastIndexOf("\") + 1 ) | Out-File $BkCatalogInclude -encoding UTF8 -append
	$BkCatalogInclude.Substring( $BkCatalogInclude.LastIndexOf("\") + 1 ) | Out-File $BkCatalogInclude -encoding UTF8 -append
	$BkCatalogExclude.Substring( $BkCatalogExclude.LastIndexOf("\") + 1 ) | Out-File $BkCatalogInclude -encoding UTF8 -append
	$BkCatalogStats.Substring( $BkCatalogStats.LastIndexOf("\") + 1 )    | Out-File $BkCatalogInclude -encoding UTF8 -append

	# Start the clocks
	$compressStart = Get-Date

	# Line up all the arguments we need and build command line
	$BkDestFile = Join-Path $BkDestPath $BkArchiveName
	$Bk7ZipArgs = @()
	$Bk7ZipArgs += "a"																	# This is the "add" switch
	$Bk7ZipArgs += $Bk7ZipSwitches														# These are the switches defined in the var file
	
	# If 7zip is beyond version 9.2 then add some more switches
	If ([int]$MyContext.SevenZBinVersionInfo.Major -gt 9) {
		$Bk7ZipArgs += "-bb2"
		$Bk7ZipArgs += "-bse1"
		$Bk7ZipArgs += "-bsp0"
	}
	
	$Bk7ZipArgs += "-t" + $BkArchiveType												# This is the type of the archive
	If(IsVarDefined "BkArchivePassword") { $Bk7ZipArgs += "-p$BkArchivePassword" }		# This is the password (if any)
	$Bk7ZipArgs += "`"$BkDestFile`""													# This is the destination file
	$Bk7ZipArgs += "`@`"$BkCatalogInclude`""											# This is the catalog input file
	If(IsVarDefined "Bk7ZipRetc") { Remove-Variable -Name Bk7ZipRetc }

	# Invoke 7zip job 
	$Bk7ZipProcess = Start-Process -FilePath $Bk7ZipBin -ArgumentList $Bk7ZipArgs -NoNewWindow -PassThru -RedirectStandardOutput $BkCompressDetail -WorkingDirectory $BkRootDir
	[console]::TreatControlCAsInput = $true
		
	# Monitor 7zip job 
	While (!($Bk7ZipProcess.HasExited)) {
		Start-Sleep -Milliseconds 2000
		$Status = ""
		If (Test-Path -Path "$BkDestFile" -PathType Leaf) {
			Get-Item "$BkDestFile" | ForEach-Object {
				$Status = "Archive Size {0,0:n2} MByte. so far ..." -f ($_.Length / 1Mb)
			}
			if($MyContext.PSVer -ge 3) {
				Get-Content -Path $BkCompressDetail -Encoding UTF8 -Tail 2 | Select -First 1 | Set-Variable -Name Bk7ZipCurrentItem
				Write-Progress -Activity "Archiving into $BkDestFile" -Status $Status -CurrentOperation ("Please wait ({0}) ..." -f $Bk7ZipCurrentItem)
			} Else {
				Write-Progress -Activity "Archiving into $BkDestFile" -Status $Status -CurrentOperation "Please wait ..."
			}
		}
		If(Check-UserCancelRequest -eq $True) {
			$Bk7ZipProcess | Stop-Process
			Start-Sleep 1
			" WARNING: User Cancel Request " | Out-File $BkCompressDetail -append
			Set-Variable -Name Bk7ZipRetc -value ([int]255) -scope Script
			# Delete the destination file
			if ((Test-Path ($BkDestFile))) { Remove-Item -literalpath $BkDestFile | Out-Null }
			Start-Sleep 1
		}
	}
	If(!(IsVarDefined "Bk7ZipRetc")) {$Bk7ZipRetc = $Bk7ZipProcess.ExitCode}
	
	# Stop the clock
	$elapsed = New-TimeSpan $compressStart $(Get-Date)
	
	# Version 9.x  and 15.x of 7zip have different outputs
	# Look inside $BkCompressDetail in search of any file which may have been skipped
	# e.g. 7-Zip could not find one or more selected files 
	If ([int]$MyContext.SevenZBinVersionInfo.Major -le 9) {
		$relevantMessages = Get-Content $BkCompressDetail -encoding UTF8 | Where-Object {$_ -match "\ WARNING:\ |\ :\ "}
	} else {
		Try {
			$relevantMessagesStartLine = [int]((Select-String $BkCompressDetail -encoding UTF8 -pattern "Scan WARNINGS for files and folders" -casesensitive).ToString().Split(":")[2])
			Get-Content $BkCompressDetail -encoding UTF8 | Select -Skip $relevantMessagesStartLine | Where-Object {$_ -notmatch "^Scan WARNINGS|^\-|^\s*$"} | Set-Variable -name relevantMessages -scope 1
		}  Catch [Exception] {
			#Do nothing. Seems like we have no warnings
		}
	}

	#If any relevant message then output
	If(($relevantMessages)) {
		Trace " 7-Zip reported the following messages " $BkLogFile
		Trace " ----------------------------------------" $BkLogFile
		$relevantMessages | ForEach-Object {
			Trace " $_" $BkLogFile; $gP.WarningsCount += 1
		}
		Trace " " $BkLogFile
	}

	
	# Check exit code by 7zip - If ErrorLevel is <2 then we assume backup
	# process completed successfully
	If(($Bk7ZipRetc -lt 2) -And (Test-Path -Path "$BkDestFile" -PathType Leaf)) {
		
		# Output informations in log file 
		Get-Item "$BkDestFile" | ForEach-Object {
			
			Trace " Created $BkArchiveName in $BkDestPath " $BkLogFile
			Trace (" Archive Size {0,0:n2} MB. Compression {1,2:n2} %" -f ($_.Length / 1MB), ((1 - ($_.Length / $gP.BytesSelected)) * 100)) $BkLogFile
			Trace (" Completed in {0,0:n0} days, {1,0:n0} hours, {2,0:n0} minutes, {3,0:n0} seconds" -f $elapsed.Days, $elapsed.Hours, $elapsed.Minutes, $elapsed.Seconds ) $BkLogFile
			Trace (" Perfomance {0,0:n2} MB/Sec." -f (($gP.BytesSelected / $elapsed.TotalSeconds) / 1MB)) $BkLogFile
			Trace " " $BkLogFile
			
		}
		
		# Do Post Archiving
		If(!(Check-UserCancelRequest -eq $True)) { PostArchiving ; }
		
		# Do rotation over backup files
		# We have to list all files in the destination directory matching the same prefix and the same type
		# list all items descending (by their creation date) and then delete the oldest out of
		# the rotation range. If no rotation is defined then assume rotation period is 999 so we
		# can easily have an output of archives on target media.
		If(!(Check-UserCancelRequest -eq $True)) {
			If(!(IsVarDefined "BkRotate")) { Set-Variable -name "BkRotate" -value ([int]999) -scope Script }
			If(($BkRotate -ge 1)) {
				Trace " Archives in $BkDestPath" $BkLogFile
				Trace " ----------------------------------------" $BkLogFile
				Get-ChildItem $BkDestPath -fi ($BkArchivePrefix + "-" + $BkType + "-*.*") | sort @{expression={$_.LastWriteTime};Descending=$true} | foreach-object {
					If(!($BkRotate -le 0)) { 
						Trace (" Kept     : {0} {1,15:n2} MB " -f $_.Name, $($_.Length / 1MB) ) $BkLogFile
						$BkRotate += -1
					} Else {
						remove-item -literalpath (Join-Path $BkDestPath $_.Name) -ErrorAction "SilentlyContinue" | Out-Null
						if ($?) { Trace (" Removed  : {0} {1,15:n2} MB " -f $_.Name, $($_.Length / 1MB) ) $BkLogFile } Else { Trace " WARNING Failed to remove $_" $BkLogFile}
					}
				}
				Trace " " $BkLogFile
			}
		}
	
		Trace " " $BkLogFile
		If(($gP.WarningsCount -gt 0)) {
			Trace (" Done with : " + $gP.WarningsCount + " warnings. Check logs!") $BkLogFile
		} Else {
			Trace " All Done !! Yuppieee" $BkLogFile
		}
		$elapsed = New-TimeSpan $selectStart $(Get-Date)
		Trace (" Completed in {0,0:n0} days, {1,0:n0} hours, {2,0:n0} minutes, {3,0:n0} seconds" -f $elapsed.Days, $elapsed.Hours, $elapsed.Minutes, $elapsed.Seconds ) $BkLogFile
		Trace " " $BkLogFile
		
	} Else {
	
		# Uncomment this line if you want to read the details of 7-Zip log of operations
		#[string]::join([environment]::newline, (Get-Content -path $BkCompressDetail -encoding ASCII)) 
	
		# If we fall down here the 7z.exe has exited with a high error level
		# According to 7-Zip manual the possibilities are:
		# 0   - No error
		# 1   - Warning (Non fatal error(s)). For example, one or more files were locked by some other application, so they were not compressed
		# 2   - Fatal error
		# 7   - Command line error
		# 8   - Not Enough memory to complete operation
		# 255 - User stopped the process
		If (($Bk7ZipRetc -eq 255)) {
			$gP.CriticalCount += 1
			Trace " " $BkLogFile
			Trace " Cancelled ! User has stopped 7-Zip archiving process" $BkLogFile
			Trace " NO ARCHIVE HAS BEEN CREATED" $BkLogFile
		} ElseIf (($Bk7ZipRetc -eq 2)) {
			$gP.CriticalCount += 1
			Trace " " $BkLogFile
		    Trace " Cancelled ! 7-Zip reported a fatal error." $BkLogFile
			Trace " NO VALID ARCHIVE HAS BEEN CREATED" $BkLogFile
		} ElseIf (($Bk7ZipRetc -eq 7)) {
			$gP.CriticalCount += 1
			Trace " " $BkLogFile
		    Trace " Cancelled ! 7-Zip has been invoked with a wrong command line." $BkLogFile
			Trace " $cmdLine" $BkLogFile
			Trace " NO VALID ARCHIVE HAS BEEN CREATED" $BkLogFile
		} ElseIf (($Bk7ZipRetc -eq 8)) {
			$gP.CriticalCount += 1
			Trace " " $BkLogFile
		    Trace " Cancelled ! 7-Zip reports not enough memory." $BkLogFile
			Trace " NO VALID ARCHIVE HAS BEEN CREATED" $BkLogFile
		} ElseIf (!(Test-Path -Path "$BkDestPath\$BkArchiveName" -PathType Leaf)) {
			$gP.CriticalCount += 1
			Trace " " $BkLogFile
			Trace " Error !" $BkLogFile
			Trace " NO ARCHIVE HAS BEEN CREATED" $BkLogFile
		}
		
	}
		
# If is set a list of notification addresses then proceed with email here
if (!(Check-UserCancelRequest -eq $True)) { if ((IsVarDefined "BkNotifyLog")) { SendNotificationEmail } }

# Clean Up 
CleanUp
