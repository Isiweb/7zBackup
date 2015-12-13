# ====================================================================
#  This is the 7zBackup Default Vars Script File
# ====================================================================
# VARIABLES - You can hardcode values here if you do not want to
#             to pass them by command line. 
# --------------------------------------------------------------------
#  Variable       : BkType 
#  Argument Name  : --type
#  Description    : Type of backup to perform. 
#  Values         : full | diff | incr | copy
#  Comments   
#  -------------------------------------------------------------------
#  full : This option performs the archiving of all files in the 
#         selection paths regardless the state of their archive attribute.
#         At successfull archiving operation all archive attributes
#         for all archived files are lowered.
#  diff : This option is generally used to perform the archiving of
#         files in the selection paths that have changed after a previous
#         backup (archive attribute set). 
#         At successfull archiving operation all archive attributes
#         for all archived files are lowered.
#  incr : This option is generally used to perform the archiving of
#         files in the selection paths that have changed after a previous
#         full backup (archive attribute set). 
#         At successfull archiving operation all archive attributes
#         for all archived files are left unchanged.
#  copy : Like FULL backup but leaves archive attribute unchanged
#  -------------------------------------------------------------------
#  Uncomment the following Set-Variable statement and set proper
#  "<value>" if you want to set the value for the 7zBackup script.
#  -------------------------------------------------------------------
# Set-Variable -name BkType -value "<value>" -scope 1

# --------------------------------------------------------------------
#  Variable       : BkWorkDrive 
#  Argument Name  : --workdrive
#  Description    : Drive unit to use for making root junction points
#  Values         : Any valid drive letter
#  Comments   
#  -------------------------------------------------------------------
#  This value holds the drive letter to use for the creation of the root
#  junction directory. Default setting is "auto"
#  which means the script will try to use the drive letter associated
#  to the %TEMP% variable
#  Of course, you can change this value using proper command line argument
#  -------------------------------------------------------------------
#  Uncomment the following Set-Variable statement and set proper
#  "<value>" if you want to set the value for the 7zBackup script.
#  -------------------------------------------------------------------
# Set-Variable -name BkWorkDrive -value "<value>" -scope 1

# --------------------------------------------------------------------
#  Variable       : BkSelection 
#  Argument Name  : --selection
#  Description    : Full path to the file holding selection directives
#  Values         : 
#  Comments   
#  -------------------------------------------------------------------
#  Generally speaking you should not hardcode this value as you will
#  likely pass different selection file names using command line.
#  -------------------------------------------------------------------
#  Uncomment the following Set-Variable statement and set proper
#  "<value>" if you want to set the value for the 7zBackup script.
#  -------------------------------------------------------------------
# Set-Variable -name BkSelection -value "<value>" -scope 1

# --------------------------------------------------------------------
#  Variable       : BkDestPath 
#  Argument Name  : --destpath
#  Description    : Full path to directory
#  Values         : 
#  Comments   
#  -------------------------------------------------------------------
#  This is the target folder that will contain the backup archive. Consider this path
#  as a sort of library that will contain all of your backups. The real archive name
#  will be generated automatically. Can be a UNC path
#  -------------------------------------------------------------------
#  Uncomment the following Set-Variable statement and set proper
#  "<value>" if you want to set the value for the 7zBackup script.
#  -------------------------------------------------------------------
# Set-Variable -name BkDestPath -value "<value>" -scope 1

# --------------------------------------------------------------------
#  Variable       : BkArchivePrefix 
#  Argument Name  : --prefix
#  Description    : Prefix to assign to generated archive
#  Values         : 
#  Comments   
#  -------------------------------------------------------------------
#  This variable contains the prefix to use in archive name generation. 
#  By default this is equal to the COMPUTERNAME environment variable but
#  you can choose whichever value you want with no spaces and no quotes.
#  The suffix can help you mantain groups of backups and to handle
#  retain/rotation policy, as described later.
#  Archive name creation template is the following:
#  $BkArchivePrefix-$BkType-YYYYMMDD-HH-mm.$BkArchiveType
#  -------------------------------------------------------------------
#  Uncomment the following Set-Variable statement and set proper
#  "<value>" if you want to set the value for the 7zBackup script.
#  -------------------------------------------------------------------
Set-Variable -name BkArchivePrefix -value ($Env:Computername) -scope 1

