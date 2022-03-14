# Brian Beard
# All commands are curtesy of docs.microsoft.com
# Run the script from the DC1 server from the snapshot after week 8.
# Disclaimer, does not accomplish every task exactly as asked for in the assignment.

# Clear the screen
Clear-Host

# Welcome
Write-Host("############`nWeek9 Script`nby Kurtsley`n##########`n`n")

$continue = Read-Host("Welcome to the week 9 script. This script will perform MOST of the tasks assigned this week. Continue? (Y/N)")
while ("Y", "N" -notcontains $continue) { $continue = Read-Host "Welcome to the week 9 script. Continue? (Y/N)" }
if ($continue -eq "Y") {

    # Create the PIAT folder
    Write-Host("Creating shared folder and setting permissions...`n")
    Start-Sleep -s 1
    New-Item -Path 'C:\PIAT' -ItemType Directory

    # Create the share with change acces to Authenticated Users
    New-SmbShare -Name PIAT -Path C:\PIAT -ChangeAccess 'Authenticated Users'

    # Create the user account
    Write-Host("Creating the new user...`n")
    Start-Sleep -s 1

    $firstname = Read-Host("Enter first name")
    $lastname = Read-Host("Enter last name")
    $logonname = $firstname.Substring(0, 1).ToUpper() + "." + (Get-Culture).TextInfo.ToTitleCase($lastname)
    $fullname = "$firstname $lastname"

    new-aduser -name $fullname -userprincipalname $logonname"@contoso.com" -displayname $fullname -samaccountname $logonname -givenname $firstname -surname $lastname -accountpassword (read-host -assecurestring "AccountPassword") -cannotchangepassword 1 -changepasswordatlogon 0 -passwordneverexpires 1 -enabled $true

    # Create security group
    Write-Host("Creating CIS-216 Users group and adding the user...`n")
    Start-Sleep -s 1
    new-adgroup -name "CIS-216 Users" -groupcategory security -groupscope global

    # Add Brian Beard to the group
    add-adgroupmember -identity "CIS-216 Users" -members $logonname

    # Adding the CIS-216 Users group to the PIAT ntfs permissions
    Write-Host("Adding the group to the shared folder ntfs permissions...`n")
    Start-Sleep -s 1
    $acl = get-acl -path "c:\piat"
    $ar = new-object system.security.accesscontrol.filesystemaccessrule("CIS-216 Users", "Modify", "ContainerInherit, ObjectInherit", "None", "Allow")
    $acl.setaccessrule($ar)
    set-acl -path "c:\piat" -aclobject $acl


    # Mapping the PIAT folder on the client, NA for this script
    # New-PSDrive -Persist -Name "Z" -PSProvider "FileSystem" -Root "\\dc1\piat" -Scope global

    # Enabling shadow copies
    Write-Host("Enabling and creating shadow copies and schedule...`n")
    Start-Sleep -s 1
    vssadmin add shadowstorage /for=C: /on=C: /maxsize=4034MB

    # Create the copy
    vssadmin create shadow /for=c:

    # Set schedule for AM
    Start-Sleep -s 1
    $Action = New-ScheduledTaskAction -Execute "c:\windows\system32\vssadmin.exe" -Argument "create shadow /for=C:"
    $Trigger = New-ScheduledTaskTrigger -Daily -At 6:00AM
    Register-ScheduledTask -TaskName ShadowCopyAM -Trigger $Trigger -Action $Action -Description "ShadowCopyAM"

    # Set schedule for PM
    $Action = New-ScheduledTaskAction -Execute "c:\windows\system32\vssadmin.exe" -Argument "create shadow /for=C:"
    $Trigger = New-ScheduledTaskTrigger -Daily -At 6:00PM
    Register-ScheduledTask -TaskName ShadowCopyPM -Trigger $Trigger -Action $Action -Description "ShadowCopyPM"

    Write-Host("Shadow copy backup will run twice daily at 6AM and 6PM.`n")
    Start-Sleep -s 3

    # Link http://serverfault.com/a/663730

    # Quota management
    Write-Host("Setting quota management...`n`nAll contoso.com users will have a 1kb warning threshold and a 1000 Petabyte data limit.`n")
    Start-Sleep -s 1
    fsutil quota track c:
    fsutil quota modify c: 1000 1000000000000000000 contoso.com

    Write-Host("Done!")
}