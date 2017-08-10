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
#				  Microsoft Windows 8.1    	(tested)
#				  Microsoft Windows 10    	(tested)
#				  Microsoft Windows 2008   	(tested)
#				  Microsoft Windows 2012   	(tested)
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
# -- Version History �
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
#                                            and new directives to stop recursion and to honor (or not)
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
$version = "1.7.2-Stable" # 20101206 Anlan   Bug   : Routine Clear-FsAttribute rewritten due to errors by
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
$version = "1.10.3-Stable" # 20160425 Anlan   Code  : Typo in LasWriteTime instead of LastWriteTime
#                                             Feat  : MaxFileAge and MinFileAge now support Decimal
#                                             Feat  : MaxFileAge and MinFileAge can be passed by CLI
#                                             
$version = "2.0.1-Stable"  # 20160608 Anlan   Code  : Since version 15.x of 7-zip it can now save natively emtpy dirs
#                                                     therefore no need to create dummy files
#                                             Code  : Removed the check for pairs of command arguments.
#                                                     Now the parser checks properly also for switch arguments
#                                             Code  : Refactored Main Scanning Routine to eliminate Stack Overflow
#                                             Feat  : Removed the limit of 100 for maxdepth
#                                             Feat  : Added new command line switch --dry
#                                                     This causes the script to go through all scanning directives
#                                                     but no compression or archiving is perfomed.
#                                             Bug   : rotation of archives might delete directories with same name
#                                                     Included check for "is not a PSContainer"
#                                             Feat  : --emptydirs is now a switch argument
#                                             Feat  : addedd --compression argument
#                                             Feat  : Removed the parsing of BkSwitches
#                                             Feat  : addedd --pre and --post action switches to enable 
#                                                     the execution of personalized scripts before and after
#                                                     the archiving process
#                                             Bug   : MaxFileAge and MinFileAge are fixed as double
#                                             Feat  : Archive name gets composed with trailing seconds
#                                             Feat  : Refactored writing of logs and details with StreamWriters
#                                                     instead of Out-File. Now scanning speed is 5x up to 20x
#                                             Code  : Refactored async launch of 7-zip process to get proper return core
#                                             Feat  : --maxfileage and --minfileage can now be passed as switches
#                                             Feat  : --maxfilesize and --minfilesize can now be passed as switches
#                                             Feat  : --pre and --post switches can invoke pws actions
#                                             Feat  : --threads switch can control resource usage by 7-zip
#
$version = "2.0.2-Stable"  # 2016xxxx Anlan   Bug   : Improper output when Send-Notification is invoked
#                                             Feat  : added --solid switch to enable or disable solid archives
#                                             Feat  : compression / solid mode / threads can be also set in selection file
#                                             Code  : adjusted checks on removal of reparse points
#                                             Code  : adjusted count of maximum threads on single core sockets
#                                             Feat  : added switch -mhe for password protected archives
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

Set-Variable -Name "MyContext" -Value ([hashtable]::Synchronized(@{})) -Scope Script
$MyContext.Name       = $MyInvocation.MyCommand.Name
$MyContext.Definition = $MyInvocation.MyCommand.Definition
$MyContext.Directory  = (Split-Path (Resolve-Path $MyInvocation.MyCommand.Definition) -Parent)
$MyContext.StartDir   = (Get-Location -PSProvider FileSystem).ProviderPath
$MyContext.WinVer     = (Get-WmiObject Win32_OperatingSystem).Version.Split(".")
$MyContext.PSVer      = [int]$PSVersionTable.PSVersion.Major
$MyContext.Cancelling = $False
$MyContext.DummyFile  = ".7zb"