# --------------------------------------------------------------------
#  Variable       : BkArchiveType 
#  Argument Name  : --archivetype
#  Description    : Type of archive to create
#  Values         : 7z | zip | tar
#  Comments   
#  -------------------------------------------------------------------
#  This variable contains the type of archive you want to create.
#  Value can be any of the supported values by 7zip for the -t switch
#  except for bzip2 (which is not an archiver)
#
#  7z   : default format with better compression
#  zip  : very compatible with other programs
#  tar  : Unix and linux compatible but only archiving (no compression)
#
#  Archive name creation template is the following:
#  $BkArchivePrefix-$BkType-YYYYMMDD-HH-mm.$BkArchiveType
#  -------------------------------------------------------------------
#  Uncomment the following Set-Variable statement and set proper
#  "<value>" if you want to set the value for the 7zBackup script.
#  -------------------------------------------------------------------
Set-Variable -name BkArchiveType -value "7z" -scope 1

# --------------------------------------------------------------------
#  Variable       : BkArchivePassword 
#  Argument Name  : --password
#  Description    : Any valid password
#  Values         : 
#  Comments   
#  -------------------------------------------------------------------
#  Set this if you want to password protect your archive
#  -------------------------------------------------------------------
#  Uncomment the following Set-Variable statement and set proper
#  "<value>" if you want to set the value for the 7zBackup script.
#  -------------------------------------------------------------------
# Set-Variable -name BkArchivePassword -value "<yourpassword>" -scope 1

# --------------------------------------------------------------------
#  Variable       : BkRotate 
#  Argument Name  : --rotate
#  Description    : An integer number greater than 0
#  Values         : 
#  Comments   
#  -------------------------------------------------------------------
#  This variable holds the number of historycal archive backups you
#  want to keep on target media. An zero value means no rotation
#  will be performed after succesful archiving and YOU will be in charge
#  to delete old backups. Pay attention or your target media
#  will run out of free space soon.
#  For example: if you set this value to 3 then it means the 3 newest
#  backups of the current type are kept on target media.
#  For a "classic" 3 week incremental scheme we suggest to :
#  $BkRotate=3 for full backups (launched once a week)
#  $BkRotate=21 for incr backups (launched once per day)
#  -------------------------------------------------------------------
#  Uncomment the following Set-Variable statement and set proper
#  "<value>" if you want to set the value for the 7zBackup script.
#  -------------------------------------------------------------------
# Set-Variable -name BkRotate -value ([int]3) -scope 1

# --------------------------------------------------------------------
#  Variable       : BkKeepEmptyDirs
#  Argument Name  : --emptydirs
#  Description    : Boolean
#  Values         : 
#  Comments   
#  -------------------------------------------------------------------
#  This variable sets weather or not archive empty directories
#  If not defined the script assumes a value of $False (default).
#
#  Empty dirs are not really archived. The script drops a dummy file
#  into empty dirs to have it archived. After archiving dummy file
#  is immediately removed.
#
#  -------------------------------------------------------------------
#  Uncomment the following Set-Variable statement and set proper
#  "<value>" if you want to set the value for the 7zBackup script.
#  -------------------------------------------------------------------
# Set-Variable -name BkKeepEmptyDirs -value $True -scope 1

# --------------------------------------------------------------------
#  Variable       : BkMaxDepth 
#  Argument Name  : --maxdepth
#  Description    : An integer number in range from 0 to 100
#  Values         : 
#  Comments   
#  -------------------------------------------------------------------
#  This variable holds the maximum level to be reached in directory
#  recursion while scanning for files to backup.
#  If not defined the script assumes a maximum level of 100 (default).
#
#  The value is zero-based which means a value of zero whil stop the
#  the scanning at the first level. A value of 1 will allow 1 recursion
#  level therefore scanning the firs level of subfolders and so on
#
#  -------------------------------------------------------------------
#  Uncomment the following Set-Variable statement and set proper
#  "<value>" if you want to set the value for the 7zBackup script.
#  -------------------------------------------------------------------
# Set-Variable -name BkMaxDepth -value ([int]100) -scope 1


# --------------------------------------------------------------------
#  Variable       : BkLogFile 
#  Argument Name  : --logfile
#  Description    : Full path you want to assign to log file
#  Values         : 
#  Comments   
#  -------------------------------------------------------------------
#  This variable holds the name of the file where to log operations
#  By default it's stored in %temp% directory within a file named 
#  as the script plus ".log" extension.
#  -------------------------------------------------------------------
#  Uncomment the following Set-Variable statement and set proper
#  "<value>" if you want to set the value for the 7zBackup script.
#  -------------------------------------------------------------------
# Set-Variable -name BkLogFile -value "<value>" -scope 1

