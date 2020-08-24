# Donation ware
If you like this piece of software a small donation is highly appreciated.
Please use one of the following addresses for your donations:
* Bitcoin : bc1q3ltqwqp0pwy070ss9j32637pw2glmm87qj0wwn
* Dash (Digital Cash) : XtydCExz6cRJLdc8gT5ZnGGpsTVKZ9j77T
* Doge : DJXpPy9wWf5BRVBET9HhpgyGuoPq75xkfR
* Ethereum : 0x4813aEEE0c30C584C559fa8Dc7424481E2e9Fc91

# Project Description
7zBackup is a PowerShell script aimed to help you automate your backup on-file tasks. 7zbackup leverages the great compression performances offered by 7-Zip while offering the great option to have different file sources stored in a single compressed archive.

# Abstract
Backup, Backup and again Backup. How many times have you heard this ? A good backup strategy is vital for any IT Infrastructure regardless their dimensions. Off-site backups are, without any doubt, the corner stone of those strategies but nowadays, the increased availability of on-disk space (larger disks, NAS, SANs), is a great help if you want to increase your backup frequencies using on-line attached media.
That's why, in my personal experience, I make intensive usage of the "old pal" NtBackup to keep on disk different copies of Full/Incremental/Differential backups of my data and, of course, data from my customers. But while NtBackup is a good companion it lacks in one particular aspect: it waste a huge amount of bytes. Every .bkf file is plus the sum of all the data backed up. 
So ... if you have space ... why waste space ? There comes in mind the obvious answer: use compression. 
There are a lot of compression tools out there but none of them have succeded in my very personal expectations, till I found 7-Zip: it's free, it's small, it's fast, it's effective.
There are a few drawbacks though: mainly the unability by 7zip to select files on specific criteria and to bind several sources in one archive unless you do it manually (many have encountered the "Duplicated File Name" problem).
So I decided to write this small script which acts, substantially, as a selection wrapper for 7zip.

## What 7zbackup.ps1 IS
It allows you to select files to backup using mostly the criteria of their "Archive" attribute which helps in building up catalogs to backup for Full, Differential and Incremental strategy. In addition it extends the selection criteria with several directives. You can fine tune the directories to dig into and file types/names to include or exclude. 
It prepares a list of files from which 7-Zip reads which files are to insert into archive
It resolves the oddity of "Duplicate File Name" of 7Zip: with the proper usage of Junction points on NTFS file system the whole selection stays under one single root and all files in the list catalog report a relative path. It resets "Archive" attribute of archived files only if they're properly processed. This is relevant if you backup using differential and or incremental methods. It keeps your backup archives in order eliminating the "older" ones.
It can help you cleaning up your directory structure from unwanted files ... in few words a small and free backup on-file solution.

## What 7zbackup.ps1 IS NOT and what it can't do
* It's NOT a disaster recovery tool.
* It can't save the state of your running machine.
* It can't save ACLs of files into archives
* It can't perform any restore operation. If you need to restore any file simply use 7-zip File Manager to open the generated archive and extract files you need.
* It can't replace any of your off-site backup strategies.

## Please read. Please ...
**This script makes use of Junction points (or Symbolic Links for Windows Vista/7/2008) typically placed in C: drive (root). These NTFS objects are displayed as folders in your Explorer interface. If, for any reason, the script should interrupt abnormally, it's generated junction points or symbolic links,  may remain on disk. DO NOT USE WINDOWS EXPLORER TO DELETE JUNCTIONS OR SYMBOLIC LINKS AS IT TRAVERSES THE LINK AND MAY REMOVE YOUR REAL FILES AND FOLDERS.**

* To remove a junction point use junction.exe with the -d switch. 
* To remove a symbolic link use the RD command line. If you are using Powershell, be more careful and use `cmd /c rmdir .\thesymlink'sname`.

## System Requirements
* Windows XP, Windows Vista or better, Windows 2003 or better. (Might also work on Windows 2000 but there is some work to do for having PowerShell running on that platform)
* NTFS File System
* [PowerShell] 2.0 or better
* [7-Zip] 9.2.0 or newest
* [SysInternals] Junction Tool v. 1.0.5 ( not required if running Windows Vista / 7 / 2008)

## Features
* Backup your files in compressed archives by 7-zip (7z format or zip or tar)
* Full, Differential, Incremental and Copy Backups
* Option to move files into archives (deleting original)
* Flexible selection of files and paths using regular expressions
* Flexible adjustement of compression over speed (compression level and threads)
* Automatic removal of "old" backup archives (rotation)
* Can remove unwanted files during the scan process
* Can remove unwanted directories during the scan process
* Send log of operations via email also to Cc and Bcc
* Easily manageable like a script is
* Easily schedule your backup operations (using task scheduler)

[//]: # (These are reference links used in the body of this note and get stripped out when the markdown processor does its job. There is no need to format nicely because it shouldn't be seen. Thanks SO - http://stackoverflow.com/questions/4823468/store-comments-in-markdown-syntax)

   [PowerShell]: <https://technet.microsoft.com/en-us/scriptcenter>
   [7-Zip]: <http://www.7-zip.org/>
   [SysInternals]: <https://technet.microsoft.com/en-us/sysinternals/bb842062.aspx>


