Param
(
[Parameter(Mandatory=$true,Position=0)]
[String]$Value
)

#############################################################################
#If Powershell is running the 32-bit version on a 64-bit machine, we 
#need to force powershell to run in 64-bit mode .
#############################################################################
if ($env:PROCESSOR_ARCHITEW6432 -eq "AMD64") {
    if ($myInvocation.Line) {
        &"$env:WINDIR\sysnative\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile $myInvocation.Line
    }else{
        &"$env:WINDIR\sysnative\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile -file "$($myInvocation.InvocationName)" $args
    }
exit $lastexitcode
}


write-host "Main script"

#############################################################################
#End
#############################################################################    
$ErrorActionPreference="SilentlyContinue"
Stop-Transcript | out-null
$ErrorActionPreference = "Continue"
Start-Transcript -path C:\sysstuff\Add-UserAsAdminTranscript.txt -append

function Add-UserAsAdmin{
    #this script is depends on another one that creates .sid file for each user that connects
    #the sid file contains that user's sid id
    $users_files = Get-ChildItem -Path C:\sysstuff -Include '*.sid' -Name
    foreach($user in $users_files){
        #for each file that ends in .sid, add the SID value to the local administrators group
        $user_sid = Get-Content C:\sysstuff\$($user)
        Add-LocalGroupMember -Group "Administrators" -Member "$($user_sid)" 
        }
    }


function Del-UserAsAdmin{
    $users_files = Get-ChildItem -Path C:\sysstuff -Include '*.sid' -Name
    foreach($user in $users_files){
        #for each file that ends in .sid, remove the SID value to the local administrators group
        $user_sid = Get-Content C:\sysstuff\$($user)
        Remove-LocalGroupMember -Group "Administrators" -Member "$($user_sid)"
        }
    $remove = net localgroup administrators | select -skip 6 | ? {$_ -and $_ -notmatch 'successfully|^administrator$|ServiceSysAdmin'};
    #Here we get the list of other users that are added to the local administrator group
    foreach ($user in $remove){
        #Additionally to removing all the users that had .sid files on the device, we also remove everyone but the administrator account(which is disabled) and our local administrator account(which we will change it's password to) 
        net localgroup administrators "`"$user`"" /delete
        }

    $op = Get-LocalUSer | where-Object Name -eq "ServiceSysAdmin" | Measure
    if ($op.Count -eq 0) {
        #This is done to prevent geniuses that try to keep admin access by changing the ServiceSysAdmin password
        Write-Host "ServiceSysAdmin account not found, we create it now"
        $passwd = ConvertTo-SecureString "S0mePass!!" -AsPlainText -Force
        New-LocalUser "ServiceSysAdmin" -Password $passwd -FullName "Sysadmin Service Account" -Description "This account will be used by Sysadmin when remoting"
        Add-LocalGroupMember -Group "Administrators" -Member "ServiceSysAdmin"
}   else {
        #This is done to prevent geniuses that try to keep admin access by changing the ServiceSysAdmin password
        Write-Host "ServiceSysAdmin account found, removing and recreating it "
        Remove-LocalUser -Name "ServiceSysAdmin"
        $passwd = ConvertTo-SecureString "S0mePass!!" -AsPlainText -Force
        New-LocalUser "ServiceSysAdmin" -Password $passwd -FullName "Sysadmin Service Account" -Description "This account will be used by Sysadmin when remoting"
        Add-LocalGroupMember -Group "Administrators" -Member "ServiceSysAdmin"
}
    }

#Here we are calling the add function using the parameter Add
if($Value -eq "Add"){
Add-UserAsAdmin 2>&1 >> C:\sysstuff\Add-UserAsAdminADDOut.txt
}

#Here we are calling the del function using the parameter Del
if($Value -eq "Del"){
Del-UserAsAdmin 2>&1 >> C:\sysstuff\Add-UserAsAdminDELOut.txt
}

Stop-Transcript
if($Value -eq "Del"){
#The transcript file is used to detect the install state of this "script" so we have to remove it in order for Intune to know that we succesfully removed the admin rights , we get the output of the dell function separately (line 78)
Remove-Item "C:\sysstuff\Add-UserAsAdminTranscript.txt"
#When removing a user from the Administrators group, you need to force a restart, otherwise the user can add himself back
Restart-Computer -ComputerName localhost -Force
}