# --------------------------------------------------------------------
#  Variable       : Bk7ZipBin
#  Argument Name  : --7zipbin
#  Description    : Full path to 7z.exe
#  Values         : 
#  Comments
#  -------------------------------------------------------------------
#  7-zip executable path. 
#  If you have installed 7zip using standard path, then you do not need to
#  change this.
#  -------------------------------------------------------------------
#  Uncomment the following Set-Variable statement and set proper
#  "<value>" if you want to set the value for the 7zBackup script.
#  -------------------------------------------------------------------
Set-Variable -name Bk7ZipBin -value (Join-Path $Env:ProgramFiles "\7-zip\7z.exe") -scope 1

# --------------------------------------------------------------------
#  Variable       : Bk7ZipSwitches
#  Argument Name  : none (can't pass them from cli)
#  Description    : Extra switches to pass to 7z.exe when running
#  Values         : 
#  Comments   
#  -------------------------------------------------------------------
#  Here you can specify several switches supported by 7zip.
#  Refer to 7zip documentation for a proper usage.
#  READ THE MANUAL ! READ THE MANUAL ! READ THE MANUAL !
#  By default we assume the following:
#  -bd        disable progress status
#  -ssw       archive locked files
#  -mf=off    disable compression filters for executable files
#  -mx1       Ultra Fast compression
#  -mmt=1     one thread only
#  -ms=e      Use a separate solid block for each new file extension
#  -mtc=on    archive NTFS file infomations (not ACLS)
#  -md=96m    use 96m dictionary
#  -slp       enables Large Pages mode.
#  -scsUTF-8  Read selection file encoded as UTF8     << DO NOT CHANGE
#  -sccUTF-8  Standard Output encoded as UTF8         << DO NOT CHANGE
#  
#  WARNING ! These default switches are to be intended for 7z archives
#  Choosing different archive types can cause 7-zip to refuse to execute
#
#  -------------------------------------------------------------------
#  Uncomment the following Set-Variable statement and set proper
#  "<value>" if you want to set the value for the 7zBackup script.
#  -------------------------------------------------------------------
Set-Variable -name Bk7ZipSwitches -value "-bd -ssw -mx1 -md=96m -mmt=6 -mtc=on -mf=off -slp -scsUTF-8 -sccUTF-8" -scope 1

# --------------------------------------------------------------------
#  Variable       : BkJunctionBin
#  Argument Name  : --jbin
#  Description    : Full path to Junction .exe
#  Values         : 
#  Comments   
#  -------------------------------------------------------------------
#  Find where Junction.exe is and set it here. If Junction.exe is in
#  a directory within the PATH variable you can simply indicate
#  junction.exe
#
#  PLEASE NOTE 
#  If you're running the script on Vista / 7 / 2008 this variable
#  and it's value is completely ignored. Instead of junctions
#  Symbolic Links are used (MKLINK).
#  -------------------------------------------------------------------
#  Uncomment the following Set-Variable statement and set proper
#  "<value>" if you want to set the value for the 7zBackup script.
#  -------------------------------------------------------------------
Set-Variable -name BkJunctionBin -value (Join-Path $Env:ProgramFiles  "\SysInternalsSuite\Junction.exe") -scope 1

# --------------------------------------------------------------------
#  Variable       : BkNotifyLog
#  Argument Name  : --notify or --notifyto
#  Description    : Holds the email address(es) to send the report
#                   of operations to.
#  Comments   
#  -------------------------------------------------------------------
#  Use this argument to set a single email address, or a list of email
#  addresses, which will receive the detailed report of operations.
#  If you mean to address the report to a single email address then
#  you will want to set the variable as a normal string.
#  If you mean to have multiple addresses to send the report to, then
#  you will have to set the variable as an array.
#
#  PLEASE NOTE 
#  Each email address undergoes a check to verify it is properly
#  formatted.
#  -------------------------------------------------------------------
#  Uncomment the following Set-Variable statement and set proper
#  "<value>" if you want to set the value for the 7zBackup script.
#  -------------------------------------------------------------------
#  Set-Variable -name BkNotifyLog -value "someemail@somedomain.com" -scope 1
# - or -
#  Set-Variable -name BkNotifyLog -value @("someemail@somedomain.com", "someotheremail@somedomain.com") -scope 1

# --------------------------------------------------------------------
#  Variable       : BkNotifyExtra
#  Argument Name  : --notifyextra 
#  Description    : Specifies if you want extra info in the notification
#                   log
#  Comments   
#  -------------------------------------------------------------------
#  Use this argument to set your option about having or not extra
#  informations in your notification log.
#  ExtraInfos are : the complete list of inclusions, the complete
#  list of exclusions and the list of exceptions (if any). In addition
#  the complete selection file will be sent.
#  Extra info delivery mode options are:
#  none   : no extra info will be sent (default)
#  inline : all extra info will be written in the message body
#  attach : all extra info will be attached as separate files
#
#  -------------------------------------------------------------------
#  Uncomment the following Set-Variable statement and set proper
#  "<value>" if you want to set the value for the 7zBackup script.
#  -------------------------------------------------------------------
#  Set-Variable -name BkNotifyExtra -value "< none | inline | attach >" -scope 1