$headerText = @"

 ------------------------------------------------------------------------------
 
  7zBackup.ps1 ver. $version (http://7zbackup.codeplex.com)
  
 ------------------------------------------------------------------------------
 
"@

$helpText = @"
 Usage : .\7zBackup.ps1 --type < full | incr | diff | copy | move >
                        --selection < full path to file name >
                        --destpath < destination path >
                       [--jbin < path to Junction.exe > ]
					   
                       -- Job specific switches --					  
                       [--dry]						
                       [--workdrive < working drive letter >]
                       [--rotate < number >]
                       [--logfile < filename >]
                       [--pre < filename | `{scriptblock`} >]
					   [--post < filename | `{scriptblock`} >]
					   
                       -- Selection specific switches --					   
                       [--maxdepth < number > ]
                       [--maxfileage < double > ]
                       [--minfileage < double > ]
                       [--maxfilesize < long > ]
                       [--minfilesize < long > ]
                       [--clearbit < True | False >]
                       [--emptydirs]

                       -- Archive (7-zip) specific switches --
                       [--prefix < string >]					   
                       [--7zipbin < path to 7z.exe > ]					   
                       [--archivetype < 7z | zip | tar >]
                       [--compression < 0 | 1 | 3 | 5 | 7 | 9 >]
                       [--threads < number >]
                       [--solid < True | False >]					   
                       [--password < string >]
                       [--encryptheaders]
                       [--workdir < working directory > OBSOLETE]
					   
                       -- Notification specific switches --
                       [--notifyto < email1@domain`[,email2@domain`[..`]`] >]
                       [--notifyfrom < sender@domain >]
                       [--notifyextra < none | inline | attach >]
                       [--smtpserver < host or ip address >]
                       [--smtpport < default 25 >]					  
                       [--smtpuser < SMTPAuth's user >]					  
                       [--smtppass < SMTPAuth's password >]					  
                       [--smtpssl]	


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
               tar  : unix and linux compatible but only archiving (no compression)

 --compression The level of compression you want to achieve.
               Possible values are [0 | 1 | 3 | 5 | 7 | 9 ].
               where lower values mean almost no compression and fast
               archiving while higher values mean the opposite.
               If omitted 7zip will use default settings			   

 --threads     Number of threads 7zip is allowed to use. If not set then
               7zip will try to adopt one thread per core. Set this value
               to 1 or 0 to disable multithreading.
			   
 --solid       Sets wether or not 7z archives should endorse solid format
               By default 7z archives endorse solid format. Refer to
               7-zip documentation to understand what are solid archives.
 
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
               positive integers. It can be specified either as command argument
               or in the hardcoded vars file, or in the selection file.

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
               This is a switch argument
 
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
               locate 7z.exe in program files folders
			   
 --jbin        Specify full path to Junction.exe. 
               If the argument is not provided the script will try to
               locate Junction.exe in program files folders
               This parameter is optional when the script is invoked
               on Windows systems which support MKLINK.
			  
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

 --smtpssl     Wheather or not smtp transport requires ssl
               This is a switch argument

 --dry         Complete the process without creating any archive file
               nor changing/deleting/clearing any file

 --pre         Pointer to a pws script or a script block to be execute 
               before scanning process starts
			   
 --post        Pointer to a pws script or a script block to be execute 
               after archiving procedure completes regardless it's been
               succesfull or not
 -----------------------------------------------------------------------
 
"@

# ====================================================================
# Start Functions Library
# ====================================================================

# Legend for Attributes bits on files
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
# Function 		: Do-PostAction
# -----------------------------------------------------------------------------
# Description	: Executes a job after execution
# Returns       : 
# Credits       : 
# -----------------------------------------------------------------------------
Function Do-PostAction {

	# --------------------------------------------------------------------------------
	# Execute post Action if we have any 
	# --------------------------------------------------------------------------------
	If(Test-Variable "BkPostAction") {

		Trace " Invoking Post-Action (Output follows if any)"
		Trace " ------------------------------------------------------------------------------"
		Try {
			& $BkPostAction 2>&1 | Set-Variable -Name "postActionOutput" -Scope Script
			$postActionOutput | ForEach-Object {
				Trace " $_"
			}
		} Catch {
			Trace " $_.Exception.Message"
		}
		Trace " ------------------------------------------------------------------------------"
		Trace " "
		
	}

}

# -----------------------------------------------------------------------------
# Function 		: Check-CTRLCRequest
# -----------------------------------------------------------------------------
# Description	: Checks whether or not the user hit CTRL + C to request
#                 script cancel
# Parameters    : 
# Returns       : $True / $False
# Credits       : 
# -----------------------------------------------------------------------------
Function Check-CTRLCRequest {

	If($MyContext.Cancelling -ne $True) {
		If($Host.UI.RawUI.KeyAvailable -and [int]$Host.UI.RawUI.ReadKey("AllowCtrlC,IncludeKeyUp,NoEcho").Character -eq 3) {
			$MyContext.Cancelling = $True
			Trace " " 
			Trace " User requested to abort ... "
			Trace " " 
		} 
	}
	$Host.UI.RawUI.FlushInputBuffer()
	Write-Output ($MyContext.Cancelling)
}


# -----------------------------------------------------------------------------
# Function 		: Check-FsAttribute
# -----------------------------------------------------------------------------
# Description	: Checks for the presence of an attribute on a FileSystem object
# Parameters    : [string]itemFullName - The name of the item to check
#				  [string]attrName     - The name of the attribute to look for
# Returns       : $True / $False
# Credits       : http://scriptolog.blogspot.com/2007/10/file-attributes-helper-functions.html
# -----------------------------------------------------------------------------
Function Check-FsAttribute {
    param([string]$itemFullName = $(throw "You must provide an item name"),
	      [string]$attrName = $(throw "You must provide an attribute name"))

	$item = Get-Item -literalPath $itemFullName -Force 
	Write-Output (($?) -and ($item) -and ($item.Attributes -band [System.IO.FileAttributes]::$attrName))
} 

# -----------------------------------------------------------------------------
# Function 		: Clear-FsAttribute
# -----------------------------------------------------------------------------
# Description	: Lowers an attribute on a file
# Parameters    : [string]fileFullName - The name of the File to work on
#				  [string]attrName - The name of the attribute to lower
# Returns       : $True / $False
# Credits       : http://scriptolog.blogspot.com/2007/10/file-attributes-helper-functions.html
# -----------------------------------------------------------------------------
Function Clear-FsAttribute {
    param([string]$fileFullName = $(throw "You must provide a file name"),
	      [string]$attrName = $(throw "You must provide an attribute name"))

	# Do Nothing in DryRun mode
	If($BkDryRun) { Write-Output $True; Return }
	
	# Lower attribute bit
	$item = (Get-Item -LiteralPath $fileFullName -Force)
	If(!($?)) {
		Write-Output $False
	} Else {
		If(($item.Attributes -band [System.IO.FileAttributes]::$attrName)) {
			$item = ( $item | Set-ItemProperty -Name Attributes -Value ($item.Attributes -bXor [System.IO.FileAttributes]::$attrName) -Force -PassThru)
			Write-Output (($?) -and ($item)) 
			Return
		}
		Write-Output $True
	}

} 

# -----------------------------------------------------------------------------
# Function 		: Clear-Script
# -----------------------------------------------------------------------------
# Description	: Cleans all files created by the script and leaves the system
#                 in a state which allows another go.
# Parameters    : -
# Returns       : Nothing
# -----------------------------------------------------------------------------
Function Clear-Script {

	#Ensure file stream writers are closed
	$SWriters.GetEnumerator() | ForEach-Object {
		Try {
		$_.Value.Flush()
		$_.Value.Close()
		$_.Value.Dispose()
		} Catch {}
	}

	
    If ((Test-Variable "cmdLineBatch")) {if ((Test-Path ($cmdLineBatch))) { Remove-Item -LiteralPath $cmdLineBatch | Out-Null }}
	If ((Test-Variable "BkLogFile")) {if ((Test-Path ($BkLogFile))) { Remove-Item -LiteralPath $BkLogFile | Out-Null }}
	If ((Test-Variable "BkLockFile")) {if ((Test-Path ($BkLockFile))) { Remove-Item -LiteralPath $BkLockFile | Out-Null }}
	Set-Location ($MyContext.StartDir)
	If ((Test-Path -Path ($BkRootDir) -PathType Container)) { Remove-RootDir $BkRootDir | Out-Null }
	[console]::TreatControlCAsInput = $False
	
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
	Write-Output ($emailAddress -match "^[a-zA-Z][\w\.-]*[a-zA-Z0-9]@[a-zA-Z0-9][\w\.-]*[a-zA-Z0-9]\.[a-zA-Z][a-zA-Z\.]*[a-zA-Z]$")
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
	Write-Output ($hostName -match "^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z]|[A-Za-z][A-Za-z0-9\-]*[A-Za-z0-9])$")
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
	Set-Variable -name "Ip" -value ([System.Net.IPAddress]::Parse("127.0.0.1")) -scope Local
	Write-Output ([System.Net.IPAddress]::TryParse($ipAddress, [ref]$Ip))
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
	If(Test-Path -Path $jTarget) {
	
		# Junction it (from alias)
		CMD /C $BkJunctionBin /accepteula `"$jPath`" `"$jTarget`" | Out-Null
		Start-Sleep -Milliseconds 10
		
		# Test is present
		Write-Output (Test-Path -Path $jPath)
		Return

		
	}
	Write-Output $False
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
	If(Test-Path $jTarget) {
	
		# Create Link
		cmd /c ("MKLINK /D `"{0}`" `"{1}`"" -f $jPath, $jTarget) | Out-Null
		Start-Sleep -Milliseconds 10
		
		# Test is present
		Write-Output (Test-Path -Path $jPath)
		Return
		
	}
	Write-Output $False
}

# -----------------------------------------------------------------------------
# Function 		: New-RootDir
# -----------------------------------------------------------------------------
# Description	: This function creates a new randomly named root dir
#				  where all junctions will be created
# Parameters    : [string]rootPath - The name of the directory to remove
# Returns       : $True / $False
# -----------------------------------------------------------------------------
Function New-RootDir {

	# Create Root Directory and place a huge README.TXT
	New-Item -Path $BkRootDir -ItemType Directory | Out-Null
	If(!$?) { 
		Write-Output ("Unable to create directory {0}. Check permissions." -f $path)
		Return
	} Else {
		If([int]$MyContext.WinVer[0] -lt 6 ) {
			New-Item (Join-Path -Path $BkRootDir -ChildPath "__README__PLEASE__README__.txt") -type File -value "This directory contains Junctions.`nDO NOT DELETE THIS DIRECTORY AND IT'S CONTENTS USING WINDOWS EXPLORER.`nUse Junction -d to delete junctions and then safely delete the directory." | Out-Null
		} Else {
			New-Item (Join-Path -Path $BkRootDir -ChildPath "__README__PLEASE__README__.txt") -type File -value "This directory contains Symbolic Links.`nDO NOT DELETE THIS DIRECTORY AND IT'S CONTENTS USING WINDOWS EXPLORER.`nUse RD command delete symbolic links and then safely delete the directory." | Out-Null
		}
		If(!$?) {
			Write-Output ("Can't write into {0}. Check permissions." -f $path)
			Return
		}
	}
	
}

# -----------------------------------------------------------------------------
# Function 		: PostArchiving
# -----------------------------------------------------------------------------
# Description	: This routine reprocess succesfully archived files
# Parameters    : 
# Returns       : 
# -----------------------------------------------------------------------------
Function PostArchiving {
	
	[console]::TreatControlCAsInput = $True
	# -----------------------------------------------------------
	# Remove created placeholders if any
	# -----------------------------------------------------------
	if ($Counters.PlaceHolders.count -gt 0) {
		Write-Progress -Activity  "Performing post archive operations" -Status "Please wait ..." -CurrentOperation "Removing Placeholders for Empty Directories"
		$Counters.PlaceHolders | Remove-Item -Force | Out-Null
		Write-Progress -Activity "." -Status "." -Completed
	}
	If(
		(Check-CTRLCRequest) -Or
		(($BkType -ne "move") -And !($BkClearBit))
	) { Return; }

	# Load compress details data with respect of different log formats for different 7zip versions
	If(Test-Variable "BkCompressDetailItems") { Remove-Variable -Name BkCompressDetailItems}
	If ([int]$MyContext.SevenZBinVersionInfo.Major -gt 9) {	
		Get-Content -Path $BkCompressDetail -Encoding UTF8 | Where-Object {$_ -match "^\+"} | Select @{Name="File";Expression={($_.Substring(2))}} | Set-Variable -Name "BkCompressDetailItems" -Scope Script
	} Else {
		Get-Content -Path $BkCompressDetail -Encoding UTF8 | Where-Object {$_ -match "^Compressing\ \ "} | Select @{Name="File";Expression={($_.Substring(13))}} | Set-Variable -Name "BkCompressDetailItems" -Scope Script
	}
	
	If( !($BkCompressDetailItems) -Or
	    ($BkCompressDetailItems.Count -eq 0) -Or
		(Check-CTRLCRequest)
	) { Return }
	
	# Remove files successfully archived if necessary
	Trace " Post Processing Successfully Archived Files"
	Trace " -------------------------------------------"
	$MyContext.PostProcessFilesStart = Get-Date
	Set-Variable -Name "ArchivedItemsCount" -Value ($BkCompressDetailItems.Count) -Scope Local
	Set-Variable -Name "OperationType" -Value "Clearing" -Scope Local
	If($BkType -eq "move") {$OperationType = "Removing"}
	
	For ($i=0; $i -lt $ArchivedItemsCount; $i++) {
		If(Check-CTRLCRequest -eq $True) { break; }
		$percentCompleted = ( $i / ($ArchivedItemsCount - 1) * 100 )
		Write-Progress -Activity  "Performing post archive operations" -Status "Please wait ..." -CurrentOperation ("{0} successfully archived files" -f $OperationType)  -PercentComplete $percentCompleted
		$item = Get-Item -LiteralPath (Join-Path $BkRootDir $BkCompressDetailItems[$i].File)
		if($? -and $item) {
			If($BkType -eq "move") {
				$item | ? { !$_.PSIsContainer } | Remove-Item -Force | Out-Null
				If(!($?)) {Trace (" Could not remove file : {0}" -f $itemName ); $Counters.Warnings++  }
			} Else {
				If(($item.Attributes -band [System.IO.FileAttributes]::Archive)) {
					$item = ( $item | Set-ItemProperty -Name Attributes -Value ($item.Attributes -bXor [System.IO.FileAttributes]::Archive) -Force -PassThru)
					If(!($?)) {
						Trace (" Could not clear archive attribute : {0}" -f $item.FullName ); $Counters.Warnings++
					}
				}
			}
		}
	}
	
	Write-Progress -Activity "." -Status "." -Completed
	$MyContext.PostProcessFilesEnd = Get-Date
	$MyContext.PostProcessFilesElapsed = New-TimeSpan $MyContext.PostProcessFilesStart $MyContext.PostProcessFilesEnd
	Trace " "
	Trace (" Completed in {0,0:n0} days {1,0:n0} hours {2,0:n0} minutes {3,0:n3} seconds" -f $MyContext.PostProcessFilesElapsed.Days, $MyContext.PostProcessFilesElapsed.Hours, $MyContext.PostProcessFilesElapsed.Minutes, ($MyContext.PostProcessFilesElapsed.Seconds + ($MyContext.PostProcessFilesElapsed.MilliSeconds/1000)) )		
	Trace " "

	
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
Function ProcessFolder ($thisFolder) {

	[console]::TreatControlCAsInput = $True
	# Increment number of processed folders
	$Counters.FoldersDone++
	
	# Status
	Write-Progress -Activity ("Folder {0}" -f $thisFolder.RealName) -CurrentOperation "Checking ... " -Status ("Selected {0,0:n0} out of {1,0:n0} files in {2,0:n0} folders. {3,0:n2} MBytes to backup" -f  $Counters.FilesSelected, $Counters.FilesProcessed, $Counters.FoldersDone, ($Counters.BytesSelected / 1MB ))
	
	# Verify wether or not we have to scan this folder for files or stop recursion due to regexp or maxdepth reached
	$scanThisPathForFiles = $True
	$scanThisPathForRecursion = $True
	If(($matchexcludepath) -and ($thisFolder.RelativeName -imatch $matchexcludepath)) {
		$scanThisPathForFiles = $False 
		$SWriters.Exclusions.WriteLine([string]("{0}`t{1}`t{2}`t{3}" -f $Counters.Exclusions++, "matchexcludepath", "D", $thisFolder.RealName))
	}
	If((Test-Variable "BkMaxDepth") -and ($thisFolder.Depth -eq [int]$BkMaxDepth)) {
		$scanThisPathForRecursion = $False
		$SWriters.Exclusions.WriteLine([string]("{0}`t{1}`t{2}`t{3}" -f $Counters.Exclusions++, "maxdepth", "D", $thisFolder.RealName))
	}
	If( ($scanThisPathForRecursion) -and (($matchstoprecurse) -and ($thisFolder.RelativeName -imatch $matchstoprecurse )) ) {
		$scanThisPathForRecursion = $False
		$SWriters.Exclusions.WriteLine([string]("{0}`t{1}`t{2}`t{3}" -f $Counters.Exclusions++, "matchstoprecurse", "D", $thisFolder.RealName))
	}
	
	If(Check-CTRLCRequest -eq $True) { return }
	# Early exit if we do not have to scan anything
	If(!$scanThisPathForFiles -and !$scanThisPathForRecursion) { return }
	
	# Get-ChildItems in folder
	# Status
	Write-Progress -Activity ("Folder {0}" -f $thisFolder.RealName) -CurrentOperation "Loading ... " -Status ("Selected {0,0:n0} out of {1,0:n0} files in {2,0:n0} folders. {3,0:n2} MBytes to backup" -f  $Counters.FilesSelected, $Counters.FilesProcessed, $Counters.FoldersDone, ($Counters.BytesSelected / 1MB ))
	
	Remove-Variable childItemsScanErrors -Scope Local | Out-Null
	$childItems = @(Get-ChildItem -LiteralPath $thisFolder.RelativeName -Force -ErrorVariable childItemsScanErrors)
	If($childItemsScanErrors) {
		for ($i=0; $i -lt $childItemsScanErrors.count; $i++) {
			$realTargetName = $childItemsScanErrors[$i].CategoryInfo.TargetName.Replace($BkRootDir + "\" , "")
			$realTargetName = $realTargetName.Replace($realTargetName.Split("\")[0],"")
			$realTargetName = [string](Join-Path -Path $BkSources[$thisFolder.ContainerAlias] -ChildPath $realTargetName)
			$SWriters.Exceptions.WriteLine(("{0}`t{1}`t{2}" -f $Counters.Exceptions++, $childItemsScanErrors[$i].CategoryInfo.Reason, $realTargetName))
		}
	}

	# Status
	Write-Progress -Activity ("Folder {0}" -f $thisFolder.RealName) -CurrentOperation "Scanning ... " -Status ("Selected {0,0:n0} out of {1,0:n0} files in {2,0:n0} folders. {3,0:n2} MBytes to backup" -f  $Counters.FilesSelected, $Counters.FilesProcessed, $Counters.FoldersDone, ($Counters.BytesSelected / 1MB ))
	
	# If it is an empty directory
	If($scanThisPathForRecursion -and (!$childFiles.Count) -and ($BkKeepEmptyDirs -eq $True) -and !($childItemsScanErrors)) {
		
		# Older versions of 7zip require at least one file to save a folder
		# Newer versions will simply create the folder
		If ([int]$MyContext.SevenZBinVersionInfo.Major -le 9) {	
			# Try to drop a placeholder file and reload child items
			$childFile = New-Item (Join-Path -Path $thisFolder.RelativeName -ChildPath $MyContext.DummyFile) -type File
			If($?) { 
				$Counters.PlaceHolders += $childFile
				$SWriters.Inclusions.WriteLine([string](Join-Path -Path $thisFolder.RelativeName -ChildPath $childFile.Name))
			}
			Return
		} Else {
			$SWriters.Inclusions.WriteLine([string]$thisFolder.RelativeName)
			Return
		}
	
	}
	
	# Process Files Within The Container
	If($scanThisPathForFiles) {
		$childFiles = @($childItems | ? {!$_.PSIsContainer})
		If($childFiles.Count) {
			for ($i=0; $i -lt $childFiles.Count; $i++) {
				
				$Counters.FilesProcessed++
				
				$childFile = $childFiles[$i]
				$childFileRealName = Join-Path -Path $thisFolder.RealName -ChildPath $childFile.Name

				# >>> Clean up files ?
				If(($matchcleanupfiles) -and ($childFileName -match $matchcleanupfiles)) {
					If(!$BkDryRun) {
						Remove-Item -Path $childFile -Force -ErrorVariable childFileRemoveError | Out-Null
						if (!$?) {
							$SWriters.Exceptions.WriteLine([string]("{0}`t{1}`t{2}" -f $Counters.Exceptions++, $childFileRemoveError.CategoryInfo.Reason, $childFileRemoveError.CategoryInfo.TargetName))
							continue
						}
					} Else {
						Write-Host (" Would remove {0} " -f $childFileRealName)
					}
				}
				# <<<

				# Archive Attribute : is it set as we need it ?
				If((($BkType -ieq "incr") -or ($BkType -ieq "diff")) -and !($childFile.Attributes -band 32)) { 
					continue
				}
				
				# Match Include ?
				If(($matchincludefiles) -and ($childFile.Name -notmatch $matchincludefiles) ) { 
					$SWriters.Exclusions.WriteLine([string]("{0}`t{1}`t{2}`t{3}" -f $Counters.Exclusions++, "matchincludefiles", "F", $childFileRealName))
					continue
				}
				
				# Match Exclude ?
				If(($matchexcludefiles) -and ($childFile.Name -match $matchexcludefiles) ) { 
					$SWriters.Exclusions.WriteLine([string]("{0}`t{1}`t{2}`t{3}" -f $Counters.Exclusions++, "matchexcludefiles", "F", $childFileRealName))
					continue
				}

				# Check the file falls into MaxFileAge
				If(($BkMaxFileAge) -and ((New-Timespan $childFile.LastWriteTime $MyContext.SelectionStart).TotalDays -gt $BkMaxFileAge) ) {
					$SWriters.Exclusions.WriteLine([string]("{0}`t{1}`t{2}`t{3}" -f $Counters.Exclusions++, "maxfileage", "F", $childFileRealName))
					continue
				}
	
				# Check the file falls into MinFileAge
				If(($BkMinFileAge) -and ((New-Timespan $childFile.LastWriteTime $MyContext.SelectionStart).TotalDays -lt $BkMinFileAge) ) {
					$SWriters.Exclusions.WriteLine([string]("{0}`t{1}`t{2}`t{3}" -f $Counters.Exclusions++, "minfileage", "F", $childFileRealName))
					continue
				}

				# Check the file falls into MaxFileSize
				If(($MaxFileSize) -and ($childFile.Length -gt $MaxFileSize) ) {
					$SWriters.Exclusions.WriteLine([string]("{0}`t{1}`t{2}`t{3}" -f $Counters.Exclusions++, "maxfilesize", "F", $childFileRealName))
					continue
				}

				# Check the file falls into MinFileSize
				If(($MinFileSize) -and ($childFile.Length -lt $MinFileSize) ) {
					$SWriters.Exclusions.WriteLine([string]("{0}`t{1}`t{2}`t{3}" -f $Counters.Exclusions++, "minfilesize", "F", $childFileRealName))
					continue
				}

				# Update counters
				$Counters.FilesSelected++ ; 
				$Counters.BytesSelected += $childFile.Length ;
				$SWriters.Inclusions.WriteLine([string](Join-Path -Path $thisFolder.RelativeName -ChildPath $childFile.Name))
				# Save Catalog Stats
				$SWriters.Stats.WriteLine([string]("{0}`t{1}`t{2}" -f $Counters.FilesSelected,$childFile.Extension,$childFile.Length ))
				
				
			}
		}
	}
	
	# Process Directories Within The Container
	If($scanThisPathForRecursion -And (!(Check-CTRLCRequest -eq $True))) {
		$childFolders = @($childItems | ? {$_.PSIsContainer})
		If($childFolders.Count) {
			for ($i=0; $i -lt $childFolders.Count; $i++) {

				$childFolderItem = @{}
				$childFolderItem.Name = $childFolders[$i].Name
				$childFolderItem.FullName = $childFolders[$i].FullName
				$childFolderItem.RelativeName = $childFolders[$i].FullName.Replace($BkRootDir + "\" , "")
				$childFolderItem.ContainerAlias = $thisFolder.ContainerAlias
				$childFolderItem.RealName = Join-Path -Path $BkSources[$thisFolder.ContainerAlias] -ChildPath ($childFolderItem.RelativeName.Replace($thisFolder.ContainerAlias, ""))
				$childFolderItem.Depth = ($thisFolder.Depth + 1);
				
				# Check subdir against recursion in junctions
				If(($BkNoFollowJunctions) -and ($childFolders[$i].Attributes -band 1024)) {
					$SWriters.Exclusions.WriteLine([string]("{0}`t{1}`t{2}`t{3}" -f $Counters.Exclusions++, "nofollowjunctions", "D", $thisFolder.RealName))
					continue
				}
				
				If ($catalogFoldersIndex -eq $catalogFolders.Count) {
					[void] $catalogFolders.Add($childFolderItem)
				} Else {
					[void] $catalogFolders.Insert(($catalogFoldersIndex + ($i + 1)), $childFolderItem)
				}
			}
		}
	}
	
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

		# UnJunction it
		CMD /C $BkJunctionBin /accepteula -d `"$jPath`" | Out-Null
		Start-Sleep --Milliseconds 10
		
		# Test is no more present !!
		Write-Output ((Test-Path -Path $jPath) -eq $False)
		Return
		
	}
	Write-Output $False
}

# -----------------------------------------------------------------------------
# Function 		: Remove-RootDir
# -----------------------------------------------------------------------------
# Description	: This function safely removes the Root Directory generated for
#				  the purpouse of holding junction points to included sources.
#				  Before it deletes the directory itself, each reparse point
#				  is removed using Junction with the -d switch.
# Parameters    : [string]rootPath - The name of the directory to remove
# Returns       : $True / $False
# -----------------------------------------------------------------------------
Function Remove-RootDir {
	param([string]$rootPath = $(throw "You must provide a path to the directory")) 
	
	If (Test-Path -Path $rootPath -PathType Container) {
		Set-Variable -Name "junctionsRemoved" -Value $True -Scope Private | Out-Null
		Get-ChildItem -Path $rootPath | ? { $_.Attributes -band 1024 } | ForEach-Object {
			If([int]$MyContext.WinVer[0] -lt 6) {
				$junctionsRemoved = Remove-Junction $_.FullName
				If(!$junctionsRemoved) {Return}
			} Else {
				$junctionsRemoved = Remove-SymLink $_.FullName
				If(!$junctionsRemoved) {Return}
			}
		}
		If($junctionsRemoved -And (@(Get-ChildItem -Path $rootPath | ? {$_.PsIsContainer}).Count -eq 0) ) {
			Remove-Item -Path $rootPath -Recurse -Force | Out-Null
			Write-Output $?
			Return 
		}
	}
	Write-Output $False
	
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
		cmd /c ("RD `"{0}`"" -f $jPath)
		Start-Sleep -Milliseconds 10
		
		# Test is no more present !!
		Write-Output ((Test-Path -Path $jPath) -eq $False)
		Return
		
	}
	Write-Output $False
}

# -----------------------------------------------------------------------------
# Function 		: Send-Notification
# -----------------------------------------------------------------------------
# Description	: Sends the notification email to given adressee
# Parameters    : None
# Returns       : $True / $False 
# -----------------------------------------------------------------------------
Function Send-Notification {

		[console]::TreatControlCAsInput = $True
		#Ensure file stream writers are closed
		$SWriters.GetEnumerator() | ForEach-Object {
			Try {
			$_.Value.Flush()
			$_.Value.Close()
			$_.Value.Dispose()
			} Catch {}
		}

		# Do  nothing if we have no-one to notify
		If(!($BkNotifyLog)) { return; }
		
		Write-Host " "
		Write-Host " Sending notification email ..."

		$SmtpClient  = [Object]
		$MailMessage = [Object]
		
		Try {
		
			If(!(Test-Variable "BkMailSubject")) { Set-Variable -name "BkMailSubject" -value ("7zBackup Report Host $Env:ComputerName") -scope Script }
			$SmtpClient = New-Object system.net.mail.smtpClient
			$MailMessage = New-Object system.net.mail.mailmessage
			
			$SmtpClient.Host = $BkSmtpRelay
			$SmtpClient.Port = $BkSmtpPort
			$SmtpClient.EnableSsl = ($BkSmtpSSL)

			# If we have both smtpuser and smtppass then we need to authenticate
			if ((Test-Variable "BkSmtpUser") -and (Test-Variable "BkSmtpPass")) {
				$SmtpUserInfo = New-Object System.Net.NetworkCredential($BkSmtpUser, $BkSmtpPass)
				$SmtpClient.UseDefaultCredentials = $False
				$SmtpClient.Credentials = $SmtpUserInfo
			}

			If(($Counters.Warnings -gt 0)) { $MailMessage.Priority = [System.Net.Mail.MailPriority]::High }
			If(($Counters.Criticals -gt 0)) { $MailMessage.Priority = [System.Net.Mail.MailPriority]::High; $BkMailSubject = "Critical ! $BkMailSubject" }
			$MailMessage.From = $BkSmtpFrom
			If(($BkNotifyLog -is [array])) {
				For ($x=0; $x -lt $BkNotifyLog.Length; $x++) { $MailMessage.To.Add($BkNotifyLog[$x]) }
			} Else { 
				$MailMessage.To.Add($BkNotifyLog) 
			}

			$MailMessage.Subject = $BkMailSubject
			$MailMessage.Body = ((Get-Content -path $BkLogFile -encoding ASCII) -join "`n")
			
			# Do we have to include extra informations ?
			If ($BkNotifyExtra -ne "none") {

				Get-ChildItem -Path $BkRootDir -Force | ? {!$_.PSIsContainer} | ForEach-Object {
					If(	
						($_.Length -gt 0) -And
						($_.Name -notmatch "stats") -And 
						($_.Name -notmatch "README")
					) {
						If($BkNotifyExtra -ieq "attach") {
							$MailAttachment = New-Object System.Net.Mail.Attachment($_.FullName)
							$MailAttachment.Name = $_.Name
							$MailMessage.Attachments.Add($MailAttachment)							
						} Else {
							$MailMessage.Body += ("`n`n{0}`n" -f $_.Name)
							$MailMessage.Body += (Get-Content $_)
						}
					}
				}
				
			}
			
			[void] $SmtpClient.Send($MailMessage) 
			Write-Host " Done" -ForeGroundColor Green
			Write-Host " "
			
			} 
			
		Catch {
			Write-Host (" Unable to send notification email : {0} " -f $_.Exception.Categoryinfo.Reason ) -ForeGroundColor Red
			Write-Host " "
			}
			
		Finally {
			If ($MailMessage.GetType().Name -ieq "MailMessage") { $MailMessage.Dispose() }
		}

}

# -----------------------------------------------------------------------------
# Function 		: Test-Lock
# -----------------------------------------------------------------------------
# Description	: This function is used to check if a previous lock file exists
# Returns       : []
# -----------------------------------------------------------------------------
Function Test-Lock { 

	If(Test-Path -LiteralPath $BkLockFile -pathType Leaf) {

		# A previously executed script has left it's lock file
		Get-Content $BkLockFile -Encoding Ascii | Where-Object {$_ -imatch "^PID="} | ForEach-Object {
			If($_ -match "^PID=")  {Set-Variable -name "OldPid" -value ($_.Substring($_.IndexOf("=") + 1)) -scope Local }
			If($_ -match "^Root=") {Set-Variable -name "OldRoot" -value ($_.Substring($_.IndexOf("=") + 1)) -scope Local }
		}

		If (Test-Variable "OldPid") {
		
			$OldProcess = Get-Process -Id $OldPid 
			If (($?) -And ($OldProcess)) {
				
				If ($OldPid -eq [System.Diagnostics.Process]::GetCurrentProcess().Id) {

				   If ((Test-Variable "OldRoot")) { 
						If(Test-Path $OldRoot -PathType Container ) { Remove-RootDir $OldRoot | Out-Null}
					}
				   Remove-Item -LiteralPath $BkLockFile -Force | Out-Null
			   
				}
					   
				ElseIf ($OldProcess.Responding) {
					
					Write-Output ("A previous operation is running with process id {0}" -f $OldPid)
					Write-Output ("Quitting ...")
					Return
				}
				
				Else {
				
					# Try Stopping the non-responding process
					Stop-Process -Id $OldPid -Force | Out-Null
					If(!($?)) {
						Write-Output ("A previous operation is not responding with process id {0}" -f $OldPid)
						Write-Output ("Quitting ...")
						Return
					}
					If(Test-Variable "OldRoot") { If(Test-Path -LiteralPath $OldRoot -PathType Container ) { Remove-RootDir $OldRoot | Out-Null } }
					Remove-Item -LiteralPath $BkLockFile | Out-Null
					If(!($?)) {
						Write-Output ("Could not remove a previous lock file")
						Write-Output ("Quitting ...")
						Return
					}
					
				}
				
			}
			   

				
		} Else {
		
			If ((New-TimeSpan -End (Get-Date) -Start (Get-Item -LiteralPath $BkLockFile).LastWriteTime).TotalHours -gt 72) { 
			
				Remove-Item -LiteralPath $BkLockFile | Out-Null  
				If(!($?)) {
					Write-Output ("Could not remove a previous lock file")
					Write-Output ("Check lock file {0}" -f $BkLockFile )
					Write-Output ("Quitting ...")
					Return
				}
				
			} Else {
				
				Write-Output ("A previous operation is running or has stopped abnormally")
				Write-Output ("Check lock file {0}" -f $BkLockFile )
				Write-Output ("Quitting ...")
				return
			
			}
		}

	} 
	
	# Drop a new lock file in place
	New-Item -Path $BkLockFile -ItemType File -Force | Out-Null
	If ($?) {("PID={0}`nRoot={1}" -f [System.Diagnostics.Process]::GetCurrentProcess().Id, $BkRootDir) | Out-File $BkLockFile -encoding ASCII -append }
	If(!($?)) {
		Write-Output ("Could not write lock file")
		Write-Output ("Quitting ...")
		Write-Output (" ")
		Return
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
	If(Test-Path -Path $testPath -PathType Container) {
	
		# Generate a dummy file name with a Guid
		$dummyItem = Join-Path $testPath ( [System.Guid]::NewGuid().ToString() )
		
		# Try to create new file in tested path
		if (( $testType -ieq "file" )) {
			New-Item $dummyItem -type File -force -value "This is only a test file. You can delete it safely." | Out-Null
		} Else {
			New-Item $dummyItem -type Directory -force | Out-Null
		}
		If ($?) {
			Remove-Item $dummyItem | Out-Null
			Write-Output $?
			Return
		} Else { 
			Write-Output $?
			Return
		}
		
	}
	Write-Output $False
}

# -----------------------------------------------------------------------------
# Function 		: Test-Variable
# -----------------------------------------------------------------------------
# Description	: This function is used to check if a variables name exist
#				  in the Variables scope
# Parameters    : [string]varName - The name of the Variable to test for
# Returns       : $True / $False
# -----------------------------------------------------------------------------
Function Test-Variable { 
	param([string]$varName = $(throw "You must provide a variable name"))
	Get-Variable -name $varName -scope Script | Out-Null
	Write-Output $?
}

# -----------------------------------------------------------------------------
# Function 		: Trace
# -----------------------------------------------------------------------------
# Description	: Outputs message to console and to logfile
# Parameters    : [string]$message  - The message to output
# Returns       : --
# -----------------------------------------------------------------------------
Function Trace ($message) {
	Write-Host ($message) 
	$SWriters.Log.WriteLine($message)
}

# -----------------------------------------------------------------------------
# Function 		: Pause
# -----------------------------------------------------------------------------
# Description	: Outputs message to console and waits for any key
# Parameters    : [string]$message  - The message to output
# Returns       : --
# -----------------------------------------------------------------------------
Function Pause ($Message="`n Paused. Press any key to continue...`r") {
	Write-Host -NoNewLine $Message
	$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
	Write-Host "                                                          "
}

# -----------------------------------------------------------------------------
# Function 		: Validate-Arguments
# -----------------------------------------------------------------------------
# Description	: This function is used to check input arguments
# Parameters    : None
# Returns       : An array of error messages (if any)
# -----------------------------------------------------------------------------
Function Validate-Arguments {

	If($BkArguments.length -ne 0) {
		$i = 0
		do {
			switch ($BkArguments[$i]) { 
				"--type"            { Set-Variable -name BkType -value $BkArguments[++$i] -scope Script }
				"--workdir"         { Set-Variable -name BkWorkDir -value $BkArguments[++$i] -scope Script }
				"--workdrive"       { Set-Variable -name BkWorkDrive -value $BkArguments[++$i] -scope Script }
				"--selection"       { Set-Variable -name BkSelection -value $BkArguments[++$i] -scope Script }
				"--destpath"        { Set-Variable -name BkDestPath -value $BkArguments[++$i] -scope Script }
				"--archiveprefix"   { Set-Variable -name BkArchivePrefix -value $BkArguments[++$i] -scope Script }
				"--prefix"          { Set-Variable -name BkArchivePrefix -value $BkArguments[++$i] -scope Script }
				"--archivetype"     { Set-Variable -name BkArchiveType -value $BkArguments[++$i] -scope Script }
				"--compression"     { Set-Variable -name BkArchiveCompression -value $BkArguments[++$i] -scope Script }
				"--threads"         { Set-Variable -name BkArchiveThreads -value $BkArguments[++$i] -scope Script }
				"--solid"           { Set-Variable -name BkArchiveSolid -value $BkArguments[++$i] -scope Script }
				"--archivepassword" { Set-Variable -name BkArchivePassword -value $BkArguments[++$i] -scope Script }
				"--password"        { Set-Variable -name BkArchivePassword -value $BkArguments[++$i] -scope Script }
				"--encryptheaders"  { Set-Variable -name BkEncryptHeaders -value $True -scope Script }
				"--rotate"          { Set-Variable -name BkRotate -value $BkArguments[++$i] -scope Script }
				"--emptydirs"       { Set-Variable -name BkKeepEmptyDirs -value $True -scope Script }
				"--maxdepth"        { Set-Variable -name BkMaxDepth -value $BkArguments[++$i] -scope Script }
				"--maxfileage"      { Set-Variable -name BkMaxFileAge -value $BkArguments[++$i] -scope Script }		
				"--minfileage"      { Set-Variable -name BkMinFileAge -value $BkArguments[++$i] -scope Script }				
				"--maxfilesize"     { Set-Variable -name BkMaxFileSize -value $BkArguments[++$i] -scope Script }		
				"--minfilesize"     { Set-Variable -name BkMinFileSize -value $BkArguments[++$i] -scope Script }				
				"--clearbit"        { Set-Variable -name BkClearBit -value $BkArguments[++$i] -scope Script }
				"--logfile"         { Set-Variable -name BkLogFile -value $BkArguments[++$i] -scope Script }
				"--notify"          { Set-Variable -name BkNotifyLog -value $BkArguments[++$i] -scope Script }
				"--notifyto"        { Set-Variable -name BkNotifyLog -value $BkArguments[++$i] -scope Script }
				"--notifyfrom"      { Set-Variable -name BkSmtpFrom -value $BkArguments[++$i] -scope Script }
				"--notifyextra"     { Set-Variable -name BkNotifyExtra -value $BkArguments[++$i] -scope Script }		
				"--smtpserver"      { Set-Variable -name BkSmtpRelay -value $BkArguments[++$i] -scope Script }
				"--smtpport"        { Set-Variable -name BkSmtpPort -value $BkArguments[++$i] -scope Script }
				"--smtpuser"        { Set-Variable -name BkSmtpUser -value $BkArguments[++$i] -scope Script }
				"--smtppass"        { Set-Variable -name BkSmtpPass -value $BkArguments[++$i] -scope Script }
				"--smtpssl"         { Set-Variable -name BkSmtpSSL -value $True -scope Script }
				"--7zbin"           { Set-Variable -name Bk7ZipBin -value $BkArguments[++$i] -scope Script }
				"--7zipbin"         { Set-Variable -name Bk7ZipBin -value $BkArguments[++$i] -scope Script }
				"--jbin"            { Set-Variable -name BkJunctionBin -value $BkArguments[++$i] -scope Script }
				"--dry"             { Set-Variable -name BkDryRun -value $True -scope Script }
				"--pre"             { Set-Variable -name BkPreAction -value $BkArguments[++$i] -scope Script }
				"--post"            { Set-Variable -name BkPostAction -value $BkArguments[++$i] -scope Script }
				
				Default { Write-Output ("Unknown argument {0}" -f $BkArguments[$i]); return }
			}
			$i++
		}
		while ($i -lt $BkArguments.length)
	}
}

# -----------------------------------------------------------------------------
# Function 		: Validate-Variables
# -----------------------------------------------------------------------------
# Description	: This function is used to check variables needed to execute
#				  the script.
# Parameters    : None
# Returns       : An array of error messages (if any)
# -----------------------------------------------------------------------------
Function Validate-Variables {

	# --------------------------------------------------------------------------------------------------------------------------
	# Environment - Checks
	# --------------------------------------------------------------------------------------------------------------------------
	# Check we're on Powershell 3.x. If not early exit.
	If($MyContext.PSVer -lt 2) {
		Write-Output ("You must be on PowerShell 2.x (or better) to run this script. You're on {0}" -f $MyContext.PSVer)
		Return
	}

	# --------------------------------------------------------------------------------------------------------------------------
	# Clear Archive Bit Policy - Checks
	# --------------------------------------------------------------------------------------------------------------------------
	If((Test-Variable "BkClearBit") -eq $True) {
		Set-Variable -name b -value $True -scope Local
		If([system.boolean]::tryparse($BkClearBit,[ref]$b)) {
			Set-Variable -name BkClearBit -value $b -scope Script
		} Else {
			Write-Output "Value $BkClearBit for --clearbit argument is not valid boolean value."
			Remove-Variable -name BkClearBit -scope Script
		}
		Remove-Variable -name b -scope Local
	}
	
	# --------------------------------------------------------------------------------------------------------------------------
	# Backup Type - Checks
	# --------------------------------------------------------------------------------------------------------------------------
	If(!(Test-Variable "BkType")) {
		Write-Output  "Missing or invalid --type argument"
	} Else {
		Switch ($BkType) {
			"full" { $BkType = "full"; If(!(Test-Variable "BkClearBit")) { Set-Variable -name BkClearBit -value $True -scope Script } }
			"incr" { $BkType = "incr"; If(!(Test-Variable "BkClearBit")) { Set-Variable -name BkClearBit -value $True -scope Script } }
			"diff" { $BkType = "diff"; If(!(Test-Variable "BkClearBit")) { Set-Variable -name BkClearBit -value $False -scope Script } }
			"copy" { $BkType = "copy"; If(!(Test-Variable "BkClearBit")) { Set-Variable -name BkClearBit -value $False -scope Script } }
			"move" { $BkType = "move"; If(!(Test-Variable "BkClearBit")) { Set-Variable -name BkClearBit -value $False -scope Script } }
			Default { Write-Output  "Missing or invalid --type argument" }
		}	
	}

	# --------------------------------------------------------------------------------------------------------------------------
	# Work drive - Checks
	# --------------------------------------------------------------------------------------------------------------------------
	# If missing or set to "auto" we will assume drive letter for TEMP path.
	# If passed from command line arguments we have to check is a valid drive letter
	# and path is writable and, of course, is NTFS filesystem
	If(!(Test-Variable "BkWorkDrive")) { Set-Variable -name BkWorkDrive -value "auto" -scope Script }
	If($BkWorkDrive -ieq "auto") { Set-Variable -name BkWorkDrive -value ($Env:Temp).Substring(0,1) -scope Script }
	If (
		($BkWorkDrive -ieq "") -or
		($BkWorkDrive -is [array]) -or
		($BkWorkDrive -notmatch "^[C-Z]{1}$") -or
		(Test-Path ($BkWorkDrive + ":\") -eq $False) -or
		((Test-Path-Writable ($BkWorkDrive + ":\") "Directory") -eq $False) -or
		((New-Object System.Io.DriveInfo($BkWorkDrive)).DriveFormat -ieq "NTFS")
	)	{ Write-Output "Missing or invalid --workdrive argument. Must be writable NTFS drive" }
	
	# --------------------------------------------------------------------------------------------------------------------------
	# Selection file - Checks
	# --------------------------------------------------------------------------------------------------------------------------
	If (
		((Test-Variable "BkSelection") -eq $False) -or
		($BkSelection -match "^\s*$") -or
		((Test-Path $BkSelection -pathType Leaf) -eq $False) -or
		(Check-FsAttribute $BkSelection "Directory")
	)	{ Write-Output "Missing or invalid --selection argument. Must be an existent file" } 
	Else 
	{
		
		# Resolve full name to file
		Set-Variable -name BkSelection -value ((Get-Item $BkSelection).FullName) -Scope Script
		
		# Try to load Selection Directives (if any)
		# Load all rows except comments and empty lines.
		Remove-Variable -name BkSelectionContents -scope Script 
		Set-Variable -name BkSelectionContents -scope Script -Value @(Get-Content $BkSelection | ? {$_ -notmatch "^#|^\s*$"})
		
		# If we have no directive from selection then handle the error
		If(
			((Test-Variable "BkSelectionContents") -eq $False) -Or 
			($BkSelectionContents.Count -eq 0) -Or
			!(($BkSelectionContents | Where-Object {$_ -match "^includesource=*"}).Length -gt 0)
		) { Write-Output "Missing or invalid --selection argument: file does not contain any `"includesource`" directive" } 
		Else 
		{
				
			# Look whether selection contents holds specific 7zip switches to use. (REMOVED)
			#$BkSelectionContents | Where-Object {$_ -match "^useswitches=*"} | ForEach-Object { Set-Variable -name "Bk7ZipSwitches" -value ($_.Substring($_.IndexOf("=") + 1)) -scope Script }

			# Look whether selection contents holds specific maxdepth value to use.
			If(!(Test-Variable "BkMaxDepth")) {$BkSelectionContents | Where-Object {$_ -match "^maxdepth=[0-9]"} | ForEach-Object { Set-Variable -name "BkMaxDepth" -value ($_.Substring($_.IndexOf("=") + 1)) -scope Script }}
			
			# Look whether selection contents holds specific rotate value to use.
			If(!(Test-Variable "BkRotate")) {$BkSelectionContents | Where-Object {$_ -match "^rotate=[0-9]"} | ForEach-Object { Set-Variable -name "BkRotate" -value ($_.Substring($_.IndexOf("=") + 1)) -scope Script }}
			
			# Look whether selection contents holds specific prefix value to use.
			If(!(Test-Variable "BkArchivePrefix")) {$BkSelectionContents | Where-Object {$_ -match "^prefix=*"} | ForEach-Object { Set-Variable -name "BkArchivePrefix" -value ($_.Substring($_.IndexOf("=") + 1)) -scope Script }}

			# Look whether selection contents sets the keeping of empty dirs.
			If(!(Test-Variable "BkKeepEmptyDirs")) {$BkSelectionContents | Where-Object {$_ -match "^emptydirs$"} | ForEach-Object { Set-Variable -name "BkKeepEmptyDirs" -value $True -scope Script }}

			# Look whether selection contents sets following of junctions
			If(!(Test-Variable "BkNoFollowJunctions")) {$BkSelectionContents | Where-Object {$_ -match "^nofollowjunctions$"} | ForEach-Object { Set-Variable -name "BkNoFollowJunctions" -value $True -scope Script }}
			
			# Look whether selection contents sets max/min file sizes
			If (!(Test-Variable "BkMaxFileSize")) { $BkSelectionContents | ? {$_ -match "^maxfilesize=\d+"} | select @{Name="Value";Expression={$_.Substring($_.IndexOf("=") + 1).Replace(",",".")}} | ForEach-Object {Set-Variable -Name "BkMaxFileSize" -Value $_.Value} }
			If (!(Test-Variable "BkMinFileSize")) { $BkSelectionContents | ? {$_ -match "^minfilesize=\d+"} | select @{Name="Value";Expression={$_.Substring($_.IndexOf("=") + 1).Replace(",",".")}} | ForEach-Object {Set-Variable -Name "BkMinFileSize" -Value $_.Value} }

			# Look whether selection contents sets max/min file ages
			If (!(Test-Variable "BkMaxFileAge")) { 	$BkSelectionContents | ? {$_ -match "^maxfileage=\d+(\,|\.)\d+"} | select @{Name="Value";Expression={$_.Substring($_.IndexOf("=") + 1).Replace(",",".")}} | ForEach-Object {Set-Variable -Name "BkMaxFileAge" -Value $_.Value} }
			If (!(Test-Variable "BkMinFileAge")) { 	$BkSelectionContents | ? {$_ -match "^minfileage=\d+(\,|\.)\d+"} | select @{Name="Value";Expression={$_.Substring($_.IndexOf("=") + 1).Replace(",",".")}} | ForEach-Object {Set-Variable -Name "BkMinFileAge" -Value $_.Value} }
			
			# Look for compression
			If (!(Test-Variable "BkArchiveCompression"))  {	$BkArchiveCompression | ? {$_ -match "^compression=\d+"} | select @{Name="Value";Expression={$_.Substring($_.IndexOf("=") + 1).Replace(",",".")}} | ForEach-Object {Set-Variable -Name "BkArchiveCompression" -Value $_.Value} } 

			# Look for threads
			If (!(Test-Variable "BkArchiveThreads"))  {	$BkArchiveThreads | ? {$_ -match "^threads=\d+"} | select @{Name="Value";Expression={$_.Substring($_.IndexOf("=") + 1).Replace(",",".")}} | ForEach-Object {Set-Variable -Name "BkArchiveThreads" -Value $_.Value} } 
			
			# Look for Solid mode
			If (!(Test-Variable "BkArchiveSolid"))  {	$BkArchiveSolid | ? {$_ -match "^solid=\d+"} | select @{Name="Value";Expression={$_.Substring($_.IndexOf("=") + 1).Replace(",",".")}} | ForEach-Object {Set-Variable -Name "BkArchiveSolid" -Value $_.Value} } 
			
		}
	}

	# --------------------------------------------------------------------------------------------------------------------------
	# Directives - Checks
	# --------------------------------------------------------------------------------------------------------------------------
	
	If (Test-Variable "BkMaxFileSize") {
		Set-Variable -Name "i" -Value [int64]0 -Scope Local
		If(([system.int64]::tryparse($BkMaxFileSize, [System.Globalization.NumberStyles]::Number, [System.Globalization.CultureInfo]::CreateSpecificCulture("en-US") ,[ref]$d))) { 
			Set-Variable -Name "BkMaxFileSize" -Value ([Math]::Abs($d)) -Scope Script
		} Else {
			Write-Output "Missing or invalid maxfilesize directive. Must be an integer"
		}
		Remove-Variable -Name "i"
	}
	If (Test-Variable "BkMinFileSize") {
		Set-Variable -Name "i" -Value [int64]0 -Scope Local
		If(([system.int64]::tryparse($BkMinFileSize, [System.Globalization.NumberStyles]::Number, [System.Globalization.CultureInfo]::CreateSpecificCulture("en-US") ,[ref]$i))) { 
			Set-Variable -Name "BkMinFileSize" -Value ([Math]::Abs($i)) -Scope Script
		} Else {
			Write-Output "Missing or invalid minfilesize directive. Must be an integer"
		}
		Remove-Variable -Name "i"
	}
	If((Test-Variable "BkMaxFileSize") -And !($BkMaxFileSize -gt 0)) { Remove-Variable -Name "BkMaxFileSize" }
	If((Test-Variable "BkMinFileSize") -And !($BkMinFileSize -gt 0)) { Remove-Variable -Name "BkMinFileSize" }

	If (Test-Variable "BkMaxFileAge") {
		Set-Variable -Name "d" -Value [double]0 -Scope Local
		If(([system.Double]::tryparse($BkMaxFileAge, [System.Globalization.NumberStyles]::AllowDecimalPoint, [System.Globalization.CultureInfo]::CreateSpecificCulture("en-US") ,[ref]$d))) { 
			Set-Variable -Name "BkMaxFileAge" -Value ([Math]::Abs($d)) -Scope Script
		} Else {
			Write-Output "Missing or invalid minfilesize directive. Must be a valid number"
		}
		Remove-Variable -Name "d"
	}
	
	If (Test-Variable "BkMinFileAge") {
		Set-Variable -Name "d" -Value [double]0 -Scope Local
		If(([system.Double]::tryparse($BkMinFileAge, [System.Globalization.NumberStyles]::AllowDecimalPoint, [System.Globalization.CultureInfo]::CreateSpecificCulture("en-US") ,[ref]$d))) { 
			Set-Variable -Name "BkMinFileAge" -Value ([Math]::Abs($d)) -Scope Script
		} Else {
			Write-Output "Missing or invalid minfilesize directive. Must be a valid number"
		}
		Remove-Variable -Name "d"
	}
	
	If((Test-Variable "BkMaxFileAge") -And !($BkMaxFileAge -gt 0)) { Remove-Variable -Name "BkMaxFileAge" }
	If((Test-Variable "BkMinFileAge") -And !($BkMinFileAge -gt 0)) { Remove-Variable -Name "BkMinFileAge" }
	
	
	# --------------------------------------------------------------------------------------------------------------------------
	# Destination Path - Checks
	# --------------------------------------------------------------------------------------------------------------------------
	# Destination path given and existent
	If(
		!(Test-Variable "BkDestPath") -Or
		($BkDestPath -match "^\s*$") -Or
		!(Test-Path $BkDestPath -pathType Container) -Or
		!(Check-FsAttribute $BkDestPath "Directory") -Or
		!(Test-Path-Writable $BkDestPath "File")
	) { Write-Output "Missing or invalid --destpath argument. Must be a writable container" }
	
	# --------------------------------------------------------------------------------------------------------------------------
	# Archive Prefix - Checks
	# --------------------------------------------------------------------------------------------------------------------------
	# Check Archive Prefix does not contain unallowed chars
	If(
		!(Test-Variable "BkArchivePrefix") -Or
		($BkArchivePrefix -match "^\s*$") -Or
		!(Test-Path -Path $BkArchivePrefix -IsValid)
	) { Write-Output "Missing or invalid --prefix argument" }

	# --------------------------------------------------------------------------------------------------------------------------
	# Archive Type - Checks
	# --------------------------------------------------------------------------------------------------------------------------
	If(!(Test-Variable "BkArchiveType")) { 
		Set-Variable -name BkArchiveType -value "7z" -scope Script
	} Else { 
		Switch ($BkArchiveType) {
			"7z"    { Set-Variable -name BkArchiveType -value "7z"  -scope Script }
			"zip"   { Set-Variable -name BkArchiveType -value "zip" -scope Script }
			"tar"   { Set-Variable -name BkArchiveType -value "tar" -scope Script }
			Default { Write-Output "Missing or invalid --archivetype argument" }
		}
	}

	# --------------------------------------------------------------------------------------------------------------------------
	# Archive Compression - Checks
	# --------------------------------------------------------------------------------------------------------------------------
	If(Test-Variable "BkArchiveCompression") { 
		If ($BkArchiveCompression -notmatch "^0$|^1$|^3$|^5$|^7$|^9$") {
			Write-Output "Missing or invalid --compression argument"
		} Else {
			Set-Variable -Name BkArchiveCompression -Value ([int]$BkArchiveCompression) -Scope Script
		}
	}

	# --------------------------------------------------------------------------------------------------------------------------
	# Solid archive policy - Checks
	# --------------------------------------------------------------------------------------------------------------------------
	If((Test-Variable "BkArchiveSolid") -eq $True) {
		Set-Variable -name b -value $True -scope Local
		If([system.boolean]::tryparse($BkArchiveSolid,[ref]$b)) {
			Set-Variable -name BkArchiveSolid -value $b -scope Script
		} Else {
			Write-Output "Provided value for --solid argument is not valid boolean value."
			Remove-Variable -name BkArchiveSolid -scope Script
		}
		Remove-Variable -name b -scope Local
	} Else {
		Set-Variable -name "BkArchiveSolid" -value $True -scope Script
	}
	
	
	# --------------------------------------------------------------------------------------------------------------------------
	# Threading - Checks
	# --------------------------------------------------------------------------------------------------------------------------
	If(Test-Variable "BkArchiveThreads") { 
		If ($BkArchiveThreads -notmatch "^\d*$") {
			Write-Output "Missing or invalid --threads argument"
		} Else {
			Set-Variable -Name "BkArchiveThreads" -Value ([int]$BkArchiveThreads) -Scope Script
			Set-Variable -Name "tmpNumCores" -Value([int]0) -Scope Local
			# Check number of threads does not exceed number of available cores
			Get-WmiObject -class win32_processor | ForEach-Object {
				If(!$_.NumberOfCores) {
					$tmpNumCores++ 
				} Else {
					$tmpNumCores += $_.NumberOfCores
				}
			}
			If($BkArchiveThreads -gt $tmpNumCores) {
				Write-Output ("Missing or invalid --threads [{0}] argument. Must not exceed {1}" -f $BkArchiveThreads, $tmpNumCores)
			}
			Remove-Variable -Name "tmpNumCores"
		}
	}
	
	
	# --------------------------------------------------------------------------------------------------------------------------
	# Archive Rotation Policy - Checks
	# --------------------------------------------------------------------------------------------------------------------------
	If((Test-Variable "BkRotate")) {
		Set-Variable -name i -value ([int]0) -scope Local
		If(([system.int64]::tryparse($BkRotate,[ref]$i))) {
			Set-Variable -name BkRotate -value $i -scope Script
			If(!($BkRotate -gt 0)) {
				Write-Output "Missing or invalid --rotate argument. Must be positive integer"
				Remove-Variable -name BkRotate -scope Script
			}
		} Else {
			Write-Output "Missing or invalid --rotate argument. Must be positive integer"
			Remove-Variable -name BkRotate -scope Script
		}
		Remove-Variable -name i -scope Local
	}

	# --------------------------------------------------------------------------------------------------------------------------
	# Max Recursion Depth Policy - Checks
	# --------------------------------------------------------------------------------------------------------------------------
	# Max depth to honor while scanning
	If(Test-Variable "BkMaxDepth") {
		Set-Variable -name i -value ([int]0) -scope Local
		If(([system.int64]::tryparse($BkmaxDepth,[ref]$i))) {
			Set-Variable -name BkMaxDepth -value $i -scope Script
			If(($BkMaxDepth -lt 0)) {
				Write-Output "Missing or invalid --maxdepth argument. Must be positive integer"
				Remove-Variable -name BkMaxdepth -scope Script
			} 
		} Else {
			Write-Output "Missing or invalid --maxdepth argument. Must be positive integer"
			Remove-Variable -name BkMaxDepth -scope Script
		}
		Remove-Variable -name i -scope Local
	}

	# --------------------------------------------------------------------------------------------------------------------------
	# Backup Log File - Checks
	# --------------------------------------------------------------------------------------------------------------------------
	If(!(Test-Variable "BkLogFile")) { Set-Variable -name BkLogFile -value (Join-Path $Env:Temp ($MyContext.Name.Substring(0, ($MyContext.Name.LastIndexOf("."))) + (Get-Date -format "yyyyMMdd-HHmmss") + ".log")) -scope Script } 
	If(
		($BkLogFile -match "^\s*$") -Or
		(Check-FsAttribute $BkLogFile "Directory") -Or
		!(Test-Path -LiteralPath $BkLogFile -IsValid)
	) { Write-Output "Missing or invalid --logfile argument. Must be a valid file" }
	If(Test-Path -LiteralPath $BkLogFile -pathType Leaf) {
		Remove-Item -Path $BkLogFile -Force | Out-Null
		If(!($?)) {Write-Output "Could not overwrite previous log file"}
	} 
	If(!(Test-Path -LiteralPath $BkLogFile -pathType Leaf)) {
		New-Item -Path $BkLogFile -ItemType File | Out-Null
		If(!($?)) {Write-Output "Could not initialize log file"}
	}

	# --------------------------------------------------------------------------------------------------------------------------
	# Emeil Notification - Checks
	# --------------------------------------------------------------------------------------------------------------------------
	If(Test-Variable "BkNotifyLog") {

		# ----------------------------------------------------------------------------------------------------------------------
		# From Email Addresses - Checks
		# ----------------------------------------------------------------------------------------------------------------------
		If(!($BkNotifyLog -is [array])) { $BkNotifyLog = @($BkNotifyLog) }
		$BkNotifyLog | ForEach-Object { If(!(IsValidEmailAddress $_)) { Write-Output ("Missing or invalid --notify argument {0} " -f $_) } }


		# ----------------------------------------------------------------------------------------------------------------------
		# To Email Addresses - Checks
		# ----------------------------------------------------------------------------------------------------------------------
		If(!(Test-Variable "BkSmtpFrom"))  { 
			Write-Output "Missing or invalid --notifyfrom argument" 
		} Else {
			If($BkSmtpFrom -is [array]) { $BkSmtpFrom = ($BkSmtpFrom -join "") }
			If(!(IsValidEmailAddress $BkSmtpFrom)) { Write-Output ("Missing or invalid --notifyfrom argument. {0} is not a valid email address" -f $BkSmtpFrom) }
		}

		# ----------------------------------------------------------------------------------------------------------------------
		# Email info - Checks
		# ----------------------------------------------------------------------------------------------------------------------
		If(!(Test-Variable "BkNotifyExtra")) { Set-Variable -name BkNotifyExtra -value "none" -scope Script }
		Switch ($BkNotifyExtra) {
			"none"   { Set-Variable -name BkNotifyExtra -value "none"  -scope Script }
			"inline" { Set-Variable -name BkNotifyExtra -value "inline" -scope Script }
			"attach" { Set-Variable -name BkNotifyExtra -value "attach" -scope Script }
			Default  { Write-Output "Missing or invalid --notifyextra argument" }
		}

		# ----------------------------------------------------------------------------------------------------------------------
		# Relay server - Checks
		# ----------------------------------------------------------------------------------------------------------------------
		If($BkSmtpRelay -is [array]) { $BkSmtpRelay = ($BkSmtpRelay -join "") }
		If(
			!(Test-Variable "BkSmtpRelay") -Or
			(!(IsValidHostName $BkSmtpRelay) -And !(IsValidIPAddress $BkSmtpRelay))
		) { Write-Output "Missing or invalid --smtpserver argument" }

		# ----------------------------------------------------------------------------------------------------------------------
		# Relay server authentication - Checks
		# ----------------------------------------------------------------------------------------------------------------------
		If ( (Test-Variable "BkSmtpUser") -Or (Test-Variable "BkSmtpPass") ) {
			If (
				!(Test-Variable "BkSmtpUser") -Or
				!(Test-Variable "BkSmtpPass") -Or
				($BkSmtpUser -match "^\s*$") -Or
				($BkSmtpPass -match "^\s*$")
			) { Write-Output "Missing or invalid --smtpuser or --smtppass argument" }
		}

		# ----------------------------------------------------------------------------------------------------------------------
		# Relay server port - Checks
		# ----------------------------------------------------------------------------------------------------------------------
		If(!(Test-Variable "BkSmtpPort"))  { Set-Variable -name BkSmtpPort -value ([int]25) -scope Script } Else {
			Set-Variable -name i -value ([int]0) -scope Local
			If(([system.int64]::tryparse($BkSmtpPort,[ref]$i))) {
				Set-Variable -name BkSmtpPort -value $i -scope Script
				If(($BkSmtpPort -le 0) -or ($BkSmtpPort -gt 65535)) {
					Write-Output "Provided value for --smtpPort argument is not valid. Must be a number [1-65535]."
					Remove-Variable -name BkSmtpPort -scope Script
				}
			} Else {
				Write-Output "Provided value for --smtpPort argument is not valid. Must be a number [1-65535]."
				Remove-Variable -name BkSmtpPort -scope Script
			}
			Remove-Variable -name i -scope Local
		}
	
	}

	# --------------------------------------------------------------------------------------------------------------------------
	# 7z.exe binary - Checks
	# --------------------------------------------------------------------------------------------------------------------------
	If(!(Test-Variable "Bk7ZipBin")) { 
		If(Test-Path -Path (Join-Path -Path ${Env:ProgramFiles} -ChildPath "\7-Zip\7z.exe") -PathType Leaf) { Set-Variable -Name Bk7ZipBin -value (Join-Path -Path ${Env:ProgramFiles} -ChildPath "\7-Zip\7z.exe") -scope Script}
		If(Test-Path -Path (Join-Path -Path ${Env:ProgramFiles(x86)} -ChildPath "\7-Zip\7z.exe") -PathType Leaf) { Set-Variable -Name Bk7ZipBin -value (Join-Path -Path ${Env:ProgramFiles(x86)} -ChildPath "\7-Zip\7z.exe") -scope Script}
	}
	If(
		!(Test-Variable "Bk7ZipBin") -Or
		($Bk7ZipBin -match "^\s*$") -Or
		!(Test-Path -Path $Bk7ZipBin -pathType Leaf)
	) { Write-Output "Missing or invalid --7zipbin argument" }
	Else 
	{
		$MyContext.SevenZBinVersionInfo = @{}
		Get-Item -Path $Bk7ZipBin | ForEach-Object {
			$MyContext.SevenZBinVersionInfo.ProductVersion = $_.VersionInfo.ProductVersion.ToString()
			$MyContext.SevenZBinVersionInfo.Major = $_.VersionInfo.ProductVersion.ToString().Split(".")[0]
			$MyContext.SevenZBinVersionInfo.Minor = $_.VersionInfo.ProductVersion.ToString().Split(".")[1]
		}
	}

	# --------------------------------------------------------------------------------------------------------------------------
	# Junction.exe binary - Checks
	# --------------------------------------------------------------------------------------------------------------------------
	# On Vista / 7 / 2008 native MKLINK is used instead
	If([int]$MyContext.WinVer[0] -lt 6) {

		If(!(Test-Variable "BkJunctionBin")) { 
			${Env:ProgramFiles}, ${Env:ProgramFiles(x86)} | ForEach-Object {
				If(Test-Path -Path $_ -ChildPath "\SysInternalsSuite\junction.exe" -PathType Leaf) {
				Set-Variable -Name BkJunctionBin -value  (Join-Path -Path $_ -ChildPath "\SysInternalsSuite\junction.exe") -scope Script
				}
			}
		}
	
		If(
			!(Test-Variable "BkJunctionBin") -Or
			($BkJunctionBin -match "^\s*$") -Or
			!(Test-Path -Path $BkJunctionBin -pathType Leaf)
		) { Write-Output "Missing or invalid --jbin argument" }
	}
	
}

# ====================================================================
# End Functions Library
# ====================================================================
# Start Script Flow Here
# ====================================================================

# This will prevent unhandled exit from the script
[console]::TreatControlCAsInput = $False

# Clean all script scoped variables beginning with "Bk"
Get-ChildItem variable:script:Bk* | Remove-Variable | Out-Null

# Output Header Text
Write-Host $headerText

# Check For the presence of "--help" argument switch
If($args.length -ne 0) { 
	switch -wildcard ($args) { "*--help*" {Write-Host $helpText ; [console]::TreatControlCAsInput = $False; Return} }
} 

# Import hard coded variables if present -vars.ps1 script
Set-Variable -name BkVarsImportScript -value (Join-Path $MyContext.Directory $MyContext.Name.Replace(".ps1", "-vars.ps1")) -scope Script
If((Test-Path $BkVarsImportScript -pathType Leaf )) {
	Try { & $BkVarsImportScript }
	Catch { }
}

Set-Variable -Name hasErrors -Value $False -Scope Script
Set-Variable -Name BkArguments -Value $args -Scope Script
Set-Variable -Name Actions -Value @("Validate-Arguments", "Validate-Variables") -Scope Script

Validate-Arguments | ForEach-Object { $hasErrors = $True; Write-Host " Err : $_" }
Validate-Variables | ForEach-Object { $hasErrors = $True; Write-Host " Err : $_" }
If($hasErrors) { Write-Host ("`n Try .\{0} --help `n" -f $MyInvocation.MyCommand.Name); Return }

# --------------------------------------------------------------------
# Initialize script scoped hashes 
# --------------------------------------------------------------------
Set-Variable -Name Counters -Value @{} -Scope Script
Set-Variable -Name SWriters -Value @{} -Scope Script

$Counters.Exclusions = 0
$Counters.Warnings = 0
$Counters.Exceptions = 0
$Counters.Criticals = 0
$Counters.FoldersDone = 0
$Counters.FilesProcessed = 0
$Counters.FilesSelected = 0
$Counters.BytesSelected = 0
$Counters.PlaceHolders = @()

# --------------------------------------------------------------------
# Do compose names
# --------------------------------------------------------------------
Set-Variable -Name BkArchiveName -Value ($BkArchivePrefix + "-" + $BkType + "-" + (Get-Date -format "yyyyMMdd-HHmmss") + "." + $BkArchiveType) -Scope Script
Set-Variable -Name BkRootDir     -Value ($BkWorkDrive + ":\~" + ([System.Guid]::NewGuid().ToString().Split("-")[1])) -Scope Script
Set-Variable -Name BkLockFile    -Value (Join-Path $Env:Temp ($MyContext.Name.Substring(0, ($MyContext.Name.LastIndexOf("."))) + ".lock")) -scope Script
Set-Variable -Name BkSources     -Value @{} -Scope Script

# Initialize log file
$SWriters.Log = New-Object -TypeName System.IO.StreamWriter($BkLogFile, [String]$True, [System.Text.Encoding]::ASCII)
$SWriters.Log.WriteLine($headerText)


Test-Lock | ForEach-Object { $hasErrors = $True; Write-Host " Err : $_" }
New-RootDir | ForEach-Object { $hasErrors = $True; Write-Host " Err : $_" }
Check-CTRLCRequest | Out-Null

If($hasErrors) { 
	If(!($MyContext.Cancelling)) {
		Do-PostAction
		Send-Notification 
	}
	Clear-Script
	Return 
}

# --------------------------------------------------------------------------------
# Execute pre Action if we have any (It may create directories we have to archive
# --------------------------------------------------------------------------------
If(Test-Variable "BkPreAction") {

	Trace " Invoking Pre-Action (Output follows if any)"
	Trace " ------------------------------------------------------------------------------"
	Try {
		& $BkPreAction 2>&1 | Set-Variable -Name preActionOutput -Scope Script
		$preActionOutput | ForEach-Object {
			Trace " $_"
		}
	} Catch {
		Trace " $_.Exception.Message"
	}
	Trace " ------------------------------------------------------------------------------"
	Trace " "
	
}


# Initalize Operations
# Output all running context informations
Trace " Started on ........ :  $(Get-Date)"
Trace " Backup Type ....... :  $BkType"
If($BkClearBit -eq $True)    { Trace " Files' Archive attr :  Will be cleared" } Else { Trace " Files' Archive attr :  Will stay unchanged" }
Trace " Selection File .... :  $BkSelection"
If(Test-Variable "BkMaxDepth") { Trace " Recursion Depth ... :  $BkMaxDepth" }
If($BkNoFollowJunctions) {Trace " Reparse points .... :  Will NOT be followed" }
Trace " Destination ....... :  $BkDestPath"
Trace " Archive Name ...... :  $BkArchiveName"
Trace " Archive Type ...... :  $BkArchiveType"
If((Test-Variable "BkRotate")) { Trace " Rotation policy ... :  Keep last $BkRotate archive(s) " } Else { Trace " Rotation policy ... :  Keep all archive(s) " }
Trace (" 7zip binary ....... :  {0} (ver. {1}) " -f $Bk7zipBin,$MyContext.SevenZBinVersionInfo.ProductVersion)
Trace (" 7zip threading .... :  {0} " -f ( & { If(Test-Variable "BkArchiveThreads") { Write-Output "$BkArchiveThreads threads" } Else { Write-Output "Auto"}   }))
If(Test-Variable "BkArchiveCompression") { Trace " 7zip Compression .. :  $BkArchiveCompression" } Else { Trace " 7zip Compression .. :  Auto" }
Trace " "
Trace " ------------------------------------------------------------------------------"

Trace " Backup From Sources   "
Trace " ------------------------------------------------------------------------------"
# --------------------------------------------------------------------
# Read the contents of selection file and create a junction for each one 
# --------------------------------------------------------------------

$BkSelectionContents | Where-Object {$_ -imatch "^includesource=(.*)\|alias=(.*)"} | ForEach-Object {
	
	$directiveLine=[string]$_
	$directiveParts = $directiveLine.split("|", [System.StringSplitOptions]::RemoveEmptyEntries)
	$target = $directiveParts[0].Split("=")[1]
	$alias  = $directiveParts[1].Split("=")[1]
	
	# Trace the selection
	Trace " + $alias <== $Target"
	
	# Check target exist
	If(!(Test-Path $target -pathType Container)) { 
		Trace "   Selection directory $target does not exist. Skipping "
	} Else {
		
		# Check alias is not already in use
		If((Test-Path (Join-Path $BkRootDir $alias))) {
			Trace "   Alias $alias already in use. Skipping selection of $target"
		} Else {
			
			If([int]$MyContext.WinVer[0] -lt 6 ) { 
				# Create the new junction for Windows previous to vista
				If(!(Make-Junction (Join-Path -Path $BkRootDir -ChildPath $alias) $target)) { Trace "   Failed to create Junction [$alias] to [$target]"} Else { $BkSources.Add($alias, $target) }
			} Else {
				# Create the new symbolic link for Windows Vista or newer
				If(!(Make-SymLink (Join-Path -Path $BkRootDir -ChildPath $alias) $target)) { Trace "   Failed to create Symbolic Link [$alias] to [$target]"} Else { $BkSources.Add($alias, $target) }
			}
			
		}
		
	}
}

# --------------------------------------------------------------------
# Check we have at least one directory alias to backup 
# --------------------------------------------------------------------
If(( $BkSources.Count -eq 0 )) {
	Trace "   There are no selectable sources to backup. Quitting"
	If(!($MyContext.Cancelling)) { 
		Do-PostAction
		Send-Notification 
	}
	Clear-Script
	Return
}  Else {
	Trace " "
}

# --------------------------------------------------------------------
# Check we have an cleanup criteria on file names
# --------------------------------------------------------------------
Trace " Cleanup Files Criteria (will be deleted during scan)"
Trace " ------------------------------------------------------------------------------"
$BkSelectionContents | Where-Object {$_ -match "^matchcleanupfiles="} | ForEach-Object {
	$line = $_.Substring($_.IndexOf("=") + 1)
	If(($line)) {
		Trace " + match $line"
		If(!($matchcleanupfiles)) { $matchcleanupfiles = $line } Else { $matchcleanupfiles += ("|" + $line) }
	}
}


# --------------------------------------------------------------------
# Check we have an exclude criteria on file names
# --------------------------------------------------------------------
Trace " "
Trace " Include Files Criteria "
Trace " ------------------------------------------------------------------------------"
$BkSelectionContents | Where-Object {$_ -match "^matchincludefiles="} | ForEach-Object {
	$line = $_.Substring($_.IndexOf("=") + 1)
	If(($line)) {
		Trace " + match $line"
		If(!($matchincludefiles)) { $matchincludefiles = $line } Else { $matchincludefiles += ("|" + $line) }
	}
}
If(!($matchincludefiles)) { Trace " + All file names " }

# --------------------------------------------------------------------
# Check we have max/min fileage to honor
# --------------------------------------------------------------------
If (Test-Variable "BkMaxFileAge") { Trace " + Max File Age : $BkMaxFileAge days" }
If (Test-Variable "BkMinFileAge") { Trace " + Min File Age : $BkMinFileAge days" }

# --------------------------------------------------------------------
# Check we have max/min filesize to honor
# --------------------------------------------------------------------
If (Test-Variable "BkMaxFileSize") { Trace " + Max File Size : $BkMaxFileSize days" }
If (Test-Variable "BkMinFileSize") { Trace " + Min File Size : $BkMinFileSize days" }

# --------------------------------------------------------------------
# Check we have an exclude criteria on file names
# --------------------------------------------------------------------
Trace " "
Trace " Exclude Files Criteria "
Trace " ------------------------------------------------------------------------------"
$BkSelectionContents | Where-Object {$_ -match "^matchexcludefiles=*"} | ForEach-Object {
	$line = $_.Substring($_.IndexOf("=") + 1)
	If(($line)) {
		Trace " - match $line"
		If(!($matchexcludefiles)) { $matchexcludefiles = $line } Else { $matchexcludefiles += ("|" + $line) }
	}
}
If(!($matchexcludefiles)) { Trace " None " }

# --------------------------------------------------------------------
# Check we have an exclude criteria on paths
# --------------------------------------------------------------------
Trace " "
Trace " Exclude Paths Criteria "
Trace " ------------------------------------------------------------------------------"
$BkSelectionContents | Where-Object {$_ -match "^matchexcludepath=*"} | ForEach-Object {
	$line = $_.Substring($_.IndexOf("=") + 1)
	If(($line)) {
		Trace " -match $line"
		If(!($matchexcludepath)) { $matchexcludepath = $line } Else { $matchexcludepath += ("|" + $line) }
	}
}
If(!($matchexcludepath))  { Trace " None "}

# --------------------------------------------------------------------
# Check we have any rule to stop digging into directories
# --------------------------------------------------------------------
Trace " "
Trace " Stop Recursion Criteria "
Trace " ------------------------------------------------------------------------------"
$BkSelectionContents | Where-Object {$_ -match "^matchstoprecurse=*"} | ForEach-Object {
	$line = $_.Substring($_.IndexOf("=") + 1)
	If(($line)) {
		Trace " -match $line"
		If(!($matchstoprecurse)) { $matchstoprecurse = $line } Else { $matchstoprecurse += ("|" + $line) }
	}
}
If(!($matchstoprecurse))  { Trace " None " }

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
$BkSelectionExcpt = Join-Path $BkRootDir "Selection-Excpt.csv"; New-Item $BkSelectionExcpt -type File -Force | Out-Null; "Id`tException`tTarget" | Out-File $BkCatalogExclude -encoding ASCII -append
$BkCatalogInclude = Join-Path $BkRootDir "Catalog-Include.txt"; New-Item $BkCatalogInclude -type File -Force | Out-Null
$BkCatalogExclude = Join-Path $BkRootDir "Catalog-Exclude.csv"; New-Item $BkCatalogExclude -type File -Force | Out-Null; "Id`tDirective`tType`tTarget" | Out-File $BkCatalogExclude -encoding ASCII -append
$BkCatalogStats   = Join-Path $BkRootDir "Catalog-Stats.csv"  ; New-Item $BkCatalogStats   -type File -Force | Out-Null; "Id`tExtension`tSize" | Out-File $BkCatalogStats -encoding ASCII -append
$BkCompressDetail = Join-Path $BkRootDir "Compress-Detail.txt"; New-Item $BkCompressDetail -type File -Force | Out-Null

# --------------------------------------------------------------------
# Open StreamWriters for optimize performance. 
# Out-File and Add-Content are rubbish and cause the selection to be
# up to 20x slower
# --------------------------------------------------------------------
$SWriters.Inclusions = New-Object -TypeName System.IO.StreamWriter($BkCatalogInclude, [String]$True, [System.Text.Encoding]::UTF8)
$SWriters.Exclusions = New-Object -TypeName System.IO.StreamWriter($BkCatalogExclude, [String]$True, [System.Text.Encoding]::ASCII)
$SWriters.Exceptions = New-Object -TypeName System.IO.StreamWriter($BkCatalogExceptions, [String]$True, [System.Text.Encoding]::ASCII)
$SWriters.Stats = New-Object -TypeName System.IO.StreamWriter($BkCatalogStats, [String]$True, [System.Text.Encoding]::ASCII)
$SWriters.GetEnumerator() | ForEach-Object { $_.Value.AutoFlush = $True }

Trace " "
Trace " Scanning ..."
Trace " ------------------------------------------------------------------------------"

# Begin the processing of the root folder to build up the catalogs and start counting elapsed time
$MyContext.SelectionStart = Get-Date

# Look-up for the folders (which are junctions) in the Root Folder
Set-Variable -Name catalogFolders -value (New-Object System.Collections.ArrayList) -scope Script
Set-Variable -Name catalogFoldersIndex -value ([int]0) -scope Script
$BkSources.GetEnumerator() | ForEach-Object {
	
	$itemFolder = @{}
    $itemFolder.Name = $_.Name
	$itemFolder.FullName = Join-Path -Path $BkRootDir -ChildPath $_.Value
    $itemFolder.RelativeName = $_.Name
	$itemFolder.ContainerAlias = $_.Name
	$itemFolder.RealName = Join-Path -Path $BkSources[$itemFolder.ContainerAlias] -ChildPath ($itemFolder.RelativeName.Replace($itemFolder.ContainerAlias, ""))
    $itemFolder.Depth = 0;
	[void] $catalogFolders.Add($itemFolder)
	
}

# Walk through catalogFolders to process each one
While ($True) {
	If(Check-CTRLCRequest) {break}
	ProcessFolder $catalogFolders[$catalogFoldersIndex] | Out-Null
	If (!(++$catalogFoldersIndex -le $catalogFolders.Count)) {Write-Progress -Activity "." -Status "." -Completed; break}
}
If($MyContext.Cancelling) {
	If(!($MyContext.Cancelling)) { Do-PostAction; Send-Notification }
	Clear-Script
	Return 
}

# Add Support Files to archive selection 
If($Counters.FilesSelected -gt 0) {
	Get-ChildItem -Path $BkRootDir -Force | ? {!$_.PSIsContainer} | ForEach-Object {
		if(	
			($_.Name -notmatch "stats") -And
			($_.Name -notmatch "README")
		) {
			$Counters.FilesSelected++ ; 
			$Counters.BytesSelected += $_.Length ;
			$SWriters.Inclusions.WriteLine($_.Name)
			$SWriters.Stats.WriteLine([string]("{0}`t{1}`t{2}" -f $Counters.FilesSelected,$_.Extension,[string]$_.Length ))
		}
	}
}

# --------------------------------------------------------------------
# Close StreamWriters letting enough time to flush buffers
# --------------------------------------------------------------------
$SWriters.GetEnumerator() | ForEach-Object { 
	$_.Value.Flush()
	If($_.Name -notmatch "^Log$") {$_.Value.Close()} 
} -End { Start-Sleep -Milliseconds 500 }


# Calc of elapsed time for selection process
$MyContext.SelectionEnd = Get-Date
$MyContext.SelectionElapsed = New-TimeSpan $MyContext.SelectionStart $MyContext.SelectionEnd

# Trace informations about what is selected
Trace " "
Trace (" Completed in {0,0:n0} days {1,0:n0} hours {2,0:n0} minutes {3,0:n3} seconds" -f $MyContext.SelectionElapsed.Days, $MyContext.SelectionElapsed.Hours, $MyContext.SelectionElapsed.Minutes, ($MyContext.SelectionElapsed.Seconds + ($MyContext.SelectionElapsed.MilliSeconds/1000)) )
Trace (" Selected {0,0:n0} out of {1,0:n0} files in {2,0:n0} folders. {3,0:n2} MBytes to backup" -f  $Counters.FilesSelected, $Counters.FilesProcessed, $Counters.FoldersDone, ($Counters.BytesSelected/1mb))


# Early exit from the process if user cancel or there is nothingto backup
If(($Counters.FilesSelected -lt 1) -or (Check-CTRLCRequest)) {

	# Trace we have not selected anything to backup
	Trace " "
	Trace " There are no files matching the selection criteria. Possible reasons: "
	Trace " - All source directories are empty and choose not to keep them"
	Trace " - No file match selection criteria"
	Trace " - User Cancel Request (CTRL+C)"
	Trace " "

	If(!($MyContext.Cancelling)) { 
		Do-PostAction
		Send-Notification 
	}
	Clear-Script
	Return 
	
}

	# Adjust at least 1byte selected (in case all files are zero length)
	# This will prevent division by zero errors
	If(($Counters.BytesSelected -lt 1)) { $Counters.BytesSelected = 1 }

	
	# Maybe there has been some exceptions during the selection progress. 
	# If this is the case output them here.
	If((Get-Item $BkSelectionExcpt).Length -gt 0) {
		Trace " "
		Trace " Exceptions during selection process"
		Trace " ------------------------------------------------------------------------------"
		Get-Content $BkSelectionExcpt | ForEach-Object {
		Trace (" {0} " -f $_); $Counters.Warnings++
		}
	}
	
	If(!(Check-CTRLCRequest -eq $True)) {
		# Do some stats (many thanks to http://www.hanselman.com/blog/ParsingCSVsAndPoorMansWebLogAnalysisWithPowerShell.aspx)
		Write-Progress -Activity "Calculating Stats on Selection" -Status "Running ..." -CurrentOperation "Please Wait ..."
		$statsByExtension = Import-Csv $BkCatalogStats -Delimiter "`t" | Select-Object Extension, Size | group Extension | select Name, @{Name="Count";Expression={($_.Count)}}, @{Name="Size";Expression={($_.Group | Measure-Object -Sum Size).Sum }} | Sort Size -desc
		Write-Progress -Activity "." -Status "." -Completed
		
		# Output summarized data
		Trace " "
		Trace " Selection Details" $BkCatalogStats
		Trace " ------------------------------------------------------------------------------"
		Trace " Extension                              Count          Total MB  Abs %   Inc % "
		Trace " -------------------------------  ----------- ----------------- ------- -------"
		$totalCount = 0; [int64]$totalBytes = 0
		$statsByExtension | ForEach-Object {
		$totalCount += $_.Count ; $totalBytes += $_.Size
		Trace (" {0,-31} {1,11:n0} {2,17:n2}  {3,6:n2}  {4,6:n2}" -f $_.Name, $_.Count, ($_.Size/1MB), ($_.Size/ $Counters.BytesSelected * 100), ($totalBytes / $Counters.BytesSelected * 100))
		}
		Trace "                                  ----------- ----------------- "
		Trace (" {0,-31} {1,11:n0} {2,17:n2}" -f "Total", $totalCount, ($totalBytes/1MB))
		Trace "                                  =========== ================= "
		Trace (" {0,-31} {1,11:n0}  {2}" -f "Performance average", ($Counters.FilesProcessed / $MyContext.SelectionElapsed.TotalMinutes ), "files per minute")
		Trace "                                  =========== ================= "
		Trace " "
	}
	
	
	
	If($BkDryRun -ne $True) {
	
		$BkDestFile = (Join-Path -Path $BkDestPath -ChildPath $BkArchiveName)
		Write-Progress -Activity "Archiving into $BkDestFile" -Status "Please wait ..." -CurrentOperation "Initializing ..."	

		# Compose arguments which will be passed to command line
		$Bk7ZipArgs = @()
		$Bk7ZipArgs += "a"																	# This is the "add" switch (means add and update)
		$Bk7ZipArgs += "-ssw"																# Archive files open for writing
		$Bk7ZipArgs += "-slp"																# Use large memory pages
		
		If((Test-Variable "BkArchiveCompression") -And ($BkArchiveType -ne "tar")) { 		# Set compression level
			$Bk7ZipArgs += ("-mx{0}" -f $BkArchiveCompression)
		}
		# Important !!!
		$Bk7ZipArgs += "-scsUTF-8"															# Set charset for list files to UTF8
		$Bk7ZipArgs += "-sccUTF-8"															# Set charset for console input/output to UTF8
		
		# If 7zip is beyond version 9.2 then add some more switches
		If ([int]$MyContext.SevenZBinVersionInfo.Major -ge 15) {
			$Bk7ZipArgs += "-bd"															# Disable Progress indicator
			$Bk7ZipArgs += "-bb1"
			$Bk7ZipArgs += "-bsp0"
			$Bk7ZipArgs += "-bso1"
			$Bk7ZipArgs += "-bse2"
			If($BkArchiveType -eq "7z") {
				$Bk7ZipArgs += "-mtm=on"													# Stores last Modified timestamps for files.
				$Bk7ZipArgs += "-mtc=on"													# Stores Creation timestamps for files.
				$Bk7ZipArgs += "-mta=on"													# Stores last Access timestamps for files.
			}
		} Else {
			$Bk7ZipArgs += "-bd"															# Disable Progress indicator
		}
		
		# Control Threading
		If(Test-Variable "BkArchiveThreads") {
			If($BkArchiveThreads -lt 1) {
				$Bk7ZipArgs += "-mmt=off"													# Disable multi threading
			} Else {
				$Bk7ZipArgs += ("-mmt={0}" -f $BkArchiveThreads)							# Use exact number of threads
			}
		}
		
		# Control solid archives															
		If(($BkArchiveType -eq "7z") -And !($BkArchiveSolid)) {
			$Bk7ZipArgs += "-ms=off"													    # Disable solid archive
		}
		
		$Bk7ZipArgs += "-t" + $BkArchiveType												# This is the type of the archive
		If(Test-Variable "BkArchivePassword") { 
			$Bk7ZipArgs += "-p$BkArchivePassword" 											# This is the password (if any)
			If($BkEncryptHeaders) { $Bk7ZipArgs += "-mhe" }
			}
		}		
		
		
		$Bk7ZipArgs += "`"$BkDestFile`""													# This is the destination file
		$Bk7ZipArgs += "`@`"$BkCatalogInclude`""											# This is the catalog input file
		
		# Create Process
		If(Test-Variable "Bk7ZipRetc") { Remove-Variable -Name Bk7ZipRetc }
		$oProcessStartInfo = New-Object -TypeName System.Diagnostics.ProcessStartInfo
		$oProcessStartInfo.FileName = $Bk7ZipBin
		$oProcessStartInfo.WorkingDirectory = $BkRootDir
		$oProcessStartInfo.RedirectStandardError = $true
		$oProcessStartInfo.RedirectStandardOutput = $true
		$oProcessStartInfo.UseShellExecute = $false
		$oProcessStartInfo.CreateNoWindow = $true
		$oProcessStartInfo.Arguments = ($Bk7ZipArgs -join " ")
		$oProcess = New-Object -Typename System.Diagnostics.Process
		$oProcess.StartInfo = $oProcessStartInfo
		
		# Initialize StreamWriter for Compress Details
		$SWriters.CompressDetail = New-Object -TypeName System.IO.StreamWriter($BkCompressDetail, [String]$True, [System.Text.Encoding]::UTF8)
		$SWriters.CompressDetail.AutoFlush = $True
		
		# Initialize StringBuilder for StdErr
		$oStdErrBuilder = New-Object -TypeName System.Text.StringBuilder
		
		# Adding event handers for stdout and stderr.
		$stdOutScripBlock = { if (! [String]::IsNullOrEmpty($EventArgs.Data)) { $Event.MessageData.WriteLine($EventArgs.Data) } }
		$stdErrScripBlock = { if (! [String]::IsNullOrEmpty($EventArgs.Data)) { $Event.MessageData.AppendLine($EventArgs.Data) } }
		
		# Register Event Handlers
		$oStdOutEvent = Register-ObjectEvent -InputObject $oProcess -Action $stdOutScripBlock -EventName 'OutputDataReceived' -MessageData $SWriters.CompressDetail
		$oStdErrEvent = Register-ObjectEvent -InputObject $oProcess -Action $stdErrScripBlock -EventName 'ErrorDataReceived'  -MessageData $oStdErrBuilder
		
		# Start the clocks
		$MyContext.CompressionStart = Get-Date
		
		
		# Start Process
		[void]$oProcess.Start()
		$oProcess.BeginOutputReadLine()
		$oProcess.BeginErrorReadLine()		
		
		# Begin polling Process
		While (!($oProcess.HasExited)) {
			Start-Sleep -Milliseconds 2000
			$Status = "Waiting for archive ..."
			Get-Item -LiteralPath $BkDestFile | ForEach-Object {
				$Status = "Archive Size {0,0:n2} MByte. so far ..." -f ($_.Length / 1Mb)
			}
			Write-Progress -Activity "Archiving into $BkDestFile" -Status $Status -CurrentOperation "Please wait ..."
			If(Check-CTRLCRequest -eq $True) {
				[void]$oProcess.Kill()
				While (!($oProcess.HasExited)) { Start-Sleep -Milliseconds 100 }
				Set-Variable -Name Bk7ZipRetc -value ([int]255) -scope Script				# Force return code to 255
				Start-Sleep -Milliseconds 500
				# Delete the destination file
				If(Test-Path -Path $BkDestFile -PathType Leaf) { Remove-Item -LiteralPath $BkDestFile -Force | Out-Null }
				break
			}
		}
		
		# Retrieve ExitCode if not already defined 
		If(!(Test-Variable "Bk7ZipRetc")) { Set-Variable -Name "Bk7ZipRetc" -value $oProcess.ExitCode -scope Script }
		
		# Stop the clock
		$MyContext.CompressionEnd = Get-Date
		$MyContext.CompressionElapsed = New-TimeSpan $MyContext.CompressionStart $MyContext.CompressionEnd
		
		# Remove event handlers
		Unregister-Event -SourceIdentifier $oStdOutEvent.Name
		Unregister-Event -SourceIdentifier $oStdErrEvent.Name		
		
		# Close StreamWriter for Compress Details
		$SWriters.CompressDetail.Flush()
		$SWriters.CompressDetail.Close()
		$SWriters.CompressDetail.Dispose()
		
		# Version 9.x  and 15.x of 7zip have different outputs
		# Look inside $BkCompressDetail in search of any file which may have been skipped
		# e.g. 7-Zip could not find one or more selected files 
		If ([int]$MyContext.SevenZBinVersionInfo.Major -le 9) {
			$relevantMessages = Get-Content $BkCompressDetail -encoding UTF8 | Where-Object {$_ -match "\ WARNING:\ |\ :\ "}
		} else {
			$relevantMessages = Get-Content $BkCompressDetail -encoding UTF8 | Where-Object {$_ -match "[A-Z]{1}\:\\.* \:\ .{1,}$"}
		}
		
		#If any relevant message then output
		If(!($Bk7ZipRetc -eq 255) -and $relevantMessages) {
			Trace " 7-Zip completed with warnings "
			Trace " ------------------------------------------------------------------------------"
			$relevantMessages | ForEach-Object {
				Trace " $_"; $Counters.Warnings++
			}
			Trace " "
		}
		
		
		# Check exit code by 7zip - If ErrorLevel is <2 then we assume backup
		# process completed successfully
		If(($Bk7ZipRetc -lt 2) -and (Test-Path -Path $BkDestFile -PathType Leaf) -and !(Check-CTRLCRequest)) {
			
			# Output informations in log file 
			Get-Item -Path $BkDestFile | ForEach-Object {
				
				Trace " Created $BkArchiveName in $BkDestPath "
				Trace (" Archive Size {0,0:n2} MB = {1,2:n2}% of original size" -f ($_.Length / 1MB), ((($_.Length / $Counters.BytesSelected)) * 100))
				Trace (" Completed in {0,0:n0} days, {1,0:n0} hours, {2,0:n0} minutes, {3,0:n3} seconds" -f $MyContext.CompressionElapsed.Days, $MyContext.CompressionElapsed.Hours, $MyContext.CompressionElapsed.Minutes, ($MyContext.CompressionElapsed.Seconds + $MyContext.CompressionElapsed.Milliseconds / 1000) )
				Trace (" Perfomance {0,0:n2} MB/Sec." -f (($Counters.BytesSelected / $MyContext.CompressionElapsed.TotalSeconds) / 1MB))
				Trace " "
				
			}
			
			# Do Post Archiving
			If(!(Check-CTRLCRequest)) { PostArchiving ; }
			
			# Do rotation over backup files
			# We have to list all files in the destination directory matching the same prefix and the same type
			# list all items descending (by their creation date) and then delete the oldest out of
			# the rotation range. If no rotation is defined then assume rotation period is 999 so we
			# can easily have an output of archives on target media.
			If(!(Check-CTRLCRequest)) {
				If(!(Test-Variable "BkRotate")) { Set-Variable -name "BkRotate" -value ([int]9999) -scope Script }
				If(($BkRotate -ge 1)) {
					$fileNameRgx = "$BkArchivePrefix-$BkType-[0-9]{8}-[0-9]{4,6}\.(7z|zip|tar)"
					Trace " Archives in $BkDestPath"
					Trace " ------------------------------------------------------------------------------"
					Get-ChildItem $BkDestPath | ?{ $_.Name -match $fileNameRgx -and !$_.PSIscontainer } | sort @{expression={$_.LastWriteTime};Descending=$true} | foreach-object {
						If(!($BkRotate -le 0)) { 
							If ($_.Name -eq $BkArchiveName) {
								Trace (" New      : {0,-48} {1,15:n2} MB " -f $_.Name, $($_.Length / 1MB) )
							} Else {
								Trace (" Kept     : {0,-48} {1,15:n2} MB " -f $_.Name, $($_.Length / 1MB) )
							}
							$BkRotate += -1
						} Else {
							remove-item -LiteralPath (Join-Path $BkDestPath $_.Name) -ErrorAction "SilentlyContinue" | Out-Null
							if ($?) { Trace (" Removed  : {0,-48} {1,15:n2} MB " -f $_.Name, $($_.Length / 1MB) ) } Else { Trace " WARNING Failed to remove $_.Name"}
						}
					}
					Trace " "
				}
			}
		
			Trace " "
			If(($Counters.Warnings -gt 0)) {
				Trace (" Done with : " + $Counters.Warnings + " warnings. Check logs!")
			} Else {
				Trace " All Done !! Yuppieee"
			}
			$MyContext.TotalElapsed = New-TimeSpan $MyContext.SelectionStart $(Get-Date)
			Trace (" Completed in {0,0:n0} days, {1,0:n0} hours, {2,0:n0} minutes, {3,0:n0} seconds" -f $MyContext.TotalElapsed.Days, $MyContext.TotalElapsed.Hours, $MyContext.TotalElapsed.Minutes, $MyContext.TotalElapsed.Seconds )
			Trace " "
			
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
				Trace " " 
				Trace " Cancelled ! User has stopped 7-Zip archiving process" 
				Trace " NO ARCHIVE HAS BEEN CREATED" 
				If(Test-Path -Path $BkDestFile -PathType Leaf) { Remove-Item -LiteralPath $BkDestFile -Force | Out-Null }
			} ElseIf (($Bk7ZipRetc -eq 2)) {
				$gP.CriticalCount += 1
				Trace " " 
				Trace " Cancelled ! 7-Zip reported a fatal error." 
				Trace " NO VALID ARCHIVE HAS BEEN CREATED"
				If(Test-Path -Path $BkDestFile -PathType Leaf) { Remove-Item -LiteralPath $BkDestFile -Force | Out-Null }
			} ElseIf (($Bk7ZipRetc -eq 7)) {
				$gP.CriticalCount += 1
				Trace " " 
				Trace " Cancelled ! 7-Zip has been invoked with a wrong command line." 
				Trace " $cmdLine" 
				Trace " NO VALID ARCHIVE HAS BEEN CREATED" 
				If(Test-Path -Path $BkDestFile -PathType Leaf) { Remove-Item -LiteralPath $BkDestFile -Force | Out-Null }
			} ElseIf (($Bk7ZipRetc -eq 8)) {
				$gP.CriticalCount += 1
				Trace " "
				Trace " Cancelled ! 7-Zip reports not enough memory." 
				Trace " NO VALID ARCHIVE HAS BEEN CREATED" 
				If(Test-Path -Path $BkDestFile -PathType Leaf) { Remove-Item -LiteralPath $BkDestFile -Force | Out-Null }
			} ElseIf (!(Test-Path -Path "$BkDestPath\$BkArchiveName" -PathType Leaf)) {
				$gP.CriticalCount += 1
				Trace " " 
				Trace " Error !" 
				Trace " NO ARCHIVE HAS BEEN CREATED" 
			}
			
			
		}
	}
	Else {
		Trace " Dry Run Selected ! No Archive creation."
	}
	
# If is set a list of notification addresses then proceed with email here
if (!(Check-CTRLCRequest)) { 
	Do-PostAction
	Send-Notification
}

# Clean Up 
Clear-Script