# --------------------------------------------------------------------
#  Variable       : mailSubject
#  Argument Name  : None (you can't pass it from cli)
#  Description    : String to use as subject for notification email
#  Values         : 
#  Comments   
#  -------------------------------------------------------------------
#  Self explanatory ... isn't it ?
#  -------------------------------------------------------------------
#  Uncomment one of the following Set-Variable statement and set proper
#  "<value>" if you want to set the value for the 7zBackup script.
#  -------------------------------------------------------------------
# Set-Variable -name mailSubject -value "7zBackup Report Host $Env:ComputerName.$Env:USERDNSDOMAIN" -scope 1
# - or -
# Set-Variable -name smtpFrom -value "7zBackup Report" -scope 1

# --------------------------------------------------------------------
#  Variable       : smtpFrom
#  Argument Name  : --notifyfrom
#  Description    : Email address to send email notifications from
#  Values         : 
#  Comments   
#  -------------------------------------------------------------------
#  Self explanatory ... isn't it ?
#  -------------------------------------------------------------------
#  Uncomment one of the following Set-Variable statement and set proper
#  "<value>" if you want to set the value for the 7zBackup script.
#  -------------------------------------------------------------------
# Set-Variable -name smtpFrom -value ($Env:UserName + "@" + $Env:UserDNSDomain) -scope 1
# - or -
# Set-Variable -name smtpFrom -value "<value>" -scope 1

# --------------------------------------------------------------------
#  Variable       : smtpRelay
#  Argument Name  : --smtpserver
#  Description    : The name of the smtp server to use when sending
#                   notification emails.
#  Values         : Host name or ip address
#  Comments   
#  -------------------------------------------------------------------
#  Self explanatory ... isn't it ?
#  -------------------------------------------------------------------
#  Uncomment one of the following Set-Variable statement and set proper
#  "<value>" if you want to set the value for the 7zBackup script.
#  -------------------------------------------------------------------
# Set-Variable -name smtpRelay -value "<yourmailserverDNSName_or_IP_address>" -scope 1

# --------------------------------------------------------------------
#  Variable       : smtpPort
#  Argument Name  : --smtpport
#  Description    : The port to contact smtp server on
#  Values         : integer number (default 25)
#  Comments   
#  -------------------------------------------------------------------
#  Self explanatory ... isn't it ?
#  -------------------------------------------------------------------
#  Uncomment one of the following Set-Variable statement and set proper
#  "<value>" if you want to set the value for the 7zBackup script.
#  -------------------------------------------------------------------
Set-Variable -name smtpPort -value ([int]25) -scope 1

# --------------------------------------------------------------------
#  Variable       : smtpUser
#  Argument Name  : --smtpuser
#  Description    : The user to access authenticated smtp
#  Values         : String
#  Comments       : If you set this remember to set smtpPass also
#  -------------------------------------------------------------------
#  Uncomment one of the following Set-Variable statement and set proper
#  "<value>" if you want to set the value for the 7zBackup script.
#  -------------------------------------------------------------------
# Set-Variable -name smtpUser -value "<authuser>" -scope 1

# --------------------------------------------------------------------
#  Variable       : smtpPass
#  Argument Name  : --smtppass
#  Description    : The password to use for authenticated smtp
#  Values         : String
#  Comments       : If you set this remember to set smtpUser also
#  -------------------------------------------------------------------
#  Uncomment one of the following Set-Variable statement and set proper
#  "<value>" if you want to set the value for the 7zBackup script.
#  -------------------------------------------------------------------
# Set-Variable -name smtpPass -value "<password>" -scope 1

# --------------------------------------------------------------------
#  Variable       : smtpSsl
#  Argument Name  : --smtpssl
#  Description    : Whether or not to enable Ssl over smtp
#  Values         : True or False
#  Comments   
#  -------------------------------------------------------------------
#  Self explanatory ... isn't it ?
#  -------------------------------------------------------------------
#  Uncomment one of the following Set-Variable statement and set proper
#  "<value>" if you want to set the value for the 7zBackup script.
#  -------------------------------------------------------------------
# Set-Variable -name smtpSsl -value ($False) -scope 1
